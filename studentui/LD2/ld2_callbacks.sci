// ============================================================================
// LD2 vartotojo veiksmų ir etapų logika
// ============================================================================

function ld2_save_answers()
    global LD2;
    if ~isfield(LD2.ui,"answer_edits") then return; end
    if ~isfield(LD2.ui,"answer_step") then return; end
    owner=LD2.ui.answer_step;
    if owner<1 | owner>12 then return; end
    for k=1:size(LD2.ui.answer_edits,"*")
        h=LD2.ui.answer_edits(k);
        try
            raw=h.string;
            if size(raw,"*")<>1 then raw=strcat(raw," "); end
            if LD2.state.answers_text(owner,k)<>raw then LD2.state.completed(owner)=0; end
            LD2.state.answers_text(owner,k)=raw;
            LD2.state.answers(owner,k)=ld2_safe_number(raw);
        catch
            // A closed window cannot erase already saved input.
        end
    end
endfunction

function ld2_go_step(step, force)
    global LD2;
    if step<1 | step>12 then return; end
    if LD2.example_active then
        ld2_clear_dynamic();
        ld2_prepare_example(step);
        return;
    end
    if isfield(LD2.ui,"answer_edits") then ld2_save_answers(); end

    oldphase=ld2_phase_for_step(LD2.state.step);
    newphase=ld2_phase_for_step(step);
    if oldphase<>newphase then LD2.state.power=%f; end
    ld2_reset_live_readings(newphase);
    LD2.state.selected_terminal="";

    // Dėstytojo režime pažengęs etapas paruošiamas iš karto.
    if LD2.state.teacher_mode | force then
        if step>=3 & step<=4 then
            [ok,missing]=ld2_validate_main("RC");
            if ~ok then LD2.state.rc_connections=ld2_required_main("RC"); end
        elseif step>=6 & step<=7 then
            [ok,missing]=ld2_validate_main("RL");
            if ~ok then LD2.state.rl_connections=ld2_required_main("RL"); end
        elseif step>=9 then
            [ok,missing]=ld2_validate_main("RLC");
            if ~ok then LD2.state.rlc_connections=ld2_required_main("RLC"); end
        end
    end

    // Keičiant matavimo pobūdį seni V~ zondai pašalinami, bet matavimai lieka.
    if step==4 | step==7 | step==9 | step==10 | step==11 | step==12 then
        phase=newphase;
        c=ld2_get_phase_connections(phase);
        c=ld2_remove_terminal_connections(c,["VM_H";"VM_L"]);
        ld2_set_phase_connections(phase,c);
    end

    if step==9 then
        rr=ld2_resonance_values(LD2.cfg.R13,LD2.cfg.L3,LD2.cfg.C4);
        if size(LD2.state.res_f,"*")==0 then LD2.state.freq=max([1 rr.F0-2*rr.BW]); end
    elseif step==10 then
        if isnan(LD2.state.res_fr_meas) then
            rr=ld2_resonance_values(LD2.cfg.R13,LD2.cfg.L3,LD2.cfg.C4);
            LD2.state.freq=rr.F0;
        else
            LD2.state.freq=LD2.state.res_fr_meas;
        end
    elseif step==11 then
        rr=ld2_resonance_values(LD2.cfg.R13,LD2.cfg.L3,LD2.cfg.C4);
        LD2.state.freq=max([1 rr.F0-rr.BW]);
    end

    LD2.state.step=step;
    ld2_render_step();
    ld2_set_status(ld2_step_title(step)+" – vykdykite dešinėje pateiktus veiksmus.","info");
endfunction

function ld2_step_button(step)
    global LD2;
    if LD2.state.teacher_mode then
        ld2_go_step(step,%t);
        return;
    end
    if step==LD2.state.step+1 then
        ld2_next();
    elseif step<=LD2.state.step | LD2.state.completed(step)==1 | LD2.state.skipped(step)==1 then
        ld2_go_step(step,%f);
    else
        if LD2.state.assessment then
            ld2_show_error("Šio etapo dar nepasiekėte.", ...
                ["Užbaikite dabartinį etapą ir spauskite Toliau."]);
        else
            ld2_show_error("Šio etapo dar nepasiekėte.", ...
                ["Užbaikite dabartinį etapą arba per Toliau pasirinkite pereiti nebaigus."]);
        end
    end
endfunction

function ld2_teacher_toggle()
    global LD2;
    LD2.state.teacher_mode=(LD2.ui.teacher.value==1);
    if LD2.state.teacher_mode then
        ld2_set_status("Dėstytojo režimas įjungtas: galima iš karto atverti bet kurį etapą.","ok");
    else
        ld2_set_status("Dėstytojo režimas išjungtas.","info");
    end
    ld2_update_nav_colors();
endfunction

function ld2_prev()
    global LD2;
    if LD2.state.step>1 then ld2_go_step(LD2.state.step-1,%f); end
endfunction

function ld2_next()
    global LD2;
    step=LD2.state.step;
    if step>=12 then return; end
    ld2_save_answers();
    if LD2.state.completed(step)==1 | LD2.state.teacher_mode then
        ld2_go_step(step+1,LD2.state.teacher_mode);
        return;
    end
    if LD2.state.assessment then
        ld2_set_status("Atsiskaityme neužbaigto etapo praleisti negalima.","warn","Užbaikite dabartinį etapą arba grįžkite į ankstesnį.");
        return;
    end
    choice=x_choose(["LIKTI IR BAIGTI";"PEREITI NEBAIGUS"],"Etapas dar nepatikrintas. Ką daryti?");
    if choice==2 then
        LD2.state.skipped(step)=1;
        ld2_go_step(step+1,%f);
    end
endfunction

function ld2_restart_apply()
    global LD2;
    ld2_save_answers();
    bench_autosave("LD2");
    if isfield(LD2,"autosave_error") then
        if LD2.autosave_error<>"" then return; end
    end
    ld2_clear_dynamic();
    teacher=LD2.state.teacher_mode;
    student=LD2.state.student;
    LD2.state=ld2_initial_state(LD2.cfg);
    LD2.state.teacher_mode=teacher;
    LD2.state.student=student;
    LD2.state.assessment=%t;
    LD2.state.practice_used=%f;
    LD2.autosave_paths=emptystr(0,1); LD2.autosave_error="";
    ld2_go_step(1,%t);
    ld2_set_status("Pradėtas naujas atsiskaitymo bandymas.","ok","Ankstesnio bandymo juodraščiai palikti atskirai; naujam bandymui kuriamas naujas juodraštis.");
    bench_autosave("LD2");
endfunction

function ld2_restart()
    global LD2;
    if LD2.example_active then ld2_show_solution(); return; end
    choice=x_choose(["ATŠAUKTI";"PRADĖTI IŠ NAUJO"], ...
        "Bus išvalyti visi laidai, matavimai ir atsakymai. Naujas darbas prasidės atsiskaitymo režimu.");
    if choice==2 then ld2_restart_apply(); end
