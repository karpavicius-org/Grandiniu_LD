mode(-1); funcprot(0);
root=getenv("LD12_TEST_RUNTIME")+"/"; out=getenv("LD12_TEST_OUT")+"/"; source=getenv("LD12_TEST_SOURCE")+"/";
global LD12 LD12_CANCEL;
function values=x_mdialog(varargin)
    global LD12_CANCEL;
    if LD12_CANCEL then values=[]; else values=["17";"Patikra Žąsė";"TEST"]; end
endfunction
function selected=messagebox(varargin)
    if varargin(2)<>"Jūsų priskirtos reikšmės" then error("Netikėtas dialogas"); end
    selected=1;
endfunction
function capture_ld12(name)
    global LD12;
    if getos()<>"Linux" then return; end
    LD12.fig.figure_name="LD12 PATIKRA "+name; show_window(LD12.fig); sleep(500);
    command="/usr/bin/python3 """+getenv("LD12_TEST_RUNTIME")+"/capture_window.py"" ""LD12 PATIKRA "+name+""" """+getenv("LD12_TEST_OUT")+"/"+name+".png""";
    assert_checkequal(host(command),0);
endfunction
try
    LD12=struct(); LD12_CANCEL=%t; exec(root+"LD12/LD12.sce",-1); assert_checkfalse(isfield(LD12,"fig"));
    LD12_CANCEL=%f; exec(root+"LD12/LD12.sce",-1); assert_checkequal(LD12.student.number,17);
    assert_checkequal(LD12.student.bank,"LD12-64-A-2026"); delete(LD12.fig);
    exec(root+"tests/workflows.sci",-1); exec(source+"tools/ergonomics.sci",-1);
    for number=[1 17 64]; bench_ld12_workflow(number,root,%t); end
    LD12=struct("cfg",ld12_variant_config(1),"student",student_profile(1,"Patikra Žąsė","TEST","LD12"),"ui",struct("headless",%f));
    ld12_start(); report=bench_report_data("LD12");
    for key=["s1" "s3"]; assert_checkequal(length(report.evidence.wiring(key).pairs),0); end
    assert_checkequal(length(report.observations),0);
    ld12_set_step(7); ld12_jump_step(%nan); assert_checkequal(LD12.step,1);
    ld12_set_mode(0); ld12_set_mode(%nan); ld12_set_mode(1.5); assert_checkequal(LD12.wireMode,1);
    ld12_toggle_solution(); assert_checkfalse(LD12.demoMode); assert_checkfalse(LD12.practice_used);
    LD12.assessment=%f; LD12.practice_used=%t; ld12_render_stage();
    ld12_toggle_solution(); assert_checktrue(LD12.demoMode); rejected=%f;
    try report=bench_report_data("LD12"); catch rejected=%t; end
    assert_checktrue(rejected); ld12_measure(); ld12_check_step(); assert_checkfalse(or(LD12.done));
    ld12_toggle_solution(); assert_checkequal(size(LD12.journal,1),0); assert_checkequal(size(LD12.wires,1),0);
    LD12.assessment=%t; LD12.practice_used=%f; ld12_render_stage();
    descriptor=mopen(out+"geometry.tsv","wt"); sizes=[1280 720;1280 800;1600 900];
    for dimension=1:3
        geometry_size(LD12.fig,sizes(dimension,:));
        for step=1:6
            LD12.step=step; LD12.wireMode=ld12_stage_mode(step); LD12.wires=ld12_canonical_wires(LD12.wireMode);
            LD12.powerOn=%t; LD12.switchOn=%t; ld12_render_stage();
            label=msprintf("LD12-E%d-%dx%d",step,sizes(dimension,1),sizes(dimension,2));
            geometry_dump(LD12.fig,label,descriptor);
            LD12.wires=LD12.wires(:,[2 1]); ld12_render_wires(); geometry_dump(LD12.fig,label+"-reverse",descriptor);
            if dimension==2 & step>=2 then capture_ld12("E"+string(step)); end
        end
    end
    LD12.ui.answerEdits(10).string="1,0";
    for dimension=[1 3 2]
        geometry_size(LD12.fig,sizes(dimension,:));
        assert_checktrue(LD12.fig.resizefcn<>""); execstr(LD12.fig.resizefcn);
        assert_checkequal(LD12.ui.answerEdits(10).string,"1,0");
        geometry_dump(LD12.fig,"LD12-resize-"+string(dimension),descriptor);
    end
    mclose(descriptor);
    report=bench_report_data("LD12");
    for key=["s1" "s3"]; assert_checkequal(length(report.evidence.wiring(key).pairs),0); end
    LD12.cfg=ld12_variant_config(64); LD12.student=student_profile(64,"Patikra Žąsė","TEST","LD12");
    // Rodmenys abiejuose režimuose; kompensacijos poveikis matomas kortelėse.
    for mode=1:2
        LD12.step=2; if mode==2 then LD12.step=4; end
        LD12.wireMode=mode; LD12.wires=ld12_canonical_wires(mode); LD12.phase=1;
        LD12.powerOn=%t; LD12.switchOn=%t; ld12_render_stage();
        [u,i,ok,msg]=ld12_measure_values();
        assert_checktrue(ok);
        handle=findobj("tag","reading:A"); assert_checkequal(handle.string,msprintf("%.3f mA",i));
        handle=findobj("tag","reading:V"); assert_checkequal(handle.string,msprintf("%.4f V",u));
        if mode==2 then
            // Trikampyje fazinė įtampa = Ul; fazinė srovė ~√3 karto didesnė.
            assert_checkalmostequal(u,LD12.cfg.Ul,1e-9,1e-9);
            assert_checktrue(i>i1_saved*1.5);
            geometry_size(LD12.fig,[1280 800]); execstr(LD12.fig.resizefcn); capture_ld12("trikampis-V64");
        else
            assert_checkalmostequal(u,LD12.cfg.Ul/sqrt(3),1e-9,1e-9);
        end
        bench_ld12_action("ld12_measure()");
        if mode==1 then i1_saved=i; end
    end
    assert_checkequal(size(LD12.journal,1),2);
    journal=LD12.journal; bench_ld12_action("ld12_measure()"); assert_checkequal(LD12.journal,journal);
    ld12_set_step(5); LD12.ui.answerEdits(6).string="10,321";
    snapshot_path=bench_save_snapshot("LD12"); snapshot=bench_read_snapshot(snapshot_path,"LD12");
    ld12_restart(); bench_restore_snapshot(snapshot);
    assert_checkequal(LD12.ui.answerEdits(6).string,"10,321"); assert_checkequal(LD12.journal,journal);
    assert_checktrue(LD12.assessment); assert_checkfalse(LD12.powerOn); assert_checkfalse(LD12.switchOn);
    ld12_toggle_solution(); assert_checkfalse(LD12.demoMode);
    LD12.assessment=%f; LD12.practice_used=%t; ld12_toggle_solution(); assert_checktrue(LD12.demoMode);
    assert_checkequal(size(LD12.journal,1),1); ld12_toggle_solution(); assert_checkequal(LD12.journal,journal);
    ld12_restart(); assert_checkfalse(LD12.assessment); assert_checktrue(LD12.practice_used);
    bench_restore_snapshot(snapshot); LD12.assessment=%f; LD12.practice_used=%t;
    LD12.done(5)=%t; LD12.ui.answerEdits(6).string="1+2"; bench_ld12_primary();
    assert_checkfalse(LD12.done(5)); assert_checkequal(LD12.step,5); assert_checkequal(LD12.ui.answerEdits(6).string,"1+2");
    expected=ld12_expected_answers(); bench_ld12_answers(5,expected(5,1:4));
    LD12.ui.answerEdits(6).string=strsubst(LD12.ui.answerEdits(6).string,".",","); bench_ld12_primary();
    assert_checkequal(LD12.step,6); assert_checktrue(LD12.done(5));
    ld12_set_step(1); ld12_restore_stage(); assert_checkequal(size(LD12.wires,1),0);
    assert_checkequal(size(ld12_journal_rows(1),1),0); assert_checkfalse(LD12.done(1));
    report=bench_report_data("LD12"); assert_checkequal(length(report.evidence.wiring.s1.pairs),0);
    ld12_show_wiring_guide(); window=gcf(); assert_checktrue(window<>LD12.fig); delete(window);
    ld12_show_stand_map(); window=gcf(); assert_checktrue(window<>LD12.fig); delete(window);
    delete(LD12.fig);
    cases=list();
    // [etapas, laukelis, santykinė paklaida; 0 = absoliuti 0,005 V (trikampio Uf)].
    specs=[1 1 .01;2 1 .02;3 1 0;4 1 .02;5 1 .02;5 2 .02;5 3 .02];
    for number=[1 17 64]
        bench_ld12_workflow(number,root,%f); expected=ld12_expected_answers(); original=LD12.answers;
        if number==1 then
            LD12.autosave_enabled=%t; bench_autosave("LD12"); bench_autosave("LD12"); bench_autosave("LD12");
            assert_checkequal(size(LD12.autosave_paths,"*"),2); assert_checkequal(LD12.autosave_error,"");
            // Užbaigtos ataskaitos: vertinimas ir suvestinės teisė nepriklauso.
            LD12.answers(2,1)="wrong";
            cases($+1)=struct("report",bench_report_data("LD12"),"accepted",%f);
            LD12.answers=original; LD12.practice_used=%t;
            cases($+1)=struct("report",bench_report_data("LD12"),"accepted",%t);
            LD12.practice_used=%f;
        end
        for index=1:size(specs,1)
            step=specs(index,1); slot=specs(index,2); value=expected(step,slot);
            if specs(index,3)==0 then tolerance=.005; else tolerance=1e-9+specs(index,3)*abs(value); end
            for delta=[-1.0001 -.9999 .9999 1.0001]
                LD12.answers=original; LD12.step=step; LD12.done(step)=%f;
                if or(step==[1 3]) then
                    LD12.wireMode=ld12_stage_mode(step); LD12.wires=ld12_canonical_wires(LD12.wireMode);
                    LD12.journal($+1,:)=[5, 1, LD12.wireMode, 1, LD12.wireMode];
                end
                LD12.answers(step,slot)=msprintf("%.17g",value+delta*tolerance); ld12_check_step();
                accepted=LD12.done(step); assert_checkequal(accepted,abs(delta)<1);
                cases($+1)=struct("report",bench_report_data("LD12"),"accepted",accepted);
            end
        end
        for slot=1:3
            for raw=[string(expected(6,slot))+",0" string(3-expected(6,slot)) "" "1+1"]
                LD12.answers=original; LD12.step=6; LD12.done(6)=%f; LD12.answers(6,slot)=raw; ld12_check_step();
                accepted=LD12.done(6); assert_checkequal(accepted,raw==string(expected(6,slot))+",0");
                cases($+1)=struct("report",bench_report_data("LD12"),"accepted",accepted);
            end
        end
    end
    mputl(toJSON(cases),out+"tolerance-cases.json");
    mputl("LD12_PASS: 3 GUI variants; star and delta wirings; Uf=Ul/sqrt(3) and phase currents from MNA; Il=sqrt(3)If and 3x power relation; actual report button; comma input without Enter; demo isolation; draft restore; 39 geometry cases including resize callback; 140 grading comparisons",out+"verdict.log"); exit(0);
catch
    mputl("LD12_FAIL: "+strcat(lasterror()," | "),out+"verdict.log"); disp(lasterror()); exit(1);
end
