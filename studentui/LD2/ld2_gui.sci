// LD2 drawing and reusable UI primitives. The single real student GUI is in
// ld2_student.sci; do not reintroduce shadowed legacy GUI implementations.



function ld2_track(h)
    global LD2;
    LD2.ui.dynamic = [matrix(LD2.ui.dynamic,1,-1) matrix(h,1,-1)];
endfunction

function ld2_clear_dynamic()
    global LD2;
    if ~isfield(LD2.ui,"dynamic") then LD2.ui.dynamic=[]; end
    n = size(LD2.ui.dynamic, "*");
    if n > 0 then
        for k = n:-1:1
            delete(LD2.ui.dynamic(k));
        end
    end
    LD2.ui.dynamic = [];
    LD2.ui.term_handles = struct("dummy",0);
    LD2.ui.answer_edits = [];
    LD2.ui.answer_step = 0;
    LD2.ui.choice_yes = [];
    LD2.ui.choice_no = [];
endfunction

function h = ld2_frame(parent, pos, bg)
    h = uicontrol(parent, "style","frame", "units","normalized", ...
        "position",pos, "backgroundcolor",bg);
    ld2_track(h);
endfunction

function h = ld2_text(parent, pos, str, fs, bold, align, bg, fg)
    if size(strindex(str,ascii(10)),"*")>0 then str="<html>"+strsubst(str,ascii(10),"<br>")+"</html>"; end
    h = uicontrol(parent, "style","text", "units","normalized", ...
        "position",pos, "string",str, "fontname","DejaVu Sans", "fontunits","pixels", "fontsize",max([11 fs]), ...
        "horizontalalignment",align, "backgroundcolor",bg, ...
        "foregroundcolor",fg);
    if bold then h.fontweight = "bold"; end
    ld2_track(h);
endfunction

function h = ld2_button(parent, pos, str, cb, fs, bg)
    h = uicontrol(parent, "style","pushbutton", "units","normalized", ...
        "position",pos, "string",str, "fontname","DejaVu Sans", "fontunits","pixels", "fontsize",max([11 fs]), ...
        "callback",cb, "backgroundcolor",bg);
    // Numerių registras: [Bxx] priešdelis (kai telpa), tag ir tooltip.
    // h.callback lieka NEPAKITĖS – jį tiksliai naudoja testai.
    registered=%f;
    try
        [code,label,hint]=ld2_button_info(cb);
        registered=%t;
    catch
    end
    if registered then
        if pos(3)>=0.25 then h.string="["+code+"] "+str; end
        h.tag=code;
        h.tooltipstring="["+code+"] "+label+". "+hint;
    end
    ld2_track(h);
endfunction

function h = ld2_edit(parent, pos, value)
    h = uicontrol(parent, "style","edit", "units","normalized", ...
        "position",pos, "string",value, "fontname","DejaVu Sans", "fontunits","pixels", "fontsize",13, ...
        "horizontalalignment","right", "backgroundcolor",[0.94 0.96 0.96],"relief","solid");
    ld2_track(h);
endfunction






function [labels,n]=ld2_answer_spec(step)
    labels=emptystr(0,1);
    if step==11 then labels="BW = f2 - f1, Hz"; end
    n=size(labels,"*");
endfunction

