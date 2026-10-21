// Measurements retain their origin, frequency and circuit revision.
// This is a virtual, ideal AC model. No physical device is controlled.

function m=ld2_empty_reading()
    m=struct("valid",%f,"phase","","target","","f",%nan,"value",%nan, ...
        "unit","","revision",-1,"step",0,"origin","","id",0);
endfunction

function f=ld2_current_frequency(phase)
    global LD2;
    if phase=="RC" then f=LD2.cfg.F_RC;
    elseif phase=="RL" then f=LD2.cfg.F_RL;
    else f=LD2.state.freq; end
endfunction

function m=ld2_store_measurement(phase,target,value,unit)
    global LD2;
    m=ld2_empty_reading();
    m.valid=%t;
    m.phase=phase; m.target=target; m.f=ld2_current_frequency(phase);
    m.value=value; m.unit=unit; m.revision=LD2.state.revision;
    m.step=LD2.state.step;
    m.id=length(LD2.state.measurements)+1;
    m.origin="VIRTUALUS MATAVIMAS";
    if isfield(LD2.state,"auto_recording") then
        if LD2.state.auto_recording then m.origin="AUTOMATINIS VIRTUALUS MATAVIMAS"; end
    end
    if LD2.example_active then m.origin="MOKOMASIS PAVYZDYS"; end
    LD2.state.measurements($+1)=m;
endfunction

function [ok,why]=ld2_live_voltage_ok(target)
    global LD2;
    ok=%f; why="Dabartinės būsenos įtampa dar neišmatuota.";
    m=LD2.state.last_voltage;
    if ~LD2.state.power then why="Generatorius išjungtas."; return; end
    phase=ld2_phase_for_step(LD2.state.step);
    [wired,missing]=ld2_validate_main(phase);
    if ~wired then why="Pagrindinė grandinė neužbaigta."; return; end
    if ld2_detect_voltage_target(phase)<>target then
        why="Voltmetro zondai nėra prijungti prie reikiamo taikinio "+target+"."; return;
    end
    if ~m.valid then return; end
    if m.phase<>phase | m.target<>target then return; end
    if m.revision<>LD2.state.revision then why="Rodmuo paseno pakeitus stendo būseną."; return; end
    if abs(m.f-ld2_current_frequency(phase))>1d-8 then
        why="Rodmuo užfiksuotas kitu dažniu."; return;
    end
    ok=%t; why="";
endfunction

function m=ld2_latest_measurement(phase,target)
    global LD2;
    m=ld2_empty_reading();
    for k=length(LD2.state.measurements):-1:1
        item=LD2.state.measurements(k);
        if item.phase==phase & item.target==target then m=item; return; end
    end
endfunction

function [f,u,ok]=ld2_peak_best(target)
    global LD2;
    f=%nan; u=%nan; ok=%f;
    idx=find(LD2.state.peak_target==target);
    if size(idx,"*")==0 then return; end
    values=LD2.state.peak_u(idx);
    if target=="ULC" then [u,j]=min(values); else [u,j]=max(values); end
    f=LD2.state.peak_f(idx(j)); ok=%t;
endfunction

function rr=ld2_peak_reference(cfg)
    rr=ld2_resonance_values(cfg.R13,cfg.L3,cfg.C4);
    rr.FL=%nan; rr.FC=%nan;
    if rr.Q>1/sqrt(2) then
        factor=sqrt(1-1/(2*rr.Q^2));
        rr.FL=rr.F0/factor;
        rr.FC=rr.F0*factor;
    end
endfunction

function ld2_record_peak_point()
    global LD2;
    if LD2.state.step<>10 then return; end
    target=ld2_detect_voltage_target("RLC");
    if target<>"UL" & target<>"UC" & target<>"ULC" then
        ld2_show_error("Pasirinkite L3, C4 arba bendros L3+C4 įtampos matavimą.", ...
            ["UL: V → L3 M1, COM → L3 M2."; ...
             "UC: V → C4 M1, COM → C4 M2."; ...
             "ULC: V → LC1, COM → LC2."]); return;
    end
    [valid,why]=ld2_live_voltage_ok(target);
    if ~valid then ld2_show_error(why,["Įjunkite generatorių ir spauskite MATUOTI U."; ...
        "Tik po to spauskite ĮRAŠYTI TAŠKĄ."]); return; end
    m=LD2.state.last_voltage;
    idx=[];
    if size(LD2.state.peak_f,"*")>0 then
        idx=find((LD2.state.peak_target==target) & (abs(LD2.state.peak_f-m.f)<1d-8));
    end
    if size(idx,"*")>0 then LD2.state.peak_u(idx(1))=m.value;
    else
        LD2.state.peak_f($+1,1)=m.f;
        LD2.state.peak_u($+1,1)=m.value;
        LD2.state.peak_target($+1,1)=target;
    end
    LD2.state.completed(10)=0;
    [bestf,bestu,found]=ld2_peak_best(target);
    ld2_render_step();
    ld2_set_status(msprintf("%s: įrašyta %.3f Hz / %.6f V. Geriausias taškas: %.3f Hz / %.6f V.", ...
        target,m.f,m.value,bestf,bestu),"ok");
