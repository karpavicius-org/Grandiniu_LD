// Shared transport / numerical boundary. Never evaluate student text as code.
global BENCH_RUNTIME_ROOT;
BENCH_RUNTIME_ROOT=get_absolute_file_path("bench_common.sci");
function v=bench_safe_number(txt)
    v=%nan;
    if type(txt)<>10 | size(txt,"*")<>1 then return; end
    t=stripblanks(txt);
    if t=="" | length(t)>128 then return; end
    t=strsubst(strsubst(strsubst(t,",","."),"D","e"),"d","e");
    allowed="0123456789.eE+-";
    for k=1:length(t)
        if isempty(strindex(allowed,part(t,k))) then return; end
    end
    [n,tail]=strtod(t);
    if tail<>"" | size(n,"*")<>1 then return; end
    if ~isreal(n) | isnan(n) | isinf(n) then return; end
    v=n;
endfunction

function bench_core_require()
    global BENCH_CORE_READY BENCH_CORE_LIBRARY BENCH_RUNTIME_ROOT;
    if BENCH_CORE_READY==%t then return; end
    root=BENCH_RUNTIME_ROOT;
    path=getenv("LD_CORE_LIBRARY",root+"bin/ldcore"+getdynlibext());
    if ~isfile(path) then error("Trūksta C++ branduolio: "+path+". Naudokite savo sistemai ir procesoriui skirtą pilną paketą."); end
    BENCH_CORE_LIBRARY=link(path,["ld_ac" "ld_mna" "ld_batch" "ld_write_new" "ld_sources" "ld_export_report" "ld_open_local"],"c");
    BENCH_CORE_READY=%t;
endfunction

function bench_open_local(path)
    bench_core_require(); p=ascii(path);
    status=call("ld_open_local",p,1,"i",size(p,"*"),2,"i","out",[1 1],3,"i");
    if status<>0 then messagebox(["Nepavyko atverti. Failą rasite čia:";path],"Ataskaitos","error"); end
endfunction

function bench_report_action(action)
    global BENCH_REPORT_WINDOW BENCH_LAST_REPORT;
    select action
    case 1 then bench_open_local(BENCH_LAST_REPORT);
    case 2 then bench_open_local(fileparts(BENCH_LAST_REPORT));
    case 3 then
        if typeof(BENCH_REPORT_WINDOW)=="handle" then
            if is_handle_valid(BENCH_REPORT_WINDOW) then delete(BENCH_REPORT_WINDOW); end
        end
    end
endfunction

function bench_report_saved(path,title)
    if getscilabmode()=="NWNI" then return; end
    global BENCH_REPORT_WINDOW BENCH_LAST_REPORT;
    BENCH_LAST_REPORT=path;
    if typeof(BENCH_REPORT_WINDOW)=="handle" then
        if is_handle_valid(BENCH_REPORT_WINDOW) then delete(BENCH_REPORT_WINDOW); end
    end
    f=figure("default_axes","off","dockable","off","menubar","none","toolbar","none","axes_size",[680 260],"figure_name",title,"resize","off");
    f.infobar_visible="off"; BENCH_REPORT_WINDOW=f;
    instruction="Persiųskite dėstytojui vieną HTML failą.";
    if title=="Vertinimas baigtas" then instruction="Pažymiai, komentarai ir CSV lentelė paruošti."; end
    if title=="Vertinimas sustabdytas" then instruction="Vertinimas sustabdytas. Išsaugoti tik jau apdorotų failų daliniai rezultatai."; end
    if title=="Mokymosi ataskaita išsaugota" then instruction="Savikontrolės ataskaita; į pažymių suvestinę ji neįtraukiama."; end
    uicontrol(f,"style","text","units","normalized","position",[.05 .67 .9 .25],"string","<html>"+title+"<br>"+instruction+"</html>","fontunits","pixels","fontsize",16);
    uicontrol(f,"style","edit","units","normalized","position",[.05 .39 .9 .21],"string",path,"max",2,"min",0,"fontunits","pixels","fontsize",13);
    uicontrol(f,"style","pushbutton","units","normalized","position",[.05 .1 .27 .2],"string","Atverti ataskaitą","callback","bench_report_action(1)");
    uicontrol(f,"style","pushbutton","units","normalized","position",[.35 .1 .35 .2],"string","Atverti ataskaitų aplanką","callback","bench_report_action(2)");
    uicontrol(f,"style","pushbutton","units","normalized","position",[.73 .1 .22 .2],"string","Grįžti į darbą","callback","bench_report_action(3)");
endfunction