endfunction

function ld2_terminal_click(id)
    global LD2;
    if LD2.state.selected_terminal=="" then
        LD2.state.selected_terminal=id;
        ld2_render_step();
        ld2_set_status("Pasirinktas "+ld2_terminal_name(id)+". Dabar pasirinkite antrą lizdą.","info");
        return;
    end

    if LD2.state.power & (LD2.state.step==2 | LD2.state.step==5 | LD2.state.step==8) then
        LD2.state.selected_terminal="";
        ld2_render_step();
        ld2_show_error("Pagrindinius laidus keiskite išjungę generatorių.", ...
            ["Spauskite ĮJUNGTA, kad generatorius išsijungtų; po to pasirinkite abu lizdus iš naujo."]);
        return;
    end
    first=LD2.state.selected_terminal;
    LD2.state.selected_terminal="";
    [ok,msg,fix]=ld2_can_add_pair(LD2.state.step,first,id);
    if ~ok then
        ld2_render_step();
        ld2_show_error(msg,[fix]);
        return;
    end
    phase=ld2_phase_for_step(LD2.state.step);
    c=ld2_get_phase_connections(phase);
    c=ld2_add_pair(c,first,id);
    ld2_set_phase_connections(phase,c);
    ld2_reset_live_readings(phase);
    ld2_render_step();
    ld2_set_status("Prijungta: "+ld2_terminal_name(first)+" → "+ld2_terminal_name(id)+".","ok");
endfunction

function ld2_reset_live_readings(phase)
    global LD2;
    LD2.state.revision=LD2.state.revision+1;
    LD2.state.amp_live=%nan;
    LD2.state.volt_live=%nan;
    LD2.state.volt_live_target="";
    LD2.state.last_voltage=ld2_empty_reading();
    LD2.state.last_current=ld2_empty_reading();
    // Historical measurements intentionally remain in the journal.
endfunction

function ld2_check_wiring()
    global LD2;
    phase=ld2_phase_for_step(LD2.state.step);
    [ok,missing]=ld2_validate_main(phase);
    if ok then
        if ~LD2.example_active then
            if LD2.state.step==2 | LD2.state.step==5 | LD2.state.step==8 then
                LD2.state.completed(LD2.state.step)=1;
            end
        end
        ld2_render_step();
        ld2_set_status(phase+" grandinė sujungta teisingai. Galite eiti toliau.","ok");
    else
        fixes=["Prijunkite: "+ld2_terminal_name(missing(1,1))+" → "+ld2_terminal_name(missing(1,2))+"."; ...
               "Po to vėl spauskite TIKRINTI SUJUNGIMĄ."];
        ld2_show_error("Trūksta "+string(size(missing,1))+" pagrindinės grandinės laido(-ų).",fixes);
    end
endfunction

function ld2_undo_wire()
    global LD2;
    phase=ld2_phase_for_step(LD2.state.step);
    c=ld2_get_phase_connections(phase);
    n=size(c,1);
    if n==0 then
        ld2_show_error("Nėra laido, kurį būtų galima atšaukti.", ...
            ["Pradėkite jungti spausdami du mėlynus arba violetinius lizdus."]);
        return;
    end

    // Matavimo etapuose negalima nuardyti užrakintos pagrindinės grandinės.
    if LD2.state.step==4 | LD2.state.step==7 | LD2.state.step==9 | ...
       LD2.state.step==10 | LD2.state.step==11 | LD2.state.step==12 then
        idx=0;
        for k=n:-1:1
            if c(k,1)=="VM_H" | c(k,2)=="VM_H" | c(k,1)=="VM_L" | c(k,2)=="VM_L" then
                idx=k; break;
            end
        end
        if idx==0 then
            ld2_show_error("Pagrindinė grandinė šiame etape užrakinta.", ...
                ["Norėdami keisti V~ jungimą, pirmiausia prijunkite zondus."; ...
                 "Pagrindinę grandinę keiskite jos sujungimo etape."]);
            return;
        end
        c=ld2_delete_connection_row(c,idx);
    else
        c=ld2_delete_connection_row(c,n);
    end
    ld2_set_phase_connections(phase,c);
    if LD2.state.step==2 | LD2.state.step==5 | LD2.state.step==8 then
        LD2.state.completed(LD2.state.step)=0;
    end
    LD2.state.selected_terminal="";
    ld2_reset_live_readings(phase);
    ld2_render_step();
    ld2_set_status("Paskutinis leistinas laidas atšauktas.","ok");
endfunction

function c=ld2_delete_connection_row(c,idx)
    n=size(c,1);
    if n<=1 then
        c=emptystr(0,2);
    elseif idx==1 then
        c=c(2:$,:);
    elseif idx==n then
        c=c(1:n-1,:);
    else
        c=[c(1:idx-1,:);c(idx+1:n,:)];
    end
endfunction

function ld2_clear_phase_wires()
    global LD2;
    phase=ld2_phase_for_step(LD2.state.step);
    ld2_set_phase_connections(phase,emptystr(0,2));
    if phase=="RC" then LD2.state.completed(2)=0;
    elseif phase=="RL" then LD2.state.completed(5)=0;
    elseif phase=="RLC" then LD2.state.completed(8)=0; end
    LD2.state.selected_terminal="";
    LD2.state.power=%f;
    ld2_reset_live_readings(phase);
    ld2_render_step();
    ld2_set_status(phase+" grandinės laidai išvalyti.","warn");
endfunction

function ld2_remove_voltage_probes()
    global LD2;
    phase=ld2_phase_for_step(LD2.state.step);
    c=ld2_get_phase_connections(phase);
    c=ld2_remove_terminal_connections(c,["VM_H";"VM_L"]);
    ld2_set_phase_connections(phase,c);
    if LD2.state.step==2 | LD2.state.step==5 | LD2.state.step==8 then
        LD2.state.completed(LD2.state.step)=0;
    end
    LD2.state.selected_terminal="";
    ld2_reset_live_readings(phase);
    ld2_render_step();
    ld2_set_status("V~ zondai nuimti. Pagrindinė grandinė nepakeista.","ok");
endfunction

function ld2_power_toggle()
    global LD2;
    phase=ld2_phase_for_step(LD2.state.step);
    [ok,missing]=ld2_validate_main(phase);
    if ~ok & ~LD2.state.power then
        ld2_show_error("Generatoriaus negalima įjungti, nes pagrindinė grandinė neužbaigta.", ...
            ["Pirmiausia prijunkite: "+ld2_terminal_name(missing(1,1))+" → "+ld2_terminal_name(missing(1,2))+"."; ...
             "Tada paspauskite TIKRINTI SUJUNGIMĄ."]);
        return;
    end
    LD2.state.power=~LD2.state.power;
    ld2_reset_live_readings(phase);
    if ~LD2.state.power then
        ld2_set_status("Generatorius išjungtas. Laidus dabar galima keisti saugiai.","warn");
    else
        ld2_set_status("Generatorius įjungtas. Galima atlikti matavimus.","ok");
    end
    ld2_render_step();
