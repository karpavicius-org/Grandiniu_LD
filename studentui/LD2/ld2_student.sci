// A quieter native bench using the same shell and palette as LD1.
function ld2_show_error(problem,fixes)
    // Like LD1: show a correction in the bench, without a blocking dialog.
    global LD2;
    LD2.state.last_error=problem;
    LD2.state.last_fix=strcat(matrix(fixes,-1,1)," ");
    if isfield(LD2.ui,"headless") then if LD2.ui.headless then return; end; end
    hint="";
    if size(fixes,"*")>0 then hint=" "+fixes(1); end
    ld2_set_status(student_wrap(problem+hint,145),"error");
endfunction

function ld2_student_main(root)
    global LD2;
    if typeof(LD2)=="st" then
        if isfield(LD2,"ui") then
            if isfield(LD2.ui,"figure") then
                if is_handle_valid(LD2.ui.figure) then show_window(LD2.ui.figure); return; end
            end
        end
    end
    try bench_core_require(); catch
        messagebox(["LD2 nepavyko paleisti.";strcat(lasterror()," "); ...
            "Išskleiskite visą paketą į vieną aplanką ir paleiskite STENDAS.sce per grafinį Scilab."], ...
            "LD2 paleidimas","error");
        return;
    end
    [ok,st,cfg]=student_enroll("LD2");
    if ~ok then return; end
    LD2=struct("root",root,"cfg",cfg,"state",ld2_initial_state(cfg), ...
        "ui",struct("headless",%f,"suppress_render",%f),"example_active",%f,"example_backup",struct());
    LD2.state.student=st;LD2.state.assessment=%t;
    student_remember(st);
    ld2_build_gui(); ld2_go_step(1,%f);
    LD2.autosave_enabled=%t;
    bench_autosave("LD2");
endfunction

function ld2_student_details()
    global LD2;
    if LD2.example_active then ld2_show_info("Pavyzdys","Pirmiausia grįžkite į savo darbą."); return; end
    if ~isfield(LD2.state,"student") then LD2.state.student=student_empty("LD2"); end
    pick=messagebox([student_caption(LD2.state.student);student_parameter_lines("LD2",LD2.cfg)], ...
        "Studentas ir priskirtos reikšmės","info",["Grįžti" "Keisti duomenis"],"modal");
    if pick<>2 then return; end
    [ok,st,cfg]=student_enroll("LD2",LD2.state.student);
    if ~ok then return; end
    if st.number<>LD2.state.student.number then
        pick=messagebox("Kitas variantas pradės naują darbą. Dabartinį darbą galite išsaugoti per Darbo meniu.", ...
            "Keisti variantą?","question",["Atšaukti" "Pradėti naują"],"modal");
        if pick<>2 then return; end
    end
    ld2_apply_profile(st,cfg);
endfunction

function ld2_apply_profile(st,cfg)
    global LD2;
    ld2_save_answers();
    changed=st.number<>LD2.state.student.number;
    assessment=LD2.state.assessment; practice=LD2.state.practice_used;
    if changed then
        bench_autosave("LD2");
        if isfield(LD2,"autosave_error") then
            if LD2.autosave_error<>"" then return; end
        end
        ld2_clear_dynamic();
        LD2.cfg=cfg; LD2.state=ld2_initial_state(cfg);
        LD2.state.assessment=assessment; LD2.state.practice_used=practice;
        LD2.autosave_paths=emptystr(0,1); LD2.autosave_error="";
    end
    LD2.state.student=st;
    ld2_render_step();
    student_remember(st);
    if changed then bench_autosave("LD2"); end
endfunction

function ld2_student_close()
    global LD2;
    if typeof(LD2)<>"st" then return; end
    if ~isfield(LD2,"ui") | ~isfield(LD2.ui,"figure") then return; end
    if ~is_handle_valid(LD2.ui.figure) then return; end
    if LD2.example_active then ld2_show_solution(); end
    ld2_save_answers();
    bench_autosave("LD2");
    if isfield(LD2,"autosave_error") then
        if LD2.autosave_error<>"" then return; end
    end
    LD2.guide_enabled=%f;student_guide_hide("LD2");
    delete(LD2.ui.figure);
endfunction

function ld2_edit_parameters()
    global LD2;
    ld2_show_info("Priskirtos reikšmės",student_parameter_lines("LD2",LD2.cfg));