function lines = ld2_summary_lines_for_step(step)
    global LD2;
    select step
    case 1 then
        rr = ld2_resonance_values(LD2.cfg.R13,LD2.cfg.L3,LD2.cfg.C4);
        lines = [ ...
          msprintf("RC: E=%.1f V, f=%.1f Hz, R8=%.0f Ω, C2=%.3f µF", ...
              LD2.cfg.E_RC,LD2.cfg.F_RC,LD2.cfg.R8,LD2.cfg.C2*1e6); ...
          msprintf("RL: E=%.1f V, f=%.1f Hz, R9=%.0f Ω, L1=%.3f H", ...
              LD2.cfg.E_RL,LD2.cfg.F_RL,LD2.cfg.R9,LD2.cfg.L1); ...
          msprintf("RLC: E=%.1f V, R13=%.0f Ω, L3=%.3f mH, C4=%.3f nF", ...
              LD2.cfg.E_RLC,LD2.cfg.R13,LD2.cfg.L3*1e3,LD2.cfg.C4*1e9); ...
          msprintf("Pagal šiuos parametrus fr=%.2f Hz.", rr.F0); ...
          "Numatytosios R8/R9/R13/L3/C4 vertės yra redaguojamos."];
    case 2 then
        [ok,missing]=ld2_validate_main("RC");
        lines = [msprintf("Prijungta laidų: %d iš 4.", size(LD2.state.rc_connections,1)); ...
                 "Mėlyni lizdai – pagrindinė grandinė."; ...
                 "Žali lizdai – jau teisingai prijungti."; ...
                 "Grandinės būsena: " + ld2_bool_text(ok)];
    case 4 then
        lines = [ ...
          "A~: " + ld2_value_or_dash(LD2.state.rc_I*1000,"mA"); ...
          "UR8: " + ld2_value_or_dash(LD2.state.rc_UR,"V"); ...
          "UC2: " + ld2_value_or_dash(LD2.state.rc_UC,"V"); ...
          "Ušaltinio: " + ld2_value_or_dash(LD2.state.rc_UE,"V")];
    case 5 then
        [ok,missing]=ld2_validate_main("RL");
        lines = [msprintf("Prijungta laidų: %d iš 4.", size(LD2.state.rl_connections,1)); ...
                 "Mėlyni lizdai – pagrindinė grandinė."; ...
                 "Žali lizdai – jau teisingai prijungti."; ...
                 "Grandinės būsena: " + ld2_bool_text(ok)];
    case 7 then
        lines = [ ...
          "A~: " + ld2_value_or_dash(LD2.state.rl_I*1000,"mA"); ...
          "UR9: " + ld2_value_or_dash(LD2.state.rl_UR,"V"); ...
          "UL1: " + ld2_value_or_dash(LD2.state.rl_UL,"V"); ...
          "Ušaltinio: " + ld2_value_or_dash(LD2.state.rl_UE,"V")];
    case 8 then
        [ok,missing]=ld2_validate_main("RLC");
        lines = [msprintf("Prijungta laidų: %d iš 5.", size(LD2.state.rlc_connections,1)); ...
                 "Grandinė: generatorius–A~–C4–L3–R13–grįžimas."; ...
                 "Grandinės būsena: " + ld2_bool_text(ok)];
    case 12 then
        rcok = ~isnan(LD2.state.rc_I) & ~isnan(LD2.state.rc_UR) & ~isnan(LD2.state.rc_UC);
        rlok = ~isnan(LD2.state.rl_I) & ~isnan(LD2.state.rl_UR) & ~isnan(LD2.state.rl_UL);
        rok = size(LD2.state.sweep_f,"*") > 0;
        lines = [ ...
          "RC matavimai: " + ld2_bool_text(rcok); ...
          "RL matavimai: " + ld2_bool_text(rlok); ...
          "RLC rezonanso taškai: " + string(size(LD2.state.res_f,"*")); ...
          "0–10 kHz skenavimas: " + ld2_bool_text(rok); ...
          "GRAFIKAS rodo lentelę; ŽURNALAS – matavimų kilmę."];
    else
        lines = ["Šiame etape atsakymų laukai rodomi aukščiau."; ...
                 "PAVYZDYS nepakeičia jūsų darbo."];
    end
endfunction

function s = ld2_bool_text(v)
    if v then s="ATLIKTA / TEISINGA"; else s="NEATLIKTA"; end
endfunction

function txt = ld2_amp_display_text()
    global LD2;
    phase = ld2_phase_for_step(LD2.state.step);
    [ok,missing] = ld2_validate_main(phase);
    if ~ok then txt="— mA"; return; end
    if ~LD2.state.power then txt="— mA"; return; end
    x=LD2.state.amp_live;
    if isnan(x) then txt="— mA"; else txt=ld2_num(x*1000,3)+" mA"; end
endfunction