endfunction

function ld2_measure_current()
    global LD2;
    phase=ld2_phase_for_step(LD2.state.step);
    [ok,missing]=ld2_validate_main(phase);
    if ~ok then
        ld2_show_error("A~ negali matuoti, nes nuosekli grandinė neužbaigta.", ...
            ["Grįžkite į šios grandinės sujungimo etapą."; ...
             "Trūksta: "+ld2_terminal_name(missing(1,1))+" → "+ld2_terminal_name(missing(1,2))+"."]);
        return;
    end
    if ~LD2.state.power then
        ld2_show_error("Generatorius išjungtas.",["Paspauskite IŠJUNGTA / ĮJUNGTA ir tik tada MATUOTI I."]);
        return;
    end
    if phase=="RC" then
        r=ld2_rc_values(LD2.cfg.E_RC,LD2.cfg.F_RC,LD2.cfg.R8,LD2.cfg.C2);
        LD2.state.rc_I=r.I;
        val=r.I;
    elseif phase=="RL" then
        r=ld2_rl_values(LD2.cfg.E_RL,LD2.cfg.F_RL,LD2.cfg.R9,LD2.cfg.L1);
        LD2.state.rl_I=r.I;
        val=r.I;
    else
        r=ld2_rlc_values(LD2.cfg.E_RLC,LD2.state.freq,LD2.cfg.R13,LD2.cfg.L3,LD2.cfg.C4);
        LD2.state.rlc_I=r.I;
        val=r.I;
    end
    LD2.state.amp_live=val;
    LD2.state.last_current=ld2_store_measurement(phase,"I",val,"A");
    ld2_render_step();
    ld2_set_status("A~ rodmuo: "+ld2_num(val*1000,3)+" mA RMS.","ok");
endfunction

function ld2_measure_voltage()
    global LD2;
    phase=ld2_phase_for_step(LD2.state.step);
    [mainok,missing]=ld2_validate_main(phase);
    if ~mainok then
        ld2_show_error("V~ negali matuoti, nes pagrindinė grandinė neužbaigta.", ...
            ["Pirmiausia grįžkite į šios grandinės sujungimo etapą."; ...
             "Trūksta: "+ld2_terminal_name(missing(1,1))+" → "+ld2_terminal_name(missing(1,2))+"."]);
        return;
    end
    if ~LD2.state.power then
        ld2_show_error("Generatorius išjungtas.",["Įjunkite generatorių ir pakartokite MATUOTI U."]);
        return;
    end
    target=ld2_detect_voltage_target(phase);
    if target=="" then
        ld2_show_error("V~ zondai neprijungti prie pilno matavimo taikinio.", ...
            ["Prijunkite V ir COM prie dviejų to paties elemento violetinių lizdų."; ...
             "Vienas zondas turi būti vienoje elemento pusėje, kitas – kitoje."]);
        return;
    end

    if phase=="RC" then
        r=ld2_rc_values(LD2.cfg.E_RC,LD2.cfg.F_RC,LD2.cfg.R8,LD2.cfg.C2);
        if target=="UR" then LD2.state.rc_UR=r.UR; val=r.UR;
        elseif target=="UC" then LD2.state.rc_UC=r.UX; val=r.UX;
        elseif target=="UE" then LD2.state.rc_UE=LD2.cfg.E_RC; val=LD2.cfg.E_RC;
        else
            ld2_show_error("RC etape pasirinktas netinkamas V~ taikinys.", ...
                ["Matuokite tik R8, C2 arba generatoriaus įtampą."]); return;
        end
    elseif phase=="RL" then
        r=ld2_rl_values(LD2.cfg.E_RL,LD2.cfg.F_RL,LD2.cfg.R9,LD2.cfg.L1);
        if target=="UR" then LD2.state.rl_UR=r.UR; val=r.UR;
        elseif target=="UL" then LD2.state.rl_UL=r.UX; val=r.UX;
        elseif target=="UE" then LD2.state.rl_UE=LD2.cfg.E_RL; val=LD2.cfg.E_RL;
        else
            ld2_show_error("RL etape pasirinktas netinkamas V~ taikinys.", ...
                ["Matuokite tik R9, L1 arba generatoriaus įtampą."]); return;
        end
    else
        if LD2.state.step==9 | LD2.state.step==11 | LD2.state.step==12 then
            [ok,problem,fixes]=ld2_validate_voltage_probes("RLC","UR_RLC");
            if ~ok then ld2_show_error(problem,fixes); return; end
        end
        r=ld2_rlc_values(LD2.cfg.E_RLC,LD2.state.freq,LD2.cfg.R13,LD2.cfg.L3,LD2.cfg.C4);
        if target=="UR" then LD2.state.rlc_UR=r.UR; val=r.UR;
        elseif target=="UL" then LD2.state.rlc_UL=r.UL; val=r.UL;
        elseif target=="UC" then LD2.state.rlc_UC=r.UC; val=r.UC;
        elseif target=="ULC" then LD2.state.rlc_ULC=r.ULC; val=r.ULC;
        else
            ld2_show_error("RLC etape pasirinktas netinkamas V~ taikinys.", ...
                ["Matuokite R13, L3, C4 arba visą C4+L3 porą."]); return;
        end
    end
    LD2.state.volt_live=val;
    LD2.state.volt_live_target=target;
    LD2.state.last_voltage=ld2_store_measurement(phase,target,val,"V");
    ld2_render_step();
    ld2_set_status("V~ rodmuo ("+target+"): "+ld2_num(val,3)+" V RMS.","ok");
endfunction

function ld2_frequency_slider()
    global LD2;
    ld2_set_frequency(LD2.ui.freq_slider.value);
endfunction

function ld2_apply_frequency()
    global LD2;
    v=ld2_safe_number(LD2.ui.freq_edit.string);
    if isnan(v) then
        ld2_show_error("Dažnio lauke nėra skaičiaus.",["Įrašykite dažnį Hz, pvz., 5030."]);
        return;
    end
    ld2_set_frequency(v);
endfunction

function ld2_frequency_delta(d)
    global LD2;
    ld2_set_frequency(LD2.state.freq+d);
endfunction

function ld2_set_frequency(v)
    global LD2;
    if ~isreal(v) | size(v,"*")<>1 then return; end
    if isnan(v) | isinf(v) then
        ld2_show_error("Netinkamas dažnis.",["Įrašykite baigtinį skaičių Hz, pvz., 5030.5."]); return;
    end
    if v<1 | v>LD2.cfg.F_MAX then
        ld2_show_error("Dažnis už stendo diapazono ribų.", ...
            ["Leidžiama nuo 1 iki "+string(LD2.cfg.F_MAX)+" Hz."; ...
             "0 Hz lentelėje pateikiamas atskirai kaip teorinė riba, ne AC matavimas."]); return;
    end
    LD2.state.freq=v;
    ld2_reset_live_readings("RLC");
    ld2_render_step();
    ld2_set_status("f = "+ld2_num(v,3)+" Hz. Naujam rodmeniui spauskite MATUOTI U arba I.","info");