endfunction

function ld2_build_gui()
    global LD2;
    f=figure("resize","off","default_axes","off","dockable","off","menubar","none","toolbar","none","visible","off");
    f.figure_name="LD2 · Kintamosios srovės stendas"; f.axes_size=[1280 720];
    f.closerequestfcn="ld2_student_close()";
    f.figure_position=[10 10]; f.infobar_visible="off"; f.background=color(246,248,249);
    LD2.ui.figure=f; LD2.ui.dynamic=[]; LD2.ui.answer_edits=[]; LD2.ui.answer_step=0;
    LD2.ui.choice_yes=[]; LD2.ui.choice_no=[]; LD2.ui.term_handles=struct("dummy",0);
    student_text(f,[0.03 0.925 0.65 0.05],"LD2  /  Kintamosios srovės grandinės",22,%t,[0.965 0.973 0.977]);
    LD2.ui.studentProgress=student_text(f,[0.705 0.93 0.15 0.044],"",14,%f,[0.965 0.973 0.977]);
    LD2.ui.studentIdentity=student_text(f,[0.03 0.895 0.94 0.025],"",12,%f,[0.965 0.973 0.977]);
    h=student_button(f,[0.87 0.93 0.105 0.044],"Darbo meniu","ld2_student_help()");
    h.backgroundcolor=[1.00 0.82 0.32];h.foregroundcolor=[0.20 0.18 0.11];
    LD2.ui.stand=student_frame(f,[0.025 0.12 0.655 0.77]);
    LD2.ui.right=student_frame(f,[0.70 0.12 0.275 0.77]);
    LD2.ui.status=student_text(f,[0.025 0.025 0.95 0.07],"",13,%f,[0.94 0.96 0.96]);
    // No ghost navigation controls. Step selection is in Pagalba -> Etapai.
    LD2.ui.step_buttons=[];
    student_finish_window(f); f.visible="on";
endfunction

function ld2_update_nav_colors()
    // Kept as a stable interface: main student UI has no hidden nav widgets.
    // Live next-action highlighting is provided by ld2_guide_next().
endfunction

function ld2_main(root)
    // Preview / automated GUI test only; never counted as an assessment.
    // Opens the SAME actual student UI without prompting for an identity.
    global LD2;
    cfg=ld2_default_config();
    LD2=struct("root",root,"cfg",cfg,"state",ld2_initial_state(cfg), ...
        "ui",struct("headless",%f,"suppress_render",%f), ...
        "example_active",%f,"example_backup",struct());
    LD2.state.student=student_profile(1,"Bandomoji peržiūra","PATIKRA","LD2");
    LD2.state.assessment=%f;
    LD2.state.practice_used=%t;
    LD2.state.teacher_mode=%t;
    ld2_build_gui();ld2_go_step(1,%t);
endfunction

function ld2_render_step()
    global LD2;
    if isfield(LD2.ui,"suppress_render") then if LD2.ui.suppress_render then return; end; end
    if isfield(LD2.ui,"headless") then if LD2.ui.headless then return; end; end
    drawing=LD2.ui.figure.immediate_drawing; LD2.ui.figure.immediate_drawing="off";
    ld2_workflow_upgrade();
    ld2_save_answers(); ld2_clear_dynamic();
    // Legacy snapshots can point to hidden stages; show the actual next experiment.
    if LD2.state.step==3 then LD2.state.step=4; end
    if LD2.state.step==6 then LD2.state.step=7; end
    ld2_render_instructions(); ld2_render_answers(); ld2_render_action_row();
    ld2_render_stand(); ld2_render_controls(); ld2_update_nav_colors();
    LD2.ui.studentProgress.string=string(ld2_visible_ordinal(LD2.state.step))+" / 10 etapų";
    if LD2.example_active then LD2.ui.studentProgress.string="Pavyzdys · "+string(ld2_visible_ordinal(LD2.state.step)); end
    if isfield(LD2.state,"student") then LD2.ui.studentIdentity.string=student_caption(LD2.state.student); end
    LD2.ui.figure.immediate_drawing=drawing;
    ld2_guide_refresh();
endfunction

