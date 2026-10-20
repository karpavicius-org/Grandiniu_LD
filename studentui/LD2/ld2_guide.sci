// LD2: contextual next-action guide (no automatic wire, measurement or answer action).
// Built on the LD1 pattern: inspect the real bench state, display ONE next action,
// highlight the corresponding free terminals / button / answer box.
// Guidance is permitted during assessment: it does not disclose numeric answers,
// choose frequencies, alter readings, mark steps done, or set practice_used.

function line=ld2_guide_terminal(id)
    code=ld2_terminal_code(id);
    line="["+code+"] "+strsubst(ld2_terminal_name(id),code+" – ","");
endfunction

function [lines,focus]=ld2_guide_pair(first,second,context)
    global LD2;
    chosen=LD2.state.selected_terminal;
    focus=[first;second];
    if chosen==first then
        focus=second;
        lines=[context; "Jau pasirinkote "+ld2_guide_terminal(first)+"."; ...
            "Dabar spauskite "+ld2_guide_terminal(second)+"."];
    elseif chosen==second then
        focus=first;
        lines=[context; "Jau pasirinkote "+ld2_guide_terminal(second)+"."; ...
            "Dabar spauskite "+ld2_guide_terminal(first)+"."];
    elseif chosen<>"" then
        focus=chosen;
        lines=[context; "Dabar pažymėtas kitas kontaktas: "+ld2_guide_terminal(chosen)+"."; ...
               "Paspauskite jį dar kartą, kad atšauktumėte pasirinkimą."];
    else
        lines=[context; "Spauskite "+ld2_guide_terminal(first)+"."; ...
            "Tada spauskite "+ld2_guide_terminal(second)+"."];
    end
endfunction

function [lines,focus,button]=ld2_guide_probe(phase,target)
    // The expected pair is determined by a real component, never by a hardcoded screen pixel.
    global LD2;
    focus=emptystr(0,1); button="";
    pair=ld2_probe_pair(phase,target);
    if size(pair,"*")<>2 then
        lines="Atverkite Pagalba → Kontaktų žinynas."; return;
    end
    c=ld2_get_phase_connections(phase);
    h1=ld2_has_connection(c,"VM_H",pair(1)); h2=ld2_has_connection(c,"VM_H",pair(2));
    l1=ld2_has_connection(c,"VM_L",pair(1)); l2=ld2_has_connection(c,"VM_L",pair(2));
    // Correct partial connection: keep it and point to the only missing probe.
    if h1 & ~ld2_terminal_used(c,"VM_L") then
        [lines,focus]=ld2_guide_pair("VM_L",pair(2),"Užbaikite "+target+" voltmetro jungimą:");return;
    elseif h2 & ~ld2_terminal_used(c,"VM_L") then
        [lines,focus]=ld2_guide_pair("VM_L",pair(1),"Užbaikite "+target+" voltmetro jungimą:");return;
    elseif l2 & ~ld2_terminal_used(c,"VM_H") then
        [lines,focus]=ld2_guide_pair("VM_H",pair(1),"Užbaikite "+target+" voltmetro jungimą:");return;
    elseif l1 & ~ld2_terminal_used(c,"VM_H") then
        [lines,focus]=ld2_guide_pair("VM_H",pair(2),"Užbaikite "+target+" voltmetro jungimą:");return;
    end
    // Other probe connections, including a wrongly completed pair: reset only probes.
    if ld2_terminal_used(c,"VM_H") | ld2_terminal_used(c,"VM_L") then
        lines=["Voltmetras dabar prijungtas ne prie reikiamo "+target+" taikinio."; ...
               "Stendo apačioje spauskite Nuimti zondus [B13]."; ...
               "Pagrindinės grandinės laidai liks nepakitę."];
        button="ld2_remove_voltage_probes()";return;
    end
    [lines,focus]=ld2_guide_pair("VM_H",pair(1),"Pradėkite "+target+" įtampos matavimą:");
endfunction

