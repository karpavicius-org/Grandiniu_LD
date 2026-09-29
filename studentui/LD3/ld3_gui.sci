// Shared Scilab UI; numerical calculation and grading remain in the C++ core.
function h=ld3_button(p,pos,label,cb,fs,bg)
    if argn(2)<5 then fs=13; end
    if argn(2)<6 then bg=[0.94 0.96 0.96]; end
    code=""; hint="";
    try
        [code,registered,hint]=ld3_button_info(cb);
    catch
        code="";
    end
    if code<>"" then label="["+code+"] "+label; end
    h=student_button(p,pos,"<html><center>"+label+"</center></html>",cb);
    h.tag=code; h.tooltipstring=hint; h.fontsize=fs; h.backgroundcolor=bg;
    if sum(bg)<1.5 then h.foregroundcolor=[1 1 1]; end
endfunction

function [term_xy,boxes]=ld3_layout()
    // Contacts are 36 x 40 client pixels. Short leads join each to its owner.
    // R and V share the same horizontal extent: both probes are vertical.
    boxes=struct("E",[9 61 16 19],"K",[42 61 14 19],"A",[73 61 17 19], ...
        "R1",[51 36 18 14],"V",[51 13 18 16]);
    term_xy=struct("E_N",[6.5 70.5],"E_P",[27.5 70.5], ...
        "K1",[39.5 70.5],"K2",[58.5 70.5],"A_P",[70.5 70.5],"A_N",[92.5 70.5], ...
        "R1B",[48.5 43],"R1A",[71.5 43],"V_N",[48.5 21],"V_P",[71.5 21]);
endfunction

function xy=ld3_terminal_xy(id)
    [tt,bb]=ld3_layout(); xy=tt(id)/100;
endfunction

function txt=ld3_terminal_button_text(id)
    select id
    case "E_P" then txt="+"; case "E_N" then txt="−";
    case "K1" then txt="1"; case "K2" then txt="2";
    case "A_P" then txt="+"; case "A_N" then txt="−";
    case "R1A" then txt="a"; case "R1B" then txt="b";
    case "V_P" then txt="+"; case "V_N" then txt="−";
    end
endfunction

function ld3_track_board(h)
    global LD3;
    if h<>[] then
        for item=matrix(h,1,-1); LD3.ui.boardHandles($+1)=item; end
    end
endfunction

function ld3_clear_board()
    global LD3;
    for k=1:length(LD3.ui.boardHandles)
        h=LD3.ui.boardHandles(k);
        if is_handle_valid(h) then delete(h); end
    end
    LD3.ui.boardHandles=list(); LD3.term.handles=list(); LD3.term.handleIds=emptystr(0,1);
    // Only the permanent controls survive. No stale terminal handles accumulate.
    LD3.ui.dynamic=LD3.ui.controls;
endfunction

function ld3_polyline(points,col)
    global LD3;
    for k=1:size(points,1)-1
        ld3_track_board(student_wire(LD3.ui.circuitFrame,points(k,:),points(k+1,:),col));
    end
endfunction

