// Complete native OS input LD2 acceptance: the Python driver can ONLY send
// desktop mouse/key events. Production callbacks perform the real operations;
// test-only observers export state and visible native GUI coordinates.
mode(-1);funcprot(0);
global LD2 LD2_NATIVE_OUT LD2_NATIVE_ROOT LD2_NATIVE_SEQ;
LD2_NATIVE_OUT=getenv("LD2_NATIVE_OUT")+"/";
LD2_NATIVE_ROOT=getenv("LD2_NATIVE_ROOT")+"/";
LD2_NATIVE_SEQ=0;
global LD2_NATIVE_REGISTRY;

function ld2_native_publish(event)
    global LD2 LD2_NATIVE_SEQ LD2_NATIVE_OUT;
    LD2_NATIVE_SEQ=LD2_NATIVE_SEQ+1;
    phase=ld2_phase_for_step(LD2.state.step);
    conn=ld2_get_phase_connections(phase);
    st=struct("seq",LD2_NATIVE_SEQ,"event",event,"step",LD2.state.step,"phase",phase, ...
        "power",LD2.state.power,"selected_terminal",LD2.state.selected_terminal, ...
        "connections",size(conn,1),"completed_count",sum(LD2.state.completed==1), ...
        "completed",LD2.state.completed, ...
        "answers",LD2.state.answers_text(LD2.state.step,:), ...
        "frequency",LD2.state.freq,"amp",LD2.state.amp_live, ...
        "voltage",LD2.state.volt_live,"target",LD2.state.volt_live_target, ...
        "reading_count",length(LD2.state.measurements), ...
        "rc_I",LD2.state.rc_I,"rc_UR",LD2.state.rc_UR,"rc_UC",LD2.state.rc_UC,"rc_UE",LD2.state.rc_UE, ...
        "rl_I",LD2.state.rl_I,"rl_UR",LD2.state.rl_UR,"rl_UL",LD2.state.rl_UL,"rl_UE",LD2.state.rl_UE, ...
        "res_f",LD2.state.res_f,"res_ur",LD2.state.res_ur, ...
        "peak_f",LD2.state.peak_f,"peak_u",LD2.state.peak_u,"peak_target",LD2.state.peak_target, ...
        "f1",LD2.state.f1_meas,"f2",LD2.state.f2_meas, ...
        "sweep_f",LD2.state.sweep_f,"status",LD2.state.status_text, ...
        "assessment",LD2.state.assessment,"practice",LD2.state.practice_used);
    fd=mopen(LD2_NATIVE_OUT+"geometry.tsv","wt");
    geometry_dump(LD2.ui.figure,"LD2-NATIVE",fd);
    mclose(fd);
    mputl(toJSON(st),LD2_NATIVE_OUT+"state.json");
endfunction

