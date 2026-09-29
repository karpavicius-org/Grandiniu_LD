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
    bench_core_require();
    [ok, st, cfg] = student_enroll("LD12");
    if ~ok then return; end
    LD12 = struct("root", root, "cfg", cfg, "student", st);
    student_remember(st); ld12_start();
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
    if needgui & ~isfield(LD12, "fig") then
        ld12_build_gui();
    end
    ld12_set_status("Sveiki! Pradėkite nuo [E01]: sujunkite trifazį imtuvą žvaigžde.", "info", "Seką rasite: Pagalba → [B04] Kaip sujungti.");
endfunction

function ld12_student_primary()
    global LD12;
    if LD12.demoMode then ld12_toggle_solution(); return; end
    ld12_save_answers();
    if LD12.step == 6 & and(LD12.done) then
        bench_export_current("LD12");
        return;
    end
    // Vienas paspaudimas: patikrinti ir, pavykus, iškart pereiti (LD2 semantika).
    if ~LD12.done(LD12.step) then
        ld12_check_step();
    end
    if LD12.done(LD12.step) & LD12.step < 6 then
        ld12_next_step();
    elseif LD12.step == 6 & LD12.done(6) & ~and(LD12.done) then
        pending = find(~LD12.done); ld12_set_step(pending(1));
    end
    ld12_student_sync();
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
            LD12.ui.studentPrimary.string = "ĮRAŠYTI ATASKAITĄ";
        elseif LD12.step == 6 & LD12.done(6) then
            LD12.ui.studentPrimary.string = "UŽBAIGTI PRALEISTĄ ETAPĄ";
        elseif LD12.done(LD12.step) then
            LD12.ui.studentPrimary.string = "TOLIAU →";
        else
            LD12.ui.studentPrimary.string = "TIKRINTI";
        end
    end
endfunction