endfunction

function ld2_record_resonance_point()
    global LD2;
    if LD2.state.step<>9 then return; end
    [ok,msg]=ld2_live_voltage_ok("UR");
    if ~ok then ld2_show_error(msg,["Prijunkite V → R13 M1 ir COM → R13 M2."; ...
        "Įjunkite generatorių; spauskite MATUOTI U, tada ĮRAŠYTI TAŠKĄ."]); return; end
    sample=LD2.state.last_voltage;
    idx=[];
    if size(LD2.state.res_f,"*")>0 then idx=find(abs(LD2.state.res_f-sample.f)<1d-8); end
    if size(idx,"*")>0 then
        LD2.state.res_ur(idx(1))=sample.value;
        LD2.state.res_i(idx(1))=sample.value/LD2.cfg.R13;
    else
        LD2.state.res_f($+1)=sample.f;
        LD2.state.res_ur($+1)=sample.value;
        LD2.state.res_i($+1)=sample.value/LD2.cfg.R13;
    end
    [umax,imax]=max(LD2.state.res_ur);
    LD2.state.res_fr_meas=LD2.state.res_f(imax);
    LD2.state.completed(9)=0;
    ld2_render_step();
    ld2_set_status(msprintf("Įrašyta %.3f Hz / %.6f V. Didžiausias UR13: %.6f V ties %.3f Hz.", ...
        sample.f,sample.value,umax,LD2.state.res_fr_meas),"ok");
endfunction

function ld2_clear_resonance_points()
    global LD2;
    LD2.state.res_f=[]; LD2.state.res_ur=[]; LD2.state.res_i=[];
    LD2.state.res_fr_meas=%nan;
    LD2.state.completed(9)=0;
    LD2.state.completed(11)=0;
    ld2_render_step();
    ld2_set_status("Rezonanso paieškos taškai išvalyti.","warn");
endfunction

function threshold=ld2_half_power_threshold()
    global LD2;
    // If stage 9 was measured use its maximum. Otherwise declare a theoretical reference.
    if size(LD2.state.res_ur,"*")>0 then
        threshold=max(LD2.state.res_ur)/sqrt(2);
    else
        threshold=LD2.cfg.E_RLC/sqrt(2);
    end
endfunction

function ld2_record_f1()
    global LD2;
    ld2_record_halfpower("f1");
endfunction

function ld2_record_f2()
    global LD2;
    ld2_record_halfpower("f2");
endfunction

function ld2_record_halfpower(whichone)
    global LD2;
    [valid,why]=ld2_live_voltage_ok("UR");
    if ~valid then
        ld2_show_error(why,["Prijunkite V ir COM prie R13 M1 ir M2."; ...
            "Įjunkite generatorių ir spauskite MATUOTI U prieš įrašydami f1 arba f2."]);
        return;
    end
    sample=LD2.state.last_voltage;
    th=ld2_half_power_threshold();
    err=abs(sample.value-th)/th;
    rr=ld2_resonance_values(LD2.cfg.R13,LD2.cfg.L3,LD2.cfg.C4);
    if err>0.03 then
        if sample.value>th then
            hint="Rodmuo per didelis: dažnį tolinkite nuo rezonanso.";
        else
            hint="Rodmuo per mažas: dažnį artinkite prie rezonanso.";
        end
        if whichone=="f1" & LD2.state.freq>rr.F0 then
            hint=hint+" f1 turi būti mažesnis už fr.";
        elseif whichone=="f2" & LD2.state.freq<rr.F0 then
            hint=hint+" f2 turi būti didesnis už fr.";
        end
        ld2_show_error("UR13 nėra pakankamai arti UR,max/√2.", ...
            [msprintf("Tikslas: %.3f V, dabar: %.3f V.",th,sample.value); hint]);
        return;
    end
    if whichone=="f1" then
        if LD2.state.freq>=rr.F0 then
            ld2_show_error("Pasirinktas dažnis yra virš rezonanso, todėl tai ne f1.", ...
                ["Mažinkite dažnį žemiau fr ir vėl raskite tą patį -3 dB rodmenį."]);
            return;
        end
        LD2.state.f1_meas=LD2.state.freq;
        LD2.state.f1_u=sample.value;
        msg="f1 įrašytas.";
    else
        if LD2.state.freq<=rr.F0 then
            ld2_show_error("Pasirinktas dažnis yra žemiau rezonanso, todėl tai ne f2.", ...
                ["Didinkite dažnį virš fr ir vėl raskite tą patį -3 dB rodmenį."]);
            return;
        end
        LD2.state.f2_meas=LD2.state.freq;
        LD2.state.f2_u=sample.value;
        msg="f2 įrašytas.";
    end
    LD2.state.completed(11)=0;
    ld2_render_step();
    ld2_set_status(msg+" Dažnis: "+ld2_num(LD2.state.freq,1)+" Hz.","ok");
endfunction

function ld2_run_sweep()
    global LD2;
    [ok,missing]=ld2_validate_main("RLC");
    if ~ok then ld2_show_error("RLC grandinė neužbaigta.", ...
        ["Grįžkite į 8 etapą ir patikrinkite visus 5 laidus."]); return; end
    if ~LD2.state.power then ld2_show_error("Generatorius išjungtas.", ...
        ["Įjunkite generatorių. Automatika atlieka virtualius matavimus, ne slepiamą teorinį skaičiavimą."]); return; end
    if ld2_detect_voltage_target("RLC")<>"UR" then
        ld2_show_error("Skenavimui voltmetras turi matuoti R13.", ...
            ["Nuimkite V zondus. Prijunkite V → R13 M1, COM → R13 M2."]); return;
    end
    oldf=LD2.state.freq;
    LD2.ui.suppress_render=%t;
    LD2.state.sweep_f=0;
    LD2.state.sweep_ur=0;
    LD2.state.sweep_source="TEORINĖ 0 Hz RIBA";
    for f=1000:1000:LD2.cfg.F_MAX
        LD2.state.freq=f;
        ld2_reset_live_readings("RLC");
        ld2_measure_voltage();
        [valid,why]=ld2_live_voltage_ok("UR");
        if ~valid then
            LD2.ui.suppress_render=%f;
            ld2_show_error("Skenavimas sustabdytas: "+why,["Patikrinkite generatorių ir abu V zondus."]); return;
        end
        LD2.state.sweep_f($+1)=f;
        LD2.state.sweep_ur($+1)=LD2.state.last_voltage.value;
        LD2.state.sweep_source($+1)="VIRTUALUS V~ MATAVIMAS";
    end
    LD2.state.freq=oldf;
    ld2_reset_live_readings("RLC");
    LD2.ui.suppress_render=%f;
    LD2.state.completed(12)=0;
    ld2_render_step();
    ld2_set_status("Lentelė užpildyta. 1–10 kHz: virtualūs V~ matavimai. 0 Hz: atskirai pažymėta teorinė riba.","ok");
