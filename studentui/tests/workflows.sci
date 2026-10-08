// Exercise normal student actions. Never mark a stage completed directly.
function bench_button(h)
    assert_checkequal(h.enable,"on");
    assert_checkequal(h.visible,"on");
    execstr(h.callback);
endfunction

function bench_ld1_click(id)
    global LD1;
    k=find(LD1.term.handleIds==id);
    assert_checktrue(size(k,"*")>0);
    bench_button(LD1.term.handles(k(1)));
endfunction

function bench_ld1_answers(values)
    global LD1;
    for k=1:size(values,"*")
        LD1.ui.qEdit(k).string=msprintf("%.12g",values(k));
        execstr(LD1.ui.qEdit(k).callback);
    end
endfunction

function bench_ld1_workflow(n,root)
    global LD1;
    cfg=ld1_variant_config(n);
    LD1=struct("base",root+"tests/results/","cfg",cfg,"student",student_profile(n,"Automatinė Patikra","TEST","LD1"));
    ld1_start();
    LD1.fig.figure_name="PATIKRA · LD1 · variantas "+string(n);
    for step=1:8
        assert_checkequal(LD1.step,step);
        if step==1 | step==5 then
            if step==1 then W=ld1_series_canonical_wires(); else W=ld1_parallel_voltage_canonical_wires(); end
            for k=1:size(W,1); bench_ld1_click(W(k,1)); bench_ld1_click(W(k,2)); end
            if step==1 then LD1.ui.typeSeries.value=1; execstr(LD1.ui.typeSeries.callback);
            else bench_button(LD1.ui.modeV); LD1.ui.typeParallel.value=1; execstr(LD1.ui.typeParallel.callback); end
        elseif step==2 then
            bench_ld1_answers([cfg.R1+1000 cfg.E/(cfg.R1+1000)*1000]);
        elseif step==3 then
            bench_button(LD1.ui.power); bench_button(LD1.ui.measure);
            LD1.ui.yes.value=1; execstr(LD1.ui.yes.callback);
        elseif step==4 then
            bench_button(LD1.ui.vr500);
            bench_ld1_answers([cfg.R1+500 cfg.E/(cfg.R1+500)*1000]);
            bench_button(LD1.ui.measure); LD1.ui.yes.value=1; execstr(LD1.ui.yes.callback);
        elseif step==6 then
            bench_ld1_answers(cfg.R3*(cfg.R2+1000)/(cfg.R3+cfg.R2+1000));
            bench_button(LD1.ui.power); bench_button(LD1.ui.measure);
            LD1.ui.yes.value=1; execstr(LD1.ui.yes.callback);
        elseif step==7 then
            ld1_set_vr(500); bench_button(LD1.ui.measure);
            LD1.ui.no.value=1; LD1.ui.yes.value=0; execstr(LD1.ui.no.callback);
        elseif step==8 then
            bench_button(LD1.ui.modeA); bench_button(LD1.ui.vr0);
            bench_ld1_click("SRC_P"); bench_ld1_click("M_P");
            bench_ld1_click("M_N"); bench_ld1_click(LD1.kclTargetA);
            i1=cfg.E/cfg.R3*1000; i2=cfg.E/cfg.R2*1000;
            bench_ld1_answers([i1 i2 i1+i2]);
            bench_button(LD1.ui.power); bench_button(LD1.ui.measure);
            LD1.ui.yes.value=1; LD1.ui.no.value=0; execstr(LD1.ui.yes.callback);
        end
        bench_button(LD1.ui.checkStep);
        if ~LD1.done(step) then error("LD1 V"+string(n)+" etapas "+string(step)+": "+LD1.ui.statusMain.string); end
        if step==2 then
            saved=LD1.ui.qEdit(2).string; LD1.ui.qEdit(2).string="0";
            execstr(LD1.ui.qEdit(2).callback); assert_checkfalse(LD1.done(2));
            bench_button(LD1.ui.checkStep); assert_checkfalse(LD1.done(2));
            LD1.ui.qEdit(2).string=saved; execstr(LD1.ui.qEdit(2).callback);
            bench_button(LD1.ui.checkStep); assert_checktrue(LD1.done(2));
        end
        if step==4 then
            saved=LD1.wires; savedText=LD1.ui.qEdit(2).string;
            ld1_toggle_solution(); assert_checktrue(LD1.demoMode);
            bench_button(LD1.ui.checkStep); assert_checkfalse(LD1.demoMode);
            assert_checkequal(LD1.wires,saved); assert_checkequal(LD1.ui.qEdit(2).string,savedText);
        end
        bench_button(LD1.ui.checkStep);
        mprintf("PASS LD1 V%02d: etapas %d\n",n,step);
    end
    assert_checkequal(LD1.step,9); assert_checktrue(and(LD1.done));
    bench_button(LD1.ui.checkStep);
    ld1_export_results(); // Legacy CSV remains available for compatibility.
    exported=mgetl(LD1.base+LD1.student.variant_id+"_rezultatai.csv");
    assert_checktrue(or(exported=="Variantas;"+ascii(34)+LD1.student.variant_id+ascii(34)));
    // Same variant identity edits retain work; changing variant resets it.
    st=student_profile(n,"Pataisytas Vardas","TEST-2","LD1"); ld1_apply_profile(st,cfg);
    assert_checktrue(and(LD1.done));
    st=student_profile(modulo(n,64)+1,"Kitas Studentas","TEST","LD1");
    ld1_apply_profile(st,ld1_variant_config(st.number)); assert_checkfalse(or(LD1.done));
    assert_checkequal(LD1.step,1); assert_checkequal(size(LD1.wires,1),0);
    delete(LD1.fig);
endfunction

function bench_ld2_action(callback)
    global LD2;
    if LD2.ui.headless then execstr(callback); return; end
    for k=1:size(LD2.ui.dynamic,"*")
        h=LD2.ui.dynamic(k);
        if h.callback==callback then bench_button(h); return; end
    end
    error("Nėra matomo mygtuko: "+callback);
endfunction

function bench_ld2_click(id)
    bench_ld2_action(msprintf("ld2_terminal_click(""%s"")",id));
endfunction

function bench_ld2_probe(phase,target)
    // The same action as the instrument's Remove probes button.
    bench_ld2_action("ld2_remove_voltage_probes()");
    pair=ld2_probe_pair(phase,target);
    bench_ld2_click("VM_H"); bench_ld2_click(pair(1));
    bench_ld2_click("VM_L"); bench_ld2_click(pair(2));
endfunction

function bench_ld2_answers(step,values)
    global LD2;
    if LD2.ui.headless then ld2_test_answers(step,values); return; end
    for k=1:size(values,"*")
        LD2.ui.answer_edits(k).string=msprintf("%.12g",values(k));
        execstr(LD2.ui.answer_edits(k).callback);
    end
endfunction

function bench_ld2_primary()
    global LD2;
    if LD2.ui.headless then ld2_student_primary();
    else bench_button(LD2.ui.studentPrimary); end
endfunction

