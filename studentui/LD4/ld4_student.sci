// ============================================================================
// LD4 studento srautas: paleidimas, pagrindinis mygtukas, pagalba.
// ============================================================================

function ld4_student_main(root)
    global LD4;
    if typeof(LD4)=="st" then
        if isfield(LD4,"fig") then
            if typeof(LD4.fig)=="handle" then
                if is_handle_valid(LD4.fig) then show_window(LD4.fig); return; end
            end
        end
    end
    try bench_core_require(); catch
        messagebox(["LD4 nepavyko paleisti.";strcat(lasterror()," "); ...
            "Išskleiskite visą paketą į vieną aplanką ir paleiskite STENDAS.sce per grafinį Scilab."], ...
            "LD4 paleidimas","error");
        return;
    end
    [ok,st,cfg]=student_enroll("LD4");
    if ~ok then return; end
    LD4=struct("root",root,"cfg",cfg,"student",st);
    student_remember(st); ld4_start();
    bench_autosave("LD4");
endfunction

function ld4_student_details()
    global LD4;
    if LD4.demoMode then
        ld4_set_status("Pirmiausia grįžkite į savo darbą.","info","");
        return;
    end
    pick=messagebox([student_caption(LD4.student);student_parameter_lines("LD4",LD4.cfg)], ...
        "Studentas ir priskirtos reikšmės","info",["Grįžti" "Keisti duomenis"],"modal");
    if pick<>2 then return; end
    [ok,st,cfg]=student_enroll("LD4",LD4.student);
    if ~ok then return; end
    if st.number<>LD4.student.number then
        pick=messagebox("Kitas variantas pradės naują darbą. Dabartinis darbas pirmiausia bus išsaugotas.", ...
            "Keisti variantą?","question",["Atšaukti" "Pradėti naują"],"modal");
        if pick<>2 then return; end
    end
    ld4_apply_profile(st,cfg);
endfunction

function ld4_apply_profile(st,cfg)
    global LD4;
    ld4_save_answers();
    changed=st.number<>LD4.student.number;
    assessment=LD4.assessment; practice=LD4.practice_used;
    if changed then
        bench_autosave("LD4");
        if isfield(LD4,"autosave_error") then
            if LD4.autosave_error<>"" then return; end
        end
        ld4_init_state();
        LD4.cfg=cfg; LD4.student=st;
        LD4.assessment=assessment; LD4.practice_used=practice;
        LD4.autosave_paths=emptystr(0,1); LD4.autosave_error="";
    else
        LD4.cfg=cfg; LD4.student=st;
    end
    student_remember(st);
    if isfield(LD4,"ui") then
        if ~isfield(LD4.ui,"headless") | ~LD4.ui.headless then ld4_render_stage(); end
    end
    bench_autosave("LD4");
endfunction

function path=ld4_export_report()
    global LD4;
    path="";
    ld4_save_answers();
    if LD4.assessment & ~and(LD4.done) then
        ld4_set_status("Dar yra neužbaigtų etapų.","error","Užbaikite visus 7 etapus ir tada išsaugokite ataskaitą.");
        return;
    end
    path=bench_export_current("LD4");
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
    ld4_set_status("Pradėkite nuo R1 matavimo grandinės sujungimo.","info","Atsiskaitymo režimas. Jei reikia, atverkite Pagalba → Kaip sujungti.");
endfunction

function ld4_student_primary()
    global LD4;
    if LD4.demoMode then ld4_toggle_solution(); return; end
    ld4_save_answers();
    if LD4.step==7 & LD4.done(7) then
        ld4_export_report();
        return;
    end
    if ~LD4.done(LD4.step) then
        ld4_check_step(~LD4.assessment);
    end
    if LD4.done(LD4.step) & LD4.step<7 then
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
            LD4.ui.studentPrimary.string = "TOLIAU →";
        else
            LD4.ui.studentPrimary.string = "TIKRINTI";
        end
    end
endfunction
