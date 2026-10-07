// A quieter native bench using the same shell and palette as LD1.
function ld2_show_error(problem,fixes)
    // Like LD1: show a correction in the bench, without a blocking dialog.
    global LD2;
    LD2.state.last_error=problem;
    LD2.state.last_fix=strcat(matrix(fixes,-1,1)," ");
    if isfield(LD2.ui,"headless") then if LD2.ui.headless then return; end; end
    hint="";
    if size(fixes,"*")>0 then hint=" "+fixes(1); end
    ld2_set_status(student_wrap(problem+hint,145),"error");
endfunction

function ld2_student_main(root)
    global LD2;
    if typeof(LD2)=="st" then
        if isfield(LD2,"ui") then
            if isfield(LD2.ui,"figure") then
                if is_handle_valid(LD2.ui.figure) then show_window(LD2.ui.figure); return; end
            end
        end
    end
    try bench_core_require(); catch
        messagebox(["LD2 nepavyko paleisti.";strcat(lasterror()," "); ...
            "Išskleiskite visą paketą į vieną aplanką ir paleiskite STENDAS.sce per grafinį Scilab."], ...
            "LD2 paleidimas","error");
        return;
    end
    [ok,st,cfg]=student_enroll("LD2");
    if ~ok then return; end
    LD2=struct("root",root,"cfg",cfg,"state",ld2_initial_state(cfg), ...
        "ui",struct("headless",%f,"suppress_render",%f),"example_active",%f,"example_backup",struct());
    LD2.state.student=st;LD2.state.assessment=%t;
    student_remember(st);
    ld2_build_gui(); ld2_go_step(1,%f);
    LD2.autosave_enabled=%t;
    bench_autosave("LD2");
endfunction

function ld2_student_details()
    global LD2;
    if LD2.example_active then ld2_show_info("Pavyzdys","Pirmiausia grįžkite į savo darbą."); return; end
    if ~isfield(LD2.state,"student") then LD2.state.student=student_empty("LD2"); end
    pick=messagebox([student_caption(LD2.state.student);student_parameter_lines("LD2",LD2.cfg)], ...
        "Studentas ir priskirtos reikšmės","info",["Grįžti" "Keisti duomenis"],"modal");
    if pick<>2 then return; end
    [ok,st,cfg]=student_enroll("LD2",LD2.state.student);
    if ~ok then return; end
    if st.number<>LD2.state.student.number then
        pick=messagebox("Kitas variantas pradės naują darbą. Dabartinį darbą galite išsaugoti per Pagalba.", ...
            "Keisti variantą?","question",["Atšaukti" "Pradėti naują"],"modal");
        if pick<>2 then return; end
    end
    ld2_apply_profile(st,cfg);
endfunction

function ld2_apply_profile(st,cfg)
    global LD2;
    ld2_save_answers();
    changed=st.number<>LD2.state.student.number;
    assessment=LD2.state.assessment; practice=LD2.state.practice_used;
    if changed then
        bench_autosave("LD2");
        if isfield(LD2,"autosave_error") then
            if LD2.autosave_error<>"" then return; end
        end
        ld2_clear_dynamic();
        LD2.cfg=cfg; LD2.state=ld2_initial_state(cfg);
        LD2.state.assessment=assessment; LD2.state.practice_used=practice;
        LD2.autosave_paths=emptystr(0,1); LD2.autosave_error="";
    end
    LD2.state.student=st;
    ld2_render_step();
    student_remember(st);
    if changed then bench_autosave("LD2"); end
endfunction

function ld2_student_close()
    global LD2;
    if typeof(LD2)<>"st" then return; end
    if ~isfield(LD2,"ui") | ~isfield(LD2.ui,"figure") then return; end
    if ~is_handle_valid(LD2.ui.figure) then return; end
    if LD2.example_active then ld2_show_solution(); end
    ld2_save_answers();
    bench_autosave("LD2");
    if isfield(LD2,"autosave_error") then
        if LD2.autosave_error<>"" then return; end
    end
    delete(LD2.ui.figure);
endfunction

function ld2_edit_parameters()
    global LD2;
    ld2_show_info("Priskirtos reikšmės",student_parameter_lines("LD2",LD2.cfg));
