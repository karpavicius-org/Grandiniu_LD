// Shared Scilab UI; numerical calculation and grading remain in the C++ core.
function h=ld6_button(p,pos,label,cb,fs,bg)
    if argn(2)<5 then fs=13; end
    if argn(2)<6 then bg=[0.94 0.96 0.96]; end
    code=""; hint="";
    try
        [code,registered,hint]=ld6_button_info(cb);
    catch
        code="";
    end
    h=student_button(p,pos,"<html><center>"+label+"</center></html>",cb);
    h.tag=code; h.tooltipstring=hint; h.fontsize=fs; h.backgroundcolor=bg;
    if sum(bg)<1.5 then h.foregroundcolor=[1 1 1]; end
endfunction

function [term_xy,boxes]=ld6_layout()
    global LD6;
    // All terminals sit outside their own component, with 36 x 40 px targets.
    boxes=struct("E1",[7 63 15 16],"K",[38.5 65 12 14],"A",[66 63 14 16], ...
        "R",[54 39 19 14],"E2",[7 39 15 14],"V",[54 12 19 16]);
    term_xy=struct("E1_N",[4.5 72],"E1_P",[24.5 72], ...
        "K1",[35.5 72],"K2",[53.5 72],"A_P",[63.5 72],"A_N",[83 72], ...
        "R_A",[51 46],"R_B",[76 46],"E2_P",[4.5 46],"E2_N",[24.5 46], ...
        "V_P",[51 20],"V_N",[76 20]);
    if or(LD6.wireMode==[3 4]) then
        term_xy.E2_P=[24.5 46]; term_xy.E2_N=[4.5 46];
    end
endfunction

function xy=ld6_terminal_xy(id)
    [tt,bb]=ld6_layout(); xy=tt(id)/100;
endfunction

function txt=ld6_terminal_button_text(id)
    select id
    case "E1_P" then txt="+"; case "E1_N" then txt="−";
    case "K1" then txt="1"; case "K2" then txt="2";
    case "A_P" then txt="+"; case "A_N" then txt="−";
    case "R_A" then txt="a"; case "R_B" then txt="b";
    case "E2_P" then txt="+"; case "E2_N" then txt="-";
    case "V_P" then txt="+"; case "V_N" then txt="−";
    end
endfunction

function ld6_track_board(h)
    global LD6;
    if h<>[] then
        for item=matrix(h,1,-1); LD6.ui.boardHandles($+1)=item; end
    end
endfunction

function ld6_clear_board()
    global LD6;
    for k=1:length(LD6.ui.boardHandles)
        h=LD6.ui.boardHandles(k);
        if is_handle_valid(h) then delete(h); end
    end
    LD6.ui.boardHandles=list(); LD6.term.handles=list(); LD6.term.handleIds=emptystr(0,1);
    // Only the permanent controls survive. No stale terminal handles accumulate.
    LD6.ui.dynamic=LD6.ui.controls;
endfunction

function ld6_polyline(points,col)
    global LD6;
    for k=1:size(points,1)-1
        ld6_track_board(student_wire(LD6.ui.circuitFrame,points(k,:),points(k+1,:),col));
    end
endfunction

