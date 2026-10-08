// Internal acceptance only: real Scilab controls, exported HTML and C++ verdicts.
mode(-1); funcprot(0);
root=getenv("LD5_TEST_RUNTIME")+"/"; out=getenv("LD5_TEST_OUT")+"/";
source=getenv("LD5_TEST_SOURCE")+"/";
global LD5 LD5_CANCEL;
function v=x_mdialog(varargin)
    global LD5_CANCEL;
    if LD5_CANCEL then v=[]; else v=["17";"Patikra Žąsė";"TEST"]; end
endfunction
function n=messagebox(varargin)
    if varargin(2)<>"Jūsų priskirtos reikšmės" then error("Netikėtas dialogas"); end
    n=1;
endfunction
function capture_ld5(name)
    global LD5;
    if getos()<>"Linux" then return; end
    LD5.fig.figure_name="LD5 PATIKRA "+name; show_window(LD5.fig); sleep(250);
    cmd="/usr/bin/python3 """+getenv("LD5_TEST_RUNTIME")+"/capture_window.py"" ""LD5 PATIKRA "+name+""" """+getenv("LD5_TEST_OUT")+"/"+name+".png""";
    assert_checkequal(host(cmd),0);
endfunction
try
    LD5=struct(); LD5_CANCEL=%t; exec(root+"LD5/LD5.sce",-1);
    assert_checkfalse(isfield(LD5,"fig"));
    LD5_CANCEL=%f; exec(root+"LD5/LD5.sce",-1);
    assert_checkequal(LD5.student.number,17);
    assert_checktrue(LD5.assessment); assert_checkfalse(LD5.practice_used);
    assert_checkequal(LD5.fig.closerequestfcn,"ld5_close()");
    delete(LD5.fig);
    exec(root+"tests/workflows.sci",-1); exec(source+"tools/ergonomics.sci",-1);
    for n=[1 17 64]; bench_ld5_workflow(n,root,%t); end
    LD5=struct("cfg",ld5_variant_config(1),"student",student_profile(1,"Patikra Žąsė","TEST","LD5"),"ui",struct("headless",%f));
    ld5_start();
    r=bench_report_data("LD5"); assert_checkequal(length(r.evidence.wiring.s1.pairs),0);
    assert_checkequal(length(r.observations),0); assert_checkequal(r.mode,"assessment"); assert_checkfalse(r.practice_used);
    // Formal mode blocks the worked example.
    ld5_toggle_solution(); assert_checkfalse(LD5.demoMode); assert_checkfalse(LD5.practice_used);
    // Learning mode permits the example; demo state itself cannot be exported.
    LD5.assessment=%f; LD5.practice_used=%t; ld5_render_stage();
    ld5_toggle_solution(); assert_checktrue(LD5.demoMode);
    rejected=%f; try r=bench_report_data("LD5"); catch rejected=%t; end
    assert_checktrue(rejected); ld5_check_step(); assert_checkfalse(or(LD5.done));
    assert_checkequal(size(LD5.journal,1),3);
    ld5_toggle_solution(); assert_checkequal(size(LD5.journal,1),0);
    LD5.assessment=%t; LD5.practice_used=%f; ld5_render_stage();
    ld5_jump_step(7); ld5_set_step(7); ld5_set_step(%nan); ld5_set_step(1.5);
    assert_checkequal(LD5.step,1);
    ld5_set_position(4); ld5_set_position(%nan); assert_checkequal(LD5.position,0);
    // Rewiring while energized is blocked before any terminal selection is retained.
    LD5.step=1; LD5.wires=ld5_canonical_wires(); LD5.powerOn=%t; LD5.switchOn=%t;
    beforeW=LD5.wires; ld5_terminal_click("E_P");
    assert_checkequal(LD5.pending,""); assert_checkequal(LD5.wires,beforeW);
    LD5.powerOn=%f; LD5.switchOn=%f;
    fd=mopen(out+"geometry.tsv","wt"); sizes=[1280 720;1280 800;1600 900];
    for dim=1:3
        geometry_size(LD5.fig,sizes(dim,:));
        for step=1:6
            LD5.step=step; LD5.wires=ld5_canonical_wires(); ld5_render_stage();
            label=msprintf("LD5-E%d-%dx%d",step,sizes(dim,1),sizes(dim,2));
            geometry_dump(LD5.fig,label,fd);
            LD5.wires=LD5.wires(:,[2 1]); ld5_render_wires(); geometry_dump(LD5.fig,label+"-reverse",fd);
            if dim==2 & or(step==[1 4 6]) then capture_ld5("E"+string(step)); end
        end
    end
    mclose(fd);
    LD5.step=2; ld5_render_stage(); ld5_toggle_power(); ld5_toggle_switch();
    for pos=[2 1 3]
        bench_ld5_action("ld5_set_position("+string(pos)+")");
        rv=ld5_rv_at(pos); u=LD5.cfg.E*rv/(LD5.cfg.R1+rv); i=LD5.cfg.E/(LD5.cfg.R1+rv)*1000;
        h=findobj("tag","reading:V"); assert_checkequal(h.string,msprintf("%g V",u));
        h=findobj("tag","reading:A"); assert_checkequal(h.string,msprintf("%.3f mA",i));
        bench_ld5_action("ld5_measure()");
        assert_checkalmostequal(LD5.lastMeasurement,i,1e-9,1e-9);
        assert_checkalmostequal(ld5_journal_rows(pos),[u i],1e-9,1e-9);
    end
    assert_checkequal(size(LD5.journal,1),3);
    ld5_measure(); assert_checkequal(size(LD5.journal,1),3);
    assert_checktrue(strindex(strcat(LD5.ui.journalList.string),"P1 (25 %)")<>[]);
    geometry_size(LD5.fig,[1280 800]); capture_ld5("rodmenys");
    journal=LD5.journal; wires=LD5.wires; position=LD5.position;
    // A real saved draft must restore raw text and journal with power off.
    LD5.ui.answerEdits(1).string="6,3521";
    path=bench_save_snapshot("LD5"); snapshot=bench_read_snapshot(path,"LD5");
    ld5_restart(); bench_restore_snapshot(snapshot);
    assert_checkequal(LD5.answers(2,1),"6,3521");
    assert_checkequal(LD5.ui.answerEdits(1).string,"6,3521");
    assert_checkequal(LD5.journal,journal); assert_checkequal(LD5.position,position);
    assert_checktrue(LD5.assessment); assert_checkfalse(LD5.powerOn); assert_checkfalse(LD5.switchOn);
    // Formal assessment accepts a wrong numeric value without revealing the key.
    LD5.done(2)=%f; LD5.step=2; ld5_render_stage();
    LD5.ui.answerEdits(1).string="0";
    bench_ld5_primary(); assert_checkequal(LD5.step,3); assert_checktrue(LD5.done(2));
    assert_checkequal(LD5.answers(2,1),"0");
    assert_checktrue(strindex(LD5.ui.statusMain.string,"Tikimasi")==[]);
    assert_checktrue(strindex(LD5.ui.statusFix.string,"Tikimasi")==[]);
    // Nonnumeric text is a format/completeness error even in formal assessment.
    ld5_jump_step(2); LD5.done(2)=%f; ld5_render_stage();
    LD5.ui.answerEdits(1).string="1+2"; execstr(LD5.ui.answerEdits(1).callback);
    bench_ld5_primary(); assert_checkequal(LD5.step,2); assert_checkfalse(LD5.done(2));
    assert_checktrue(strindex(LD5.ui.statusMain.string,"skaičius")<>[]);
    assert_checktrue(strindex(LD5.ui.statusMain.string,"Tikimasi")==[]);
    // Learning mode still performs local correctness validation.
    LD5.assessment=%f; LD5.practice_used=%t; LD5.done(2)=%f; ld5_render_stage();
    exp=ld5_expected_answers();
    LD5.ui.answerEdits(1).string=msprintf("%.12g",exp(2,1)*0.5); execstr(LD5.ui.answerEdits(1).callback);
    bench_ld5_primary();
    assert_checkequal(LD5.step,2); assert_checkfalse(LD5.done(2));
    assert_checktrue(strindex(LD5.ui.statusMain.string,"netiksli")<>[]);
    assert_checktrue(strindex(LD5.ui.statusFix.string,"Tikimasi")<>[]);
    LD5.ui.answerEdits(1).string=strsubst(msprintf("%.12g",exp(2,1)),".",",");
    execstr(LD5.ui.answerEdits(1).callback);
    bench_ld5_primary(); assert_checkequal(LD5.step,3); assert_checktrue(LD5.done(2));
    LD5.assessment=%t; LD5.practice_used=%f;
    ld5_set_step(6); ld5_next_step(); assert_checkequal(LD5.step,6);
    ld5_terminal_click("E_P"); assert_checkequal(LD5.pending,"");
    ld5_set_step(1); LD5.done(:)=%t; LD5.report_wires(1)=LD5.wires;
    ld5_restore_stage(); assert_checkfalse(or(LD5.done));
    assert_checkequal(size(LD5.journal,1),0); assert_checkequal(size(LD5.wires,1),0);
    r=bench_report_data("LD5"); assert_checkequal(length(r.evidence.wiring.s1.pairs),0);
    ld5_show_wiring_guide(); h=gcf(); assert_checktrue(h<>LD5.fig); delete(h);
    ld5_show_stand_map(); h=gcf(); assert_checktrue(h<>LD5.fig); delete(h);
    ld5_close(); assert_checkfalse(is_handle_valid(LD5.fig));
    // The GUI and teacher must agree just inside/outside BOTH tolerance edges.
    cases=list(); specs=[2 1 .01;4 1 .01;4 2 .01;4 3 .02;4 4 .02;5 1 .02;5 2 .02];
    for n=[1 17 64]
        bench_ld5_workflow(n,root,%f); expected=ld5_expected_answers(); original=LD5.answers;
        if n==1 then
            LD5.autosave_enabled=%t; bench_autosave("LD5"); bench_autosave("LD5"); bench_autosave("LD5");
            assert_checkequal(size(LD5.autosave_paths,"*"),2); assert_checkequal(LD5.autosave_error,"");
            paths=LD5.autosave_paths;
            LD5.assessment=%f;LD5.practice_used=%t;ld5_toggle_solution();assert_checktrue(LD5.demoMode);
            bench_autosave("LD5");assert_checkequal(LD5.autosave_paths,paths);
            ld5_toggle_solution();LD5.assessment=%t;LD5.practice_used=%f;
        end
        for k=1:size(specs,1)
            st=specs(k,1); q=specs(k,2); e=expected(st,q); tolerance=1e-9+specs(k,3)*abs(e);
            for delta=[-1.0001 -0.9999 0.9999 1.0001]
                LD5.answers=original; LD5.step=st; LD5.done(st)=%f;
                LD5.answers(st,q)=msprintf("%.17g",e+delta*tolerance);
                ld5_check_step(); accepted=LD5.done(st); assert_checkequal(accepted,abs(delta)<1);
                cases($+1)=struct("report",bench_report_data("LD5"),"accepted",accepted);
            end
        end
        for q=1:2
            // Išvadų laukeliai yra pasirinkimai: tik literalus 1 arba 2.
            // Teisingas atsakymas šiame LD yra 1; formulės ir dešimtainės formos čia netinka.
            for raw=["1" "2" "" "1+0"]
                LD5.answers=original; LD5.step=6; LD5.done(6)=%f; LD5.answers(6,q)=raw;
                ld5_check_step(); accepted=LD5.done(6); assert_checkequal(accepted,raw=="1");
                cases($+1)=struct("report",bench_report_data("LD5"),"accepted",accepted);
            end
        end
    end
    mputl(toJSON(cases),out+"tolerance-cases.json");
    mputl("LD5_PASS: registration; assessment/learning split; autosave/restore/close; safe wiring; GUI variants 1/17/64; actual export; live C++ readings; comma/raw input; evidence; demo isolation; reset; 36 geometry cases; grading comparisons",out+"verdict.log"); exit(0);
catch
    mputl("LD5_FAIL: "+strcat(lasterror()," | "),out+"verdict.log"); disp(lasterror()); exit(1);
end