function bench_ld2_workflow(n,root,gui)
    global LD2;
    cfg=ld2_variant_config(n);
    LD2=struct("root",root,"cfg",cfg,"state",ld2_initial_state(cfg), ...
        "ui",struct("headless",~gui,"suppress_render",%f,"dynamic",[],"answer_edits",[],"answer_step",0,"test_no_dialogs",%t), ...
        "example_active",%f,"example_backup",struct());
    LD2.state.student=student_profile(n,"Automatinė Patikra","TEST","LD2");
    if gui then
        ld2_build_gui(); LD2.ui.figure.figure_name="PATIKRA · LD2 · variantas "+string(n);
        assert_checkequal(LD2.ui.figure.closerequestfcn,"ld2_student_close()");
    end
    ld2_go_step(1,%f);
    rc=ld2_rc_values(cfg.E_RC,cfg.F_RC,cfg.R8,cfg.C2);
    rl=ld2_rl_values(cfg.E_RL,cfg.F_RL,cfg.R9,cfg.L1);
    rr=ld2_peak_reference(cfg);
    for step=1:12
        assert_checkequal(LD2.state.step,step);
        phase=ld2_phase_for_step(step);
        if step==2 | step==5 | step==8 then
            W=ld2_required_main(phase);
            for k=1:size(W,1); bench_ld2_click(W(k,1)); bench_ld2_click(W(k,2)); end
        elseif step==3 then
            bench_ld2_answers(step,[rc.X rc.Z rc.I*1000 rc.UR rc.UX rc.P*1000 rc.PHI_I]);
        elseif step==6 then
            bench_ld2_answers(step,[rl.X rl.Z rl.I*1000 rl.UR rl.UX rl.P*1000 rl.PHI_I]);
        elseif step==4 | step==7 then
            bench_ld2_action("ld2_power_toggle()"); bench_ld2_action("ld2_measure_current()");
            if step==4 then targets=["UR" "UC" "UE"]; r=rc; e=cfg.E_RC;
            else targets=["UR" "UL" "UE"]; r=rl; e=cfg.E_RL; end
            for target=targets; bench_ld2_probe(phase,target); bench_ld2_action("ld2_measure_voltage()"); end
            bench_ld2_answers(step,[e r.I*1000]);
        elseif step==9 then
            bench_ld2_probe("RLC","UR"); bench_ld2_action("ld2_power_toggle()");
            for f=[rr.F0-rr.BW/2 rr.F0 rr.F0+rr.BW/2]
                ld2_set_frequency(f); bench_ld2_action("ld2_measure_voltage()"); bench_ld2_action("ld2_record_resonance_point()");
            end
            bench_ld2_answers(step,[rr.F0 rr.F0 1000/rr.F0 cfg.E_RLC]);
        elseif step==10 then
            targets=["UL" "UC" "ULC"]; centers=[rr.FL rr.FC rr.F0];
            for j=1:3
                bench_ld2_probe("RLC",targets(j));
                for f=[centers(j)-rr.BW/2 centers(j) centers(j)+rr.BW/2]
                    ld2_set_frequency(f); bench_ld2_action("ld2_measure_voltage()"); bench_ld2_action("ld2_record_peak_point()");
                end
            end
            [fl,ul,yes]=ld2_peak_best("UL"); [fc,uc,yes]=ld2_peak_best("UC"); [fz,uz,yes]=ld2_peak_best("ULC");
            bench_ld2_answers(step,[ul uc uz fl fc fz]);
        elseif step==11 then
            bench_ld2_probe("RLC","UR");
            ld2_set_frequency(rr.F1); bench_ld2_action("ld2_measure_voltage()"); bench_ld2_action("ld2_record_f1()");
            ld2_set_frequency(rr.F2); bench_ld2_action("ld2_measure_voltage()"); bench_ld2_action("ld2_record_f2()");
            bench_ld2_answers(step,[cfg.E_RLC/sqrt(2) rr.F1 rr.F2 rr.BW rr.Q]);
        elseif step==12 then
            bench_ld2_probe("RLC","UR"); bench_ld2_action("ld2_run_sweep()");
        end
        bench_ld2_primary();
        if LD2.state.completed(step)<>1 then error("LD2 V"+string(n)+" etapas "+string(step)+": "+LD2.state.last_error); end
        if gui & step==3 then
            saved=LD2.ui.answer_edits(1).string;
            LD2.ui.answer_edits(1).string="0"; execstr(LD2.ui.answer_edits(1).callback);
            bench_ld2_primary(); assert_checkequal(LD2.state.completed(3),0);
            assert_checktrue(LD2.state.last_error<>"");
            LD2.ui.answer_edits(1).string=saved; execstr(LD2.ui.answer_edits(1).callback);
            bench_ld2_primary(); assert_checkequal(LD2.state.completed(3),1);
        end
        if step>1 & step<12 then bench_ld2_primary(); end
        if gui then mprintf("PASS LD2 V%02d: etapas %d\n",n,step); end
    end
    assert_checktrue(and(LD2.state.completed==1));
    assert_checktrue(length(LD2.state.measurements)>=30);
    assert_checkequal(LD2.state.student.number,n);
    if gui then
        // Formal assessment accepts nonempty raw text without local correctness disclosure.
        clean=LD2.state; LD2.state.assessment=%t; LD2.state.practice_used=%f;
        mprintf("PASS LD2 V17: postflow baseline\n");
        ld2_go_step(3,%f); LD2.state.completed(3)=0;
        mprintf("PASS LD2 V17: reopened step 3\n");
        LD2.ui.answer_edits(1).string="0"; execstr(LD2.ui.answer_edits(1).callback);
        mprintf("PASS LD2 V17: numeric wrong edit callback\n");
        bench_ld2_primary();
        mprintf("PASS LD2 V17: assessment numeric wrong accepted\n");
        assert_checkequal(LD2.state.step,4); assert_checkequal(LD2.state.completed(3),1);
        assert_checkequal(LD2.state.answers_text(3,1),"0");
        // Neskaitinis tekstas yra pilnumo / formato klaida, bet neatskleidžia etalono.
        ld2_go_step(3,%f); LD2.state.completed(3)=0;
        LD2.ui.answer_edits(1).string="raw-wrong"; execstr(LD2.ui.answer_edits(1).callback);
        bench_ld2_primary();
        assert_checkequal(LD2.state.step,3); assert_checkequal(LD2.state.completed(3),0);
        assert_checktrue(strindex(LD2.state.status_text,"skaičių")<>[]);
        mprintf("PASS LD2 V17: assessment rejects nonnumeric text without answer key\n");
        // Restore the fully correct state and verify formal example blocking/export.
        LD2.state=clean; LD2.state.assessment=%t; LD2.state.practice_used=%f; LD2.state.completed(11)=0; LD2.state.step=12; ld2_render_step();
        assert_checkfalse(ld2_assessment_ready());
        assert_checktrue(strindex(LD2.state.status_text,"ankstesnių etapų")<>[]);
        mprintf("PASS LD2 V17: final export blocked by unfinished prior stage\n");
        LD2.state=clean; LD2.state.assessment=%t; LD2.state.practice_used=%f; ld2_render_step();
        ld2_show_solution(); assert_checkfalse(LD2.example_active); assert_checkfalse(LD2.state.practice_used);
        mprintf("PASS LD2 V17: formal example block\n");
        bench_ld2_primary();
        if isempty(strindex(LD2.ui.status.string,"Ataskaita išsaugota")) then
            mprintf("LD2 export diagnostic: "+LD2.state.status_text+" | "+LD2.state.status_hint+"\n");
        end
        assert_checktrue(strindex(LD2.state.status_text,"Ataskaita išsaugota")<>[]);
        assert_checktrue(strindex(LD2.ui.status.string,"Ataskaita išsaugota")<>[]);
        mprintf("PASS LD2 V17: formal report export\n");
        ld2_write_exports(root+"tests/results/");
        mprintf("PASS LD2 V17: CSV exports\n");
        ld2_write_session(root+"tests/results/LD2-test.sod");
        mprintf("PASS LD2 V17: session write\n");
        session=ld2_read_session(root+"tests/results/LD2-test.sod");
        mprintf("PASS LD2 V17: session read\n");
        assert_checkequal(session.state.student,LD2.state.student);
        assert_checktrue(session.state.assessment); assert_checkfalse(session.state.practice_used);
        ld2_restore_session(session);
        mprintf("PASS LD2 V17: formal session restore\n");
        assert_checktrue(and(LD2.state.completed==1)); assert_checktrue(LD2.state.assessment);
        assert_checkfalse(LD2.state.power);
        // Mokymosi bandymas lieka mokomasis. IŠ NAUJO pradeda švarų formalų bandymą.
        LD2.state.assessment=%f; LD2.state.practice_used=%t;
        ld2_show_solution(); assert_checktrue(LD2.example_active);
        mprintf("PASS LD2 V17: learning example open\n");
        bench_ld2_primary(); assert_checkfalse(LD2.example_active); assert_checktrue(LD2.state.practice_used);
        mprintf("PASS LD2 V17: learning example close\n");
        ld2_restart_apply(); assert_checktrue(LD2.state.assessment); assert_checkfalse(LD2.state.practice_used);
        assert_checkequal(LD2.state.step,1); assert_checkequal(length(LD2.state.measurements),0);
        assert_checktrue(isfield(LD2,"autosave_paths")); assert_checkequal(size(LD2.autosave_paths,"*"),0);
        mprintf("PASS LD2 V17: restart creates clean assessment and autosave chain\n");
        ld2_step_button(5); assert_checkequal(LD2.state.step,1);
        assert_checktrue(strindex(LD2.state.status_text,"dar nepasiekėte")<>[]);
        assert_checktrue(strindex(LD2.state.status_text,"DĖSTYTOJO")==[]);
        mprintf("PASS LD2 V17: future-stage navigation is student-facing\n");
        ld2_restore_session(session);
        mprintf("PASS LD2 V17: second session restore\n");
        st=student_profile(n,"Pataisytas Vardas","TEST-2","LD2"); ld2_apply_profile(st,cfg);
        mprintf("PASS LD2 V17: same variant profile\n");
        assert_checktrue(and(LD2.state.completed==1)); assert_checktrue(LD2.state.assessment);
        st=student_profile(modulo(n,64)+1,"Kitas Studentas","TEST","LD2");
        ld2_apply_profile(st,ld2_variant_config(st.number));
        mprintf("PASS LD2 V17: new variant profile\n");
        assert_checkequal(length(LD2.state.measurements),0); assert_checkequal(LD2.state.step,1);
        assert_checktrue(LD2.state.assessment); assert_checkfalse(LD2.state.practice_used);
        ld2_student_close(); assert_checkfalse(is_handle_valid(LD2.ui.figure));
        mprintf("PASS LD2 V17: close autosave path\n");
    end
endfunction

function bench_ld3_action(callback)
    global LD3;
    if LD3.ui.headless then execstr(callback); return; end
    if isfield(LD3.ui,"dynamic") then
        for k=1:size(LD3.ui.dynamic,"*")
            h=LD3.ui.dynamic(k);
            if h.callback==callback then bench_button(h); return; end
        end
    end
    error("Nėra matomo mygtuko: "+callback);
endfunction

function bench_ld3_click(id)
    bench_ld3_action(msprintf("ld3_terminal_click(""%s"")",id));
endfunction

function bench_ld3_primary()
    // LD3 mirrors LD2: one primary button per stage with callback ld3_student_primary().
    global LD3;
    if LD3.ui.headless then ld3_student_primary(); return; end
    if isfield(LD3.ui,"studentPrimary") then bench_button(LD3.ui.studentPrimary); return; end
    bench_ld3_action("ld3_student_primary()");
endfunction

function bench_ld3_answers(step,values)
    // GUI checks must type into visible fields, not bypass the edit callbacks.
    global LD3;
    for k=1:size(values,"*")
        if LD3.ui.headless then
            LD3.answers(step,k)=msprintf("%.12g",values(k));
        else
            for j=1:8
                [st,sl]=ld3_answer_slot(j);
                if st==step & sl==k then
                    h=LD3.ui.answerEdits(j); assert_checkequal(h.visible,"on");
                    h.string=msprintf("%.12g",values(k)); execstr(h.callback);
                end
            end
        end
    end
endfunction