try
    root=LD2_NATIVE_ROOT+"studentui/";
    exec(root+"LD2/LD2_LOAD.sce",-1);
    cfg=ld2_variant_config(17);
    [valid,why]=ld2_validate_config(cfg);if ~valid then error(why);end
    LD2=struct("root",root+"LD2/","cfg",cfg,"state",ld2_initial_state(cfg), ...
        "ui",struct("headless",%f,"suppress_render",%f,"dynamic",[],"answer_edits",[],"answer_step",0), ...
        "example_active",%f,"example_backup",struct());
    LD2.state.student=student_profile(17,"OS tikra pele","TEST","LD2");
    LD2.state.assessment=%t;LD2.state.practice_used=%f;
    ld2_build_gui();ld2_go_step(1,%f);
    LD2.autosave_enabled=%t;
    exec(LD2_NATIVE_ROOT+"tools/ergonomics.sci",-1);

    rc=ld2_rc_values(cfg.E_RC,cfg.F_RC,cfg.R8,cfg.C2);
    rl=ld2_rl_values(cfg.E_RL,cfg.F_RL,cfg.R9,cfg.L1);
    rr=ld2_peak_reference(cfg);
    refs=struct("rc",[rc.X rc.Z rc.I*1000 rc.UR rc.UX rc.P*1000 rc.PHI_I], ...
        "rl",[rl.X rl.Z rl.I*1000 rl.UR rl.UX rl.P*1000 rl.PHI_I], ...
        "f0",rr.F0,"f1",rr.F1,"f2",rr.F2,"bw",rr.BW,"q",rr.Q, ...
        "fl",rr.FL,"fc",rr.FC);
    mputl(toJSON(refs),LD2_NATIVE_OUT+"references.json");
    mputl(toJSON(cfg),LD2_NATIVE_OUT+"config.json");
    lines=emptystr(0,1);
    for phase=["RC" "RL" "RLC"]
        req=ld2_required_main(phase);
        for k=1:size(req,1)
            lines($+1)=phase+ascii(9)+ld2_terminal_code(req(k,1))+ascii(9)+ld2_terminal_code(req(k,2));
        end
    end
    mputl(lines,LD2_NATIVE_OUT+"wiring.tsv");
    probes=emptystr(0,1);
    for phase=["RC" "RL" "RLC"]
        if phase=="RC" then names=["UR" "UC" "UE"];
        elseif phase=="RL" then names=["UR" "UL" "UE"];
        else names=["UR" "UL" "UC" "ULC"];end
        for target=names
            pair=ld2_probe_pair(phase,target);
            probes($+1)=phase+ascii(9)+target+ascii(9)+ ...
                ld2_terminal_code("VM_H")+ascii(9)+ld2_terminal_code(pair(1))+ascii(9)+ ...
                ld2_terminal_code("VM_L")+ascii(9)+ld2_terminal_code(pair(2));
        end
    end
    mputl(probes,LD2_NATIVE_OUT+"probes.tsv");
catch
    [err,code,line,fn]=lasterror();
    mputl("LD2 setup failed: "+strcat(err," | ")+" at "+fn+":"+string(line),LD2_NATIVE_OUT+"failure");
    exit(1);
end

global LD2_NATIVE_ORIG_ld2_student_primary;
LD2_NATIVE_ORIG_ld2_student_primary=ld2_student_primary;
global LD2_NATIVE_ORIG_ld2_terminal_click;
LD2_NATIVE_ORIG_ld2_terminal_click=ld2_terminal_click;
global LD2_NATIVE_ORIG_ld2_power_toggle;
LD2_NATIVE_ORIG_ld2_power_toggle=ld2_power_toggle;
global LD2_NATIVE_ORIG_ld2_measure_current;
LD2_NATIVE_ORIG_ld2_measure_current=ld2_measure_current;
global LD2_NATIVE_ORIG_ld2_measure_voltage;
LD2_NATIVE_ORIG_ld2_measure_voltage=ld2_measure_voltage;
global LD2_NATIVE_ORIG_ld2_remove_voltage_probes;
LD2_NATIVE_ORIG_ld2_remove_voltage_probes=ld2_remove_voltage_probes;
global LD2_NATIVE_ORIG_ld2_student_answers_changed;
LD2_NATIVE_ORIG_ld2_student_answers_changed=ld2_student_answers_changed;
global LD2_NATIVE_ORIG_ld2_apply_frequency;
LD2_NATIVE_ORIG_ld2_apply_frequency=ld2_apply_frequency;
global LD2_NATIVE_ORIG_ld2_record_resonance_point;
LD2_NATIVE_ORIG_ld2_record_resonance_point=ld2_record_resonance_point;
global LD2_NATIVE_ORIG_ld2_record_peak_point;
LD2_NATIVE_ORIG_ld2_record_peak_point=ld2_record_peak_point;
global LD2_NATIVE_ORIG_ld2_record_f1;
LD2_NATIVE_ORIG_ld2_record_f1=ld2_record_f1;
global LD2_NATIVE_ORIG_ld2_record_f2;
LD2_NATIVE_ORIG_ld2_record_f2=ld2_record_f2;
global LD2_NATIVE_ORIG_ld2_run_sweep;
LD2_NATIVE_ORIG_ld2_run_sweep=ld2_run_sweep;
global LD2_NATIVE_ORIG_ld2_prev;
LD2_NATIVE_ORIG_ld2_prev=ld2_prev;
function ld2_student_primary()
    global LD2_NATIVE_ORIG_ld2_student_primary;
    LD2_NATIVE_ORIG_ld2_student_primary();
    ld2_native_publish("primary");
