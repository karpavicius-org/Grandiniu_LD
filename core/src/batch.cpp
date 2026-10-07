#include "grader.hpp"
#include <algorithm>
#include <atomic>
#include <fstream>
#include <iostream>
#include <memory>
#include <mutex>
#include <random>
#include <sstream>
#include <stdexcept>
#ifdef _WIN32
#define NOMINMAX
#include <windows.h>
#else
#include <fcntl.h>
#include <unistd.h>
#endif
namespace fs=std::filesystem;
namespace ld {
namespace {
std::string unique_suffix() {
    static std::atomic<unsigned> serial{0};std::random_device random;
    return ".tmp-"+std::to_string(random())+"-"+std::to_string(++serial);
}
void atomic_write(const fs::path& path,const std::string& data,bool replace) {
    if(!fs::is_directory(path.parent_path()) || fs::is_symlink(path)) throw std::runtime_error("output_path");
    fs::path temp=path;temp+=unique_suffix();
    try {
#ifdef _WIN32
#define NOMINMAX
        HANDLE h=CreateFileW(temp.c_str(),GENERIC_WRITE,0,nullptr,CREATE_NEW,FILE_ATTRIBUTE_NORMAL,nullptr);
        if(h==INVALID_HANDLE_VALUE) throw std::runtime_error("output_open");
        DWORD written=0;bool ok=WriteFile(h,data.data(),static_cast<DWORD>(data.size()),&written,nullptr)!=0;
        ok=ok && written==data.size();if(!FlushFileBuffers(h)) ok=false;CloseHandle(h);
        if(!ok) throw std::runtime_error("output_write");
        if(!MoveFileExW(temp.c_str(),path.c_str(),MOVEFILE_WRITE_THROUGH|(replace?MOVEFILE_REPLACE_EXISTING:0))) throw std::runtime_error("output_commit");
#else
        int fd=::open(temp.c_str(),O_WRONLY|O_CREAT|O_EXCL,0600);
        if(fd<0) throw std::runtime_error("output_open");
        size_t offset=0;bool ok=true;
        while(offset<data.size()) {auto n=::write(fd,data.data()+offset,data.size()-offset);if(n<=0){ok=false;break;}offset+=static_cast<size_t>(n);}
        if(::fsync(fd)!=0) ok=false;
        if(::close(fd)!=0) ok=false;
        if(!ok) throw std::runtime_error("output_write");
        if(replace) {if(::rename(temp.c_str(),path.c_str())!=0) throw std::runtime_error("output_commit");}
        else {if(::link(temp.c_str(),path.c_str())!=0) throw std::runtime_error("output_exists_or_commit");fs::remove(temp);}
        int parent=::open(path.parent_path().c_str(),O_RDONLY|O_DIRECTORY);
        if(parent>=0) {::fsync(parent);::close(parent);}
#endif
    } catch(...) {std::error_code ec;fs::remove(temp,ec);throw;}
}
std::string csv(std::string s) {
    auto first=s.find_first_not_of(" \t\r\n");
    if(first!=std::string::npos && std::string("=+-@").find(s[first])!=std::string::npos) s="'"+s;
    std::string r="\"";for(char c:s) {if(c=='"') r+='"';r+=c;}return r+'"';
}
std::string message(const std::string& reason) {
    if(reason.find("unsupported")!=std::string::npos) return "Nepalaikoma darbo arba ataskaitos versija. Balas neskiriamas.";
    if(reason=="variant_parameters_mismatch") return "Ataskaitos parametrai neatitinka priskirto variantų banko.";
    if(reason=="unsupported_file") return "Reikalinga stendo sukurta HTML ataskaita. Šio failo formatas nepalaikomas.";
    if(reason=="file_type") return "Simbolinės nuorodos ir specialūs failai neskaitomi.";
    return "Ataskaitos duomenys netinkami arba nepilni. Patikrinkite failą; jis nevertinamas nuliu.";
}
class Batch {
    fs::path input,output;std::vector<fs::path> files;size_t cursor=0;
    Json results=Json::array();std::map<std::string,std::vector<size_t>> ids;
    std::map<std::string,Json> canonical;bool cancelled=false;
public:
    Batch(fs::path in,fs::path out):input(fs::absolute(in).lexically_normal()),output(fs::absolute(out).lexically_normal()) {
        if(!fs::is_directory(input)||fs::is_symlink(input)||fs::exists(output)) throw std::runtime_error("batch_paths");
        // Take the input inventory before creating the output directory. No student
        // file is modified. Symlink directories are included as review entries.
        for(fs::recursive_directory_iterator it(input),end;it!=end;++it) {
            if(it->is_directory()) {
                const auto name=it->path().filename().u8string();
                if(name.rfind("Vertinimai-",0)==0) {it.disable_recursion_pending();continue;}
            }
            if(fs::is_symlink(it->symlink_status())) {it.disable_recursion_pending();files.push_back(it->path());}
            else if(!it->is_directory()) files.push_back(it->path());
            if(files.size()>10000) throw std::runtime_error("batch_file_limit");
        }
        std::sort(files.begin(),files.end());
        if(!fs::create_directory(output)) throw std::runtime_error("output_directory");
        checkpoint();
    }
    void checkpoint() {
        Json state={{"core_version","0.3.0"},{"complete",cursor==files.size()&&!cancelled},{"cancelled",cancelled},
                    {"processed",cursor},{"total",files.size()},{"results",results}};
        Json pending=Json::array();for(size_t k=cursor;k<files.size();++k) pending.push_back(files[k].lexically_relative(input).generic_u8string());
        state["unprocessed"]=pending;
        atomic_write(output/"vertinimai.json",state.dump(2),true);
    }
    void next() {
        size_t end=std::min(cursor+25,files.size());
        for(;cursor<end;++cursor) {
            const auto& path=files[cursor];Json verdict;
            try {
                auto ext=path.extension().u8string();std::transform(ext.begin(),ext.end(),ext.begin(),[](unsigned char c){return static_cast<char>(std::tolower(c));});
                if(ext!=".html" && ext!=".htm") throw std::runtime_error("unsupported_file");
                auto report=read_report(path);verdict=grade(report);
                auto id=verdict.at("submission_id").get<std::string>();
                auto& group=ids[id];
                if(!group.empty()) {
                    bool same=canonical.at(id)==report;
                    if(!same || results[group.front()].at("status")=="conflict") {
                        for(auto index:group) {results[index]["status"]="conflict";results[index]["grade_10"]=nullptr;results[index]["comment"]="Tas pats ataskaitos ID turi skirtingus duomenis. Automatinis balas sustabdytas.";}
                        verdict["status"]="conflict";verdict["grade_10"]=nullptr;verdict["comment"]="Tas pats ataskaitos ID turi skirtingus duomenis.";
                    } else {verdict["status"]="duplicate";verdict["grade_10"]=nullptr;verdict["comment"]="Tiksli jau nuskaitytos ataskaitos kopija; antrą kartą neįskaitoma.";}
                } else canonical[id]=report;
                group.push_back(results.size());
            } catch(const std::exception& e) {
                std::string reason=e.what();if(reason.find("[json.exception")!=std::string::npos) reason="invalid_schema";
                verdict={{"status","review"},{"grade_10",nullptr},{"reason",reason},{"comment",message(reason)}};
            }
            // lexical_relative does not resolve symlink targets outside the input.
            verdict["file"]=path.lexically_relative(input).generic_u8string();results.push_back(verdict);
        }
        checkpoint();
    }
    bool done() const {return cursor==files.size();}
    void progress(double* p) const {
        p[0]=static_cast<double>(cursor);p[1]=static_cast<double>(files.size());p[2]=p[3]=0;
        for(auto& r:results) {if(r.at("status")=="graded") ++p[2];if(r.at("status")=="review"||r.at("status")=="conflict") ++p[3];}
    }
    void finish(bool cancel=false) {
        cancelled=cancel;
        // Keep every attempt visible. Choose the highest-scoring valid submission
        // for each reported name/group/lab; ties use lexically first input path.
        std::map<std::string,size_t> selected;
        for(size_t i=0;i<results.size();++i) {
            auto& r=results[i];if(r.at("status")!="graded"||r.at("mode")=="learning"||r.value("practice_used",false)) continue;
            auto key=Json::array({r.at("student"),r.at("lab_id")}).dump();auto it=selected.find(key);
            if(it==selected.end()) selected[key]=i;
            else if(r.at("grade_10").get<double>()>results[it->second].at("grade_10").get<double>()) it->second=i;
        }
        for(auto& r:results) r["selected_for_summary"]=false;
        for(auto& p:selected) results[p.second]["selected_for_summary"]=true;
        checkpoint();
        std::string table="\xef\xbb\xbf" "Failas;Statusas;Studentas;Grupė;Darbas;Variantas;Balai;Iš;Įvertinimas_10;Suvestinei;Komentaras\r\n";
        std::string html="<!doctype html><html lang=\"lt\"><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width\"><title>Laboratorinių vertinimas</title><style>body{font:16px system-ui;max-width:1100px;margin:2rem auto;padding:1rem}table{border-collapse:collapse;width:100%}th,td{text-align:left;padding:.5rem;border-bottom:1px solid #ddd}.bad{color:#963e16}details{margin:1rem 0}pre{white-space:pre-wrap}</style><h1>Laboratorinių darbų vertinimas</h1>";
        html+="<p>Nuskaityta "+std::to_string(cursor)+" iš "+std::to_string(files.size())+" failų. "+(cancelled?"Vertinimas sustabdytas.":"Vertinimas baigtas.")+"</p><p>Rubrika: LD1-1 / LD1-2 / LD2-1 / LD3-1 / LD4-1 / LD5-1 / LD6-1 / LD6-2 / LD7-1 / LD8-1 / LD9-1 / LD10-1 / LD11-1 / LD12-1. Balas = 10 × surinkti taškai / visi taškai; apvalinama iki 0,1. Suvestinei parenkamas geriausias to paties studento to paties darbo bandymas. Mokymosi bandymai ir darbai su naudota mokymosi pagalba į pažymių suvestinę neįtraukiami. Visi bandymai pateikti žemiau.</p>";
        for(auto& r:results) {
            auto get=[&](const char* k) {return r.contains(k)&&!r.at(k).is_null()?(r.at(k).is_string()?r.at(k).get<std::string>():r.at(k).dump()):"";};
            std::string name,group;if(r.contains("student")){name=r["student"]["name"];group=r["student"]["group"];}
            std::vector<std::string> row={get("file"),get("status"),name,group,get("lab_id"),get("variant"),get("points"),get("max_points"),get("grade_10"),get("selected_for_summary"),get("comment")};
            for(size_t k=0;k<row.size();++k) {if(k) table+=';';table+=csv(row[k]);}table+="\r\n";
            html+="<details><summary>"+html_escape(get("file"))+" · "+html_escape(name)+" · "+html_escape(get("status"))+" · "+html_escape(get("grade_10"))+"</summary>";
            if(r.value("practice_used",false)||r.value("mode",std::string{})=="learning") html+="<p>Mokymosi bandymas: į galutinę pažymių suvestinę neįtrauktas.</p>";
            if(r.contains("comment")) html+="<p>"+html_escape(get("comment"))+"</p>";
            if(r.contains("items")) {
                html+="<table><tr><th>Užduotis</th><th>Balai</th><th>Atsakymas / etalonas</th><th>Komentaras</th></tr>";
                for(auto& item:r["items"]) {
                    std::string given=item.contains("raw")?item["raw"].get<std::string>():item.value("given",Json(nullptr)).dump();
                    std::string expected=item.value("expected",Json(nullptr)).dump();
                    html+="<tr><td>"+html_escape(item["label"])+"</td><td>"+item["points"].dump()+" / "+item["max_points"].dump()+"</td><td>"+html_escape(given)+" / "+html_escape(expected)+" "+html_escape(item.value("unit",std::string{}))+"</td><td>"+html_escape(item["comment"])+"</td></tr>";
                }html+="</table><p>"+html_escape(get("note_policy"))+"</p><pre>"+html_escape(get("note"))+"</pre>";
            }html+="</details>";
        }
        html+="</html>";
        atomic_write(output/"suvestine.csv",table,true);atomic_write(output/"vertinimai.html",html,true);
    }
};
std::mutex batch_mutex;std::unique_ptr<Batch> current_batch;
std::string bytes(const int* p,const int* n,int max,bool allow_zero=false) {
    if(!n || *n<1 || *n>max || !p) throw std::runtime_error("bytes_length");
    std::string s;s.reserve(*n);for(int k=0;k<*n;++k) {if(p[k]<(allow_zero?0:1)||p[k]>255) throw std::runtime_error("bytes_value");s+=static_cast<char>(p[k]);}return s;
}
} // namespace
void write_new(const fs::path& path,const std::string& contents) {atomic_write(fs::absolute(path),contents,false);}
int run_batch(const fs::path& input,const fs::path& output) {
    Batch batch(input,output);while(!batch.done()) {batch.next();double p[4];batch.progress(p);std::cout<<p[0]<<" / "<<p[1]<<"\n";}
    batch.finish();return 0;
}
} // namespace ld
LD_API void ld_write_new(const int* p,const int* np,const int* b,const int* nb,int* status) noexcept {
    if(!status) return;
    *status=-1;
    try {ld::write_new(fs::u8path(ld::bytes(p,np,32768)),ld::bytes(b,nb,16*1024*1024,true));*status=0;}catch(...) {}
}
LD_API void ld_batch(const int* cmd,const int* in,const int* ni,const int* out,const int* no,double* progress,int* status) noexcept {
    if(!status) return;
    *status=-1;if(!cmd||!progress) return;
    std::lock_guard<std::mutex> lock(ld::batch_mutex);
    try {
        if(*cmd==1) {
            if(ld::current_batch) throw std::runtime_error("batch_busy");
            ld::current_batch=std::make_unique<ld::Batch>(fs::u8path(ld::bytes(in,ni,32768)),fs::u8path(ld::bytes(out,no,32768)));
        } else if(!ld::current_batch) throw std::runtime_error("no_batch");
        if(*cmd==2) ld::current_batch->next();
        if(*cmd==3 || *cmd==4) ld::current_batch->finish(*cmd==3);
        ld::current_batch->progress(progress);*status=ld::current_batch->done()?1:0;
        if(*cmd==3 || *cmd==4) ld::current_batch.reset();
    } catch(...) {ld::current_batch.reset();*status=-1;}
}