endfunction

function ld2_export_csv()
    ld2_export_all();
endfunction

function ld2_edit_parameters()
    global LD2;
    if LD2.example_active then
        ld2_show_error("Parametrų keitimas pavyzdyje negalimas.",["Pirmiausia grįžkite į savo darbą."]); return;
    end
    labels=["RC E, V RMS";"RC f, Hz (originalo schemoje 60)";"R8, Ω (demo: 1000)";"C2, µF"; ...
      "RL E, V RMS";"RL f, Hz (redaguojama prielaida)";"R9, Ω (demo: 1000)";"L1, H"; ...
      "RLC E, V RMS";"R13, Ω (demo: 100)";"L3, mH (demo: 100)";"C4, nF (demo: 10)"];
    defs=[string(LD2.cfg.E_RC);string(LD2.cfg.F_RC);string(LD2.cfg.R8);string(LD2.cfg.C2*1e6); ...
      string(LD2.cfg.E_RL);string(LD2.cfg.F_RL);string(LD2.cfg.R9);string(LD2.cfg.L1); ...
      string(LD2.cfg.E_RLC);string(LD2.cfg.R13);string(LD2.cfg.L3*1e3);string(LD2.cfg.C4*1e9)];
    vals=x_mdialog("LD2: originalo reikšmės ir aiškiai pažymėtas demonstracinis rinkinys",labels,defs);
    if size(vals,"*")==0 then return; end
    n=zeros(12,1);
    for k=1:12
        n(k)=ld2_safe_number(vals(k));
        if isnan(n(k)) | n(k)<=0 then
            ld2_show_error(labels(k)+": netinkama reikšmė.",["Įrašykite teigiamą skaičių nurodytais vienetais, be formulės."]); return;
        end
    end
    cfg=LD2.cfg;
    cfg.E_RC=n(1); cfg.F_RC=n(2); cfg.R8=n(3); cfg.C2=n(4)*1e-6;
    cfg.E_RL=n(5); cfg.F_RL=n(6); cfg.R9=n(7); cfg.L1=n(8);
    cfg.E_RLC=n(9); cfg.R13=n(10); cfg.L3=n(11)*1e-3; cfg.C4=n(12)*1e-9;
    [valid,why]=ld2_validate_config(cfg);
    if ~valid then ld2_show_error(why,["Pakartokite PARAMETRAI ir pataisykite nurodytą reikšmę. Ankstesni parametrai nepakeisti."]); return; end
    if length(LD2.state.measurements)>0 | or(LD2.state.answers_text<>"") then
        pick=x_choose(["ATŠAUKTI";"KEISTI IR PRADĖTI NAUJĄ DARBĄ"], ...
            "Parametrų pakeitimas išvalys šio darbo matavimus. Prireikus pirma IŠSAUGOKITE.");
        if pick<>2 then return; end
    end
    ld2_clear_dynamic();
    LD2.cfg=cfg;
    LD2.state=ld2_initial_state(cfg);
    ld2_go_step(1,%t);
    ld2_set_status("Parametrai pritaikyti; pradėtas naujas darbas.","ok");
endfunction

function ld2_show_method_fixes()
    ld2_show_info("Originalas ir aiškiai pažymėti patikslinimai", [ ...
      "Pagrindas: KVK LD Nr. 2 (RC, RL, nuoseklus RLC), PDF 3–6 psl."; ...
      "RC schemoje nurodyta 60 Hz; tai numatytasis šios versijos RC dažnis."; ...
      "Nežinomos R8, R9, R13, L3, C4 vertės yra REDAGUOJAMAS DEMONSTRACINIS RINKINYS."; ...
      "XC = 1/(2*pi*f*C); fr = 1/(2*pi*sqrt(L*C))."; ...
      "Originalo įtampų sumos pažymėtos vektoriais. Jų nelaikome aritmetine klaida."; ...
      "Idealiuose RC/RL modeliuose moduliams E = sqrt(UR^2+UX^2)."; ...
      "R ir X, Z vektoriai pateikiami atskirai nuo įtampų vektorių."; ...
      "10 etapas: ieškoma atskirų UL ir UC maksimumų bei ULC minimumo ir lyginami dažniai."; ...
      "METODIKOS KOREKCIJA: -3 dB ieškoma pagal R13 įtampą arba srovę, ne pagal UL maksimumą."; ...
      "0 Hz nėra kintamosios srovės matavimas: lentelėje tai teorinė f→0 riba."; ...
      "Visas stendas yra idealus virtualus modelis, ne realios įrangos saugos instrukcija."]);
endfunction

function ld2_show_theory()
    ld2_show_info("RC ir RL formulės", [ ...
      "RC: XC=1/(2πfC), |Z|=√(R²+XC²), I=E/|Z|."; ...
      "RC: UR=IR, UC=IXC, E=√(UR²+UC²), P=I²R."; ...
      "RC: phiZ = -atan(XC/R), phiI = -phiZ; srovė pirmauja."; ...
      ""; ...
      "RL: XL=2πfL, |Z|=√(R²+XL²), I=E/|Z|."; ...
      "RL: UR=IR, UL=IXL, E=√(UR²+UL²), P=I²R."; ...
      "RL: phiZ = +atan(XL/R), phiI = -phiZ; srovė atsilieka."; ...
      "Atsakymų laukelyje phiI prašomas SROVĖS kampas šaltinio atžvilgiu."; ...
      "Originalo varžų diagramos phiZ ir srovės phiI ženklai yra priešingi."]);
endfunction

function ld2_show_resonance_theory()
    ld2_show_info("Nuoseklios RLC rezonansas", [ ...
      "Z=R+j(XL−XC), XL=2πfL, XC=1/(2πfC)."; ...
      "fr=1/(2π√(LC))."; ...
      "Ties fr: XL=XC, |Z|=R, I=E/R, UR=E."; ...
      "UL ir UC gali būti daug didesnės už E, bet yra priešingų fazių."; ...
      "Pusės galios: UR=UR,max/√2, BW=f2−f1, Q=fr/BW."]);
endfunction

function ld2_help_current()
    // [B02] Visa dabartinio etapo metodika atskirame lange.
    global LD2;
    ld2_open_method(LD2.state.step);
endfunction