endfunction

function ld2_build_gui()
    global LD2;
    f=figure("resize","off","default_axes","off","dockable","off","menubar","none","toolbar","none","visible","off");
    f.figure_name="LD2 · Kintamosios srovės stendas"; f.axes_size=[1280 720];
    f.closerequestfcn="ld2_student_close()";
    f.figure_position=[10 10]; f.infobar_visible="off"; f.background=color(246,248,249);
    LD2.ui.figure=f; LD2.ui.dynamic=[]; LD2.ui.answer_edits=[]; LD2.ui.answer_step=0;
    LD2.ui.choice_yes=[]; LD2.ui.choice_no=[]; LD2.ui.term_handles=struct("dummy",0);
    student_text(f,[0.03 0.925 0.65 0.05],"LD2  /  Kintamosios srovės grandinės",22,%t,[0.965 0.973 0.977]);
    LD2.ui.studentProgress=student_text(f,[0.705 0.93 0.15 0.044],"",14,%f,[0.965 0.973 0.977]);
    LD2.ui.studentIdentity=student_text(f,[0.03 0.895 0.94 0.025],"",12,%f,[0.965 0.973 0.977]);
    student_button(f,[0.87 0.93 0.105 0.044],"Pagalba","ld2_student_help()");
    LD2.ui.stand=student_frame(f,[0.025 0.12 0.655 0.77]);
    LD2.ui.right=student_frame(f,[0.70 0.12 0.275 0.77]);
    LD2.ui.status=student_text(f,[0.025 0.025 0.95 0.07],"",13,%f,[0.94 0.96 0.96]);
    nav=student_frame(f,[0 0 0.01 0.01]); nav.visible="off";
    LD2.ui.step_buttons=[];
    for k=1:12
        h=student_button(nav,[0 0 1 1],string(k),"ld2_step_button("+string(k)+")");
        LD2.ui.step_buttons=[LD2.ui.step_buttons h];
    end
    LD2.ui.teacher=uicontrol(nav,"style","checkbox","value",0,"string","Peržiūra");
    student_finish_window(f); f.visible="on";
endfunction

function ld2_render_step()
    global LD2;
    if isfield(LD2.ui,"suppress_render") then if LD2.ui.suppress_render then return; end; end
    if isfield(LD2.ui,"headless") then if LD2.ui.headless then return; end; end
    drawing=LD2.ui.figure.immediate_drawing; LD2.ui.figure.immediate_drawing="off";
    ld2_save_answers(); ld2_clear_dynamic();
    ld2_render_instructions(); ld2_render_answers(); ld2_render_action_row();
    ld2_render_stand(); ld2_render_controls(); ld2_update_nav_colors();
    LD2.ui.studentProgress.string=string(LD2.state.step)+" / 12 etapas";
    if LD2.example_active then LD2.ui.studentProgress.string="Pavyzdys · "+string(LD2.state.step); end
    if isfield(LD2.state,"student") then LD2.ui.studentIdentity.string=student_caption(LD2.state.student); end
    LD2.ui.figure.immediate_drawing=drawing;
endfunction

