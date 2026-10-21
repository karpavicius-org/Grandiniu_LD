// LD2-3: one-click virtual lab procedures.
// All measurements are explicitly synthetic virtual instruments. All automated
// operations leave a clear provenance trail; only typed student answers are
// recorded as student answers. Never silently manufacture typed responses.

function ld2_auto_note(label)
    global LD2;
    if ~isfield(LD2.state,"auto_actions") then LD2.state.auto_actions=emptystr(0,1); end
    LD2.state.auto_actions($+1,1)=string(ld2_visible_ordinal(LD2.state.step))+" etapas: "+label;
endfunction

function ld2_auto_probe(phase,target)
    global LD2;
    pair=ld2_probe_pair(phase,target);
    if size(pair,"*")<>2 then error("Nežinoma voltmetro matavimo pora: "+target); end
    c=ld2_get_phase_connections(phase);
    c=ld2_remove_terminal_connections(c,["VM_H";"VM_L"]);
    c=[c;"VM_H" pair(1);"VM_L" pair(2)];
    ld2_set_phase_connections(phase,c);
    LD2.state.selected_terminal="";
    ld2_reset_live_readings(phase);
    if ld2_detect_voltage_target(phase)<>target then error("Neteisingas virtualus zondų prijungimas: "+target); end
endfunction

// Keep the entire automatic experiment in one CPU-side transaction.
// Do not invoke UI callbacks recursively: those callbacks redraw the window,
// change transient instrument state and can invalidate an in-flight reading.
function ld2_auto_enable_power()
    global LD2;
    phase=ld2_phase_for_step(LD2.state.step);
    [ok,missing]=ld2_validate_main(phase);
    if ~ok then error("Prieš automatinį matavimą užbaikite grandinę."); end
    if ~LD2.state.power then
        LD2.state.power=%t;
        ld2_reset_live_readings(phase);
    end
endfunction

function value=ld2_auto_current_reading(phase)
    global LD2;
    if ~LD2.state.power then error("Generatorius išjungtas."); end
    if phase=="RC" then
        model=ld2_rc_values(LD2.cfg.E_RC,LD2.cfg.F_RC,LD2.cfg.R8,LD2.cfg.C2);
        LD2.state.rc_I=model.I;
    elseif phase=="RL" then
        model=ld2_rl_values(LD2.cfg.E_RL,LD2.cfg.F_RL,LD2.cfg.R9,LD2.cfg.L1);
        LD2.state.rl_I=model.I;
    else
        error("Automatinė srovė numatyta tik RC ir RL dalyse.");
    end
    value=model.I;
    if isnan(value) | isinf(value) | value<=0 then error("Netinkamas virtualus srovės rodmuo."); end
    LD2.state.amp_live=value;
    LD2.state.last_current=ld2_store_measurement(phase,"I",value,"A");
endfunction

function value=ld2_auto_voltage_reading(phase,target,f)
    global LD2;
    if ~LD2.state.power then error("Generatorius išjungtas."); end
    if phase=="RC" then
        model=ld2_rc_values(LD2.cfg.E_RC,LD2.cfg.F_RC,LD2.cfg.R8,LD2.cfg.C2);
        select target
        case "UR" then value=model.UR; LD2.state.rc_UR=value;
        case "UC" then value=model.UX; LD2.state.rc_UC=value;
        case "UE" then value=LD2.cfg.E_RC; LD2.state.rc_UE=value;
        else error("Nežinomas RC matavimo taikinys.");
        end
    elseif phase=="RL" then
        model=ld2_rl_values(LD2.cfg.E_RL,LD2.cfg.F_RL,LD2.cfg.R9,LD2.cfg.L1);
        select target
        case "UR" then value=model.UR; LD2.state.rl_UR=value;
        case "UL" then value=model.UX; LD2.state.rl_UL=value;
        case "UE" then value=LD2.cfg.E_RL; LD2.state.rl_UE=value;
        else error("Nežinomas RL matavimo taikinys.");
        end
    elseif phase=="RLC" then
        if f<1 | f>LD2.cfg.F_MAX | isnan(f) | isinf(f) then
            error("Automatinio RLC bandymo dažnis už diapazono ribų.");
        end
        LD2.state.freq=f;
        model=ld2_rlc_values(LD2.cfg.E_RLC,f,LD2.cfg.R13,LD2.cfg.L3,LD2.cfg.C4);
        select target
        case "UR" then value=model.UR; LD2.state.rlc_UR=value;
        case "UL" then value=model.UL; LD2.state.rlc_UL=value;
        case "UC" then value=model.UC; LD2.state.rlc_UC=value;
        case "ULC" then value=model.ULC; LD2.state.rlc_ULC=value;
        else error("Nežinomas RLC matavimo taikinys.");
        end
    else
        error("Nežinoma automatinio matavimo grandinė.");
    end
    if isnan(value) | isinf(value) | value<0 then
        error("Modelis grąžino netinkamą virtualų voltmetro rodmenį.");
    end
    // This is the same virtual instrument model and observable reading record
    // as for manual Matuoti U, with explicit automated origin metadata.
    LD2.state.amp_live=model.I;
    LD2.state.volt_live=value;
    LD2.state.volt_live_target=target;
    LD2.state.last_voltage=ld2_store_measurement(phase,target,value,"V");
