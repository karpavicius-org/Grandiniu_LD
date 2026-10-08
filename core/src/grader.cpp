#include "grader.hpp"
#include <algorithm>
#include <cmath>
#include <fstream>
#include <locale>
#include <map>
#include <regex>
#include <set>
#include <sstream>
#include <stdexcept>
namespace ld {
namespace {
void require(bool ok,const char* reason) {if(!ok) throw std::runtime_error(reason);}
double number(const Json& j) {
    require(j.is_number(),"expected_number");
    double x=j.get<double>(); require(std::isfinite(x),"non_finite"); return x;
}
std::string text(const Json& j,size_t limit=256) {
    require(j.is_string(),"expected_text"); auto s=j.get<std::string>();
    require(s.size()<=limit && s.find('\0')==std::string::npos,"text_limit"); return s;
}
bool parse_number(std::string s,double& x) {
    auto a=s.find_first_not_of(" \t\r\n"),b=s.find_last_not_of(" \t\r\n");
    if(a==std::string::npos || s.size()>128) return false;
    s=s.substr(a,b-a+1);
    for(char& c:s) {if(c==',') c='.'; if(c=='d'||c=='D') c='e';}
    static const std::regex grammar(R"([+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?)");
    if(!std::regex_match(s,grammar)) return false;
    std::istringstream in(s); in.imbue(std::locale::classic()); in>>x;
    return bool(in) && in.eof() && std::isfinite(x);
}
bool near(double a,double b,double rel=.015,double abs=.005) {
    return std::isfinite(a) && std::isfinite(b) && std::abs(a-b)<=abs+rel*std::abs(b);
}
using Index=std::map<std::string,Json>;
Index index(const Json& array) {
    require(array.is_array() && array.size()<=256,"array_limit"); Index result;
    for(const auto& a:array) {
        std::string id=text(a.at("id"));
        require(result.emplace(id,a).second,"duplicate_item_id");
    }
    return result;
}
struct Grader {
    Json items=Json::array(); Index answers,observations; std::set<std::string> used_answers,used_observations;
    explicit Grader(const Json& r):answers(index(r.at("answers"))),observations(index(r.at("observations"))) {}
    void add(const std::string& id,const std::string& label,bool ok,const std::string& comment,const std::string& status="") {
        items.push_back({{"id",id},{"label",label},{"points",ok?1:0},{"max_points",1},
                         {"status",status.empty()?(ok?"correct":"incorrect"):status},{"comment",ok?"Teisingai.":comment}});
    }
    void answer(const std::string& id,const std::string& label,double expected,const std::string& unit,
                const std::string& hint,double rel=.015,double abs=.005) {
        used_answers.insert(id);
        auto it=answers.find(id); std::string raw; bool missing=it==answers.end();
        if(!missing) {require(text(it->second.at("unit"))==unit,"answer_unit"); raw=text(it->second.at("raw"),2048); missing=raw.find_first_not_of(" \t\r\n")==std::string::npos;}
        double value=0; bool parsed=!missing && parse_number(raw,value),ok=parsed&&near(value,expected,rel,abs);
        std::string comment=missing?"Atsakymas neįvestas.":(!parsed?"Įrašas nėra baigtinis skaičius. Įveskite skaičių be formulės ir vieneto.":hint);
        if(parsed && !ok && expected!=0 && (near(value,expected*1000,rel,abs)||near(value,expected/1000,rel,abs)))
            comment+=" Patikrinkite vienetus: atsakymas skiriasi maždaug 1000 kartų.";
        add(id,label,ok,comment,missing?"missing":(!parsed?"invalid":""));
        auto& item=items.back(); item["raw"]=raw; item["unit"]=unit; item["expected"]=expected;
        item["tolerance"]={{"absolute",abs},{"relative",rel}};
        item["given"]=parsed?Json(value):Json(nullptr);
    }
    double observation(const std::string& id,const std::string& unit) {
        used_observations.insert(id); auto it=observations.find(id);
        if(it==observations.end()) return NAN;
        require(text(it->second.at("unit"))==unit,"observation_unit");
        if(it->second.at("value").is_null()) return NAN;
        return number(it->second.at("value"));
    }
    double measured(const std::string& id,const std::string& label,double expected,const std::string& unit,double rel=.02,double abs=.005) {
        double v=observation(id,unit);
        add(id,label,near(v,expected,rel,abs),std::isnan(v)?"Matavimas neužfiksuotas.":"Matavimas neatitinka priskirtos grandinės. Patikrinkite dažnį, zondus ir vienetus.",std::isnan(v)?"missing":"");
        items.back()["expected"]=expected; items.back()["given"]=std::isnan(v)?Json(nullptr):Json(v); items.back()["unit"]=unit;
        return v;
    }
    void finish() {
        for(auto& a:answers) require(used_answers.count(a.first)!=0,"unknown_answer_id");
        for(auto& a:observations) require(used_observations.count(a.first)!=0,"unknown_observation_id");
    }
};
using Pairs=std::vector<std::pair<std::string,std::string>>;
Pairs pairs(const Json& j) {
    require(j.is_array() && j.size()<=128,"wiring_limit"); Pairs r;
    for(const auto& p:j) {require(p.is_array() && p.size()==2,"wire_pair");r.emplace_back(text(p[0]),text(p[1]));}
    return r;
}
bool contains(const Pairs& p,const std::string& a,const std::string& b) {
    return std::any_of(p.begin(),p.end(),[&](const auto& e){return (e.first==a&&e.second==b)||(e.second==a&&e.first==b);});
}
bool ld2_wiring(const Json& j,const std::string& phase) {
    auto p=pairs(j); std::string first=phase=="RC"?"R8":phase=="RL"?"R9":"C4";
    std::string second=phase=="RC"?"C2":phase=="RL"?"L1":"L3";
    Pairs req={{"GEN_H","AM_H"},{"AM_L",first+"_1"},{first+"_2",second+"_1"},
               {phase=="RLC"?"R13_2":second+"_2","GEN_L"}};
    if(phase=="RLC") req.emplace_back("L3_2","R13_1");
    for(auto& e:req) if(!contains(p,e.first,e.second)) return false;
    // Only the two removable voltmeter probes may accompany the main circuit.
    std::set<std::pair<std::string,std::string>> unique;
    int high=0,low=0;
    for(auto e:p) {
        if(e.first>e.second) std::swap(e.first,e.second);
        if(!unique.insert(e).second || e.first==e.second) return false;
        if(contains(req,e.first,e.second)) continue;
        if(e.first=="VM_H" || e.second=="VM_H") ++high;
        else if(e.first=="VM_L" || e.second=="VM_L") ++low;
        else return false;
    }
    return high<=1 && low<=1;
}
struct Nodes {
    std::map<std::string,std::string> parent;
    std::string root(const std::string& a) {auto it=parent.emplace(a,a).first; return it->second==a?a:root(it->second);}
    void join(const std::string& a,const std::string& b) {auto x=root(a),y=root(b);parent[x]=y;}
};
bool ld1_wiring(const Json& j,bool series) {
    auto p=pairs(j.at("pairs")); if(p.size()!=(series?4u:9u) || text(j.at("meter"))!=(series?"A":"V")) return false;
    std::set<std::string> allowed={"SRC_P","SRC_N","M_P","M_N","VR1_1","VR1_2"};
    for(auto r:series?std::vector<std::string>{"R1"}:std::vector<std::string>{"R2","R3"}) {allowed.insert(r+"_1");allowed.insert(r+"_2");}
    Nodes nodes;
    if(!series) for(int i=1;i<=4;++i) for(auto c:{"A","B"}) {
        std::string id="NODE_"+std::string(c)+std::to_string(i);allowed.insert(id);nodes.join(id,"NODE_"+std::string(c)+"1");
    }
    std::set<std::pair<std::string,std::string>> seen;
    for(auto e:p) {
        if(!allowed.count(e.first)||!allowed.count(e.second)||e.first==e.second) return false;
        if(e.first>e.second) std::swap(e.first,e.second);
        if(!seen.insert(e).second) return false;
        nodes.join(e.first,e.second);
    }
    auto pair=[&](std::string a,std::string b) {return std::make_pair(nodes.root(a),nodes.root(b));};
    auto src=pair("SRC_P","SRC_N"); if(src.first==src.second) return false;
    if(series) {
        std::map<std::string,int> degree; Nodes connected;
        for(auto e:Pairs{src,pair("M_P","M_N"),pair("R1_1","R1_2"),pair("VR1_1","VR1_2")}) {
            if(e.first==e.second) return false;
            ++degree[e.first];++degree[e.second];connected.join(e.first,e.second);
        }
        if(degree.size()!=4) return false;
        for(auto& d:degree) if(d.second!=2||connected.root(d.first)!=connected.root(src.first)) return false;
        return true;
    }
    auto equal=[](auto a,auto b){return a==b || (a.first==b.second && a.second==b.first);};
    if(!equal(pair("M_P","M_N"),src)||!equal(pair("R3_1","R3_2"),src)) return false;
    auto a=pair("R2_1","R2_2"),b=pair("VR1_1","VR1_2");
    for(int i=0;i<2;++i) {std::swap(a.first,a.second);for(int k=0;k<2;++k) {
        std::swap(b.first,b.second);
        if(a.first!=a.second && b.first!=b.second && a.second==b.first && equal(std::make_pair(a.first,b.second),src)) return true;
    }} return false;
}
void parameters(const Json& r,const Json& expected) {
    const auto& p=r.at("parameters"); require(p.is_object()&&p.size()==expected.size(),"parameters_shape");
    for(auto it=expected.begin();it!=expected.end();++it)
        require(near(number(p.at(it.key())),number(it.value()),1e-12,1e-15),"variant_parameters_mismatch");
}
void grade_dc(Grader& g,const Json& r,const Bank& b) {
    parameters(r,{{"E",10},{"R1",b.r1},{"R2",b.r2},{"R3",b.r3}});
    double i=10000/(b.r1+1000),j=10000/(b.r1+500),i1=10000/b.r3,i2=10000/b.r2;
    g.answer("s2.q1","2 etapas (nuoseklioji, VR1 = 1000 Ω): bendroji varža Rb = R1 + VR1",b.r1+1000,"Ohm","Rb = R1 + 1000 Ω.",.01,1e-9);
    g.answer("s2.q2","2 etapas (nuoseklioji, VR1 = 1000 Ω): srovė I = E / Rb",i,"mA","I = 10 / Rb × 1000 mA.",.01,1e-9);
    g.answer("s4.q1","4 etapas (nuoseklioji, VR1 = 500 Ω): bendroji varža Rb = R1 + VR1",b.r1+500,"Ohm","Rb = R1 + 500 Ω.",.01,1e-9);
    g.answer("s4.q2","4 etapas (nuoseklioji, VR1 = 500 Ω): srovė I = E / Rb",j,"mA","I = 10 / Rb × 1000 mA.",.01,1e-9);
    g.answer("s6.q1","6 etapas (lygiagretė): ekvivalentinė varža RAB = R3 ∥ (R2 + VR1)",b.r3*(b.r2+1000)/(b.r3+b.r2+1000),"Ohm","Rb = R3 × (R2+1000) / (R3+R2+1000).",.01,1e-9);
    const char* kcl[]={"8 etapas (KSD): srovė I1 per R3 šaką",
                       "8 etapas (KSD): srovė I2 per R2 + VR1 šaką (VR1 = 0)",
                       "8 etapas (KSD): bendroji srovė I = I1 + I2 prieš mazgą A"};
    int w=0;
    for(auto q:std::vector<std::pair<std::string,double>>{{"s8.q1",i1},{"s8.q2",i2},{"s8.q3",i1+i2}})
        g.answer(q.first,kcl[w++],q.second,"mA","I1=10/R3×1000; I2=10/R2×1000; I=I1+I2.",.01,1e-9);
    g.answer("s1.type","1 etapas (nuoseklioji): grandinės tipo apibrėžimas",1,"choice","1 – nuosekli; 2 – lygiagreti; 3 – mišri.",0,0);
    g.answer("s5.type","5 etapas (lygiagretė): grandinės tipo apibrėžimas",2,"choice","R3 ir R2+VR1 sudaro lygiagrečias šakas.",0,0);
    double base=g.measured("s6.measure","6 etapas (lygiagretė): įtampa tarp mazgų A–B, UAB",10,"V",.05);
    const std::map<int,std::string> meas_label={{3,"3 etapas (nuoseklioji, VR1 = 1000 Ω): srovės I matavimas ampermetru"},
        {4,"4 etapas (nuoseklioji, VR1 = 500 Ω): srovės I matavimas ampermetru"},
        {7,"7 etapas (lygiagretė): įtampos UAB matavimas pakeitus VR1"},
        {8,"8 etapas (KSD): bendrosios srovės I matavimas ampermetru"}};
    const std::map<int,std::string> comp_label={{3,"3 etapas: išvada — ar skaičiuota srovė I sutampa su išmatuota (±5 %)"},
        {4,"4 etapas: išvada — ar srovė I (VR1 = 500 Ω) sutampa su matavimu"},
        {6,"6 etapas: išvada — ar UAB lygi šaltinio įtampai E"},
        {7,"7 etapas: išvada — ar UAB pasikeitė pakeitus VR1"},
        {8,"8 etapas: išvada — ar I = I1 + I2 patvirtina Kirchhofo srovės dėsnį"}};
    for(auto p:std::vector<std::pair<int,double>>{{3,i},{4,j},{6,10},{7,10},{8,i1+i2}}) {
        int step=p.first; auto id="s"+std::to_string(step);
        double v=step==6?base:g.measured(id+".measure",meas_label.at(step),p.second,step==7?"V":"mA",.05);
        double ref=p.second;
        // Comparison is against the student's calculation where the bench asks
        // for it; a wrong calculation loses its own point, not this reasoning point.
        if(step==3 || step==4) {
            auto it=g.answers.find(step==3?"s2.q2":"s4.q2");double own=0;
            if(it!=g.answers.end() && parse_number(text(it->second.at("raw"),2048),own)&&own>0) ref=own;
        }
        if(step==8) {
            auto a=g.answers.find("s8.q1"),second=g.answers.find("s8.q2");double x=0,y=0;
            if(a!=g.answers.end() && second!=g.answers.end() &&
               parse_number(text(a->second.at("raw"),2048),x) &&
               parse_number(text(second->second.at("raw"),2048),y) && x+y>0) ref=x+y;
        }
        if(step==7 && std::isfinite(base)) ref=base;
        bool match=near(v,ref,.05,0);
        double expected=step==7?(match?2:1):(match?1:2);
        g.answer(id+".compare",comp_label.at(step),expected,"choice","Palyginkite užfiksuotas reikšmes: 5 % riba; 1 – Taip, 2 – Ne.",0,0);
        if(!std::isfinite(v)) {g.items.back()["points"]=0;g.items.back()["status"]="missing_evidence";g.items.back()["comment"]="Palyginimui trūksta matavimo.";}
    }
    const std::map<int,std::string> wire_label={{1,"1 etapas (nuoseklioji): stendo sujungimas — šaltinis → R1 → VR1 → ampermetras"},
        {5,"5 etapas (lygiagretė): stendo sujungimas — dvi šakos tarp mazgų A ir B"}};
    for(int s:{1,5}) g.add("s"+std::to_string(s)+".wiring",wire_label.at(s),
        ld1_wiring(r.at("evidence").at("wiring").at("s"+std::to_string(s)),s==1),
        "Patikrinkite šaltinio, rezistorių ir matuoklio sujungimą. Vertinama išsaugota topologija.");
}
// LD1-3 evaluates manual wiring and seven interpretations of recorded readings.
// Solver observations remain visible diagnostics, never student-earned points.
void grade_dc_measurement(Grader& g,const Json& r,const Bank& b) {
    parameters(r,{{"E",10},{"R1",b.r1},{"R2",b.r2},{"R3",b.r3}});
    const double i=10000/(b.r1+1000),j=10000/(b.r1+500),a=10000/b.r3,c=10000/b.r2;
    const auto measured=[&](const std::string& id,const std::string& label,double expected,const std::string& unit) {
        double value=g.measured(id,label,expected,unit,.05);
        auto& item=g.items.back();item["points"]=0;item["max_points"]=0;item["automatic"]=true;
        item["comment"]="Programos užfiksuotas matavimo duomuo; balų neskiriama. "+item.at("comment").get<std::string>();
        return value;
    };
    const double baseline=measured("s3.measure","3 etapas: ampermetro srovė prieš keičiant VR1",i,"mA");
    const double after=measured("s4.measure","4 etapas: ampermetro srovė po VR1 = 500 Ω",j,"mA");
    const double voltage=measured("s6.measure","6 etapas: voltmetro įtampa tarp A ir B",10,"V");
    const double voltage_after=measured("s7.measure","7 etapas: voltmetro įtampa po VR1 = 500 Ω",10,"V");
    const double total=measured("s8.measure","8 etapas: ampermetro bendroji srovė",a+c,"mA");
    const double r1=measured("s3.r1","3 etapas: automatinio matavimo taško srovė per R1",i,"mA");
    const double vr1=measured("s3.vr1","3 etapas: automatinio matavimo taško srovė per VR1",i,"mA");
    const double r3=measured("s8.r3","8 etapas: automatinio matavimo taško srovė R3 šakoje",a,"mA");
    const double r2=measured("s8.r2","8 etapas: automatinio matavimo taško srovė R2 + VR1 šakoje",c,"mA");
    g.answer("s1.type","1 etapas: kaip sujungti R1 ir VR1",1,"choice","Rezistoriai vienoje šakoje sujungti nuosekliai.",0,0);
    g.answer("s5.type","5 etapas: kaip tarpusavyje sujungtos dvi šakos",2,"choice","Abi šakos prijungtos tarp tų pačių mazgų A ir B.",0,0);
    const auto choice=[&](const std::string& id,const std::string& label,double expected,bool available,const std::string& hint) {
        g.answer(id,label,expected,"choice",hint,0,0);
        if(!available) {auto& item=g.items.back();item["points"]=0;item["status"]="missing_evidence";item["comment"]="Išvadai patikrinti trūksta užfiksuotų matavimų.";}
    };
    const auto same=[](double x,double y){return near(x,y,.05,0);};
    const auto direction=[&](double x,double y){return same(x,y)?3:(y>x?1:2);};
    choice("s3.compare","3 etapas: ar srovės per R1 ir VR1 vienodos",same(r1,vr1)?1:2,std::isfinite(r1)&&std::isfinite(vr1),"Palyginkite du srovės rodmenis: 1 – Taip, 2 – Ne.");
    choice("s4.change","4 etapas: kaip pasikeitė srovė sumažinus VR1",direction(baseline,after),std::isfinite(baseline)&&std::isfinite(after),"Palyginkite Prieš ir Po: 1 – padidėjo, 2 – sumažėjo, 3 – nepakito.");
    choice("s6.compare","6 etapas: ar UAB sutampa su šaltinio įtampa",same(voltage,10)?1:2,std::isfinite(voltage),"Palyginkite šaltinio ir voltmetro įtampas: 1 – Taip, 2 – Ne.");
    choice("s7.change","7 etapas: kaip pasikeitė įtampa pakeitus VR1",direction(voltage,voltage_after),std::isfinite(voltage)&&std::isfinite(voltage_after),"Palyginkite Prieš ir Po: 1 – padidėjo, 2 – sumažėjo, 3 – nepakito.");
    choice("s8.compare","8 etapas: ar bendroji srovė lygi dviejų šakų srovių sumai",same(total,r3+r2)?1:2,std::isfinite(total)&&std::isfinite(r3)&&std::isfinite(r2),"Palyginkite ampermetro srovę ir programos pateiktą šakų sumą: 1 – Taip, 2 – Ne.");
    for(int step:{1,5}) {
        g.add("s"+std::to_string(step)+".wiring",step==1?"1 etapas: studento sujungta vienos šakos grandinė":"5 etapas: studento sujungtos dvi šakos tarp A ir B",
              ld1_wiring(r.at("evidence").at("wiring").at("s"+std::to_string(step)),step==1),"Patikrinkite išsaugotą grandinės topologiją.");
        if(r.at("evidence").value("automatic_setup",false)) {
            auto& item=g.items.back();item["points"]=0;item["max_points"]=0;item["automatic"]=true;
            item["comment"]="Mokymosi režime grandinę paruošė programa; už jungimą balų neskiriama.";
        }
    }
}
struct Point {double f,u;};
std::vector<Point> points(const Json& rows,const Bank& b,const std::string& target,bool& valid) {
    require(rows.is_array()&&rows.size()<=2048,"points_limit"); std::vector<Point> p; std::set<double> seen;
    for(auto& row:rows) {
        if(row.contains("target") && text(row.at("target"))!=target) continue;
        double f=number(row.at("f")),u=number(row.at("u"));
        if(f<0 || f>10000 || !seen.insert(f).second) {valid=false;continue;}
        auto v=ac(3,5,f,b.r13,b.l3,b.c4); int idx=target=="UR"?4:target=="UL"?5:target=="UC"?6:7;
        if(!near(u,v[idx],.002,.005)) valid=false;
        p.push_back({f,u});
    } return p;
}
bool bracket(const std::vector<Point>& p,Point best) {
    bool lo=false,hi=false; for(auto v:p) {lo|=v.f<best.f;hi|=v.f>best.f;} return p.size()>=3 && lo&&hi;
}
Point best_point(const std::vector<Point>& p,bool minimum=false) {
    Point best{NAN,NAN};for(auto v:p) if(std::isnan(best.u)||(minimum?v.u<best.u:v.u>best.u)) best=v; return best;
}
void dependent(Grader& g,const std::string& id,const std::string& label,double ref,const std::string& unit,bool valid,double rel=.015) {
    g.answer(id,label,std::isfinite(ref)?ref:0,unit,"Atsakymą apskaičiuokite iš savo užfiksuotų matavimo taškų.",rel);
    if(!valid || !std::isfinite(ref)) {
        g.items.back()["points"]=0;g.items.back()["status"]="missing_evidence";g.items.back()["expected"]=nullptr;
        g.items.back()["comment"]="Trūksta tinkamų matavimo taškų. Pirmiausia atlikite ir užfiksuokite bandymą.";
    }
}
void grade_ac(Grader& g,const Json& r,const Bank& b) {
    parameters(r,{{"E_RC",9},{"F_RC",b.frc},{"R8",b.r8},{"C2",4.7e-6},{"E_RL",9},{"F_RL",b.frl},{"R9",b.r9},{"L1",.5},{"E_RLC",5},{"R13",b.r13},{"L3",b.l3},{"C4",b.c4}});
    for(int kind:{1,2}) {
        bool rc=kind==1;int s=rc?3:6;auto v=ac(kind,9,rc?b.frc:b.frl,rc?b.r8:b.r9,.5,4.7e-6);
        double refs[]={v[rc?1:0],v[2],v[3]*1000,v[4],v[rc?6:5],v[8]*1000,-v[9]};
        const char* units[]={"Ohm","Ohm","mA","V","V","mW","deg"};
        const char* labels[]={rc?"talpinė reaktyvioji varža XC = 1/(ωC)":"induktyvioji reaktyvioji varža XL = ωL",
            rc?"impedanso modulis |Z| = √(R8² + XC²)":"impedanso modulis |Z| = √(R9² + XL²)",
            "srovė I = E / |Z|",rc?"įtampa rezistoriuje UR8 = I·R8":"įtampa rezistoriuje UR9 = I·R9",
            rc?"įtampa kondensatoriuje UC2 = I·XC":"įtampa ritėje UL1 = I·XL",
            "aktyvioji galia P = I²·R","srovės fazė φI"};
        for(int q=0;q<7;++q) g.answer("s"+std::to_string(s)+".q"+std::to_string(q+1),std::to_string(s)+" etapas ("+(rc?"RC":"RL")+"): "+labels[q],refs[q],units[q],"Naudokite kompleksinį impedansą ir RMS dydžius. P=I²R; srovės fazė priešinga impedanso fazei.");
        std::string prefix=rc?"rc_":"rl_";
        std::string tag=std::to_string(s)+" etapas ("+(rc?"RC":"RL")+"): ";
        double mi=g.measured(prefix+"I",tag+"srovės I matavimas",v[3],"A",.002,5e-6);
        double ur=g.measured(prefix+"UR",tag+"įtampa rezistoriuje "+(rc?"UR8":"UR9")+" matavimas",v[4],"V"),
             ux=g.measured(prefix+(rc?"UC":"UL"),tag+"įtampa "+(rc?"kondensatoriuje UC2":"ritėje UL1")+" matavimas",v[rc?6:5],"V");
        double ue=g.measured(prefix+"UE",tag+"šaltinio įtampa E matavimas",9,"V");
        bool valid=std::isfinite(mi)&&std::isfinite(ur)&&std::isfinite(ux)&&std::isfinite(ue);
        dependent(g,"s"+std::to_string(s+1)+".q1",std::to_string(s+1)+" etapas ("+(rc?"RC":"RL")+" patikra): įtampų vektorinė suma E = √(UR² + U"+(rc?"C2":"L1")+"²)",std::hypot(ur,ux),"V",valid);
        dependent(g,"s"+std::to_string(s+1)+".q2",std::to_string(s+1)+" etapas ("+(rc?"RC":"RL")+" patikra): srovė I = "+(rc?"UR8 / R8":"UR9 / R9"),ur/(rc?b.r8:b.r9)*1000,"mA",valid);
    }
    const auto& e=r.at("evidence");
    for(auto p:std::vector<std::pair<std::string,int>>{{"RC",2},{"RL",5},{"RLC",8}})
        g.add("s"+std::to_string(p.second)+".wiring",std::to_string(p.second)+" etapas ("+p.first+"): stendo sujungimas",ld2_wiring(e.at("wiring").at(p.first),p.first),"Trūksta pagrindinės grandinės jungčių arba yra papildomų netinkamų laidų.");
    double f0=1/(2*std::acos(-1.0)*std::sqrt(b.l3*b.c4));
    bool valid=true;auto rp=points(e.at("resonance"),b,"UR",valid);auto best=best_point(rp);
    bool resonance=valid&&bracket(rp,best)&&best.u>=.97*5;
    g.add("s9.experiment","9 etapas (RLC rezonansas): dažnio paieškos taškai abipus maksimumo",resonance,"Užfiksuokite bent 3 dažnius abipus UR maksimumo; maksimumas turi siekti bent 97 % E.");
    g.answer("s9.q1","9 etapas: teorinis rezonanso dažnis f0 = 1/(2π√(LC))",f0,"Hz","f0=1/(2π√(LC)).",.005);
    dependent(g,"s9.q2","9 etapas: rezonanso dažnis fr ties UR13 maksimumu",best.f,"Hz",resonance,.0002);
    dependent(g,"s9.q3","9 etapas: periodas T = 1000 / fr",1000/best.f,"ms",resonance,.01);
    dependent(g,"s9.q4","9 etapas: UR13 maksimumas rezonanso dažnyje",best.u,"V",resonance);
    int q=1;
    for(auto target:{"UL","UC","ULC"}) {
        valid=true;auto pp=points(e.at("peaks"),b,target,valid);auto bp=best_point(pp,std::string(target)=="ULC");
        bool ok=valid&&bracket(pp,bp)&&(std::string(target)!="ULC"||bp.u<=.5);
        g.add("s10.experiment."+std::string(target),"10 etapas (RLC): "+std::string(target)+" ekstremumo paieška",ok,"Reikia trijų skirtingų dažnių abipus ekstremumo ir modelį atitinkančių rodmenų.");
        dependent(g,"s10.q"+std::to_string(q),"10 etapas: "+std::string(target)+" ekstremumo įtampa",bp.u,"V",ok);
        dependent(g,"s10.q"+std::to_string(q+3),"10 etapas: dažnis ties "+std::string(target)+" ekstremumu",bp.f,"Hz",ok,.0002);++q;
    }
    double f1=g.observation("f1_meas","Hz"),f2=g.observation("f2_meas","Hz"),u1=g.observation("f1_u","V"),u2=g.observation("f2_u","V");
    double threshold=(std::isfinite(best.u)?best.u:5)/std::sqrt(2.0);
    bool half=std::isfinite(f1)&&std::isfinite(f2)&&f1>0&&f1<f0&&f2>f0&&f2<=10000 &&
        near(u1,threshold,.0301,0)&&near(u2,threshold,.0301,0);
    if(half) half=near(u1,ac(3,5,f1,b.r13,b.l3,b.c4)[4],.002,.005)&&near(u2,ac(3,5,f2,b.r13,b.l3,b.c4)[4],.002,.005);
    g.add("s11.experiment","11 etapas (pusės galios): f1 ir f2 matavimai ties URmax/√2",half,"Išmatuokite f1 ir f2 skirtingose rezonanso pusėse, ties URmax/√2 slenksčiu (3 % paklaida).");
    double refs[]={threshold,f1,f2,f2-f1,(std::isfinite(best.f)?best.f:f0)/(f2-f1)};
    const char* units[]={"V","Hz","Hz","Hz","1"};double rel[]={.015,.0002,.0002,.02,.02};
        const char* half_labels[]={"11 etapas: UR13 slenkstis URmax/√2","11 etapas: žemutinis pusės galios dažnis f1",
        "11 etapas: viršutinis pusės galios dažnis f2","11 etapas: juostos plotis BW = f2 − f1",
        "11 etapas: kokybės faktorius Q = fr / BW"};
    for(int k=0;k<5;++k) dependent(g,"s11.q"+std::to_string(k+1),half_labels[k],refs[k],units[k],half,rel[k]);
    valid=true;auto sweep=points(e.at("sweep"),b,"UR",valid);bool sweep_ok=valid&&sweep.size()==11;
    for(int k=0;k<=10;++k) if(std::none_of(sweep.begin(),sweep.end(),[&](auto p){return p.f==k*1000;})) sweep_ok=false;
    g.add("s12.sweep","12 etapas (RLC): dažninė charakteristika 0–10 kHz (11 taškų)",sweep_ok,"Reikia 11 modelį atitinkančių matavimų: 0, 1000, …, 10000 Hz.");
}
// LD3: exactly the six canonical wires, order-insensitive, no duplicates or extras.
bool ld3_wiring(const Json& j,bool& valid) {
    try {
        const Json& list=j.is_array()?j:j.at("pairs");
        auto p=pairs(list);
        std::set<std::pair<std::string,std::string>> unique;
        for(auto& e:p) {
            if(e.first==e.second) return false;
            if(e.first>e.second) std::swap(e.first,e.second);
            if(!unique.insert(e).second) return false;
        }
        static const std::set<std::pair<std::string,std::string>> canonical={
            {"A_N","R1A"},{"A_P","K2"},{"E_N","R1B"},{"E_P","K1"},{"R1A","V_P"},{"R1B","V_N"}};
        return unique==canonical;
    } catch(const std::exception&) {valid=false;return false;}
}
bool ld4_wiring(const Json& pairs,int mode,bool& valid) {
    // mode: 1 = R1, 2 = R2, 3 = nuoseklus R1+R2.
    static const char* c1[][2]={{"E_P","K1"},{"K2","A_P"},{"A_N","R1A"},{"R1B","E_N"},{"V_P","R1A"},{"V_N","R1B"}};
    static const char* c2[][2]={{"E_P","K1"},{"K2","A_P"},{"A_N","R2A"},{"R2B","E_N"},{"V_P","R2A"},{"V_N","R2B"}};
    static const char* cs[][2]={{"E_P","K1"},{"K2","A_P"},{"A_N","R1A"},{"R1B","R2A"},{"R2B","E_N"},{"V_P","R1A"},{"V_N","R2B"}};
    const auto set=mode==1?c1:mode==2?c2:cs;const int n=mode==3?7:6;
    try {
        if(!pairs.is_array()) {valid=false;return false;}
        if(pairs.size()!=(size_t)n) return false;   // kito režimo laidų kiekis — ne klaida
        std::set<std::pair<std::string,std::string>> unique,canonical;
        for(int k=0;k<n;++k) canonical.insert({std::min(std::string(set[k][0]),std::string(set[k][1])),
                                               std::max(std::string(set[k][0]),std::string(set[k][1]))});
        for(auto& w:pairs) {
            if(!w.is_array() || w.size()!=2) {valid=false;return false;}
            const auto a=text(w.at(0)),b2=text(w.at(1));
            if(a.empty()||b2.empty()) {valid=false;return false;}
            if(!unique.insert({std::min(a,b2),std::max(a,b2)}).second) return false;  // dublis
        }
        return unique==canonical;
    } catch(const std::exception&) {valid=false;return false;}
}
void grade_ld4(Grader& g,const Json& r,const Bank& b) {
    parameters(r,{{"R1nom",b.r1n},{"R2nom",b.r2n},{"R1",b.r1a},{"R2",b.r2a},{"U1",b.u1},{"U2",b.u2},{"U3",b.u3}});
    const double uu[3]={b.u1,b.u2,b.u3};
    const double i1m[3]={b.u1/b.r1a*1000,b.u2/b.r1a*1000,b.u3/b.r1a*1000};
    const double i2m[3]={b.u1/b.r2a*1000,b.u2/b.r2a*1000,b.u3/b.r2a*1000};
    g.answer("s2.q1","2 etapas (teorinė prognozė): srovė I1 = U1 / R1nom",b.u1/b.r1n*1000,"mA","I1 = U1 / R1nom; mA = V / Ω × 1000.",.01,1e-9);
    double r1u[3],r1i[3],r2u[3],r2i[3];
    for(int k=0;k<3;++k) {
        auto s=std::to_string(k+1);
        r1u[k]=g.measured("r1u"+s,"2 etapas (R1 matavimas): įtampa U"+s+" voltmetru",uu[k],"V",0,.05);
        r1i[k]=g.measured("r1i"+s,"2 etapas (R1 matavimas): srovė I"+s+" ampermetru",i1m[k],"mA",.02);
        r2u[k]=g.measured("r2u"+s,"3 etapas (R2 matavimas): įtampa U"+s+" voltmetru",uu[k],"V",0,.05);
        r2i[k]=g.measured("r2i"+s,"3 etapas (R2 matavimas): srovė I"+s+" ampermetru",i2m[k],"mA",.02);
    }
    double su1=g.measured("su1","6 etapas (nuoseklus): įtampa U voltmetru",b.u3,"V",0,.05);
    double si1=g.measured("si1","6 etapas (nuoseklus): srovė I ampermetru",b.u3/(b.r1a+b.r2a)*1000,"mA",.02);
    auto calc=[&](double* u,double* i){double s=0;int n=0;for(int k=0;k<3;++k)if(std::isfinite(u[k])&&std::isfinite(i[k])&&i[k]!=0){s+=u[k]/i[k]*1000;++n;}return n==3?s/3:NAN;};
    const double r1v=calc(r1u,r1i),r2v=calc(r2u,r2i);
    dependent(g,"s4.q1","4 etapas (skaičiavimai): vidutinė R1m = U / I",r1v,"Ohm",std::isfinite(r1v),.02);
    dependent(g,"s4.q2","4 etapas (skaičiavimai): vidutinė R2m = U / I",r2v,"Ohm",std::isfinite(r2v),.02);
    dependent(g,"s4.q3","4 etapas (skaičiavimai): nuokrypa δ1 = (R1m / R1nom − 1) · 100 %",std::isfinite(r1v)?(r1v/b.r1n-1)*100:NAN,"1",std::isfinite(r1v),.05);
    dependent(g,"s4.q4","4 etapas (skaičiavimai): nuokrypa δ2 = (R2m / R2nom − 1) · 100 %",std::isfinite(r2v)?(r2v/b.r2n-1)*100:NAN,"1",std::isfinite(r2v),.05);
    auto slope=[&](double* u,double* i){return std::isfinite(u[0])&&std::isfinite(u[2])&&std::isfinite(i[0])&&std::isfinite(i[2])&&i[2]!=i[0]?(u[2]-u[0])/((i[2]-i[0])/1000):NAN;};
    const double s1v=slope(r1u,r1i),s2v=slope(r2u,r2i);
    dependent(g,"s5.q1","5 etapas (charakteristika): R1 iš I(U) nuolydžio",s1v,"Ohm",std::isfinite(s1v),.02);
    dependent(g,"s5.q2","5 etapas (charakteristika): R2 iš I(U) nuolydžio",s2v,"Ohm",std::isfinite(s2v),.02);
    dependent(g,"s5.q3","5 etapas (charakteristika): laidumas G2 = 1000 / R2",std::isfinite(s2v)?1000/s2v:NAN,"mS",std::isfinite(s2v),.02);
    dependent(g,"s6.q1","6 etapas (nuoseklus): Rs = U / I",std::isfinite(su1)&&std::isfinite(si1)&&si1!=0?su1/si1*1000:NAN,"Ohm",std::isfinite(su1)&&std::isfinite(si1),.02);
    g.answer("s7.q1","7 etapas (išvada): ar abiejų rezistorių I(U) tiesinės",1,"choice","1 – Taip, 2 – Ne.",0,0);
    g.answer("s7.q2","7 etapas (išvada): ar δ telpa ±5 % tolerancijos ribose",1,"choice","1 – Taip, 2 – Ne.",0,0);
    const auto& w=r.at("evidence").at("wiring");
    bool ok1=true,ok6=true;
    bool w1=ld4_wiring(w.at("s1").at("pairs"),1,ok1);
    bool w6=ld4_wiring(w.at("s6").at("pairs"),3,ok6);
    g.add("s1.wiring","1 etapas: faktiškai sujungta R1 matavimo grandinė",w1,
          "Trūksta teisingo R1 grandinės sujungimo įrodymo.",ok1?"":"missing_evidence");
    g.add("s6.wiring","6 etapas (nuoseklus): R1 ir R2 sujungti eilėje, voltmetras prijungtas per visą R1 + R2 porą",w6,
          ok6?"Nuosekliam jungimui R1 išėjimą sujunkite su R2 įėjimu; grąžinamąjį laidą junkite iš R2 į šaltinį; voltmetrą prijunkite prie visos R1 + R2 poros galų.":"Sujungimo įrodymo duomenys sugadinti.",ok6?"":"missing_evidence");
}
bool ld5_wiring(const Json& pairs,bool& valid) {
    static const char* cs[][2]={{"E_P","K1"},{"K2","A_P"},{"A_N","R1A"},{"R1B","RVA"},{"RVB","E_N"},{"V_P","RVA"},{"V_N","RVB"}};
    try {
        if(!pairs.is_array()) {valid=false;return false;}
        if(pairs.size()!=7) return false;
        std::set<std::pair<std::string,std::string>> unique,canonical;
        for(int k=0;k<7;++k) canonical.insert({std::min(std::string(cs[k][0]),std::string(cs[k][1])),
                                               std::max(std::string(cs[k][0]),std::string(cs[k][1]))});
        for(auto& w:pairs) {
            if(!w.is_array()||w.size()!=2) {valid=false;return false;}
            const auto a=text(w.at(0)),b2=text(w.at(1));
            if(a.empty()||b2.empty()) {valid=false;return false;}
            if(!unique.insert({std::min(a,b2),std::max(a,b2)}).second) return false;
        }
        return unique==canonical;
    } catch(const std::exception&) {valid=false;return false;}
}
void grade_ld5(Grader& g,const Json& r,const Bank& b) {
    parameters(r,{{"R1nom",b.r1n},{"RVnom",b.r2n},{"R1",b.r1a},{"RV",b.r2a},{"E",9},{"P1",b.p1},{"P2",b.p2},{"P3",b.p3}});
    auto rvd=[&](int k){return b.r2a*(k==1?b.p1:k==2?b.p2:b.p3)/100.0;};
    auto uk=[&](int k){return 9.0*rvd(k)/(b.r1a+rvd(k));};
    auto ik=[&](int k){return 9.0/(b.r1a+rvd(k))*1000;};
    g.answer("s2.q1","2 etapas (teorinė prognozė): išėjimo įtampa U2 = E·RVd/(R1+RVd)",uk(2),"V","U2 = E·RVd/(R1+RVd), padėtis 2.",.01,1e-9);
    for(int k=1;k<=3;++k) {
        g.measured("u"+std::to_string(k),std::to_string(k==2?2:3)+" etapas (matavimas): U"+std::to_string(k)+" voltmetru, padėtis "+std::to_string(k),uk(k),"V",0,.05);
        g.measured("i"+std::to_string(k),std::to_string(k==2?2:3)+" etapas (matavimas): I"+std::to_string(k)+" ampermetru, padėtis "+std::to_string(k),ik(k),"mA",.02);
    }
    g.answer("s4.q1","4 etapas (skaičiavimai): teorinė U1t = E·RVd1/(R1+RVd1)",uk(1),"V","Dalikio formulė.",.01,1e-9);
    g.answer("s4.q2","4 etapas (skaičiavimai): teorinė U3t = E·RVd3/(R1+RVd3)",uk(3),"V","Dalikio formulė.",.01,1e-9);
    g.answer("s4.q3","4 etapas (skaičiavimai): reguliavimo diapazonas ΔU = U3t − U1t",uk(3)-uk(1),"V","ΔU = U3t − U1t.",.02,1e-9);
    g.answer("s4.q4","4 etapas (skaičiavimai): diapazonas procentais nuo E",(uk(3)-uk(1))/9*100,"1","ΔU/E · 100 %.",.02,1e-9);
    g.answer("s5.q1","5 etapas (srovė): I2 = E/(R1+RVd2)",ik(2),"mA","I = E/(R1+RVd).",.02,1e-9);
    g.answer("s5.q2","5 etapas (dalis): RVd2/(R1+RVd2) · 100 %",rvd(2)/(b.r1a+rvd(2))*100,"1","Dalies santykis procentais.",.02,1e-9);
    g.answer("s6.q1","6 etapas (išvada): ar įtampa reguliuojama sklandžiai",1,"choice","1 – Taip, 2 – Ne.",0,0);
    g.answer("s6.q2","6 etapas (išvada): ar dalikio dėsnis galioja",1,"choice","1 – Taip, 2 – Ne.",0,0);
    bool ok1=true;
    bool w1=ld5_wiring(r.at("evidence").at("wiring").at("s1").at("pairs"),ok1);
    g.add("s1.wiring","1 etapas (įtampos daliklio stendas): sujungimas — E → jungiklis → ampermetras → R1 → RV, voltmetras prie RV",w1,
          ok1?"Patikrinkite seką: E → K → A → R1 → RV → grįžimas; zondai prie RV galų.":"Sujungimo įrodymo duomenys sugadinti.",ok1?"":"missing_evidence");
}
bool ld6_wiring(const Json& pairs,bool& valid,int mode=1) {
    std::vector<std::pair<std::string,std::string>> required={{"E1_P","K1"},{"K2","A_P"},{"A_N","R_A"},{"V_P","R_A"},{"V_N","R_B"}};
    if(mode==1||mode==4) required.push_back({"R_B","E1_N"});
    if(mode==2) {required.push_back({"R_B","E2_N"});required.push_back({"E2_P","E1_N"});}
    if(mode==3) {required.push_back({"R_B","E2_P"});required.push_back({"E2_N","E1_N"});}
    if(mode==4) {required.push_back({"E1_P","E2_P"});required.push_back({"E1_N","E2_N"});}
    try {
        if(!pairs.is_array()) {valid=false;return false;}
        if(pairs.size()!=required.size()) return false;
        std::set<std::pair<std::string,std::string>> unique,canonical;
        for(const auto& wire:required) canonical.insert({std::min(wire.first,wire.second),std::max(wire.first,wire.second)});
        for(auto& w:pairs) {
            if(!w.is_array()||w.size()!=2) {valid=false;return false;}
            const auto a=text(w.at(0)),b2=text(w.at(1));
            if(a.empty()||b2.empty()) {valid=false;return false;}
            if(!unique.insert({std::min(a,b2),std::max(a,b2)}).second) return false;
        }
        return unique==canonical;
    } catch(const std::exception&) {valid=false;return false;}
}
void grade_ld6(Grader& g,const Json& r,const Bank& b) {
    parameters(r,{{"E1",9},{"E2",b.e2},{"R",b.r6},{"Rnom",b.r6n}});
    g.answer("s2.q1","2 etapas (teorinė prognozė): srovė I1 = E1 / R",9.0/b.r6*1000,"mA","I1 = E1/R.",.01,1e-9);
    const double us[3]={9.0,9.0+b.e2,9.0-b.e2};
    const double is[3]={9.0/b.r6*1000,(9.0+b.e2)/b.r6*1000,(9.0-b.e2)/b.r6*1000};
    const char* modes[3]={"tik E1","E1+E2 serija","E1−E2 priešinieji"};
    for(int k=0;k<3;++k) {
        g.measured("u"+std::to_string(k+1),std::to_string(k+2)+" etapas (matavimas, "+modes[k]+"): U",us[k],"V",0,.05);
        g.measured("i"+std::to_string(k+1),std::to_string(k+2)+" etapas (matavimas, "+modes[k]+"): I",is[k],"mA",.02);
    }
    g.answer("s4.q1","4 etapas (skaičiavimai): U_ser = E1 + E2",us[1],"V","Nuoseklių šaltinių EV sudedamos.",.01,1e-9);
    g.answer("s4.q2","4 etapas (skaičiavimai): I_ser = (E1+E2) / R",is[1],"mA","I = ΣE/R.",.02,1e-9);
    g.answer("s4.q3","4 etapas (skaičiavimai): U_pries = E1 − E2",us[2],"V","Priešinių šaltinių EV atimamos.",.01,1e-9);
    g.answer("s4.q4","4 etapas (skaičiavimai): I_pries = (E1−E2) / R",is[2],"mA","I = ΔE/R.",.02,1e-9);
    g.answer("s6.q1","6 etapas (išvada): ar nuoseklių šaltinių EV sudedamos",1,"choice","1 – Taip, 2 – Ne.",0,0);
    g.answer("s6.q2","6 etapas (išvada): ar priešinių šaltinių EV atimamos",1,"choice","1 – Taip, 2 – Ne.",0,0);
    bool ok1=true;
    bool w1=ld6_wiring(r.at("evidence").at("wiring").at("s1").at("pairs"),ok1);
    g.add("s1.wiring","1 etapas (šaltinių jungimo stendas): sujungimas — E1 → jungiklis → ampermetras → R",w1,
          ok1?"Patikrinkite: E1 → K → A → R → grįžimas; zondai prie R.":"Sujungimo duomenys sugadinti.",ok1?"":"missing_evidence");
}
void grade_ld6_sources(Grader& grader,const Json& report,const Bank& variant) {
    parameters(report,{{"E1",9},{"E2",variant.e2},{"R",variant.r1a},{"Rnom",variant.r6n},{"r1",10},{"r2",10}});
    const double load=variant.r1a;
    const double currents[]={9000/(load+10),(9+variant.e2)*1000/(load+20),
        (9-variant.e2)*1000/(load+20),(9+variant.e2)/2*1000/(load+5)};
    double volts[4];
    const char* mode_names[]={"tik E1","šaltiniai nuosekliai","šaltiniai priešpriešiais","šaltiniai lygiagrečiai"};
    for(int mode=0;mode<4;++mode) {
        volts[mode]=currents[mode]*load/1000;
        grader.measured("u"+std::to_string(mode+1),std::string("Matavimas (")+mode_names[mode]+"): apkrovos U",volts[mode],"V",0,.005);
        grader.measured("i"+std::to_string(mode+1),std::string("Matavimas (")+mode_names[mode]+"): apkrovos I",currents[mode],"mA",.02);
    }
    const double first=(9-volts[3])/10*1000,second=(variant.e2-volts[3])/10*1000;
    grader.measured("parallel_i1","Lygiagrečiai: E1 atiduodama srovė",first,"mA",.02);
    grader.measured("parallel_i2","Lygiagrečiai: E2 atiduodama srovė",second,"mA",.02);
    grader.answer("s2.q1","E1: apkrovos srovė",currents[0],"mA","I = E1/(R+r1), mA.",.01,1e-9);
    grader.answer("s4.q1","Nuosekliai: apkrovos įtampa",volts[1],"V","U = (E1+E2)·R/(R+r1+r2).",.01,1e-9);
    grader.answer("s4.q2","Nuosekliai: apkrovos srovė",currents[1],"mA","I = (E1+E2)/(R+r1+r2), mA.",.02,1e-9);
    grader.answer("s4.q3","Priešpriešiais: apkrovos įtampa",volts[2],"V","U = (E1−E2)·R/(R+r1+r2). Išlaikykite ženklą.",.01,1e-9);
    grader.answer("s4.q4","Priešpriešiais: apkrovos srovė",currents[2],"mA","I = (E1−E2)/(R+r1+r2), mA. Išlaikykite ženklą.",.02,1e-9);
    grader.answer("s5.q1","Lygiagrečiai: apkrovos įtampa",volts[3],"V","U = (E1/r1+E2/r2)/(1/R+1/r1+1/r2).",.01,1e-9);
    grader.answer("s5.q2","Lygiagrečiai: apkrovos srovė",currents[3],"mA","I = U/R, mA.",.02,1e-9);
    grader.answer("s5.q3","Lygiagrečiai: E1 srovė",first,"mA","I1 = (E1−U)/r1, mA.",.02,1e-9);
    grader.answer("s5.q4","Lygiagrečiai: E2 srovė",second,"mA","I2 = (E2−U)/r2, mA. Neigiama srovė teka į šaltinį.",.02,1e-9);
    grader.answer("s6.q1","Ar nuosekliai EV sudedamos su ženklais?",1,"choice","1 – Taip, 2 – Ne.",0,0);
    grader.answer("s6.q2","Ar lygiagrečiai E1 ir E2 įtampos sudedamos?",2,"choice","Lygiagretaus jungimo įtampa nėra E1+E2.",0,0);
    const int stages[]={1,3,4,5};
    const char* wiring_labels[]={
        "1 etapas: sujungta grandinė tik su šaltiniu E1",
        "3 etapas: šaltiniai sujungti nuosekliai",
        "4 etapas: šaltiniai sujungti priešpriešiais",
        "5 etapas: šaltiniai sujungti lygiagrečiai"
    };
    for(int mode=1;mode<=4;++mode) {
        const auto stage="s"+std::to_string(stages[mode-1]);
        bool valid=true,correct=false;
        try {correct=ld6_wiring(report.at("evidence").at("wiring").at(stage).at("pairs"),valid,mode);}
        catch(const std::exception&) {valid=false;}
        grader.add(stage+".wiring",wiring_labels[mode-1],correct,
            valid?"Patikrinkite šaltinių poliškumą, ampermetro vietą ir voltmetro zondus prie apkrovos R.":"Trūksta tinkamo sujungimo įrodymo.",valid?"":"missing_evidence");
    }
}
bool ld7_wiring(const Json& pairs,bool& valid,int mode=1) {
    std::vector<std::pair<std::string,std::string>> required={{"E_P","K1"},{"K2","A_P"},{"A_N","R_A"},{"V_P","R_A"},{"V_N","R_B"}};
    if(mode==1) required.push_back({"R_B","E_N"});
    if(mode==2) required={{"V_P","E_P"},{"V_N","E_N"}};
    if(mode==3) required={{"E_P","K1"},{"K2","A_P"},{"A_N","E_N"}};
    try {
        if(!pairs.is_array()) {valid=false;return false;}
        if(pairs.size()!=required.size()) return false;
        std::set<std::pair<std::string,std::string>> unique,canonical;
        for(const auto& wire:required) canonical.insert({std::min(wire.first,wire.second),std::max(wire.first,wire.second)});
        for(auto& w:pairs) {
            if(!w.is_array()||w.size()!=2) {valid=false;return false;}
            const auto a=text(w.at(0)),b2=text(w.at(1));
            if(a.empty()||b2.empty()) {valid=false;return false;}
            if(!unique.insert({std::min(a,b2),std::max(a,b2)}).second) return false;
        }
        return unique==canonical;
    } catch(const std::exception&) {valid=false;return false;}
}
void grade_ld7(Grader& grader,const Json& report,const Bank& variant) {
    parameters(report,{{"E",variant.e7},{"r",variant.r7},{"R1",variant.w71},{"R2",variant.w72},
                       {"R3",variant.w73},{"R4",variant.w74},{"R5",variant.w75}});
    const double E=variant.e7,r=variant.r7;
    const double load[5]={variant.w71,variant.w72,variant.w73,variant.w74,variant.w75};
    double volts[5],cur[5],p[5];
    for(int k=0;k<5;++k) {
        volts[k]=E*load[k]/(load[k]+r);
        cur[k]=E/(load[k]+r)*1000;
        p[k]=volts[k]*cur[k];
        grader.measured("u"+std::to_string(k+1),"Matavimas: U, padėtis P"+std::to_string(k+1),volts[k],"V",0,.005);
        grader.measured("i"+std::to_string(k+1),"Matavimas: I, padėtis P"+std::to_string(k+1),cur[k],"mA",.02);
    }
    grader.measured("te_u","Matavimas: tuščiosios eigos įtampa U0",E*1e6/(1e6+r),"V",0,.005);
    grader.measured("tj_i","Matavimas: trumpojo jungimo srovė Ik",E/(r+1e-6)*1000,"mA",.02);
    grader.answer("s3.q1","Vidinė varža r iš dviejų taškų: r = (U5−U1)/(I1−I5)",r,"Ohm","r = ΔU/ΔI; srovę perkelti į amperus.",.03,1e-9);
    grader.answer("s3.q2","Patikra: E = U1 + I1·r",E,"V","I1 – amperais.",.01,1e-9);
    grader.answer("s4.q1","Galia padėtyje P1: P1 = U1 · I1",p[0],"mW","P = U[V] · I[mA] = mW.",.02,1e-9);
    grader.answer("s4.q2","Galia padėtyje P3: P3 = U3 · I3",p[2],"mW","P = U[V] · I[mA] = mW.",.02,1e-9);
    grader.answer("s4.q3","Galia padėtyje P5: P5 = U5 · I5",p[4],"mW","P = U[V] · I[mA] = mW.",.02,1e-9);
    grader.answer("s4.q4","Teorinė didžiausioji galia: Pmax = E²/(4r)",1000*E*E/(4*r),"mW","Pmax = E²/(4r) W → ×1000 mW.",.02,1e-9);
    grader.answer("s4.q5","Naudingumo koeficientas padėtyje P3: η3 = (U3/E)·100 %",50.0,"1","η = R3/(R3+r) · 100.",.02,1e-9);
    grader.answer("s5.q1","Tuščiosios eigos įtampa U0",E*1e6/(1e6+r),"V","U0 ≈ E (TE).",.01,1e-9);
    grader.answer("s5.q2","Trumpojo jungimo srovė Ik = E/r",E/r*1000,"mA","Ik = E/r A → ×1000 mA.",.02,1e-9);
    grader.answer("s6.q1","Išvada: galia didžiausia, kai R = r",1,"choice","1 – Taip, 2 – Ne.",0,0);
    grader.answer("s6.q2","Išvada: suderinamumo režime η = 50 %",1,"choice","1 – Taip, 2 – Ne.",0,0);
    grader.answer("s6.q3","Išvada: kodėl U mažėja didėjant srovei",1,"choice","1 – krista vidinėje varžoje, 2 – keičiasi šaltinio EV.",0,0);
    const std::pair<const char*,int> wiring_stages[]={{"s1",1},{"s5te",2},{"s5tj",3}};
    const char* wiring_labels[3]={"Sujungimas: E → K → A → R grįžimas; voltmetras prie R",
                                  "Sujungimas (TE): voltmetras prie šaltinio galų",
                                  "Sujungimas (TJ): ampermetras vietoj krovinio"};
    for(auto& entry:wiring_stages) {
        bool valid=true,correct=false;
        try {correct=ld7_wiring(report.at("evidence").at("wiring").at(entry.first).at("pairs"),valid,entry.second);}
        catch(const std::exception&) {valid=false;}
        grader.add(std::string(entry.first)+".wiring",wiring_labels[entry.second-1],correct,
            valid?"Patikrinkite laidus pagal schemas ir zondų vietas.":"Trūksta tinkamo sujungimo įrodymo.",valid?"":"missing_evidence");
    }
}
bool ld8_wiring(const Json& pairs,bool& valid,int mode=1) {
    std::vector<std::pair<std::string,std::string>> required={{"E_P","K1"},{"K2","A_P"},{"A_N","R1_A"},
        {"V_P","E_P"},{"V_N","E_N"}};
    if(mode==1) {required.push_back({"R1_B","R2_A"});required.push_back({"R2_B","R3_A"});required.push_back({"R3_B","E_N"});}
    if(mode==2) {required.push_back({"R1_A","R2_A"});required.push_back({"R2_A","R3_A"});
                 required.push_back({"R1_B","E_N"});required.push_back({"R1_B","R2_B"});required.push_back({"R2_B","R3_B"});}
    if(mode==3) {required.push_back({"R1_B","R2_A"});required.push_back({"R2_A","R3_A"});
                 required.push_back({"R2_B","R3_B"});required.push_back({"R3_B","E_N"});}
    try {
        if(!pairs.is_array()) {valid=false;return false;}
        if(pairs.size()!=required.size()) return false;
        std::set<std::pair<std::string,std::string>> unique,canonical;
        for(const auto& wire:required) canonical.insert({std::min(wire.first,wire.second),std::max(wire.first,wire.second)});
        for(auto& w:pairs) {
            if(!w.is_array()||w.size()!=2) {valid=false;return false;}
            const auto a=text(w.at(0)),b2=text(w.at(1));
            if(a.empty()||b2.empty()) {valid=false;return false;}
            if(!unique.insert({std::min(a,b2),std::max(a,b2)}).second) return false;
        }
        return unique==canonical;
    } catch(const std::exception&) {valid=false;return false;}
}
void grade_ld8(Grader& grader,const Json& report,const Bank& variant) {
    parameters(report,{{"E",12},{"R1",variant.e8a},{"R2",variant.e8b},{"R3",variant.e8c}});
    const double E=12,r1=variant.e8a,r2=variant.e8b,r3=variant.e8c;
    const double series=r1+r2+r3;
    const double parallel=1.0/(1.0/r1+1.0/r2+1.0/r3);
    const double mixed=r1+r2*r3/(r2+r3);
    const double currents[]={E/series*1000,E/parallel*1000,E/mixed*1000};
    const char* names[]={"nuosekliai","lygiagrečiai","mišriai"};
    for(int mode=0;mode<3;++mode) {
        grader.measured("u"+std::to_string(mode+1),std::string("Matavimas: U, ")+names[mode],E,"V",0,.005);
        grader.measured("i"+std::to_string(mode+1),std::string("Matavimas: I, ")+names[mode],currents[mode],"mA",.02);
    }
    grader.answer("s2.q1","Nuoseklioji grandinė: Rt = R1 + R2 + R3",series,"Ohm","Varžos sudedamos.",.01,1e-9);
    grader.answer("s2.q2","Nuoseklioji grandinė: Re = U / I",series,"Ohm","Re = U/I (I – amperais).",.02,1e-9);
    grader.answer("s3.q1","Lygiagretė grandinė: Rt = 1/(1/R1+1/R2+1/R3)",parallel,"Ohm","Laidžiai sudedami.",.01,1e-9);
    grader.answer("s3.q2","Lygiagretė grandinė: Re = U / I",parallel,"Ohm","Re = U/I (I – amperais).",.02,1e-9);
    grader.answer("s4.q1","Mišrioji grandinė: Rt = R1 + R2·R3/(R2+R3)",mixed,"Ohm","R2 ir R3 lygiagrečiai, plius R1.",.01,1e-9);
    grader.answer("s4.q2","Mišrioji grandinė: Re = U / I",mixed,"Ohm","Re = U/I (I – amperais).",.02,1e-9);
    grader.answer("s5.q1","Šakos srovė lygiagrečiai: I1 = U / R1",E/r1*1000,"mA","I = U/R, mA.",.02,1e-9);
    grader.answer("s5.q2","Šakos srovė lygiagrečiai: I2 = U / R2",E/r2*1000,"mA","I = U/R, mA.",.02,1e-9);
    grader.answer("s5.q3","Šakos srovė lygiagrečiai: I3 = U / R3",E/r3*1000,"mA","I = U/R, mA.",.02,1e-9);
    grader.answer("s6.q1","Išvada: nuoseklioji Rt didesnė už kiekvieną varžą",1,"choice","1 – Taip, 2 – Ne.",0,0);
    grader.answer("s6.q2","Išvada: lygiagretė Rt mažesnė už mažiausią varžą",1,"choice","1 – Taip, 2 – Ne.",0,0);
    grader.answer("s6.q3","Išvada: šakų srovių suma lygi bendrai srovei",1,"choice","1 – Taip, 2 – Ne.",0,0);
    const std::pair<const char*,int> wiring_stages[]={{"s1",1},{"s3",2},{"s4",3}};
    const char* wiring_labels[3]={"Sujungimas (nuosekliai): E → K → A → R1 → R2 → R3, voltmetras prie šaltinio",
                                  "Sujungimas (lygiagrečiai): visos varžos tarp tų pačių mazgų",
                                  "Sujungimas (mišriai): R1 nuosekliai su lygiagrečiais R2 ir R3"};
    for(auto& entry:wiring_stages) {
        bool valid=true,correct=false;
        try {correct=ld8_wiring(report.at("evidence").at("wiring").at(entry.first).at("pairs"),valid,entry.second);}
        catch(const std::exception&) {valid=false;}
        grader.add(std::string(entry.first)+".wiring",wiring_labels[entry.second-1],correct,
            valid?"Patikrinkite grandinės seką pagal Pagalbą.":"Trūksta tinkamo sujungimo įrodymo.",valid?"":"missing_evidence");
    }
}
bool ld9_wiring(const Json& pairs,bool& valid) {
    const std::vector<std::pair<std::string,std::string>> required={
        {"GEN_P","K1"},{"K2","A_P"},{"A_N","R_A"},{"R_B","L_A"},{"L_B","C_A"},{"C_B","GEN_N"}};
    try {
        if(!pairs.is_array()) {valid=false;return false;}
        if(pairs.size()!=required.size()) return false;
        std::set<std::pair<std::string,std::string>> unique,canonical;
        for(const auto& wire:required) canonical.insert({std::min(wire.first,wire.second),std::max(wire.first,wire.second)});
        for(auto& w:pairs) {
            if(!w.is_array()||w.size()!=2) {valid=false;return false;}
            const auto a=text(w.at(0)),b2=text(w.at(1));
            if(a.empty()||b2.empty()) {valid=false;return false;}
            if(!unique.insert({std::min(a,b2),std::max(a,b2)}).second) return false;
        }
        return unique==canonical;
    } catch(const std::exception&) {valid=false;return false;}
}
void grade_ld9(Grader& grader,const Json& report,const Bank& variant) {
    parameters(report,{{"E",5},{"R",variant.e9r},{"L",variant.e9l},{"C",variant.e9c}});
    const double E=5,R=variant.e9r,L=variant.e9l,C=variant.e9c;
    const double f0=1.0/(2.0*std::acos(-1.0)*std::sqrt(L*C));
    const double multipliers[]={0.5,1.0,2.0};
    double current[3],ur[3],ul[3],uc[3];
    for(int point=0;point<3;++point) {
        const auto v=ld::ac(3,E,multipliers[point]*f0,R,L,C);
        current[point]=v[3]*1000; ur[point]=v[4]; ul[point]=v[5]; uc[point]=v[6];
        grader.measured("i"+std::to_string(point+1),std::string("Matavimas: I, taškas f")+std::to_string(point+1),current[point],"mA",.02);
        grader.measured("ur"+std::to_string(point+1),std::string("Matavimas: UR, taškas f")+std::to_string(point+1),ur[point],"V",0,.005);
        grader.measured("ul"+std::to_string(point+1),std::string("Matavimas: UL, taškas f")+std::to_string(point+1),ul[point],"V",0,.005);
        grader.measured("uc"+std::to_string(point+1),std::string("Matavimas: UC, taškas f")+std::to_string(point+1),uc[point],"V",0,.005);
        grader.measured("ue"+std::to_string(point+1),std::string("Matavimas: U, taškas f")+std::to_string(point+1),E,"V",0,.005);
    }
    grader.answer("s1.q1","Teorinis rezonanso dažnis f0 = 1/(2π·√(L·C))",f0,"Hz","L – henrais, C – faradais.",.01,1e-9);
    grader.answer("s3.q1","Kokybė ties f0: Q = UL / U",ul[1]/E,"1","Q = UL(f0)/U.",.03,1e-9);
    grader.answer("s3.q2","Skirtumas ties f0: UL − UC",ul[1]-uc[1],"V","Ties rezonansu UL = UC.",0,.02);
    const double z1=E/(current[0]/1000);
    grader.answer("s5.q1","Įtampų trikampis f1: √(UR² + (UL−UC)²)",std::hypot(ur[0],ul[0]-uc[0]),"V","Pitagoro teorema.",.02,1e-9);
    grader.answer("s5.q2","Pilnutinė varža f1: Z = U / I",z1,"Ohm","I – amperais.",.02,1e-9);
    grader.answer("s5.q3","Galios faktorius f1: cos φ = UR / U",ur[0]/E,"1","cos φ = R/Z = UR/U.",.02,1e-9);
    grader.answer("s5.q4","Aktyvioji galia f1: P = UR · I",ur[0]*current[0],"mW","P = UR[V]·I[mA].",.02,1e-9);
    grader.answer("s5.q5","Reaktyvioji galia f1: Q = (UL−UC) · I",(ul[0]-uc[0])*current[0],"mvar","Q = (UL−UC)[V]·I[mA].",.02,1e-9);
    grader.answer("s5.q6","Pilnutinė galia f1: S = U · I",E*current[0],"mVA","S = U[V]·I[mA].",.02,1e-9);
    grader.answer("s6.q1","Išvada: ties f0 fazės poslinkis φ = 0",1,"choice","1 – Taip, 2 – Ne.",0,0);
    grader.answer("s6.q2","Išvada: ties f0 UL = UC",1,"choice","1 – Taip, 2 – Ne.",0,0);
    grader.answer("s6.q3","Išvada: žemiau f0 grandinė talpinė, aukščiau – indukcinė",1,"choice","1 – Taip, 2 – Ne.",0,0);
    bool valid=true,correct=false;
    try {correct=ld9_wiring(report.at("evidence").at("wiring").at("s1").at("pairs"),valid);}
    catch(const std::exception&) {valid=false;}
    grader.add("s1.wiring","Sujungimas: generatorius → jungiklis → ampermetras → R → L → C",correct,
        valid?"Patikrinkite nuoseklią seką ir grįžimą į generatorių.":"Trūksta tinkamo sujungimo įrodymo.",valid?"":"missing_evidence");
}
bool ld10_wiring(const Json& pairs,bool& valid) {
    const std::vector<std::pair<std::string,std::string>> required={
        {"GEN_P","K1"},{"K2","A_P"},{"A_N","R_A"},
        {"R_A","L_A"},{"L_A","C_A"},{"R_B","GEN_N"},{"R_B","L_B"},{"L_B","C_B"}};
    try {
        if(!pairs.is_array()) {valid=false;return false;}
        if(pairs.size()!=required.size()) return false;
        std::set<std::pair<std::string,std::string>> unique,canonical;
        for(const auto& wire:required) canonical.insert({std::min(wire.first,wire.second),std::max(wire.first,wire.second)});
        for(auto& w:pairs) {
            if(!w.is_array()||w.size()!=2) {valid=false;return false;}
            const auto a=text(w.at(0)),b2=text(w.at(1));
            if(a.empty()||b2.empty()) {valid=false;return false;}
            if(!unique.insert({std::min(a,b2),std::max(a,b2)}).second) return false;
        }
        return unique==canonical;
    } catch(const std::exception&) {valid=false;return false;}
}
void grade_ld10(Grader& grader,const Json& report,const Bank& variant) {
    parameters(report,{{"E",5},{"R",variant.e10r},{"L",variant.e10l},{"C",variant.e10c}});
    const double E=5,R=variant.e10r,L=variant.e10l,C=variant.e10c;
    const double f0=1.0/(2.0*std::acos(-1.0)*std::sqrt(L*C));
    const double multipliers[]={0.5,1.0,2.0};
    double total[3],ir[3],il[3],ic[3];
    for(int point=0;point<3;++point) {
        const auto v=ld::ac(4,E,multipliers[point]*f0,R,L,C);
        total[point]=v[3]*1000; ir[point]=v[4]*1000; il[point]=v[5]*1000; ic[point]=v[6]*1000;
        grader.measured("u"+std::to_string(point+1),std::string("Matavimas: U, taškas f")+std::to_string(point+1),E,"V",0,.005);
        grader.measured("ir"+std::to_string(point+1),std::string("Matavimas: IR, taškas f")+std::to_string(point+1),ir[point],"mA",.02);
        grader.measured("il"+std::to_string(point+1),std::string("Matavimas: IL, taškas f")+std::to_string(point+1),il[point],"mA",.02);
        grader.measured("ic"+std::to_string(point+1),std::string("Matavimas: IC, taškas f")+std::to_string(point+1),ic[point],"mA",.02);
        grader.measured("i"+std::to_string(point+1),std::string("Matavimas: I bendra, taškas f")+std::to_string(point+1),total[point],"mA",.02);
    }
    grader.answer("s1.q1","Teorinis rezonanso dažnis f0 = 1/(2π·√(L·C))",f0,"Hz","L – henrais, C – faradais.",.01,1e-9);
    grader.answer("s3.q1","Srovių kokybė ties f0: Q = IL / I",il[1]/total[1],"1","Q = IL(f0)/I.",.03,1e-9);
    grader.answer("s3.q2","Skirtumas ties f0: IL − IC",il[1]-ic[1],"mA","Ties rezonansu IL = IC.",0,.02);
    grader.answer("s5.q1","Srovių trikampis f1: √(IR² + (IL−IC)²)",std::hypot(ir[0],il[0]-ic[0]),"mA","Pitagoro teorema.",.02,1e-9);
    grader.answer("s5.q2","Pilnutinis laidis f1: Y = I / U",total[0]/E,"mS","I – mAmperais, U – voltais.",.02,1e-9);
    grader.answer("s5.q3","Galios faktorius f1: cos φ = IR / I",ir[0]/total[0],"1","cos φ = G/Y = IR/I.",.02,1e-9);
    grader.answer("s5.q4","Aktyvioji galia f1: P = U · IR",E*ir[0],"mW","P = U[V]·IR[mA].",.02,1e-9);
    grader.answer("s5.q5","Reaktyvioji galia f1: Q = U · (IL−IC)",E*(il[0]-ic[0]),"mvar","Q = U[V]·(IL−IC)[mA].",.02,1e-9);
    grader.answer("s5.q6","Pilnutinė galia f1: S = U · I",E*total[0],"mVA","S = U[V]·I[mA].",.02,1e-9);
    grader.answer("s6.q1","Išvada: ties f0 bendroji srovė I minimali",1,"choice","1 – Taip, 2 – Ne.",0,0);
    grader.answer("s6.q2","Išvada: ties f0 IL = IC",1,"choice","1 – Taip, 2 – Ne.",0,0);
    grader.answer("s6.q3","Išvada: žemiau f0 grandinė indukcinė, aukščiau – talpinė",1,"choice","1 – Taip, 2 – Ne.",0,0);
    bool valid=true,correct=false;
    try {correct=ld10_wiring(report.at("evidence").at("wiring").at("s1").at("pairs"),valid);}
    catch(const std::exception&) {valid=false;}
    grader.add("s1.wiring","Sujungimas (lygiagrečiai): generatorius → jungiklis → ampermetras → R, L ir C tarp tų pačių mazgų",correct,
        valid?"Patikrinkite, ar visos trys šakos jungiamos tarp tų pačių dviejų mazgų.":"Trūksta tinkamo sujungimo įrodymo.",valid?"":"missing_evidence");
}
bool ld11_wiring(const Json& pairs,bool& valid,int mode=1) {
    std::vector<std::pair<std::string,std::string>> required={{"GEN_P","K1"},{"K2","A_P"},
        {"A_N","RL_A"},{"RL_B","GEN_N"}};
    if(mode==2) {required.push_back({"RL_A","C_A"});required.push_back({"C_B","GEN_N"});}
    try {
        if(!pairs.is_array()) {valid=false;return false;}
        if(pairs.size()!=required.size()) return false;
        std::set<std::pair<std::string,std::string>> unique,canonical;
        for(const auto& wire:required) canonical.insert({std::min(wire.first,wire.second),std::max(wire.first,wire.second)});
        for(auto& w:pairs) {
            if(!w.is_array()||w.size()!=2) {valid=false;return false;}
            const auto a=text(w.at(0)),b2=text(w.at(1));
            if(a.empty()||b2.empty()) {valid=false;return false;}
            if(!unique.insert({std::min(a,b2),std::max(a,b2)}).second) return false;
        }
        return unique==canonical;
    } catch(const std::exception&) {valid=false;return false;}
}
void grade_ld11(Grader& grader,const Json& report,const Bank& variant) {
    parameters(report,{{"E",variant.e11e},{"f",50},{"R",variant.e11r},{"L",variant.e11l},{"Ck",variant.e11c}});
    const double E=variant.e11e,R=variant.e11r,L=variant.e11l,Ck=variant.e11c;
    const auto no_cap=ld::ac(5,E,50,R,L,0.0);
    const auto with_cap=ld::ac(5,E,50,R,L,Ck);
    grader.measured("u1","Matavimas (be Ck): U",E,"V",0,.005);
    grader.measured("i1","Matavimas (be Ck): I",no_cap[3]*1000,"mA",.02);
    grader.measured("p1","Matavimas (be Ck): aktyvioji galia P",no_cap[5]*1000,"mW",.02,1e-6);
    grader.measured("u2","Matavimas (su Ck): U",E,"V",0,.005);
    grader.measured("i2","Matavimas (su Ck): I",with_cap[3]*1000,"mA",.02);
    grader.measured("p2","Matavimas (su Ck): P",with_cap[5]*1000,"mW",.02,1e-6);
    const double s1=E*no_cap[3], q1=no_cap[6], s2=E*with_cap[3], q2=with_cap[6];
    grader.answer("s1.q1","Pradinis galios faktorius: cos φ0 = R / Z",R/std::hypot(R,no_cap[0]),"1","Z = √(R² + XL²).",.01,1e-9);
    grader.answer("s2.q1","Pilnutinė galia be Ck: S = U·I",s1*1000,"mVA","S = U[V]·I[mA].",.02,1e-9);
    grader.answer("s2.q2","Reaktyvioji galia be Ck: Q = √(S² − P²)",std::abs(q1)*1000,"mvar","Q iš galios trikampio.",.02,1e-9);
    grader.answer("s2.q3","Galios faktorius be Ck: cos φ = P / S",no_cap[5]/s1,"1","cos φ = P/S.",.02,1e-9);
    grader.answer("s3.q1","Kompensuojantis kondensatorius: Ck = XL/(ω·(R²+XL²))",Ck*1e6,"uF","ω = 2π·50; atsakymas mikromadais.",.03,1e-9);
    grader.answer("s5.q1","Pilnutinė galia su Ck: S2 = U·I2",s2*1000,"mVA","S2 = U[V]·I2[mA].",.02,1e-9);
    grader.answer("s5.q2","Reaktyvioji galia su Ck: Q2",std::abs(q2)*1000,"mvar","Q2 iš naujo trikampio.",.02,1e-9);
    grader.answer("s5.q3","Galios faktorius su Ck: cos φ2 = P2/S2",with_cap[5]/s2,"1","cos φ2 = P2/S2.",.02,1e-9);
    grader.answer("s5.q4","Pilnutinės galios sumažėjimas: ΔS = S − S2",(s1-s2)*1000,"mVA","ΔS = S − S2.",.02,1e-9);
    grader.answer("s6.q1","Išvada: aktyvioji galia P po kompensacijos nepakito",1,"choice","1 – Taip, 2 – Ne.",0,0);
    grader.answer("s6.q2","Išvada: srovė I po kompensacijos sumažėjo",1,"choice","1 – Taip, 2 – Ne.",0,0);
    grader.answer("s6.q3","Išvada: cos φ po kompensacijos padidėjo",1,"choice","1 – Taip, 2 – Ne.",0,0);
    const std::pair<const char*,int> wiring_stages[]={{"s1",1},{"s4",2}};
    const char* wiring_labels[2]={"Sujungimas (be kondensatoriaus): generatorius → jungiklis → ampermetras → rišlė (R, L)",
                                  "Sujungimas (su Ck): kondensatorius lygiagrečiai rišlei"};
    for(auto& entry:wiring_stages) {
        bool valid=true,correct=false;
        try {correct=ld11_wiring(report.at("evidence").at("wiring").at(entry.first).at("pairs"),valid,entry.second);}
        catch(const std::exception&) {valid=false;}
        grader.add(std::string(entry.first)+".wiring",wiring_labels[entry.second-1],correct,
            valid?"Patikrinkite seką ir zondus prie generatoriaus.":"Trūksta tinkamo sujungimo įrodymo.",valid?"":"missing_evidence");
    }
}
bool ld12_wiring(const Json& pairs,bool& valid,int mode=1) {
    // Terminalai: L1 L2 L3 N; imtuvai R1(a/b), R2, R3.
    // Žvaigždė (4): L1–R1a, L2–R2a, L3–R3a, R1b–N, R2b–N, R3b–N → 6 laidai.
    // Trikampis: R1 tarp L1–L2, R2 tarp L2–L3, R3 tarp L3–L1 → 6 laidai.
    std::vector<std::pair<std::string,std::string>> required;
    if(mode==1) required={{"L1","R1_A"},{"L2","R2_A"},{"L3","R3_A"},{"R1_B","R2_B"},{"R2_B","R3_B"},{"R3_B","N"}};
    else required={{"L1","R1_A"},{"R1_B","L2"},{"L2","R2_A"},{"R2_B","L3"},{"L3","R3_A"},{"R3_B","L1"}};
    try {
        if(!pairs.is_array()) {valid=false;return false;}
        if(pairs.size()!=required.size()) return false;
        std::set<std::pair<std::string,std::string>> unique,canonical;
        for(const auto& wire:required) canonical.insert({std::min(wire.first,wire.second),std::max(wire.first,wire.second)});
        for(auto& w:pairs) {
            if(!w.is_array()||w.size()!=2) {valid=false;return false;}
            const auto a=text(w.at(0)),b2=text(w.at(1));
            if(a.empty()||b2.empty()) {valid=false;return false;}
            if(!unique.insert({std::min(a,b2),std::max(a,b2)}).second) return false;
        }
        return unique==canonical;
    } catch(const std::exception&) {valid=false;return false;}
}
void grade_ld12(Grader& grader,const Json& report,const Bank& variant) {
    parameters(report,{{"Ul",variant.e12u},{"R",variant.e12r}});
    const double Ul=variant.e12u,R=variant.e12r;
    const double phase=Ul/std::sqrt(3.0);
    const double i_star=phase/R*1000;         // žvaigždė: fazinė = linijinė srovė
    const double i_ph_delta=Ul/R*1000;        // trikampis: fazinė srovė
    const double i_line_delta=i_ph_delta*std::sqrt(3.0);
    const double p_star=Ul*Ul/R;
    const double p_delta=3.0*Ul*Ul/R;   // P = 3·Uf²/R abiem jungimais
    grader.measured("is","Matavimas (žvaigždė): pasirinktos fazės srovė",i_star,"mA",.02);
    grader.measured("id","Matavimas (trikampis): pasirinktos šakos fazinė srovė",i_ph_delta,"mA",.02);
    grader.answer("s1.q1","Fazinė įtampa žvaigždėje: Uf = Ul/√3",phase,"V","Uf = Ul/√3.",.01,1e-9);
    grader.answer("s2.q1","Žvaigždės fazinė srovė: If = Uf/R",i_star,"mA","If = Uf/R, mA.",.02,1e-9);
    grader.answer("s3.q1","Trikampio fazinė įtampa",Ul,"V","Trikampyje Uf = Ul.",0,.005);
    grader.answer("s4.q1","Trikampio fazinė srovė: If = Ul/R",i_ph_delta,"mA","If = Ul/R, mA.",.02,1e-9);
    grader.answer("s5.q1","Trikampio linijinė srovė: Il = √3·If",i_line_delta,"mA","Il = √3·If, mA.",.02,1e-9);
    grader.answer("s5.q2","Trikampio galia: P = √3·Ul·Il",p_delta*1000,"mW","P = √3·Ul·Il, W → mW.",.02,1e-9);
    grader.answer("s5.q3","Žvaigždės galia: P = 3·Uf·If",p_star*1000,"mW","P = 3·Uf·If, W → mW.",.02,1e-9);
    grader.answer("s6.q1","Išvada: žvaigždėje fazinė ir linijinė srovės vienodos",1,"choice","1 – Taip, 2 – Ne.",0,0);
    grader.answer("s6.q2","Išvada: trikampyje Il = √3·If",1,"choice","1 – Taip, 2 – Ne.",0,0);
    grader.answer("s6.q3","Išvada: trikampio galia tris kartus didesnė už žvaigždės",1,"choice","1 – Taip, 2 – Ne.",0,0);
    const std::pair<const char*,int> wiring_stages[]={{"s1",1},{"s3",2}};
    const char* wiring_labels[2]={"Sujungimas (žvaigždė): L1/L2/L3 → imtuvai → bendras neutralis N",
                                  "Sujungimas (trikampis): imtuvai tarp linijų L1–L2, L2–L3, L3–L1"};
    for(auto& entry:wiring_stages) {
        bool valid=true,correct=false;
        try {correct=ld12_wiring(report.at("evidence").at("wiring").at(entry.first).at("pairs"),valid,entry.second);}
        catch(const std::exception&) {valid=false;}
        grader.add(std::string(entry.first)+".wiring",wiring_labels[entry.second-1],correct,
            valid?"Patikrinkite, ar kiekvienas imtuvas jungiamas pagal schemą.":"Trūksta tinkamo sujungimo įrodymo.",valid?"":"missing_evidence");
    }
}
void grade_ld3(Grader& g,const Json& r,const Bank& b) {
    parameters(r,{{"R",b.r},{"U1",b.u1},{"U2",b.u2},{"U3",b.u3}});
    const double uu[3]={b.u1,b.u2,b.u3},im[3]={b.u1/b.r*1000,b.u2/b.r*1000,b.u3/b.r*1000};
    g.answer("s2.q1","2 etapas (teorinė prognozė): srovė I1 = U1 / R",im[0],"mA","I1 = U1 / R; mA = V / Ω × 1000.",.01,1e-9);
    double uk[3],ik[3];
    for(int k=0;k<3;++k) {
        auto s=std::to_string(k+1),step=std::to_string(k+2);
        uk[k]=g.measured("u"+s,step+" etapas (matavimas): įtampa U"+s+" voltmetru",uu[k],"V",0,.05);
        ik[k]=g.measured("i"+s,step+" etapas (matavimas): srovė I"+s+" ampermetru",im[k],"mA",.02);
    }
    // R at each point depends on the student's own recorded U and I.
    auto calc=[&](int k){return std::isfinite(uk[k])&&std::isfinite(ik[k])&&ik[k]!=0?uk[k]/ik[k]*1000:NAN;};
    const double rc[3]={calc(0),calc(1),calc(2)};
    const bool all=std::isfinite(rc[0])&&std::isfinite(rc[1])&&std::isfinite(rc[2]);
    dependent(g,"s4.q1","4 etapas (skaičiavimai): varža R1 = U1 / I1",rc[0],"Ohm",std::isfinite(rc[0]),.02);
    dependent(g,"s4.q2","4 etapas (skaičiavimai): varža R2 = U2 / I2",rc[1],"Ohm",std::isfinite(rc[1]),.02);
    dependent(g,"s4.q3","4 etapas (skaičiavimai): varža R3 = U3 / I3",rc[2],"Ohm",std::isfinite(rc[2]),.02);
    dependent(g,"s4.q4","4 etapas (skaičiavimai): vidutinė varža Rvid",all?(rc[0]+rc[1]+rc[2])/3:NAN,"Ohm",all,.02);
    g.answer("s5.q1","5 etapas (charakteristika): varža iš I(U) nuolydžio",b.r,"Ohm","R = ΔU / ΔI iš I(U) tiesės (mA → A: × 1000).",.02);
    g.answer("s6.q1","6 etapas (išvada): ar I(U) priklausomybė tiesinė",1,"choice","1 – Taip, 2 – Ne.",0,0);
    g.answer("s6.q2","6 etapas (išvada): ar varža R pastovi visuose taškuose",1,"choice","1 – Taip, 2 – Ne.",0,0);
    bool wiring_valid=true;
    bool wired=ld3_wiring(r.at("evidence").at("wiring").at("s1"),wiring_valid);
    g.add("s1.wiring","1 etapas (Omo dėsnio stendas): sujungimas — šaltinis → jungiklis → ampermetras → R1, voltmetras lygiagrečiai R1",wired,
          wiring_valid?"Patikrinkite seką: šaltinis → jungiklis → ampermetras → R1; voltmetras lygiagrečiai R1.":"Sujungimo įrodymo duomenys sugadinti.",
          wiring_valid?"":"missing_evidence");
}
} // namespace

Json read_report(const std::filesystem::path& path) {
    require(!std::filesystem::is_symlink(path)&&std::filesystem::is_regular_file(path),"file_type");
    require(std::filesystem::file_size(path)<=2*1024*1024,"file_size_limit");
    std::ifstream in(path,std::ios::binary);require(bool(in),"cannot_read");
    // Bound the read as well as the initial stat: a concurrently growing file
    // must not bypass the importer memory limit.
    std::string body(2*1024*1024+1,'\0');in.read(body.data(),static_cast<std::streamsize>(body.size()));
    auto count=in.gcount();require(!in.bad(),"cannot_read");require(count<=2*1024*1024,"file_size_limit");
    body.resize(static_cast<size_t>(count));
    const std::string start="<script type=\"application/json\" id=\"ld-data\">",end="</script>";
    auto a=body.find(start);require(a!=std::string::npos&&body.find(start,a+start.size())==std::string::npos,"data_block");
    a+=start.size();auto b=body.find(end,a);require(b!=std::string::npos,"data_block");
    std::vector<std::set<std::string>> keys;
    auto callback=[&](int depth,Json::parse_event_t event,Json& value){
        require(depth<=32,"depth_limit");
        if(event==Json::parse_event_t::object_start) keys.emplace_back();
        if(event==Json::parse_event_t::key) require(keys.back().insert(value.get<std::string>()).second,"duplicate_key");
        if(event==Json::parse_event_t::object_end) keys.pop_back();
        return true;
    };
    return Json::parse(body.begin()+static_cast<std::ptrdiff_t>(a),body.begin()+static_cast<std::ptrdiff_t>(b),callback);
}
Json grade(const Json& r) {
    require(r.at("schema_version").is_number_integer()&&r.at("schema_version")==1,"unsupported_schema");
    auto lab=text(r.at("lab_id"));require(lab=="LD1"||lab=="LD2"||lab=="LD3"||lab=="LD4"||lab=="LD5"||lab=="LD6"||lab=="LD7"||lab=="LD8"||lab=="LD9"||lab=="LD10"||lab=="LD11"||lab=="LD12","unsupported_lab");
    const bool sources_revision=lab=="LD6"&&r.at("lab_revision")=="2"&&r.at("rubric_version")=="LD6-2"&&r.at("bank_id")=="LD6-64-B-2026";
    const bool guided_revision=lab=="LD1"&&r.at("lab_revision")=="2"&&r.at("rubric_version")=="LD1-2"&&r.at("bank_id")=="LD1-64-A-2026";
    const bool measurement_revision=lab=="LD1"&&r.at("lab_revision")=="3"&&r.at("rubric_version")=="LD1-3"&&r.at("bank_id")=="LD1-64-A-2026";
    require(sources_revision||guided_revision||measurement_revision||(r.at("lab_revision")=="1"&&r.at("rubric_version")==lab+"-1"&&r.at("bank_id")==lab+"-64-A-2026"),"unsupported_version");
    if(guided_revision) require(r.at("evidence").value("automatic_setup",false),"automatic_setup_required");
    if(measurement_revision) require(r.at("evidence").value("measurement_workflow",false)&&r.at("evidence").value("automatic_measurement",false),"measurement_workflow_required");
    require(r.at("variant").is_number_integer(),"variant_type");
    require(r.at("variant")>=1 && r.at("variant")<=64,"variant_range");
    int variant=r.at("variant").get<int>();auto b=bank(variant);
    const auto& s=r.at("student");
    require(s.at("number").is_number_integer()&&s.at("number")==variant,"student_number");
    for(auto k:{"name","group"}) {
        const auto value=text(s.at(k));
        require(value.find_first_not_of(" \t\r\n")!=std::string::npos &&
                value.find('\r')==std::string::npos && value.find('\n')==std::string::npos,
                "student_identity");
    }
    auto id=text(r.at("submission_id"),128);require(!id.empty(),"submission_identity");
    require(r.at("mode")=="learning"||r.at("mode")=="assessment","mode");
    text(r.at("note"),32000);
    Grader g(r);if(measurement_revision) grade_dc_measurement(g,r,b);else if(lab=="LD1") grade_dc(g,r,b);else if(lab=="LD2") grade_ac(g,r,b);else if(lab=="LD3") grade_ld3(g,r,b);else if(lab=="LD4") grade_ld4(g,r,b);else if(lab=="LD5") grade_ld5(g,r,b);else if(lab=="LD7") grade_ld7(g,r,b);else if(lab=="LD8") grade_ld8(g,r,b);else if(lab=="LD9") grade_ld9(g,r,b);else if(lab=="LD10") grade_ld10(g,r,b);else if(lab=="LD11") grade_ld11(g,r,b);else if(lab=="LD12") grade_ld12(g,r,b);else if(sources_revision) grade_ld6_sources(g,r,b);else grade_ld6(g,r,b);g.finish();
    int points=0,maximum=0;
    for(auto& item:g.items) {
        auto key=item.at("id").get<std::string>();
        if(guided_revision&&(key.find(".measure")!=std::string::npos||key.find(".wiring")!=std::string::npos)) {
            item["points"]=0;item["max_points"]=0;item["automatic"]=true;
            item["comment"]="Automatinis stendo veiksmas; į studento pažymį neįtraukiamas. "+item.at("comment").get<std::string>();
        }
        points+=item.at("points").get<int>(); maximum+=item.at("max_points").get<int>();
    }
    return {{"status","graded"},{"submission_id",id},{"student",s},{"lab_id",lab},{"variant",variant},
            {"mode",r.at("mode")},{"bank_id",r.at("bank_id")},{"lab_revision",r.at("lab_revision")},{"rubric_version",r.at("rubric_version")},
            {"core_version","0.3.0"},{"points",points},{"max_points",maximum},
            {"grade_10",std::round(100.0*points/maximum)/10.0},{"items",g.items},
            {"practice_used",r.value("practice_used",false)},
            {"note",r.at("note")},{"note_policy","Laisvas tekstas išsaugomas; už jo turinį ši skaitinė rubrika balų neskiria."}};
}
std::string html_escape(const std::string& s) {
    std::string o;for(char c:s) switch(c) {case '&':o+="&amp;";break;case '<':o+="&lt;";break;case '>':o+="&gt;";break;case '"':o+="&quot;";break;case '\'':o+="&#39;";break;default:o+=c;}return o;
}
} // namespace ld