function ld2_render_instructions()
    global LD2;
    titles=["Darbo eiga";"Sujunkite RC";"Apskaičiuokite RC";"Išmatuokite RC"; ...
        "Sujunkite RL";"Apskaičiuokite RL";"Išmatuokite RL";"Sujunkite RLC"; ...
        "Raskite rezonansą";"Įtampų maksimumai";"Dažnių juosta";"Jūsų rezultatai"];
    k=LD2.state.step;
    select k
    case 1 then
        tip=["Darbą sudaro trys dalys: RC, RL ir nuoseklios RLC grandinės tyrimas."; ...
             "Grandines jungsite patys, rodmenis fiksuos virtualūs matuokliai."; ...
             "Atsiskaityme programa tikrina, ar etapas užpildytas, bet neatskleidžia atsakymo teisingumo."];
    case 2 then
        tip=["Sujunkite nuoseklią RC grandinę pagal schemą kairėje."; ...
             "Laidą prijunkite paspausdami du mėlynus gnybtus. Generatorius turi būti išjungtas."; ...
             "Kai prijungti visi 4 laidai, spauskite Toliau."];
    case 3 then
        tip=["Pagal savo RC parametrus apskaičiuokite septynias reikšmes dešinėje."; ...
             "Į laukus rašykite tik skaičius; vienetai jau nurodyti."; ...
             "Formulės ir paaiškinimas pasiekiami per Pagalba → Šio etapo pagalba."];
    case 4 then
        tip=["Įjunkite generatorių ir išmatuokite srovę."; ...
             "Voltmetru paeiliui išmatuokite įtampą ties R8, C2 ir šaltiniu. Prieš kitą matavimą nuimkite zondus."; ...
             "Pagal rodmenis įrašykite dvi reikšmes dešinėje ir spauskite Toliau."];
    case 5 then
        tip=["Sujunkite nuoseklią RL grandinę pagal schemą kairėje."; ...
             "Laidą prijunkite paspausdami du mėlynus gnybtus. Generatorius turi būti išjungtas."; ...
             "Kai prijungti visi 4 laidai, spauskite Toliau."];
    case 6 then
        tip=["Pagal savo RL parametrus apskaičiuokite septynias reikšmes dešinėje."; ...
             "Į laukus rašykite tik skaičius; vienetai jau nurodyti."; ...
             "Formulės ir paaiškinimas pasiekiami per Pagalba → Šio etapo pagalba."];
    case 7 then
        tip=["Įjunkite generatorių ir išmatuokite srovę."; ...
             "Voltmetru paeiliui išmatuokite įtampą ties R9, L1 ir šaltiniu. Prieš kitą matavimą nuimkite zondus."; ...
             "Pagal rodmenis įrašykite dvi reikšmes dešinėje ir spauskite Toliau."];
    case 8 then
        tip=["Sujunkite nuoseklią RLC grandinę pagal schemą kairėje."; ...
             "Jungiama seka: šaltinis → ampermetras → C4 → L3 → R13 → šaltinis."; ...
             "Kai prijungti visi 5 laidai, spauskite Toliau."];
    case 9 then
        tip=["Voltmetrą prijunkite prie R13 ir įjunkite generatorių."; ...
             "Keiskite dažnį, spauskite Matuoti U ir Įrašyti tašką."; ...
             "Surinkite bent 3 taškus: žemiau maksimumo, ties maksimumu ir aukščiau jo. Tada įrašykite rezultatus dešinėje."];
    case 10 then
        tip=["Tirkite tris įtampas po vieną: UL, UC ir ULC."; ...
             "Kiekvienam taikiniui prijunkite voltmetrą, keiskite dažnį, matuokite ir įrašykite bent 3 taškus abipus ekstremumo."; ...
             "Iš savo taškų įrašykite maksimumus, minimumą ir jų dažnius."];
    case 11 then
        tip=["Voltmetrą prijunkite prie R13. Reikalingas lygis yra UR13,max / √2."; ...
             "Žemiau rezonanso raskite ir įrašykite f1, aukščiau rezonanso – f2."; ...
             "Tada apskaičiuokite juostos plotį BW ir kokybės koeficientą Q."];
    case 12 then
        tip=["Atlikite 0–10 kHz skenavimą ir peržiūrėkite darbo suvestinę."; ...
             "Jei norite, įrašykite bendras išvadas."; ...
             "Kai visi etapai užfiksuoti, spauskite Išsaugoti ataskaitą ir dėstytojui perduokite vieną HTML failą."];
    end
    h=student_text(LD2.ui.right,[0.07 0.85 0.86 0.11],student_wrap(titles(k),24),20,%t); ld2_track(h);
    h=student_text(LD2.ui.right,[0.07 0.625 0.86 0.215],student_wrap(tip,44),13,%f);
    h.verticalalignment="top"; ld2_track(h);
endfunction