function bench_ld3_workflow(n,root,gui)
    global LD3;
    if argn(2)<3 then gui=%f; end
    cfg=ld3_variant_config(n);
    [valid,why]=ld3_validate_config(cfg);
    assert_checktrue(valid);
    LD3=struct("cfg",cfg,"student",student_profile(n,"Automatinė Patikra","TEST","LD3"), ...
        "ui",struct("headless",~gui));
    ld3_start();
    if gui then mprintf("LD3 V%02d: start PASS\n",n); end
    assert_checktrue(LD3.assessment);
    assert_checkfalse(LD3.practice_used);
    if gui then
        assert_checktrue(LD3.autosave_enabled);
        if isfield(LD3.ui,"figure") then LD3.ui.figure.figure_name="PATIKRA · LD3 · variantas "+string(n);
        elseif isfield(LD3,"fig") then
            LD3.fig.figure_name="PATIKRA · LD3 · variantas "+string(n);
            assert_checkequal(LD3.fig.closerequestfcn,"ld3_close()");
        end
        assert_checktrue(strindex(LD3.ui.answerLabels(1).string,"[A")==[]);
        if n==17 then
            // Formal assessment must not reveal the example.
            ld3_toggle_solution(); assert_checkfalse(LD3.demoMode); assert_checkfalse(LD3.practice_used);
            mprintf("LD3 V17: formal example block PASS\n");
        end
    end
    W=["E_P" "K1";"K2" "A_P";"A_N" "R1A";"R1B" "E_N";"V_P" "R1A";"V_N" "R1B"];
    u=[cfg.U1 cfg.U2 cfg.U3];
    for step=1:6
        assert_checkequal(LD3.step,step);
        primary_done=%f;
        select step
        case 1 then
            for k=1:size(W,1); bench_ld3_click(W(k,1)); bench_ld3_click(W(k,2)); end
        case 2 then
            bench_ld3_answers(step,u(1)/cfg.R*1000);
            bench_ld3_action("ld3_toggle_power()");
            bench_ld3_action("ld3_toggle_switch()");
            ld3_set_voltage(u(1)); bench_ld3_action("ld3_measure()");
            if gui & n==17 then
                // Assessment keeps the student's wrong raw value and advances
                // without showing the correct value locally.
                LD3.ui.answerEdits(1).string="0";
                bench_ld3_primary();
                assert_checktrue(LD3.done(2)); assert_checkequal(LD3.step,3);
                assert_checkequal(LD3.answers(2,1),"0");
                assert_checktrue(strindex(LD3.ui.statusMain.string,"Tikimasi")==[]); assert_checktrue(strindex(LD3.ui.statusFix.string,"Tikimasi")==[]);
                // Neskaitinis tekstas yra formato klaida, bet etalonas neatskleidžiamas.
                ld3_jump_step(2);
                LD3.ui.answerEdits(1).string="raw-wrong"; execstr(LD3.ui.answerEdits(1).callback);
                bench_ld3_primary();
                assert_checkfalse(LD3.done(2)); assert_checkequal(LD3.step,2);
                assert_checktrue(strindex(LD3.ui.statusMain.string,"skaičius")<>[]);
                assert_checktrue(strindex(LD3.ui.statusMain.string,"Tikimasi")==[]);
                // Restore a correct raw answer so the exported acceptance fixture
                // remains a perfect report.
                LD3.ui.answerEdits(1).string=msprintf("%.12g",u(1)/cfg.R*1000);
                execstr(LD3.ui.answerEdits(1).callback);
                assert_checkfalse(LD3.done(2));
                bench_ld3_primary();
                assert_checktrue(LD3.done(2)); assert_checkequal(LD3.step,3);
                primary_done=%t;
            end
        case 3 then
            for k=2:3
                ld3_set_voltage(u(k)); bench_ld3_action("ld3_measure()");
            end
        case 4 then
            r=[LD3.journal(1,1)*1000/LD3.journal(1,2) LD3.journal(2,1)*1000/LD3.journal(2,2) LD3.journal(3,1)*1000/LD3.journal(3,2)];
            bench_ld3_answers(step,[r(1) r(2) r(3) (r(1)+r(2)+r(3))/3]);
        case 5 then
            bench_ld3_answers(step,(LD3.journal(3,1)-LD3.journal(1,1))/((LD3.journal(3,2)-LD3.journal(1,2))/1000));
        case 6 then
            bench_ld3_answers(step,[1 1]);
        end
        if ~primary_done then bench_ld3_primary(); end
        if ~LD3.done(step) then
            detail="";
            if isfield(LD3.ui,"statusMain") then detail=": "+LD3.ui.statusMain.string; end
            error("LD3 V"+string(n)+" etapas "+string(step)+detail);
        end
        if step==3 then
            assert_checkequal(size(LD3.journal,1),3);
            for k=1:3
                assert_checkalmostequal(LD3.journal(k,1),u(k),1e-3,1e-3);
                assert_checkalmostequal(LD3.journal(k,2),u(k)/cfg.R*1000,1e-3,1e-3);
            end
        end
        if gui then mprintf("PASS LD3 V%02d: etapas %d\n",n,step); end
    end
    assert_checktrue(and(LD3.done));
    assert_checkequal(LD3.student.number,n);
    if gui then
        if n==17 then
            // Snapshot restore keeps formal state and raw work, but powers down.
            saved=bench_snapshot("LD3");
            keep=LD3.answers(5,1); LD3.answers(5,1)="sugadinta";
            bench_restore_snapshot(saved);
            assert_checkequal(LD3.answers(5,1),keep);
            assert_checktrue(LD3.assessment); assert_checkfalse(LD3.powerOn); assert_checkfalse(LD3.switchOn);
        end
        // Galutinė ataskaita negali apeiti ankstesnio neužbaigto etapo.
        LD3.done(5)=%f; LD3.step=6; ld3_render_stage();
        bench_ld3_primary();
        assert_checktrue(strindex(LD3.ui.statusMain.string,"ankstesnių etapų")<>[]);
        LD3.done(5)=%t; ld3_render_stage();
        bench_ld3_primary();
        assert_checktrue(strindex(LD3.ui.statusMain.string,"Ataskaita išsaugota")<>[]);
        if n==17 then
            // Naujas bandymas po mokymosi turi būti švarus formalus atsiskaitymas.
            LD3.assessment=%f; LD3.practice_used=%t; ld3_restart();
            assert_checktrue(LD3.assessment); assert_checkfalse(LD3.practice_used);
            assert_checkequal(LD3.step,1); assert_checkequal(size(LD3.journal,1),0);
            assert_checktrue(size(LD3.autosave_paths,"*")>=1);
            // Toliau sąmoningai persijungiame į mokymąsi ir tikriname vietinį grįžtamąjį ryšį.
            LD3.assessment=%f; LD3.practice_used=%t; ld3_student_sync();
            for k=1:size(W,1); bench_ld3_click(W(k,1)); bench_ld3_click(W(k,2)); end
            bench_ld3_primary(); assert_checkequal(LD3.step,2);
            bench_ld3_action("ld3_toggle_power()"); bench_ld3_action("ld3_toggle_switch()");
            ld3_set_voltage(u(1)); bench_ld3_action("ld3_measure()");
            LD3.ui.answerEdits(1).string="0"; bench_ld3_primary();
            assert_checkfalse(LD3.done(2)); assert_checkequal(LD3.step,2);
            assert_checktrue(strindex(LD3.ui.statusFix.string,"Tikimasi")<>[]);
            ld3_toggle_solution(); assert_checktrue(LD3.demoMode); assert_checktrue(LD3.practice_used);
            ld3_toggle_solution(); assert_checkfalse(LD3.demoMode);
        end
        assert_checktrue(isfield(LD3,"autosave_paths"));
        assert_checktrue(size(LD3.autosave_paths,"*")>=1);
        // To paties varianto duomenų taisymas nepraranda darbo.
        before=LD3.done;
        st=student_profile(n,"Pataisytas Vardas","TEST-2","LD3");
        ld3_apply_profile(st,cfg);
        assert_checkequal(LD3.done,before); assert_checkequal(LD3.student.name,"Pataisytas Vardas");
        // Kitas variantas pradeda švarų darbą, bet išsaugo pasirinktą režimą.
        st=student_profile(modulo(n,64)+1,"Kitas Studentas","TEST","LD3");
        ld3_apply_profile(st,ld3_variant_config(st.number));
        assert_checkequal(LD3.step,1); assert_checkfalse(or(LD3.done));
        assert_checkequal(size(LD3.journal,1),0);
        // Varianto keitimas išsaugo studento pasirinktą mokymosi / atsiskaitymo režimą.
        assert_checkfalse(LD3.assessment); assert_checktrue(LD3.practice_used);
        mprintf("PASS LD3 V17: student data and variant change\n");
        ld3_close();
        assert_checkfalse(is_handle_valid(LD3.fig));
    end
endfunction

// ------------------------------- LD4 ----------------------------------------
function bench_ld4_action(callback)
    global LD4;
    if LD4.ui.headless then execstr(callback); return; end
    for k=1:size(LD4.ui.dynamic,"*")
        h=LD4.ui.dynamic(k);
        if h.callback==callback then bench_button(h); return; end
    end
    error("Nėra matomo LD4 mygtuko: "+callback);
endfunction

function bench_ld4_click(id)
    bench_ld4_action(msprintf("ld4_terminal_click(""%s"")",id));
endfunction

function bench_ld4_primary()
    global LD4;
    if LD4.ui.headless then ld4_student_primary();
    else bench_button(LD4.ui.studentPrimary); end
endfunction

function bench_ld4_answers(step,values)
    global LD4;
    if LD4.ui.headless then ld4_test_answers(step,values); return; end
    vi=1;
    for k=1:11
        [st,sl]=ld4_answer_slot_global(k);
        if st==step & vi<=size(values,"*") then
            LD4.ui.answerEdits(k).string=msprintf("%.12g",values(vi));
            execstr(LD4.ui.answerEdits(k).callback);
            vi=vi+1;
        end
    end
endfunction

function [st,sl]=ld4_answer_slot_global(k)
    mapa=[2 1;4 1;4 2;4 3;4 4;5 1;5 2;5 3;6 1;7 1;7 2];
    st=mapa(k,1); sl=mapa(k,2);
endfunction

