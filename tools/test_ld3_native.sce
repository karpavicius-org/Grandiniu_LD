// LD3 native desktop acceptance. Original callbacks run ONLY in response to
// OS events. The wrappers below observe their results; they never drive the lab.
mode(-1);funcprot(0);
global LD3 LD3_NATIVE_OUT LD3_NATIVE_ROOT LD3_NATIVE_SEQ;
LD3_NATIVE_OUT=getenv("LD3_NATIVE_OUT")+"/";
LD3_NATIVE_ROOT=getenv("LD3_NATIVE_ROOT")+"/";
LD3_NATIVE_SEQ=0;

function ld3_native_publish(event)
    global LD3 LD3_NATIVE_OUT LD3_NATIVE_SEQ;
    LD3_NATIVE_SEQ=LD3_NATIVE_SEQ+1;
    instruction=ld3_step_instruction(LD3.step);
    if or(LD3.step==[4 5]) then
        // These instructions must work with the actual displayed mA readings.
        assert_checktrue(strindex(instruction,"1000")<>[]);
        assert_checktrue(strindex(instruction,"mA")<>[]);
    end
    st=struct("seq",LD3_NATIVE_SEQ,"event",event,"step",LD3.step, ...
        "done_count",sum(LD3.done),"wire_count",size(LD3.wires,1), ...
        "journal_count",size(LD3.journal,1),"journal",LD3.journal, ...
        "pending",LD3.pending,"power",LD3.powerOn,"switch",LD3.switchOn, ...
        "voltage",LD3.voltage,"answers",LD3.answers(LD3.step,:), ...
        "all_answers",LD3.answers,"cfg",LD3.cfg, ...
        "status",LD3.ui.statusMain.string,"instruction",instruction);
    fd=mopen(LD3_NATIVE_OUT+"geometry.tsv","wt");
    geometry_dump(LD3.fig,"LD3-native",fd);mclose(fd);
    mputl(toJSON(st),LD3_NATIVE_OUT+"state.json");
endfunction

try
    root=LD3_NATIVE_ROOT+"studentui/";
    exec(root+"LD3/LD3_LOAD.sce",-1);
    cfg=ld3_variant_config(17);
    LD3=struct("root",root+"LD3/","cfg",cfg, ...
        "student",student_profile(17,"Native LD3 test","TEST","LD3"));
    ld3_start();
    exec(LD3_NATIVE_ROOT+"tools/ergonomics.sci",-1);
    LD3.ui.studentPrimary.tag="OS_PRIMARY";
    LD3.ui.controls($).tag="OS_BACK";
    global LD3_OLD_TERMINAL LD3_OLD_POWER LD3_OLD_SWITCH LD3_OLD_VOLTAGE;
    global LD3_OLD_MEASURE LD3_OLD_PRIMARY LD3_OLD_ANSWER LD3_OLD_BACK;
    LD3_OLD_TERMINAL=ld3_terminal_click;LD3_OLD_POWER=ld3_toggle_power;
    LD3_OLD_SWITCH=ld3_toggle_switch;LD3_OLD_VOLTAGE=ld3_set_voltage;
    LD3_OLD_MEASURE=ld3_measure;LD3_OLD_PRIMARY=ld3_student_primary;
    LD3_OLD_ANSWER=ld3_answers_changed;LD3_OLD_BACK=ld3_jump_step;
catch
    [err,code,line,fn]=lasterror();
    mputl(strcat(err," | ")+" at "+fn+":"+string(line),LD3_NATIVE_OUT+"failure");
    exit(1);
end

function ld3_terminal_click(id)
    global LD3_OLD_TERMINAL;
    LD3_OLD_TERMINAL(id);ld3_native_publish("terminal");
endfunction
function ld3_toggle_power()
    global LD3_OLD_POWER;
    LD3_OLD_POWER();ld3_native_publish("power");
endfunction
function ld3_toggle_switch()
    global LD3_OLD_SWITCH;
    LD3_OLD_SWITCH();ld3_native_publish("switch");
endfunction
function ld3_set_voltage(v)
    global LD3_OLD_VOLTAGE;
    LD3_OLD_VOLTAGE(v);ld3_native_publish("voltage");
endfunction
function ld3_measure()
    global LD3_OLD_MEASURE;
    LD3_OLD_MEASURE();ld3_native_publish("measure");
endfunction
function ld3_student_primary()
    global LD3_OLD_PRIMARY;
    LD3_OLD_PRIMARY();ld3_native_publish("primary");
endfunction
function ld3_answers_changed()
    global LD3_OLD_ANSWER;
    LD3_OLD_ANSWER();ld3_native_publish("answer");
endfunction
function ld3_jump_step(n)
    global LD3_OLD_BACK;
    LD3_OLD_BACK(n);ld3_native_publish("back");
endfunction

try
    LD3.fig.figure_name="LD3 · OS INPUT TEST";show_window(LD3.fig);
    ld3_native_publish("ready");
catch
    [err,code,line,fn]=lasterror();
    mputl(strcat(err," | ")+" at "+fn+":"+string(line),LD3_NATIVE_OUT+"failure");
    exit(1);
end