function ld2_render_instructions()
    global LD2;
    p=LD2.ui.right;
    h=student_text(p,[0.07 0.85 0.86 0.12],student_wrap(ld2_workflow_title(LD2.state.step),24),20,%t);ld2_track(h);
    lines=ld2_stage_purpose(LD2.state.step);
    if ld2_guide_enabled() then [lines,focus,button,field]=ld2_guide_next(); end
    h=student_text(p,[0.07 0.65 0.86 0.18],student_wrap(lines,34),16,%f,[1 1 1]);
    h.verticalalignment="top";h.tag="LD2_GUIDE";LD2.ui.guide_text=h;ld2_track(h);
    h=student_button(p,[0.07 0.585 0.40 0.05],"Paaiškinimas","ld2_guide_show()");ld2_track(h);
    h=student_button(p,[0.53 0.585 0.40 0.05],"Teorija","ld2_help_current()");ld2_track(h);
endfunction

function ld2_render_answers()
    global LD2;
    p=LD2.ui.right;step=LD2.state.step;
    LD2.ui.answer_edits=[];LD2.ui.answer_step=step;
    [action,ready]=ld2_auto_stage_status(step);
    if step==1 then
        txt=["1. Atlikite bandymą.";"2. Palyginkite rodmenis.";"3. Pasirinkite savo išvadą.";"";"Tik BW įrašysite patys."];
        h=student_text(p,[0.07 0.24 0.86 0.30],student_wrap(txt,35),15,%f);ld2_track(h);return;
    end
    if or(step==[2 5 8]) then
        phase=ld2_phase_for_step(step);req=ld2_required_main(phase);
        [valid,missing]=ld2_validate_main(phase);
        txt=string(size(req,1)-size(missing,1))+" / "+string(size(req,1))+" laidai prijungti";
        h=student_text(p,[0.07 0.40 0.86 0.10],txt,17,%t);ld2_track(h);
        h=student_text(p,[0.07 0.25 0.86 0.13],student_wrap("Sujungti galima vienu mygtuku arba spaudžiant paryškintus kontaktus.",34),14,%f);ld2_track(h);return;
    end
    if step==12 then
        labels=["Grafikas";"Suvestinė";"Įrašyti išvadas"];
        callbacks=["ld2_plot_current()";"ld2_show_summary_window()";"ld2_edit_conclusions()"];
        for k=1:3
            h=student_button(p,[0.07 0.47-(k-1)*0.09 0.86 0.065],labels(k),callbacks(k));
            h.tag="LD2_RESULT_"+string(k);
            if k==1 & ~ready then h.enable="off"; end
            ld2_track(h);
        end
        return;
    end
    if ~ready then
        h=student_text(p,[0.07 0.29 0.86 0.24],student_wrap("Čia atsiras bandymo rodmenys ir jūsų pasirinkimas. Pirmiausia paleiskite bandymą po grandine.",35),15,%f);ld2_track(h);return;
    end
    [question,details]=ld2_workflow_question(step);
    if step==9 then
        h=student_text(p,[0.07 0.49 0.86 0.07],student_wrap(question,35),14,%t);ld2_track(h);
        for k=1:size(LD2.state.res_f,"*")
            label=msprintf("%.2f Hz  |  UR %.3f V",LD2.state.res_f(k),LD2.state.res_ur(k));
            if LD2.state.resonance_choice==k then label="✓ "+label; end
            h=student_button(p,[0.07 0.40-(k-1)*0.08 0.86 0.067],label,msprintf("ld2_choose_resonance(%d)",k));
            h.fontsize=13;h.tag="LD2_POINT_"+string(k);ld2_track(h);
        end
    else
        rows=ld2_workflow_readings(step);
        h=student_text(p,[0.07 0.37 0.86 0.18],student_wrap(rows,34),16,%t,[0.93 0.97 0.95]);
        h.verticalalignment="top";h.tag="LD2_READINGS";ld2_track(h);
        if step==11 then
            h=student_text(p,[0.07 0.27 0.48 0.07],"BW, Hz",15,%t);ld2_track(h);
            e=ld2_edit(p,[0.56 0.27 0.37 0.07],LD2.state.answers_text(11,1));
            e.callback="ld2_student_answers_changed()";e.tag="A11.01";LD2.ui.answer_edits=e;
            h=student_text(p,[0.07 0.19 0.86 0.06],"Galite rašyti tašką arba kablelį.",12,%f);ld2_track(h);
        else
            h=student_text(p,[0.07 0.265 0.86 0.09],student_wrap(question,36),14,%t);ld2_track(h);
            for k=1:2
                labels=["Taip" "Ne"];label=labels(k);
                if LD2.state.comparisons(step)==k then label="✓ "+label; end
                h=student_button(p,[0.07+(k-1)*0.46 0.19 0.40 0.06],label,msprintf("ld2_choose_comparison(%d)",k));
                h.tag="LD2_CHOICE_"+string(k);ld2_track(h);
            end
        end
    end
