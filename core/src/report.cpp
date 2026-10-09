#include "grader.hpp"
#include <map>
#include <cerrno>
#include <stdexcept>
#include <iomanip>
#include <sstream>
#ifdef _WIN32
#define NOMINMAX
#include <windows.h>
#include <shellapi.h>
#else
#include <spawn.h>
#include <sys/wait.h>
#include <thread>
extern char **environ;
#endif
namespace fs=std::filesystem;
namespace {
std::string bytes(const int* p,const int* n,int limit) {
    if(!p||!n||*n<1||*n>limit) throw std::runtime_error("input_length");
    std::string s; s.reserve(*n);
    for(int k=0;k<*n;++k) {if(p[k]<1||p[k]>255) throw std::runtime_error("input_byte");s+=static_cast<char>(p[k]);}
    return s;
}
std::string unit(std::string u) {
    if(u=="Ohm") return "Ω";
    if(u=="choice"||u=="1") return "";
    return u;
}
std::string parameter_unit(const std::string& key) {
    if(key.empty()) return "";
    if(key[0]=='R'||key=="r") return "Ω";
    if(key[0]=='E'||key[0]=='U') return "V";
    if(key[0]=='F') return "Hz";
    if(key[0]=='C') return "F";
    if(key[0]=='L') return "H";
    if(key[0]=='P') return "%";
    return "";
}
std::string numeric(const ld::Json& value) {
    if(!value.is_number()) return value.dump();
    std::ostringstream out; out << std::setprecision(8) << value.get<double>();return out.str();
}
std::string answer_text(const ld::Json& a) {
    auto raw=a.at("raw").get<std::string>(); if(raw.empty()) return "Neįvesta";
    if(a.at("unit")=="choice") {
        auto id=a.at("id").get<std::string>();
        if(id.find(".change")!=std::string::npos) {
            if(raw=="1") return "Padidėjo";
            if(raw=="2") return "Sumažėjo";
            if(raw=="3") return "Nepakito";
        } else if(id.find(".type")!=std::string::npos) {
            if(raw=="1") return "Nuosekli";
            if(raw=="2") return "Lygiagreti";
            if(raw=="3") return "Mišri";
        } else {if(raw=="1") return "Taip";if(raw=="2") return "Ne";}
    }
    return raw;
}
}
namespace ld {
std::string report_html(const Json& r) {
    // Reuse rubric labels only. Never publish expected answers or grading hints
    // into the student's submitted report.
    auto verdict=grade(r);std::map<std::string,std::string> labels;
    for(auto& item:verdict.at("items")) labels[item.at("id")]=item.at("label");
    labels["f1_meas"]="Apatinis ribinis dažnis"; labels["f2_meas"]="Viršutinis ribinis dažnis";
    labels["f1_u"]="Įtampa ties apatiniu ribiniu dažniu"; labels["f2_u"]="Įtampa ties viršutiniu ribiniu dažniu";
    if(r.at("rubric_version")=="LD6-3") {
        const char* modes[]={"Tik E1","Nuosekliai","Priešpriešiais","Lygiagrečiai"};
        for(int mode=1;mode<=4;++mode) {
            labels["u"+std::to_string(mode)]=std::string(modes[mode-1])+": apkrovos U";
            labels["i"+std::to_string(mode)]=std::string(modes[mode-1])+": apkrovos I";
        }
        labels["parallel_i1"]="Lygiagrečiai: E1 šaltinio srovė";
        labels["parallel_i2"]="Lygiagrečiai: E2 šaltinio srovė";
    }
    auto esc=[](const std::string& s){return html_escape(s);};
    auto label=[&](const std::string& id){auto i=labels.find(id);return i==labels.end()?id:i->second;};
    std::string doc="<!doctype html><html lang=\"lt\"><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width\"><title>"+esc(r.at("lab_id"))+" ataskaita</title><style>body{font:16px system-ui;max-width:960px;margin:2rem auto;padding:1rem;color:#203237}table{border-collapse:collapse;width:100%}td,th{padding:.6rem;border-bottom:1px solid #ddd;text-align:left}pre{white-space:pre-wrap}h1,h2{color:#17645a}</style>";
    doc+="<h1>"+esc(r.at("lab_id"))+" · studento ataskaita</h1><p>"+esc(r.at("student").at("name"))+" · "+esc(r.at("student").at("group"))+" · variantas "+r.at("variant").dump()+"</p>";
    doc+="<p>"+std::string(r.at("mode")=="assessment"?"Atsiskaitymas":"Mokymasis")+". ";
    if(r.value("practice_used",false)) doc+="Naudota mokymosi pagalba; dėstytojui reikalinga atskira peržiūra. ";
    if(r.at("rubric_version")=="LD1-2") doc+="Vertinami 15 studento atsakymų. Už automatinius matavimus ir jungimus balai neskiriami. ";
    if(r.at("rubric_version")=="LD1-3") doc+="Vertinami studento jungimai ir septyni atsakymai apie matavimus. Automatiniai matavimo duomenys balų nedidina. Šakų srovės užfiksuotos virtualiuose matavimo taškuose, naudojant tą patį sujungtos grandinės modelį. ";
    if(r.at("rubric_version")=="LD6-3") doc+="Vertinami keturi realūs sujungimai, keturi atlikti matavimo režimai, penki teoriniai skaičiavimai ir dvi išvados. Virtualaus stendo parodytų U/I skaičių perrašyti nereikia. ";
    doc+="</p><h2>Priskirtos reikšmės</h2><table><tr><th>Dydis</th><th>Reikšmė</th></tr>";
    for(auto it=r.at("parameters").begin();it!=r.at("parameters").end();++it) doc+="<tr><td>"+esc(it.key())+"</td><td>"+esc(numeric(it.value()))+" "+parameter_unit(it.key())+"</td></tr>";
    doc+="</table><h2>Jūsų atsakymai</h2><table><tr><th>Užduotis</th><th>Atsakymas</th><th>Vienetas</th></tr>";
    for(auto& a:r.at("answers")) doc+="<tr><td>"+esc(label(a.at("id")))+"</td><td>"+esc(answer_text(a))+"</td><td>"+esc(unit(a.at("unit")))+"</td></tr>";
    doc+="</table><h2>Matavimai</h2><table><tr><th>Matavimas</th><th>Rodmuo</th><th>Vienetas</th></tr>";
    for(auto& a:r.at("observations")) doc+="<tr><td>"+esc(label(a.at("id")))+"</td><td>"+(a.at("value").is_null()?"Neišmatuota":esc(numeric(a.at("value"))))+"</td><td>"+esc(unit(a.at("unit")))+"</td></tr>";
    doc+="</table>";
    if(r.at("rubric_version")=="LD1-3") {
        const std::map<std::string,std::string> contacts={{"SRC_P","Šaltinis +"},{"SRC_N","Šaltinis −"},{"M_P","Multimetras +"},{"M_N","Multimetras COM"}};
        const auto contact=[&](const std::string& id) {
            auto found=contacts.find(id);if(found!=contacts.end()) return found->second;
            if(id.rfind("NODE_",0)==0) return "Mazgas "+id.substr(5);
            auto pos=id.find('_');return pos==std::string::npos?id:id.substr(0,pos)+" · kontaktas "+id.substr(pos+1);
        };
        doc+="<h2>Išsaugoti sujungimai</h2><p>"+std::string(r.at("evidence").value("automatic_setup",false)?"Stendą paruošė programa mokymosi režime.":"Laidus sujungė studentas.")+"</p><table><tr><th>Etapas</th><th>Jungtis</th></tr>";
        for(const auto& stage:{"s1","s5"}) for(const auto& pair:r.at("evidence").at("wiring").at(stage).at("pairs"))
            doc+="<tr><td>"+std::string(stage==std::string("s1")?"1":"5")+"</td><td>"+esc(contact(pair.at(0)))+" ↔ "+esc(contact(pair.at(1)))+"</td></tr>";
        doc+="</table>";
    }
    doc+="<h2>Pastabos</h2><pre>"+esc(r.at("note"))+"</pre><p>Persiųskite šį vieną HTML failą dėstytojui. Juodraščio siųsti nereikia.</p>";
    std::string payload=r.dump(),safe;
    for(char c:payload) {if(c=='<') safe+="\\u003c";else safe+=c;}
    return doc+"<script type=\"application/json\" id=\"ld-data\">"+safe+"</script></html>";
}
}
LD_API void ld_export_report(const int* p,const int* np,const int* b,const int* nb,int* status) noexcept {
    if(!status)return;
    *status=-1;
    try {auto r=ld::Json::parse(bytes(b,nb,2*1024*1024));ld::write_new(fs::u8path(bytes(p,np,32768)),ld::report_html(r));*status=0;}catch(...){}
}
LD_API void ld_open_local(const int* p,const int* n,int* status) noexcept {
    if(!status)return;
    *status=-1;
    try {
        auto path=fs::absolute(fs::u8path(bytes(p,n,32768)));
        if(!fs::is_directory(path)&&!(fs::is_regular_file(path)&&path.extension()==".html")) return;
#ifdef _WIN32
        auto result=ShellExecuteW(nullptr,L"open",path.c_str(),nullptr,nullptr,SW_SHOWNORMAL);
        if(reinterpret_cast<INT_PTR>(result)>32)*status=0;
#else
#ifdef __APPLE__
        std::string opener="/usr/bin/open";
#else
        std::string opener="xdg-open";
#endif
        auto arg=path.u8string();char* argv[]={opener.data(),arg.data(),nullptr};pid_t pid;
        if(posix_spawnp(&pid,opener.c_str(),nullptr,nullptr,argv,environ)==0) {
            *status=0;std::thread([pid]{int s;while(waitpid(pid,&s,0)<0&&errno==EINTR){}}).detach();
        }
#endif
    }catch(...){}
}