function bench_ld4_workflow(n,root,gui)
    global LD4;
    if argn(2)<3 then gui=%f; end
    cfg=ld4_variant_config(n);
    [valid,why]=ld4_validate_config(cfg);
    assert_checktrue(valid);
    LD4=struct("cfg",cfg,"student",student_profile(n,"Automatinė Patikra","TEST","LD4"), ...
        "ui",struct("headless",~gui));
    ld4_start();
    assert_checktrue(LD4.assessment);
    assert_checkfalse(LD4.practice_used);
    if gui then
        assert_checktrue(LD4.autosave_enabled);
        if isfield(LD4,"fig") then
            LD4.fig.figure_name="PATIKRA · LD4 · variantas "+string(n);
            assert_checkequal(LD4.fig.closerequestfcn,"ld4_close()");
        end
        assert_checktrue(strindex(LD4.ui.answerLabels(1).string,"[A")==[]);
        if n==17 then
            ld4_toggle_solution(); assert_checkfalse(LD4.demoMode); assert_checkfalse(LD4.practice_used);
        end
    end
    W=["E_P" "K1";"K2" "A_P";"A_N" "R1A";"R1B" "E_N";"V_P" "R1A";"V_N" "R1B"];
    u=[cfg.U1 cfg.U2 cfg.U3];
    for step=1:7
        assert_checkequal(LD4.step,step);
        primary_done=%f;
        select step
        case 1 then
            for k=1:size(W,1); bench_ld4_click(W(k,1)); bench_ld4_click(W(k,2)); end
        case 2 then
            bench_ld4_answers(step,u(1)/cfg.R1nom*1000);
            bench_ld4_action("ld4_toggle_power()");
            bench_ld4_action("ld4_toggle_switch()");
            for k=3:-1:1
                bench_ld4_action(msprintf("ld4_set_voltage(LD4.cfg.U%d)",k)); bench_ld4_action("ld4_measure()");
            end
            if gui & n==17 then
                // Formal assessment keeps an incorrect raw answer and does not reveal the key.
                LD4.ui.answerEdits(1).string="0";
                bench_ld4_primary();
                assert_checktrue(LD4.done(2)); assert_checkequal(LD4.step,3);
                assert_checkequal(LD4.answers(2,1),"0");
                assert_checktrue(strindex(LD4.ui.statusMain.string,"Tikimasi")==[]); assert_checktrue(strindex(LD4.ui.statusFix.string,"Tikimasi")==[]);
                assert_checkfalse(LD4.powerOn); assert_checkfalse(LD4.switchOn);
                // Neskaitinis tekstas yra formato klaida, bet etalonas neatskleidžiamas.
                ld4_jump_step(2);
                LD4.ui.answerEdits(1).string="raw-wrong"; execstr(LD4.ui.answerEdits(1).callback);
                bench_ld4_primary();
                assert_checkfalse(LD4.done(2)); assert_checkequal(LD4.step,2);
                assert_checktrue(strindex(LD4.ui.statusMain.string,"skaičius")<>[]);
                assert_checktrue(strindex(LD4.ui.statusMain.string,"Tikimasi")==[]);
                // Restore the correct raw answer so the exported acceptance report is perfect.
                LD4.ui.answerEdits(1).string=msprintf("%.12g",u(1)/cfg.R1nom*1000);
                execstr(LD4.ui.answerEdits(1).callback);
                assert_checkfalse(LD4.done(2));
                bench_ld4_primary();
                assert_checktrue(LD4.done(2)); assert_checkequal(LD4.step,3);
                primary_done=%t;
            end
        case 3 then
            assert_checkfalse(LD4.powerOn); assert_checkfalse(LD4.switchOn);
            bench_ld4_action("ld4_set_resistor(2)");
            assert_checkfalse(LD4.powerOn); assert_checkfalse(LD4.switchOn);
            bench_ld4_action("ld4_toggle_power()"); bench_ld4_action("ld4_toggle_switch()");
            for k=1:3
                bench_ld4_action(msprintf("ld4_set_voltage(LD4.cfg.U%d)",k)); bench_ld4_action("ld4_measure()");
            end
        case 4 then
            r1m=(LD4.journal(1,1)/LD4.journal(1,2)+LD4.journal(2,1)/LD4.journal(2,2)+LD4.journal(3,1)/LD4.journal(3,2))/3*1000;
            r2m=(LD4.journal(4,1)/LD4.journal(4,2)+LD4.journal(5,1)/LD4.journal(5,2)+LD4.journal(6,1)/LD4.journal(6,2))/3*1000;
            bench_ld4_answers(step,[r1m r2m (r1m/cfg.R1nom-1)*100 (r2m/cfg.R2nom-1)*100]);
        case 5 then
            r1s=(LD4.journal(3,1)-LD4.journal(1,1))/((LD4.journal(3,2)-LD4.journal(1,2))/1000);
            r2s=(LD4.journal(6,1)-LD4.journal(4,1))/((LD4.journal(6,2)-LD4.journal(4,2))/1000);
            bench_ld4_answers(step,[r1s r2s 1000/r2s]);
        case 6 then
            assert_checkfalse(LD4.powerOn); assert_checkfalse(LD4.switchOn);
            // Remove the old R2 feed/probe through actual terminal callbacks.
            bench_ld4_click("A_N"); bench_ld4_click("R2A");
            bench_ld4_click("V_P"); bench_ld4_click("R2A");
            for wire=["A_N" "R1A";"R1B" "R2A";"V_P" "R1A"]'
                bench_ld4_click(wire(1)); bench_ld4_click(wire(2));
            end
            bench_ld4_action("ld4_toggle_power()"); bench_ld4_action("ld4_toggle_switch()");
            bench_ld4_action("ld4_set_voltage(LD4.cfg.U3)"); bench_ld4_action("ld4_measure()");
            bench_ld4_answers(step,LD4.journal(7,1)/LD4.journal(7,2)*1000);
        case 7 then
            bench_ld4_answers(step,[1 1]);
        end
        if ~primary_done then bench_ld4_primary(); end
        if ~LD4.done(step) then
            detail="";
            if isfield(LD4.ui,"statusMain") then detail=": "+LD4.ui.statusMain.string; end
            error("LD4 V"+string(n)+" etapas "+string(step)+detail);
        end
        if step==3 then assert_checkequal(size(LD4.journal,1),6); end
        if step==6 then
            assert_checkequal(size(LD4.journal,1),7);
            assert_checkalmostequal(LD4.journal(7,2),u(3)/(cfg.R1+cfg.R2)*1000,1e-3,1e-3);
        end
        if gui then mprintf("PASS LD4 V%02d: etapas %d\n",n,step); end
    end
    assert_checktrue(and(LD4.done)); assert_checkequal(LD4.student.number,n);
    if gui then
        if n==17 then
            saved=bench_snapshot("LD4");
            keep=LD4.answers(5,1); LD4.answers(5,1)="sugadinta";
            bench_restore_snapshot(saved);
            assert_checkequal(LD4.answers(5,1),keep);
            assert_checktrue(LD4.assessment); assert_checkfalse(LD4.powerOn); assert_checkfalse(LD4.switchOn);
            mprintf("PASS LD4 V17: snapshot restore\n");
        end
        // Formalios ataskaitos negalima eksportuoti su neužbaigtu ankstesniu etapu.
        LD4.done(6)=%f; LD4.step=7; ld4_render_stage();
        path=ld4_export_report(); assert_checkequal(path,"");
        assert_checktrue(strindex(LD4.ui.statusMain.string,"neužbaigtų")<>[]);
        LD4.done(6)=%t; ld4_render_stage();
        r=bench_report_data("LD4"); assert_checkequal(r.mode,"assessment"); assert_checkfalse(r.practice_used);
        mprintf("PASS LD4 V%02d: report data\n",n);
        // Naudojame tikrąjį perduotą LD_DATA_DIR kelią. Jo neperrašome ir
        // neatkuriame per setenv, nes Windows Unicode kelias turi išlikti bitų tikslumu.
        path=ld4_export_report();
        assert_checktrue(path<>""); assert_checktrue(isfile(path));
        mprintf("PASS LD4 V%02d: export file\n",n);
        if n==17 then
            // Naujas bandymas po mokymosi turi būti švarus formalus atsiskaitymas.
            LD4.assessment=%f; LD4.practice_used=%t; ld4_restart();
            assert_checktrue(LD4.assessment); assert_checkfalse(LD4.practice_used);
            assert_checkequal(LD4.step,1); assert_checkequal(size(LD4.journal,1),0);
            assert_checktrue(size(LD4.autosave_paths,"*")>=1);
            mprintf("PASS LD4 V17: clean assessment restart\n");
            // Toliau sąmoningai persijungiame į mokymąsi ir tikriname vietinį grįžtamąjį ryšį.
            LD4.assessment=%f; LD4.practice_used=%t; ld4_student_sync();
            for k=1:size(W,1); bench_ld4_click(W(k,1)); bench_ld4_click(W(k,2)); end
            bench_ld4_primary(); assert_checkequal(LD4.step,2);
            bench_ld4_action("ld4_toggle_power()"); bench_ld4_action("ld4_toggle_switch()");
            for k=1:3
                bench_ld4_action(msprintf("ld4_set_voltage(LD4.cfg.U%d)",k)); bench_ld4_action("ld4_measure()");
            end
            LD4.ui.answerEdits(1).string="0"; bench_ld4_primary();
            assert_checkfalse(LD4.done(2)); assert_checkequal(LD4.step,2);
            assert_checktrue(strindex(LD4.ui.statusFix.string,"Tikimasi")<>[]);
            mprintf("PASS LD4 V17: learning validation\n");
            ld4_toggle_solution(); assert_checktrue(LD4.demoMode); assert_checktrue(LD4.practice_used);
            ld4_toggle_solution(); assert_checkfalse(LD4.demoMode);
            mprintf("PASS LD4 V17: practice demo\n");
        end
        assert_checktrue(isfield(LD4,"autosave_paths"));
        assert_checktrue(size(LD4.autosave_paths,"*")>=1);
        mprintf("PASS LD4 V%02d: autosave\n",n);
        // To paties varianto duomenų taisymas nepraranda darbo.
        before=LD4.done; beforeAssessment=LD4.assessment; beforePractice=LD4.practice_used;
        st=student_profile(n,"Pataisytas Vardas","TEST-2","LD4");
        ld4_apply_profile(st,cfg);
        assert_checkequal(LD4.done,before); assert_checkequal(LD4.student.name,"Pataisytas Vardas");
        assert_checkequal(LD4.assessment,beforeAssessment); assert_checkequal(LD4.practice_used,beforePractice);
        // Kitas variantas pradeda švarų darbą ir išsaugo pasirinktą režimą.
        st=student_profile(modulo(n,64)+1,"Kitas Studentas","TEST","LD4");
        ld4_apply_profile(st,ld4_variant_config(st.number));
        assert_checkequal(LD4.step,1); assert_checkfalse(or(LD4.done));
        assert_checkequal(size(LD4.journal,1),0);
        assert_checkequal(LD4.assessment,beforeAssessment); assert_checkequal(LD4.practice_used,beforePractice);
        mprintf("PASS LD4 V%02d: student data and variant change\n",n);
        ld4_close();
        if typeof(LD4.fig)=="handle" then error("LD4 V"+string(n)+" close blocked: "+LD4.autosave_error); end
        assert_checktrue(typeof(LD4.fig)<>"handle");
        mprintf("PASS LD4 V%02d: close\n",n);
    end
endfunction

// ------------------------------- LD5 ----------------------------------------
function bench_ld5_action(callback)
    global LD5;
    if LD5.ui.headless then execstr(callback); return; end
    for k=1:size(LD5.ui.dynamic,"*")
        h=LD5.ui.dynamic(k);
        if h.callback==callback then bench_button(h); return; end
    end
    error("Nėra matomo LD5 mygtuko: "+callback);
endfunction

function bench_ld5_click(id)
    bench_ld5_action(msprintf("ld5_terminal_click(""%s"")",id));
endfunction

function bench_ld5_primary()
    global LD5;
    if LD5.ui.headless then ld5_student_primary();
    else bench_button(LD5.ui.studentPrimary); end
endfunction

function bench_ld5_answers(step,values)
    global LD5;
    if LD5.ui.headless then ld5_test_answers(step,values); return; end
    vi=1;
    for k=1:9
        mapa=[2 1;4 1;4 2;4 3;4 4;5 1;5 2;6 1;6 2];
        st=mapa(k,1);
        if st==step & vi<=size(values,"*") then
            LD5.ui.answerEdits(k).string=msprintf("%.12g",values(vi));
            execstr(LD5.ui.answerEdits(k).callback);
            vi=vi+1;
        end
    end
endfunction