endfunction

function ld2_render_action_row()
    global LD2;
    step=LD2.state.step;label=ld2_primary_label(step);
    if LD2.example_active then label="Grįžti į savo darbą";end
    h=student_button(LD2.ui.right,[0.07 0.085 0.86 0.075],label,"ld2_student_primary()",%t);
    h.tag="B04";LD2.ui.studentPrimary=h;ld2_track(h);
    [ready,why]=ld2_workflow_ready();
    if ~ready & ~LD2.example_active then h.enable="off";end
    h=student_button(LD2.ui.right,[0.07 0.015 0.37 0.05],"← Atgal","ld2_prev()");
    if step==1 | LD2.example_active then h.enable="off";end
    h.tag="B05";ld2_track(h);
    h=student_button(LD2.ui.right,[0.50 0.015 0.43 0.05],"Pagalba ?","ld2_guide_show()");
    h.backgroundcolor=[1.00 0.82 0.32];h.tag="LD2_HELP_VISIBLE";ld2_track(h);
endfunction

function ld2_student_answers_changed()
    global LD2;
    ld2_save_answers();
    bench_autosave("LD2");
    ld2_guide_refresh();
    if ~LD2.example_active then
        if LD2.state.assessment then LD2.ui.studentPrimary.string="Toliau →";
        else LD2.ui.studentPrimary.string="Patikrinti";end
    end
endfunction

function ld2_student_primary()
    global LD2;
    ld2_save_answers();
    if LD2.example_active then ld2_show_solution();
    elseif LD2.state.assessment then
        if ~ld2_assessment_ready() then bench_autosave("LD2"); return; end
        LD2.state.completed(LD2.state.step)=1; LD2.state.skipped(LD2.state.step)=0;
        bench_autosave("LD2");
        if LD2.state.step==12 then bench_export_current("LD2");
        else ld2_go_step(ld2_visible_next(LD2.state.step),%f);end
    elseif LD2.state.step==1 then ld2_check_step(); ld2_next();
    elseif LD2.state.completed(LD2.state.step) then
        if LD2.state.step==12 then bench_export_current("LD2"); else ld2_next(); end
    else ld2_check_step(); end
endfunction