function ld3_render_wires()
    global LD3;
    if ~isfield(LD3,"ui") then return; end
    if isfield(LD3.ui,"headless") then if LD3.ui.headless then return; end; end
    if ~isfield(LD3.ui,"circuitFrame") then return; end
    if ~is_handle_valid(LD3.ui.circuitFrame) then return; end
    drawing=LD3.fig.immediate_drawing; LD3.fig.immediate_drawing="off";
    ld3_clear_board(); p=LD3.ui.circuitFrame;
    ports=[];
    for id=matrix(ld3_terminal_ids(),1,-1); ports($+1,:)=[ld3_terminal_xy(id) 36 40]; end
    p.user_data=struct("ports",ports);
    student_begin_wires(p);
    for k=1:size(LD3.wires,1)
        a=LD3.wires(k,1); b=LD3.wires(k,2); p1=ld3_terminal_xy(a); p2=ld3_terminal_xy(b);
        col=[0.22 0.40 0.42];
        if or([a b]=="V_P") | or([a b]=="V_N") then col=[0.52 0.25 0.48]; end
        // Canonical routing is independent of which endpoint is clicked first.
        if (a=="A_N" & b=="R1A") | (b=="A_N" & a=="R1A") then
            pts=[p1;p1(1) 0.54;p2(1) 0.54;p2];
        elseif (a=="E_N" & b=="R1B") | (b=="E_N" & a=="R1B") then
            if a=="E_N" then pts=[p1;p1(1) p2(2);p2]; else pts=[p1;p2(1) p1(2);p2]; end
        elseif abs(p1(1)-p2(1))<1e-9 | abs(p1(2)-p2(2))<1e-9 then pts=[p1;p2];
        else
            // Invalid student wiring stays visible and is rejected by the core.
            xm=(p1(1)+p2(1))/2; pts=[p1;xm p1(2);xm p2(2);p2];
        end
        ld3_polyline(pts,col);
    end
    [tt,bb]=ld3_layout(); ids=["E" "K" "A" "R1" "V"];
    names=["ŠALTINIS" "JUNGIKLIS" "AMPERMETRAS" "R1" "VOLTMETRAS"];
    switchText="Atviras"; if LD3.switchOn then switchText="Uždarytas"; end
    powerText="Išjungtas"; if LD3.powerOn then powerText=msprintf("%d V",LD3.voltage); end
    ampText="— mA"; if ~isnan(LD3.lastMeasurement) then ampText=msprintf("%.2f mA",LD3.lastMeasurement); end
    vals=[powerText switchText ampText msprintf("%d Ω",LD3.cfg.R) msprintf("%d V",LD3.voltage)];
    pairs=["E_N" "E_P";"K1" "K2";"A_P" "A_N";"R1B" "R1A";"V_N" "V_P"];
    for k=1:5
        r=bb(ids(k))/100; bg=[0.94 0.97 0.97];
        for j=1:2
            xy=tt(pairs(k,j))/100; edge=[r(1) xy(2)]; if j==2 then edge(1)=r(1)+r(3); end
            ld3_track_board(student_wire(p,xy,edge,[0.41 0.49 0.51],"lead:"+ids(k)));
        end
        fr=student_frame(p,r,bg); fr.tag="component:"+ids(k); ld3_track_board(fr);
        h=student_text(fr,[0.06 0.66 0.88 0.24],names(k),12,%t,bg); h.horizontalalignment="center";
        h=student_text(fr,[0.06 0.15 0.88 0.36],vals(k),16,%t,bg); h.horizontalalignment="center";
    end
    tids=ld3_terminal_ids();
    for id=matrix(tids,1,-1)
        bg=[0.08 0.39 0.37]; if id==LD3.pending then bg=[0.60 0.39 0.06]; end
        cb="ld3_terminal_click("""+id+""")";
        h=student_terminal(p,ld3_terminal_xy(id),ld3_terminal_button_text(id),ld3_terminal_code(id),cb,ld3_terminal_name(id),bg);
        if LD3.demoMode | LD3.step<>1 then h.enable="off"; end
        LD3.term.handles($+1)=h; LD3.term.handleIds($+1,1)=id; LD3.ui.dynamic($+1)=h; ld3_track_board(h);
    end
    ld3_track_board(student_end_wires(p));
    LD3.fig.immediate_drawing=drawing;
endfunction

function ld3_render_journal()
    global LD3;
    if ~isfield(LD3,"ui") then return; end
    if ~isfield(LD3.ui,"journalList") then return; end
    rows="U, V         I, mA";
    for m=1:size(LD3.journal,1)
        rows($+1)=msprintf("%g              %.2f",LD3.journal(m,1),LD3.journal(m,2));
    end
    LD3.ui.journalList.string=rows;
endfunction

function ld3_render_stage()
    global LD3;
    if ~isfield(LD3,"ui") then return; end
    if isfield(LD3.ui,"headless") then if LD3.ui.headless then return; end; end
    if ~isfield(LD3.ui,"answerEdits") then return; end
    row=0;
    for k=1:8
        [st,sl]=ld3_answer_slot(k); h=LD3.ui.answerEdits(k); lab=LD3.ui.answerLabels(k);
        h.visible="off"; lab.visible="off";
        if st==LD3.step then
            yy=0.55-row*0.10; row=row+1;
            lab.position=[0.07 yy 0.53 0.075]; h.position=[0.63 yy 0.30 0.075];
            h.string=LD3.answers(st,sl); h.visible="on"; lab.visible="on";
        end
    end
    LD3.ui.instructionLine(1).string=student_wrap(ld3_step_instruction(LD3.step),38);
    LD3.ui.progress.string=string(LD3.step)+" / 6 etapas";
    LD3.ui.identity.string=student_caption(LD3.student);
    ld3_render_wires(); ld3_render_journal(); ld3_student_sync();
endfunction

function ld3_build_gui()
    global LD3;
    f=figure("resize","off","default_axes","off","dockable","off","menubar","none","toolbar","none","visible","off");
    f.axes_size=[1280 720]; f.figure_position=[10 10]; f.infobar_visible="off";
    f.figure_name="LD3 · Omo dėsnio stendas"; f.background=color(246,248,249); LD3.fig=f;
    LD3.ui=struct("headless",%f,"boardHandles",list(),"dynamic",[],"controls",[]);
    LD3.term=struct("handles",list(),"handleIds",emptystr(0,1));
    student_text(f,[0.03 0.925 0.65 0.05],"LD3  /  Omo dėsnis",22,%t,[0.965 0.973 0.977]);
    LD3.ui.progress=student_text(f,[0.705 0.93 0.15 0.044],"",14,%f,[0.965 0.973 0.977]);
    LD3.ui.identity=student_text(f,[0.03 0.895 0.94 0.025],"",12,%f,[0.965 0.973 0.977]);
    student_button(f,[0.87 0.93 0.105 0.044],"Pagalba","ld3_show_actions()");
    p=student_frame(f,[0.025 0.12 0.655 0.77]); LD3.ui.circuitFrame=p;
    right=student_frame(f,[0.70 0.12 0.275 0.77]); LD3.ui.right=right;
    student_text(p,[0.04 0.87 0.92 0.065],"Omo dėsnio stendas · I = U / R",19,%t);
    // Two unobstructed control rows. Measurement journal stays next to the circuit.
    LD3.ui.journalList=uicontrol(p,"style","listbox","units","normalized","position",[0.04 0.13 0.28 0.25], ...
        "string","Matavimai","fontname","DejaVu Sans","fontunits","pixels","fontsize",14,"tag","V02");
    controls=[];
    for k=1:3
        vv=LD3.cfg("U"+string(k)); cb="ld3_set_voltage(LD3.cfg.U"+string(k)+")";
        controls($+1)=ld3_button(p,[0.04+(k-1)*0.20 0.025 0.18 0.060],"U"+string(k)+" = "+string(vv)+" V",cb);
    end
    controls($+1)=ld3_button(p,[0.755 0.35 0.21 0.06],"Maitinimas","ld3_toggle_power()",12);
    controls($+1)=ld3_button(p,[0.755 0.25 0.21 0.06],"Jungiklis","ld3_toggle_switch()",12);
    controls($+1)=ld3_button(p,[0.755 0.15 0.21 0.06],"Matuoti","ld3_measure()",13,[0.08 0.39 0.37]);
    LD3.ui.instructionLine(1)=student_text(right,[0.07 0.64 0.86 0.31],"",14,%f);
    LD3.ui.instructionLine(1).verticalalignment="top";
    labels=["[A02.01] I1 teorinė, mA";"[A04.01] R1, Ω";"[A04.02] R2, Ω";"[A04.03] R3, Ω"; ...
        "[A04.04] Rvid, Ω";"[A05.01] R iš nuolydžio, Ω";"[A06.01] Tiesinė? 1 Taip / 2 Ne";"[A06.02] R pastovi? 1 Taip / 2 Ne"];
    LD3.ui.answerEdits=[]; LD3.ui.answerLabels=[];
    for k=1:8
        LD3.ui.answerLabels($+1)=student_text(right,[0.07 0.5 0.53 0.075],student_wrap(labels(k),22),14,%f);
        [st,sl]=ld3_answer_slot(k);
        h=uicontrol(right,"style","edit","units","normalized","position",[0.63 0.5 0.30 0.075], ...
            "string","","fontunits","pixels","fontsize",14,"fontname","DejaVu Sans", ...
            "tag",ld3_answer_code(st,sl),"callback","ld3_answers_changed()","backgroundcolor",[0.94 0.96 0.96]);
        LD3.ui.answerEdits($+1)=h;
    end
    LD3.ui.studentPrimary=ld3_button(right,[0.07 0.085 0.86 0.075],"Tikrinti","ld3_student_primary()",15,[0.08 0.39 0.37]);
    controls($+1)=LD3.ui.studentPrimary;
    controls($+1)=ld3_button(right,[0.07 0.015 0.37 0.045],"← Atgal","ld3_jump_step(LD3.step-1)",12);
    controls($+1)=ld3_button(right,[0.48 0.015 0.45 0.045],"Žemėlapis","ld3_show_stand_map()",12);
    LD3.ui.controls=controls; LD3.ui.dynamic=controls;
    LD3.ui.statusMain=student_text(f,[0.025 0.055 0.95 0.035],"",13,%t,[0.94 0.96 0.96]);
    LD3.ui.statusFix=student_text(f,[0.025 0.020 0.95 0.035],"",12,%f,[0.94 0.96 0.96]);
    f.closerequestfcn="ld3_close()";
    student_finish_window(f); f.visible="on"; ld3_render_stage();
endfunction

function ld3_show_actions()
    global LD3;
    choice=x_choose(["Tęsti išsaugotą darbą";"[B04] Kaip sujungti";"[B08] Išsaugoti ataskaitą"; ...
        "Mokymosi / atsiskaitymo režimas";"Daugiau veiksmų";"Studentas ir priskirtos reikšmės"],"LD3 · Pagalba");
    select choice
    case 1 then bench_open_snapshot("LD3");
    case 2 then ld3_show_wiring_guide();
    case 3 then bench_export_current("LD3");
    case 4 then bench_mode("LD3"); ld3_student_sync(); bench_autosave("LD3");
    case 6 then ld3_text_window("Studentas ir priskirtos reikšmės",[student_caption(LD3.student);"";student_parameter_lines("LD3",LD3.cfg)]);
    case 5 then
        extra=x_choose(["[B05] Žemėlapis";"[B07] Pavyzdys";"[B06] Atkurti stendą";"[B09] Pradėti iš naujo"],"LD3 · Daugiau veiksmų");
        select extra
        case 1 then ld3_show_stand_map();
        case 2 then ld3_toggle_solution();
        case 3 then ld3_restore_stage();
        case 4 then
            if messagebox("Pradėti darbą iš naujo? Atsakymai bus išvalyti.","LD3","question",["Pradėti" "Grįžti"],"modal")==1 then ld3_restart(); end
        end
    end
endfunction
