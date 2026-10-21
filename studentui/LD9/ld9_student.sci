// ============================================================================
// LD9 studento srautas: paleidimas, pagrindinis mygtukas, pagalba.
// ============================================================================

function ld9_student_main(root)
    global LD9;
    if typeof(LD9) == "st" then
        if isfield(LD9, "fig") then
            if is_handle_valid(LD9.fig) then show_window(LD9.fig); return; end
        end
    end
    try bench_core_require(); catch
        messagebox(["LD9 nepavyko paleisti.";strcat(lasterror()," "); ...
            "Išskleiskite visą paketą ir paleiskite STENDAS.sce grafinėje Scilab aplinkoje."], ...
            "LD9 paleidimas","error"); return;
    end
    [ok, st, cfg] = student_enroll("LD9");
    if ~ok then return; end
    LD9 = struct("root", root, "cfg", cfg, "student", st);
    student_remember(st); ld9_start(); bench_autosave("LD9");
endfunction

// Fixing a typo in the student's name/group must never invalidate measurements.
function ld9_student_details()
    global LD9;
    if LD9.demoMode then ld9_set_status("Pirma grįžkite į savo darbą.","info","");return;end
    choice=messagebox([student_caption(LD9.student);student_parameter_lines("LD9",LD9.cfg)], ...
        "Studentas ir priskirtos reikšmės","info",["Grįžti" "Keisti duomenis"],"modal");
    if choice<>2 then return;end
    [ok,st,cfg]=student_enroll("LD9",LD9.student);
    if ~ok then return;end
    if st.number<>LD9.student.number then
        choice=messagebox("Pakeitus eilės numerį, bus pradėtas naujas variantas. Dabartinį darbą programa prieš tai išsaugos.", ...
            "Keisti variantą?","question",["Atšaukti" "Pradėti naują"],"modal");
        if choice<>2 then return;end
    end
    ld9_apply_profile(st,cfg);
endfunction

function ld9_apply_profile(st,cfg)
    global LD9;
    ld9_save_answers();
    changed=st.number<>LD9.student.number;
    assessment=LD9.assessment; practice=LD9.practice_used;
    if changed then
        bench_autosave("LD9");
        if isfield(LD9,"autosave_error") then
            if LD9.autosave_error<>"" then return;end
        end
        ld9_init_state();
        LD9.cfg=cfg;LD9.student=st;
        LD9.assessment=assessment;LD9.practice_used=practice;
        LD9.autosave_paths=emptystr(0,1);LD9.autosave_error="";
    else
        LD9.cfg=cfg;LD9.student=st;
    end
    student_remember(st);
    if isfield(LD9,"ui") then
        if ~isfield(LD9.ui,"headless") | ~LD9.ui.headless then
            ld9_render_stage();
        end
    end
    bench_autosave("LD9");
endfunction

function path=ld9_export_report()
    global LD9;
    path=""; ld9_save_answers();
    if LD9.assessment & ~and(LD9.done) then
        ld9_set_status("Dar yra neužbaigtų etapų.","error","Užbaikite visus 6 etapus ir tada išsaugokite ataskaitą."); return;
    end
    path=bench_export_current("LD9");
endfunction

function ld9_start()
    global LD9;
    if ~isfield(LD9, "step") then
        cfg = LD9.cfg; st = LD9.student;
        ld9_init_state();
        LD9.cfg = cfg; LD9.student = st;
    end
    needgui = %t;
    if isfield(LD9, "ui") then
        if isfield(LD9.ui, "headless") then
            if LD9.ui.headless then needgui = %f; end
        end
        if isfield(LD9.ui, "circuitFrame") then needgui = %f; end
    end
    if ~isfield(LD9,"autosave_enabled") then LD9.autosave_enabled=needgui; end
    if needgui & ~isfield(LD9, "fig") then
        ld9_build_gui();
    end
    ld9_set_status("Pradėkite nuo nuoseklios RLC grandinės sujungimo.","info","Seka: Pagalba → Kaip sujungti. Formulės: Pagalba → Teorija ir paaiškinimai.");
endfunction

function ld9_student_primary()
    global LD9;
    if LD9.demoMode then ld9_toggle_solution(); return; end
    ld9_save_answers();
    if LD9.step == 6 & and(LD9.done) then
        ld9_export_report();
        return;
    end
    // Vienas paspaudimas: patikrinti ir, pavykus, iškart pereiti (LD2 semantika).
    if ~LD9.done(LD9.step) then
        ld9_check_step(~LD9.assessment);
    end
    if LD9.done(LD9.step) & LD9.step < 6 then
        ld9_next_step();
    elseif LD9.step == 6 & LD9.done(6) & ~and(LD9.done) then
        pending = find(~LD9.done); ld9_set_step(pending(1));
    end
    ld9_student_sync(); bench_autosave("LD9");
endfunction

function ld9_jump_step(n)
    global LD9;
    if ~ld9_valid_index(n, 6) then return; end
    if n <= LD9.step | LD9.done(n) | LD9.skipped(n) then
        ld9_set_step(n);
    else
        ld9_set_status("Šio etapo dar nepasiekėte.", "info", "Dabartinį etapą patikrinkite ir spauskite TOLIAU.");
    end
endfunction

function ld9_student_sync()
    global LD9;
    if ~isfield(LD9, "ui") then return; end
    if isfield(LD9.ui, "headless") then if LD9.ui.headless then return; end end
    if isfield(LD9.ui, "studentPrimary") & is_handle_valid(LD9.ui.studentPrimary) then
        if LD9.demoMode then
            LD9.ui.studentPrimary.string = "GRĮŽTI Į SAVO DARBĄ";
        elseif LD9.step == 6 & and(LD9.done) then
            LD9.ui.studentPrimary.string = "IŠSAUGOTI ATASKAITĄ";
        elseif LD9.step == 6 & LD9.done(6) then
            LD9.ui.studentPrimary.string = "UŽBAIGTI PRALEISTĄ ETAPĄ";
        elseif LD9.done(LD9.step) then
            LD9.ui.studentPrimary.string = "TOLIAU →";
        elseif LD9.assessment then
            LD9.ui.studentPrimary.string = "TOLIAU →";
        else
            LD9.ui.studentPrimary.string = "TIKRINTI";
        end
    end
    ld9_guide_refresh();
endfunction