function ld2_render_answers()
    global LD2;
    p=LD2.ui.right; step=LD2.state.step;
    [labels,n]=ld2_answer_spec(step);
    LD2.ui.answer_edits=[]; LD2.ui.answer_step=step;
    if n>0 then
        h=student_text(p,[0.07 0.585 0.86 0.04],"JŪSŲ ATSAKYMAI",12,%t); ld2_track(h);
        for k=1:n
            y=0.515-(k-1)*0.057;
            h=student_text(p,[0.07 y 0.51 0.053],student_wrap(labels(k),26),12,%f); ld2_track(h);
            e=ld2_edit(p,[0.62 y 0.31 0.05],LD2.state.answers_text(step,k));
            e.callback="ld2_student_answers_changed()";
            e.tag=msprintf("A%02d.%02d",step,k);
            e.tooltipstring=msprintf("[A%02d.%02d] ",step,k)+labels(k);
            LD2.ui.answer_edits=[LD2.ui.answer_edits e];
        end
    elseif step==2 | step==5 | step==8 then
        phase=ld2_phase_for_step(step); req=ld2_required_main(phase); c=ld2_get_phase_connections(phase);
        txt=string(size(c,1))+" / "+string(size(req,1))+" laidai prijungti";
        h=student_text(p,[0.07 0.47 0.86 0.07],txt,17,%t); ld2_track(h);
        action="Toliau"; if ~LD2.state.assessment then action="Patikrinti"; end
        h=student_text(p,[0.07 0.32 0.86 0.13],student_wrap("Sujungę spauskite "+action+". Jei suklydote, atšaukite paskutinį laidą.",37),14,%f); ld2_track(h);
    elseif step==1 then
        h=student_text(p,[0.07 0.36 0.86 0.20],student_wrap("Pirmiausia peržiūrėkite darbo eigą. Toliau kiekviename ekrane bus vienas konkretus veiksmas.",37),15,%f); ld2_track(h);
    elseif step==12 then
        h=ld2_button_reg(p,[0.07 0.48 0.86 0.06],"Darbo suvestinė","ld2_show_summary_window()",%f,%f); ld2_track(h);
        h=ld2_button_reg(p,[0.07 0.39 0.86 0.06],"Įrašyti išvadas","ld2_edit_conclusions()",%f,%f); ld2_track(h);
    end
endfunction

function ld2_render_action_row()
    global LD2;
    label="Patikrinti";
    if LD2.state.completed(LD2.state.step) then label="Toliau →"; end
    if LD2.state.assessment then label="Toliau →";end
    if LD2.state.step==1 then label="Pradėti →"; end
    if LD2.state.step==12 then label="Išsaugoti ataskaitą"; end
    if LD2.example_active then label="Grįžti į savo darbą"; end
    h=student_button(LD2.ui.right,[0.07 0.085 0.86 0.075],label,"ld2_student_primary()",%t);
    h.tag="B04";
    h.tooltipstring="Užfiksuoja dabartinį etapą ir tęsia darbą.";
    LD2.ui.studentPrimary=h; ld2_track(h);
    h=ld2_button_reg(LD2.ui.right,[0.07 0.015 0.37 0.045],"← Atgal","ld2_prev()",%f,%f);
    if LD2.state.step==1 | LD2.example_active then h.enable="off"; end; ld2_track(h);
endfunction

function ld2_student_answers_changed()
    global LD2;
    ld2_save_answers();
    bench_autosave("LD2");
    if ~LD2.example_active then
        if LD2.state.assessment then LD2.ui.studentPrimary.string="Toliau →";
        else LD2.ui.studentPrimary.string="Patikrinti";end
    end
endfunction

function ld2_student_primary()
    global LD2;
    ld2_save_answers();
    if LD2.example_active then ld2_show_solution();
    elseif LD2.state.assessment then
        // Jei 12 etapas jau užbaigtas ir visi etapai įskaityti, pirminis mygtukas
        // yra ataskaitos eksportas. Nekartojame transientinių matavimo būsenų
        // validacijos po renderio / sesijos atkūrimo: pakeistas atsakymas ar
        // laidai patys nuima atitinkamo etapo completed žymą.
        if LD2.state.step==12 & and(LD2.state.completed==1) then
            bench_export_current("LD2");
            return;
        end
        if ~ld2_assessment_ready() then bench_autosave("LD2"); return; end
        LD2.state.completed(LD2.state.step)=1; LD2.state.skipped(LD2.state.step)=0;
        bench_autosave("LD2");
        if LD2.state.step==12 then bench_export_current("LD2");
        else ld2_go_step(LD2.state.step+1,%f);end
    elseif LD2.state.step==1 then ld2_check_step(); ld2_next();
    elseif LD2.state.completed(LD2.state.step) then
        if LD2.state.step==12 then bench_export_current("LD2"); else ld2_next(); end
    else ld2_check_step(); end
