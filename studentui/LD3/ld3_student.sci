// ============================================================================
// LD3 studento srautas: paleidimas, pagrindinis mygtukas, pagalba.
// ============================================================================

function ld3_student_main(root)
    global LD3;
    if typeof(LD3)=="st" then
        if isfield(LD3,"fig") then
            if is_handle_valid(LD3.fig) then show_window(LD3.fig); return; end
        end
    end
    try bench_core_require(); catch
        messagebox(["LD3 nepavyko paleisti.";strcat(lasterror()," "); ...
            "Išskleiskite visą paketą į vieną aplanką ir paleiskite STENDAS.sce per grafinį Scilab."], ...
            "LD3 paleidimas","error");
        return;
    end
    [ok,st,cfg]=student_enroll("LD3");
    if ~ok then return; end
    LD3=struct("root",root,"cfg",cfg,"student",st);
    student_remember(st); ld3_start();
    bench_autosave("LD3");
endfunction

function ld3_student_details()
    global LD3;
    if LD3.demoMode then
        ld3_set_status("Pirmiausia grįžkite į savo darbą.","info","");
        return;
    end
    pick=messagebox([student_caption(LD3.student);student_parameter_lines("LD3",LD3.cfg)], ...
        "Studentas ir priskirtos reikšmės","info",["Grįžti" "Keisti duomenis"],"modal");
    if pick<>2 then return; end
    [ok,st,cfg]=student_enroll("LD3",LD3.student);
    if ~ok then return; end
    if st.number<>LD3.student.number then
        pick=messagebox("Kitas variantas pradės naują darbą. Dabartinis darbas pirmiausia bus išsaugotas.", ...
            "Keisti variantą?","question",["Atšaukti" "Pradėti naują"],"modal");
        if pick<>2 then return; end
    end
    ld3_apply_profile(st,cfg);
endfunction

function ld3_apply_profile(st,cfg)
    global LD3;
    ld3_save_answers();
    changed=st.number<>LD3.student.number;
    assessment=LD3.assessment; practice=LD3.practice_used;
    if changed then
        bench_autosave("LD3");
        if isfield(LD3,"autosave_error") then
            if LD3.autosave_error<>"" then return; end
        end
        ld3_init_state();
        LD3.cfg=cfg; LD3.student=st;
        LD3.assessment=assessment; LD3.practice_used=practice;
        LD3.autosave_paths=emptystr(0,1); LD3.autosave_error="";
    else
        LD3.cfg=cfg; LD3.student=st;
    end
    student_remember(st);
    if isfield(LD3,"ui") then
        if ~isfield(LD3.ui,"headless") | ~LD3.ui.headless then ld3_render_stage(); end
    end
    bench_autosave("LD3");
endfunction

function ld3_start()
    global LD3;
    // Darbo pradžia inicializuoja būseną (kaip ld1_start): cfg/student išlieka.
    if ~isfield(LD3, "step") then
        cfg = LD3.cfg; st = LD3.student;
        ld3_init_state();
        LD3.cfg = cfg; LD3.student = st;
    end
    needgui = %t;
    if isfield(LD3, "ui") then
        if isfield(LD3.ui, "headless") then
            if LD3.ui.headless then needgui = %f; end
        end
        if isfield(LD3.ui, "standFrame") then needgui = %f; end  // jau pastatyta
    end
    if needgui & ~isfield(LD3, "fig") then
        ld3_build_gui();
    end
    if ~isfield(LD3,"autosave_enabled") then LD3.autosave_enabled=needgui; end
    ld3_set_status("Pradėkite nuo grandinės sujungimo.","info","Atsiskaitymo režimas. Jei reikia, atverkite Pagalba → Kaip sujungti.");
endfunction

function ld3_student_primary()
    global LD3;
    if LD3.demoMode then ld3_toggle_solution(); return; end
    ld3_save_answers();
    if LD3.step==6 & LD3.done(6) then
        if ~and(LD3.done) then
            ld3_set_status("Dar yra neužbaigtų ankstesnių etapų.","error","Grįžkite prie neužbaigto etapo ir jį užfiksuokite.");
            return;
        end
        bench_export_current("LD3");
        return;
    end
    if ~LD3.done(LD3.step) then
        ld3_check_step(~LD3.assessment);
    end
    if LD3.done(LD3.step) & LD3.step<6 then
        ld3_next_step();
    end
    ld3_student_sync(); bench_autosave("LD3");
endfunction

function ld3_jump_step(n)
    global LD3;
    if n<1 | n>6 then return; end
    if n <= LD3.step | LD3.done(n) | LD3.skipped(n) then
        ld3_set_step(n);
    else
        ld3_set_status("Šio etapo dar nepasiekėte.","info","Dabartinį etapą patikrinkite ir spauskite TOLIAU.");
    end
endfunction

function ld3_student_sync()
    global LD3;
    if ~isfield(LD3, "ui") then return; end
    if isfield(LD3.ui, "headless") then if LD3.ui.headless then return; end end
    if isfield(LD3.ui, "studentPrimary") & is_handle_valid(LD3.ui.studentPrimary) then
        if LD3.step == 6 & LD3.done(6) then
            LD3.ui.studentPrimary.string = "ĮRAŠYTI ATASKAITĄ";
        elseif LD3.done(LD3.step) then
            LD3.ui.studentPrimary.string = "TOLIAU →";
        elseif LD3.assessment then
            LD3.ui.studentPrimary.string = "TOLIAU →";
        else
            LD3.ui.studentPrimary.string = "TIKRINTI";
        end
    end
endfunction
