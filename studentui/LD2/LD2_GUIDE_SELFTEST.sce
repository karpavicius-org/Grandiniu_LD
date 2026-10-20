// CPU-only LD2 guide acceptance cases (requires a local Scilab installation).
// Does NOT launch the graphical window, use GitHub CI or change student files.
mode(-1);
exec(get_absolute_file_path("LD2_GUIDE_SELFTEST.sce")+"LD2_LOAD.sce",-1);
global LD2;

function ld2_guide_assert(ok,description)
    if ~ok then error("LD2_GUIDE_FAIL: "+description); end
    mprintf("PASS: %s\n",description);
endfunction

cfg=ld2_default_config();
LD2=struct("cfg",cfg,"state",ld2_initial_state(cfg), ...
    "ui",struct("headless",%t),"example_active",%f);
LD2.state.assessment=%t;
LD2.state.step=2;
[txt,focus,button,answer]=ld2_guide_next();
ld2_guide_assert(size(focus,"*")==2 & and(focus==["GEN_H";"AM_H"]),"RC first wire highlights two real terminals");
LD2.state.selected_terminal="GEN_H";
[txt,focus,button,answer]=ld2_guide_next();
ld2_guide_assert(size(focus,"*")==1 & focus=="AM_H","RC one clicked terminal points to the second one");
LD2.state.selected_terminal="";
req=ld2_required_main("RC");
LD2.state.rc_connections=req(1,:);
[txt,focus,button,answer]=ld2_guide_next();
ld2_guide_assert(size(focus,"*")==2 & and(focus==["AM_L";"R8_1"]),"Guide skips completed first wire");
LD2.state.rc_connections=req;
[txt,focus,button,answer]=ld2_guide_next();
ld2_guide_assert(button=="ld2_student_primary()","Four wires advance to next stage");

LD2.state.step=4;
LD2.state.power=%f;
[txt,focus,button,answer]=ld2_guide_next();
ld2_guide_assert(button=="ld2_power_toggle()","Power has to be enabled before measurement");
LD2.state.power=%t;
[txt,focus,button,answer]=ld2_guide_next();
ld2_guide_assert(button=="ld2_measure_current()","Current measurement comes before voltage");
LD2.state.rc_I=0.004;
[txt,focus,button,answer]=ld2_guide_next();
ld2_guide_assert(size(focus,"*")==2 & and(focus==["VM_H";"R8_M1"]),"Guide chooses first voltage probe pair");
LD2.state.rc_connections=[req;"VM_H" "R8_M1"];
[txt,focus,button,answer]=ld2_guide_next();
ld2_guide_assert(size(focus,"*")==2 & and(focus==["VM_L";"R8_M2"]),"Guide preserves partially fitted probe pair");
LD2.state.rc_connections=[req;"VM_H" "R8_M1";"VM_L" "R8_M2"];
[txt,focus,button,answer]=ld2_guide_next();
ld2_guide_assert(button=="ld2_measure_voltage()","Correct probe pair -> actual measure button");
LD2.state.rc_UR=2.0;
[txt,focus,button,answer]=ld2_guide_next();
ld2_guide_assert(button=="ld2_remove_voltage_probes()","Completed R measurement -> remove probes before C");
LD2.state.rc_connections=req;
LD2.state.rc_UC=4.0;
LD2.state.rc_UE=9.0;
[txt,focus,button,answer]=ld2_guide_next();
ld2_guide_assert(answer==1,"Measured RC values -> first own calculated answer");
LD2.state.answers_text(4,1)="4.47";
[txt,focus,button,answer]=ld2_guide_next();
ld2_guide_assert(answer==2,"Second answer field highlighted after first entry");
LD2.state.answers_text(4,2)="6.06";
[txt,focus,button,answer]=ld2_guide_next();
ld2_guide_assert(button=="ld2_student_primary()","Complete measurement answers -> Next");

LD2.state.step=5;LD2.state.power=%f;
[txt,focus,button,answer]=ld2_guide_next();
ld2_guide_assert(size(focus,"*")==2 & and(focus==["GEN_H";"AM_H"]),"RL starts with own live wiring guide");
LD2.state.step=8;
[txt,focus,button,answer]=ld2_guide_next();
ld2_guide_assert(size(focus,"*")==2 & and(focus==["GEN_H";"AM_H"]),"RLC starts with own live wiring guide");

LD2.state.rlc_connections=ld2_required_main("RLC");
LD2.state.step=9;LD2.state.power=%t;
LD2.state.res_f=[700 900 1100];LD2.state.res_ur=[4.6 4.96 4.6];
[txt,focus,button,answer]=ld2_guide_next();
ld2_guide_assert(answer==1,"Bracketing resonance completed: next guidance is the student's own answer");
LD2.state.step=10;
[txt,focus,button,answer]=ld2_guide_next();
ld2_guide_assert(size(focus,"*")>0,"Peak-search shows required L3/C4/LC contacts");
LD2.state.step=11;
LD2.state.rlc_connections=[ld2_required_main("RLC");"VM_H" "R13_M1";"VM_L" "R13_M2"];
LD2.state.last_voltage=ld2_empty_reading();
[txt,focus,button,answer]=ld2_guide_next();
ld2_guide_assert(button=="ld2_measure_voltage()","Half-power requires fresh voltage reading");
LD2.state.step=12;
[txt,focus,button,answer]=ld2_guide_next();
ld2_guide_assert(button=="ld2_run_sweep()","Final step: actual 0-10kHz measurement sweep");
ld2_guide_assert(LD2.state.practice_used==%f & LD2.state.assessment==%t, ...
    "Read-only guidance never changes assessment to practice");
mprintf("LD2_GUIDE_SELFTEST: PASS\n");
exit(0);
