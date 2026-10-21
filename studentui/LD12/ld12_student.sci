// ============================================================================
// LD12 studento srautas: paleidimas, pagrindinis mygtukas, pagalba.
// ============================================================================

function ld12_student_main(root)
    global LD12;
    if typeof(LD12) == "st" then
        if isfield(LD12, "fig") then
            if is_handle_valid(LD12.fig) then show_window(LD12.fig); return; end
        end
    end
    try bench_core_require(); catch
        messagebox(["LD12 nepavyko paleisti.";strcat(lasterror()," "); ...
            "Išskleiskite visą paketą ir paleiskite STENDAS.sce grafinėje Scilab aplinkoje."], ...
            "LD12 paleidimas","error"); return;
    end
    [ok, st, cfg] = student_enroll("LD12");
    if ~ok then return; end
    LD12 = struct("root", root, "cfg", cfg, "student", st);
    student_remember(st); ld12_start(); bench_autosave("LD12");
endfunction

// Fixing a typo in the student's name/group must never invalidate measurements.
function ld12_student_details()
    global LD12;
    if LD12.demoMode then ld12_set_status("Pirma grįžkite į savo darbą.","info","");return;end
    choice=messagebox([student_caption(LD12.student);student_parameter_lines("LD12",LD12.cfg)], ...
        "Studentas ir priskirtos reikšmės","info",["Grįžti" "Keisti duomenis"],"modal");
    if choice<>2 then return;end
    [ok,st,cfg]=student_enroll("LD12",LD12.student);
    if ~ok then return;end
    if st.number<>LD12.student.number then
        choice=messagebox("Pakeitus eilės numerį, bus pradėtas naujas variantas. Dabartinį darbą programa prieš tai išsaugos.", ...
            "Keisti variantą?","question",["Atšaukti" "Pradėti naują"],"modal");
        if choice<>2 then return;end
    end
    ld12_apply_profile(st,cfg);
endfunction

function ld12_apply_profile(st,cfg)
    global LD12;
    ld12_save_answers();
    changed=st.number<>LD12.student.number;
    assessment=LD12.assessment; practice=LD12.practice_used;
    if changed then
        bench_autosave("LD12");
        if isfield(LD12,"autosave_error") then
            if LD12.autosave_error<>"" then return;end
        end
        ld12_init_state();
        LD12.cfg=cfg;LD12.student=st;
        LD12.assessment=assessment;LD12.practice_used=practice;
        LD12.autosave_paths=emptystr(0,1);LD12.autosave_error="";
    else
        LD12.cfg=cfg;LD12.student=st;
    end
    student_remember(st);
    if isfield(LD12,"ui") then
        if ~isfield(LD12.ui,"headless") | ~LD12.ui.headless then
            ld12_render_stage();
        end
    end
    bench_autosave("LD12");
endfunction

function path=ld12_export_report()
    global LD12;
    path=""; ld12_save_answers();
    if LD12.assessment & ~and(LD12.done) then
        ld12_set_status("Dar yra neužbaigtų etapų.","error","Užbaikite visus 6 etapus ir tada išsaugokite ataskaitą."); return;
    end
    path=bench_export_current("LD12");
endfunction

function ld12_start()
    global LD12;
    if ~isfield(LD12, "step") then
        cfg = LD12.cfg; st = LD12.student;
        ld12_init_state();
        LD12.cfg = cfg; LD12.student = st;
    end
    needgui = %t;
    if isfield(LD12, "ui") then
        if isfield(LD12.ui, "headless") then
            if LD12.ui.headless then needgui = %f; end
        end
        if isfield(LD12.ui, "circuitFrame") then needgui = %f; end
    end
    if ~isfield(LD12,"autosave_enabled") then LD12.autosave_enabled=needgui; end
    if needgui & ~isfield(LD12, "fig") then
        ld12_build_gui();
    end
    ld12_set_status("Pradėkite nuo trijų imtuvų sujungimo žvaigžde.","info","Seka: Pagalba → Kaip sujungti. Formulės: Pagalba → Teorija ir paaiškinimai.");
endfunction

function ld12_student_primary()
    global LD12;
    if LD12.demoMode then ld12_toggle_solution(); return; end
    ld12_save_answers();
    if LD12.step == 6 & and(LD12.done) then
        ld12_export_report();
        return;
    end
    // Vienas paspaudimas: patikrinti ir, pavykus, iškart pereiti (LD2 semantika).
    if ~LD12.done(LD12.step) then
        ld12_check_step(~LD12.assessment);
    end
    if LD12.done(LD12.step) & LD12.step < 6 then
        ld12_next_step();
    elseif LD12.step == 6 & LD12.done(6) & ~and(LD12.done) then
        pending = find(~LD12.done); ld12_set_step(pending(1));
    end
    ld12_student_sync(); bench_autosave("LD12");
endfunction

function ld12_jump_step(n)
    global LD12;
    if ~ld12_valid_index(n, 6) then return; end
    if n <= LD12.step | LD12.done(n) | LD12.skipped(n) then
        ld12_set_step(n);
    else
        ld12_set_status("Šio etapo dar nepasiekėte.", "info", "Dabartinį etapą patikrinkite ir spauskite TOLIAU.");
    end
endfunction

function ld12_student_sync()
    global LD12;
    if ~isfield(LD12, "ui") then return; end
    if isfield(LD12.ui, "headless") then if LD12.ui.headless then return; end end
    if isfield(LD12.ui, "studentPrimary") & is_handle_valid(LD12.ui.studentPrimary) then
        if LD12.demoMode then
            LD12.ui.studentPrimary.string = "GRĮŽTI Į SAVO DARBĄ";
        elseif LD12.step == 6 & and(LD12.done) then
            LD12.ui.studentPrimary.string = "IŠSAUGOTI ATASKAITĄ";
        elseif LD12.step == 6 & LD12.done(6) then
            LD12.ui.studentPrimary.string = "UŽBAIGTI PRALEISTĄ ETAPĄ";
        elseif LD12.done(LD12.step) then
            LD12.ui.studentPrimary.string = "TOLIAU →";
        elseif LD12.assessment then
            LD12.ui.studentPrimary.string = "TOLIAU →";
        else
            LD12.ui.studentPrimary.string = "TIKRINTI";
        end
    end
    ld12_guide_refresh();
endfunction
