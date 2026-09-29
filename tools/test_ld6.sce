mode(-1); funcprot(0);
root=getenv("LD6_TEST_RUNTIME")+"/"; out=getenv("LD6_TEST_OUT")+"/"; source=getenv("LD6_TEST_SOURCE")+"/";
global LD6 LD6_CANCEL;
function values=x_mdialog(varargin)
    global LD6_CANCEL;
    if LD6_CANCEL then values=[]; else values=["17";"Patikra Žąsė";"TEST"]; end
endfunction
function selected=messagebox(varargin)
    if varargin(2)<>"Jūsų priskirtos reikšmės" then error("Netikėtas dialogas"); end
    selected=1;
endfunction
function capture_ld6(name)
    global LD6;
    if getos()<>"Linux" then return; end
    LD6.fig.figure_name="LD6 PATIKRA "+name; show_window(LD6.fig); sleep(250);
    command="/usr/bin/python3 """+getenv("LD6_TEST_RUNTIME")+"/capture_window.py"" ""LD6 PATIKRA "+name+""" """+getenv("LD6_TEST_OUT")+"/"+name+".png""";
    assert_checkequal(host(command),0);
endfunction
try
    LD6=struct(); LD6_CANCEL=%t; exec(root+"LD6/LD6.sce",-1); assert_checkfalse(isfield(LD6,"fig"));
    LD6_CANCEL=%f; exec(root+"LD6/LD6.sce",-1); assert_checkequal(LD6.student.number,17);
    assert_checkequal(LD6.student.bank,"LD6-64-B-2026");
    assert_checktrue(LD6.assessment); assert_checkfalse(LD6.practice_used);
    assert_checkequal(LD6.fig.closerequestfcn,"ld6_close()");
    delete(LD6.fig);
    exec(root+"tests/workflows.sci",-1); exec(source+"tools/ergonomics.sci",-1);
    for number=[1 17 64]; bench_ld6_workflow(number,root,%t); end
    LD6=struct("cfg",ld6_variant_config(1),"student",student_profile(1,"Patikra Žąsė","TEST","LD6"),"ui",struct("headless",%f));
    ld6_start(); report=bench_report_data("LD6");
    for stage=[1 3 4 5]; assert_checkequal(length(report.evidence.wiring("s"+string(stage)).pairs),0); end
    assert_checkequal(length(report.observations),0);
    assert_checkequal(report.mode,"assessment"); assert_checkfalse(report.practice_used);
    ld6_set_mode(4); assert_checkequal(size(LD6.wires,1),0);
    ld6_set_mode(0); ld6_set_mode(%nan); ld6_set_mode(1.5); assert_checkequal(LD6.wireMode,4);
    ld6_set_step(7); ld6_jump_step(%nan); assert_checkequal(LD6.step,1);
    assert_checkfalse(ld6_valid_index([1 2],4));
    // Formal mode blocks the worked example.
    ld6_toggle_solution(); assert_checkfalse(LD6.demoMode); assert_checkfalse(LD6.practice_used);
    // Learning mode permits the example; demo state cannot be exported.
    LD6.assessment=%f; LD6.practice_used=%t; ld6_render_stage();
    ld6_toggle_solution(); assert_checktrue(LD6.demoMode); rejected=%f;
    try report=bench_report_data("LD6"); catch rejected=%t; end
    assert_checktrue(rejected); ld6_measure(); ld6_check_step(); assert_checkfalse(or(LD6.done));
    ld6_toggle_solution(); assert_checkequal(size(LD6.journal,1),0); assert_checkequal(size(LD6.wires,1),0);
    LD6.assessment=%t; LD6.practice_used=%f; ld6_render_stage();
    descriptor=mopen(out+"geometry.tsv","wt"); sizes=[1280 720;1280 800;1600 900];
    for dimension=1:3
        geometry_size(LD6.fig,sizes(dimension,:));
        for step=1:6
            LD6.step=step; LD6.wireMode=ld6_stage_mode(step); LD6.wires=ld6_canonical_wires(LD6.wireMode);
            LD6.powerOn=%t; LD6.switchOn=%t; ld6_render_stage();
            label=msprintf("LD6-E%d-%dx%d",step,sizes(dimension,1),sizes(dimension,2));
            geometry_dump(LD6.fig,label,descriptor);
            LD6.wires=LD6.wires(:,[2 1]); ld6_render_wires(); geometry_dump(LD6.fig,label+"-reverse",descriptor);
            if dimension==2 & step>=2 then capture_ld6("E"+string(step)); end
        end
    end
    // Invoke the registered native resize callback without re-rendering a stage.
    // This checks the callback contract; it does not emulate an OS drag event.
    LD6.ui.answerEdits(10).string="1,0";
    for dimension=[1 3 2]
        geometry_size(LD6.fig,sizes(dimension,:));
        assert_checktrue(LD6.fig.resizefcn<>""); execstr(LD6.fig.resizefcn);
        assert_checkequal(LD6.ui.answerEdits(10).string,"1,0");
        geometry_dump(LD6.fig,"LD6-resize-"+string(dimension),descriptor);
    end
    mclose(descriptor);
    report=bench_report_data("LD6");
    for stage=[1 3 4 5]; assert_checkequal(length(report.evidence.wiring("s"+string(stage)).pairs),0); end
    LD6.cfg=ld6_variant_config(64); LD6.student=student_profile(64,"Patikra Žąsė","TEST","LD6");
    for mode=1:4
        LD6.wireMode=mode; LD6.wires=ld6_canonical_wires(mode); LD6.powerOn=%t; LD6.switchOn=%t;
        LD6.step=mode+1; ld6_render_stage(); values=ld6_reference(mode);
        handle=findobj("tag","reading:A"); assert_checkequal(handle.string,msprintf("%.3f mA",values(2)));
        handle=findobj("tag","reading:V"); assert_checkequal(handle.string,msprintf("%g V",values(1)));
        bench_ld6_action("ld6_measure()"); assert_checkalmostequal(ld6_journal_rows(mode),values,1e-9,1e-9);
        if mode==3 then assert_checktrue(values(2)<0); end
        if mode==4 then
            assert_checktrue(values(3)<0); assert_checkalmostequal(values(3)+values(4),values(2),1e-9,1e-9);
            geometry_size(LD6.fig,[1280 800]); execstr(LD6.fig.resizefcn); capture_ld6("lygiagretus-V64");
        end
    end
    journal=LD6.journal; ld6_measure(); assert_checkequal(LD6.journal,journal);
    values=ld6_reference(4); bench_ld6_answers(5,values);
    LD6.ui.answerEdits(6).string="10,321";
    snapshot_path=bench_save_snapshot("LD6"); snapshot=bench_read_snapshot(snapshot_path,"LD6");
    ld6_restart(); bench_restore_snapshot(snapshot);
    assert_checkequal(LD6.ui.answerEdits(6).string,"10,321"); assert_checkequal(LD6.journal,journal);
    assert_checktrue(LD6.assessment); assert_checkfalse(LD6.powerOn); assert_checkfalse(LD6.switchOn);
    // Formal assessment preserves invalid raw text and advances without revealing the key.
    values=ld6_reference(4); bench_ld6_answers(5,values); LD6.ui.answerEdits(6).string="1+2";
    bench_ld6_primary(); assert_checkequal(LD6.step,6); assert_checktrue(LD6.done(5));
    assert_checkequal(LD6.answers(5,1),"1+2"); assert_checktrue(strindex(LD6.ui.statusMain.string,"Patikrinkite")==[]);
    // Learning mode still validates locally.
    ld6_jump_step(5); LD6.assessment=%f; LD6.practice_used=%t; ld6_render_stage();
    values=ld6_reference(4); bench_ld6_answers(5,values); LD6.ui.answerEdits(6).string="1+2";
    bench_ld6_primary(); assert_checkfalse(LD6.done(5)); assert_checkequal(LD6.step,5);
    assert_checktrue(strindex(LD6.ui.statusMain.string,"Patikrinkite")<>[]);
    bench_ld6_answers(5,values); LD6.ui.answerEdits(6).string=strsubst(LD6.ui.answerEdits(6).string,".",","); bench_ld6_primary();
    assert_checkequal(LD6.step,6); assert_checktrue(LD6.done(5));
    ld6_toggle_solution(); assert_checktrue(LD6.demoMode); assert_checktrue(LD6.practice_used);
    ld6_toggle_solution(); assert_checkfalse(LD6.demoMode);
    LD6.assessment=%t; LD6.practice_used=%f;
    ld6_set_step(5); ld6_restore_stage(); assert_checkequal(size(LD6.wires,1),0);
    assert_checkequal(size(ld6_journal_rows(4),1),0); assert_checkfalse(LD6.done(5));
    report=bench_report_data("LD6"); assert_checkequal(length(report.evidence.wiring.s5.pairs),0);
    ld6_show_wiring_guide(); window=gcf(); assert_checktrue(window<>LD6.fig); delete(window);
    ld6_show_stand_map(); window=gcf(); assert_checktrue(window<>LD6.fig); delete(window);
    ld6_close(); assert_checkfalse(is_handle_valid(LD6.fig));
    cases=list(); specs=[2 1 .01;4 1 .01;4 2 .02;4 3 .01;4 4 .02;5 1 .01;5 2 .02;5 3 .02;5 4 .02];
    for number=[1 17 64]
        bench_ld6_workflow(number,root,%f); expected=ld6_expected_answers(); original=LD6.answers;
        if number==1 then
            LD6.autosave_enabled=%t; bench_autosave("LD6"); bench_autosave("LD6"); bench_autosave("LD6");
            assert_checkequal(size(LD6.autosave_paths,"*"),2); assert_checkequal(LD6.autosave_error,"");
        end
        for index=1:size(specs,1)
            step=specs(index,1); slot=specs(index,2); value=expected(step,slot); tolerance=1e-9+specs(index,3)*abs(value);
            for delta=[-1.0001 -.9999 .9999 1.0001]
                LD6.answers=original; LD6.step=step; LD6.done(step)=%f;
                LD6.answers(step,slot)=msprintf("%.17g",value+delta*tolerance); ld6_check_step();
                accepted=LD6.done(step); assert_checkequal(accepted,abs(delta)<1);
                cases($+1)=struct("report",bench_report_data("LD6"),"accepted",accepted);
            end
        end
        for slot=1:2
            for raw=[string(expected(6,slot))+",0" string(3-expected(6,slot)) "" "1+1"]
                LD6.answers=original; LD6.step=6; LD6.done(6)=%f; LD6.answers(6,slot)=raw; ld6_check_step();
                accepted=LD6.done(6); assert_checkequal(accepted,raw==string(expected(6,slot))+",0");
                cases($+1)=struct("report",bench_report_data("LD6"),"accepted",accepted);
            end
        end
    end
    mputl(toJSON(cases),out+"tolerance-cases.json");
    mputl("LD6_PASS: assessment/learning split; autosave/restore/close; 3 GUI variants; four safely wired modes; signed MNA readings; actual report button; saved wiring evidence; comma/raw input; demo isolation; 39 geometry cases including resize callback; grading comparisons",out+"verdict.log"); exit(0);
catch
    mputl("LD6_FAIL: "+strcat(lasterror()," | "),out+"verdict.log"); disp(lasterror()); exit(1);
end
