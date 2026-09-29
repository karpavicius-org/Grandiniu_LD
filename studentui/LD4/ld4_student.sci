// ============================================================================
// LD4 studento srautas: paleidimas, pagrindinis mygtukas, pagalba.
// ============================================================================

function ld4_student_main(root)
    global LD4;
    if typeof(LD4)=="st" then
        if isfield(LD4,"fig") then
            if is_handle_valid(LD4.fig) then show_window(LD4.fig); return; end
        end
    end
    bench_core_require();
    [ok,st,cfg]=student_enroll("LD4");
    if ~ok then return; end
    LD4=struct("root",root,"cfg",cfg,"student",st);
    student_remember(st); ld4_start();
endfunction

function ld4_start()
    global LD4;
    // Darbo pradžia inicializuoja būseną (kaip ld1_start): cfg/student išlieka.
    if ~isfield(LD4, "step") then
        cfg = LD4.cfg; st = LD4.student;
        ld4_init_state();
        LD4.cfg = cfg; LD4.student = st;
    end
    needgui = %t;
    if isfield(LD4, "ui") then
        if isfield(LD4.ui, "headless") then
            if LD4.ui.headless then needgui = %f; end
        end
        if isfield(LD4.ui, "standFrame") then needgui = %f; end  // jau pastatyta
    end
    if needgui & ~isfield(LD4, "fig") then
        ld4_build_gui();
    end
    if ~isfield(LD4,"autosave_enabled") then LD4.autosave_enabled=needgui; end
    ld4_set_status("Sveiki! Pradėkite nuo [E01]: sujunkite matavimo grandinę.","info","Atsiskaitymo režimas. Seką rasite: Pagalba → [B04] Kaip sujungti.");
endfunction

function ld4_student_primary()
    global LD4;
    if LD4.demoMode then ld4_toggle_solution(); return; end
    ld4_save_answers();
    if LD4.step == 7 & LD4.done(7) then
        bench_export_current("LD4");
        return;
    end
    // Vienas paspaudimas: patikrinti ir, pavykus, iškart pereiti (LD2 semantika).
    if ~LD4.done(LD4.step) then
        ld4_check_step(~LD4.assessment);
    end
    if LD4.done(LD4.step) & LD4.step < 7 then
        ld4_next_step();
    end
    ld4_student_sync(); bench_autosave("LD4");
endfunction

function ld4_jump_step(n)
    global LD4;
    if n<1 | n>7 then return; end
    if n <= LD4.step | LD4.done(n) | LD4.skipped(n) then
        ld4_set_step(n);
    else
        ld4_set_status("Šio etapo dar nepasiekėte.","info","Dabartinį etapą patikrinkite ir spauskite TOLIAU.");
    end
endfunction

function ld4_student_sync()
    global LD4;
    if ~isfield(LD4, "ui") then return; end
    if isfield(LD4.ui, "headless") then if LD4.ui.headless then return; end end
    if isfield(LD4.ui, "studentPrimary") & is_handle_valid(LD4.ui.studentPrimary) then
        if LD4.step == 7 & LD4.done(7) then
            LD4.ui.studentPrimary.string = "ĮRAŠYTI ATASKAITĄ";
        elseif LD4.done(LD4.step) then
            LD4.ui.studentPrimary.string = "TOLIAU →";
        elseif LD4.assessment then
            LD4.ui.studentPrimary.string = "ĮRAŠYTI IR TOLIAU →";
        else
            LD4.ui.studentPrimary.string = "TIKRINTI";
        end
    end
endfunction