endfunction

function ld2_auto_set_frequency(f)
    global LD2;
    if ~isreal(f) | size(f,"*")<>1 then error("Netinkamas dažnio matmuo."); end
    if isnan(f) | isinf(f) | f<1 | f>LD2.cfg.F_MAX then
        error("Automatinio bandymo dažnis nepatenka į 1–10000 Hz ribas.");
    end
    LD2.state.freq=f;
    ld2_reset_live_readings("RLC");
endfunction

function [label,ready]=ld2_auto_stage_status(step)
    global LD2;
    label=""; ready=%f;
    if or(step==[2 5 8]) then
        label="Sujungti grandinę";
        phase=ld2_phase_for_step(step);
        [ready,missing]=ld2_validate_main(phase);
    elseif step==4 | step==7 then
        label="Įjungti ir matuoti";
        if step==4 then
            ready=~or(isnan([LD2.state.rc_I LD2.state.rc_UR LD2.state.rc_UC LD2.state.rc_UE]));
        else
            ready=~or(isnan([LD2.state.rl_I LD2.state.rl_UR LD2.state.rl_UL LD2.state.rl_UE]));
        end
    elseif step==9 then
        label="Palyginti tris dažnius";
        ready=size(LD2.state.res_f,"*")>=3 & ~isnan(LD2.state.res_fr_meas);
    elseif step==10 then
        label="Išmatuoti tris įtampas";
        ready=ld2_guide_peak_done("UL") & ld2_guide_peak_done("UC") & ld2_guide_peak_done("ULC");
    elseif step==11 then
        label="Išmatuoti f1 ir f2";
        ready=~isnan(LD2.state.f1_meas) & ~isnan(LD2.state.f2_meas);
    elseif step==12 then
        label="Sudaryti dažninę kreivę";
        ready=%f;
        if size(LD2.state.sweep_f,"*")==11 & size(LD2.state.sweep_ur,"*")==11 then
            ready=and(matrix(LD2.state.sweep_f,1,-1)==(0:1000:LD2.cfg.F_MAX)) & ...
                ~or(isnan(LD2.state.sweep_ur)) & ~or(isinf(LD2.state.sweep_ur));
        end
    end
endfunction

function lines=ld2_auto_summary(step)
    lines=ld2_workflow_readings(step);
endfunction