function txt = ld2_volt_display_text()
    global LD2;
    phase = ld2_phase_for_step(LD2.state.step);
    target = ld2_detect_voltage_target(phase);
    if target == "" then txt="— V"; return; end
    if ~LD2.state.power then txt="— V"; return; end
    x=LD2.state.volt_live;
    if LD2.state.volt_live_target<>target then x=%nan; end
    if isnan(x) then txt="— V"; else txt=ld2_num(x,3)+" V"; end
endfunction



// ---------------------------------------------------------------------------
// Stendo braižymas
// ---------------------------------------------------------------------------

function ld2_render_stand()
    global LD2;
    step=LD2.state.step;
    phase=ld2_phase_for_step(step);
    p=LD2.ui.stand;
    if phase=="OVERVIEW" then
        ld2_draw_overview(p);
    else
        ld2_draw_phase_stand(p, phase, step);
    end
endfunction



function active=ld2_active_terminals(step)
    active=emptystr(0,1);
    if or(step==[2 5 8]) then
        req=ld2_required_main(ld2_phase_for_step(step));active=matrix(req,-1,1);
    end
endfunction

function tf = ld2_in_string_list(id, listv)
    tf=%f;
    for k=1:size(listv,"*")
        if id==listv(k) then tf=%t; return; end
    end
endfunction


function ld2_draw_chain_common(parent,phase,labelR,labelX,prefixR,prefixX,active,c)
    global LD2;
    // Komponentai
    ld2_component_box(parent,[0.04 0.40 0.15 0.20],"GENERATORIUS", ...
        ld2_source_text(phase),[0.90 0.95 1.00]);
    ld2_component_box(parent,[0.27 0.55 0.12 0.14],"A~", ...
        "AMPERMETRAS",[0.91 0.97 0.92]);
    ld2_component_box(parent,[0.48 0.55 0.13 0.14],labelR, ...
        "AKTYVIOJI VARŽA",[1.00 0.97 0.87]);
    ld2_component_box(parent,[0.70 0.55 0.13 0.14],labelX, ...
        "REAKTYVUS ELEMENTAS",[1.00 0.97 0.87]);
    ld2_component_box(parent,[0.42 0.14 0.20 0.14],"V~ VOLTMETRAS", ...
        "RMS",[0.91 0.97 0.92]);

    ids=["GEN_H";"GEN_L";"GEN_MH";"GEN_ML";"AM_H";"AM_L"; ...
         prefixR+"_1";prefixR+"_2";prefixR+"_M1";prefixR+"_M2"; ...
         prefixX+"_1";prefixX+"_2";prefixX+"_M1";prefixX+"_M2";"VM_H";"VM_L"];
    labs=["~";"0";"M~";"M0";"A";"COM"; ...
          "1";"2";"M1";"M2";"1";"2";"M1";"M2";"V";"COM"];
    for k=1:size(ids,"*")
        [x,y]=ld2_terminal_xy(phase,ids(k));
        ld2_draw_terminal(parent,ids(k),labs(k),[x y],active,c);
    end

endfunction

function s=ld2_source_text(phase)
    global LD2;
    select phase
    case "RC" then s=msprintf("%g V RMS • %g Hz",LD2.cfg.E_RC,LD2.cfg.F_RC);
    case "RL" then s=msprintf("%g V RMS • %g Hz",LD2.cfg.E_RL,LD2.cfg.F_RL);
    case "RLC" then s=msprintf("%g V RMS • %g Hz",LD2.cfg.E_RLC,LD2.state.freq);
    end
endfunction

