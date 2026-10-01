// ============================================================================
// LD7 studento srautas: paleidimas, pagrindinis mygtukas, pagalba.
// ============================================================================

function ld7_student_main(root)
    global LD7;
    if typeof(LD7) == "st" then
        if isfield(LD7, "fig") then
            if is_handle_valid(LD7.fig) then show_window(LD7.fig); return; end
        end
    end
    bench_core_require();
    [ok, st, cfg] = student_enroll("LD7");
    if ~ok then return; end
    LD7 = struct("root", root, "cfg", cfg, "student", st);
    student_remember(st); ld7_start();
endfunction

function ld7_start()
    global LD7;
    // Darbo pradžia inicializuoja būseną (kaip ld6_start): cfg/student išlieka.
    if ~isfield(LD7, "step") then
        cfg = LD7.cfg; st = LD7.student;
        ld7_init_state();
        LD7.cfg = cfg; LD7.student = st;
    end
    needgui = %t;
    if isfield(LD7, "ui") then
        if isfield(LD7.ui, "headless") then
            if LD7.ui.headless then needgui = %f; end
        end
        if isfield(LD7.ui, "circuitFrame") then needgui = %f; end  // jau pastatyta
    end
    if needgui & ~isfield(LD7, "fig") then
        ld7_build_gui();
    end
    if ~isfield(LD7,"autosave_enabled") then LD7.autosave_enabled=needgui; end
    ld7_set_status("Sveiki! Pradėkite nuo [E01]: sujunkite matavimo grandinę.", "info", "Atsiskaitymo režimas. Seką rasite: Pagalba → [B04] Kaip sujungti.");
endfunction

function ld7_student_primary()
    global LD7;
    if LD7.demoMode then ld7_toggle_solution(); return; end
    ld7_save_answers();
    if LD7.step == 6 & and(LD7.done) then
        bench_export_current("LD7");
        return;
    end
    // Vienas paspaudimas: patikrinti ir, pavykus, iškart pereiti (LD2 semantika).
    if ~LD7.done(LD7.step) then
        ld7_check_step(~LD7.assessment);
    end
    if LD7.done(LD7.step) & LD7.step < 6 then
        ld7_next_step();
    elseif LD7.step == 6 & LD7.done(6) & ~and(LD7.done) then
        pending = find(~LD7.done); ld7_set_step(pending(1));
    end
    ld7_student_sync(); bench_autosave("LD7");
endfunction

function ld7_jump_step(n)
    global LD7;
    if ~ld7_valid_index(n, 6) then return; end
    if n <= LD7.step | LD7.done(n) | LD7.skipped(n) then
        ld7_set_step(n);
    else
        ld7_set_status("Šio etapo dar nepasiekėte.", "info", "Dabartinį etapą patikrinkite ir spauskite TOLIAU.");
    end
endfunction

function ld7_student_sync()
    global LD7;
    if ~isfield(LD7, "ui") then return; end
    if isfield(LD7.ui, "headless") then if LD7.ui.headless then return; end end
    if isfield(LD7.ui, "studentPrimary") & is_handle_valid(LD7.ui.studentPrimary) then
        if LD7.demoMode then
            LD7.ui.studentPrimary.string = "GRĮŽTI Į SAVO DARBĄ";
        elseif LD7.step == 6 & and(LD7.done) then
            LD7.ui.studentPrimary.string = "ĮRAŠYTI ATASKAITĄ";
        elseif LD7.step == 6 & LD7.done(6) then
            LD7.ui.studentPrimary.string = "UŽBAIGTI PRALEISTĄ ETAPĄ";
        elseif LD7.done(LD7.step) then
            LD7.ui.studentPrimary.string = "TOLIAU →";
        elseif LD7.assessment then
            LD7.ui.studentPrimary.string = "ĮRAŠYTI IR TOLIAU →";
        else
            LD7.ui.studentPrimary.string = "TIKRINTI";
        end
    end
endfunction
