// Windows desktop smoke test: the controller clicks the native instrument.
mode(-1); funcprot(0);
global LD1;
root=getenv("LD1_MOUSE_SOURCE")+"/studentui/";
out=getenv("LD1_MOUSE_OUT")+"/";
try
    exec(root+"LD1/LD1_LOAD.sce",-1);
    cfg=ld1_variant_config(17);
    LD1=struct("base",root+"LD1/","cfg",cfg,"student",student_profile(17,"Pelės patikra","TEST","LD1"),"assessment",%t,"guided",%f);
    ld1_start();
    W=ld1_series_canonical_wires();
    for k=1:size(W,1); ld1_terminal_click(W(k,1)); ld1_terminal_click(W(k,2)); end
    LD1.ui.typeSeries.value=1; ld1_student_primary();
    assert_checkequal(LD1.step,2); assert_checktrue(isnan(LD1.stepMeas(2)));
    original_ld1_measure=ld1_measure;
    function ld1_measure()
        global LD1;
        original_ld1_measure();
        mputl(toJSON(struct("step",LD1.step,"power",LD1.powerOn,"measurement",LD1.stepMeas(2),"expected",1000*LD1.cfg.E/(LD1.cfg.R1+1000))),getenv("LD1_MOUSE_OUT")+"/reading.json");
    endfunction
    exec(getenv("LD1_MOUSE_SOURCE")+"/tools/ergonomics.sci",-1);
    fd=mopen(out+"geometry.tsv","wt"); geometry_dump(LD1.fig,"mouse",fd); mclose(fd);
    LD1.fig.figure_name="LD1 · Pelės patikra";
    show_window(LD1.fig); mputl("READY",out+"ready");
catch
    mputl(strcat(lasterror()," | "),out+"failure"); exit(1);
end