function ld2_student_help()
    global LD2;
    selected=x_choose(["Vesti žingsnis po žingsnio";"Šio etapo pagalba"; ...
        "Tęsti arba atkurti darbą";"Mano duomenys ir variantas"; ...
        "Ataskaita ir rezultatai";"Daugiau veiksmų"],"Darbo meniu");
    if selected==0 then return; end
    if selected==1 then ld2_guide_show(); return; end
    selected=selected-1;
    n=0;
    if selected==1 then
        a=x_choose(["Metodika ir formulės";"Etapo paaiškinimas";"Grafikai";"Matavimų žurnalas";"Kontaktų žinynas"],"Šio etapo pagalba");
        if a==1 then n=1;
        elseif a==2 then n=13;
        elseif a==3 then
            k=x_choose(["Dabartinio bandymo grafikas";"Oscilograma";"Varžų vektoriai";"Įtampų vektoriai"],"Grafikai");
            select k
            case 1 then ld2_plot_current();
            case 2 then ld2_plot_scope_current();
            case 3 then ld2_plot_impedance();
            case 4 then ld2_plot_voltage_current(); end
            return;
        elseif a==4 then n=4;
        elseif a==5 then n=14; end
    elseif selected==2 then
        a=x_choose(["Tęsti automatinį juodraštį";"Išsaugoti darbą";"Atverti išsaugotą darbą";"Etapai"],"Tęsti arba atkurti darbą");
        if a==1 then n=11; elseif a==2 then n=5; elseif a==3 then n=6; elseif a==4 then n=7; end
    elseif selected==3 then
        a=x_choose(["Studentas ir priskirtos reikšmės";"64 variantų bankas"],"Mano duomenys ir variantas");
        if a==1 then n=8; elseif a==2 then n=15; end
    elseif selected==4 then
        a=x_choose(["Darbo suvestinė";"Įrašyti išvadas";"Išsaugoti ataskaitą";"Atverti ataskaitų aplanką"],"Ataskaita ir rezultatai");
        if a==1 then ld2_show_summary_window(); return;
        elseif a==2 then ld2_edit_conclusions(); return;
        elseif a==3 then bench_export_current("LD2"); return;
        elseif a==4 then bench_open_local(bench_documents()); return; end
    elseif selected==5 then
        a=x_choose(["Atsiskaitymo / mokymosi režimas";"Parodyti pavyzdį / mano darbą"; ...
            "Pradėti darbą iš naujo";"Šaltiniai ir metodiniai pakeitimai";"Valdiklių žinynas"],"Daugiau veiksmų");
        if a==1 then n=12; elseif a==2 then n=2; elseif a==3 then n=9; elseif a==4 then n=16; elseif a==5 then n=17; end
    end
    select n
    case 1 then ld2_help_current();
    case 2 then ld2_show_solution();
    case 4 then ld2_show_journal();
    case 5 then ld2_save_work();
    case 6 then ld2_load_work();
    case 7 then
        stages=ld2_visible_steps();
        opts=emptystr(size(stages,"*"),1);
        for k=1:size(stages,"*")
            stage=stages(k);
            state="Neatlikta";
            if LD2.state.completed(stage)==1 then
                if LD2.state.assessment then state="Įrašyta"; else state="Patikrinta"; end
            elseif LD2.state.skipped(stage)==1 then state="Praleista"; end
            opts(k)=state+" · "+ld2_step_title(stage);
        end
        choice=x_choose(opts,"Etapai · atsakymai išlieka");
        if choice>0 then ld2_step_button(stages(choice)); end
    case 8 then ld2_student_details();
    case 9 then ld2_restart();
    case 11 then bench_open_snapshot("LD2");
    case 12 then bench_mode("LD2");
    case 13 then ld2_edit_step_note();
    case 14 then ld2_show_contact_map();
    case 15 then ld2_show_variant_bank();
    case 16 then ld2_show_method_fixes();
    case 17 then ld2_show_button_map();
    end
endfunction

function ld2_render_controls()
    global LD2;
    step=LD2.state.step;p=LD2.ui.stand;
    if step==1 then return;end
    [action,ready]=ld2_auto_stage_status(step);
    h=student_button(p,[0.52 0.02 0.44 0.065],action,"ld2_auto_stage()",%t);
    h.tag="LD2_RUN";ld2_track(h);
    if ready then h.enable="off";h.string="✓ Bandymas atliktas";end
    if or(step==[2 5 8]) then
        h=student_button(p,[0.04 0.02 0.21 0.065],"Atšaukti laidą","ld2_undo_wire()");h.tag="B11";ld2_track(h);
        h=student_button(p,[0.27 0.02 0.22 0.065],"Jungimo pagalba","ld2_guide_show()");ld2_track(h);
    else
        h=student_text(p,[0.04 0.02 0.45 0.065],"Zondus ir rodmenis valdo stendas.",13,%f);ld2_track(h);
    end
    if LD2.example_active then
        for h=LD2.ui.dynamic
            if is_handle_valid(h) then
                if h.type=="uicontrol" then
                    if h.style=="pushbutton" | h.style=="edit" then h.enable="off";end
                end
            end
        end
        LD2.ui.studentPrimary.enable="on";
    end
endfunction

