mode(-1); funcprot(0);
root=getenv("LD11_TEST_RUNTIME")+"/"; out=getenv("LD11_TEST_OUT")+"/"; source=getenv("LD11_TEST_SOURCE")+"/";
global LD11 LD11_CANCEL;
function values=x_mdialog(varargin)
    global LD11_CANCEL;
    if LD11_CANCEL then values=[]; else values=["17";"Patikra Žąsė";"TEST"]; end
endfunction
function selected=messagebox(varargin)
    if varargin(2)<>"Jūsų priskirtos reikšmės" then error("Netikėtas dialogas"); end
    selected=1;
endfunction
function capture_ld11(name)
    global LD11;
    if getos()<>"Linux" then return; end
    LD11.fig.figure_name="LD11 PATIKRA "+name; show_window(LD11.fig); sleep(500);
    command="/usr/bin/python3 """+getenv("LD11_TEST_RUNTIME")+"/capture_window.py"" ""LD11 PATIKRA "+name+""" """+getenv("LD11_TEST_OUT")+"/"+name+".png""";
    assert_checkequal(host(command),0);
endfunction
try
    LD11=struct(); LD11_CANCEL=%t; exec(root+"LD11/LD11.sce",-1); assert_checkfalse(isfield(LD11,"fig"));
    LD11_CANCEL=%f; exec(root+"LD11/LD11.sce",-1); assert_checkequal(LD11.student.number,17);
    assert_checkequal(LD11.student.bank,"LD11-64-A-2026"); delete(LD11.fig);
    exec(root+"tests/workflows.sci",-1); exec(source+"tools/ergonomics.sci",-1);
    for number=[1 17 64]; bench_ld11_workflow(number,root,%t); end
    LD11=struct("cfg",ld11_variant_config(1),"student",student_profile(1,"Patikra Žąsė","TEST","LD11"),"ui",struct("headless",%f));
    ld11_start(); report=bench_report_data("LD11");
    for key=["s1" "s4"]; assert_checkequal(length(report.evidence.wiring(key).pairs),0); end
    assert_checkequal(length(report.observations),0);
    ld11_set_step(7); ld11_jump_step(%nan); assert_checkequal(LD11.step,1);
    ld11_set_mode(0); ld11_set_mode(%nan); ld11_set_mode(1.5); assert_checkequal(LD11.wireMode,1);
    ld11_toggle_solution(); assert_checkfalse(LD11.demoMode); assert_checkfalse(LD11.practice_used);
    LD11.assessment=%f; LD11.practice_used=%t; ld11_render_stage();
    ld11_toggle_solution(); assert_checktrue(LD11.demoMode); rejected=%f;
    try report=bench_report_data("LD11"); catch rejected=%t; end
    assert_checktrue(rejected); ld11_measure(); ld11_check_step(); assert_checkfalse(or(LD11.done));
    ld11_toggle_solution(); assert_checkequal(size(LD11.journal,1),0); assert_checkequal(size(LD11.wires,1),0);
    LD11.assessment=%t; LD11.practice_used=%f; ld11_render_stage();
    descriptor=mopen(out+"geometry.tsv","wt"); sizes=[1280 720;1280 800;1600 900];
    for dimension=1:3
        geometry_size(LD11.fig,sizes(dimension,:));
        for step=1:6
            LD11.step=step; LD11.wireMode=ld11_stage_mode(step); LD11.wires=ld11_canonical_wires(LD11.wireMode);
            LD11.powerOn=%t; LD11.switchOn=%t; ld11_render_stage();
            label=msprintf("LD11-E%d-%dx%d",step,sizes(dimension,1),sizes(dimension,2));
            geometry_dump(LD11.fig,label,descriptor);
            LD11.wires=LD11.wires(:,[2 1]); ld11_render_wires(); geometry_dump(LD11.fig,label+"-reverse",descriptor);
            if dimension==2 & step>=2 then capture_ld11("E"+string(step)); end
        end
    end
    LD11.ui.answerEdits(10).string="1,0";
    for dimension=[1 3 2]
        geometry_size(LD11.fig,sizes(dimension,:));
        assert_checktrue(LD11.fig.resizefcn<>""); execstr(LD11.fig.resizefcn);
        assert_checkequal(LD11.ui.answerEdits(10).string,"1,0");
        geometry_dump(LD11.fig,"LD11-resize-"+string(dimension),descriptor);
    end
    mclose(descriptor);
    report=bench_report_data("LD11");
    for key=["s1" "s4"]; assert_checkequal(length(report.evidence.wiring(key).pairs),0); end
    LD11.cfg=ld11_variant_config(64); LD11.student=student_profile(64,"Patikra Žąsė","TEST","LD11");
    // Rodmenys abiejuose režimuose; kompensacijos poveikis matomas kortelėse.
    for mode=1:2
        LD11.step=2*mode-0*1; if mode==2 then LD11.step=4; end
        LD11.wireMode=mode; LD11.wires=ld11_canonical_wires(mode);
        LD11.powerOn=%t; LD11.switchOn=%t; ld11_render_stage();
        [u,i,ok,msg,p]=ld11_measure_values();
        assert_checktrue(ok);
        handle=findobj("tag","reading:A"); assert_checkequal(handle.string,msprintf("%.3f mA",i));
        handle=findobj("tag","reading:W"); assert_checkequal(handle.string,msprintf("%.3f mW",p));
        handle=findobj("tag","reading:V"); assert_checkequal(handle.string,msprintf("%.4f V",u));
        bench_ld11_action("ld11_measure()");
        if mode==1 then
            assert_checktrue(and([i p] > 0));
        else
            // Po kompensacijos: I mažesnis, P toks pat, cos φ → 1.
            assert_checktrue(i<i1_saved);
            assert_checkalmostequal(p,p1_saved,1e-9,1e-9);
            geometry_size(LD11.fig,[1280 800]); execstr(LD11.fig.resizefcn); capture_ld11("su-Ck-V64");
        end
        if mode==1 then i1_saved=i; p1_saved=p; end
    end
    assert_checkequal(size(LD11.journal,1),2);
    journal=LD11.journal; bench_ld11_action("ld11_measure()"); assert_checkequal(LD11.journal,journal);
    ld11_set_step(5); LD11.ui.answerEdits(6).string="10,321";
    snapshot_path=bench_save_snapshot("LD11"); snapshot=bench_read_snapshot(snapshot_path,"LD11");
    ld11_restart(); bench_restore_snapshot(snapshot);
    assert_checkequal(LD11.ui.answerEdits(6).string,"10,321"); assert_checkequal(LD11.journal,journal);
    assert_checktrue(LD11.assessment); assert_checkfalse(LD11.powerOn); assert_checkfalse(LD11.switchOn);
    ld11_toggle_solution(); assert_checkfalse(LD11.demoMode);
    LD11.assessment=%f; LD11.practice_used=%t; ld11_toggle_solution(); assert_checktrue(LD11.demoMode);
    assert_checkequal(size(LD11.journal,1),1); ld11_toggle_solution(); assert_checkequal(LD11.journal,journal);
    ld11_restart(); assert_checkfalse(LD11.assessment); assert_checktrue(LD11.practice_used);
    bench_restore_snapshot(snapshot); LD11.assessment=%f; LD11.practice_used=%t;
    LD11.done(5)=%t; LD11.ui.answerEdits(6).string="1+2"; bench_ld11_primary();
    assert_checkfalse(LD11.done(5)); assert_checkequal(LD11.step,5); assert_checkequal(LD11.ui.answerEdits(6).string,"1+2");
    expected=ld11_expected_answers(); bench_ld11_answers(5,expected(5,1:4));
    LD11.ui.answerEdits(6).string=strsubst(LD11.ui.answerEdits(6).string,".",","); bench_ld11_primary();
    assert_checkequal(LD11.step,6); assert_checktrue(LD11.done(5));
    ld11_set_step(1); ld11_restore_stage(); assert_checkequal(size(LD11.wires,1),0);
    assert_checkequal(size(ld11_journal_rows(1),1),0); assert_checkfalse(LD11.done(1));
    report=bench_report_data("LD11"); assert_checkequal(length(report.evidence.wiring.s1.pairs),0);
    ld11_show_wiring_guide(); window=gcf(); assert_checktrue(window<>LD11.fig); delete(window);
    ld11_show_stand_map(); window=gcf(); assert_checktrue(window<>LD11.fig); delete(window);
    delete(LD11.fig);
    cases=list(); specs=[1 1 .01;2 1 .02;2 2 .02;2 3 .02;3 1 .03;5 1 .02;5 2 .02;5 3 .02;5 4 .02];
    for number=[1 17 64]
        bench_ld11_workflow(number,root,%f); expected=ld11_expected_answers(); original=LD11.answers;
        if number==1 then
            LD11.autosave_enabled=%t; bench_autosave("LD11"); bench_autosave("LD11"); bench_autosave("LD11");
            assert_checkequal(size(LD11.autosave_paths,"*"),2); assert_checkequal(LD11.autosave_error,"");
            // Užbaigtos ataskaitos: vertinimas ir suvestinės teisė nepriklauso.
            LD11.answers(2,1)="wrong";
            cases($+1)=struct("report",bench_report_data("LD11"),"accepted",%f);
            LD11.answers=original; LD11.practice_used=%t;
            cases($+1)=struct("report",bench_report_data("LD11"),"accepted",%t);
            LD11.practice_used=%f;
        end
        for index=1:size(specs,1)
            step=specs(index,1); slot=specs(index,2); value=expected(step,slot); tolerance=1e-9+specs(index,3)*abs(value);
            for delta=[-1.0001 -.9999 .9999 1.0001]
                LD11.answers=original; LD11.step=step; LD11.done(step)=%f;
                if or(step==[1 4]) then
                    LD11.wireMode=ld11_stage_mode(step); LD11.wires=ld11_canonical_wires(LD11.wireMode);
                    LD11.journal($+1,:)=[5, 1, LD11.wireMode, 1, LD11.wireMode];
                end
                LD11.answers(step,slot)=msprintf("%.17g",value+delta*tolerance); ld11_check_step();
                accepted=LD11.done(step); assert_checkequal(accepted,abs(delta)<1);
                cases($+1)=struct("report",bench_report_data("LD11"),"accepted",accepted);
            end
        end
        for slot=1:3
            for raw=[string(expected(6,slot))+",0" string(3-expected(6,slot)) "" "1+1"]
                LD11.answers=original; LD11.step=6; LD11.done(6)=%f; LD11.answers(6,slot)=raw; ld11_check_step();
                accepted=LD11.done(6); assert_checkequal(accepted,raw==string(expected(6,slot))+",0");
                cases($+1)=struct("report",bench_report_data("LD11"),"accepted",accepted);
            end
        end
    end
    mputl(toJSON(cases),out+"tolerance-cases.json");
    mputl("LD11_PASS: 3 GUI variants; coil wiring with and without Ck; wattmeter readings; compensation keeps P, cuts S and I, cos phi toward 1; actual report button; comma input without Enter; demo isolation; draft restore; 39 geometry cases including resize callback; 148 grading comparisons",out+"verdict.log"); exit(0);
catch
    mputl("LD11_FAIL: "+strcat(lasterror()," | "),out+"verdict.log"); disp(lasterror()); exit(1);
end