endfunction

function ld2_student_help()
    global LD2;
    selected=x_choose(["Šio etapo pagalba";"Tęsti arba atkurti darbą"; ...
        "Mano duomenys ir variantas";"Ataskaita ir rezultatai";"Daugiau veiksmų"],"Pagalba");
    n=0;
    if selected==1 then
        a=x_choose(["Metodika ir formulės";"Etapo paaiškinimas";"Grafikai";"Matavimų žurnalas";"Kontaktų žinynas"],"Šio etapo pagalba");
        if a==1 then n=1;
        elseif a==2 then n=13;
        elseif a==3 then
            k=x_choose(["Dabartinio bandymo grafikas";"Oscilograma";"Varžų vektoriai";"Įtampų vektoriai"],"Grafikai");
            select k
            case 1 then ld2_plot_current();
            case 2 then ld2_plot_scope_current();
            case 3 then ld2_plot_impedance();
            case 4 then ld2_plot_voltage_current(); end
            return;
        elseif a==4 then n=4;
        elseif a==5 then n=14; end
    elseif selected==2 then
        a=x_choose(["Tęsti automatinį juodraštį";"Išsaugoti darbą";"Atverti išsaugotą darbą";"Etapai"],"Tęsti arba atkurti darbą");
        if a==1 then n=11; elseif a==2 then n=5; elseif a==3 then n=6; elseif a==4 then n=7; end
    elseif selected==3 then
        a=x_choose(["Studentas ir priskirtos reikšmės";"64 variantų bankas"],"Mano duomenys ir variantas");
        if a==1 then n=8; elseif a==2 then n=15; end
    elseif selected==4 then
        a=x_choose(["Darbo suvestinė";"Įrašyti išvadas";"Išsaugoti ataskaitą";"Atverti ataskaitų aplanką"],"Ataskaita ir rezultatai");
        if a==1 then ld2_show_summary_window(); return;
        elseif a==2 then ld2_edit_conclusions(); return;
        elseif a==3 then bench_export_current("LD2"); return;
        elseif a==4 then bench_open_local(bench_documents()); return; end
    elseif selected==5 then
        a=x_choose(["Atsiskaitymo / mokymosi režimas";"Parodyti pavyzdį / mano darbą"; ...
            "Pradėti darbą iš naujo";"Šaltiniai ir metodiniai pakeitimai";"Valdiklių žinynas"],"Daugiau veiksmų");
        if a==1 then n=12; elseif a==2 then n=2; elseif a==3 then n=9; elseif a==4 then n=16; elseif a==5 then n=17; end
    end
    select n
    case 1 then ld2_help_current();
    case 2 then ld2_show_solution();
    case 4 then ld2_show_journal();
    case 5 then ld2_save_work();
    case 6 then ld2_load_work();
    case 7 then
        opts=emptystr(12,1);
        for k=1:12
            state="Neatlikta";
            if LD2.state.completed(k)==1 then
                if LD2.state.assessment then state="Įrašyta"; else state="Patikrinta"; end
            elseif LD2.state.skipped(k)==1 then state="Praleista"; end
            opts(k)=string(k)+" etapas · "+state+" · "+ld2_step_title(k);
        end
        k=x_choose(opts,"Etapai · atsakymai išlieka");
        if k>0 then ld2_step_button(k); end
    case 8 then ld2_student_details();
    case 9 then ld2_restart();
    case 11 then bench_open_snapshot("LD2");
    case 12 then bench_mode("LD2");
    case 13 then ld2_edit_step_note();
    case 14 then ld2_show_contact_map();
    case 15 then ld2_show_variant_bank();
    case 16 then ld2_show_method_fixes();
    case 17 then ld2_show_button_map();
    end
endfunction

