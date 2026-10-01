mode(-1); funcprot(0);
root=getenv("LD7_TEST_RUNTIME")+"/"; out=getenv("LD7_TEST_OUT")+"/"; source=getenv("LD7_TEST_SOURCE")+"/";
global LD7 LD7_CANCEL;
function values=x_mdialog(varargin)
    global LD7_CANCEL;
    if LD7_CANCEL then values=[]; else values=["17";"Patikra Žąsė";"TEST"]; end
endfunction
function selected=messagebox(varargin)
    if varargin(2)<>"Jūsų priskirtos reikšmės" then error("Netikėtas dialogas"); end
    selected=1;
endfunction
function capture_ld7(name)
    global LD7;
    if getos()<>"Linux" then return; end
    LD7.fig.figure_name="LD7 PATIKRA "+name; show_window(LD7.fig); sleep(500);
    command="/usr/bin/python3 """+getenv("LD7_TEST_RUNTIME")+"/capture_window.py"" ""LD7 PATIKRA "+name+""" """+getenv("LD7_TEST_OUT")+"/"+name+".png""";
    assert_checkequal(host(command),0);
endfunction
try
    LD7=struct(); LD7_CANCEL=%t; exec(root+"LD7/LD7.sce",-1); assert_checkfalse(isfield(LD7,"fig"));
    LD7_CANCEL=%f; exec(root+"LD7/LD7.sce",-1); assert_checkequal(LD7.student.number,17);
    assert_checkequal(LD7.student.bank,"LD7-64-A-2026");
    assert_checktrue(LD7.assessment); assert_checkfalse(LD7.practice_used);
    assert_checkequal(LD7.fig.closerequestfcn,"ld7_close()");
    delete(LD7.fig);
    exec(root+"tests/workflows.sci",-1); exec(source+"tools/ergonomics.sci",-1);
    for number=[1 17 64]; bench_ld7_workflow(number,root,%t); end
    LD7=struct("cfg",ld7_variant_config(1),"student",student_profile(1,"Patikra Žąsė","TEST","LD7"),"ui",struct("headless",%f));
    ld7_start(); report=bench_report_data("LD7");
    for key=["s1" "s5te" "s5tj"]; assert_checkequal(length(report.evidence.wiring(key).pairs),0); end
    assert_checkequal(length(report.observations),0);
    assert_checkequal(report.mode,"assessment"); assert_checkfalse(report.practice_used);
    ld7_set_mode(3); assert_checkequal(size(LD7.wires,1),0);
    ld7_set_mode(0); ld7_set_mode(%nan); ld7_set_mode(1.5); assert_checkequal(LD7.wireMode,3);
    ld7_set_mode(1);
    ld7_set_position(2); ld7_set_position(0); ld7_set_position(%nan); ld7_set_position(6);
    assert_checkequal(LD7.position,2);
    ld7_set_step(7); ld7_jump_step(%nan); assert_checkequal(LD7.step,1);
    assert_checkfalse(ld7_valid_index([1 2],5));
    // Rewiring remains blocked while energized.
    LD7.wireMode=1;LD7.wires=ld7_canonical_wires(1);LD7.powerOn=%t;LD7.switchOn=%t;LD7.pending="";
    beforeW=LD7.wires;ld7_terminal_click("E_P");
    assert_checkequal(LD7.pending,"");assert_checkequal(LD7.wires,beforeW);
    LD7.powerOn=%f;LD7.switchOn=%f;LD7.wires=emptystr(0,2);
    // Formal mode blocks the worked example.
    ld7_toggle_solution(); assert_checkfalse(LD7.demoMode); assert_checkfalse(LD7.practice_used);
    // Learning mode permits it; demo state cannot be exported.
    LD7.assessment=%f; LD7.practice_used=%t; ld7_render_stage();
    ld7_toggle_solution(); assert_checktrue(LD7.demoMode); rejected=%f;
    try report=bench_report_data("LD7"); catch rejected=%t; end
    assert_checktrue(rejected); ld7_measure(); ld7_check_step(); assert_checkfalse(or(LD7.done));
    ld7_toggle_solution(); assert_checkequal(size(LD7.journal,1),0); assert_checkequal(size(LD7.wires,1),0);
    LD7.assessment=%t; LD7.practice_used=%f; ld7_render_stage();
    descriptor=mopen(out+"geometry.tsv","wt"); sizes=[1280 720;1280 800;1600 900];
    LD7.position=3;
    for dimension=1:3
        geometry_size(LD7.fig,sizes(dimension,:));
        for step=1:6
            LD7.step=step; LD7.wireMode=ld7_stage_mode(step); LD7.wires=ld7_canonical_wires(LD7.wireMode);
            LD7.powerOn=%t; LD7.switchOn=%t; ld7_render_stage();
            label=msprintf("LD7-E%d-%dx%d",step,sizes(dimension,1),sizes(dimension,2));
            geometry_dump(LD7.fig,label,descriptor);
            LD7.wires=LD7.wires(:,[2 1]); ld7_render_wires(); geometry_dump(LD7.fig,label+"-reverse",descriptor);
            if dimension==2 & step>=2 then capture_ld7("E"+string(step)); end
        end
    end
    // Invoke the registered native resize callback without re-rendering a stage.
    // This checks the callback contract; it does not emulate an OS drag event.
    LD7.ui.answerEdits(10).string="1,0";
    for dimension=[1 3 2]
        geometry_size(LD7.fig,sizes(dimension,:));
        assert_checktrue(LD7.fig.resizefcn<>""); execstr(LD7.fig.resizefcn);
        assert_checkequal(LD7.ui.answerEdits(10).string,"1,0");
        geometry_dump(LD7.fig,"LD7-resize-"+string(dimension),descriptor);
    end
    mclose(descriptor);
    report=bench_report_data("LD7");
    for key=["s1" "s5te" "s5tj"]; assert_checkequal(length(report.evidence.wiring(key).pairs),0); end
    LD7.cfg=ld7_variant_config(64); LD7.student=student_profile(64,"Patikra Žąsė","TEST","LD7");
    // Darbinė grandinė: suderinamumo padėties P3 rodmenys.
    LD7.step=2; LD7.wireMode=1; LD7.position=3; LD7.wires=ld7_canonical_wires(1); LD7.powerOn=%t; LD7.switchOn=%t;
    ld7_render_stage(); values=ld7_reference(1,3);
    handle=findobj("tag","reading:A"); assert_checkequal(handle.string,msprintf("%.3f mA",values(2)));
    handle=findobj("tag","reading:V"); assert_checkequal(handle.string,msprintf("%.4f V",values(1)));
    bench_ld7_action("ld7_measure()"); rows=ld7_journal_rows(3);
    assert_checkalmostequal(rows(1,1:2),values,1e-9,1e-9);
    assert_checkequal(rows(1,3),LD7.cfg.R3);
    // Tuščioji eiga: U0 rodo voltmetras prie šaltinio.
    LD7.step=5; LD7.wireMode=2; LD7.wires=ld7_canonical_wires(2); LD7.powerOn=%t; LD7.switchOn=%f;
    ld7_render_stage(); values=ld7_reference(2);
    handle=findobj("tag","reading:V"); assert_checkequal(handle.string,msprintf("%.4f V",values(1)));
    bench_ld7_action("ld7_measure()"); rows=ld7_journal_rows(6);
    assert_checkalmostequal(rows(1,1:2),values,1e-9,1e-9);
    // Trumpasis jungimas: Ik rodo ampermetras vietoj krovinio.
    LD7.wireMode=3; LD7.wires=ld7_canonical_wires(3); LD7.powerOn=%t; LD7.switchOn=%t;
    ld7_render_stage(); values=ld7_reference(3);
    handle=findobj("tag","reading:A"); assert_checkequal(handle.string,msprintf("%.3f mA",values(2)));
    bench_ld7_action("ld7_measure()"); rows=ld7_journal_rows(7);
    assert_checkalmostequal(rows(1,1:2),values,1e-9,1e-9);
    assert_checktrue(values(2)>0 & abs(values(1))<1e-3);
    geometry_size(LD7.fig,[1280 800]); execstr(LD7.fig.resizefcn); capture_ld7("trumpasis-V64");
    journal=LD7.journal; bench_ld7_action("ld7_measure()"); assert_checkequal(LD7.journal,journal);
    expected=ld7_expected_answers(); bench_ld7_answers(5,expected(5,1:2));
    LD7.ui.answerEdits(8).string="10,321";
    snapshot_path=bench_save_snapshot("LD7"); snapshot=bench_read_snapshot(snapshot_path,"LD7");
    ld7_restart(); bench_restore_snapshot(snapshot);
    assert_checkequal(LD7.ui.answerEdits(8).string,"10,321"); assert_checkequal(LD7.journal,journal);
    assert_checktrue(LD7.assessment); assert_checkfalse(LD7.powerOn); assert_checkfalse(LD7.switchOn);
    // Formal assessment preserves invalid raw text and advances without revealing correctness.
    expected=ld7_expected_answers(); bench_ld7_answers(5,expected(5,1:2)); LD7.ui.answerEdits(8).string="1+2";
    bench_ld7_primary(); assert_checkequal(LD7.step,6); assert_checktrue(LD7.done(5));
    assert_checkequal(LD7.answers(5,1),"1+2"); assert_checktrue(strindex(LD7.ui.statusMain.string,"Patikrinkite")==[]);
    // Learning mode still validates locally.
    ld7_jump_step(5); LD7.assessment=%f; LD7.practice_used=%t; ld7_render_stage();
    expected=ld7_expected_answers(); bench_ld7_answers(5,expected(5,1:2)); LD7.ui.answerEdits(8).string="1+2";
    bench_ld7_primary(); assert_checkfalse(LD7.done(5)); assert_checkequal(LD7.step,5);
    assert_checktrue(strindex(LD7.ui.statusMain.string,"Patikrinkite")<>[]);
    bench_ld7_answers(5,expected(5,1:2)); LD7.ui.answerEdits(8).string=strsubst(LD7.ui.answerEdits(8).string,".",","); bench_ld7_primary();
    assert_checkequal(LD7.step,6); assert_checktrue(LD7.done(5));
    ld7_toggle_solution(); assert_checktrue(LD7.demoMode); assert_checktrue(LD7.practice_used);
    ld7_toggle_solution(); assert_checkfalse(LD7.demoMode);
    LD7.assessment=%t; LD7.practice_used=%f;
    ld7_set_step(5); ld7_restore_stage(); assert_checkequal(size(LD7.wires,1),0);
    assert_checkequal(size(ld7_journal_rows(6),1),0); assert_checkfalse(LD7.done(5));
    report=bench_report_data("LD7"); assert_checkequal(length(report.evidence.wiring.s5te.pairs),0);
    ld7_show_wiring_guide(); window=gcf(); assert_checktrue(window<>LD7.fig); delete(window);
    ld7_show_stand_map(); window=gcf(); assert_checktrue(window<>LD7.fig); delete(window);
    ld7_close(); assert_checkfalse(is_handle_valid(LD7.fig));
    cases=list(); specs=[3 1 .03;3 2 .01;4 1 .02;4 2 .02;4 3 .02;4 4 .02;4 5 .02;5 1 .01;5 2 .02];
    for number=[1 17 64]
        bench_ld7_workflow(number,root,%f); expected=ld7_expected_answers(); original=LD7.answers;
        if number==1 then
            LD7.autosave_enabled=%t; bench_autosave("LD7"); bench_autosave("LD7"); bench_autosave("LD7");
            assert_checkequal(size(LD7.autosave_paths,"*"),2); assert_checkequal(LD7.autosave_error,"");
        end
        for index=1:size(specs,1)
            step=specs(index,1); slot=specs(index,2); value=expected(step,slot); tolerance=1e-9+specs(index,3)*abs(value);
            for delta=[-1.0001 -.9999 .9999 1.0001]
                LD7.answers=original; LD7.step=step; LD7.done(step)=%f;
                LD7.answers(step,slot)=msprintf("%.17g",value+delta*tolerance); ld7_check_step();
                accepted=LD7.done(step); assert_checkequal(accepted,abs(delta)<1);
                cases($+1)=struct("report",bench_report_data("LD7"),"accepted",accepted);
            end
        end
        for slot=1:3
            for raw=[string(expected(6,slot))+",0" string(3-expected(6,slot)) "" "1+1"]
                LD7.answers=original; LD7.step=6; LD7.done(6)=%f; LD7.answers(6,slot)=raw; ld7_check_step();
                accepted=LD7.done(6); assert_checkequal(accepted,raw==string(expected(6,slot))+",0");
                cases($+1)=struct("report",bench_report_data("LD7"),"accepted",accepted);
            end
        end
    end
    mputl(toJSON(cases),out+"tolerance-cases.json");
    mputl("LD7_PASS: assessment/learning split; autosave/restore/close; 3 GUI variants; safe darbine/TE/virtual-TJ wirings; MNA readings; actual report button; saved wiring evidence; comma/raw input; demo isolation; 39 geometry cases including resize callback; grading comparisons",out+"verdict.log"); exit(0);
catch
    mputl("LD7_FAIL: "+strcat(lasterror()," | "),out+"verdict.log"); disp(lasterror()); exit(1);
end
