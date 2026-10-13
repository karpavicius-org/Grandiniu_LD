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
    try bench_core_require(); catch
        messagebox(["LD7 nepavyko paleisti.";strcat(lasterror()," "); ...
            "Išskleiskite visą paketą į vieną aplanką ir paleiskite STENDAS.sce per grafinį Scilab."], ...
            "LD7 paleidimas","error");
        return;
    end
    [ok, st, cfg] = student_enroll("LD7");
    if ~ok then return; end
    LD7 = struct("root", root, "cfg", cfg, "student", st);
    student_remember(st); ld7_start();
    bench_autosave("LD7");
endfunction

// A mistaken name or group must be fixable without losing the experiment.
function ld7_student_details()
    global LD7;
    if LD7.demoMode then
        ld7_set_status("Pirma grįžkite į savo darbą.","info",""); return;
    end
    pick=messagebox([student_caption(LD7.student);student_parameter_lines("LD7",LD7.cfg)], ...
        "Studentas ir priskirtos reikšmės","info",["Grįžti" "Keisti duomenis"],"modal");
    if pick<>2 then return; end
    [ok,st,cfg]=student_enroll("LD7",LD7.student);
    if ~ok then return; end
    if st.number<>LD7.student.number then
        pick=messagebox("Kitas variantas pradės naują darbą. Dabartinis darbas pirmiausia bus išsaugotas.", ...
            "Keisti variantą?","question",["Atšaukti" "Pradėti naują"],"modal");
        if pick<>2 then return; end
    end
    ld7_apply_profile(st,cfg);
endfunction

function ld7_apply_profile(st,cfg)
    global LD7;
    ld7_save_answers();
    changed=st.number<>LD7.student.number;
    assessment=LD7.assessment; practice=LD7.practice_used;
    if changed then
        bench_autosave("LD7");
        if isfield(LD7,"autosave_error") then
            if LD7.autosave_error<>"" then return; end
        end
        ld7_init_state();
        LD7.cfg=cfg; LD7.student=st;
        LD7.assessment=assessment; LD7.practice_used=practice;
        LD7.autosave_paths=emptystr(0,1); LD7.autosave_error="";
    else
        LD7.cfg=cfg; LD7.student=st;
    end
    student_remember(st);
    if isfield(LD7,"ui") then
        if ~isfield(LD7.ui,"headless") | ~LD7.ui.headless then
            // Variant change affects the permanent P1–P5 button captions too.
            if changed & isfield(LD7.ui,"controls") then
                for k=1:5
                    h=LD7.ui.controls(k+3);
                    if is_handle_valid(h) then
                        h.string="<html><center>"+msprintf("P%d<br>%g Ω",k,cfg("R"+string(k)))+"</center></html>";
                    end
                end
            end
            ld7_render_stage();
        end
    end
    bench_autosave("LD7");
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
    ld7_set_status("Pradėkite nuo darbinės grandinės sujungimo.", "info", "Atsiskaitymo režimas. Jungimo seką rasite per Pagalba → Kaip sujungti.");
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