function ld2_draw_rlc_chain(parent,active,c)
    global LD2;
    ld2_component_box(parent,[0.025 0.40 0.13 0.20],"GENERATORIUS", ...
        ld2_source_text("RLC"),[0.90 0.95 1.00]);
    ld2_component_box(parent,[0.22 0.55 0.10 0.13],"A~", ...
        "AMPERMETRAS",[0.91 0.97 0.92]);
    ld2_component_box(parent,[0.39 0.55 0.10 0.13], ...
        msprintf("C4 = %g nF",LD2.cfg.C4*1e9),"KONDENSATORIUS",[1.00 0.97 0.87]);
    ld2_component_box(parent,[0.56 0.55 0.10 0.13], ...
        msprintf("L3 = %g mH",LD2.cfg.L3*1e3),"RITĖ",[1.00 0.97 0.87]);
    ld2_component_box(parent,[0.73 0.55 0.10 0.13], ...
        msprintf("R13 = %.0f Ω",LD2.cfg.R13),"REZISTORIUS",[1.00 0.97 0.87]);
    ld2_component_box(parent,[0.42 0.14 0.20 0.14],"V~ VOLTMETRAS", ...
        "RMS",[0.91 0.97 0.92]);

    ids=["GEN_H";"GEN_L";"GEN_MH";"GEN_ML";"AM_H";"AM_L"; ...
         "C4_1";"C4_2";"C4_M1";"C4_M2"; ...
         "L3_1";"L3_2";"L3_M1";"L3_M2"; ...
         "R13_1";"R13_2";"R13_M1";"R13_M2"; ...
         "LC_M1";"LC_M2";"VM_H";"VM_L"];
    labs=["~";"0";"M~";"M0";"A";"COM"; ...
          "1";"2";"M1";"M2";"1";"2";"M1";"M2"; ...
          "1";"2";"M1";"M2";"LC1";"LC2";"V";"COM"];
    for k=1:size(ids,"*")
        [x,y]=ld2_terminal_xy("RLC",ids(k));
        ld2_draw_terminal(parent,ids(k),labs(k),[x y],active,c);
    end
endfunction


function [x,y]=ld2_terminal_xy(phase,id)
    // Koordinatės yra lizdo centro kairiojo-apatinio kampo pozicija.
    if phase=="RC" | phase=="RL" then
        select id
        case "GEN_H" then x=0.187; y=0.545;
        case "GEN_L" then x=0.187; y=0.415;
        case "GEN_MH" then x=0.075; y=0.70;
        case "GEN_ML" then x=0.075; y=0.335;
        case "AM_H" then x=0.247; y=0.600;
        case "AM_L" then x=0.392; y=0.600;
        case "R8_1" then x=0.452; y=0.600;
        case "R8_2" then x=0.612; y=0.600;
        case "R8_M1" then x=0.492; y=0.495;
        case "R8_M2" then x=0.572; y=0.495;
        case "C2_1" then x=0.672; y=0.600;
        case "C2_2" then x=0.832; y=0.600;
        case "C2_M1" then x=0.712; y=0.495;
        case "C2_M2" then x=0.792; y=0.495;
        case "R9_1" then x=0.452; y=0.600;
        case "R9_2" then x=0.612; y=0.600;
        case "R9_M1" then x=0.492; y=0.495;
        case "R9_M2" then x=0.572; y=0.495;
        case "L1_1" then x=0.672; y=0.600;
        case "L1_2" then x=0.832; y=0.600;
        case "L1_M1" then x=0.712; y=0.495;
        case "L1_M2" then x=0.792; y=0.495;
        case "VM_H" then x=0.435; y=0.285;
        case "VM_L" then x=0.585; y=0.285;
        else x=0.01; y=0.01;
        end
    else
        select id
        case "GEN_H" then x=0.147; y=0.545;
        case "GEN_L" then x=0.147; y=0.415;
        case "GEN_MH" then x=0.055; y=0.70;
        case "GEN_ML" then x=0.055; y=0.335;
        case "AM_H" then x=0.187; y=0.597;
        case "AM_L" then x=0.322; y=0.597;
        case "C4_1" then x=0.357; y=0.597;
        case "C4_2" then x=0.492; y=0.597;
        case "C4_M1" then x=0.400; y=0.485;
        case "C4_M2" then x=0.455; y=0.485;
        case "L3_1" then x=0.527; y=0.597;
        case "L3_2" then x=0.662; y=0.597;
        case "L3_M1" then x=0.570; y=0.485;
        case "L3_M2" then x=0.625; y=0.485;
        case "R13_1" then x=0.697; y=0.597;
        case "R13_2" then x=0.832; y=0.597;
        case "R13_M1" then x=0.740; y=0.485;
        case "R13_M2" then x=0.795; y=0.485;
        case "LC_M1" then x=0.380; y=0.425;
        case "LC_M2" then x=0.645; y=0.425;
        case "VM_H" then x=0.435; y=0.285;
        case "VM_L" then x=0.585; y=0.285;
        else x=0.01; y=0.01;
        end
    end
    // Return the legacy anchor (center - [0.014 0.019]); every caller uses
    // the same center. RLC has enough space for two distinct 36 px contacts
    // between adjacent components, rather than overlapping click targets.
    if phase=="RC" | phase=="RL" then
        if id=="GEN_H" | id=="GEN_L" then x=0.2155-0.014; end
        if id=="AM_H" then x=0.268-0.014; end
    else
        ids=["GEN_H" "GEN_L" "AM_H" "AM_L" "C4_1" "C4_2" "L3_1" "L3_2" "R13_1" "R13_2" ...
             "C4_M1" "C4_M2" "L3_M1" "L3_M2" "R13_M1" "R13_M2"];
        xx=[0.160 0.160 0.213 0.338 0.391 0.515 0.568 0.692 0.745 0.869 0.430 0.490 0.607 0.667 0.784 0.844];
        k=find(ids==id);
        if k<>[] then x=xx(k)-0.014; end
        if id=="LC_M1" | id=="LC_M2" then y=0.417-0.019; end
    end