function bench_ld5_workflow(n,root,gui)
    global LD5;
    if argn(2)<3 then gui=%f; end
    cfg=ld5_variant_config(n);
    [valid,why]=ld5_validate_config(cfg);
    assert_checktrue(valid);
    LD5=struct("cfg",cfg,"student",student_profile(n,"Automatinė Patikra","TEST","LD5"), ...
        "ui",struct("headless",~gui));
    ld5_start();
    assert_checktrue(LD5.assessment);
    assert_checkfalse(LD5.practice_used);
    if gui then
        assert_checktrue(LD5.autosave_enabled);
        if isfield(LD5,"fig") then
            LD5.fig.figure_name="PATIKRA · LD5 · variantas "+string(n);
            assert_checkequal(LD5.fig.closerequestfcn,"ld5_close()");
        end
        assert_checktrue(strindex(LD5.ui.answerLabels(1).string,"[A")==[]);
        if n==17 then
            ld5_toggle_solution(); assert_checkfalse(LD5.demoMode); assert_checkfalse(LD5.practice_used);
        end
    end
    W=["E_P" "K1";"K2" "A_P";"A_N" "R1A";"R1B" "RVA";"RVB" "E_N";"V_P" "RVA";"V_N" "RVB"];
    rv2=cfg.RV*cfg.P2/100; rv1=cfg.RV*cfg.P1/100; rv3=cfg.RV*cfg.P3/100;
    u2=cfg.E*rv2/(cfg.R1+rv2); u1=cfg.E*rv1/(cfg.R1+rv1); u3=cfg.E*rv3/(cfg.R1+rv3);
    for step=1:6
        assert_checkequal(LD5.step,step);
        primary_done=%f;
        select step
        case 1 then
            for k=1:size(W,1); bench_ld5_click(W(k,1)); bench_ld5_click(W(k,2)); end
            // Removing a real wire must fail checking; reconnect in reverse order.
            bench_ld5_click("V_P"); bench_ld5_click("RVA");
            bench_ld5_primary(); assert_checkfalse(LD5.done(1));
            bench_ld5_click("RVA"); bench_ld5_click("V_P");
        case 2 then
            bench_ld5_answers(step,u2);
            bench_ld5_action("ld5_toggle_power()");
            bench_ld5_action("ld5_toggle_switch()");
            bench_ld5_action("ld5_set_position(2)"); bench_ld5_action("ld5_measure()");
            if gui & n==17 then
                // Formal assessment keeps the student's wrong raw answer and advances
                // without disclosing the expected value locally.
                LD5.ui.answerEdits(1).string="0";
                bench_ld5_primary();
                assert_checktrue(LD5.done(2)); assert_checkequal(LD5.step,3);
                assert_checkequal(LD5.answers(2,1),"0");
                assert_checktrue(strindex(LD5.ui.statusMain.string,"Tikimasi")==[]); assert_checktrue(strindex(LD5.ui.statusFix.string,"Tikimasi")==[]);
                // Neskaitinis tekstas yra formato klaida, bet etalonas neatskleidžiamas.
                ld5_jump_step(2);
                LD5.ui.answerEdits(1).string="raw-wrong"; execstr(LD5.ui.answerEdits(1).callback);
                bench_ld5_primary();
                assert_checkfalse(LD5.done(2)); assert_checkequal(LD5.step,2);
                assert_checktrue(strindex(LD5.ui.statusMain.string,"skaičius")<>[]);
                assert_checktrue(strindex(LD5.ui.statusMain.string,"Tikimasi")==[]);
                // Put the correct raw value back so acceptance exports remain perfect.
                LD5.ui.answerEdits(1).string=msprintf("%.12g",u2);
                execstr(LD5.ui.answerEdits(1).callback);
                assert_checkfalse(LD5.done(2));
                bench_ld5_primary();
                assert_checktrue(LD5.done(2)); assert_checkequal(LD5.step,3);
                primary_done=%t;
            end
        case 3 then
            bench_ld5_action("ld5_set_position(1)"); bench_ld5_action("ld5_measure()");
            bench_ld5_action("ld5_set_position(3)"); bench_ld5_action("ld5_measure()");
        case 4 then
            bench_ld5_answers(step,[u1 u3 u3-u1 (u3-u1)/cfg.E*100]);
        case 5 then
            bench_ld5_answers(step,[cfg.E/(cfg.R1+rv2)*1000 rv2/(cfg.R1+rv2)*100]);
        case 6 then
            bench_ld5_answers(step,[1 1]);
        end
        if ~primary_done then bench_ld5_primary(); end
        if ~LD5.done(step) then
            detail="";
            if isfield(LD5.ui,"statusMain") then detail=": "+LD5.ui.statusMain.string; end
            error("LD5 V"+string(n)+" etapas "+string(step)+detail);
        end
        if step==3 then
            assert_checkequal(size(LD5.journal,1),3);
            for k=1:3
                rvk=cfg.RV*cfg("P"+string(k))/100;
                uk=cfg.E*rvk/(cfg.R1+rvk);
                row=find(LD5.journal(:,3)==k);
                assert_checkalmostequal(LD5.journal(row,1),uk,1e-3,1e-3);
            end
        end
        if gui then mprintf("PASS LD5 V%02d: etapas %d\n",n,step); end
    end
    assert_checktrue(and(LD5.done));
    assert_checkequal(LD5.student.number,n);
    if gui then
        if n==17 then
            saved=bench_snapshot("LD5");
            keep=LD5.answers(5,1); LD5.answers(5,1)="sugadinta";
            bench_restore_snapshot(saved);
            assert_checkequal(LD5.answers(5,1),keep);
            assert_checktrue(LD5.assessment); assert_checkfalse(LD5.powerOn); assert_checkfalse(LD5.switchOn);
        end
        // Formalios ataskaitos negalima eksportuoti su neužbaigtu ankstesniu etapu.
        LD5.done(5)=%f; LD5.step=6; ld5_render_stage();
        path=ld5_export_report(); assert_checkequal(path,"");
        assert_checktrue(strindex(LD5.ui.statusMain.string,"neužbaigtų")<>[]);
        LD5.done(5)=%t; ld5_render_stage();
        r=bench_report_data("LD5"); assert_checkequal(r.mode,"assessment"); assert_checkfalse(r.practice_used);
        before=size(listfiles(bench_documents()+"/*.html"),"*");
        path=ld5_export_report();
        assert_checktrue(path<>""); assert_checktrue(isfile(path));
        assert_checkequal(size(listfiles(bench_documents()+"/*.html"),"*"),before+1);
        assert_checktrue(strindex(LD5.ui.statusMain.string,"Ataskaita išsaugota")<>[]);
        if n==17 then
            // Naujas bandymas po mokymosi turi būti švarus formalus atsiskaitymas.
            LD5.assessment=%f; LD5.practice_used=%t; ld5_restart();
            assert_checktrue(LD5.assessment); assert_checkfalse(LD5.practice_used);
            assert_checkequal(LD5.step,1); assert_checkequal(size(LD5.journal,1),0);
            assert_checktrue(size(LD5.autosave_paths,"*")>=1);
            // Toliau sąmoningai persijungiame į mokymąsi ir tikriname vietinį grįžtamąjį ryšį.
            LD5.assessment=%f; LD5.practice_used=%t; ld5_student_sync();
            for k=1:size(W,1); bench_ld5_click(W(k,1)); bench_ld5_click(W(k,2)); end
            bench_ld5_primary(); assert_checkequal(LD5.step,2);
            bench_ld5_action("ld5_toggle_power()"); bench_ld5_action("ld5_toggle_switch()");
            bench_ld5_action("ld5_set_position(2)"); bench_ld5_action("ld5_measure()");
            LD5.ui.answerEdits(1).string="0"; bench_ld5_primary();
            assert_checkfalse(LD5.done(2)); assert_checkequal(LD5.step,2);
            assert_checktrue(strindex(LD5.ui.statusFix.string,"Tikimasi")<>[]);
            ld5_toggle_solution(); assert_checktrue(LD5.demoMode); assert_checktrue(LD5.practice_used);
            ld5_toggle_solution(); assert_checkfalse(LD5.demoMode);
        end
        assert_checktrue(isfield(LD5,"autosave_paths"));
        assert_checktrue(size(LD5.autosave_paths,"*")>=1);
        // To paties varianto duomenų taisymas nepraranda darbo.
        beforeDone=LD5.done; beforeAssessment=LD5.assessment; beforePractice=LD5.practice_used;
        st=student_profile(n,"Pataisytas Vardas","TEST-2","LD5");
        ld5_apply_profile(st,cfg);
        assert_checkequal(LD5.done,beforeDone); assert_checkequal(LD5.student.name,"Pataisytas Vardas");
        assert_checkequal(LD5.assessment,beforeAssessment); assert_checkequal(LD5.practice_used,beforePractice);
        // Kitas variantas pradeda švarų darbą ir išsaugo pasirinktą režimą.
        st=student_profile(modulo(n,64)+1,"Kitas Studentas","TEST","LD5");
        ld5_apply_profile(st,ld5_variant_config(st.number));
        assert_checkequal(LD5.step,1); assert_checkfalse(or(LD5.done));
        assert_checkequal(size(LD5.journal,1),0);
        assert_checkequal(LD5.assessment,beforeAssessment); assert_checkequal(LD5.practice_used,beforePractice);
        mprintf("PASS LD5 V%02d: student data and variant change\n",n);
        ld5_close(); assert_checkfalse(is_handle_valid(LD5.fig));
    end
endfunction

// ------------------------------- LD6 ----------------------------------------
function bench_ld6_action(callback)
    global LD6;
    if LD6.ui.headless then execstr(callback); return; end
    for k=1:size(LD6.ui.dynamic,"*")
        h=LD6.ui.dynamic(k);
        if h.callback==callback then bench_button(h); return; end
    end
    error("Nėra matomo LD6 mygtuko: "+callback);
endfunction

function bench_ld6_click(id)
    bench_ld6_action(msprintf("ld6_terminal_click(""%s"")",id));
endfunction

function bench_ld6_primary()
    global LD6;
    if LD6.ui.headless then ld6_student_primary();
    else bench_button(LD6.ui.studentPrimary); end
endfunction

function bench_ld6_answers(step,values)
    global LD6;
    if LD6.ui.headless then ld6_test_answers(step,values); return; end
    value_index=1;
    for index=1:11
        [answer_step,slot]=ld6_answer_slot(index);
        if answer_step==step then
            LD6.ui.answerEdits(index).string=msprintf("%.17g",values(value_index));
            execstr(LD6.ui.answerEdits(index).callback);
            value_index=value_index+1;
        end
    end
endfunction

function bench_ld6_connect(mode)
    global LD6;
    wires=["E1_P" "K1";"K2" "A_P";"A_N" "R_A";"V_P" "R_A";"V_N" "R_B"];
    select mode
    case 1 then wires=[wires;"R_B" "E1_N"];
    case 2 then wires=[wires;"R_B" "E2_N";"E2_P" "E1_N"];
    case 3 then wires=[wires;"R_B" "E2_P";"E2_N" "E1_N"];
    case 4 then wires=[wires;"R_B" "E1_N";"E1_P" "E2_P";"E1_N" "E2_N"];
    end
    assert_checkequal(size(LD6.wires,1),0);
    for index=1:size(wires,1)
        bench_ld6_click(wires(index,1)); bench_ld6_click(wires(index,2));
    end
    bench_ld6_click(wires($,1)); bench_ld6_click(wires($,2));
    [valid,message]=ld6_wiring_valid(LD6.wires); assert_checkfalse(valid);
    bench_ld6_click(wires($,2)); bench_ld6_click(wires($,1));
    [valid,message]=ld6_wiring_valid(LD6.wires); assert_checktrue(valid);
endfunction