// One deliberately clicked automatic experiment. The state either commits
// completely or is rolled back; no partially completed virtual observation
// may be presented as a finished student result.
function ld2_auto_stage()
    global LD2;
    if LD2.example_active then
        ld2_show_error("Automatinis bandymas pavyzdyje negalimas.", ...
            ["Grįžkite į savo darbą ir pasirinkite etapą."]); return;
    end
    step=LD2.state.step;
    phase=ld2_phase_for_step(step);
    if ~or(step==[2 4 5 7 8 9 10 11 12]) then return; end
    [action,already_done]=ld2_auto_stage_status(step);
    if already_done then
        ld2_set_status("Bandymas jau atliktas – rezultatai išsaugoti. Spauskite Toliau.","info");
        return;
    end
    ld2_save_answers();
    previous_state=LD2.state;
    LD2.ui.suppress_render=%t;
    LD2.state.auto_recording=%t;
    success=%f;
    failure="";
    try
        if or(step==[2 5 8]) then
            LD2.state.power=%f;
            ld2_set_phase_connections(phase,ld2_required_main(phase));
            LD2.state.selected_terminal="";
            ld2_reset_live_readings(phase);
            ld2_auto_note("Automatiškai sujungta "+phase+" grandinė");
        else
            [connected,missing]=ld2_validate_main(phase);
            if ~connected then error("Trūksta grandinės laidų; pirmiau pasirinkite Sujungti automatiškai."); end
            ld2_auto_enable_power();
            if step==4 | step==7 then
                value=ld2_auto_current_reading(phase);
                if phase=="RC" then targets=["UR" "UC" "UE"];
                else targets=["UR" "UL" "UE"]; end
                for target=targets
                    ld2_auto_probe(phase,target);
                    value=ld2_auto_voltage_reading(phase,target,ld2_current_frequency(phase));
                end
                ld2_auto_note("Automatiškai išmatuota srovė ir trys įtampos: I, UR, UX, UE");
            else
                select step
                case 9 then
                rr=ld2_peak_reference(LD2.cfg);
                frequencies=[rr.F0-rr.BW/2 rr.F0 rr.F0+rr.BW/2];
                LD2.state.res_f=[];LD2.state.res_ur=[];LD2.state.res_i=[];
                LD2.state.res_fr_meas=%nan;
                ld2_auto_probe("RLC","UR");
                for k=1:3
                    f=frequencies(k);
                    ld2_auto_set_frequency(f);
                    value=ld2_auto_voltage_reading("RLC","UR",f);
                    LD2.state.res_f($+1)=f;
                    LD2.state.res_ur($+1)=value;
                    LD2.state.res_i($+1)=value/LD2.cfg.R13;
                end
                [peak,index]=max(LD2.state.res_ur);
                LD2.state.res_fr_meas=LD2.state.res_f(index);
                if peak<0.97*LD2.cfg.E_RLC | index<>2 then
                    error("Rezonanso maksimumas nepatvirtintas trimis taškais.");
                end
                ld2_auto_note("Automatiškai atlikti trys UR rezonanso matavimai");
            case 10 then
                rr=ld2_peak_reference(LD2.cfg);
                targets=["UL" "UC" "ULC"];
                centers=[rr.FL rr.FC rr.F0];
                LD2.state.peak_f=[];LD2.state.peak_u=[];
                LD2.state.peak_target=emptystr(0,1);
                for k=1:3
                    target=targets(k);
                    ld2_auto_probe("RLC",target);
                    for f=[centers(k)-rr.BW/2 centers(k) centers(k)+rr.BW/2]
                        ld2_auto_set_frequency(f);
                        value=ld2_auto_voltage_reading("RLC",target,f);
                        LD2.state.peak_f($+1,1)=f;
                        LD2.state.peak_u($+1,1)=value;
                        LD2.state.peak_target($+1,1)=target;
                    end
                end
                if ~(ld2_guide_peak_done("UL") & ld2_guide_peak_done("UC") & ...
                    ld2_guide_peak_done("ULC")) then
                    error("Neužfiksuoti visi trys įtampų ekstremumai.");
                end
                ld2_auto_note("Automatiškai išmatuoti devyni UL, UC ir ULC taškai");
            case 11 then
                rr=ld2_peak_reference(LD2.cfg);
                LD2.state.f1_meas=%nan;LD2.state.f2_meas=%nan;
                LD2.state.f1_u=%nan;LD2.state.f2_u=%nan;
                ld2_auto_probe("RLC","UR");
                for k=1:2
                    if k==1 then f=rr.F1;else f=rr.F2;end
                    ld2_auto_set_frequency(f);
                    value=ld2_auto_voltage_reading("RLC","UR",f);
                    if k==1 then
                        LD2.state.f1_meas=f;LD2.state.f1_u=value;
                    else
                        LD2.state.f2_meas=f;LD2.state.f2_u=value;
                    end
                end
                threshold=ld2_half_power_threshold();
                if abs(LD2.state.f1_u-threshold)>0.0301*threshold | ...
                    abs(LD2.state.f2_u-threshold)>0.0301*threshold | ...
                    LD2.state.f1_meas>=rr.F0 | LD2.state.f2_meas<=rr.F0 then
                    error("Pusės galios taškai nesutampa su išmatuotu slenksčiu.");
                end
                ld2_auto_note("Automatiškai išmatuoti du pusės galios dažniai f1 ir f2");
            case 12 then
                LD2.state.sweep_f=0;
                LD2.state.sweep_ur=0;
                LD2.state.sweep_source="TEORINĖ 0 Hz RIBA";
                ld2_auto_probe("RLC","UR");
                for f=1000:1000:LD2.cfg.F_MAX
                    ld2_auto_set_frequency(f);
                    value=ld2_auto_voltage_reading("RLC","UR",f);
                    LD2.state.sweep_f($+1)=f;
                    LD2.state.sweep_ur($+1)=value;
                    LD2.state.sweep_source($+1)="AUTOMATINIS VIRTUALUS V~ MATAVIMAS";
                end
                if size(LD2.state.sweep_f,"*")<>11 then
                    error("Dažninė lentelė turi turėti 11 taškų.");
                end
                ld2_auto_note("Automatinė 0–10 kHz virtualių matavimų kreivė");
                end
            end
        end
        [label,ready]=ld2_auto_stage_status(step);
        if ~ready then error("Veiksmas neužbaigtas: trūksta būtinų stendo duomenų."); end
        LD2.state.completed(step)=0;
        LD2.state.auto_recording=%f;
        success=%t;
    catch
        failure=strcat(lasterror()," ");
        LD2.state=previous_state;
    end
    LD2.ui.suppress_render=%f;
    // Render and autosave exactly once; failures are visible, never swallowed.
    if success then
        ld2_render_step();
        bench_autosave("LD2");
        ld2_set_status("Automatinė virtuali operacija atlikta. Patikrinkite rodmenis ir tęskite.","ok");
    else
        ld2_render_step();
        ld2_show_error("Automatinio bandymo veiksmas nebaigtas.", ...
            [failure;"Darbo būsena atkurta; nepilni duomenys neišsaugoti."]);
        // A compact non-silent diagnostic on actual failure only. It can be
        // photographed and sent without exposing personal student records.
        ld2_show_info("LD2 automatinio bandymo klaida", ...
            ["Etapas: "+string(ld2_visible_ordinal(step))+" iš 10"; ...
             failure;"Nepavyko užbaigti bandymo. Ankstesnis darbas išsaugotas."]);
    end
endfunction