function ld6_render_wires()
    global LD6;
    if ~isfield(LD6,"ui") then return; end
    if isfield(LD6.ui,"headless") then if LD6.ui.headless then return; end; end
    if ~isfield(LD6.ui,"circuitFrame") then return; end
    if ~is_handle_valid(LD6.ui.circuitFrame) then return; end
    drawing=LD6.fig.immediate_drawing; LD6.fig.immediate_drawing="off";
    ld6_clear_board(); p=LD6.ui.circuitFrame;
    ports=[];
    for id=matrix(ld6_terminal_ids(),1,-1); ports($+1,:)=[ld6_terminal_xy(id) 36 40]; end
    p.user_data=struct("ports",ports);
    student_begin_wires(p);
    for k=1:size(LD6.wires,1)
        a=LD6.wires(k,1); b=LD6.wires(k,2); p1=ld6_terminal_xy(a); p2=ld6_terminal_xy(b);
        col=[0.22 0.40 0.42];
        if or([a b]=="V_P") | or([a b]=="V_N") then col=[0.52 0.25 0.48]; end
        // Canonical routing is independent of which endpoint is clicked first.
        if (a=="A_N" & b=="R_A") | (b=="A_N" & a=="R_A") | (a=="A_N" & b=="E2_P") | (b=="A_N" & a=="E2_P") then
            pts=[p1;p1(1) 0.57;p2(1) 0.57;p2];
        elseif (a=="E1_N" & b=="R_B") | (b=="E1_N" & a=="R_B") then
            if a=="E1_N" then pts=[p1;.015 p1(2);.015 .34;p2(1) .34;p2];
            else pts=[p1;p1(1) .34;.015 .34;.015 p2(2);p2]; end
        elseif (a=="R_B" & or(b==["E2_P" "E2_N"])) | (b=="R_B" & or(a==["E2_P" "E2_N"])) then
            pts=[p1;p1(1) .34;p2(1) .34;p2];
        elseif or([a b]=="V_P") | or([a b]=="V_N") then
            if a=="V_P" | a=="V_N" then pts=[p1;p2(1) p1(2);p2];
            else pts=[p1;p1(1) p2(2);p2]; end
        elseif abs(p1(1)-p2(1))<1e-9 | abs(p1(2)-p2(2))<1e-9 then pts=[p1;p2];
        else
            // Invalid student wiring stays visible and is rejected by the core.
            xm=(p1(1)+p2(1))/2; pts=[p1;xm p1(2);xm p2(2);p2];
        end
        ld6_polyline(pts,col);
    end
    [tt,bb]=ld6_layout(); ids=["E1" "K" "A" "R" "E2" "V"];
    names=["E1 ŠALTINIS" "JUNGIKLIS" "AMPERMETRAS" "R APKROVA" "E2 ŠALTINIS" "VOLTMETRAS"];
    if LD6.wireMode==1 then names(5)="E2 (nenaud.)"; end
    switchText="Atviras"; if LD6.switchOn then switchText="Uždarytas"; end
    [u,i,valid,reason,branches]=ld6_measure_values();
    ampText="— mA"; voltText="— V";
    if valid then ampText=msprintf("%.3f mA",i); voltText=msprintf("%g V",u); end
    firstText=msprintf("%g V · %g Ω",LD6.cfg.E1,LD6.cfg.r1);
    secondText=msprintf("%g V · %g Ω",LD6.cfg.E2,LD6.cfg.r2);
    if valid then
        firstText="<html><center>"+firstText+msprintf("<br>%.3f mA</center></html>",branches(1));
        secondText="<html><center>"+secondText+msprintf("<br>%.3f mA</center></html>",branches(2));
    end
    vals=[firstText switchText ampText msprintf("%g Ω",LD6.cfg.R) secondText voltText];
    pairs=["E1_N" "E1_P";"K1" "K2";"A_P" "A_N";"R_A" "R_B";"E2_P" "E2_N";"V_P" "V_N"];
    for k=1:6
        r=bb(ids(k))/100; bg=[0.94 0.97 0.97];
        for j=1:2
            xy=tt(pairs(k,j))/100; edge=[r(1) xy(2)]; if xy(1)>r(1)+r(3)/2 then edge(1)=r(1)+r(3); end
            ld6_track_board(student_wire(p,xy,edge,[0.41 0.49 0.51],"lead:"+ids(k)));
        end
        fr=student_frame(p,r,bg); fr.tag="component:"+ids(k); ld6_track_board(fr);
        h=student_text(fr,[0.06 0.66 0.88 0.24],names(k),12,%t,bg); h.horizontalalignment="center";
        h=student_text(fr,[0.04 0.04 0.92 0.58],vals(k),14,%t,bg); h.horizontalalignment="center";
        h.tag="reading:"+ids(k);
        if k==4 then h.tooltipstring=msprintf("Krovinys R: %g Ω; nominali %d Ω ±5 %%.",LD6.cfg.R,LD6.cfg.Rnom); end
        if or(k==[1 5]) then h.tooltipstring="EV ir vidinė varža. Teigiama srovė atiduodama apkrovai; neigiama teka į šaltinį."; end
    end
    tids=ld6_terminal_ids();
    for id=matrix(tids,1,-1)
        bg=[0.08 0.39 0.37]; if id==LD6.pending then bg=[0.60 0.39 0.06]; end
        cb="ld6_terminal_click("""+id+""")";
        h=student_terminal(p,ld6_terminal_xy(id),ld6_terminal_button_text(id),ld6_terminal_code(id),cb,ld6_terminal_name(id),bg);
        h.horizontalalignment="center";
        if ~ld6_wiring_editable() then h.enable="off"; end
        LD6.term.handles($+1)=h; LD6.term.handleIds($+1,1)=id; LD6.ui.dynamic($+1)=h; ld6_track_board(h);
    end
    ld6_track_board(student_end_wires(p));
    for k=1:4
        h=LD6.ui.controls(k); h.backgroundcolor=[0.94 0.96 0.96]; h.foregroundcolor=[0.08 0.20 0.22];
        if LD6.wireMode==k then h.backgroundcolor=[0.08 0.39 0.37]; h.foregroundcolor=[1 1 1]; end
    end
    LD6.ui.controls(7).enable="off";
    if ~LD6.demoMode & or(LD6.step==[2 3 4 5]) & LD6.wireMode==ld6_stage_mode(LD6.step) then LD6.ui.controls(7).enable="on"; end
    ld6_font(p);
    LD6.fig.immediate_drawing=drawing;
endfunction

function ld6_render_journal()
    global LD6;
    if ~isfield(LD6,"ui") then return; end
    if ~isfield(LD6.ui,"journalList") then return; end
    rows=emptystr(0,1);
    modes=["E1";"Nuosekliai";"Priešpriešiais";"Lygiagrečiai"];
    for tag=1:4
        measurements=ld6_journal_rows(tag);
        for k=1:size(measurements,1)
            rows($+1)=msprintf("%s     %.4f V     %.3f mA",modes(tag),measurements(k,1),measurements(k,2));
        end
    end
    if rows==[] then rows="Matavimų dar nėra."; end
    LD6.ui.journalList.string=rows;
endfunction

function ld6_render_stage()
    global LD6;
    if ~isfield(LD6,"ui") then return; end
    if isfield(LD6.ui,"headless") then if LD6.ui.headless then return; end; end
    if ~isfield(LD6.ui,"answerEdits") then return; end
    row=0;
    for k=1:7
        [st,sl]=ld6_answer_slot(k); h=LD6.ui.answerEdits(k); lab=LD6.ui.answerLabels(k);
        h.visible="off"; lab.visible="off";
        if st==LD6.step then
            if LD6.step==6 then
                // Išvadų tekstai ilgesni, o atsakymas tik vienas skaitmuo.
                // Duodame tekstui daugiau pločio/aukščio, kad nereikėtų slinkties rodyklių.
                yy=0.53-row*0.14;
                lab.position=[0.07 yy 0.59 0.11];
                h.position=[0.72 yy+0.015 0.21 0.075];
            else
                yy=0.55-row*0.10;
                lab.position=[0.07 yy 0.53 0.075];
                h.position=[0.63 yy 0.30 0.075];
            end
            row=row+1;
            h.string=LD6.answers(st,sl); h.visible="on"; lab.visible="on";
            h.enable="on"; if LD6.demoMode then h.enable="off"; end
        end
    end
    LD6.ui.instructionLine(1).string=student_wrap(ld6_step_instruction(LD6.step),38);
    regime="ATSISKAITYMAS"; if ~LD6.assessment then regime="MOKYMASIS"; end
    LD6.ui.progress.string=string(LD6.step)+" / 6 etapas · "+regime;
    if LD6.demoMode then LD6.ui.progress.string="PAVYZDYS"; end
    LD6.ui.identity.string=student_caption(LD6.student);
    ld6_render_wires(); ld6_render_journal(); ld6_student_sync();
endfunction

function ld6_resize(id)
    global LD6;
    if typeof(LD6)<>"st" then return; end
    if ~isfield(LD6,"fig") then return; end
    if ~is_handle_valid(LD6.fig) then return; end
    if LD6.fig.figure_id<>id then return; end
    // Recompute fixed pixel terminal targets and crossing gaps. Keep raw edits.
    ld6_render_wires();
endfunction

function ld6_build_gui()
    global LD6;
    f=figure("resize","off","default_axes","off","dockable","off","menubar","none","toolbar","none","visible","off");
    f.axes_size=[1280 720]; f.figure_position=[10 10]; f.infobar_visible="off";
    f.figure_name="LD6 · Nuoseklus ir lygiagretus šaltinių jungimas"; f.background=color(246,248,249); LD6.fig=f;
    LD6.ui=struct("headless",%f,"boardHandles",list(),"dynamic",[],"controls",[]);
    LD6.term=struct("handles",list(),"handleIds",emptystr(0,1));
    student_text(f,[0.03 0.925 0.65 0.05],"LD6 / Nuoseklus ir lygiagretus šaltinių jungimas",22,%t,[0.965 0.973 0.977]);
    LD6.ui.progress=student_text(f,[0.705 0.93 0.15 0.044],"",14,%f,[0.965 0.973 0.977]);
    LD6.ui.identity=student_text(f,[0.03 0.895 0.94 0.025],"",12,%f,[0.965 0.973 0.977]);
    student_button(f,[0.87 0.93 0.105 0.044],"Pagalba","ld6_show_actions()");
    p=student_frame(f,[0.025 0.12 0.655 0.77]); LD6.ui.circuitFrame=p;
    right=student_frame(f,[0.70 0.12 0.275 0.77]); LD6.ui.right=right;
    student_text(p,[0.79 0.82 0.19 0.15],student_wrap("Laidas: spauskite abu galus. Pakartoję — pašalinsite. Tarpas sankirtoje: nesujungta.",22),12,%f);
    // Two unobstructed control rows. Measurement journal stays next to the circuit.
    LD6.ui.journalList=uicontrol(p,"style","listbox","units","normalized","position",[0.04 0.81 0.73 0.17], ...
        "string","Matavimai","fontname","DejaVu Sans","fontunits","pixels","fontsize",14,"tag","V02");
    controls=[];
    lbl=["E1";"Nuosekliai";"Priešpriešiais";"Lygiagrečiai"];
    for k=1:4
        cb="ld6_set_mode("+string(k)+")";
        controls($+1)=ld6_button(p,[0.02+(k-1)*0.185 0.020 0.175 0.070],lbl(k),cb,12);
    end
    controls($+1)=ld6_button(p,[0.80 0.40 0.18 0.06],"Maitinimas","ld6_toggle_power()",12);
    controls($+1)=ld6_button(p,[0.80 0.30 0.18 0.06],"Jungiklis","ld6_toggle_switch()",12);
    controls($+1)=ld6_button(p,[0.80 0.20 0.18 0.06],"Matuoti","ld6_measure()",13,[0.08 0.39 0.37]);
    LD6.ui.instructionLine(1)=student_text(right,[0.07 0.64 0.86 0.31],"",14,%f);
    LD6.ui.instructionLine(1).verticalalignment="top";
    labels=["Tik E1: teorinė apkrovos I, mA";"Nuosekliai: bendra EV EΣ, V"; ...
        "Priešpriešiais: bendra EV EΔ, V";"Lygiagrečiai: ekvivalentinė EV Eeq, V"; ...
        "Lygiagrečiai: ekvivalentinė vidinė req, Ω"; ...
        "Ar nuosekliai EV sudedamos su ženklais? 1 Taip / 2 Ne";"Ar lygiagrečiai U = E1 + E2? 1 Taip / 2 Ne"];
    LD6.ui.answerEdits=[]; LD6.ui.answerLabels=[];
    for k=1:7
        LD6.ui.answerLabels($+1)=student_text(right,[0.07 0.5 0.53 0.075],student_wrap(labels(k),22),14,%f);
        [st,sl]=ld6_answer_slot(k);
        h=uicontrol(right,"style","edit","units","normalized","position",[0.63 0.5 0.30 0.075], ...
            "string","","fontunits","pixels","fontsize",14,"fontname","DejaVu Sans", ...
            "tag",ld6_answer_code(st,sl),"callback","ld6_answers_changed()","backgroundcolor",[0.94 0.96 0.96]);
        LD6.ui.answerEdits($+1)=h;
    end
    LD6.ui.studentPrimary=ld6_button(right,[0.07 0.085 0.86 0.075],"Tikrinti","ld6_student_primary()",15,[0.08 0.39 0.37]);
    controls($+1)=LD6.ui.studentPrimary;
    controls($+1)=ld6_button(right,[0.07 0.015 0.37 0.045],"← Atgal","ld6_jump_step(LD6.step-1)",12);
    LD6.ui.controls=controls; LD6.ui.dynamic=controls;
    LD6.ui.statusMain=student_text(f,[0.025 0.055 0.95 0.035],"",13,%t,[0.94 0.96 0.96]);
    LD6.ui.statusFix=student_text(f,[0.025 0.020 0.95 0.035],"",12,%f,[0.94 0.96 0.96]);
    f.closerequestfcn="ld6_close()";
    ld6_font(f); student_finish_window(f); f.visible="on"; ld6_render_stage();
    f.resizefcn="ld6_resize("+string(f.figure_id)+")";
endfunction

function ld6_show_actions()
    global LD6;
    choice=x_choose(["Šio etapo pagalba";"Tęsti arba atkurti darbą"; ...
        "Ataskaita ir režimas";"Mano duomenys";"Daugiau veiksmų"],"LD6 · Pagalba");
    select choice
    case 1 then
        extra=x_choose(["Kaip sujungti";"Stendo žemėlapis"],"Šio etapo pagalba");
        if extra==1 then ld6_show_wiring_guide(); elseif extra==2 then ld6_show_stand_map(); end
    case 2 then
        extra=x_choose(["Tęsti automatinį juodraštį";"Atkurti šio etapo stendą"],"Tęsti arba atkurti darbą");
        if extra==1 then bench_open_snapshot("LD6"); elseif extra==2 then ld6_restore_stage(); end
    case 3 then
        extra=x_choose(["Išsaugoti ataskaitą";"Atsiskaitymo / mokymosi režimas"],"Ataskaita ir režimas");
        if extra==1 then ld6_export_report();
        elseif extra==2 then bench_mode("LD6"); ld6_render_stage(); bench_autosave("LD6"); end
    case 4 then
        ld6_student_details();
    case 5 then
        extra=x_choose(["Parodyti pavyzdį / mano darbą";"Pradėti darbą iš naujo"],"Daugiau veiksmų");
        if extra==1 then ld6_toggle_solution();
        elseif extra==2 then
            if messagebox("Pradėti darbą iš naujo? Laidai, matavimai ir atsakymai bus išvalyti.","LD6","question",["Pradėti" "Grįžti"],"modal")==1 then ld6_restart(); end
        end
    end
endfunction

// Java logical font exists on both Windows and Linux; no external font install.
function ld6_font(parent)
    for h=matrix(parent.children,1,-1)
        if h.type=="uicontrol" then
            h.fontname="SansSerif";
            ld6_font(h);
        end
    end
endfunction
