mode(-1); funcprot(0);
root=getenv("LD8_TEST_RUNTIME")+"/"; out=getenv("LD8_TEST_OUT")+"/"; source=getenv("LD8_TEST_SOURCE")+"/";
global LD8 LD8_CANCEL LD8_CHOICES LD8_DRAFT;
LD8_CHOICES=[]; LD8_DRAFT="";
function values=x_mdialog(varargin)
    global LD8_CANCEL;
    if LD8_CANCEL then values=[]; else values=["17";"Patikra Žąsė";"TEST"]; end
endfunction
function selected=messagebox(varargin)
    if ~or(varargin(2)==["Jūsų priskirtos reikšmės" "Studentas ir priskirtos reikšmės"]) then error("Netikėtas dialogas"); end
    selected=1;
endfunction
function selected=x_choose(varargin)
    global LD8_CHOICES;
    assert_checktrue(size(LD8_CHOICES,"*")>0);
    selected=LD8_CHOICES(1); LD8_CHOICES(1)=[];
endfunction
function path=uigetfile(varargin)
    global LD8_DRAFT; path=LD8_DRAFT;
endfunction
function ld8_test_help()
    global LD8;
    handles=findobj(LD8.fig,"callback","ld8_show_actions()");
    assert_checkequal(size(handles,"*"),1); bench_button(handles(1));
endfunction
function capture_ld8(name)
    global LD8;
    if getos()<>"Linux" then return; end
    LD8.fig.figure_name="LD8 PATIKRA "+name; show_window(LD8.fig); sleep(500);
    command="/usr/bin/python3 """+getenv("LD8_TEST_RUNTIME")+"/capture_window.py"" ""LD8 PATIKRA "+name+""" """+getenv("LD8_TEST_OUT")+"/"+name+".png""";
    assert_checkequal(host(command),0);
