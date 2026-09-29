// ============================================================================
// LD5 studento srautas: paleidimas, pagrindinis mygtukas, pagalba.
// ============================================================================

function ld5_student_main(root)
    global LD5;
    if typeof(LD5)=="st" then
        if isfield(LD5,"fig") then
            if is_handle_valid(LD5.fig) then show_window(LD5.fig); return; end
        end
    end
    bench_core_require();
    [ok,st,cfg]=student_enroll("LD5");
    if ~ok then return; end
    LD5=struct("root",root,"cfg",cfg,"student",st);
    student_remember(st); ld5_start();
endfunction

function ld5_start()
    global LD5;
    // Darbo pradžia inicializuoja būseną (kaip ld1_start): cfg/student išlieka.
    if ~isfield(LD5, "step") then
        cfg = LD5.cfg; st = LD5.student;
        ld5_init_state();
        LD5.cfg = cfg; LD5.student = st;
    end
    needgui = %t;
    if isfield(LD5, "ui") then
        if isfield(LD5.ui, "headless") then
            if LD5.ui.headless then needgui = %f; end
        end
        if isfield(LD5.ui, "circuitFrame") then needgui = %f; end  // jau pastatyta
    end
    if needgui & ~isfield(LD5, "fig") then
        ld5_build_gui();
    end
    if ~isfield(LD5,"autosave_enabled") then LD5.autosave_enabled=needgui; end
    ld5_set_status("Sveiki! Pradėkite nuo [E01]: sujunkite matavimo grandinę.","info","Atsiskaitymo režimas. Seką rasite: Pagalba → [B04] Kaip sujungti.");
endfunction

function ld5_student_primary()
    global LD5;
    if LD5.demoMode then ld5_toggle_solution(); return; end
    ld5_save_answers();
    if LD5.step == 6 & and(LD5.done) then
        bench_export_current("LD5");
        return;
    end
    // Vienas paspaudimas: patikrinti ir, pavykus, iškart pereiti (LD2 semantika).
    if ~LD5.done(LD5.step) then
        ld5_check_step(~LD5.assessment);
    end
    if LD5.done(LD5.step) & LD5.step < 6 then
        ld5_next_step();
    end
    ld5_student_sync(); bench_autosave("LD5");
endfunction

function ld5_jump_step(n)
    global LD5;
    if ~ld5_valid_index(n,6) then return; end
    if n <= LD5.step | LD5.done(n) | LD5.skipped(n) then
        ld5_set_step(n);
    else
        ld5_set_status("Šio etapo dar nepasiekėte.","info","Dabartinį etapą patikrinkite ir spauskite TOLIAU.");
    end
endfunction

function ld5_student_sync()
    global LD5;
    if ~isfield(LD5, "ui") then return; end
    if isfield(LD5.ui, "headless") then if LD5.ui.headless then return; end end
    if isfield(LD5.ui, "studentPrimary") & is_handle_valid(LD5.ui.studentPrimary) then
        if LD5.demoMode then
            LD5.ui.studentPrimary.string="GRĮŽTI Į SAVO DARBĄ";
        elseif LD5.step == 6 & and(LD5.done) then
            LD5.ui.studentPrimary.string = "ĮRAŠYTI ATASKAITĄ";
        elseif LD5.done(LD5.step) then
            LD5.ui.studentPrimary.string = "TOLIAU →";
        elseif LD5.assessment then
            LD5.ui.studentPrimary.string = "ĮRAŠYTI IR TOLIAU →";
        else
            LD5.ui.studentPrimary.string = "TIKRINTI";
        end
    end
endfunction