function ld2_component_box(parent,pos,main,sub,bg)
    global LD2;
    bg=[0.96 0.97 0.96]; phase=ld2_phase_for_step(LD2.state.step); step=LD2.state.step;
    if main=="GENERATORIUS" then
        pos(4)=0.24; pos(2)=0.40;
        if phase=="RLC" then pos(3)=0.11; end
        fr=ld2_frame(parent,pos,[0.94 0.97 0.97]);
        fr.tag="component:GEN";
        ld2_text(fr,[0.07 0.77 0.86 0.16],"ŠALTINIS",12,%t,"left",[0.94 0.97 0.97],[0.13 0.19 0.23]);
        txt=strsubst(sub," • ",ascii(10));
        if phase=="RLC" then txt=msprintf("%.0f V RMS",LD2.cfg.E_RLC)+ascii(10)+msprintf("%.1f Hz",LD2.state.freq);end
        ld2_text(fr,[0.07 0.31 0.86 0.40],txt,14,%t,"left",[0.94 0.97 0.97],[0.13 0.19 0.23]);
        label="Išjungtas"; if LD2.state.power then label="Įjungtas"; end
        h=ld2_text(fr,[0.07 0.06 0.86 0.22],label,12,%t,"left",[0.94 0.97 0.97],[0.13 0.19 0.23]);
    elseif main=="A~" then
        pos(2)=0.535; pos(4)=0.19;
        if phase=="RLC" then pos(1)=0.238; pos(3)=0.075;
        else pos(1)=0.293; pos(3)=0.089; end
        [tx,ty]=ld2_terminal_xy(phase,"AM_H");
        ld2_wire_segment(parent,tx+0.014,ty+0.019,pos(1),ty+0.019,[0.41 0.49 0.51]);
        [tx,ty]=ld2_terminal_xy(phase,"AM_L");
        ld2_wire_segment(parent,pos(1)+pos(3),ty+0.019,tx+0.014,ty+0.019,[0.41 0.49 0.51]);
        fr=ld2_frame(parent,pos,[0.93 0.96 0.96]);
        fr.tag="component:AM";
        name=ld2_text(parent,[pos(1)+pos(3)/2-0.10 pos(2)+pos(4)+0.012 0.20 0.035],sub,12,%t,"center",[1 1 1],[0.13 0.19 0.23]);
        name.tag="label:AM_NAME";
        ld2_text(fr,[0.06 0.77 0.88 0.16],"A~",15,%t,"center",[0.93 0.96 0.96],[0.13 0.19 0.23]);
        reading=strsubst(ld2_amp_display_text()," mA",ascii(10)+"mA");
        ld2_text(fr,[0.04 0.34 0.92 0.36],reading,12,%t,"center",[0.93 0.96 0.96],[0.13 0.19 0.23]);

    elseif main=="V~ VOLTMETRAS" then
        if ~(step==4 | step==7 | step>=9) then return; end
        pos=[0.41 0.10 0.28 0.16];
        fr=ld2_frame(parent,pos,[0.93 0.96 0.96]);
        fr.tag="component:VM";
        ld2_text(fr,[0.07 0.77 0.86 0.19],"VOLTMETRAS · V~",12,%t,"left",[0.93 0.96 0.96],[0.13 0.19 0.23]);
        ld2_text(fr,[0.07 0.41 0.86 0.28],ld2_volt_display_text(),19,%t,"center",[0.93 0.96 0.96],[0.13 0.19 0.23]);

    else
        eq=strindex(main," = ");
        if size(eq,"*")>0 then
            id=part(main,1:eq(1)-1);
            if phase=="RLC" then
                select id
                case "C4" then pos(1)=0.415;
                case "L3" then pos(1)=0.592;
                case "R13" then pos(1)=0.769;
                end
                pos(3)=0.075;
            else pos(1)=pos(1)+0.012; pos(3)=pos(3)-0.022; end
            [tx,ty]=ld2_terminal_xy(phase,id+"_1");
            ld2_wire_segment(parent,tx+0.014,ty+0.019,pos(1),ty+0.019,[0.41 0.49 0.51]);
            [tx,ty]=ld2_terminal_xy(phase,id+"_2");
            ld2_wire_segment(parent,pos(1)+pos(3),ty+0.019,tx+0.014,ty+0.019,[0.41 0.49 0.51]);
        end
        fr=ld2_frame(parent,pos,bg);
        fr.tag="component:"+id;
        txt=strsubst(main," = ",ascii(10));
        if phase=="RLC" then txt=strsubst(txt," ",ascii(10)); end
        ld2_text(fr,[0.07 0.10 0.86 0.80],txt,14,%t,"center",bg,[0.13 0.19 0.23]);
    end
endfunction

