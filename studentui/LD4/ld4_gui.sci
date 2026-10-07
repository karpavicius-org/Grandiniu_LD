// Shared Scilab UI; numerical calculation and grading remain in the C++ core.
function h=ld4_button(p,pos,label,cb,fs,bg)
    if argn(2)<5 then fs=13; end
    if argn(2)<6 then bg=[0.94 0.96 0.96]; end
    code=""; hint="";
    try
        [code,registered,hint]=ld4_button_info(cb);
    catch
        code="";
    end
    h=student_button(p,pos,"<html><center>"+label+"</center></html>",cb);
    h.tag=code; h.tooltipstring=hint; h.fontsize=fs; h.backgroundcolor=bg;
    if sum(bg)<1.5 then h.foregroundcolor=[1 1 1]; end
endfunction

function [term_xy,boxes]=ld4_layout()
    global LD4;
    // All terminals sit outside their own component, with 36 x 40 px targets.
    boxes=struct("E",[7 63 15 16],"K",[38.5 65 12 14],"A",[66 63 14 16], ...
        "R1",[18 39 19 14],"R2",[54 39 19 14],"V",[35 12 21 16]);
    term_xy=struct("E_N",[4.5 72],"E_P",[24.5 72], ...
        "K1",[35.5 72],"K2",[53.5 72],"A_P",[63.5 72],"A_N",[83 72], ...
        "R1A",[15 46],"R1B",[40 46],"R2A",[51 46],"R2B",[76 46], ...
        "V_P",[32 20],"V_N",[59 20]);
    // The voltmeter follows the measured resistor, keeping the probe leads clear.
    m=ld4_wire_mode();
    if m==1 then boxes.V=[18 12 19 16]; term_xy.V_P=[15 20]; term_xy.V_N=[40 20];
    elseif m==2 then boxes.V=[54 12 19 16]; term_xy.V_P=[51 20]; term_xy.V_N=[76 20]; end
endfunction

function xy=ld4_terminal_xy(id)
    [tt,bb]=ld4_layout(); xy=tt(id)/100;
endfunction

function txt=ld4_terminal_button_text(id)
    select id
    case "E_P" then txt="+"; case "E_N" then txt="−";
    case "K1" then txt="1"; case "K2" then txt="2";
    case "A_P" then txt="+"; case "A_N" then txt="−";
    case "R1A" then txt="a"; case "R1B" then txt="b";
    case "R2A" then txt="a"; case "R2B" then txt="b";
    case "V_P" then txt="+"; case "V_N" then txt="−";
    end
endfunction

function ld4_track_board(h)
    global LD4;
    if h<>[] then
        for item=matrix(h,1,-1); LD4.ui.boardHandles($+1)=item; end
    end
endfunction

function ld4_clear_board()
    global LD4;
    for k=1:length(LD4.ui.boardHandles)
        h=LD4.ui.boardHandles(k);
        if is_handle_valid(h) then delete(h); end
    end
    LD4.ui.boardHandles=list(); LD4.term.handles=list(); LD4.term.handleIds=emptystr(0,1);
    // Only the permanent controls survive. No stale terminal handles accumulate.
    LD4.ui.dynamic=LD4.ui.controls;
endfunction

function ld4_polyline(points,col)
    global LD4;
    for k=1:size(points,1)-1
        ld4_track_board(student_wire(LD4.ui.circuitFrame,points(k,:),points(k+1,:),col));
    end
endfunction