endfunction


function ld2_draw_connection(parent,phase,a,b)
    // Spalva parenkama pagal grandinės vietą.
    if a=="VM_H" | a=="VM_L" | b=="VM_H" | b=="VM_L" then
        col=[0.52 0.35 0.44];
    elseif a=="GEN_L" | b=="GEN_L" then
        col=[0.41 0.49 0.51];
    else
        col=[0.22 0.40 0.42];
    end
    [x1,y1]=ld2_terminal_xy(phase,a);
    [x2,y2]=ld2_terminal_xy(phase,b);
    x1=x1+0.014; y1=y1+0.019;
    x2=x2+0.014; y2=y2+0.019;

    if a=="VM_H" | a=="VM_L" then
        vm=a; other=b;
    elseif b=="VM_H" | b=="VM_L" then
        vm=b; other=a;
    else
        vm=""; other="";
    end

    if vm<>"" then
        if other=="GEN_MH" then
            [vx,vy]=ld2_terminal_xy(phase,vm); vx=vx+0.014; vy=vy+0.019;
            [gx,gy]=ld2_terminal_xy(phase,other); gx=gx+0.014; gy=gy+0.019;
            lane=0.355; if vm=="VM_L" then lane=0.325; end
            ld2_wire_segment(parent,vx,vy,vx,lane,col);
            ld2_wire_segment(parent,vx,lane,0.012,lane,col);
            ld2_wire_segment(parent,0.012,lane,0.012,0.710,col);
            ld2_wire_segment(parent,0.012,0.710,gx,0.710,col);
            ld2_wire_segment(parent,gx,0.710,gx,gy,col);
            return;
        end
        if vm=="VM_H" then lane=0.355; else lane=0.325; end
        ld2_wire_segment(parent,x1,y1,x1,lane,col);
        ld2_wire_segment(parent,x1,lane,x2,lane,col);
        ld2_wire_segment(parent,x2,lane,x2,y2,col);
    elseif (a=="GEN_L" | b=="GEN_L") then
        lane=0.370;
        ld2_wire_segment(parent,x1,y1,x1,lane,col);
        ld2_wire_segment(parent,x1,lane,x2,lane,col);
        ld2_wire_segment(parent,x2,lane,x2,y2,col);
    else
        lane=max([y1 y2]);
        if abs(y1-y2)<0.01 then
            ld2_wire_segment(parent,x1,y1,x2,y2,col);
        else
            ld2_wire_segment(parent,x1,y1,x1,lane,col);
            ld2_wire_segment(parent,x1,lane,x2,lane,col);
            ld2_wire_segment(parent,x2,lane,x2,y2,col);
        end
    end
endfunction

function ld2_wire_segment(parent,x1,y1,x2,y2,col)
    h=student_wire(parent,[x1 y1],[x2 y2],col);
    if h<>[] then ld2_track(h); end
endfunction
