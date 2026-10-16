// ============================================================================
// LD11 studento srautas: paleidimas, pagrindinis mygtukas, pagalba.
// ============================================================================

function ld11_student_main(root)
    global LD11;
    if typeof(LD11) == "st" then
        if isfield(LD11, "fig") then
            if is_handle_valid(LD11.fig) then show_window(LD11.fig); return; end
        end
    end
    try bench_core_require(); catch
        messagebox(["LD11 nepavyko paleisti.";strcat(lasterror()," "); ...
            "Išskleiskite visą paketą ir paleiskite STENDAS.sce grafinėje Scilab aplinkoje."], ...
            "LD11 paleidimas","error"); return;
    end
    [ok, st, cfg] = student_enroll("LD11");
    if ~ok then return; end
    LD11 = struct("root", root, "cfg", cfg, "student", st);
    student_remember(st); ld11_start(); bench_autosave("LD11");
endfunction

// Fixing a typo in the student's name/group must never invalidate measurements.
function ld11_student_details()
    global LD11;
    if LD11.demoMode then ld11_set_status("Pirma grįžkite į savo darbą.","info","");return;end
    choice=messagebox([student_caption(LD11.student);student_parameter_lines("LD11",LD11.cfg)], ...
        "Studentas ir priskirtos reikšmės","info",["Grįžti" "Keisti duomenis"],"modal");
    if choice<>2 then return;end
    [ok,st,cfg]=student_enroll("LD11",LD11.student);
    if ~ok then return;end
    if st.number<>LD11.student.number then
        choice=messagebox("Pakeitus eilės numerį, bus pradėtas naujas variantas. Dabartinį darbą programa prieš tai išsaugos.", ...
            "Keisti variantą?","question",["Atšaukti" "Pradėti naują"],"modal");
        if choice<>2 then return;end
    end
    ld11_apply_profile(st,cfg);
endfunction

function ld11_apply_profile(st,cfg)
    global LD11;
    ld11_save_answers();
    changed=st.number<>LD11.student.number;
    assessment=LD11.assessment; practice=LD11.practice_used;
    if changed then
        bench_autosave("LD11");
        if isfield(LD11,"autosave_error") then
            if LD11.autosave_error<>"" then return;end
        end
        ld11_init_state();
        LD11.cfg=cfg;LD11.student=st;
        LD11.assessment=assessment;LD11.practice_used=practice;
        LD11.autosave_paths=emptystr(0,1);LD11.autosave_error="";
    else
        LD11.cfg=cfg;LD11.student=st;
    end
    student_remember(st);
    if isfield(LD11,"ui") then
        if ~isfield(LD11.ui,"headless") | ~LD11.ui.headless then
            ld11_render_stage();
        end
    end
    bench_autosave("LD11");
endfunction

function path=ld11_export_report()
    global LD11;
    path=""; ld11_save_answers();
    if LD11.assessment & ~and(LD11.done) then
        ld11_set_status("Dar yra neužbaigtų etapų.","error","Užbaikite visus 6 etapus ir tada išsaugokite ataskaitą."); return;
    end
    path=bench_export_current("LD11");
endfunction

function ld11_start()
    global LD11;
    if ~isfield(LD11, "step") then
        cfg = LD11.cfg; st = LD11.student;
        ld11_init_state();
        LD11.cfg = cfg; LD11.student = st;
    end
    needgui = %t;
    if isfield(LD11, "ui") then
        if isfield(LD11.ui, "headless") then
            if LD11.ui.headless then needgui = %f; end
        end
        if isfield(LD11.ui, "circuitFrame") then needgui = %f; end
    end
    if ~isfield(LD11,"autosave_enabled") then LD11.autosave_enabled=needgui; end
    if needgui & ~isfield(LD11, "fig") then
        ld11_build_gui();
    end
    ld11_set_status("Pradėkite nuo ritės (R, L) sujungimo be kondensatoriaus.","info","Seka: Pagalba → Kaip sujungti. Formulės: Pagalba → Teorija ir paaiškinimai.");
endfunction

function ld11_student_primary()
    global LD11;
    if LD11.demoMode then ld11_toggle_solution(); return; end
    ld11_save_answers();
    if LD11.step == 6 & and(LD11.done) then
        ld11_export_report();
        return;
    end
    // Vienas paspaudimas: patikrinti ir, pavykus, iškart pereiti (LD2 semantika).
    if ~LD11.done(LD11.step) then
        ld11_check_step(~LD11.assessment);
    end
    if LD11.done(LD11.step) & LD11.step < 6 then
        ld11_next_step();
    elseif LD11.step == 6 & LD11.done(6) & ~and(LD11.done) then
        pending = find(~LD11.done); ld11_set_step(pending(1));
    end
    ld11_student_sync(); bench_autosave("LD11");
endfunction

function ld11_jump_step(n)
    global LD11;
    if ~ld11_valid_index(n, 6) then return; end
    if n <= LD11.step | LD11.done(n) | LD11.skipped(n) then
        ld11_set_step(n);
    else
        ld11_set_status("Šio etapo dar nepasiekėte.", "info", "Dabartinį etapą patikrinkite ir spauskite TOLIAU.");
    end
endfunction

function ld11_student_sync()
    global LD11;
    if ~isfield(LD11, "ui") then return; end
    if isfield(LD11.ui, "headless") then if LD11.ui.headless then return; end end
    if isfield(LD11.ui, "studentPrimary") & is_handle_valid(LD11.ui.studentPrimary) then
        if LD11.demoMode then
            LD11.ui.studentPrimary.string = "GRĮŽTI Į SAVO DARBĄ";
        elseif LD11.step == 6 & and(LD11.done) then
            LD11.ui.studentPrimary.string = "IŠSAUGOTI ATASKAITĄ";
        elseif LD11.step == 6 & LD11.done(6) then
            LD11.ui.studentPrimary.string = "UŽBAIGTI PRALEISTĄ ETAPĄ";
        elseif LD11.done(LD11.step) then
            LD11.ui.studentPrimary.string = "TOLIAU →";
        elseif LD11.assessment then
            LD11.ui.studentPrimary.string = "TOLIAU →";
        else
            LD11.ui.studentPrimary.string = "TIKRINTI";
        end
    end
endfunction
