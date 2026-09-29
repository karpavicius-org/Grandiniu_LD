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
    bench_core_require();
    [ok, st, cfg] = student_enroll("LD11");
    if ~ok then return; end
    LD11 = struct("root", root, "cfg", cfg, "student", st);
    student_remember(st); ld11_start();
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
    if needgui & ~isfield(LD11, "fig") then
        ld11_build_gui();
    end
    if ~isfield(LD11,"autosave_enabled") then LD11.autosave_enabled=needgui; end
    ld11_set_status("Sveiki! Pradėkite nuo [E01]: sujunkite R–L rišlę be kompensavimo kondensatoriaus.", "info", "Seką rasite: Pagalba → [B04] Kaip sujungti.");
endfunction

function ld11_student_primary()
    global LD11;
    if LD11.demoMode then ld11_toggle_solution(); return; end
    ld11_save_answers();
    if LD11.step == 6 & and(LD11.done) then
        bench_export_current("LD11");
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
            LD11.ui.studentPrimary.string = "ĮRAŠYTI ATASKAITĄ";
        elseif LD11.step == 6 & LD11.done(6) then
            LD11.ui.studentPrimary.string = "UŽBAIGTI PRALEISTĄ ETAPĄ";
        elseif LD11.done(LD11.step) then
            LD11.ui.studentPrimary.string = "TOLIAU →";
        elseif LD11.assessment then
            LD11.ui.studentPrimary.string = "ĮRAŠYTI IR TOLIAU →";
        else
            LD11.ui.studentPrimary.string = "TIKRINTI";
        end
    end
endfunction