endfunction

function ld2_goto_found_resonance()
    global LD2;
    rr=ld2_resonance_values(LD2.cfg.R13,LD2.cfg.L3,LD2.cfg.C4);
    if isnan(LD2.state.res_fr_meas) then
        f=rr.F0; basis="naudojamas teorinis fr, nes 9 etapo maksimumas dar neužfiksuotas";
    else f=LD2.state.res_fr_meas; basis="naudojamas 9 etape rastas fr"; end
    ld2_set_frequency(f);
    ld2_set_status("f = "+ld2_num(f,3)+" Hz; "+basis+".","info");
endfunction

function lines=ld2_wrap_lines(input,width)
    lines=emptystr(0,1);
    for k=1:size(input,"*")
        rest=input(k);
        while length(rest)>width
            positions=strindex(part(rest,1:width)," ");
            if size(positions,"*")==0 then cut=width; else cut=positions($); end
            lines($+1,1)=stripblanks(part(rest,1:cut));
            rest=stripblanks(part(rest,(cut+1):length(rest)));
        end
        lines($+1,1)=rest;
    end
endfunction

function txt=ld2_reading_text(m)
    if ~m.valid then txt="NEATLIKTA"; return; end
    v=m.value; unit=m.unit;
    if unit=="A" then v=v*1000; unit="mA"; end
    txt=msprintf("%s = %.6f %s   |   f = %.3f Hz",m.target,v,unit,m.f);
endfunction

function rows=ld2_history_lines(step)
    global LD2;
    rows=emptystr(0,1);
    phase=ld2_phase_for_step(step);
    if step==9 then
        for k=1:size(LD2.state.res_f,"*")
            rows($+1,1)=msprintf("Taškas %d: f = %.3f Hz; UR13 = %.6f V",k, ...
                LD2.state.res_f(k),LD2.state.res_ur(k));
        end
    elseif step==10 then
        for target=["UL" "UC" "ULC"]
            [f,u,ok]=ld2_peak_best(target);
            n=size(find(LD2.state.peak_target==target),"*");
            if target=="ULC" then what="minimumas"; else what="maksimumas"; end
            if ok then rows($+1,1)=msprintf("%s %s: %.6f V ties %.3f Hz; taškų: %d",target,what,u,f,n);
            else rows($+1,1)=target+" "+what+": NEATLIKTA"; end
        end
    elseif step==11 then
        rows=["R13 slenkstis: "+ld2_num(ld2_half_power_threshold(),6)+" V"; ...
            "f1: "+ld2_value_or_dash(LD2.state.f1_meas,"Hz")+" | U = "+ld2_value_or_dash(LD2.state.f1_u,"V"); ...
            "f2: "+ld2_value_or_dash(LD2.state.f2_meas,"Hz")+" | U = "+ld2_value_or_dash(LD2.state.f2_u,"V")];
        if size(LD2.state.res_ur,"*")==0 then
            rows($+1)="Slenksčio pagrindas – nominali E (9 etapas neatliktas).";
        else rows($+1)="Slenksčio pagrindas – 9 etape išmatuotas UR13 maksimumas."; end
    elseif step==12 then
        for k=1:size(LD2.state.sweep_f,"*")
            rows($+1,1)=msprintf("%5.0f Hz | UR13 = %.6f V | %s", ...
                LD2.state.sweep_f(k),LD2.state.sweep_ur(k),LD2.state.sweep_source(k));
        end
    elseif phase=="RC" | phase=="RL" then
        if phase=="RC" then targets=["I" "UR" "UC" "UE"]; else targets=["I" "UR" "UL" "UE"]; end
        for target=targets
            m=ld2_latest_measurement(phase,target);
            if m.valid then rows($+1,1)=ld2_reading_text(m);
            else rows($+1,1)=target+": NEATLIKTA"; end
        end
    end
    if size(rows,"*")==0 then rows="Dar nėra užfiksuotų šio etapo matavimų."; end
endfunction

function ld2_render_measurement_history(parent)
    global LD2;
    if LD2.state.step==2 | LD2.state.step==5 | LD2.state.step==8 then
        rows=ld2_connection_list_text(ld2_required_main(ld2_phase_for_step(LD2.state.step)));
        title="JUNGIMO PLANAS (pilnas tekstas slenkamas)";
    else
        rows=ld2_history_lines(LD2.state.step);
        title="UŽFIKSUOTI REZULTATAI – išlieka pakeitus dažnį ar zondus";
    end
    if LD2.example_active then title="PAVYZDŽIO REZULTATAI – ne studento atliktas darbas"; end
    ld2_text(parent,[0.03 0.88 0.94 0.025],title,11,%t,"left",[1 1 1],[0.08 0.22 0.35]);
    h=uicontrol(parent,"style","listbox","units","normalized", ...
        "position",[0.03 0.745 0.94 0.128],"string",rows, ...
        "fontname","Arial","fontunits","pixels","fontsize",12, ...
        "backgroundcolor",[0.96 0.98 1],"foregroundcolor",[0.06 0.10 0.16]);
    ld2_track(h);
endfunction