endfunction
try
    LD8=struct(); LD8_CANCEL=%t; exec(root+"LD8/LD8.sce",-1); assert_checkfalse(isfield(LD8,"fig"));
    LD8_CANCEL=%f; exec(root+"LD8/LD8.sce",-1); assert_checkequal(LD8.student.number,17);
    assert_checkequal(LD8.student.bank,"LD8-64-A-2026");
    assert_checktrue(LD8.assessment); assert_checktrue(LD8.autosave_enabled); delete(LD8.fig);
    exec(root+"tests/workflows.sci",-1); exec(source+"tools/ergonomics.sci",-1);
    for number=[1 17 64]; bench_ld8_workflow(number,root,%t); end
    LD8=struct("cfg",ld8_variant_config(1),"student",student_profile(1,"Patikra Žąsė","TEST","LD8"),"ui",struct("headless",%f));
    ld8_start(); report=bench_report_data("LD8");
    for key=["s1" "s3" "s4"]; assert_checkequal(length(report.evidence.wiring(key).pairs),0); end
    assert_checkequal(length(report.observations),0);
    ld8_set_mode(3); assert_checkequal(size(LD8.wires,1),0);
    ld8_set_mode(0); ld8_set_mode(%nan); ld8_set_mode(1.5); assert_checkequal(LD8.wireMode,3);
    ld8_set_step(7); ld8_jump_step(%nan); assert_checkequal(LD8.step,1);
    assert_checkfalse(ld8_valid_index([1 2],3));
    // Formal mode blocks the example.
    ld8_toggle_solution(); assert_checkfalse(LD8.demoMode); assert_checkfalse(LD8.practice_used);
    // Learning mode permits it; demo state itself cannot be exported.
    LD8.assessment=%f; LD8.practice_used=%t; ld8_render_stage();
    ld8_toggle_solution(); assert_checktrue(LD8.demoMode); rejected=%f;
    try report=bench_report_data("LD8"); catch rejected=%t; end
    assert_checktrue(rejected); ld8_measure(); ld8_check_step(); assert_checkfalse(or(LD8.done));
    ld8_toggle_solution(); assert_checkequal(size(LD8.journal,1),0); assert_checkequal(size(LD8.wires,1),0);
    LD8.assessment=%t; LD8.practice_used=%f; ld8_render_stage();
    descriptor=mopen(out+"geometry.tsv","wt"); sizes=[1280 720];
    screen=get(0,"screensize_px"); viewport=min(sizes,max([320 240],screen(3:4)-[40 120]));
    for dimension=1
        assert_checkequal(matrix(LD8.fig.axes_size,1,-1),viewport);
        assert_checkequal(student_size(LD8.ui.circuitFrame.parent),sizes);
        for step=1:6
            LD8.step=step; LD8.wireMode=ld8_stage_mode(step); LD8.wires=ld8_canonical_wires(LD8.wireMode);
            LD8.powerOn=%t; LD8.switchOn=%t; ld8_render_stage();
            label=msprintf("LD8-E%d-%dx%d",step,sizes(dimension,1),sizes(dimension,2));
            geometry_dump(LD8.fig,label,descriptor);
            LD8.wires=LD8.wires(:,[2 1]); ld8_render_wires(); geometry_dump(LD8.fig,label+"-reverse",descriptor);
            if step>=2 then capture_ld8("E"+string(step)); end
        end
    end
    // Invoke the registered native resize callback without re-rendering a stage.
    // This checks the callback contract; it does not emulate an OS drag event.
    LD8.ui.answerEdits(7).value=2;
    for dimension=1
        assert_checkequal(matrix(LD8.fig.axes_size,1,-1),viewport);
        assert_checkequal(student_size(LD8.ui.circuitFrame.parent),sizes);
        assert_checktrue(LD8.fig.resizefcn<>""); execstr(LD8.fig.resizefcn);
        assert_checkequal(LD8.ui.answerEdits(7).value,2);
        geometry_dump(LD8.fig,"LD8-resize-"+string(dimension),descriptor);
    end
    mclose(descriptor);
    report=bench_report_data("LD8");
    for key=["s1" "s3" "s4"]; assert_checkequal(length(report.evidence.wiring(key).pairs),0); end
    LD8.cfg=ld8_variant_config(64); LD8.student=student_profile(64,"Patikra Žąsė","TEST","LD8");
    // Rodmenys visuose trijuose režimuose; matavimas eina per tikrą MNA tinklą.
    stages=[1 3 4];
    for circuit_mode=1:3
        LD8.step=stages(circuit_mode); LD8.wireMode=circuit_mode; LD8.wires=ld8_canonical_wires(circuit_mode);
        LD8.powerOn=%t; LD8.switchOn=%t; ld8_render_stage(); values=ld8_reference(circuit_mode);
        handle=findobj("tag","reading:A"); assert_checkequal(handle.string,msprintf("%.3f mA",values(2)));
        handle=findobj("tag","reading:V"); assert_checkequal(handle.string,msprintf("%.4f V",values(1)));
        assert_checkalmostequal(values(1),12,1e-9,1e-9);
        bench_ld8_action("ld8_measure()");
        rows=ld8_journal_rows(circuit_mode);
        assert_checkalmostequal(rows(1,1:2),values(1:2),1e-9,1e-9);
        if circuit_mode==3 then
            execstr(LD8.fig.resizefcn); capture_ld8("misri-V64");
        end
    end
    mprintf("LD8_GUI_STAGE: actual MNA meters and windows PASS\n");
    journal=LD8.journal; bench_ld8_action("ld8_measure()"); assert_checkequal(LD8.journal,journal);
    ld8_set_step(5); LD8.ui.answerEdits(5).string="10,321";
    snapshot_path=bench_save_snapshot("LD8"); snapshot=bench_read_snapshot(snapshot_path,"LD8");
    ld8_restart(); bench_restore_snapshot(snapshot);
    assert_checkequal(LD8.ui.answerEdits(5).string,"10,321"); assert_checkequal(LD8.journal,journal);
    assert_checktrue(LD8.assessment); assert_checkfalse(LD8.powerOn); assert_checkfalse(LD8.switchOn);
    mprintf("LD8_GUI_STAGE: autosave and snapshot restore PASS\n");
    ld8_toggle_solution(); assert_checkfalse(LD8.demoMode);
    LD8.assessment=%f; LD8.practice_used=%t; ld8_toggle_solution(); assert_checktrue(LD8.demoMode);
    assert_checkequal(size(LD8.journal,1),1); ld8_toggle_solution(); assert_checkequal(LD8.journal,journal);
    mprintf("LD8_GUI_STAGE: worked example isolation PASS\n");
    // Restart must not erase the practice marker.
    ld8_restart(); assert_checkfalse(LD8.assessment); assert_checktrue(LD8.practice_used);
    bench_restore_snapshot(snapshot); LD8.assessment=%f; LD8.practice_used=%t;
    // All other required inputs must be present before testing a single
    // malformed field; otherwise the first missing input is rightly reported.
    expected=ld8_expected_answers();
    bench_ld8_answers(5,expected(5,1:3));
    LD8.done(5)=%t; LD8.ui.answerEdits(5).string="1+2"; bench_ld8_primary();
    assert_checkfalse(LD8.done(5)); assert_checkequal(LD8.step,5);
    assert_checkequal(LD8.ui.answerEdits(5).string,"1+2");
    assert_checktrue(strindex(LD8.ui.statusMain.string,"skaičių")<>[]);
    expected=ld8_expected_answers(); bench_ld8_answers(5,expected(5,1:3));
    LD8.ui.answerEdits(5).string=strsubst(LD8.ui.answerEdits(5).string,".",","); bench_ld8_primary();
    assert_checkequal(LD8.step,6); assert_checktrue(LD8.done(5));
    mprintf("LD8_GUI_STAGE: learning checks / locale comma PASS\n");
    // 5 etapas skaičiuoja iš 3 etapo matavimų: atkūrimas nieko nevalo.
    ld8_set_step(3); ld8_restore_stage(); assert_checkequal(size(LD8.wires,1),0);
    assert_checkequal(size(ld8_journal_rows(2),1),0); assert_checkfalse(LD8.done(3));
    report=bench_report_data("LD8"); assert_checkequal(length(report.evidence.wiring.s3.pairs),0);
    ld8_show_wiring_guide(); window=gcf(); assert_checktrue(window<>LD8.fig); delete(window);
    ld8_show_theory(); window=gcf(); assert_checktrue(window<>LD8.fig); delete(window);
    ld8_show_stand_map(); window=gcf(); assert_checktrue(window<>LD8.fig); delete(window);
    mprintf("LD8_GUI_STAGE: wiring guide and contextual theory PASS\n");
    // Assessment rejects empty/nonnumeric input but keeps a wrong numeric answer
    // for the teacher, without revealing its correctness to the student.
    LD8.assessment=%t; ld8_set_step(5); expected=ld8_expected_answers();
    bench_ld8_answers(5,expected(5,1:3)); LD8.ui.answerEdits(5).string="";
    bench_ld8_primary(); assert_checkequal(LD8.step,5); assert_checkfalse(LD8.done(5));
    LD8.ui.answerEdits(5).string="1+2"; bench_ld8_primary();
    assert_checkequal(LD8.step,5); assert_checkfalse(LD8.done(5));
    assert_checktrue(strindex(LD8.ui.statusMain.string,"skaičių")<>[]);
    LD8.ui.answerEdits(5).string=msprintf("%.17g",expected(5,2)*1.2); bench_ld8_primary();
    assert_checkequal(LD8.step,6);
    assert_checkalmostequal(ld8_parse_number(LD8.answers(5,2)),expected(5,2)*1.2,1e-9,1e-9);
    mprintf("LD8_GUI_STAGE: assessment numeric format checks PASS\n");
    // Close flushes an edit without Enter; actual Help restores the saved work.
    LD8.ui.answerEdits(7).value=3; // Ne – selection is saved as "2", not a typed number.
    closing=LD8.fig; execstr(closing.closerequestfcn); assert_checkfalse(is_handle_valid(closing));
    ld8_show_actions(); ld8_render_stage(); ld8_render_journal(); // queued events after close
    LD8_DRAFT=LD8.autosave_paths($);
    saved=bench_read_snapshot(LD8_DRAFT,"LD8"); assert_checkequal(saved.state.answers(6,1),"2");
    assert_checkalmostequal(ld8_parse_number(saved.state.answers(5,2)),expected(5,2)*1.2,1e-9,1e-9);
    LD8=struct(); exec(root+"LD8/LD8.sce",-1);
    LD8_CHOICES=1; ld8_test_help();
    assert_checkequal(LD8.step,6); assert_checkequal(LD8.student.number,64);
    assert_checkequal(LD8.ui.answerEdits(7).value,3);
    assert_checktrue(LD8.assessment); assert_checktrue(LD8.autosave_enabled);
    mprintf("LD8_GUI_STAGE: close/reopen and draft resume PASS\n");
    LD8_CHOICES=[5 2]; ld8_test_help(); assert_checkfalse(LD8.assessment); assert_checktrue(LD8.practice_used);
    LD8_CHOICES=[5 1]; ld8_test_help(); assert_checktrue(LD8.assessment); assert_checktrue(LD8.practice_used);
    LD8_CHOICES=3; ld8_test_help(); window=gcf(); assert_checktrue(window<>LD8.fig); delete(window);
    LD8_CHOICES=7; ld8_test_help(); assert_checktrue(is_handle_valid(LD8.fig));
    before_journal=LD8.journal; before_answers=LD8.answers;
    ld8_apply_profile(student_profile(64,"Pataisyta Pavardė","KITA","LD8"),LD8.cfg);
    assert_checkequal(LD8.journal,before_journal); assert_checkequal(LD8.answers,before_answers);
    assert_checktrue(strindex(LD8.ui.identity.string,"Pataisyta Pavardė")<>[]);
    nextcfg=ld8_variant_config(1);
    ld8_apply_profile(student_profile(1,"Pataisyta Pavardė","KITA","LD8"),nextcfg);
    assert_checkequal(LD8.student.number,1); assert_checkequal(LD8.step,1);
    assert_checkequal(LD8.journal,[]); assert_checkfalse(or(LD8.done));
    h=findobj("tag","reading:R1"); assert_checktrue(h<>[]);
    assert_checkequal(h.string,msprintf("%g Ω",nextcfg.R1));
    mprintf("LD8_GUI_STAGE: edit profile and switch variants PASS\n");
    delete(LD8.fig);
    cases=list(); specs=[2 1 .01;3 1 .01;4 1 .01;5 1 .02;5 2 .02;5 3 .02];
    for number=[1 17 64]
        bench_ld8_workflow(number,root,%f); expected=ld8_expected_answers(); original=LD8.answers;
        if number==1 then
            LD8.autosave_enabled=%t; bench_autosave("LD8"); bench_autosave("LD8"); bench_autosave("LD8");
            assert_checkequal(size(LD8.autosave_paths,"*"),2); assert_checkequal(LD8.autosave_error,"");
        end
        // Fully completed reports: grading and summary eligibility are independent.
        if number==1 then
            LD8.answers(2,1)="wrong";
            cases($+1)=struct("report",bench_report_data("LD8"),"accepted",%f);
            LD8.answers=original; LD8.practice_used=%t;
            cases($+1)=struct("report",bench_report_data("LD8"),"accepted",%t);
            LD8.practice_used=%f;
        end
        for index=1:size(specs,1)
            step=specs(index,1); slot=specs(index,2); value=expected(step,slot); tolerance=1e-9+specs(index,3)*abs(value);
            for delta=[-1.0001 -.9999 .9999 1.0001]
                LD8.answers=original; LD8.step=step; LD8.done(step)=%f;
                // Jungimo etapai reikalauja atitinkamo režimo (žurnalo eilutės lieka iš workflow).
                if or(step==[1 3 4]) then
                    LD8.wireMode=ld8_stage_mode(step); LD8.wires=ld8_canonical_wires(LD8.wireMode);
                end
                LD8.answers(step,slot)=msprintf("%.17g",value+delta*tolerance); ld8_check_step();
                accepted=LD8.done(step); assert_checkequal(accepted,abs(delta)<1);
                cases($+1)=struct("report",bench_report_data("LD8"),"accepted",accepted);
            end
        end
        for slot=1:3
            for raw=[string(expected(6,slot)) string(3-expected(6,slot)) "" "1+1"]
                LD8.answers=original; LD8.step=6; LD8.done(6)=%f; LD8.answers(6,slot)=raw; ld8_check_step();
                accepted=LD8.done(6); assert_checkequal(accepted,raw==string(expected(6,slot)));
                cases($+1)=struct("report",bench_report_data("LD8"),"accepted",accepted);
            end
        end
    end
    mputl(toJSON(cases),out+"tolerance-cases.json");
    mprintf("LD8_GUI_STAGE: tolerance comparisons PASS\n");
    // Legacy LD8-1 draft: never lose any real work, theory or Kirchhoff answers.
    bench_ld8_workflow(1,root,%f);
    previous=bench_snapshot("LD8");
    previous.state.workflow_revision=1; previous.state.answers(2:4,2)="kopijuotas rodmuo";
    old_journal=LD8.journal; old_wires=LD8.report_wires(2);
    old_theory=LD8.answers(3,1); old_done=LD8.done;
    bench_restore_snapshot(previous);
    assert_checkequal(LD8.workflow_revision,2);
    assert_checkequal(LD8.journal,old_journal);
    assert_checkequal(LD8.report_wires(2),old_wires);
    assert_checkequal(LD8.answers(3,1),old_theory);
    assert_checkequal(LD8.answers(2:4,2),["";"";""]);
    assert_checkequal(LD8.done,old_done);
    assert_checkequal(bench_report_data("LD8").rubric_version,"LD8-2");
    mprintf("LD8_GUI_STAGE: legacy draft migration PASS\n");
    mputl("LD8_PASS: LD8-2 15 criteria; no Re copy; nine meaningful answers; context theory; three grouped U/I measurements and real wiring; old draft preserved; 3 GUI variants; comma/raw input; saved choices; profile corrections; format validation; 13 geometry cases; grading comparisons",out+"verdict.log"); exit(0);
catch
    [problem,code,line,fn]=lasterror();
    mputl("LD8_FAIL: "+strcat(problem," | ")+" at "+fn+":"+string(line),out+"verdict.log"); disp(problem); exit(1);
end