function bench_ld6_workflow(number,root,gui)
    global LD6;
    if argn(2)<3 then gui=%f; end
    cfg=ld6_variant_config(number); [valid,message]=ld6_validate_config(cfg); assert_checktrue(valid);
    LD6=struct("cfg",cfg,"student",student_profile(number,"Automatinė Patikra","TEST","LD6"),"ui",struct("headless",~gui));
    ld6_start();
    assert_checktrue(LD6.assessment); assert_checkfalse(LD6.practice_used);
    if gui then
        assert_checktrue(LD6.autosave_enabled);
        if isfield(LD6,"fig") then
            LD6.fig.figure_name="PATIKRA · LD6 · variantas "+string(number);
            assert_checkequal(LD6.fig.closerequestfcn,"ld6_close()");
        end
        assert_checktrue(strindex(LD6.ui.answerLabels(1).string,"[A")==[]);
        if number==17 then
            ld6_toggle_solution(); assert_checkfalse(LD6.demoMode); assert_checkfalse(LD6.practice_used);
        end
    end
    series=(cfg.E1+cfg.E2)/(cfg.R+cfg.r1+cfg.r2);
    opposing=(cfg.E1-cfg.E2)/(cfg.R+cfg.r1+cfg.r2);
    parallel=(cfg.E1/cfg.r1+cfg.E2/cfg.r2)/(1/cfg.R+1/cfg.r1+1/cfg.r2);
    for step=1:6
        assert_checkequal(LD6.step,step);
        primary_done=%f;
        if or(step==[1 3 4 5]) then bench_ld6_connect(ld6_stage_mode(step)); end
        if or(step==[2 3 4 5]) then
            bench_ld6_action("ld6_toggle_power()"); bench_ld6_action("ld6_toggle_switch()"); bench_ld6_action("ld6_measure()");
        end
        select step
        case 2 then bench_ld6_answers(step,cfg.E1/(cfg.R+cfg.r1)*1000);
        case 4 then bench_ld6_answers(step,[series*cfg.R series*1000 opposing*cfg.R opposing*1000]);
        case 5 then
            bench_ld6_answers(step,[parallel parallel/cfg.R*1000 (cfg.E1-parallel)/cfg.r1*1000 (cfg.E2-parallel)/cfg.r2*1000]);
            if gui & number==17 then
                // Formal assessment accepts a wrong numeric value without revealing the key.
                LD6.ui.answerEdits(6).string="0"; execstr(LD6.ui.answerEdits(6).callback);
                bench_ld6_primary();
                assert_checktrue(LD6.done(5)); assert_checkequal(LD6.step,6);
                assert_checkequal(LD6.answers(5,1),"0");
                assert_checktrue(strindex(LD6.ui.statusMain.string,"Patikrinkite")==[]);
                // Nonnumeric text is a format/completeness error.
                ld6_jump_step(5); LD6.done(5)=%f;
                LD6.ui.answerEdits(6).string="1+2"; execstr(LD6.ui.answerEdits(6).callback);
                bench_ld6_primary();
                assert_checkfalse(LD6.done(5)); assert_checkequal(LD6.step,5);
                assert_checktrue(strindex(LD6.ui.statusMain.string,"skaičių")<>[]);
                // Restore the correct answer so the acceptance export remains perfect.
                values=ld6_reference(4); bench_ld6_answers(5,values);
                bench_ld6_primary();
                assert_checktrue(LD6.done(5)); assert_checkequal(LD6.step,6);
                primary_done=%t;
            end
        case 6 then bench_ld6_answers(step,[1 2]);
        end
        if ~primary_done then bench_ld6_primary(); end
        if ~LD6.done(step) then error("LD6 variantas "+string(number)+", etapas "+string(step)); end
        if gui then mprintf("PASS LD6 V%02d: etapas %d\n",number,step); end
    end
    assert_checktrue(and(LD6.done)); assert_checkequal(size(LD6.journal,1),4);
    if gui then
        if number==17 then
            saved=bench_snapshot("LD6");
            keep=LD6.answers(5,1); LD6.answers(5,1)="sugadinta";
            bench_restore_snapshot(saved);
            assert_checkequal(LD6.answers(5,1),keep);
            assert_checktrue(LD6.assessment); assert_checkfalse(LD6.powerOn); assert_checkfalse(LD6.switchOn);
        end
        // Formalios ataskaitos negalima eksportuoti su neužbaigtu ankstesniu etapu.
        LD6.done(5)=%f; LD6.step=6; ld6_render_stage();
        path=ld6_export_report(); assert_checkequal(path,"");
        assert_checktrue(strindex(LD6.ui.statusMain.string,"neužbaigtų")<>[]);
        LD6.done(5)=%t; ld6_render_stage();
        r=bench_report_data("LD6"); assert_checkequal(r.mode,"assessment"); assert_checkfalse(r.practice_used);
        before=size(listfiles(bench_documents()+"/*.html"),"*");
        path=ld6_export_report();
        assert_checktrue(path<>""); assert_checktrue(isfile(path));
        assert_checkequal(size(listfiles(bench_documents()+"/*.html"),"*"),before+1);
        assert_checktrue(strindex(LD6.ui.statusMain.string,"Ataskaita išsaugota")<>[]);
        if number==17 then
            // Naujas bandymas po mokymosi turi būti švarus formalus atsiskaitymas.
            LD6.assessment=%f; LD6.practice_used=%t; ld6_restart();
            assert_checktrue(LD6.assessment); assert_checkfalse(LD6.practice_used);
            assert_checkequal(LD6.step,1); assert_checkequal(size(LD6.journal,1),0);
            assert_checktrue(size(LD6.autosave_paths,"*")>=1);
            // Toliau sąmoningai persijungiame į mokymąsi ir tikriname vietinį grįžtamąjį ryšį.
            LD6.assessment=%f; LD6.practice_used=%t; ld6_student_sync();
            bench_ld6_connect(1); bench_ld6_primary(); assert_checkequal(LD6.step,2);
            bench_ld6_action("ld6_toggle_power()"); bench_ld6_action("ld6_toggle_switch()"); bench_ld6_action("ld6_measure()");
            LD6.ui.answerEdits(1).string="0"; execstr(LD6.ui.answerEdits(1).callback); bench_ld6_primary();
            assert_checkfalse(LD6.done(2)); assert_checkequal(LD6.step,2);
            assert_checktrue(strindex(LD6.ui.statusMain.string,"Patikrinkite")<>[]);
            ld6_toggle_solution(); assert_checktrue(LD6.demoMode); assert_checktrue(LD6.practice_used);
            ld6_toggle_solution(); assert_checkfalse(LD6.demoMode);
        end
        assert_checktrue(isfield(LD6,"autosave_paths")); assert_checktrue(size(LD6.autosave_paths,"*")>=1);
        // To paties varianto duomenų taisymas nepraranda darbo.
        beforeDone=LD6.done; beforeAssessment=LD6.assessment; beforePractice=LD6.practice_used;
        st=student_profile(number,"Pataisytas Vardas","TEST-2","LD6");
        ld6_apply_profile(st,cfg);
        assert_checkequal(LD6.done,beforeDone); assert_checkequal(LD6.student.name,"Pataisytas Vardas");
        assert_checkequal(LD6.assessment,beforeAssessment); assert_checkequal(LD6.practice_used,beforePractice);
        // Kitas variantas pradeda švarų darbą ir išsaugo pasirinktą režimą.
        st=student_profile(modulo(number,64)+1,"Kitas Studentas","TEST","LD6");
        ld6_apply_profile(st,ld6_variant_config(st.number));
        assert_checkequal(LD6.step,1); assert_checkfalse(or(LD6.done));
        assert_checkequal(size(LD6.journal,1),0);
        assert_checkequal(LD6.assessment,beforeAssessment); assert_checkequal(LD6.practice_used,beforePractice);
        mprintf("PASS LD6 V%02d: student data and variant change\n",number);
        ld6_close(); assert_checkfalse(is_handle_valid(LD6.fig));
    end
endfunction

// ------------------------------- LD7 ----------------------------------------
function bench_ld7_action(callback)
    global LD7;
    if LD7.ui.headless then execstr(callback); return; end
    for k=1:size(LD7.ui.dynamic,"*")
        h=LD7.ui.dynamic(k);
        if h.callback==callback then bench_button(h); return; end
    end
    error("Nėra matomo LD7 mygtuko: "+callback);
endfunction

function bench_ld7_click(id)
        bench_ld7_action(msprintf("ld7_terminal_click(""%s"")",id));
endfunction

function bench_ld7_primary()
    global LD7;
    if LD7.ui.headless then ld7_student_primary();
    else bench_button(LD7.ui.studentPrimary); end
endfunction

function bench_ld7_answers(step,values)
    global LD7;
    if LD7.ui.headless then ld7_test_answers(step,values); return; end
    value_index=1;
    for index=1:12
        [answer_step,slot]=ld7_answer_slot(index);
        if answer_step==step then
            LD7.ui.answerEdits(index).string=msprintf("%.17g",values(value_index));
            execstr(LD7.ui.answerEdits(index).callback);
            value_index=value_index+1;
        end
    end
endfunction

function bench_ld7_connect(mode)
    global LD7;
    wires=ld7_canonical_wires(mode);
    assert_checkequal(size(LD7.wires,1),0);
    for index=1:size(wires,1)
        bench_ld7_click(wires(index,1)); bench_ld7_click(wires(index,2));
    end
    bench_ld7_click(wires($,1)); bench_ld7_click(wires($,2));
    [valid,message]=ld7_wiring_valid(LD7.wires); assert_checkfalse(valid);
    bench_ld7_click(wires($,2)); bench_ld7_click(wires($,1));
    [valid,message]=ld7_wiring_valid(LD7.wires); assert_checktrue(valid);
endfunction

function bench_ld7_workflow(number,root,gui)
    global LD7;
    if argn(2)<3 then gui=%f; end
    cfg=ld7_variant_config(number); [valid,message]=ld7_validate_config(cfg); assert_checktrue(valid);
    LD7=struct("cfg",cfg,"student",student_profile(number,"Automatinė Patikra","TEST","LD7"),"ui",struct("headless",~gui));
    ld7_start();
    assert_checktrue(LD7.assessment); assert_checkfalse(LD7.practice_used);
    if gui then
        assert_checktrue(LD7.autosave_enabled);
        if isfield(LD7,"fig") then LD7.fig.figure_name="PATIKRA · LD7 · variantas "+string(number); end
        if number==17 then
            ld7_toggle_solution(); assert_checkfalse(LD7.demoMode); assert_checkfalse(LD7.practice_used);
        end
    end
    loads=[cfg.R1 cfg.R2 cfg.R3 cfg.R4 cfg.R5];
    for step=1:6
        assert_checkequal(LD7.step,step);
        primary_done=%f;
        select step
        case 1 then
            bench_ld7_connect(1);
        case 2 then
            bench_ld7_action("ld7_toggle_power()"); bench_ld7_action("ld7_toggle_switch()");
            for k=1:5
                bench_ld7_action("ld7_set_position("+string(k)+")");
                bench_ld7_action("ld7_measure()");
            end
            bench_ld7_action("ld7_toggle_power()");
        case 3 then
            bench_ld7_answers(step,[cfg.r cfg.E]);
        case 4 then
            uu=cfg.E*loads./(loads+cfg.r); ii=cfg.E./(loads+cfg.r)*1000;
            bench_ld7_answers(step,[uu(1)*ii(1) uu(3)*ii(3) uu(5)*ii(5) 1000*cfg.E^2/(4*cfg.r) 50]);
            if gui & number==17 then
                // Formal assessment keeps a non-empty wrong raw value and does not reveal correctness.
                LD7.ui.answerEdits(3).string="1+2";
                bench_ld7_primary();
                assert_checktrue(LD7.done(4)); assert_checkequal(LD7.step,5);
                assert_checkequal(LD7.answers(4,1),"1+2");
                assert_checktrue(strindex(LD7.ui.statusMain.string,"Patikrinkite")==[]);
                // Restore correct data so the exported acceptance fixture remains perfect.
                ld7_jump_step(4);
                bench_ld7_answers(4,[uu(1)*ii(1) uu(3)*ii(3) uu(5)*ii(5) 1000*cfg.E^2/(4*cfg.r) 50]);
                bench_ld7_primary();
                assert_checktrue(LD7.done(4)); assert_checkequal(LD7.step,5);
                primary_done=%t;
            end
        case 5 then
            bench_ld7_connect(2);
            bench_ld7_action("ld7_toggle_power()"); bench_ld7_action("ld7_measure()"); bench_ld7_action("ld7_toggle_power()");
            bench_ld7_action("ld7_set_mode(3)");
            bench_ld7_connect(3);
            bench_ld7_action("ld7_toggle_power()"); bench_ld7_action("ld7_toggle_switch()"); bench_ld7_action("ld7_measure()"); bench_ld7_action("ld7_toggle_power()");
            bench_ld7_answers(step,[cfg.E*1e6/(1e6+cfg.r) cfg.E/cfg.r*1000]);
        case 6 then
            bench_ld7_answers(step,[1 1 1]);
        end
        if ~primary_done then bench_ld7_primary(); end
        if ~LD7.done(step) then error("LD7 variantas "+string(number)+", etapas "+string(step)); end
        if gui then mprintf("PASS LD7 V%02d: etapas %d\n",number,step); end
    end
    assert_checktrue(and(LD7.done)); assert_checkequal(size(LD7.journal,1),7);
    if gui then
        if number==17 then
            saved=bench_snapshot("LD7");
            keep=LD7.answers(4,1); LD7.answers(4,1)="sugadinta";
            bench_restore_snapshot(saved);
            assert_checkequal(LD7.answers(4,1),keep);
            assert_checktrue(LD7.assessment); assert_checkfalse(LD7.powerOn); assert_checkfalse(LD7.switchOn);
        end
        r=bench_report_data("LD7"); assert_checkequal(r.mode,"assessment"); assert_checkfalse(r.practice_used);
        before=size(listfiles(bench_documents()+"/*.html"),"*");
        bench_ld7_primary();
        assert_checkequal(size(listfiles(bench_documents()+"/*.html"),"*"),before+1);
        assert_checktrue(strindex(LD7.ui.statusMain.string,"Ataskaita išsaugota")<>[]);
        if number==17 then
            // Learning mode still validates locally; practice remains sticky across restart.
            LD7.assessment=%f; LD7.practice_used=%t; ld7_restart();
            assert_checkfalse(LD7.assessment); assert_checktrue(LD7.practice_used);
            bench_ld7_connect(1); bench_ld7_primary(); assert_checkequal(LD7.step,2);
            bench_ld7_action("ld7_toggle_power()"); bench_ld7_action("ld7_toggle_switch()");
            for k=1:5
                bench_ld7_action("ld7_set_position("+string(k)+")"); bench_ld7_action("ld7_measure()");
            end
            bench_ld7_action("ld7_toggle_power()"); bench_ld7_primary(); assert_checkequal(LD7.step,3);
            LD7.ui.answerEdits(1).string="1+2"; LD7.ui.answerEdits(2).string=string(cfg.E);
            bench_ld7_primary();
            assert_checkfalse(LD7.done(3)); assert_checkequal(LD7.step,3);
            assert_checktrue(strindex(LD7.ui.statusMain.string,"Patikrinkite")<>[]);
            ld7_toggle_solution(); assert_checktrue(LD7.demoMode); assert_checktrue(LD7.practice_used);
            ld7_toggle_solution(); assert_checkfalse(LD7.demoMode);
        end
        assert_checktrue(isfield(LD7,"autosave_paths")); assert_checktrue(size(LD7.autosave_paths,"*")>=1);
        ld7_close(); assert_checkfalse(is_handle_valid(LD7.fig));
    end