function yes=ld2_guide_peak_done(target)
    global LD2;
    yes=%f;
    idx=find(LD2.state.peak_target==target);
    if size(idx,"*")<3 then return; end
    [f,u,ok]=ld2_peak_best(target);
    if ~ok then return; end
    sample=LD2.state.peak_f(idx);
    if min(sample)>=f | max(sample)<=f then return; end
    if target=="ULC" & u>0.1*LD2.cfg.E_RLC then return; end
    yes=%t;
endfunction

function [lines,focus,button,answer]=ld2_guide_next()
    global LD2;
    focus=emptystr(0,1);button="";answer=0;
    step=LD2.state.step; phase=ld2_phase_for_step(step);
    if LD2.example_active then
        lines=["Dabar rodomas mokomasis pavyzdys, ne jūsų atsiskaitymas."; ...
               "Spauskite Grįžti į savo darbą ir tęskite patys."];
        button="ld2_student_primary()";return;
    end
    if LD2.state.completed(step)==1 & step<>12 then
        lines=["Šio etapo duomenys jau įrašyti."; ...
               "Spauskite Toliau →; ankstesnius matavimus programa išsaugojo."];
        button="ld2_student_primary()";return;
    end
    if or(step==[2 5 8]) then
        req=ld2_required_main(phase);
        [ok,missing]=ld2_validate_main(phase);
        if LD2.state.power then
            lines=["Prieš jungdami laidus išjunkite generatorių."; ...
                   "Spauskite šaltinio mygtuką Išjungti."];
            button="ld2_power_toggle()";return;
        end
        if ~ok then
            k=size(req,1)-size(missing,1)+1;
            prompt=msprintf("%s: prijunkite %d-ą iš %d laidų.",phase,k,size(req,1));
            chosen=LD2.state.selected_terminal;
            a=missing(1,1); b=missing(1,2);
            // Student may start with another still missing required pair.
            if chosen<>"" then
                for i=1:size(missing,1)
                    if chosen==missing(i,1) | chosen==missing(i,2) then
                        a=missing(i,1);b=missing(i,2);break;
                    end
                end
            end
            [lines,focus]=ld2_guide_pair(a,b,prompt);
            return;
        end
        lines=["Visi "+string(size(req,1))+" pagrindiniai laidai prijungti."; ...
               "Spauskite Toliau →. Grandinės jungimų daugiau nekeiskite."];
        button="ld2_student_primary()";return;
    end
    if step==1 then
        lines=["Patikrinkite viršuje savo vardą, grupę ir variantą."; ...
               "Spauskite Pradėti →; pereisite prie RC sujungimo."];
        button="ld2_student_primary()";return;
    end

    [mainok,missing]=ld2_validate_main(phase);
    if ~mainok then
        lines=["Trūksta pagrindinio laido: "+ld2_guide_terminal(missing(1,1))+"."; ...
               "Per Pagalba → Etapai grįžkite į sujungimo etapą."; ...
               "Matavimo pradėti dar negalima."];return;
    end
    need_power=%t;
    if step==4 then
        need_power=isnan(LD2.state.rc_I) | isnan(LD2.state.rc_UR) | isnan(LD2.state.rc_UC) | isnan(LD2.state.rc_UE);
    elseif step==7 then
        need_power=isnan(LD2.state.rl_I) | isnan(LD2.state.rl_UR) | isnan(LD2.state.rl_UL) | isnan(LD2.state.rl_UE);
    elseif step==12 then
        need_power=size(LD2.state.sweep_f,"*")<>11;
    end
    if ~LD2.state.power & need_power then
        lines=["Pagrindinė grandinė paruošta."; ...
               "Šaltinio kortelėje paspauskite Įjungti [B09]."; ...
               "Tada nurodysiu tikslų matavimo veiksmą."];
        button="ld2_power_toggle()";return;
    end

    if step==4 | step==7 then
        if step==4 then
            im=LD2.state.rc_I; ur=LD2.state.rc_UR; ux=LD2.state.rc_UC; ue=LD2.state.rc_UE;
            r=LD2.cfg.R8; xname="UC2"; xcode="UC"; phase="RC";
        else
            im=LD2.state.rl_I; ur=LD2.state.rl_UR; ux=LD2.state.rl_UL; ue=LD2.state.rl_UE;
            r=LD2.cfg.R9; xname="UL1"; xcode="UL"; phase="RL";
        end
        if isnan(im) then
            lines=["Dabar išmatuokite bendrą grandinės srovę."; ...
                   "Ant ampermetro A~ spauskite Matuoti [B14]."; ...
                   "Rodmuo į žurnalą įrašomas automatiškai."];
            button="ld2_measure_current()";return;
        end
        if isnan(ur) then target="UR"; name="rezistoriaus įtampą";
        elseif isnan(ux) then target=xcode; name="reaktyviojo elemento įtampą";
        elseif isnan(ue) then target="UE";name="šaltinio įtampą";
        else target="";name="";end
        if target<>"" then
            if ld2_detect_voltage_target(phase)<>target then
                [lines,focus,button]=ld2_guide_probe(phase,target);return;
            end
            lines=["Zondai prijungti: dabar matuokite "+name+"."; ...
                   "Ant voltmetro V~ spauskite Matuoti U [B15]."; ...
                   "Rodmuo automatiškai išsaugomas žurnale."];
            button="ld2_measure_voltage()";return;
        end
        [labels,n]=ld2_answer_spec(step);
        for k=1:n
            if stripblanks(LD2.state.answers_text(step,k))=="" then
                answer=k;
                if k==1 then
                    formula=msprintf("E = sqrt(UR² + %s²). UR = %.3f V; %s = %.3f V.",xname,ur,xname,ux);
                else
                    formula=msprintf("I_mA = 1000×UR/R. UR = %.3f V; R = %.1f Ω.",ur,r);
                end
                lines=["Visi keturi matavimai užfiksuoti. Toliau skaičiuokite patys."; ...
                       "Įveskite "+labels(k)+" į [A"+msprintf("%02d.%02d",step,k)+"]."; ...
                       formula];return;
            end
        end
        lines=["Matavimai ir atsakymai įrašyti."; ...
               "Spauskite Toliau →. Skaičiavimų teisingumą įvertins dėstytojas."];
        button="ld2_student_primary()";return;
    end

    // RLC: do not keep asking for new measurements once the evidence is sufficient.
    resonance_done=%f;
    if step==9 then
        n=size(LD2.state.res_f,"*");
        if n>=3 then
            [maxu,maxidx]=max(LD2.state.res_ur);
            bestf=LD2.state.res_f(maxidx);
            resonance_done=(min(LD2.state.res_f)<bestf & max(LD2.state.res_f)>bestf & ...
                maxu>=0.97*LD2.cfg.E_RLC);
        end
    end
    // RLC: voltmeter must be connected to the relevant physical component.
    if step==9 & resonance_done then target="";
    elseif step==9 | step==11 | step==12 then target="UR";
    elseif step==10 then
        target="";
        for t=["UL" "UC" "ULC"]
            if ~ld2_guide_peak_done(t) then target=t;break;end
        end
    else target=""; end
    if target<>"" & ld2_detect_voltage_target("RLC")<>target then
        [lines,focus,button]=ld2_guide_probe("RLC",target);return;
    end

    if step==12 then
        if size(LD2.state.sweep_f,"*")<>11 then
            lines=["Matuojama R13 įtampa; generatorius įjungtas."; ...
                   "Stendo apačioje spauskite Skenuoti 0–10 kHz [B26]."; ...
                   "Programa įrašys matavimų lentelę (0 Hz – teorinė riba)."];
            button="ld2_run_sweep()";return;
        end
        lines=["Visi dažninės charakteristikos taškai išsaugoti."; ...
               "Per Pagalba peržiūrėkite suvestinę, įrašykite išvadas."; ...
               "Kai etapai baigti, spauskite Išsaugoti ataskaitą."];
        button="ld2_student_primary()";return;
    end
    if step==11 & isnan(LD2.state.f1_meas) then
        slot="f1 (mažesnis už rezonansinį dažnį)";callback="ld2_record_f1()";
    elseif step==11 & isnan(LD2.state.f2_meas) then
        slot="f2 (didesnis už rezonansinį dažnį)";callback="ld2_record_f2()";
    else slot="";callback="";end

    if ((step==9 & ~resonance_done) | (step==10 & target<>"") | ...
        (step==11 & slot<>"")) then
        if step==9 then active="UR"; record="ld2_record_resonance_point()";
        elseif step==10 then active=target;record="ld2_record_peak_point()";
        else active="UR";record=callback;end
        [live,why]=ld2_live_voltage_ok(active);
        if ~live then
            lines=["Nustatykite generatoriaus dažnį lauke [F04] (Hz)."; ...
                   "Spauskite Taikyti [B16], o ant V~ – Matuoti U [B15]."; ...
                   "Tada užfiksuosite gautą tašką."];
            button="ld2_measure_voltage()";return;
        end
        if step==9 then
            count=size(LD2.state.res_f,"*");
            lines=["Dabar yra šviežias UR13 rodmuo ties f = "+ld2_num(LD2.state.freq,2)+" Hz."; ...
                   "Spauskite Įrašyti tašką [B21]. Turite "+string(count)+" paieškos taškų."; ...
                   "Keiskite dažnį ir ieškokite maksimumo iš abiejų pusių."];
        elseif step==10 then
            count=size(find(LD2.state.peak_target==target),"*");
            lines=["Užfiksuosite "+target+" tašką ties f = "+ld2_num(LD2.state.freq,2)+" Hz."; ...
                   "Spauskite Įrašyti tašką [B23]. Šiam dydžiui turite "+string(count)+" taškų."; ...
                   "Maksimumą arba minimumą apimkite bent trimis dažniais."];
        else
            lines=["Ieškote "+slot+"."; ...
                   "Rodmuo turi būti artimas URmax/√2 = "+ld2_num(ld2_half_power_threshold(),3)+" V."; ...
                   "Pasiekę ribą spauskite Įrašyti "+part(slot,1:2)+" [B24/B25]."];
        end
        button=record;return;
    end
    // Recorded RLC experiment -> guide the first empty numerical result.
    [labels,n]=ld2_answer_spec(step);
    for k=1:n
        if stripblanks(LD2.state.answers_text(step,k))=="" then
            answer=k;
            lines=["Matavimo taškai išsaugoti. Skaičiuokite tik likusius dydžius."; ...
                   "Dabar užpildykite [A"+msprintf("%02d.%02d",step,k)+"]: "+labels(k)+"."; ...
                   "Formulės yra Pagalba → Šio etapo pagalba → Metodika ir formulės."];
            return;
        end
    end
    lines=["Dabartinio etapo duomenys ir atsakymai įrašyti."; ...
           "Spauskite Toliau →. Įvestus atsakymus saugos jūsų juodraštis."];
    button="ld2_student_primary()";