function v=bench_cpp_ac(kind,E,f,R,L,C)
    bench_core_require(); p=[E f R L C];
    [v,status]=call("ld_ac",kind,1,"i",p,2,"d","out",[1 10],3,"d",[1 1],4,"i");
    if status<>0 then error("C++ modelis atmetė netinkamus grandinės parametrus."); end
endfunction

function [volts,currents,status]=bench_cpp_dc(edges,reachable,srcP,srcN,E)
    nodes=find(reachable); nodes(nodes==srcN)=[];
    mapping=zeros(reachable); mapping(nodes)=1:size(nodes,"*");
    table=[4 mapping(srcP) 0 E 0]; included=[];
    for k=1:size(edges,1)
        a=edges(k,1); b=edges(k,2);
        if ~reachable(a) | ~reachable(b) then continue; end
        kind=1; value=edges(k,3);
        // Ideal wire / ideal ammeter is a zero-voltage constraint, avoiding
        // subtraction of nearly equal voltages across a fictitious 1e-9 ohm.
        if value<=1e-9 then kind=4;value=0; end
        if a==b & kind==4 then continue; end
        table($+1,:)=[kind mapping(a) mapping(b) value 0]; included($+1)=k;
    end
    n=size(nodes,"*"); m=size(table,1);
    [v,i,status]=call("ld_mna",table,1,"d",m,2,"i",n,3,"i",0,4,"d", ...
        "out",[n+1 2],5,"d",[m 2],6,"d",[1 1],7,"i");
    volts=%nan*ones(reachable); currents=%nan*ones(size(edges,1),1);
    if status<>0 then return; end
    volts(srcN)=0; volts(nodes)=v(2:$,1)';
    for k=1:size(included,"*");currents(included(k))=i(k+1,1);end
endfunction

function a=bench_list(values)
    a=list(); for k=1:size(values,"*"); a($+1)=values(k); end
endfunction

function a=bench_pairs(values)
    a=list(); for k=1:size(values,1); a($+1)=list(values(k,1),values(k,2)); end
endfunction

function s=bench_html(s)
    s=strsubst(string(s),"&","&amp;"); s=strsubst(s,"<","&lt;");
    s=strsubst(s,">","&gt;"); s=strsubst(s,ascii(34),"&quot;");
    s=strsubst(s,ascii(39),"&#39;");
endfunction

function folder=bench_documents()
    if getos()=="Windows" then userdir=getenv("USERPROFILE",SCIHOME);
    else userdir=getenv("HOME",SCIHOME); end
    folder=getenv("LD_DATA_DIR",fullfile(userdir,"Grandiniu_LD_darbai"));
    if ~isdir(folder) then
        [ok,msg]=mkdir(folder); if ~ok then error(msg); end
    end
endfunction

function id=bench_id()
    // One ID per export, excludes personal data and avoids path characters.
    global BENCH_EXPORT_COUNTER;
    if isempty(BENCH_EXPORT_COUNTER) then BENCH_EXPORT_COUNTER=0; end
    BENCH_EXPORT_COUNTER=BENCH_EXPORT_COUNTER+1;
    d=getdate();
    id=msprintf("%04d%02d%02dT%02d%02d%02d-%d-%d-%d",d(1),d(2),d(6),d(7),d(8),d(9),getpid(),d(10),BENCH_EXPORT_COUNTER);
endfunction

function bench_write_new(path,contents)
    bench_core_require();
    p=ascii(path); b=ascii(contents);
    status=call("ld_write_new",p,1,"i",size(p,"*"),2,"i",b,3,"i",size(b,"*"),4,"i","out",[1 1],5,"i");
    if status<>0 then error("Failas neišsaugotas. Patikrinkite aplanko teises, laisvą vietą ir ar failas jau neegzistuoja: "+path); end
endfunction