function ok=ld2_assessment_ready()
    global LD2;
    ok=%f; step=LD2.state.step;
    [labels,n]=ld2_answer_spec(step);
    for k=1:n
        raw=stripblanks(LD2.state.answers_text(step,k));
        if raw=="" then
            ld2_set_status("Užpildykite "+labels(k)+".","error","Atsakymo teisingumą vertins dėstytojo programa.");
            return;
        end
        if isnan(ld2_safe_number(raw)) then
            ld2_set_status("Įrašykite skaičių: "+labels(k)+".","error","Tinka kablelis arba taškas. Formulės ir vienetai į lauką nerašomi.");
            return;
        end
    end
    select step
    case 1 then ok=%t;
    case 2 then
        [ok,missing]=ld2_validate_main("RC");
        if ~ok then ld2_set_status("RC grandinė dar nesujungta.","error","Užbaikite laidus pagal schemą kairėje."); end
    case 3 then ok=%t;
    case 4 then
        ok=~isnan(LD2.state.rc_I) & ~isnan(LD2.state.rc_UR) & ~isnan(LD2.state.rc_UC) & ~isnan(LD2.state.rc_UE);
        if ~ok then ld2_set_status("Trūksta RC matavimo.","error","Užfiksuokite I, UR, UC ir šaltinio įtampą."); end
    case 5 then
        [ok,missing]=ld2_validate_main("RL");
        if ~ok then ld2_set_status("RL grandinė dar nesujungta.","error","Užbaikite laidus pagal schemą kairėje."); end
    case 6 then ok=%t;
    case 7 then
        ok=~isnan(LD2.state.rl_I) & ~isnan(LD2.state.rl_UR) & ~isnan(LD2.state.rl_UL) & ~isnan(LD2.state.rl_UE);
        if ~ok then ld2_set_status("Trūksta RL matavimo.","error","Užfiksuokite I, UR, UL ir šaltinio įtampą."); end
    case 8 then
        [ok,missing]=ld2_validate_main("RLC");
        if ~ok then ld2_set_status("RLC grandinė dar nesujungta.","error","Užbaikite laidus pagal schemą kairėje."); end
    case 9 then
        if size(LD2.state.res_f,"*")<3 then
            ld2_set_status("Rezonanso paieškai reikia bent trijų matavimo taškų.","error","Užfiksuokite taškus abipus stebimo maksimumo."); return;
        end
        [umax,imax]=max(LD2.state.res_ur); fm=LD2.state.res_f(imax);
        ok=min(LD2.state.res_f)<fm & max(LD2.state.res_f)>fm;
        if ~ok then ld2_set_status("Rezonanso maksimumas dar neaprėmintas.","error","Reikia matavimo mažesniu ir didesniu dažniu."); end
    case 10 then
        ok=%t;
        for target=["UL" "UC" "ULC"]
            idx=find(LD2.state.peak_target==target);
            [bestf,bestu,found]=ld2_peak_best(target);
            if ~found | size(idx,"*")<3 | min(LD2.state.peak_f(idx))>=bestf | max(LD2.state.peak_f(idx))<=bestf then ok=%f; end
        end
        if ~ok then ld2_set_status("Trūksta ekstremumų matavimo taškų.","error","Kiekvienam UL, UC ir ULC reikia bent trijų taškų abipus ekstremumo."); end
    case 11 then
        ok=~isnan(LD2.state.f1_meas) & ~isnan(LD2.state.f2_meas) & LD2.state.f2_meas>LD2.state.f1_meas;
        if ~ok then ld2_set_status("Trūksta f1 ir f2 matavimų.","error","Užfiksuokite abu dažnius skirtingose rezonanso pusėse."); end
    case 12 then
        if ~and(LD2.state.completed(1:11)==1) then
            ld2_set_status("Dar yra neužfiksuotų ankstesnių etapų.","error","Per Pagalba → Tęsti arba atkurti darbą → Etapai grįžkite prie neužbaigtų etapų.");
            return;
        end
        expected=0:1000:LD2.cfg.F_MAX;
        ok=size(LD2.state.sweep_f,"*")==size(expected,"*");
        if ok then ok=and(LD2.state.sweep_f==expected); end
        if ~ok then ld2_set_status("Dažninė lentelė dar neužpildyta.","error","Atlikite 0–10 kHz skenavimą."); end
    end
    if ok then ld2_set_status("Etapo duomenys įrašyti.","ok","Teisingumą vertins dėstytojo programa."); end
endfunction

