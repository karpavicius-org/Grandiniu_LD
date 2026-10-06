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
    bench_core_require();
    [ok,st,cfg]=student_enroll("LD2");
    if ~ok then return; end
    LD2=struct("root",root,"cfg",cfg,"state",ld2_initial_state(cfg), ...
        "ui",struct("headless",%f,"suppress_render",%f),"example_active",%f,"example_backup",struct());
    LD2.state.student=st;LD2.state.assessment=%t;
    student_remember(st);
    ld2_build_gui(); ld2_go_step(1,%f);
    LD2.autosave_enabled=%t;
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
    assessment=LD2.state.assessment; practice=LD2.state.practice_used;
    if st.number<>LD2.state.student.number then
        ld2_clear_dynamic();
        LD2.cfg=cfg; LD2.state=ld2_initial_state(cfg);
        LD2.state.assessment=assessment; LD2.state.practice_used=practice;
    end
    LD2.state.student=st;
    ld2_render_step();
    student_remember(st);
endfunction

function ld2_edit_parameters()
    global LD2;
    ld2_show_info("Priskirtos reikšmės",student_parameter_lines("LD2",LD2.cfg));
endfunction

function ld2_build_gui()
    global LD2;
    f=figure("resize","off","default_axes","off","dockable","off","menubar","none","toolbar","none","visible","off");
    f.figure_name="LD2 · Kintamosios srovės stendas"; f.axes_size=[1280 720];
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
    titles=["Trys grandinės";"Sujunkite RC";"Apskaičiuokite RC";"Išmatuokite RC"; ...
        "Sujunkite RL";"Apskaičiuokite RL";"Išmatuokite RL";"Sujunkite RLC"; ...
        "Raskite rezonansą";"Įtampų maksimumai";"Dažnių juosta";"Jūsų rezultatai"];
    // Instrukcijos su elementų kodais: [Bxx] mygtukai, [Txx] lizdai,
    // [Wxx] laidai, [Axx.xx] atsakymų laukai (žinynas – Pagalba → [B45]).
    // Instrukcijos su elementų kodais: [Bxx] mygtukai, [Txx] lizdai,
    // [Wxx] laidai, [Axx.xx] atsakymų laukai (žinynas – Pagalba → [B45]).
    tips=[ ...
        "Priskirkite variantą: Pagalba → [B01]."; ...
        "[F01] numeris 1–64; [F02] vardas; [F03] grupė."; ...
        "[B39] rodo jūsų reikšmes; [B43] – 64 variantai."; ...
        "Metodika: Pagalba → [B02]; [B05] išsaugo darbą.";
        "[B09] generatorius turi būti IŠJUNGTAS."; ...
        "[W01] [T01]→[T05];   [W02] [T06]→[T09]."; ...
        "[W03] [T10]→[T13];  [W04] [T14]→[T02]."; ...
        "Laidas: spauskite pirmą, paskui antrą lizdą."; ...
        "[B11] atšaukia laidą; [B12] valo visus."; ...
        "Baigę spauskite „Patikrinti“ ([B04]).";
        "Apskaičiuokite [A03.01]–[A03.07]."; ...
        "Parametrai: [B39] (E_RC, f_RC, R8, C2)."; ...
        "I – mA, P – mW, φI – laipsniais."; ...
        "E = √(UR8²+UC2²); φI tarp 0 ir +90°."; ...
        "Meniu Grafikai: [B28] varžos, [B29] įtampų."; ...
        "Paaiškinkite per [B41]; tikrinkite [B04].";
        "[B09] įjunkite; [B14] išmatuokite srovę I."; ...
        "UR8: [T07]→[T11], [T08]→[T12]; [B15]."; ...
        "UC2: [T07]→[T15], [T08]→[T16]; [B15]."; ...
        "E: [T07]→[T03], [T08]→[T04]; [B15]."; ...
        "Prieš kitą porą spauskite [B13]."; ...
        "[A04.01] √(UR8²+UC2²); [A04.02] 1000·UR8/R8."; ...
        "Žurnalas – [B33]; diagramos meniu Grafikai.";
        "[B09] generatorius turi būti IŠJUNGTAS."; ...
        "[W01] [T01]→[T05];   [W02] [T06]→[T17]."; ...
        "[W03] [T18]→[T21];  [W04] [T22]→[T02]."; ...
        "M lizdus [T19]–[T24] dar nejunkite."; ...
        "[B11] atšaukia laidą; [B12] valo visus."; ...
        "Baigę spauskite „Patikrinti“ ([B04]).";
        "Apskaičiuokite [A06.01]–[A06.07]."; ...
        "Parametrai: [B39] (E_RL, f_RL, R9, L1)."; ...
        "I – mA, P – mW; φI −90°…0°."; ...
        "E = √(UR9²+UL1²)."; ...
        "Meniu Grafikai: [B28] varžos, [B29] įtampų."; ...
        "Palyginimą su RC įrašykite per [B41].";
        "[B09] įjunkite; [B14] išmatuokite srovę I."; ...
        "UR9: [T07]→[T19], [T08]→[T20]; [B15]."; ...
        "UL1: [T07]→[T23], [T08]→[T24]; [B15]."; ...
        "E: [T07]→[T03], [T08]→[T04]; [B15]."; ...
        "Prieš kitą porą spauskite [B13]."; ...
        "[A07.01] √(UR9²+UL1²); [A07.02] 1000·UR9/R9.";
        "[B09] generatorius turi būti IŠJUNGTAS."; ...
        "[W01] [T01]→[T05];   [W02] [T06]→[T25]."; ...
        "[W03] [T26]→[T29];  [W04] [T30]→[T33]."; ...
        "[W05] [T34]→[T02]. Voltmetro dar nejunkite."; ...
        "[B11] atšaukia laidą; [B12] valo visus."; ...
        "Baigę spauskite „Patikrinti“ ([B04]).";
        "Zondai: [T07]→[T35], [T08]→[T36]; [B09] įjungta."; ...
        "[F04] ir [B16] nustato dažnį."; ...
        "Seka: [B16] → [B15] → [B21]."; ...
        "3+ taškai abipus maksimumo ([B18]/[B20])."; ...
        "[A09.01]–[A09.04]: f0, fr, 1000/fr, UR13."; ...
        "Paieškos taškai – [B31]; paaiškinimas [B41].";
        "UL: [T07]→[T31], [T08]→[T32] (prieš tai [B13])."; ...
        "UC: [T07]→[T27], [T08]→[T28]."; ...
        "ULC: [T07]→[T37], [T08]→[T38]."; ...
        "Seka: [B16] → [B15] → [B23]; 3+ taškai."; ...
        "Iš lentelės → [A10.01]–[A10.06]."; ...
        "Ieškokite UL/UC maks., ULC min ([B04] tikrina).";
        "Zondai: [T07]→[T35], [T08]→[T36]; [B09] įjungta."; ...
        "Slenkstis: UR13,max/√2 (iš [E09] taškų)."; ...
        "Žemiau fr: [B16]→[B15], tada [B24]."; ...
        "Aukščiau fr: [B16]→[B15], tada [B25]."; ...
        "[A11.01]–[A11.05]: slenkstis, f1, f2, BW, Q."; ...
        "BW = f2−f1;  Q = fr/BW.";
        "Zondai: [T07]→[T35], [T08]→[T36]; [B09] įjungta."; ...
        "[B26] skenuoja 0–10 kHz lentelę."; ...
        "[B31] grafikas; [B33] žurnalas; [B34] suvestinė."; ...
        "[B08] bendros išvados; [B41] etapo aprašymas."; ...
        "Tikrinkite [B04]; [B05] išsaugo darbą."; ...
        "[B07] sugeneruoja HTML ataskaitą.";
    ];
    starts=[1 5 11 17 24 30 36 43 49 55 61 67];
    k=LD2.state.step;
    if k<12 then tip=tips(starts(k):starts(k+1)-1); else tip=tips(starts(12):$); end
    h=student_text(LD2.ui.right,[0.07 0.85 0.86 0.11],student_wrap(titles(LD2.state.step),24),20,%t); ld2_track(h);
    h=student_text(LD2.ui.right,[0.07 0.625 0.86 0.215],student_wrap(tip,44),12,%f);
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
            label=msprintf("[A%02d.%02d] ",step,k)+labels(k);
            h=student_text(p,[0.07 y 0.51 0.053],student_wrap(label,26),12,%f); ld2_track(h);
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
        h=student_text(p,[0.07 0.32 0.86 0.13],student_wrap("Sujungę spauskite Patikrinti. Jei suklydote, atšaukite paskutinį laidą.",37),14,%f); ld2_track(h);
    elseif step==1 then
        h=student_text(p,[0.07 0.36 0.86 0.20],student_wrap("Grandinę jungiate patys. Rodmenis fiksuojate prietaisuose. Patikrinę atsakymą pereinate toliau.",37),15,%f); ld2_track(h);
    elseif step==12 then
        h=ld2_button_reg(p,[0.07 0.48 0.86 0.06],"Rezultatų suvestinė","ld2_show_summary_window()"); ld2_track(h);
        h=ld2_button_reg(p,[0.07 0.39 0.86 0.06],"Įrašyti išvadas","ld2_edit_conclusions()"); ld2_track(h);
        h=ld2_button_reg(p,[0.07 0.30 0.86 0.06],"Ataskaita dėstytojui","bench_export_current(""LD2"")"); ld2_track(h);
    end