function bench_mode(lab)
    global LD1 LD2 LD3 LD4 LD5 LD6 LD7 LD8 LD9 LD10 LD11 LD12;
    if lab=="LD1" then ld1_student_mode(); return; end
    selected=x_choose(["Atsiskaitymas · atsakymus tikrina dėstytojo programa"; ...
        "Mokymasis · galima tikrinti atsakymus ir matyti pavyzdžius"],"Darbo režimas");
    if selected==0 then return;end
    if lab=="LD1" then
        LD1.assessment=(selected==1);
        if selected==2 then LD1.practice_used=%t;end
        ld1_student_sync();
    elseif lab=="LD2" then
        LD2.state.assessment=(selected==1);
        if selected==2 then LD2.state.practice_used=%t;end
        ld2_render_step();
    elseif lab=="LD3" then
        LD3.assessment=(selected==1);
        if selected==2 then LD3.practice_used=%t; end
        if LD3.assessment then ld3_set_status("Atsiskaitymo režimas: atsakymus tikrins dėstytojo programa.","ok","");
        else ld3_set_status("Mokymosi režimas: galima tikrintis ir naudotis pagalba.","ok",""); end
    elseif lab=="LD4" then
        LD4.assessment=(selected==1);
        if selected==2 then LD4.practice_used=%t; end
        if LD4.assessment & LD4.practice_used then
            ld4_set_status("Atsiskaitymo režimas pasirinktas, bet šis bandymas jau pažymėtas mokymosi.","info","Naujam formaliam bandymui reikės naujos darbo sesijos.");
        elseif LD4.assessment then
            ld4_set_status("Atsiskaitymo režimas: atsakymus tikrins dėstytojo programa.","ok","");
        else
            ld4_set_status("Mokymosi režimas: galima tikrintis ir naudotis pagalba.","ok","");
        end
    elseif lab=="LD5" then
        LD5.assessment=(selected==1);
        if selected==2 then LD5.practice_used=%t; end
        if LD5.assessment & LD5.practice_used then
            ld5_set_status("Atsiskaitymo režimas pasirinktas, bet šis bandymas jau pažymėtas mokymosi.","info","Naujam formaliam bandymui reikės naujos darbo sesijos.");
        elseif LD5.assessment then
            ld5_set_status("Atsiskaitymo režimas: atsakymus tikrins dėstytojo programa.","ok","");
        else
            ld5_set_status("Mokymosi režimas: galima tikrintis ir naudotis pagalba.","ok","");
        end
    elseif lab=="LD6" then
        LD6.assessment=(selected==1);
        if selected==2 then LD6.practice_used=%t; end
        if LD6.assessment & LD6.practice_used then
            ld6_set_status("Atsiskaitymo režimas pasirinktas, bet šis bandymas jau pažymėtas mokymosi.","info","Naujam formaliam bandymui reikės naujos darbo sesijos.");
        elseif LD6.assessment then
            ld6_set_status("Atsiskaitymo režimas: atsakymus tikrins dėstytojo programa.","ok","");
        else
            ld6_set_status("Mokymosi režimas: galima tikrintis ir naudotis pagalba.","ok","");
        end
    elseif lab=="LD7" then
        LD7.assessment=(selected==1);
        if selected==2 then LD7.practice_used=%t; end
        if LD7.assessment & LD7.practice_used then
            ld7_set_status("Atsiskaitymo režimas pasirinktas, bet šis bandymas jau pažymėtas mokymosi.","info","Naujam formaliam bandymui reikės naujos darbo sesijos.");
        elseif LD7.assessment then
            ld7_set_status("Atsiskaitymo režimas: atsakymus tikrins dėstytojo programa.","ok","");
        else
            ld7_set_status("Mokymosi režimas: galima tikrintis ir naudotis pagalba.","ok","");
        end
    elseif lab=="LD8" then
        LD8.assessment=(selected==1);
        if selected==2 then LD8.practice_used=%t; end
        if LD8.assessment then ld8_set_status("Atsiskaitymo režimas: atsakymus tikrins dėstytojo programa.","ok","");
        else ld8_set_status("Mokymosi režimas: galima tikrintis ir naudotis pagalba.","ok",""); end
    elseif lab=="LD9" then
        LD9.assessment=(selected==1);
        if selected==2 then LD9.practice_used=%t; end
        if LD9.assessment then ld9_set_status("Atsiskaitymo režimas: atsakymus tikrins dėstytojo programa.","ok","");
        else ld9_set_status("Mokymosi režimas: galima tikrintis ir naudotis pagalba.","ok",""); end
    elseif lab=="LD10" then
        LD10.assessment=(selected==1);
        if selected==2 then LD10.practice_used=%t; end
        if LD10.assessment then ld10_set_status("Atsiskaitymo režimas: atsakymus tikrins dėstytojo programa.","ok","");
        else ld10_set_status("Mokymosi režimas: galima tikrintis ir naudotis pagalba.","ok",""); end
    elseif lab=="LD11" then
        LD11.assessment=(selected==1);
        if selected==2 then LD11.practice_used=%t; end
        if LD11.assessment then ld11_set_status("Atsiskaitymo režimas: atsakymus tikrins dėstytojo programa.","ok","");
        else ld11_set_status("Mokymosi režimas: galima tikrintis ir naudotis pagalba.","ok",""); end
    elseif lab=="LD12" then
        LD12.assessment=(selected==1);
        if selected==2 then LD12.practice_used=%t; end
        if LD12.assessment then ld12_set_status("Atsiskaitymo režimas: atsakymus tikrins dėstytojo programa.","ok","");
        else ld12_set_status("Mokymosi režimas: galima tikrintis ir naudotis pagalba.","ok",""); end
    end
endfunction