endfunction
function ld2_terminal_click(id)
    global LD2_NATIVE_ORIG_ld2_terminal_click;
    LD2_NATIVE_ORIG_ld2_terminal_click(id);
    ld2_native_publish("terminal");
endfunction
function ld2_power_toggle()
    global LD2_NATIVE_ORIG_ld2_power_toggle;
    LD2_NATIVE_ORIG_ld2_power_toggle();
    ld2_native_publish("power");
endfunction
function ld2_measure_current()
    global LD2_NATIVE_ORIG_ld2_measure_current;
    LD2_NATIVE_ORIG_ld2_measure_current();
    ld2_native_publish("current");
endfunction
function ld2_measure_voltage()
    global LD2_NATIVE_ORIG_ld2_measure_voltage;
    LD2_NATIVE_ORIG_ld2_measure_voltage();
    ld2_native_publish("voltage");
endfunction
function ld2_remove_voltage_probes()
    global LD2_NATIVE_ORIG_ld2_remove_voltage_probes;
    LD2_NATIVE_ORIG_ld2_remove_voltage_probes();
    ld2_native_publish("remove_probes");
endfunction
function ld2_student_answers_changed()
    global LD2_NATIVE_ORIG_ld2_student_answers_changed;
    LD2_NATIVE_ORIG_ld2_student_answers_changed();
    ld2_native_publish("answer");
endfunction
function ld2_apply_frequency()
    global LD2_NATIVE_ORIG_ld2_apply_frequency;
    LD2_NATIVE_ORIG_ld2_apply_frequency();
    ld2_native_publish("frequency");
endfunction
function ld2_record_resonance_point()
    global LD2_NATIVE_ORIG_ld2_record_resonance_point;
    LD2_NATIVE_ORIG_ld2_record_resonance_point();
    ld2_native_publish("resonance_point");
endfunction
function ld2_record_peak_point()
    global LD2_NATIVE_ORIG_ld2_record_peak_point;
    LD2_NATIVE_ORIG_ld2_record_peak_point();
    ld2_native_publish("peak_point");
endfunction
function ld2_record_f1()
    global LD2_NATIVE_ORIG_ld2_record_f1;
    LD2_NATIVE_ORIG_ld2_record_f1();
    ld2_native_publish("f1");
endfunction
function ld2_record_f2()
    global LD2_NATIVE_ORIG_ld2_record_f2;
    LD2_NATIVE_ORIG_ld2_record_f2();
    ld2_native_publish("f2");
endfunction
function ld2_run_sweep()
    global LD2_NATIVE_ORIG_ld2_run_sweep;
    LD2_NATIVE_ORIG_ld2_run_sweep();
    ld2_native_publish("sweep");
endfunction
function ld2_prev()
    global LD2_NATIVE_ORIG_ld2_prev;
    LD2_NATIVE_ORIG_ld2_prev();
    ld2_native_publish("previous");
endfunction

try
    LD2.ui.figure.figure_name="LD2 · OS INPUT TEST";
    show_window(LD2.ui.figure);
    ld2_native_publish("ready");
    mputl("READY",LD2_NATIVE_OUT+"ready");
catch
    [err,code,line,fn]=lasterror();
    mputl("LD2 GUI witness failed: "+strcat(err," | ")+" at "+fn+":"+string(line),LD2_NATIVE_OUT+"failure");
    exit(1);
end