function ld2_render_controls()
    // Controls belong beside the relevant instrument on the bench.
    global LD2;
    phase=ld2_phase_for_step(LD2.state.step); step=LD2.state.step; p=LD2.ui.stand;
    if phase=="OVERVIEW" then return; end
    if step==2 | step==5 | step==8 then
        h=ld2_button_reg(p,[0.04 0.035 0.23 0.055],"Atšaukti laidą","ld2_undo_wire()"); ld2_track(h);
    end
    if phase=="RLC" & step>=9 then
        fr=ld2_frame(p,[0.035 0.085 0.30 0.225],[0.95 0.97 0.97]);
        ld2_text(fr,[0.07 0.77 0.86 0.16],"DAŽNIS, Hz",13,%t,"left",[0.95 0.97 0.97],[0.13 0.19 0.23]);
        LD2.ui.freq_edit=ld2_edit(fr,[0.07 0.43 0.55 0.25],ld2_num(LD2.state.freq,3));
        LD2.ui.freq_edit.callback="ld2_apply_frequency()";
        LD2.ui.freq_edit.tag="F04";
        LD2.ui.freq_edit.tooltipstring="[F04] Dažnis, Hz. [B16] Taikyti – pritaiko reikšmę.";
        ld2_button_reg(fr,[0.66 0.43 0.27 0.25],"Taikyti","ld2_apply_frequency()",%f,%f,13,[0.90 0.94 0.94]);
        ld2_button_reg(fr,[0.07 0.09 0.39 0.22],"−1 Hz","ld2_frequency_delta(-1)",%f,%f,13,[0.90 0.94 0.94]);
        ld2_button_reg(fr,[0.54 0.09 0.39 0.22],"+1 Hz","ld2_frequency_delta(1)",%f,%f,13,[0.90 0.94 0.94]);
        if step==9 then cb="ld2_record_resonance_point()"; label="Įrašyti tašką";
        elseif step==10 then cb="ld2_record_peak_point()"; label="Įrašyti tašką";
        elseif step==12 then cb="ld2_run_sweep()"; label="Skenuoti 0–10 kHz";
        else cb=""; label=""; end
        if cb<>"" then h=ld2_button_reg(p,[0.41 0.035 0.28 0.055],label,cb); ld2_track(h); end
        if step==11 then
            h=ld2_button_reg(p,[0.39 0.035 0.17 0.055],"Įrašyti f1","ld2_record_f1()",%f,%f); ld2_track(h);
            h=ld2_button_reg(p,[0.58 0.035 0.17 0.055],"Įrašyti f2","ld2_record_f2()",%f,%f); ld2_track(h);
        end
    end
    if step==4 | step==7 | step>=9 then
        h=ld2_button_reg(p,[0.75 0.035 0.21 0.055],"Nuimti zondus","ld2_remove_voltage_probes()",%f,%f,12); ld2_track(h);
        h=ld2_button_reg(p,[0.75 0.115 0.21 0.055],"Matavimai","ld2_show_journal()"); ld2_track(h);
    end
    if LD2.example_active then
        // An example is view-only; all dynamic buttons except the return action are locked.
        for h=LD2.ui.dynamic
            if h.type=="uicontrol" then
                if h.style=="pushbutton" | h.style=="edit" | h.style=="slider" then h.enable="off"; end
            end
        end
        LD2.ui.studentPrimary.enable="on";
    end
endfunction