endfunction

function ld2_render_action_row()
    global LD2;
    label="Patikrinti";
    if LD2.state.completed(LD2.state.step) then label="Toliau →"; end
    if LD2.state.assessment then label="Įrašyti ir toliau →";end
    if LD2.state.step==1 then label="Pradėti →"; end
    if LD2.state.step==12 then label="Išsaugoti ataskaitą"; end
    if LD2.example_active then label="Grįžti į savo darbą"; end
    h=student_button(LD2.ui.right,[0.07 0.085 0.86 0.075],label,"ld2_student_primary()",%t);
    h.tag="B04";
    h.tooltipstring="[B04] Etapo patikra ir tęsimas (Patikrinti / Toliau).";
    LD2.ui.studentPrimary=h; ld2_track(h);
    h=ld2_button_reg(LD2.ui.right,[0.07 0.015 0.37 0.045],"← Atgal","ld2_prev()",%f,%f);
    if LD2.state.step==1 | LD2.example_active then h.enable="off"; end; ld2_track(h);
endfunction

function ld2_student_answers_changed()
    global LD2;
    ld2_save_answers();
    bench_autosave("LD2");
    if ~LD2.example_active then
        if LD2.state.assessment then LD2.ui.studentPrimary.string="Įrašyti ir toliau →";
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
    n=x_choose(["Šio etapo metodika ir formulės [B02]";"Parodyti pavyzdį / mano darbą [B03]"; ...
        "Grafikai";"Matavimų žurnalas [B33]";"Išsaugoti darbą [B05]";"Atverti išsaugotą darbą [B06]"; ...
        "Etapai";"Studentas ir priskirtos reikšmės [B01]";"Pradėti iš naujo [B37]";"Išsaugoti ataskaitą dėstytojui [B07]";"Atverti automatinį juodraštį";"Atsiskaitymo / mokymosi režimas"; ...
        "Etapo paaiškinimas [B41]";"Kontaktų žinynas [B42]";"64 variantų bankas [B43]"; ...
        "Šaltiniai ir metodiniai pakeitimai [B38]";"Valdiklių žinynas [B45]"],"Pagalba ir papildomi veiksmai");
    select n
    case 1 then ld2_help_current();
    case 2 then ld2_show_solution();
    case 3 then
        k=x_choose(["Dabartinio bandymo grafikas";"Oscilograma";"Varžų vektoriai";"Įtampų vektoriai"],"Grafikai");
        select k
        case 1 then ld2_plot_current();
        case 2 then ld2_plot_scope_current();
        case 3 then ld2_plot_impedance();
        case 4 then ld2_plot_voltage_current(); end
    case 4 then ld2_show_journal();
    case 5 then ld2_save_work();
    case 6 then ld2_load_work();
    case 7 then
        opts=emptystr(12,1);
        for k=1:12; opts(k)=ld2_step_title(k); end
        k=x_choose(opts,"Etapai · atsakymai išlieka");
        if k>0 then ld2_step_button(k); end
    case 8 then ld2_student_details();
    case 9 then ld2_restart();
    case 10 then bench_export_current("LD2");
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
        h=ld2_button_reg(p,[0.75 0.035 0.21 0.055],"Nuimti zondus","ld2_remove_voltage_probes()",%f,%t,12); ld2_track(h);
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
        h.string="<html><center>[B09]<br>"+label+"</center></html>";
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
            h=ld2_button_reg(fr,[0.06 0.06 0.88 0.24],"Matuoti I","ld2_measure_current()",%t,%f,12); ld2_track(h);
            h.string="<html><center>[B14] I</center></html>";
        end
    elseif main=="V~ VOLTMETRAS" then
        if ~(step==4 | step==7 | step>=9) then return; end
        pos=[0.41 0.10 0.28 0.16];
        fr=ld2_frame(parent,pos,[0.93 0.96 0.96]);
        fr.tag="component:VM";
        ld2_text(fr,[0.07 0.77 0.86 0.19],"VOLTMETRAS · V~",12,%t,"left",[0.93 0.96 0.96],[0.13 0.19 0.23]);
        ld2_text(fr,[0.07 0.41 0.86 0.28],ld2_volt_display_text(),19,%t,"center",[0.93 0.96 0.96],[0.13 0.19 0.23]);
        h=ld2_button_reg(fr,[0.07 0.06 0.86 0.29],"Matuoti U","ld2_measure_voltage()",%t,%t,12); ld2_track(h);
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