function ld4_render_wires()
    global LD4;
    if ~isfield(LD4,"ui") then return; end
    if isfield(LD4.ui,"headless") then if LD4.ui.headless then return; end; end
    if ~isfield(LD4.ui,"circuitFrame") then return; end
    if ~is_handle_valid(LD4.ui.circuitFrame) then return; end
    drawing=LD4.fig.immediate_drawing; LD4.fig.immediate_drawing="off";
    ld4_clear_board(); p=LD4.ui.circuitFrame;
    ports=[];
    for id=matrix(ld4_terminal_ids(),1,-1); ports($+1,:)=[ld4_terminal_xy(id) 36 40]; end
    p.user_data=struct("ports",ports);
    student_begin_wires(p);
    for k=1:size(LD4.wires,1)
        a=LD4.wires(k,1); b=LD4.wires(k,2); p1=ld4_terminal_xy(a); p2=ld4_terminal_xy(b);
        col=[0.22 0.40 0.42];
        if or([a b]=="V_P") | or([a b]=="V_N") then col=[0.52 0.25 0.48]; end
        // Canonical routing is independent of which endpoint is clicked first.
        if (a=="A_N" & b=="R1A") | (b=="A_N" & a=="R1A") | (a=="A_N" & b=="R2A") | (b=="A_N" & a=="R2A") then
            pts=[p1;p1(1) 0.57;p2(1) 0.57;p2];
        elseif (a=="E_N" & b=="R1B") | (b=="E_N" & a=="R1B") | (a=="E_N" & b=="R2B") | (b=="E_N" & a=="R2B") then
            // Return rail is below both resistors. Probe crossings use gaps.
            pts=[p1;p1(1) 0.34;p2(1) 0.34;p2];
        elseif or([a b]=="V_P") | or([a b]=="V_N") then
            if a=="V_P" | a=="V_N" then pts=[p1;p2(1) p1(2);p2];
            else pts=[p1;p1(1) p2(2);p2]; end
        elseif (a=="R1B" & b=="R2A") | (b=="R1B" & a=="R2A") then
            pts=[p1;p2];  // nuoseklus tiltas tarp gretimų rezistorių — tiesus
        elseif abs(p1(1)-p2(1))<1e-9 | abs(p1(2)-p2(2))<1e-9 then pts=[p1;p2];
        else
            // Invalid student wiring stays visible and is rejected by the core.
            xm=(p1(1)+p2(1))/2; pts=[p1;xm p1(2);xm p2(2);p2];
        end
        ld4_polyline(pts,col);
    end
    [tt,bb]=ld4_layout(); ids=["E" "K" "A" "R1" "R2" "V"];
    names=["ŠALTINIS" "JUNGIKLIS" "AMPERMETRAS" "R1" "R2" "VOLTMETRAS"];
    switchText="Atviras"; if LD4.switchOn then switchText="Uždarytas"; end
    powerText="Išjungtas"; if LD4.powerOn then powerText=msprintf("%d V",LD4.voltage); end
    [u,i,valid,reason]=ld4_measure_values();
    ampText="— mA"; voltText="— V";
    if valid then ampText=msprintf("%.3f mA",i); voltText=msprintf("%g V",u); end
    vals=[powerText switchText ampText msprintf("%d Ω ±5%%",LD4.cfg.R1nom) ...
          msprintf("%d Ω ±5%%",LD4.cfg.R2nom) voltText];
    pairs=["E_N" "E_P";"K1" "K2";"A_P" "A_N";"R1A" "R1B";"R2A" "R2B";"V_P" "V_N"];
    for k=1:6
        r=bb(ids(k))/100; bg=[0.94 0.97 0.97];
        for j=1:2
            xy=tt(pairs(k,j))/100; edge=[r(1) xy(2)]; if j==2 then edge(1)=r(1)+r(3); end
            ld4_track_board(student_wire(p,xy,edge,[0.41 0.49 0.51],"lead:"+ids(k)));
        end
        fr=student_frame(p,r,bg); fr.tag="component:"+ids(k); ld4_track_board(fr);
        h=student_text(fr,[0.06 0.66 0.88 0.24],names(k),12,%t,bg); h.horizontalalignment="center";
        h=student_text(fr,[0.06 0.15 0.88 0.36],vals(k),16,%t,bg); h.horizontalalignment="center";
        h.tag="reading:"+ids(k);
    end
    tids=ld4_terminal_ids();
    for id=matrix(tids,1,-1)
        bg=[0.08 0.39 0.37]; if id==LD4.pending then bg=[0.60 0.39 0.06]; end
        cb="ld4_terminal_click("""+id+""")";
        h=student_terminal(p,ld4_terminal_xy(id),ld4_terminal_button_text(id),ld4_terminal_code(id),cb,ld4_terminal_name(id),bg);
        if LD4.demoMode | (LD4.step<>1 & LD4.step<>6) then h.enable="off"; end
        LD4.term.handles($+1)=h; LD4.term.handleIds($+1,1)=id; LD4.ui.dynamic($+1)=h; ld4_track_board(h);
    end
    ld4_track_board(student_end_wires(p));
    ld4_font(p);
    LD4.fig.immediate_drawing=drawing;
endfunction

function ld4_render_journal()
    global LD4;
    if ~isfield(LD4,"ui") then return; end
    if ~isfield(LD4.ui,"journalList") then return; end
    rows="Rezistorius       U, V          I, mA"; names=["R1" "R2" "R1+R2"];
    for tag=1:3
        measurements=ld4_journal_rows(tag);
        for k=1:size(measurements,1)
            rows($+1)=msprintf("%s                 %g              %.3f",names(tag),measurements(k,1),measurements(k,2));
        end
    end
    LD4.ui.journalList.string=rows;
endfunction

function ld4_render_stage()
    global LD4;
    if ~isfield(LD4,"ui") then return; end
    if isfield(LD4.ui,"headless") then if LD4.ui.headless then return; end; end
    if ~isfield(LD4.ui,"answerEdits") then return; end
    row=0;
    for k=1:11
        [st,sl]=ld4_answer_slot(k); h=LD4.ui.answerEdits(k); lab=LD4.ui.answerLabels(k);
        h.visible="off"; lab.visible="off";
        if st==LD4.step then
            yy=0.55-row*0.10; row=row+1;
            lab.position=[0.07 yy 0.53 0.075]; h.position=[0.63 yy 0.30 0.075];
            h.string=LD4.answers(st,sl); h.visible="on"; lab.visible="on";
        end
    end
    LD4.ui.instructionLine(1).string=student_wrap(ld4_step_instruction(LD4.step),38);
    regime="ATSISKAITYMAS"; if ~LD4.assessment then regime="MOKYMASIS"; end
    LD4.ui.progress.string=string(LD4.step)+" / 7 etapas · "+regime;
    LD4.ui.identity.string=student_caption(LD4.student);
    ld4_render_wires(); ld4_render_journal(); ld4_student_sync();
endfunction

function ld4_build_gui()
    global LD4;
    f=figure("resize","off","default_axes","off","dockable","off","menubar","none","toolbar","none","visible","off");
    f.axes_size=[1280 720]; f.figure_position=[10 10]; f.infobar_visible="off";
    f.figure_name="LD4 · Tiesinių rezistorių tyrimas"; f.background=color(246,248,249); LD4.fig=f;
    LD4.ui=struct("headless",%f,"boardHandles",list(),"dynamic",[],"controls",[]);
    LD4.term=struct("handles",list(),"handleIds",emptystr(0,1));
    student_text(f,[0.03 0.925 0.65 0.05],"LD4  /  Tiesinių rezistorių tyrimas",22,%t,[0.965 0.973 0.977]);
    LD4.ui.progress=student_text(f,[0.705 0.93 0.15 0.044],"",14,%f,[0.965 0.973 0.977]);
    LD4.ui.identity=student_text(f,[0.03 0.895 0.94 0.025],"",12,%f,[0.965 0.973 0.977]);
    student_button(f,[0.87 0.93 0.105 0.044],"Pagalba","ld4_show_actions()");
    p=student_frame(f,[0.025 0.12 0.655 0.77]); LD4.ui.circuitFrame=p;
    right=student_frame(f,[0.70 0.12 0.275 0.77]); LD4.ui.right=right;
    student_text(p,[0.79 0.82 0.19 0.15],student_wrap("Laidas: spauskite abu galus. Pakartoję — pašalinsite. Tarpas sankirtoje: nesujungta.",22),12,%f);
    // Two unobstructed control rows. Measurement journal stays next to the circuit.
    LD4.ui.journalList=uicontrol(p,"style","listbox","units","normalized","position",[0.04 0.82 0.73 0.15], ...
        "string","Matavimai","fontname","DejaVu Sans","fontunits","pixels","fontsize",14,"tag","V02");
    controls=[];
    for k=1:3
        vv=LD4.cfg("U"+string(k)); cb="ld4_set_voltage(LD4.cfg.U"+string(k)+")";
        controls($+1)=ld4_button(p,[0.02+(k-1)*0.165 0.025 0.155 0.060],"U"+string(k)+" = "+string(vv)+" V",cb);
    end
    controls($+1)=ld4_button(p,[0.515 0.025 0.155 0.060],"Į R2","ld4_set_resistor(2)",12,[0.52 0.25 0.48]);
    controls($+1)=ld4_button(p,[0.80 0.40 0.18 0.06],"Maitinimas","ld4_toggle_power()",12);
    controls($+1)=ld4_button(p,[0.80 0.30 0.18 0.06],"Jungiklis","ld4_toggle_switch()",12);
    controls($+1)=ld4_button(p,[0.80 0.20 0.18 0.06],"Matuoti","ld4_measure()",13,[0.08 0.39 0.37]);
    LD4.ui.instructionLine(1)=student_text(right,[0.07 0.64 0.86 0.31],"",14,%f);
    LD4.ui.instructionLine(1).verticalalignment="top";
    labels=["I1 teorinė, mA";"R1 iš matavimų, Ω";"R2 iš matavimų, Ω";"R1 nuokrypis, %"; ...
        "R2 nuokrypis, %";"R1 iš nuolydžio, Ω";"R2 iš nuolydžio, Ω";"G2, mS"; ...
        "R1 + R2 iš matavimo, Ω";"Ar abi I(U) tiesinės? 1 Taip / 2 Ne";"Ar nuokrypis ≤ 5 %? 1 Taip / 2 Ne"];
    LD4.ui.answerEdits=[]; LD4.ui.answerLabels=[];
    for k=1:11
        LD4.ui.answerLabels($+1)=student_text(right,[0.07 0.5 0.53 0.075],student_wrap(labels(k),22),14,%f);
        [st,sl]=ld4_answer_slot(k);
        h=uicontrol(right,"style","edit","units","normalized","position",[0.63 0.5 0.30 0.075], ...
            "string","","fontunits","pixels","fontsize",14,"fontname","DejaVu Sans", ...
            "tag",ld4_answer_code(st,sl),"callback","ld4_answers_changed()","backgroundcolor",[0.94 0.96 0.96]);
        LD4.ui.answerEdits($+1)=h;
    end
    LD4.ui.studentPrimary=ld4_button(right,[0.07 0.085 0.86 0.075],"Tikrinti","ld4_student_primary()",15,[0.08 0.39 0.37]);
    controls($+1)=LD4.ui.studentPrimary;
    controls($+1)=ld4_button(right,[0.07 0.015 0.37 0.045],"← Atgal","ld4_jump_step(LD4.step-1)",12);
    LD4.ui.controls=controls; LD4.ui.dynamic=controls;
    LD4.ui.statusMain=student_text(f,[0.025 0.055 0.95 0.035],"",13,%t,[0.94 0.96 0.96]);
    LD4.ui.statusFix=student_text(f,[0.025 0.020 0.95 0.035],"",12,%f,[0.94 0.96 0.96]);
    f.closerequestfcn="ld4_close()";
    ld4_font(f); student_finish_window(f); f.visible="on"; ld4_render_stage();
endfunction

function ld4_show_actions()
    global LD4;
    choice=x_choose(["Šio etapo pagalba";"Tęsti arba atkurti darbą"; ...
        "Ataskaita ir režimas";"Mano duomenys";"Daugiau veiksmų"],"LD4 · Pagalba");
    select choice
    case 1 then
        extra=x_choose(["Kaip sujungti";"Stendo žemėlapis"],"Šio etapo pagalba");
        if extra==1 then ld4_show_wiring_guide(); elseif extra==2 then ld4_show_stand_map(); end
    case 2 then
        extra=x_choose(["Tęsti automatinį juodraštį";"Atkurti šio etapo stendą"],"Tęsti arba atkurti darbą");
        if extra==1 then bench_open_snapshot("LD4"); elseif extra==2 then ld4_restore_stage(); end
    case 3 then
        extra=x_choose(["Išsaugoti ataskaitą";"Atsiskaitymo / mokymosi režimas"],"Ataskaita ir režimas");
        if extra==1 then ld4_export_report();
        elseif extra==2 then bench_mode("LD4"); ld4_render_stage(); bench_autosave("LD4"); end
    case 4 then
        ld4_student_details();
    case 5 then
        extra=x_choose(["Parodyti pavyzdį / mano darbą";"Pradėti darbą iš naujo"],"Daugiau veiksmų");
        if extra==1 then ld4_toggle_solution();
        elseif extra==2 then
            if messagebox("Pradėti darbą iš naujo? Laidai, matavimai ir atsakymai bus išvalyti.","LD4","question",["Pradėti" "Grįžti"],"modal")==1 then ld4_restart(); end
        end
    end
endfunction

// Java logical font exists on both Windows and Linux; no external font install.
function ld4_font(parent)
    for h=matrix(parent.children,1,-1)
        if h.type=="uicontrol" then
            h.fontname="SansSerif";
            ld4_font(h);
        end
    end
endfunction
