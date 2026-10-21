mode(-1);funcprot(0);
try
    exec(get_absolute_file_path("LD2_GUIDE_SELFTEST.sce")+"LD2_LOAD.sce",-1);
    global LD2;
    cfg=ld2_variant_config(17);
    LD2=struct("cfg",cfg,"root",LD2_ROOT,"state",ld2_initial_state(cfg), ...
        "ui",struct("headless",%t,"suppress_render",%f),"example_active",%f);
    LD2.state.step=2;
    [lines,focus,button,field]=ld2_guide_next();
    ld2_test_assert(button=="ld2_auto_stage()","setup action missing");
    ld2_test_assert(size(focus,"*")==2,"two manual contact targets");
    LD2.state.selected_terminal=focus(1);
    [lines,focus,button,field]=ld2_guide_next();
    ld2_test_assert(size(focus,"*")==1,"selected contact not respected");
    ld2_auto_stage();ld2_go_step(4,%f);
    [lines,focus,button,field]=ld2_guide_next();
    ld2_test_assert(button=="ld2_auto_stage()","guide asks for manual power before auto experiment");
    ld2_auto_stage();
    [lines,focus,button,field]=ld2_guide_next();
    ld2_test_assert(field==0,"removed numeric input requested");
    ld2_choose_comparison(1);
    [lines,focus,button,field]=ld2_guide_next();
    ld2_test_assert(button=="ld2_student_primary()","completed comparison cannot continue");
    disp("PASS guide: setup, selected terminal, automatic measurement, comparison and continuation.");exit(0);
catch
    disp(lasterror());exit(1);
end
