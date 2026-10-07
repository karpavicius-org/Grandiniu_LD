mode(-1); funcprot(0);
root=getenv("LD1_TEST_RUNTIME")+"/"; out=getenv("LD1_TEST_OUT")+"/";
global LD1 LD1_TEST_NUMBER LD1_TEST_LEARNING;
LD1_TEST_LEARNING=1;
function values=x_mdialog(varargin)
    global LD1_TEST_NUMBER; values=[string(LD1_TEST_NUMBER);"Studento UI Patikra";"TEST"];
endfunction
function selected=messagebox(varargin)
    global LD1_TEST_LEARNING;
    if varargin(2)=="Pereiti į mokymąsi?" then selected=LD1_TEST_LEARNING; return; end
    if varargin(2)=="LD1" & varargin(1)=="Ar tikrai pradėti laboratorinį darbą iš naujo?" then selected=1; return; end
    if varargin(2)<>"Jūsų priskirtos reikšmės" then error("Netikėtas dialogas: "+strcat(string(varargin(1))," | ")); end
    selected=1;
endfunction
function ui_visible(h)
    while h.type=="uicontrol"
        assert_checkequal(h.visible,"on"); h=h.parent;
    end
endfunction
function ui_button(h)
    ui_visible(h); assert_checkequal(h.enable,"on");
    fd=mopen(getenv("LD1_TEST_OUT")+"/actions.log","at"); mfprintf(fd,"%s\n",h.callback); mclose(fd);
    execstr(h.callback);
endfunction
function ui_wire(W)
    global LD1;
    for k=1:size(W,1)
        for id=W(k,:)
            index=find(LD1.term.handleIds==id);
            ui_button(LD1.term.handles(index(1)));
        end
    end
endfunction
function ui_primary()
    global LD1;
    assert_checkequal(LD1.ui.ctrlFrame.visible,"on");
    assert_checkequal(LD1.ui.checkStep.visible,"on"); assert_checkequal(LD1.ui.checkStep.enable,"on");
    execstr(LD1.ui.checkStep.callback);
endfunction
function ui_contacts()
    global LD1;
    for id=matrix(LD1.term.active,1,-1)
        index=find(LD1.term.handleIds==id); assert_checkequal(size(index,"*"),1);
        h=LD1.term.handles(index(1)); ui_visible(h);
        assert_checkequal(h.tag,ld1_terminal_code(id));
        assert_checkequal(h.string,"<html><center>"+ld1_terminal_button_text(id)+"<br>"+ld1_terminal_code(id)+"</center></html>");
        assert_checkequal(h.horizontalalignment,"center");
        assert_checkequal(h.relief,"flat");
        bounds=h.position(3:4).*student_size(h.parent); assert_checkalmostequal(bounds,[36 40],1e-9,1e-9);
        expected="off"; if ld1_terminal_should_show(id) & ~ld1_guided() then expected="on"; end
        assert_checkequal(h.enable,expected);
    end
endfunction
function ui_answers(values)
    global LD1;
    for k=1:size(values,"*")
        assert_checkequal(LD1.ui.qEdit(k).visible,"on");
        LD1.ui.qEdit(k).string=strsubst(msprintf("%.12g",values(k)),".",",");
    end
endfunction
function ui_auto_numbers(values)
    global LD1;
    for k=1:size(values,"*")
        assert_checkequal(LD1.ui.qEdit(k).visible,"off");
        assert_checkequal(LD1.ui.qEdit(k).string,"");
    end
endfunction
function capture_ld1(name)
    global LD1;
    if getos()=="Darwin" then return; end
    if getos()=="Windows" & getenv("LD1_CAPTURE_WINDOWS","0")=="0" then return; end
    LD1.fig.figure_name="LD1 UI "+name; show_window(LD1.fig); sleep(250);
    python="/usr/bin/python3"; if getos()=="Windows" then python="python"; end
    command=python+" """+getenv("LD1_TEST_RUNTIME")+"/capture_window.py"" ""LD1 UI "+name+""" """+getenv("LD1_TEST_OUT")+"/"+name+".png""";
    assert_checkequal(host(command),0);