function ld2_draw_terminal(parent,id,label,xy,active,c)
    global LD2;
    used=ld2_terminal_used(c,id); isactive=ld2_in_string_list(id,active);
    if ~used & ~isactive then return; end
    parts=tokens(id,"_"); owner=parts(1);
    if id=="LC_M1" then owner="C4"; end
    if id=="LC_M2" then owner="L3"; end
    for fr=parent.children'
        if fr.style=="frame" & fr.tag=="component:"+owner then
            r=fr.position; center=xy+[0.014 0.019];
            edge=[max(r(1),min(r(1)+r(3),center(1))) max(r(2),min(r(2)+r(4),center(2)))];
            mid=[center(1) edge(2)];
            hh=student_wire(parent,center,mid,[0.41 0.49 0.51],"lead:"+owner); if hh<>[] then ld2_track(hh); end
            hh=student_wire(parent,mid,edge,[0.41 0.49 0.51],"lead:"+owner); if hh<>[] then ld2_track(hh); end
        end
    end
    selected=(LD2.state.selected_terminal==id);
    highlighted=%f;
    if ld2_guide_enabled() then
        [gtext,gtargets,gcallback,gfield]=ld2_guide_next();
        highlighted=ld2_in_string_list(id,gtargets);
    end
    bg=[0.08 0.39 0.37];
    if highlighted & isactive & ~used then bg=[0.98 0.70 0.17]; end
    if selected then bg=[0.85 0.59 0.16]; end
    if label=="COM" then label="C"; end
    h=student_terminal(parent,xy+[0.014 0.019],label,ld2_terminal_code(id), ...
        msprintf("ld2_terminal_click(""%s"")",id),ld2_terminal_name(id),bg);
    if LD2.example_active | used | ~isactive then h.enable="off"; end
    ld2_track(h);
endfunction

function ld2_draw_phase_stand(parent,phase,step)
    global LD2;
    c=ld2_get_phase_connections(phase); active=ld2_active_terminals(step);
    ports=[];
    for id=matrix(ld2_terminal_ids(),1,-1)
        if ld2_terminal_used(c,id) | ld2_in_string_list(id,active) then
            [tx,ty]=ld2_terminal_xy(phase,id); ports($+1,:)=[tx+0.014 ty+0.019 36 40];
        end
    end
    parent.user_data=struct("ports",ports);
    student_begin_wires(parent);
    ld2_text(parent,[0.04 0.87 0.9 0.065],phase+" grandinė",19,%t,"left",[1 1 1],[0.13 0.19 0.23]);
    if step==2 | step==5 | step==8 then tip="Sujunkite mygtuku apačioje arba spauskite paryškintus kontaktus.";
    else
        [action,ready]=ld2_auto_stage_status(step);
        if ready then tip="Bandymas atliktas. Peržiūrėkite rodmenis ir atsakymą dešinėje.";
        else tip="Paleiskite bandymą apačioje. Rodmenys įsirašo automatiškai.";end
    end
    ld2_text(parent,[0.04 0.79 0.92 0.065],student_wrap(tip,72),14,%f,"left",[1 1 1],[0.38 0.45 0.48]);
    for k=1:size(c,1); ld2_draw_connection(parent,phase,c(k,1),c(k,2)); end
    if phase=="RC" then
        ld2_draw_chain_common(parent,phase,msprintf("R8 = %.0f Ω",LD2.cfg.R8), ...
            msprintf("C2 = %.2f µF",LD2.cfg.C2*1e6),"R8","C2",active,c);
    elseif phase=="RL" then
        ld2_draw_chain_common(parent,phase,msprintf("R9 = %.0f Ω",LD2.cfg.R9), ...
            msprintf("L1 = %.2f H",LD2.cfg.L1),"R9","L1",active,c);
    else ld2_draw_rlc_chain(parent,active,c); end
    h=student_end_wires(parent); if h<>[] then ld2_track(h); end
endfunction

function ld2_draw_overview(parent)
    ld2_text(parent,[0.06 0.79 0.88 0.10],"Vienas stendas. Trys tyrimai.",27,%t,"left",[1 1 1],[0.13 0.19 0.23]);
    names=["RC";"RL";"RLC"]; desc=["Rezistorius + kondensatorius";"Rezistorius + ritė";"Rezonanso tyrimas"];
    for k=1:3
        y=0.60-(k-1)*0.19;
        fr=ld2_frame(parent,[0.06 y 0.88 0.145],[0.95 0.97 0.97]);
        ld2_text(fr,[0.05 0.2 0.17 0.6],names(k),27,%t,"left",[0.95 0.97 0.97],[0.08 0.39 0.37]);
        ld2_text(fr,[0.24 0.2 0.71 0.6],desc(k),19,%f,"left",[0.95 0.97 0.97],[0.13 0.19 0.23]);
    end
endfunction