function ld2_check_step()
    global LD2;
    if LD2.example_active then
        ld2_set_status("Tai pavyzdys: etapai neįskaitomi. Spauskite MANO DARBAS.","warn"); return;
    end
    ld2_save_answers();
    step=LD2.state.step;
    LD2.state.completed(step)=0;
    LD2.state.last_error=""; LD2.state.last_fix="";
    select step
    case 1 then
        ok=%t;
    case 2 then
        [ok,missing]=ld2_validate_main("RC");
        if ~ok then ld2_check_wiring(); return; end
    case 3 then
        r=ld2_rc_values(LD2.cfg.E_RC,LD2.cfg.F_RC,LD2.cfg.R8,LD2.cfg.C2);
        ref=[r.X r.Z r.I*1000 r.UR r.UX r.P*1000 r.PHI_I];
        [ok,bad]=ld2_check_answer_vector(step,ref);
        if ~ok then ld2_answer_error(bad,ref(bad)); return; end
    case 4 then
        if isnan(LD2.state.rc_I) | isnan(LD2.state.rc_UR) | isnan(LD2.state.rc_UC) | isnan(LD2.state.rc_UE) then
            ld2_show_error("Trūksta RC matavimo.",["Išmatuokite I mygtuku MATUOTI I."; ...
              "UR: V → R8 M1; COM → R8 M2.";"UC: V → C2 M1; COM → C2 M2."; ...
              "UE: V → generatoriaus M~; COM → M0. Kaskart spauskite MATUOTI U."]); return;
        end
        ref=[sqrt(LD2.state.rc_UR^2+LD2.state.rc_UC^2) LD2.state.rc_UR/LD2.cfg.R8*1000];
        [ok,bad]=ld2_check_answer_vector(step,ref);
        if ~ok then ld2_answer_error(bad,ref(bad)); return; end
    case 5 then
        [ok,missing]=ld2_validate_main("RL");
        if ~ok then ld2_check_wiring(); return; end
    case 6 then
        r=ld2_rl_values(LD2.cfg.E_RL,LD2.cfg.F_RL,LD2.cfg.R9,LD2.cfg.L1);
        ref=[r.X r.Z r.I*1000 r.UR r.UX r.P*1000 r.PHI_I];
        [ok,bad]=ld2_check_answer_vector(step,ref);
        if ~ok then ld2_answer_error(bad,ref(bad)); return; end
    case 7 then
        if isnan(LD2.state.rl_I) | isnan(LD2.state.rl_UR) | isnan(LD2.state.rl_UL) | isnan(LD2.state.rl_UE) then
            ld2_show_error("Trūksta RL matavimo.",["Išmatuokite I mygtuku MATUOTI I."; ...
              "UR: V → R9 M1; COM → R9 M2.";"UL: V → L1 M1; COM → L1 M2."; ...
              "UE: V → generatoriaus M~; COM → M0. Kaskart spauskite MATUOTI U."]); return;
        end
        ref=[sqrt(LD2.state.rl_UR^2+LD2.state.rl_UL^2) LD2.state.rl_UR/LD2.cfg.R9*1000];
        [ok,bad]=ld2_check_answer_vector(step,ref);
        if ~ok then ld2_answer_error(bad,ref(bad)); return; end
    case 8 then
        [ok,missing]=ld2_validate_main("RLC");
        if ~ok then ld2_check_wiring(); return; end
    case 9 then
        if size(LD2.state.res_f,"*")<3 then
            ld2_show_error("Rezonanso paieškai reikia bent trijų užfiksuotų taškų.", ...
                ["V → R13 M1; COM → R13 M2. Įjunkite generatorių."; ...
                 "Keiskite f, spauskite MATUOTI U ir ĮRAŠYTI TAŠKĄ."; ...
                 "Reikia taško žemiau maksimumo, ties juo ir aukščiau."]); return;
        end
        [umax,imax]=max(LD2.state.res_ur); fm=LD2.state.res_f(imax);
        if min(LD2.state.res_f)>=fm | max(LD2.state.res_f)<=fm then
            ld2_show_error("Maksimumas dar neaprėmintas matavimais iš abiejų pusių.", ...
                ["Įrašykite tašką mažesniu ir tašką didesniu dažniu už "+ld2_num(fm,3)+" Hz."]); return;
        end
        if umax<0.97*LD2.cfg.E_RLC then
            ld2_show_error("Rastas UR13 dar per mažas rezonanso maksimumui.", ...
                ["Artinkite dažnį prie didžiausią rodmenį turinčio taško."; ...
                 "Naudokite ±1 Hz arba tikslų įvedimo lauką; įrašykite naują tašką."]); return;
        end
        rr=ld2_resonance_values(LD2.cfg.R13,LD2.cfg.L3,LD2.cfg.C4);
        ref=[rr.F0 fm 1000/fm umax];
        [ok,bad]=ld2_check_answer_vector_custom(step,ref,[0.005 0.0002 0.01 0.015]);
        if ~ok then ld2_answer_error(bad,ref(bad)); return; end
    case 10 then
        [fl,ul,okl]=ld2_peak_best("UL"); [fc,uc,okc]=ld2_peak_best("UC");
        [fz,uz,okz]=ld2_peak_best("ULC");
        if ~okl | ~okc | ~okz then
            ld2_show_error("Trūksta UL, UC maksimumų arba ULC minimumo tyrimo.", ...
                ["Kiekvienam taikiniui prijunkite abu zondus pagal PAGALBA."; ...
                 "Keiskite dažnį; MATUOTI U → ĮRAŠYTI TAŠKĄ."; ...
                 "Kiekvienam taikiniui užfiksuokite bent 3 skirtingus dažnius."]); return;
        end
        for target=["UL" "UC" "ULC"]
            idx=find(LD2.state.peak_target==target);
            [bestf,bestu,found]=ld2_peak_best(target);
            if size(idx,"*")<3 then
                ld2_show_error(target+": per mažai taškų.",["Tam pačiam taikiniui įrašykite bent 3 skirtingus dažnius."]); return;
            end
            if min(LD2.state.peak_f(idx))>=bestf | max(LD2.state.peak_f(idx))<=bestf then
                ld2_show_error(target+": ekstremumas dar neaprėmintas.", ...
                    ["Įrašykite matavimus mažesniu ir didesniu f už "+ld2_num(bestf,3)+" Hz."]); return;
            end
        end
        if uz>0.1*LD2.cfg.E_RLC then
            ld2_show_error("ULC minimumas dar nepakankamai arti rezonanso.", ...
                ["Prijunkite V → LC1, COM → LC2."; ...
                 "Mažais dažnio žingsniais mažinkite ULC ir įrašykite naują tašką."]); return;
        end
        // These references come from the actual recorded frequencies, NOT an exact f0 substituted later.
        ref=[ul uc uz fl fc fz];
        [ok,bad]=ld2_check_answer_vector_custom(step,ref,[0.015 0.015 0.015 0.0002 0.0002 0.0002]);
        if ~ok then ld2_answer_error(bad,ref(bad)); return; end
    case 11 then
        if isnan(LD2.state.f1_meas) | isnan(LD2.state.f2_meas) then
            ld2_show_error("f1 ir f2 dar neužfiksuoti matavimo mygtukais.", ...
                ["V → R13 M1, COM → R13 M2. Įjunkite generatorių."; ...
                 "Žemiau fr raskite slenkstį; MATUOTI U → ĮRAŠYTI f1."; ...
                 "Virš fr pakartokite MATUOTI U → ĮRAŠYTI f2."; ...
                 "Vien skaičių įrašymas į atsakymų laukus nelaikomas matavimu."]); return;
        end
        threshold=ld2_half_power_threshold();
        if abs(LD2.state.f1_u-threshold)>0.0301*threshold | abs(LD2.state.f2_u-threshold)>0.0301*threshold then
            ld2_show_error("Pasikeitė slenkstis arba senieji f1/f2 rodmenys jo nebeatitinka.", ...
                ["Pagal dabar rodomą R13 slenkstį iš naujo išmatuokite ir užfiksuokite f1 bei f2."]); return;
        end
        bw=LD2.state.f2_meas-LD2.state.f1_meas;
        if bw<=0 then ld2_show_error("f2 turi būti didesnis už f1.",["Iš naujo užfiksuokite taškus skirtingose rezonanso pusėse."]); return; end
        rr=ld2_resonance_values(LD2.cfg.R13,LD2.cfg.L3,LD2.cfg.C4);
        fr=LD2.state.res_fr_meas; if isnan(fr) then fr=rr.F0; end
        ref=[ld2_half_power_threshold() LD2.state.f1_meas LD2.state.f2_meas bw fr/bw];
        [ok,bad]=ld2_check_answer_vector_custom(step,ref,[0.015 0.0002 0.0002 0.02 0.02]);
        if ~ok then ld2_answer_error(bad,ref(bad)); return; end
    case 12 then
        expected=(0:1000:LD2.cfg.F_MAX);
        if size(LD2.state.sweep_f,"*")<>size(expected,"*") then
            ld2_show_error("Dažninė lentelė dar neužpildyta.", ...
                ["V → R13 M1, COM → R13 M2. Įjunkite generatorių."; ...
                 "Spauskite SKENUOTI 0–10 kHz."]); return;
        end
        ok=%t;
    end
    LD2.state.completed(step)=1; LD2.state.skipped(step)=0;
    ld2_render_step();
    ld2_set_status("Etapas "+string(step)+" patikrintas. Matavimai ir atsakymai išsaugoti stendo būsenoje.","ok");
endfunction

function [ok,bad]=ld2_check_answer_vector(step,ref)
    global LD2;
    vals=LD2.state.answers(step,1:size(ref,"*"));
    ok=%t; bad=0;
    for k=1:size(ref,"*")
        if isnan(vals(k)) | ~ld2_close_enough(vals(k),ref(k)) then
            ok=%f; bad=k; return;
        end
    end