endfunction

// ------------------------------- LD8 ----------------------------------------
function bench_ld8_action(callback)
    global LD8;
    if LD8.ui.headless then execstr(callback); return; end
    for k=1:size(LD8.ui.dynamic,"*")
        h=LD8.ui.dynamic(k);
        if h.callback==callback then bench_button(h); return; end
    end
    error("Nėra matomo LD8 mygtuko: "+callback);
endfunction

function bench_ld8_click(id)
    bench_ld8_action(msprintf("ld8_terminal_click(""%s"")",id));
endfunction

function bench_ld8_primary()
    global LD8;
    if LD8.ui.headless then ld8_student_primary();
    else bench_button(LD8.ui.studentPrimary); end
endfunction

function bench_ld8_answers(step,values)
    global LD8;
    if LD8.ui.headless then ld8_test_answers(step,values); return; end
    value_index=1;
    for index=1:12
        [answer_step,slot]=ld8_answer_slot(index);
        if answer_step==step then
            LD8.ui.answerEdits(index).string=msprintf("%.17g",values(value_index));
            execstr(LD8.ui.answerEdits(index).callback);
            value_index=value_index+1;
        end
    end
endfunction

function bench_ld8_connect(mode)
    global LD8;
    wires=ld8_canonical_wires(mode);
    assert_checkequal(size(LD8.wires,1),0);
    for index=1:size(wires,1)
        bench_ld8_click(wires(index,1)); bench_ld8_click(wires(index,2));
    end
    bench_ld8_click(wires($,1)); bench_ld8_click(wires($,2));
    [valid,message]=ld8_wiring_valid(LD8.wires); assert_checkfalse(valid);
    bench_ld8_click(wires($,2)); bench_ld8_click(wires($,1));
    [valid,message]=ld8_wiring_valid(LD8.wires); assert_checktrue(valid);
endfunction

function bench_ld8_workflow(number,root,gui)
    global LD8;
    if argn(2)<3 then gui=%f; end
    cfg=ld8_variant_config(number); [valid,message]=ld8_validate_config(cfg); assert_checktrue(valid);
    LD8=struct("cfg",cfg,"student",student_profile(number,"Automatinė Patikra","TEST","LD8"),"ui",struct("headless",~gui));
    ld8_start();
    series=cfg.R1+cfg.R2+cfg.R3;
    parallel=1/(1/cfg.R1+1/cfg.R2+1/cfg.R3);
    mixed=cfg.R1+cfg.R2*cfg.R3/(cfg.R2+cfg.R3);
    for step=1:6
        assert_checkequal(LD8.step,step);
        select step
        case 1 then
            bench_ld8_connect(1);
            bench_ld8_action("ld8_toggle_power()"); bench_ld8_action("ld8_toggle_switch()"); bench_ld8_action("ld8_measure()");
            bench_ld8_action("ld8_toggle_power()");
        case 2 then
            bench_ld8_answers(step,[series series]);
        case 3 then
            bench_ld8_connect(2);
            bench_ld8_action("ld8_toggle_power()"); bench_ld8_action("ld8_toggle_switch()"); bench_ld8_action("ld8_measure()");
            bench_ld8_action("ld8_toggle_power()");
            bench_ld8_answers(step,[parallel parallel]);
        case 4 then
            bench_ld8_connect(3);
            bench_ld8_action("ld8_toggle_power()"); bench_ld8_action("ld8_toggle_switch()"); bench_ld8_action("ld8_measure()");
            bench_ld8_action("ld8_toggle_power()");
            bench_ld8_answers(step,[mixed mixed]);
        case 5 then
            bench_ld8_answers(step,[12/cfg.R1*1000 12/cfg.R2*1000 12/cfg.R3*1000]);
        case 6 then
            bench_ld8_answers(step,[1 1 1]);
        end
        bench_ld8_primary();
        if ~LD8.done(step) then error("LD8 variantas "+string(number)+", etapas "+string(step)); end
        if gui then mprintf("PASS LD8 V%02d: etapas %d\n",number,step); end
    end
    assert_checktrue(and(LD8.done)); assert_checkequal(size(LD8.journal,1),3);
    if gui then
        before=size(listfiles(bench_documents()+"/*.html"),"*");
        bench_ld8_primary();
        assert_checkequal(size(listfiles(bench_documents()+"/*.html"),"*"),before+1);
        assert_checktrue(strindex(LD8.ui.statusMain.string,"Ataskaita išsaugota")<>[]);
        delete(LD8.fig);
    end
endfunction

// ------------------------------- LD9 ----------------------------------------
function bench_ld9_action(callback)
    global LD9;
    if LD9.ui.headless then execstr(callback); return; end
    for k=1:size(LD9.ui.dynamic,"*")
        h=LD9.ui.dynamic(k);
        if h.callback==callback then bench_button(h); return; end
    end
    error("Nėra matomo LD9 mygtuko: "+callback);
endfunction

function bench_ld9_click(id)
    bench_ld9_action(msprintf("ld9_terminal_click(""%s"")",id));
endfunction

function bench_ld9_primary()
    global LD9;
    if LD9.ui.headless then ld9_student_primary();
    else bench_button(LD9.ui.studentPrimary); end
endfunction

function bench_ld9_answers(step,values)
    global LD9;
    if LD9.ui.headless then ld9_test_answers(step,values); return; end
    value_index=1;
    for index=1:12
        [answer_step,slot]=ld9_answer_slot(index);
        if answer_step==step then
            LD9.ui.answerEdits(index).string=msprintf("%.17g",values(value_index));
            execstr(LD9.ui.answerEdits(index).callback);
            value_index=value_index+1;
        end
    end
endfunction

function bench_ld9_connect()
    global LD9;
    wires=ld9_canonical_wires();
    assert_checkequal(size(LD9.wires,1),0);
    for index=1:size(wires,1)
        bench_ld9_click(wires(index,1)); bench_ld9_click(wires(index,2));
    end
    bench_ld9_click(wires($,1)); bench_ld9_click(wires($,2));
    [valid,message]=ld9_wiring_valid(LD9.wires); assert_checkfalse(valid);
    bench_ld9_click(wires($,2)); bench_ld9_click(wires($,1));
    [valid,message]=ld9_wiring_valid(LD9.wires); assert_checktrue(valid);
endfunction

function bench_ld9_measure_point(step)
    // Nustato etapo dažnį ir išmatuoja visus keturis taikinius.
    global LD9;
    bench_ld9_action("ld9_set_freq("+string(step-1)+")");
    bench_ld9_action("ld9_toggle_power()"); bench_ld9_action("ld9_toggle_switch()");
    for target=1:4
        bench_ld9_action("ld9_set_target("+string(target)+")");
        bench_ld9_action("ld9_measure()");
    end
    bench_ld9_action("ld9_toggle_power()");
    assert_checkequal(size(ld9_journal_rows(step-1,4),1),1);
endfunction

function bench_ld9_workflow(number,root,gui)
    global LD9;
    if argn(2)<3 then gui=%f; end
    cfg=ld9_variant_config(number); [valid,message]=ld9_validate_config(cfg); assert_checktrue(valid);
    LD9=struct("cfg",cfg,"student",student_profile(number,"Automatinė Patikra","TEST","LD9"),"ui",struct("headless",~gui));
    ld9_start();
    f0=1/(2*%pi*sqrt(cfg.L*cfg.C));
    expected=ld9_expected_answers();
    for step=1:6
        assert_checkequal(LD9.step,step);
        select step
        case 1 then
            bench_ld9_connect();
            bench_ld9_answers(step,[f0]);
        case 2 then
            bench_ld9_measure_point(2);
        case 3 then
            bench_ld9_measure_point(3);
            bench_ld9_answers(step,[expected(3,1) expected(3,2)]);
        case 4 then
            bench_ld9_measure_point(4);
        case 5 then
            bench_ld9_answers(step,expected(5,1:6));
        case 6 then
            bench_ld9_answers(step,[1 1 1]);
        end
        bench_ld9_primary();
        if ~LD9.done(step) then error("LD9 variantas "+string(number)+", etapas "+string(step)); end
        if gui then mprintf("PASS LD9 V%02d: etapas %d\n",number,step); end
    end
    assert_checktrue(and(LD9.done)); assert_checkequal(size(LD9.journal,1),12);
    if gui then
        LD9.assessment=%t;
        before=size(listfiles(bench_documents()+"/*.html"),"*");
        bench_ld9_primary();
        assert_checkequal(size(listfiles(bench_documents()+"/*.html"),"*"),before+1);
        assert_checktrue(strindex(LD9.ui.statusMain.string,"Ataskaita išsaugota")<>[]);
        delete(LD9.fig);
    end
endfunction

// ------------------------------- LD10 ----------------------------------------
function bench_ld10_action(callback)
    global LD10;
    if LD10.ui.headless then execstr(callback); return; end
    for k=1:size(LD10.ui.dynamic,"*")
        h=LD10.ui.dynamic(k);
        if h.callback==callback then bench_button(h); return; end
    end
    error("Nėra matomo LD10 mygtuko: "+callback);
endfunction

function bench_ld10_click(id)
    bench_ld10_action(msprintf("ld10_terminal_click(""%s"")",id));
endfunction

function bench_ld10_primary()
    global LD10;
    if LD10.ui.headless then ld10_student_primary();
    else bench_button(LD10.ui.studentPrimary); end
endfunction