endfunction
try
    exec(getenv("LD1_TEST_SOURCE")+"/tools/ergonomics.sci",-1);
    fd=mopen(out+"geometry.tsv","wt"); sizes=[1280 640];
    for number=[1 17 64]
        LD1=struct(); LD1_TEST_NUMBER=number; exec(root+"LD1/LD1.sce",-1);
        assert_checkfalse(LD1.guided); assert_checktrue(LD1.assessment);
        screen=get(0,"screensize_px"); assert_checkequal(LD1.fig.axes_size,min([1280 640],max([320 240],screen(3:4)-[40 120]))); assert_checkequal(LD1.fig.resize,"off");
        LD1.autosave_enabled=%f; cfg=LD1.cfg;
        assert_checkequal(LD1.ui.typeSeries.value+LD1.ui.typeParallel.value+LD1.ui.typeMixed.value,0);
        primary_position=LD1.ui.checkStep.position; back_position=LD1.ui.prev.position;
        assert_checkequal(size(LD1.wires,1),0);
        LD1.ui.typeSeries.value=1; ui_primary(); assert_checkequal(LD1.step,1);
        LD1.ui.typeSeries.value=0;
        ui_button(LD1.ui.example); assert_checkfalse(LD1.demoMode); assert_checktrue(LD1.assessment);
        for h=[LD1.ui.explanation LD1.ui.theory];
            ids=winsid(); ui_button(h); added=setdiff(winsid(),ids);
            assert_checkequal(size(added,"*"),1); delete(scf(added(1))); show_window(LD1.fig);
        end
        ui_primary(); assert_checkequal(LD1.step,1); // Missing choice stays visible.
        ui_button(LD1.ui.wiringGuide); assert_checktrue(LD1.wiring_help);
        assert_checkequal(ld1_measurement_hint_pair(),["SRC_P" "R1_1"]);
        assert_checkequal(size(LD1.wires,1),0); // Guidance highlights; the student still connects.
        for step=1:8
            assert_checkequal(LD1.step,step);
            if or(step==[3 6 8]) then assert_checkequal(LD1.ui.yes.value+LD1.ui.no.value,0); end
            if or(step==[4 7]) then assert_checkequal(LD1.ui.typeSeries.value+LD1.ui.typeParallel.value+LD1.ui.typeMixed.value,0); end
            if step==5 then assert_checkequal(LD1.ui.typeSeries.value+LD1.ui.typeParallel.value+LD1.ui.typeMixed.value,0); end
            if step==1 then ui_wire(ld1_series_canonical_wires()); LD1.ui.typeSeries.value=1;
            elseif step==2 then
                wires=LD1.wires; ld1_terminal_click("SRC_P"); assert_checkequal(LD1.wires,wires);
                assert_checkequal(LD1.ui.power.visible,"off"); ui_visible(LD1.ui.measure);
                assert_checkequal(LD1.ui.measure.enable,"on");
                ui_primary(); assert_checkequal(LD1.step,2); // Measurements are required; no numerical input.
                ui_button(LD1.ui.measure);
                assert_checkalmostequal(LD1.stepMeas(2),cfg.E/(cfg.R1+1000)*1000,1e-9,1e-9);
                assert_checkalmostequal(LD1.seriesProbes(2,:),[1 1]*LD1.stepMeas(2),1e-9,1e-9);
                ui_auto_numbers([cfg.R1+1000 cfg.E/(cfg.R1+1000)*1000]);
                if number==1 then LD1.autosave_enabled=%t; end
            elseif step==3 then
                assert_checkequal(LD1.stepMeas(3),LD1.stepMeas(2));
                assert_checkequal(LD1.seriesProbes(3,:),LD1.seriesProbes(2,:));
                if number==1 then
                    assert_checkequal(LD1.autosave_error,"");
                    disk=bench_read_snapshot(LD1.autosave_paths($),"LD1");
                    assert_checkequal(disk.state.stepMeas(3),LD1.stepMeas(3));
                    LD1.autosave_enabled=%f;
                end
                assert_checkalmostequal(LD1.stepMeas(3),cfg.E/(cfg.R1+1000)*1000,1e-9,1e-9);
                LD1.ui.yes.value=1;
            elseif step==4 then
                assert_checkequal(LD1.VR1,1000); ui_button(LD1.ui.vr500);
                assert_checkequal(LD1.VR1,500);
                ui_auto_numbers([cfg.R1+500 cfg.E/(cfg.R1+500)*1000]);
                assert_checkalmostequal(LD1.stepMeas(4),cfg.E/(cfg.R1+500)*1000,1e-9,1e-9); LD1.ui.typeSeries.value=1;
            elseif step==5 then
                assert_checkequal(LD1.meterMode,"V");
                ui_wire(ld1_parallel_voltage_canonical_wires()); LD1.ui.typeParallel.value=1;
            elseif step==6 then
                ui_button(LD1.ui.measure);
                ui_auto_numbers(cfg.R3*(cfg.R2+1000)/(cfg.R3+cfg.R2+1000)); LD1.ui.yes.value=1;
            elseif step==7 then
                ui_primary(); assert_checkequal(LD1.step,7);
                ui_button(LD1.ui.vr500);
                assert_checkalmostequal(LD1.stepMeas(7),cfg.E,1e-9,1e-9);
                assert_checkequal(LD1.VR1,500); LD1.ui.typeMixed.value=1;
            elseif step==8 then
                assert_checkequal(size(LD1.wires,1),6);
                ui_wire(["SRC_P" "M_P";"M_N" LD1.kclTargetA]);
                assert_checkequal(LD1.meterMode,"A"); assert_checkequal(LD1.VR1,0);
                ui_button(LD1.ui.measure);
                assert_checkequal(size(LD1.wires,1),8);
                i1=cfg.E/cfg.R3*1000; i2=cfg.E/cfg.R2*1000; ui_auto_numbers([i1 i2 i1+i2]);
                assert_checkalmostequal(LD1.branchProbes(8,:),[i1 i2],1e-7,1e-8);
                LD1.ui.yes.value=1; LD1.ui.no.value=0;
            end
            ui_contacts();
            if number==1 then
                for dimension=1:size(sizes,1)
                    execstr(LD1.fig.resizefcn);
                    geometry_dump(LD1.fig,msprintf("LD1-E%d-%dx%d",step,sizes(dimension,1),sizes(dimension,2)),fd);
                    if dimension==1 & or(step==[1 2 3 8]) then
                        beforeW=LD1.wires; capture_ld1("E"+string(step));
                        if ~isequal(beforeW,LD1.wires) then error("Capture changed wires: "+LD1.ui.statusMain.string); end
                    end
                end
            end
            ui_primary();
            if LD1.step<>step+1 then error("V"+string(number)+" E"+string(step)+": "+LD1.ui.statusMain.string+" | "+LD1.ui.statusFix.string); end
            assert_checktrue(LD1.recorded(step));
            screen=get(0,"screensize_px"); assert_checkequal(LD1.fig.axes_size,min([1280 640],max([320 240],screen(3:4)-[40 120])));
            assert_checkequal(LD1.ui.checkStep.position,primary_position);
            assert_checkequal(LD1.ui.prev.position,back_position);
            mprintf("UI LD1 V%02d E%d PASS\n",number,step);
        end
        assert_checkfalse(or(isnan(LD1.stepMeas([3 4 6 7 8]))));
        assert_checkequal(LD1.res.Mseries1000,LD1.stepMeas(3)); assert_checkequal(LD1.res.MIt,LD1.stepMeas(8));
        assert_checkequal(size(strindex(strcat(LD1.ui.resultsTable.string," "),"NEATLIKTA"),"*"),0);
        before=LD1.stepMeas; raw=LD1.stepQ;
        if number==1 then
            for dimension=1:size(sizes,1)

                geometry_dump(LD1.fig,msprintf("LD1-E9-%dx%d",sizes(dimension,1),sizes(dimension,2)),fd);
                capture_ld1("ataskaita");
            end
        end
        ui_primary(); assert_checktrue(size(strindex(LD1.ui.statusMain.string,"Ataskaita išsaugota"),"*")>0);
        report=bench_report_data("LD1"); assert_checkfalse(report.evidence.automatic_setup);
        assert_checkfalse(report.evidence.automatic_calculation); assert_checktrue(report.evidence.automatic_measurement);
        assert_checkequal(report.rubric_version,"LD1-3"); assert_checkequal(length(report.answers),7);
        assert_checkfalse(report.practice_used);
        summary_snapshot=bench_snapshot("LD1"); bench_restore_snapshot(summary_snapshot);
        assert_checkequal(LD1.step,9); assert_checkequal(length(LD1.ui.resultCards),5);
        for h=LD1.ui.resultCards; assert_checktrue(is_handle_valid(h)); assert_checkequal(h.visible,"on"); end
        ld1_set_step(4); LD1.ui.typeSeries.value=0; LD1.ui.typeParallel.value=1; ui_primary(); assert_checkequal(LD1.step,5);
        assert_checkequal(LD1.stepType(4),2); // Incorrect conclusions remain the student's.
        report=bench_report_data("LD1"); mputl(toJSON(report),out+msprintf("wrong-V%02d.json",number));
        ui_primary(); assert_checkequal(LD1.step,6);
        assert_checkequal(LD1.stepMeas,before);
        snapshot=bench_snapshot("LD1"); ld1_restart(); bench_restore_snapshot(snapshot);
        assert_checkequal(LD1.stepType(4),2); assert_checkequal(LD1.stepMeas,before);
        LD1_TEST_LEARNING=2;
        raw=LD1.stepQ; ui_button(LD1.ui.example); assert_checktrue(LD1.demoMode);
        ui_primary(); assert_checkfalse(LD1.demoMode);
        assert_checkequal(LD1.stepQ,raw); assert_checkequal(LD1.stepMeas,before);
        assert_checkfalse(LD1.assessment); assert_checktrue(LD1.practice_used);
        ld1_toggle_guided(); assert_checktrue(LD1.guided); assert_checkequal(LD1.stepMeas,before);
        LD1.ui.yes.value=0; LD1.ui.no.value=1; ui_primary(); assert_checkequal(LD1.step,6); assert_checkfalse(LD1.done(6));
        LD1.ui.yes.value=1; LD1.ui.no.value=0; ui_primary(); assert_checktrue(LD1.done(6));
        ld1_toggle_guided(); assert_checkfalse(LD1.guided); ui_visible(LD1.ui.measure);
        ld1_set_step(9); raw=LD1.stepQ; before=LD1.stepMeas;
        ui_button(LD1.ui.example); assert_checktrue(LD1.demoMode); ui_primary();
        assert_checkfalse(LD1.demoMode); assert_checkequal(LD1.stepQ,raw); assert_checkequal(LD1.stepMeas,before);
        ld1_restart(); assert_checktrue(LD1.assessment); assert_checkfalse(LD1.practice_used);
        assert_checkfalse(LD1.guided); assert_checkfalse(LD1.guided_used); assert_checkequal(size(LD1.wires,1),0);
        LD1_TEST_LEARNING=1;
        delete(LD1.fig);
        ld1_student_answer_changed(); ld1_student_primary(); ld1_student_help();
    end
    mclose(fd);
    // Original manual workflow must still work, through its actual controls.
    exec(root+"tests/workflows.sci",-1); bench_ld1_workflow(17,root);
    mputl("PASS: 3 LD1 measurement entries; 9 stages; real solver probes; manual wiring; no numeric input; conclusions preserved; report; draft restore; learning isolation; 1280x640 geometry; legacy workflow",out+"verdict.log"); exit(0);
catch
    [detail,code,line,fun]=lasterror();
    mputl(["FAIL: "+strcat(detail," | ");"line "+string(line)+" in "+fun],out+"verdict.log"); disp(detail); exit(1);
end