endfunction

function [ok,bad]=ld2_check_answer_vector_custom(step,ref,rel)
    global LD2;
    vals=LD2.state.answers(step,1:size(ref,"*"));
    ok=%t; bad=0;
    for k=1:size(ref,"*")
        if isnan(vals(k)) then ok=%f; bad=k; return; end
        if abs(vals(k)-ref(k))>LD2.cfg.ANSWER_TOL_ABS+rel(k)*abs(ref(k)) then
            ok=%f; bad=k; return;
        end
    end
endfunction

function ld2_answer_error(idx,ref)
    global LD2;
    [labels,n]=ld2_answer_spec(LD2.state.step);
    if idx<=n then name=labels(idx); else name="atsakymas Nr. "+string(idx); end
    ld2_show_error(name+" reikšmė tuščia arba neteisinga.", ...
      ["Patikrinkite vienetus ir formulę."; ...
       "Kontrolinė reikšmė pagal dabartinius stendo parametrus yra apie "+ld2_num(ref,4)+"."; ...
       "PAVYZDYS parodo atliktą variantą; formules atverkite mygtuku TEORIJA / PAGALBA."]);
endfunction

function ld2_show_solution()
    global LD2;
    if LD2.state.assessment & ~LD2.example_active then
        ld2_set_status("Pavyzdžiai pasiekiami mokymosi režime. Režimą galite pakeisti Pagalbos meniu.","info");return;
    end
    if LD2.example_active then
        ld2_clear_dynamic();
        LD2.state=LD2.example_backup;
        LD2.example_active=%f;
        ld2_render_step();
        ld2_set_status("Grįžote į savo darbą. Jūsų laidai, tekstas ir matavimai atkurti.","ok");
        return;
    end
    ld2_save_answers();
    LD2.state.practice_used=%t;
    LD2.example_backup=LD2.state;
    LD2.example_active=%t;
    step=LD2.state.step;
    ld2_clear_dynamic();
    try
        ld2_prepare_example(step);
    catch
        details=lasterror();
        LD2.ui.suppress_render=%f;
        LD2.state=LD2.example_backup;
        LD2.example_active=%f;
        ld2_render_step();
        ld2_show_error("Nepavyko atverti pavyzdžio. Jūsų darbas atkurtas.", ...
            [details;"Vykdykite LD2_SELFTEST.sce ir pateikite testo žurnalą."]);
    end
endfunction

function ld2_prepare_example(step)
    global LD2;
    LD2.ui.suppress_render=%t;
    student=LD2.state.student;
    LD2.state=ld2_initial_state(LD2.cfg);
    LD2.state.student=student;
    LD2.state.step=step;
    LD2.state.teacher_mode=%t;
    phase=ld2_phase_for_step(step);
    if phase<>"OVERVIEW" then ld2_set_phase_connections(phase,ld2_required_main(phase)); end
    LD2.state.power=%t;
    rc=ld2_rc_values(LD2.cfg.E_RC,LD2.cfg.F_RC,LD2.cfg.R8,LD2.cfg.C2);
    rl=ld2_rl_values(LD2.cfg.E_RL,LD2.cfg.F_RL,LD2.cfg.R9,LD2.cfg.L1);
    rr=ld2_peak_reference(LD2.cfg);
    ref=[];
    if step==2 | step==5 | step==8 | step==1 then
        LD2.state.power=%f;
    elseif step==3 then
        ref=[rc.X rc.Z rc.I*1000 rc.UR rc.UX rc.P*1000 rc.PHI_I];
    elseif step==6 then
        ref=[rl.X rl.Z rl.I*1000 rl.UR rl.UX rl.P*1000 rl.PHI_I];
    elseif step==4 | step==7 then
        ld2_measure_current();
        if phase=="RC" then targets=["UR" "UC" "UE"]; else targets=["UR" "UL" "UE"]; end
        for target=targets
            ld2_example_connect_probe(phase,target);
            ld2_measure_voltage();
        end
        if phase=="RC" then ref=[LD2.cfg.E_RC rc.I*1000]; else ref=[LD2.cfg.E_RL rl.I*1000]; end
    elseif step==9 then
        ld2_example_connect_probe("RLC","UR");
        for f=[rr.F0-rr.BW/2 rr.F0 rr.F0+rr.BW/2]
            LD2.state.freq=f; ld2_reset_live_readings("RLC");
            ld2_measure_voltage(); ld2_record_resonance_point();
        end
        LD2.state.freq=rr.F0; ld2_reset_live_readings("RLC"); ld2_measure_voltage();
        ref=[rr.F0 rr.F0 1000/rr.F0 LD2.cfg.E_RLC];
    elseif step==10 then
        targets=["UL" "UC" "ULC"]; centers=[rr.FL rr.FC rr.F0];
        for j=1:3
            ld2_example_connect_probe("RLC",targets(j));
            for f=[centers(j)-rr.BW/2 centers(j) centers(j)+rr.BW/2]
                LD2.state.freq=f; ld2_reset_live_readings("RLC");
                ld2_measure_voltage(); ld2_record_peak_point();
            end
        end
        [fl,ul,yes]=ld2_peak_best("UL"); [fc,uc,yes]=ld2_peak_best("UC"); [fz,uz,yes]=ld2_peak_best("ULC");
        ref=[ul uc uz fl fc fz];
        LD2.state.freq=rr.F0; ld2_reset_live_readings("RLC"); ld2_measure_voltage();
    elseif step==11 then
        ld2_example_connect_probe("RLC","UR");
        LD2.state.freq=rr.F1; ld2_reset_live_readings("RLC"); ld2_measure_voltage(); ld2_record_f1();
        LD2.state.freq=rr.F2; ld2_reset_live_readings("RLC"); ld2_measure_voltage(); ld2_record_f2();
        ref=[LD2.cfg.E_RLC/sqrt(2) rr.F1 rr.F2 rr.BW rr.Q];
    elseif step==12 then
        ld2_example_connect_probe("RLC","UR");
        ld2_run_sweep();
        LD2.ui.suppress_render=%t;
    end
    for j=1:size(ref,"*")
        LD2.state.answers(step,j)=ref(j);
        LD2.state.answers_text(step,j)=ld2_num(ref(j),4);
    end
    LD2.state.completed=zeros(1,12);
    LD2.ui.suppress_render=%f;
    ld2_render_step();
    ld2_set_status("PAVYZDYS: galima išbandyti valdiklius. Jūsų darbas nepakeistas; grįžimui spauskite MANO DARBAS.","warn");
endfunction

function ld2_example_connect_probe(phase,target)
    global LD2;
    pair=ld2_probe_pair(phase,target);
    c=ld2_required_main(phase);
    c=[c;"VM_H" pair(1);"VM_L" pair(2)];
    ld2_set_phase_connections(phase,c);
    ld2_reset_live_readings(phase);
endfunction
