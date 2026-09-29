// ============================================================================
// LD6 studento srautas: paleidimas, pagrindinis mygtukas, pagalba.
// ============================================================================

function ld6_student_main(root)
    global LD6;
    if typeof(LD6)=="st" then
        if isfield(LD6,"fig") then
            if is_handle_valid(LD6.fig) then show_window(LD6.fig); return; end
        end
    end
    bench_core_require();
    [ok,st,cfg]=student_enroll("LD6");
    if ~ok then return; end
    LD6=struct("root",root,"cfg",cfg,"student",st);
    student_remember(st); ld6_start();
endfunction

function ld6_start()
    global LD6;
    // Darbo pradžia inicializuoja būseną (kaip ld1_start): cfg/student išlieka.
    if ~isfield(LD6, "step") then
        cfg = LD6.cfg; st = LD6.student;
        ld6_init_state();
        LD6.cfg = cfg; LD6.student = st;
    end
    needgui = %t;
    if isfield(LD6, "ui") then
        if isfield(LD6.ui, "headless") then
            if LD6.ui.headless then needgui = %f; end
        end
        if isfield(LD6.ui, "circuitFrame") then needgui = %f; end  // jau pastatyta
    end
    if needgui & ~isfield(LD6, "fig") then
        ld6_build_gui();
    end
    if ~isfield(LD6,"autosave_enabled") then LD6.autosave_enabled=needgui; end
    ld6_set_status("Sveiki! Pradėkite nuo [E01]: sujunkite matavimo grandinę.","info","Atsiskaitymo režimas. Seką rasite: Pagalba → [B04] Kaip sujungti.");
endfunction

function ld6_student_primary()
    global LD6;
    if LD6.demoMode then ld6_toggle_solution(); return; end
    ld6_save_answers();
    if LD6.step == 6 & and(LD6.done) then
        bench_export_current("LD6");
        return;
    end
    // Vienas paspaudimas: patikrinti ir, pavykus, iškart pereiti (LD2 semantika).
    if ~LD6.done(LD6.step) then
        ld6_check_step(~LD6.assessment);
    end
    if LD6.done(LD6.step) & LD6.step < 6 then
        ld6_next_step();
    elseif LD6.step==6 & LD6.done(6) & ~and(LD6.done) then
        pending=find(~LD6.done); ld6_set_step(pending(1));
    end
    ld6_student_sync(); bench_autosave("LD6");
endfunction

function ld6_jump_step(n)
    global LD6;
    if ~ld6_valid_index(n,6) then return; end
    if n <= LD6.step | LD6.done(n) | LD6.skipped(n) then
        ld6_set_step(n);
    else
        ld6_set_status("Šio etapo dar nepasiekėte.","info","Dabartinį etapą patikrinkite ir spauskite TOLIAU.");
    end
endfunction

function ld6_student_sync()
    global LD6;
    if ~isfield(LD6, "ui") then return; end
    if isfield(LD6.ui, "headless") then if LD6.ui.headless then return; end end
    if isfield(LD6.ui, "studentPrimary") & is_handle_valid(LD6.ui.studentPrimary) then
        if LD6.demoMode then
            LD6.ui.studentPrimary.string="GRĮŽTI Į SAVO DARBĄ";
        elseif LD6.step == 6 & and(LD6.done) then
            LD6.ui.studentPrimary.string = "ĮRAŠYTI ATASKAITĄ";
        elseif LD6.step==6 & LD6.done(6) then
            LD6.ui.studentPrimary.string = "UŽBAIGTI PRALEISTĄ ETAPĄ";
        elseif LD6.done(LD6.step) then
            LD6.ui.studentPrimary.string = "TOLIAU →";
        elseif LD6.assessment then
            LD6.ui.studentPrimary.string = "ĮRAŠYTI IR TOLIAU →";
        else
            LD6.ui.studentPrimary.string = "TIKRINTI";
        end
    end
endfunction
