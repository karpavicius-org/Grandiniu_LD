// Observe an actual desktop walkthrough. No answers, wires or readings are injected.
mode(-1); funcprot(0);
global LD1 LD1_WALK_SEQUENCE LD1_WALK_DEPTH;
LD1_WALK_SEQUENCE=0; LD1_WALK_DEPTH=0;
root=getenv("LD1_WALK_RUNTIME")+"/"; out=getenv("LD1_WALK_OUT")+"/";
try
    exec(root+"LD1/LD1_LOAD.sce",-1);
    // Only registration is supplied; all laboratory actions come from the desktop mouse.
    function values=x_mdialog(varargin)
        values=["17";"Studento eiga";"TEST"];
    endfunction
    function answer=messagebox(varargin)
        if varargin(2)<>"Jūsų priskirtos reikšmės" then error("Netikėtas dialogas"); end
        answer=1;
    endfunction
    exec(getenv("LD1_WALK_SOURCE")+"/tools/ergonomics.sci",-1);
    function desktop_publish()
        global LD1 LD1_WALK_SEQUENCE;
        LD1.fig.figure_name="LD1 · Studento eiga";
        output=getenv("LD1_WALK_OUT")+"/";
        fd=mopen(output+"geometry.tsv","wt"); geometry_dump(LD1.fig,"desktop",fd); mclose(fd);
        LD1_WALK_SEQUENCE=LD1_WALK_SEQUENCE+1;
        state=struct("sequence",LD1_WALK_SEQUENCE,"step",LD1.step,"power",LD1.powerOn,"VR",LD1.VR1,"mode",LD1.meterMode, ...
            "measurement",LD1.lastMeasurement,"readings",LD1.stepMeas,"numbers",LD1.stepQ(LD1.step,:), ...
            "wire_count",size(LD1.wires,1),"status",LD1.ui.statusMain.string,"target",LD1.kclTargetA, ...
            "choice",[LD1.ui.typeSeries.value LD1.ui.typeParallel.value LD1.ui.typeMixed.value LD1.ui.yes.value LD1.ui.no.value], ...
            "cfg",struct("E",LD1.cfg.E,"R1",LD1.cfg.R1,"R2",LD1.cfg.R2,"R3",LD1.cfg.R3));
        mputl(toJSON(state),output+"state.json");
    endfunction
    function desktop_begin()
        global LD1_WALK_DEPTH; LD1_WALK_DEPTH=LD1_WALK_DEPTH+1;
    endfunction
    function desktop_end()
        global LD1_WALK_DEPTH; LD1_WALK_DEPTH=LD1_WALK_DEPTH-1;
        if LD1_WALK_DEPTH==0 then desktop_publish(); end
    endfunction
    function desktop_failure()
        mputl(strcat(lasterror()," | "),getenv("LD1_WALK_OUT")+"/failure");
    endfunction
    original_terminal_click=ld1_terminal_click;
    function ld1_terminal_click(id)
        desktop_begin(); try original_terminal_click(id); desktop_end(); catch desktop_failure(); end
    endfunction
    original_measure=ld1_measure;
    function ld1_measure()
        desktop_begin(); try original_measure(); desktop_end(); catch desktop_failure(); end
    endfunction
    original_toggle_power=ld1_toggle_power;
    function ld1_toggle_power()
        desktop_begin(); try original_toggle_power(); desktop_end(); catch desktop_failure(); end
    endfunction
    original_set_vr=ld1_set_vr;
    function ld1_set_vr(value)
        desktop_begin(); try original_set_vr(value); desktop_end(); catch desktop_failure(); end
    endfunction
    original_primary=ld1_student_primary;
    function ld1_student_primary()
        desktop_begin(); try original_primary(); desktop_end(); catch desktop_failure(); end
    endfunction
    original_answer_changed=ld1_student_answer_changed;
    function ld1_student_answer_changed()
        desktop_begin(); try original_answer_changed(); desktop_end(); catch desktop_failure(); end
    endfunction
    original_prev=ld1_prev_step;
    function ld1_prev_step()
        desktop_begin(); try original_prev(); desktop_end(); catch desktop_failure(); end
    endfunction
    LD1=struct(); ld1_student_main(root+"LD1/");
    desktop_publish(); show_window(LD1.fig); mputl("READY",out+"ready");
catch
    mputl(strcat(lasterror()," | "),out+"failure"); exit(1);
end