function ld2_component_box(parent,pos,main,sub,bg)
    global LD2;
    bg=[0.96 0.97 0.96]; phase=ld2_phase_for_step(LD2.state.step); step=LD2.state.step;
    if main=="GENERATORIUS" then
        pos(4)=0.24; pos(2)=0.40;
        if phase=="RLC" then pos(3)=0.11; end
        fr=ld2_frame(parent,pos,[0.94 0.97 0.97]);
        fr.tag="component:GEN";
        ld2_text(fr,[0.07 0.77 0.86 0.16],"ŠALTINIS",12,%t,"left",[0.94 0.97 0.97],[0.13 0.19 0.23]);
        txt=strsubst(sub," • ",ascii(10));
        if phase=="RLC" then txt=strsubst(txt," Hz",ascii(10)+"Hz"); end
        ld2_text(fr,[0.07 0.31 0.86 0.40],txt,14,%t,"left",[0.94 0.97 0.97],[0.13 0.19 0.23]);
        label="Įjungti"; if LD2.state.power then label="Išjungti"; end
        h=ld2_button_reg(fr,[0.07 0.06 0.86 0.22],label,"ld2_power_toggle()",%f,%t,12); ld2_track(h);
        h.string=label;
        if step==2 | step==3 | step==5 | step==6 | step==8 then h.enable="off"; end
    elseif main=="A~" then
        pos(2)=0.535; pos(4)=0.19;
        if phase=="RLC" then pos(1)=0.238; pos(3)=0.075;
        else pos(1)=0.293; pos(3)=0.089; end
        [tx,ty]=ld2_terminal_xy(phase,"AM_H");
        ld2_wire_segment(parent,tx+0.014,ty+0.019,pos(1),ty+0.019,[0.41 0.49 0.51]);
        [tx,ty]=ld2_terminal_xy(phase,"AM_L");
        ld2_wire_segment(parent,pos(1)+pos(3),ty+0.019,tx+0.014,ty+0.019,[0.41 0.49 0.51]);
        fr=ld2_frame(parent,pos,[0.93 0.96 0.96]);
        fr.tag="component:AM";
        ld2_text(fr,[0.06 0.77 0.88 0.16],"A~",15,%t,"center",[0.93 0.96 0.96],[0.13 0.19 0.23]);
        reading=strsubst(ld2_amp_display_text()," mA",ascii(10)+"mA");
        ld2_text(fr,[0.04 0.34 0.92 0.36],reading,12,%t,"center",[0.93 0.96 0.96],[0.13 0.19 0.23]);
        if step==4 | step==7 | step>=9 then
            h=ld2_button_reg(fr,[0.06 0.06 0.88 0.24],"Matuoti","ld2_measure_current()",%t,%f,10.5); ld2_track(h);
            h.string="Matuoti";
        end
    elseif main=="V~ VOLTMETRAS" then
        if ~(step==4 | step==7 | step>=9) then return; end
        pos=[0.41 0.10 0.28 0.16];
        fr=ld2_frame(parent,pos,[0.93 0.96 0.96]);
        fr.tag="component:VM";
        ld2_text(fr,[0.07 0.77 0.86 0.19],"VOLTMETRAS · V~",12,%t,"left",[0.93 0.96 0.96],[0.13 0.19 0.23]);
        ld2_text(fr,[0.07 0.41 0.86 0.28],ld2_volt_display_text(),19,%t,"center",[0.93 0.96 0.96],[0.13 0.19 0.23]);
        h=ld2_button_reg(fr,[0.07 0.06 0.86 0.29],"Matuoti U","ld2_measure_voltage()",%t,%f,12); ld2_track(h);
    else
        eq=strindex(main," = ");
        if size(eq,"*")>0 then
            id=part(main,1:eq(1)-1);
            if phase=="RLC" then
                select id
                case "C4" then pos(1)=0.415;
                case "L3" then pos(1)=0.592;
                case "R13" then pos(1)=0.769;
                end
                pos(3)=0.075;
            else pos(1)=pos(1)+0.012; pos(3)=pos(3)-0.022; end
            [tx,ty]=ld2_terminal_xy(phase,id+"_1");
            ld2_wire_segment(parent,tx+0.014,ty+0.019,pos(1),ty+0.019,[0.41 0.49 0.51]);
            [tx,ty]=ld2_terminal_xy(phase,id+"_2");
            ld2_wire_segment(parent,pos(1)+pos(3),ty+0.019,tx+0.014,ty+0.019,[0.41 0.49 0.51]);
        end
        fr=ld2_frame(parent,pos,bg);
        fr.tag="component:"+id;
        txt=strsubst(main," = ",ascii(10));
        if phase=="RLC" then txt=strsubst(txt," ",ascii(10)); end
        ld2_text(fr,[0.07 0.10 0.86 0.80],txt,14,%t,"center",bg,[0.13 0.19 0.23]);
    end
endfunction

