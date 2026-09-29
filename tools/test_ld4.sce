// Targeted LD4 acceptance: real callbacks and C++ geometry, Windows and Linux.
mode(-1); funcprot(0);
root=getenv("LD4_TEST_RUNTIME")+"/"; out=getenv("LD4_TEST_OUT")+"/";
source=getenv("LD4_TEST_SOURCE")+"/";
global LD4 LD4_CANCEL;
function v=x_mdialog(varargin)
    global LD4_CANCEL;
    if LD4_CANCEL then v=[]; else v=["17";"Patikra Žąsė";"TEST"]; end
endfunction
function n=messagebox(varargin)
    if varargin(2)<>"Jūsų priskirtos reikšmės" then error("Netikėtas dialogas"); end
    n=1;
endfunction
function capture_ld4(name)
    global LD4;
    if getos()<>"Linux" then return; end
    LD4.fig.figure_name="LD4 PATIKRA "+name; show_window(LD4.fig); sleep(250);
    cmd="/usr/bin/python3 """+getenv("LD4_TEST_RUNTIME")+"/capture_window.py"" ""LD4 PATIKRA "+name+""" """+getenv("LD4_TEST_OUT")+"/"+name+".png""";
    assert_checkequal(host(cmd),0);
endfunction
try
    LD4=struct(); LD4_CANCEL=%t; exec(root+"LD4/LD4.sce",-1);
    assert_checkfalse(isfield(LD4,"fig"));
    LD4_CANCEL=%f; exec(root+"LD4/LD4.sce",-1);
    assert_checkequal(LD4.student.number,17);
    assert_checktrue(LD4.assessment); assert_checkfalse(LD4.practice_used);
    assert_checkequal(LD4.fig.closerequestfcn,"ld4_close()");
    delete(LD4.fig);
    exec(root+"tests/workflows.sci",-1);exec(source+"tools/ergonomics.sci",-1);
    // All actions include real terminal removal/reconnection and export callback.
    for n=[1 17 64]; bench_ld4_workflow(n,root,%t); end
    LD4=struct("cfg",ld4_variant_config(1),"student",student_profile(1,"Patikra Žąsė","TEST","LD4"),"ui",struct("headless",%f));
    ld4_start();
    r=bench_report_data("LD4");assert_checkequal(length(r.evidence.wiring.s1.pairs),0);assert_checkequal(length(r.evidence.wiring.s6.pairs),0);
    assert_checkequal(r.mode,"assessment"); assert_checkfalse(r.practice_used);
    // Formal mode blocks the worked example.
    ld4_toggle_solution(); assert_checkfalse(LD4.demoMode); assert_checkfalse(LD4.practice_used);
    // Learning mode permits it, and a demo cannot be exported.
    LD4.assessment=%f;LD4.practice_used=%t;ld4_render_stage();ld4_toggle_solution();assert_checktrue(LD4.demoMode);
    rejected=%f;try r=bench_report_data("LD4");catch rejected=%t;end
    assert_checktrue(rejected);ld4_toggle_solution();assert_checkequal(size(LD4.journal,1),0);
    LD4.assessment=%t;LD4.practice_used=%f;ld4_render_stage();
    fd=mopen(out+"geometry.tsv","wt");
    sizes=[1280 720;1280 800;1600 900];
    for dim=1:3
        geometry_size(LD4.fig,sizes(dim,:));
        for step=1:7
            LD4.step=step;
            if step<3 then LD4.wireMode=1;
            elseif step<6 then LD4.wireMode=2;
            else LD4.wireMode="S";end
            LD4.wires=ld4_canonical_wires(ld4_wire_mode());
            ld4_render_stage();
            label=msprintf("LD4-E%d-%dx%d",step,sizes(dim,1),sizes(dim,2));
            geometry_dump(LD4.fig,label,fd);
            LD4.wires=LD4.wires(:,[2 1]);ld4_render_wires();
            geometry_dump(LD4.fig,label+"-reverse",fd);
            if dim==2 & or(step==[1 3 6]) then capture_ld4("E"+string(step)); end
        end
    end
    mclose(fd);
    LD4.step=2;LD4.wires=ld4_canonical_wires(1);ld4_render_stage();
    ld4_toggle_power();ld4_toggle_switch();ld4_set_voltage(LD4.cfg.U1);ld4_measure();
    assert_checkalmostequal(LD4.lastMeasurement,31.25,1e-9,1e-9);
    h=findobj("tag","reading:A");assert_checkequal(h.string,"31.250 mA");
    h=findobj("tag","reading:E");assert_checkequal(h.string,"3 V");
    h=findobj("tag","reading:V");assert_checkequal(h.string,"3 V");
    capture_ld4("rodmenys");
    for vv=[LD4.cfg.U2 LD4.cfg.U3];ld4_set_voltage(vv);ld4_measure();end
    assert_checkequal(size(ld4_journal_rows(1),1),3);
    // Formal assessment keeps a wrong raw answer and advances without revealing the key.
    LD4.ui.answerEdits(1).string="0";
    ld4_student_primary();assert_checkequal(LD4.step,3);assert_checktrue(LD4.done(2));
    assert_checkequal(LD4.answers(2,1),"0");assert_checktrue(strindex(LD4.ui.statusMain.string,"Tikimasi")==[]);
    assert_checkfalse(LD4.powerOn);assert_checkfalse(LD4.switchOn);
    ld4_set_resistor(2);assert_checkfalse(LD4.powerOn);assert_checkfalse(LD4.switchOn);
    ld4_set_step(4);
    assert_checkequal(LD4.ui.instructionLine(1).string,student_wrap(ld4_step_instruction(4),38));
    assert_checktrue(ld4_close_enough(30.3,30,0.01,1e-9));
    assert_checkfalse(ld4_close_enough(30.45,30,0.01,1e-9));
    assert_checktrue(ld4_close_enough(0,1e-14,0.05,0.005));
    ld4_close();assert_checkfalse(is_handle_valid(LD4.fig));
    mputl("LD4_PASS: registration, assessment/learning split, autosave/close, safe rewiring, GUI variants 1/17/64, removal, reconnect, actual export, evidence, C++ readings, raw edits, 42 geometry cases",out+"verdict.log");exit(0);
catch
    mputl("LD4_FAIL: "+strcat(lasterror()," | "),out+"verdict.log");disp(lasterror());exit(1);
end