endfunction

function ld2_guide_refresh()
    // Update only visible guidance and input focus; never rebuild the window while typing.
    global LD2;
    [lines,focus,button,answer]=ld2_guide_next();
    if isfield(LD2.ui,"headless") then if LD2.ui.headless then return; end; end
    if isfield(LD2.ui,"guide_text") then
        if is_handle_valid(LD2.ui.guide_text) then
            LD2.ui.guide_text.string=student_wrap(["KĄ DARYTI DABAR?";lines],44);
        end
    end
    if isfield(LD2.ui,"answer_edits") then
        for k=1:size(LD2.ui.answer_edits,"*")
            h=LD2.ui.answer_edits(k);
            if is_handle_valid(h) & h.enable=="on" then
                h.backgroundcolor=[0.94 0.96 0.96];
                if answer==k then h.backgroundcolor=[1.00 0.92 0.65]; end
            end
        end
    end
    if isfield(LD2.ui,"studentPrimary") then
        h=LD2.ui.studentPrimary;
        if is_handle_valid(h) then
            if button=="ld2_student_primary()" then
                h.backgroundcolor=[0.97 0.72 0.26];h.foregroundcolor=[0.16 0.16 0.10];
            else
                h.backgroundcolor=[0.08 0.39 0.37];h.foregroundcolor=[1 1 1];
            end
        end
    end
endfunction

function ld2_guide_show()
    global LD2;
    [lines,focus,button,field]=ld2_guide_next();
    if isfield(LD2.ui,"headless") then if LD2.ui.headless then return; end; end
    ld2_render_step();
    ld2_set_status(strcat(lines," "),"info");
endfunction
