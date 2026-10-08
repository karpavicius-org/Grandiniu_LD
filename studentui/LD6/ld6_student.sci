// ============================================================================
// LD6 studento srautas: paleidimas, pagrindinis mygtukas, pagalba.
// ============================================================================

function ld6_student_main(root)
    global LD6;
    if typeof(LD6)=="st" then
        if isfield(LD6,"fig") then
            if is_handle_valid(LD6.fig) then show_window(LD6.fig); return; end
        end
    end
    try bench_core_require(); catch
        messagebox(["LD6 nepavyko paleisti.";strcat(lasterror()," "); ...
            "Išskleiskite visą paketą į vieną aplanką ir paleiskite STENDAS.sce per grafinį Scilab."], ...
            "LD6 paleidimas","error");
        return;
    end
    [ok,st,cfg]=student_enroll("LD6");
    if ~ok then return; end
    LD6=struct("root",root,"cfg",cfg,"student",st);
    student_remember(st); ld6_start();
    bench_autosave("LD6");
endfunction

function ld6_student_details()
    global LD6;
    if LD6.demoMode then
        ld6_set_status("Pirmiausia grįžkite į savo darbą.","info","");
        return;
    end
    pick=messagebox([student_caption(LD6.student);student_parameter_lines("LD6",LD6.cfg)], ...
        "Studentas ir priskirtos reikšmės","info",["Grįžti" "Keisti duomenis"],"modal");
    if pick<>2 then return; end
    [ok,st,cfg]=student_enroll("LD6",LD6.student);
    if ~ok then return; end
    if st.number<>LD6.student.number then
        pick=messagebox("Kitas variantas pradės naują darbą. Dabartinis darbas pirmiausia bus išsaugotas.", ...
            "Keisti variantą?","question",["Atšaukti" "Pradėti naują"],"modal");
        if pick<>2 then return; end
    end
    ld6_apply_profile(st,cfg);
endfunction

function ld6_apply_profile(st,cfg)
    global LD6;
    ld6_save_answers();
    changed=st.number<>LD6.student.number;
    assessment=LD6.assessment; practice=LD6.practice_used;
    if changed then
        bench_autosave("LD6");
        if isfield(LD6,"autosave_error") then
            if LD6.autosave_error<>"" then return; end
        end
        ld6_init_state();
        LD6.cfg=cfg; LD6.student=st;
        LD6.assessment=assessment; LD6.practice_used=practice;
        LD6.autosave_paths=emptystr(0,1); LD6.autosave_error="";
    else
        LD6.cfg=cfg; LD6.student=st;
    end
    student_remember(st);
    if isfield(LD6,"ui") then
        if ~isfield(LD6.ui,"headless") | ~LD6.ui.headless then ld6_render_stage(); end
    end
    bench_autosave("LD6");
endfunction

function path=ld6_export_report()
    global LD6;
    path="";
    ld6_save_answers();
    if LD6.assessment & ~and(LD6.done) then
        ld6_set_status("Dar yra neužbaigtų etapų.","error","Užbaikite visus 6 etapus ir tada išsaugokite ataskaitą.");
        return;
    end
    path=bench_export_current("LD6");
endfunction

function ld6_start()
    global LD6;
    // Darbo pradžia inicializuoja būseną (kaip ld1_start): cfg/student išlieka.
    if ~isfield(LD6, "step") then
        cfg = LD6.cfg; st = LD6.student;
        ld6_init_state();
        LD6.cfg = cfg; LD6.student = st;
    end
    needgui = %t;
    if isfield(LD6, "ui") then
        if isfield(LD6.ui, "headless") then
            if LD6.ui.headless then needgui = %f; end
        end
        if isfield(LD6.ui, "circuitFrame") then needgui = %f; end  // jau pastatyta
    end
    if needgui & ~isfield(LD6, "fig") then
        ld6_build_gui();
    end
    if ~isfield(LD6,"autosave_enabled") then LD6.autosave_enabled=needgui; end
    ld6_set_status("Pradėkite nuo grandinės su vienu šaltiniu E1.","info","Atsiskaitymo režimas. Jei reikia, atverkite Pagalba → Kaip sujungti.");
endfunction

function ld6_student_primary()
    global LD6;
    if LD6.demoMode then ld6_toggle_solution(); return; end
    ld6_save_answers();
    if LD6.step==6 & LD6.done(6) then
        ld6_export_report();
        return;
    end
    if ~LD6.done(LD6.step) then
        ld6_check_step(~LD6.assessment);
    end
    if LD6.done(LD6.step) & LD6.step<6 then
        ld6_next_step();
    end
    ld6_student_sync(); bench_autosave("LD6");
endfunction

function ld6_jump_step(n)
    global LD6;
    if ~ld6_valid_index(n,6) then return; end
    if n <= LD6.step | LD6.done(n) | LD6.skipped(n) then
        ld6_set_step(n);
    else
        ld6_set_status("Šio etapo dar nepasiekėte.","info","Dabartinį etapą patikrinkite ir spauskite TOLIAU.");
    end
endfunction

function ld6_student_sync()
    global LD6;
    if ~isfield(LD6, "ui") then return; end
    if isfield(LD6.ui, "headless") then if LD6.ui.headless then return; end end
    if isfield(LD6.ui, "studentPrimary") & is_handle_valid(LD6.ui.studentPrimary) then
        if LD6.demoMode then
            LD6.ui.studentPrimary.string="GRĮŽTI Į SAVO DARBĄ";
        elseif LD6.step == 6 & and(LD6.done) then
            LD6.ui.studentPrimary.string = "ĮRAŠYTI ATASKAITĄ";
        elseif LD6.step==6 & LD6.done(6) then
            LD6.ui.studentPrimary.string = "UŽBAIGTI PRALEISTĄ ETAPĄ";
        elseif LD6.done(LD6.step) then
            LD6.ui.studentPrimary.string = "TOLIAU →";
        elseif LD6.assessment then
            LD6.ui.studentPrimary.string = "TOLIAU →";
        else
            LD6.ui.studentPrimary.string = "TIKRINTI";
        end
    end
endfunction
