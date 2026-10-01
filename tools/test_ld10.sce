mode(-1); funcprot(0);
root=getenv("LD10_TEST_RUNTIME")+"/"; out=getenv("LD10_TEST_OUT")+"/"; source=getenv("LD10_TEST_SOURCE")+"/";
global LD10 LD10_CANCEL;
function values=x_mdialog(varargin)
    global LD10_CANCEL;
    if LD10_CANCEL then values=[]; else values=["17";"Patikra Žąsė";"TEST"]; end
endfunction
function selected=messagebox(varargin)
    if varargin(2)<>"Jūsų priskirtos reikšmės" then error("Netikėtas dialogas"); end
    selected=1;
endfunction
function capture_ld10(name)
    global LD10;
    if getos()<>"Linux" then return; end
    LD10.fig.figure_name="LD10 PATIKRA "+name; show_window(LD10.fig); sleep(500);
    command="/usr/bin/python3 """+getenv("LD10_TEST_RUNTIME")+"/capture_window.py"" ""LD10 PATIKRA "+name+""" """+getenv("LD10_TEST_OUT")+"/"+name+".png""";
    assert_checkequal(host(command),0);
endfunction
try
    LD10=struct(); LD10_CANCEL=%t; exec(root+"LD10/LD10.sce",-1); assert_checkfalse(isfield(LD10,"fig"));
    LD10_CANCEL=%f; exec(root+"LD10/LD10.sce",-1); assert_checkequal(LD10.student.number,17);
    assert_checkequal(LD10.student.bank,"LD10-64-A-2026"); delete(LD10.fig);
    exec(root+"tests/workflows.sci",-1); exec(source+"tools/ergonomics.sci",-1);
    for number=[1 17 64]; bench_ld10_workflow(number,root,%t); end
    LD10=struct("cfg",ld10_variant_config(1),"student",student_profile(1,"Patikra Žąsė","TEST","LD10"),"ui",struct("headless",%f));
    ld10_start(); report=bench_report_data("LD10");
    assert_checkequal(length(report.evidence.wiring.s1.pairs),0);
    assert_checkequal(length(report.observations),0);
    ld10_set_step(7); ld10_jump_step(%nan); assert_checkequal(LD10.step,1);
    assert_checkfalse(ld10_valid_index([1 2],4));
    ld10_toggle_solution(); assert_checkfalse(LD10.demoMode); assert_checkfalse(LD10.practice_used);
    LD10.assessment=%f; LD10.practice_used=%t; ld10_render_stage();
    ld10_toggle_solution(); assert_checktrue(LD10.demoMode); rejected=%f;
    try report=bench_report_data("LD10"); catch rejected=%t; end
    assert_checktrue(rejected); ld10_measure(); ld10_check_step(); assert_checkfalse(or(LD10.done));
    ld10_toggle_solution(); assert_checkequal(size(LD10.journal,1),0); assert_checkequal(size(LD10.wires,1),0);
    LD10.assessment=%t; LD10.practice_used=%f; ld10_render_stage();
    descriptor=mopen(out+"geometry.tsv","wt"); sizes=[1280 720;1280 800;1600 900];
    for dimension=1:3
        geometry_size(LD10.fig,sizes(dimension,:));
        for step=1:6
            LD10.step=step; LD10.wires=ld10_canonical_wires();
            LD10.powerOn=%t; LD10.switchOn=%t; ld10_render_stage();
            label=msprintf("LD10-E%d-%dx%d",step,sizes(dimension,1),sizes(dimension,2));
            geometry_dump(LD10.fig,label,descriptor);
            LD10.wires=LD10.wires(:,[2 1]); ld10_render_wires(); geometry_dump(LD10.fig,label+"-reverse",descriptor);
            if dimension==2 & step>=2 then capture_ld10("E"+string(step)); end
        end
    end
    // Invoke the registered native resize callback without re-rendering a stage.
    // This checks the callback contract; it does not emulate an OS drag event.
    LD10.ui.answerEdits(10).string="1,0";
    for dimension=[1 3 2]
        geometry_size(LD10.fig,sizes(dimension,:));
        assert_checktrue(LD10.fig.resizefcn<>""); execstr(LD10.fig.resizefcn);
        assert_checkequal(LD10.ui.answerEdits(10).string,"1,0");
        geometry_dump(LD10.fig,"LD10-resize-"+string(dimension),descriptor);
    end
    mclose(descriptor);
    report=bench_report_data("LD10"); assert_checkequal(length(report.evidence.wiring.s1.pairs),0);
    LD10.cfg=ld10_variant_config(64); LD10.student=student_profile(64,"Patikra Žąsė","TEST","LD10");
    // Rodmenys visuose trijuose taškuose ir visuose taikiniuose.
    for step=[2 3 4]
        LD10.step=step; LD10.wires=ld10_canonical_wires(); LD10.powerOn=%t; LD10.switchOn=%t;
        LD10.freqPoint=step-1;
        ld10_render_stage();
        kk=[0.5 1 2]; f=kk(step-1)/sqrt(LD10.cfg.L*LD10.cfg.C)/(2*%pi);
        for target=1:4
            LD10.target=target; ld10_render_wires();
            v=bench_cpp_ac(4,LD10.cfg.E,f,LD10.cfg.R,LD10.cfg.L,LD10.cfg.C);
            cur=v(4)*1000; if target==1 then cur=v(5)*1000; elseif target==2 then cur=v(6)*1000; elseif target==3 then cur=v(7)*1000; end
            handle=findobj("tag","reading:A"); assert_checkequal(handle.string,msprintf("%.3f mA",cur));
        end
        handle=findobj("tag","reading:V"); assert_checkequal(handle.string,msprintf("%.4f V",LD10.cfg.E));
        if step==3 then
            // Ties f0: IL = IC, abi viršija bendrąją I (srovių kokybė Q > 1).
            assert_checkalmostequal(v(6),v(7),1e-9,1e-6);
            assert_checktrue(v(6)>v(4) & v(7)>v(4));
        end
        // Atstatome išjungtą maitinimą, nes measure_point pats perjungia.
        LD10.powerOn=%f; LD10.switchOn=%f; LD10.target=4;
        bench_ld10_measure_point(step);
        geometry_size(LD10.fig,[1280 800]); execstr(LD10.fig.resizefcn); capture_ld10("taskas-f"+string(step-1));
    end
    assert_checkequal(size(LD10.journal,1),12);
    journal=LD10.journal; bench_ld10_action("ld10_measure()"); assert_checkequal(LD10.journal,journal);
    ld10_set_step(5); LD10.ui.answerEdits(4).string="10,321";
    snapshot_path=bench_save_snapshot("LD10"); snapshot=bench_read_snapshot(snapshot_path,"LD10");
    ld10_restart(); bench_restore_snapshot(snapshot);
    assert_checkequal(LD10.ui.answerEdits(4).string,"10,321"); assert_checkequal(LD10.journal,journal);
    assert_checktrue(LD10.assessment); assert_checkfalse(LD10.powerOn); assert_checkfalse(LD10.switchOn);
    ld10_set_step(3); ld10_toggle_solution(); assert_checkfalse(LD10.demoMode);
    LD10.assessment=%f; LD10.practice_used=%t; ld10_toggle_solution(); assert_checktrue(LD10.demoMode);
    assert_checkequal(size(LD10.journal,1),4); ld10_toggle_solution(); assert_checkequal(LD10.journal,journal);
    ld10_restart(); assert_checkfalse(LD10.assessment); assert_checktrue(LD10.practice_used);
    bench_restore_snapshot(snapshot); LD10.assessment=%f; LD10.practice_used=%t;
    ld10_set_step(5); LD10.done(5)=%t; LD10.ui.answerEdits(4).string="1+2"; bench_ld10_primary();
    assert_checkfalse(LD10.done(5)); assert_checkequal(LD10.step,5); assert_checkequal(LD10.ui.answerEdits(4).string,"1+2");
    expected=ld10_expected_answers(); bench_ld10_answers(5,expected(5,1:6));
    LD10.ui.answerEdits(4).string=strsubst(LD10.ui.answerEdits(4).string,".",","); bench_ld10_primary();
    assert_checkequal(LD10.step,6); assert_checktrue(LD10.done(5));
    ld10_set_step(1); ld10_restore_stage(); assert_checkequal(size(LD10.wires,1),0);
    assert_checkequal(size(LD10.journal,1),0); assert_checkfalse(LD10.done(1));
    report=bench_report_data("LD10"); assert_checkequal(length(report.evidence.wiring.s1.pairs),0);
    ld10_show_wiring_guide(); window=gcf(); assert_checktrue(window<>LD10.fig); delete(window);
    ld10_show_stand_map(); window=gcf(); assert_checktrue(window<>LD10.fig); delete(window);
    delete(LD10.fig);
    cases=list(); specs=[1 1 .01;3 1 .03;3 2 0;5 1 .02;5 2 .02;5 3 .02;5 4 .02;5 5 .02;5 6 .02];
    for number=[1 17 64]
        bench_ld10_workflow(number,root,%f); expected=ld10_expected_answers(); original=LD10.answers;
        if number==1 then
            LD10.autosave_enabled=%t; bench_autosave("LD10"); bench_autosave("LD10"); bench_autosave("LD10");
            assert_checkequal(size(LD10.autosave_paths,"*"),2); assert_checkequal(LD10.autosave_error,"");
        end
        // Užbaigtos ataskaitos: vertinimas ir suvestinės teisė nepriklauso.
        if number==1 then
            LD10.answers(5,1)="wrong";
            cases($+1)=struct("report",bench_report_data("LD10"),"accepted",%f);
            LD10.answers=original; LD10.practice_used=%t;
            cases($+1)=struct("report",bench_report_data("LD10"),"accepted",%t);
            LD10.practice_used=%f;
        end
        for index=1:size(specs,1)
            step=specs(index,1); slot=specs(index,2); value=expected(step,slot);
            if specs(index,3)==0 then tolerance=.02; else tolerance=1e-9+specs(index,3)*abs(value); end
            for delta=[-1.0001 -.9999 .9999 1.0001]
                LD10.answers=original; LD10.step=step; LD10.done(step)=%f;
                if step==1 then LD10.wires=ld10_canonical_wires(); end
                LD10.answers(step,slot)=msprintf("%.17g",value+delta*tolerance); ld10_check_step();
                accepted=LD10.done(step); assert_checkequal(accepted,abs(delta)<1);
                cases($+1)=struct("report",bench_report_data("LD10"),"accepted",accepted);
            end
        end
        for slot=1:3
            for raw=[string(expected(6,slot))+",0" string(3-expected(6,slot)) "" "1+1"]
                LD10.answers=original; LD10.step=6; LD10.done(6)=%f; LD10.answers(6,slot)=raw; ld10_check_step();
                accepted=LD10.done(6); assert_checkequal(accepted,raw==string(expected(6,slot))+",0");
                cases($+1)=struct("report",bench_report_data("LD10"),"accepted",accepted);
            end
        end
    end
    mputl(toJSON(cases),out+"tolerance-cases.json");
    mputl("LD10_PASS: 3 GUI variants; single parallel RLC wiring; three frequency points; four ammeter targets; IL=IC at resonance with minimal total current; current triangle from own measurements; actual report button; comma input without Enter; demo isolation; draft restore; 39 geometry cases including resize callback; 144 grading comparisons",out+"verdict.log"); exit(0);
catch
    mputl("LD10_FAIL: "+strcat(lasterror()," | "),out+"verdict.log"); disp(lasterror()); exit(1);
end