function ld2_draw_terminal(parent,id,label,xy,active,c)
    global LD2;
    used=ld2_terminal_used(c,id); isactive=ld2_in_string_list(id,active);
    if ~used & ~isactive then return; end
    parts=tokens(id,"_"); owner=parts(1);
    if id=="LC_M1" then owner="C4"; end
    if id=="LC_M2" then owner="L3"; end
    for fr=parent.children'
        if fr.style=="frame" & fr.tag=="component:"+owner then
            r=fr.position; center=xy+[0.014 0.019];
            edge=[max(r(1),min(r(1)+r(3),center(1))) max(r(2),min(r(2)+r(4),center(2)))];
            mid=[center(1) edge(2)];
            hh=student_wire(parent,center,mid,[0.41 0.49 0.51],"lead:"+owner); if hh<>[] then ld2_track(hh); end
            hh=student_wire(parent,mid,edge,[0.41 0.49 0.51],"lead:"+owner); if hh<>[] then ld2_track(hh); end
        end
    end
    selected=(LD2.state.selected_terminal==id);
    bg=[0.08 0.39 0.37]; if selected then bg=[0.85 0.59 0.16]; end
    if label=="COM" then label="C"; end
    h=student_terminal(parent,xy+[0.014 0.019],label,ld2_terminal_code(id), ...
        msprintf("ld2_terminal_click(""%s"")",id),ld2_terminal_name(id),bg);
    if LD2.example_active | used then h.enable="off"; end
    ld2_track(h);
endfunction

function ld2_draw_phase_stand(parent,phase,step)
    global LD2;
    c=ld2_get_phase_connections(phase); active=ld2_active_terminals(step);
    ports=[];
    for id=matrix(ld2_terminal_ids(),1,-1)
        if ld2_terminal_used(c,id) | ld2_in_string_list(id,active) then
            [tx,ty]=ld2_terminal_xy(phase,id); ports($+1,:)=[tx+0.014 ty+0.019 36 40];
        end
    end
    parent.user_data=struct("ports",ports);
    student_begin_wires(parent);
    ld2_text(parent,[0.04 0.87 0.9 0.065],phase+" grandinė",19,%t,"left",[1 1 1],[0.13 0.19 0.23]);
    if step==2 | step==5 | step==8 then tip="Laidas: spauskite du gnybtus.";
    elseif step==3 | step==6 then tip="Parametrai pateikti prie komponentų.";
    else tip="Zondus junkite prie elemento M lizdų. Laidų tarpas sankirtoje: nesujungta."; end
    ld2_text(parent,[0.04 0.79 0.92 0.065],student_wrap(tip,72),14,%f,"left",[1 1 1],[0.38 0.45 0.48]);
    for k=1:size(c,1); ld2_draw_connection(parent,phase,c(k,1),c(k,2)); end
    if phase=="RC" then
        ld2_draw_chain_common(parent,phase,msprintf("R8 = %.0f Ω",LD2.cfg.R8), ...
            msprintf("C2 = %.2f µF",LD2.cfg.C2*1e6),"R8","C2",active,c);
    elseif phase=="RL" then
        ld2_draw_chain_common(parent,phase,msprintf("R9 = %.0f Ω",LD2.cfg.R9), ...
            msprintf("L1 = %.2f H",LD2.cfg.L1),"R9","L1",active,c);
    else ld2_draw_rlc_chain(parent,active,c); end
    h=student_end_wires(parent); if h<>[] then ld2_track(h); end
endfunction

function ld2_draw_overview(parent)
    ld2_text(parent,[0.06 0.79 0.88 0.10],"Vienas stendas. Trys tyrimai.",27,%t,"left",[1 1 1],[0.13 0.19 0.23]);
    names=["RC";"RL";"RLC"]; desc=["Rezistorius + kondensatorius";"Rezistorius + ritė";"Rezonanso tyrimas"];
    for k=1:3
        y=0.60-(k-1)*0.19;
        fr=ld2_frame(parent,[0.06 y 0.88 0.145],[0.95 0.97 0.97]);
        ld2_text(fr,[0.05 0.2 0.17 0.6],names(k),27,%t,"left",[0.95 0.97 0.97],[0.08 0.39 0.37]);
        ld2_text(fr,[0.24 0.2 0.71 0.6],desc(k),19,%f,"left",[0.95 0.97 0.97],[0.13 0.19 0.23]);
    end
endfunction
