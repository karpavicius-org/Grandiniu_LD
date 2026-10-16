// ============================================================================
// LD10 studento srautas: paleidimas, pagrindinis mygtukas, pagalba.
// ============================================================================

function ld10_student_main(root)
    global LD10;
    if typeof(LD10) == "st" then
        if isfield(LD10, "fig") then
            if is_handle_valid(LD10.fig) then show_window(LD10.fig); return; end
        end
    end
    try bench_core_require(); catch
        messagebox(["LD10 nepavyko paleisti.";strcat(lasterror()," "); ...
            "Išskleiskite visą paketą ir paleiskite STENDAS.sce grafinėje Scilab aplinkoje."], ...
            "LD10 paleidimas","error"); return;
    end
    [ok, st, cfg] = student_enroll("LD10");
    if ~ok then return; end
    LD10 = struct("root", root, "cfg", cfg, "student", st);
    student_remember(st); ld10_start(); bench_autosave("LD10");
endfunction

// Fixing a typo in the student's name/group must never invalidate measurements.
function ld10_student_details()
    global LD10;
    if LD10.demoMode then ld10_set_status("Pirma grįžkite į savo darbą.","info","");return;end
    choice=messagebox([student_caption(LD10.student);student_parameter_lines("LD10",LD10.cfg)], ...
        "Studentas ir priskirtos reikšmės","info",["Grįžti" "Keisti duomenis"],"modal");
    if choice<>2 then return;end
    [ok,st,cfg]=student_enroll("LD10",LD10.student);
    if ~ok then return;end
    if st.number<>LD10.student.number then
        choice=messagebox("Pakeitus eilės numerį, bus pradėtas naujas variantas. Dabartinį darbą programa prieš tai išsaugos.", ...
            "Keisti variantą?","question",["Atšaukti" "Pradėti naują"],"modal");
        if choice<>2 then return;end
    end
    ld10_apply_profile(st,cfg);
endfunction

function ld10_apply_profile(st,cfg)
    global LD10;
    ld10_save_answers();
    changed=st.number<>LD10.student.number;
    assessment=LD10.assessment; practice=LD10.practice_used;
    if changed then
        bench_autosave("LD10");
        if isfield(LD10,"autosave_error") then
            if LD10.autosave_error<>"" then return;end
        end
        ld10_init_state();
        LD10.cfg=cfg;LD10.student=st;
        LD10.assessment=assessment;LD10.practice_used=practice;
        LD10.autosave_paths=emptystr(0,1);LD10.autosave_error="";
    else
        LD10.cfg=cfg;LD10.student=st;
    end
    student_remember(st);
    if isfield(LD10,"ui") then
        if ~isfield(LD10.ui,"headless") | ~LD10.ui.headless then
            ld10_render_stage();
        end
    end
    bench_autosave("LD10");
endfunction

function path=ld10_export_report()
    global LD10;
    path=""; ld10_save_answers();
    if LD10.assessment & ~and(LD10.done) then
        ld10_set_status("Dar yra neužbaigtų etapų.","error","Užbaikite visus 6 etapus ir tada išsaugokite ataskaitą."); return;
    end
    path=bench_export_current("LD10");
endfunction

function ld10_start()
    global LD10;
    if ~isfield(LD10, "step") then
        cfg = LD10.cfg; st = LD10.student;
        ld10_init_state();
        LD10.cfg = cfg; LD10.student = st;
    end
    needgui = %t;
    if isfield(LD10, "ui") then
        if isfield(LD10.ui, "headless") then
            if LD10.ui.headless then needgui = %f; end
        end
        if isfield(LD10.ui, "circuitFrame") then needgui = %f; end
    end
    if ~isfield(LD10,"autosave_enabled") then LD10.autosave_enabled=needgui; end
    if needgui & ~isfield(LD10, "fig") then
        ld10_build_gui();
    end
    ld10_set_status("Pradėkite nuo lygiagrečios RLC grandinės sujungimo.","info","Seka: Pagalba → Kaip sujungti. Formulės: Pagalba → Teorija ir paaiškinimai.");
endfunction

function ld10_student_primary()
    global LD10;
    if LD10.demoMode then ld10_toggle_solution(); return; end
    ld10_save_answers();
    if LD10.step == 6 & and(LD10.done) then
        ld10_export_report();
        return;
    end
    // Vienas paspaudimas: patikrinti ir, pavykus, iškart pereiti (LD2 semantika).
    if ~LD10.done(LD10.step) then
        ld10_check_step(~LD10.assessment);
    end
    if LD10.done(LD10.step) & LD10.step < 6 then
        ld10_next_step();
    elseif LD10.step == 6 & LD10.done(6) & ~and(LD10.done) then
        pending = find(~LD10.done); ld10_set_step(pending(1));
    end
    ld10_student_sync(); bench_autosave("LD10");
endfunction

function ld10_jump_step(n)
    global LD10;
    if ~ld10_valid_index(n, 6) then return; end
    if n <= LD10.step | LD10.done(n) | LD10.skipped(n) then
        ld10_set_step(n);
    else
        ld10_set_status("Šio etapo dar nepasiekėte.", "info", "Dabartinį etapą patikrinkite ir spauskite TOLIAU.");
    end
endfunction

function ld10_student_sync()
    global LD10;
    if ~isfield(LD10, "ui") then return; end
    if isfield(LD10.ui, "headless") then if LD10.ui.headless then return; end end
    if isfield(LD10.ui, "studentPrimary") & is_handle_valid(LD10.ui.studentPrimary) then
        if LD10.demoMode then
            LD10.ui.studentPrimary.string = "GRĮŽTI Į SAVO DARBĄ";
        elseif LD10.step == 6 & and(LD10.done) then
            LD10.ui.studentPrimary.string = "IŠSAUGOTI ATASKAITĄ";
        elseif LD10.step == 6 & LD10.done(6) then
            LD10.ui.studentPrimary.string = "UŽBAIGTI PRALEISTĄ ETAPĄ";
        elseif LD10.done(LD10.step) then
            LD10.ui.studentPrimary.string = "TOLIAU →";
        elseif LD10.assessment then
            LD10.ui.studentPrimary.string = "TOLIAU →";
        else
            LD10.ui.studentPrimary.string = "TIKRINTI";
        end
    end
endfunction
