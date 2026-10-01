mode(-1); funcprot(0);
root=getenv("LD8_TEST_RUNTIME")+"/"; out=getenv("LD8_TEST_OUT")+"/"; source=getenv("LD8_TEST_SOURCE")+"/";
global LD8 LD8_CANCEL LD8_CHOICES LD8_DRAFT;
LD8_CHOICES=[]; LD8_DRAFT="";
function values=x_mdialog(varargin)
    global LD8_CANCEL;
    if LD8_CANCEL then values=[]; else values=["17";"Patikra Žąsė";"TEST"]; end
endfunction
function selected=messagebox(varargin)
    if varargin(2)<>"Jūsų priskirtos reikšmės" then error("Netikėtas dialogas"); end
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
    LD8.ui.answerEdits(10).string="1,0";
    for dimension=1
        assert_checkequal(matrix(LD8.fig.axes_size,1,-1),viewport);
        assert_checkequal(student_size(LD8.ui.circuitFrame.parent),sizes);
        assert_checktrue(LD8.fig.resizefcn<>""); execstr(LD8.fig.resizefcn);
        assert_checkequal(LD8.ui.answerEdits(10).string,"1,0");
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
    journal=LD8.journal; bench_ld8_action("ld8_measure()"); assert_checkequal(LD8.journal,journal);
    ld8_set_step(5); LD8.ui.answerEdits(8).string="10,321";
    snapshot_path=bench_save_snapshot("LD8"); snapshot=bench_read_snapshot(snapshot_path,"LD8");
    ld8_restart(); bench_restore_snapshot(snapshot);
    assert_checkequal(LD8.ui.answerEdits(8).string,"10,321"); assert_checkequal(LD8.journal,journal);
    assert_checktrue(LD8.assessment); assert_checkfalse(LD8.powerOn); assert_checkfalse(LD8.switchOn);
    ld8_toggle_solution(); assert_checkfalse(LD8.demoMode);
    LD8.assessment=%f; LD8.practice_used=%t; ld8_toggle_solution(); assert_checktrue(LD8.demoMode);
    assert_checkequal(size(LD8.journal,1),1); ld8_toggle_solution(); assert_checkequal(LD8.journal,journal);
    // Restart must not erase the practice marker.
    ld8_restart(); assert_checkfalse(LD8.assessment); assert_checktrue(LD8.practice_used);
    bench_restore_snapshot(snapshot); LD8.assessment=%f; LD8.practice_used=%t;
    LD8.done(5)=%t; LD8.ui.answerEdits(8).string="1+2"; bench_ld8_primary();
    assert_checkfalse(LD8.done(5)); assert_checkequal(LD8.step,5); assert_checkequal(LD8.ui.answerEdits(8).string,"1+2");
    expected=ld8_expected_answers(); bench_ld8_answers(5,expected(5,1:3));
    LD8.ui.answerEdits(8).string=strsubst(LD8.ui.answerEdits(8).string,".",","); bench_ld8_primary();
    assert_checkequal(LD8.step,6); assert_checktrue(LD8.done(5));
    // 5 etapas skaičiuoja iš 3 etapo matavimų: atkūrimas nieko nevalo.
    ld8_set_step(3); ld8_restore_stage(); assert_checkequal(size(LD8.wires,1),0);
    assert_checkequal(size(ld8_journal_rows(2),1),0); assert_checkfalse(LD8.done(3));
    report=bench_report_data("LD8"); assert_checkequal(length(report.evidence.wiring.s3.pairs),0);
    ld8_show_wiring_guide(); window=gcf(); assert_checktrue(window<>LD8.fig); delete(window);
    ld8_show_stand_map(); window=gcf(); assert_checktrue(window<>LD8.fig); delete(window);
    // Assessment accepts raw wrong answers, but requires a nonempty field.
    LD8.assessment=%t; ld8_set_step(5); expected=ld8_expected_answers();
    bench_ld8_answers(5,expected(5,1:3)); LD8.ui.answerEdits(8).string="";
    bench_ld8_primary(); assert_checkequal(LD8.step,5); assert_checkfalse(LD8.done(5));
    LD8.ui.answerEdits(8).string="1+2"; bench_ld8_primary();
    assert_checkequal(LD8.step,6); assert_checkequal(LD8.answers(5,2),"1+2");
    // Close flushes an edit without Enter; actual Help restores the saved work.
    LD8.ui.answerEdits(10).string="2,0";
    closing=LD8.fig; execstr(closing.closerequestfcn); assert_checkfalse(is_handle_valid(closing));
    ld8_show_actions(); ld8_render_stage(); ld8_render_journal(); // queued events after close
    LD8_DRAFT=LD8.autosave_paths($);
    saved=bench_read_snapshot(LD8_DRAFT,"LD8"); assert_checkequal(saved.state.answers(6,1),"2,0");
    assert_checkequal(saved.state.answers(5,2),"1+2");
    LD8=struct(); exec(root+"LD8/LD8.sce",-1);
    LD8_CHOICES=1; ld8_test_help();
    assert_checkequal(LD8.step,6); assert_checkequal(LD8.student.number,64);
    assert_checkequal(LD8.ui.answerEdits(10).string,"2,0");
    assert_checktrue(LD8.assessment); assert_checktrue(LD8.autosave_enabled);
    LD8_CHOICES=[4 2]; ld8_test_help(); assert_checkfalse(LD8.assessment); assert_checktrue(LD8.practice_used);
    LD8_CHOICES=[4 1]; ld8_test_help(); assert_checktrue(LD8.assessment); assert_checktrue(LD8.practice_used);
    LD8_CHOICES=6; ld8_test_help(); window=gcf(); assert_checktrue(window<>LD8.fig); delete(window);
    delete(LD8.fig);
    cases=list(); specs=[2 1 .01;2 2 .02;3 1 .01;3 2 .02;4 1 .01;4 2 .02;5 1 .02;5 2 .02;5 3 .02];
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
            for raw=[string(expected(6,slot))+",0" string(3-expected(6,slot)) "" "1+1"]
                LD8.answers=original; LD8.step=6; LD8.done(6)=%f; LD8.answers(6,slot)=raw; ld8_check_step();
                accepted=LD8.done(6); assert_checkequal(accepted,raw==string(expected(6,slot))+",0");
                cases($+1)=struct("report",bench_report_data("LD8"),"accepted",accepted);
            end
        end
    end
    mputl(toJSON(cases),out+"tolerance-cases.json");
    mputl("LD8_PASS: 3 GUI variants; series/parallel/mixed wirings; true MNA readings; actual report button; saved wiring evidence; comma input without Enter; demo isolation; draft restore; 13 fixed-window geometry cases including resize callback; close/autosave and Help restore; assessment and learning modes; 146 grading comparisons",out+"verdict.log"); exit(0);
catch
    [problem,code,line,fn]=lasterror();
    mputl("LD8_FAIL: "+strcat(problem," | ")+" at "+fn+":"+string(line),out+"verdict.log"); disp(problem); exit(1);
end
