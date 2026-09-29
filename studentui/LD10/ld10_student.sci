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
    bench_core_require();
    [ok, st, cfg] = student_enroll("LD10");
    if ~ok then return; end
    LD10 = struct("root", root, "cfg", cfg, "student", st);
    student_remember(st); ld10_start();
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
    if needgui & ~isfield(LD10, "fig") then
        ld10_build_gui();
    end
    ld10_set_status("Sveiki! Pradėkite nuo [E01]: sujunkite lygiagrečią RLC grandinę.", "info", "Seką rasite: Pagalba → [B04] Kaip sujungti.");
endfunction

function ld10_student_primary()
    global LD10;
    if LD10.demoMode then ld10_toggle_solution(); return; end
    ld10_save_answers();
    if LD10.step == 6 & and(LD10.done) then
        bench_export_current("LD10");
        return;
    end
    // Vienas paspaudimas: patikrinti ir, pavykus, iškart pereiti (LD2 semantika).
    if ~LD10.done(LD10.step) then
        ld10_check_step();
    end
    if LD10.done(LD10.step) & LD10.step < 6 then
        ld10_next_step();
    elseif LD10.step == 6 & LD10.done(6) & ~and(LD10.done) then
        pending = find(~LD10.done); ld10_set_step(pending(1));
    end
    ld10_student_sync();
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
            LD10.ui.studentPrimary.string = "ĮRAŠYTI ATASKAITĄ";
        elseif LD10.step == 6 & LD10.done(6) then
            LD10.ui.studentPrimary.string = "UŽBAIGTI PRALEISTĄ ETAPĄ";
        elseif LD10.done(LD10.step) then
            LD10.ui.studentPrimary.string = "TOLIAU →";
        else
            LD10.ui.studentPrimary.string = "TIKRINTI";
        end
    end
endfunction