function bench_ld10_answers(step,values)
    global LD10;
    if LD10.ui.headless then ld10_test_answers(step,values); return; end
    value_index=1;
    for index=1:12
        [answer_step,slot]=ld10_answer_slot(index);
        if answer_step==step then
            LD10.ui.answerEdits(index).string=msprintf("%.17g",values(value_index));
            execstr(LD10.ui.answerEdits(index).callback);
            value_index=value_index+1;
        end
    end
endfunction

function bench_ld10_connect()
    global LD10;
    wires=ld10_canonical_wires();
    assert_checkequal(size(LD10.wires,1),0);
    for index=1:size(wires,1)
        bench_ld10_click(wires(index,1)); bench_ld10_click(wires(index,2));
    end
    bench_ld10_click(wires($,1)); bench_ld10_click(wires($,2));
    [valid,message]=ld10_wiring_valid(LD10.wires); assert_checkfalse(valid);
    bench_ld10_click(wires($,2)); bench_ld10_click(wires($,1));
    [valid,message]=ld10_wiring_valid(LD10.wires); assert_checktrue(valid);
endfunction

function bench_ld10_measure_point(step)
    // Nustato etapo dažnį ir išmatuoja visus keturis taikinius.
    global LD10;
    bench_ld10_action("ld10_set_freq("+string(step-1)+")");
    bench_ld10_action("ld10_toggle_power()"); bench_ld10_action("ld10_toggle_switch()");
    for target=1:4
        bench_ld10_action("ld10_set_target("+string(target)+")");
        bench_ld10_action("ld10_measure()");
    end
    bench_ld10_action("ld10_toggle_power()");
    assert_checkequal(size(ld10_journal_rows(step-1,4),1),1);
endfunction

function bench_ld10_workflow(number,root,gui)
    global LD10;
    if argn(2)<3 then gui=%f; end
    cfg=ld10_variant_config(number); [valid,message]=ld10_validate_config(cfg); assert_checktrue(valid);
    LD10=struct("cfg",cfg,"student",student_profile(number,"Automatinė Patikra","TEST","LD10"),"ui",struct("headless",~gui));
    ld10_start();
    expected=ld10_expected_answers();
    for step=1:6
        assert_checkequal(LD10.step,step);
        select step
        case 1 then
            bench_ld10_connect();
            bench_ld10_answers(step,[expected(1,1)]);
        case 2 then
            bench_ld10_measure_point(2);
        case 3 then
            bench_ld10_measure_point(3);
            bench_ld10_answers(step,[expected(3,1) expected(3,2)]);
        case 4 then
            bench_ld10_measure_point(4);
        case 5 then
            bench_ld10_answers(step,expected(5,1:6));
        case 6 then
            bench_ld10_answers(step,[1 1 1]);
        end
        bench_ld10_primary();
        if ~LD10.done(step) then error("LD10 variantas "+string(number)+", etapas "+string(step)); end
        if gui then mprintf("PASS LD10 V%02d: etapas %d\n",number,step); end
    end
    assert_checktrue(and(LD10.done)); assert_checkequal(size(LD10.journal,1),12);
    if gui then
        LD10.assessment=%t;
        before=size(listfiles(bench_documents()+"/*.html"),"*");
        bench_ld10_primary();
        assert_checkequal(size(listfiles(bench_documents()+"/*.html"),"*"),before+1);
        assert_checktrue(strindex(LD10.ui.statusMain.string,"Ataskaita išsaugota")<>[]);
        delete(LD10.fig);
    end
endfunction


// ------------------------------- LD11 ---------------------------------------
function bench_ld11_action(callback)
    global LD11;
    if LD11.ui.headless then execstr(callback); return; end
    for k=1:size(LD11.ui.dynamic,"*")
        h=LD11.ui.dynamic(k);
        if h.callback==callback then bench_button(h); return; end
    end
    error("Nėra matomo LD11 mygtuko: "+callback);
endfunction

function bench_ld11_click(id)
    bench_ld11_action(msprintf("ld11_terminal_click(""%s"")",id));
endfunction

function bench_ld11_primary()
    global LD11;
    if LD11.ui.headless then ld11_student_primary();
    else bench_button(LD11.ui.studentPrimary); end
endfunction

function bench_ld11_answers(step,values)
    global LD11;
    if LD11.ui.headless then ld11_test_answers(step,values); return; end
    value_index=1;
    for index=1:12
        [answer_step,slot]=ld11_answer_slot(index);
        if answer_step==step then
            LD11.ui.answerEdits(index).string=msprintf("%.17g",values(value_index));
            execstr(LD11.ui.answerEdits(index).callback);
            value_index=value_index+1;
        end
    end
endfunction

function bench_ld11_connect(mode)
    global LD11;
    wires=ld11_canonical_wires(mode);
    assert_checkequal(size(LD11.wires,1),0);
    for index=1:size(wires,1)
        bench_ld11_click(wires(index,1)); bench_ld11_click(wires(index,2));
    end
    bench_ld11_click(wires($,1)); bench_ld11_click(wires($,2));
    [valid,message]=ld11_wiring_valid(LD11.wires); assert_checkfalse(valid);
    bench_ld11_click(wires($,2)); bench_ld11_click(wires($,1));
    [valid,message]=ld11_wiring_valid(LD11.wires); assert_checktrue(valid);
endfunction

function bench_ld11_workflow(number,root,gui)
    global LD11;
    if argn(2)<3 then gui=%f; end
    cfg=ld11_variant_config(number); [valid,message]=ld11_validate_config(cfg); assert_checktrue(valid);
    LD11=struct("cfg",cfg,"student",student_profile(number,"Automatinė Patikra","TEST","LD11"),"ui",struct("headless",~gui));
    ld11_start();
    expected=ld11_expected_answers();
    for step=1:6
        assert_checkequal(LD11.step,step);
        select step
        case 1 then
            bench_ld11_connect(1);
            bench_ld11_answers(step,expected(1,1));
        case 2 then
            bench_ld11_action("ld11_toggle_power()"); bench_ld11_action("ld11_toggle_switch()"); bench_ld11_action("ld11_measure()");
            bench_ld11_action("ld11_toggle_power()");
            bench_ld11_answers(step,expected(2,1:3));
        case 3 then
            bench_ld11_answers(step,expected(3,1));
        case 4 then
            bench_ld11_action("ld11_set_mode(2)");
            bench_ld11_connect(2);
            bench_ld11_action("ld11_toggle_power()"); bench_ld11_action("ld11_toggle_switch()"); bench_ld11_action("ld11_measure()");
            bench_ld11_action("ld11_toggle_power()");
        case 5 then
            bench_ld11_answers(step,expected(5,1:4));
        case 6 then
            bench_ld11_answers(step,[1 1 1]);
        end
        bench_ld11_primary();
        if ~LD11.done(step) then error("LD11 variantas "+string(number)+", etapas "+string(step)); end
        if gui then mprintf("PASS LD11 V%02d: etapas %d\n",number,step); end
    end
    assert_checktrue(and(LD11.done)); assert_checkequal(size(LD11.journal,1),2);
    if gui then
        LD11.assessment=%t;
        before=size(listfiles(bench_documents()+"/*.html"),"*");
        bench_ld11_primary();
        assert_checkequal(size(listfiles(bench_documents()+"/*.html"),"*"),before+1);
        assert_checktrue(strindex(LD11.ui.statusMain.string,"Ataskaita išsaugota")<>[]);
        delete(LD11.fig);
    end
endfunction


// ------------------------------- LD12 ---------------------------------------
function bench_ld12_action(callback)
    global LD12;
    if LD12.ui.headless then execstr(callback); return; end
    for k=1:size(LD12.ui.dynamic,"*")
        h=LD12.ui.dynamic(k);
        if h.callback==callback then bench_button(h); return; end
    end
    error("Nėra matomo LD12 mygtuko: "+callback);
endfunction

function bench_ld12_click(id)
    bench_ld12_action(msprintf("ld12_terminal_click(""%s"")",id));
endfunction

function bench_ld12_primary()
    global LD12;
    if LD12.ui.headless then ld12_student_primary();
    else bench_button(LD12.ui.studentPrimary); end
endfunction

function bench_ld12_answers(step,values)
    global LD12;
    if LD12.ui.headless then ld12_test_answers(step,values); return; end
    value_index=1;
    for index=1:10
        [answer_step,slot]=ld12_answer_slot(index);
        if answer_step==step then
            LD12.ui.answerEdits(index).string=msprintf("%.17g",values(value_index));
            execstr(LD12.ui.answerEdits(index).callback);
            value_index=value_index+1;
        end
    end
endfunction

function bench_ld12_connect(mode)
    global LD12;
    wires=ld12_canonical_wires(mode);
    assert_checkequal(size(LD12.wires,1),0);
    for index=1:size(wires,1)
        bench_ld12_click(wires(index,1)); bench_ld12_click(wires(index,2));
    end
    bench_ld12_click(wires($,1)); bench_ld12_click(wires($,2));
    [valid,message]=ld12_wiring_valid(LD12.wires); assert_checkfalse(valid);
    bench_ld12_click(wires($,2)); bench_ld12_click(wires($,1));
    [valid,message]=ld12_wiring_valid(LD12.wires); assert_checktrue(valid);
endfunction

function bench_ld12_workflow(number,root,gui)
    global LD12;
    if argn(2)<3 then gui=%f; end
    cfg=ld12_variant_config(number); [valid,message]=ld12_validate_config(cfg); assert_checktrue(valid);
    LD12=struct("cfg",cfg,"student",student_profile(number,"Automatinė Patikra","TEST","LD12"),"ui",struct("headless",~gui));
    ld12_start();
    expected=ld12_expected_answers();
    for step=1:6
        assert_checkequal(LD12.step,step);
        select step
        case 1 then
            bench_ld12_connect(1);
            bench_ld12_answers(step,expected(1,1));
        case 2 then
            bench_ld12_action("ld12_set_phase(1)");
            bench_ld12_action("ld12_toggle_power()"); bench_ld12_action("ld12_toggle_switch()"); bench_ld12_action("ld12_measure()");
            bench_ld12_action("ld12_toggle_power()");
            bench_ld12_answers(step,expected(2,1));
        case 3 then
            bench_ld12_action("ld12_set_mode(2)");
            bench_ld12_connect(2);
            bench_ld12_answers(step,expected(3,1));
        case 4 then
            bench_ld12_action("ld12_set_phase(1)");
            bench_ld12_action("ld12_toggle_power()"); bench_ld12_action("ld12_toggle_switch()"); bench_ld12_action("ld12_measure()");
            bench_ld12_action("ld12_toggle_power()");
            bench_ld12_answers(step,expected(4,1));
        case 5 then
            bench_ld12_answers(step,expected(5,1:3));
        case 6 then
            bench_ld12_answers(step,[1 1 1]);
        end
        bench_ld12_primary();
        if ~LD12.done(step) then error("LD12 variantas "+string(number)+", etapas "+string(step)); end
        if gui then mprintf("PASS LD12 V%02d: etapas %d\n",number,step); end
    end
    assert_checktrue(and(LD12.done)); assert_checkequal(size(LD12.journal,1),2);
    if gui then
        LD12.assessment=%t;
        before=size(listfiles(bench_documents()+"/*.html"),"*");
        bench_ld12_primary();
        assert_checkequal(size(listfiles(bench_documents()+"/*.html"),"*"),before+1);
        assert_checktrue(strindex(LD12.ui.statusMain.string,"Ataskaita išsaugota")<>[]);
        delete(LD12.fig);
    end
endfunction
