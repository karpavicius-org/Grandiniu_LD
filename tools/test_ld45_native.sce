// Test-only read-only callbacks: every user action must originate in the
// operating system's actual mouse or keyboard input, never from Python.
mode(-1);funcprot(0);
global OS45_LAB OS45_ROOT OS45_OUT OS45_SEQ LD4 LD5;
OS45_LAB=getenv("OS45_LAB");
OS45_ROOT=getenv("OS45_ROOT")+"/";
OS45_OUT=getenv("OS45_OUT")+"/";
OS45_SEQ=0;

function os45_witness(action,refreshGeometry)
    global OS45_LAB OS45_OUT OS45_SEQ LD4 LD5;
    if argn(2)<2 then refreshGeometry=%f;end
    OS45_SEQ=OS45_SEQ+1;
    if OS45_LAB=="LD4" then
        b=LD4;
        value=b.voltage;
        pos=0;
        mode=b.wireMode;
    elseif OS45_LAB=="LD5" then
        b=LD5;
        value=b.cfg.E;
        pos=b.position;
        mode=1;
    else error("Invalid OS45_LAB "+OS45_LAB);
    end
    if refreshGeometry then
        fd=mopen(OS45_OUT+"geometry.tsv","wt");
        geometry_dump(b.fig,"current",fd);
        mclose(fd);
    end
    st=struct("seq",OS45_SEQ,"event",action,"lab",OS45_LAB, ...
        "step",b.step,"done_count",sum(b.done),"done",b.done, ...
        "wire_count",size(b.wires,1),"pending",b.pending, ...
        "power",b.powerOn,"switch",b.switchOn,"mode",mode, ...
        "voltage",value,"position",pos,"journal_count",size(b.journal,1), ...
        "journal",b.journal,"answers",b.answers(b.step,:), ...
        "status",b.ui.statusMain.string, ...
        "assessment",b.assessment,"practice",b.practice_used);
    mputl(toJSON(st),OS45_OUT+"state.json");
endfunction

try
    root=OS45_ROOT+"studentui/";
    select OS45_LAB
    case "LD4" then
        exec(root+"LD4/LD4_LOAD.sce",-1);
        cfg=ld4_variant_config(17);
        LD4=struct("cfg",cfg,"student",student_profile(17,"Realūs pelės veiksmai","TEST","LD4"), ...
                   "ui",struct("headless",%f));
        ld4_start();
    case "LD5" then
        exec(root+"LD5/LD5_LOAD.sce",-1);
        cfg=ld5_variant_config(17);
        LD5=struct("cfg",cfg,"student",student_profile(17,"Realūs pelės veiksmai","TEST","LD5"), ...
                   "ui",struct("headless",%f));
        ld5_start();
    else error("Expected LD4 or LD5");
    end
    exec(OS45_ROOT+"tools/ergonomics.sci",-1);
catch
    [err,code,line,fn]=lasterror();
    mputl("OS45 SETUP FAILED: "+strcat(err," | ")+" at "+fn+":"+string(line),OS45_OUT+"failure");
    exit(1);
end

// LD4 original functions stored only after native LD4 starts.
global OS45_ORIG_ld4_terminal_click;
global OS45_ORIG_ld4_toggle_power;
global OS45_ORIG_ld4_toggle_switch;
global OS45_ORIG_ld4_measure;
global OS45_ORIG_ld4_set_voltage;
global OS45_ORIG_ld4_set_resistor;
global OS45_ORIG_ld4_student_primary;
global OS45_ORIG_ld4_answers_changed;
global OS45_ORIG_ld4_jump_step;

// LD5 original functions stored only after native LD5 starts.
global OS45_ORIG_ld5_terminal_click;
global OS45_ORIG_ld5_toggle_power;
global OS45_ORIG_ld5_toggle_switch;
global OS45_ORIG_ld5_measure;
global OS45_ORIG_ld5_set_position;
global OS45_ORIG_ld5_student_primary;
global OS45_ORIG_ld5_answers_changed;
global OS45_ORIG_ld5_jump_step;

try
    if OS45_LAB=="LD4" then
        OS45_ORIG_ld4_terminal_click=ld4_terminal_click;
        OS45_ORIG_ld4_toggle_power=ld4_toggle_power;
        OS45_ORIG_ld4_toggle_switch=ld4_toggle_switch;
        OS45_ORIG_ld4_measure=ld4_measure;
        OS45_ORIG_ld4_set_voltage=ld4_set_voltage;
        OS45_ORIG_ld4_set_resistor=ld4_set_resistor;
        OS45_ORIG_ld4_student_primary=ld4_student_primary;
        OS45_ORIG_ld4_answers_changed=ld4_answers_changed;
        OS45_ORIG_ld4_jump_step=ld4_jump_step;
    end
    if OS45_LAB=="LD5" then
        OS45_ORIG_ld5_terminal_click=ld5_terminal_click;
        OS45_ORIG_ld5_toggle_power=ld5_toggle_power;
        OS45_ORIG_ld5_toggle_switch=ld5_toggle_switch;
        OS45_ORIG_ld5_measure=ld5_measure;
        OS45_ORIG_ld5_set_position=ld5_set_position;
        OS45_ORIG_ld5_student_primary=ld5_student_primary;
        OS45_ORIG_ld5_answers_changed=ld5_answers_changed;
        OS45_ORIG_ld5_jump_step=ld5_jump_step;
    end
catch
    [err,code,line,fn]=lasterror();mputl("ORIGINAL FUNCTION CAPTURE FAILED: "+strcat(err," | "),OS45_OUT+"failure");exit(1);
end

function ld4_terminal_click(id)
    global OS45_ORIG_ld4_terminal_click;
    OS45_ORIG_ld4_terminal_click(id);
    os45_witness("terminal",%f);
endfunction

function ld4_toggle_power()
    global OS45_ORIG_ld4_toggle_power;
    OS45_ORIG_ld4_toggle_power();
    os45_witness("power",%f);
endfunction

function ld4_toggle_switch()
    global OS45_ORIG_ld4_toggle_switch;
    OS45_ORIG_ld4_toggle_switch();
    os45_witness("switch",%f);
endfunction

function ld4_measure()
    global OS45_ORIG_ld4_measure;
    OS45_ORIG_ld4_measure();
    os45_witness("measure",%f);
endfunction

function ld4_set_voltage(v)
    global OS45_ORIG_ld4_set_voltage;
    OS45_ORIG_ld4_set_voltage(v);
    os45_witness("voltage",%f);
endfunction

function ld4_set_resistor(k)
    global OS45_ORIG_ld4_set_resistor;
    OS45_ORIG_ld4_set_resistor(k);
    os45_witness("resistor",%t);
endfunction

function ld4_student_primary()
    global OS45_ORIG_ld4_student_primary;
    OS45_ORIG_ld4_student_primary();
    os45_witness("primary",%t);
endfunction

function ld4_answers_changed()
    global OS45_ORIG_ld4_answers_changed;
    OS45_ORIG_ld4_answers_changed();
    os45_witness("answer",%f);
endfunction

function ld4_jump_step(n)
    global OS45_ORIG_ld4_jump_step;
    OS45_ORIG_ld4_jump_step(n);
    os45_witness("back",%t);
endfunction

function ld5_terminal_click(id)
    global OS45_ORIG_ld5_terminal_click;
    OS45_ORIG_ld5_terminal_click(id);
    os45_witness("terminal",%f);
endfunction

function ld5_toggle_power()
    global OS45_ORIG_ld5_toggle_power;
    OS45_ORIG_ld5_toggle_power();
    os45_witness("power",%f);
endfunction

function ld5_toggle_switch()
    global OS45_ORIG_ld5_toggle_switch;
    OS45_ORIG_ld5_toggle_switch();
    os45_witness("switch",%f);
endfunction

function ld5_measure()
    global OS45_ORIG_ld5_measure;
    OS45_ORIG_ld5_measure();
    os45_witness("measure",%f);
endfunction

function ld5_set_position(k)
    global OS45_ORIG_ld5_set_position;
    OS45_ORIG_ld5_set_position(k);
    os45_witness("position",%f);
endfunction

function ld5_student_primary()
    global OS45_ORIG_ld5_student_primary;
    OS45_ORIG_ld5_student_primary();
    os45_witness("primary",%t);
endfunction

function ld5_answers_changed()
    global OS45_ORIG_ld5_answers_changed;
    OS45_ORIG_ld5_answers_changed();
    os45_witness("answer",%f);
endfunction

function ld5_jump_step(n)
    global OS45_ORIG_ld5_jump_step;
    OS45_ORIG_ld5_jump_step(n);
    os45_witness("back",%t);
endfunction

try
    if OS45_LAB=="LD4" then
        b=LD4; b.ui.studentPrimary.tag="OS_PRIMARY";b.ui.controls($).tag="OS_BACK";
        n=3;
    else
        b=LD5; b.ui.studentPrimary.tag="OS_PRIMARY";b.ui.controls($).tag="OS_BACK";
        n=1;
    end
    b.fig.figure_name=OS45_LAB+" · OS INPUT TEST";
    show_window(b.fig);
    lines=emptystr(0,1);
    for modeId=1:n
        if OS45_LAB=="LD4" then
            if modeId==3 then wires=ld4_canonical_wires("S");
            else wires=ld4_canonical_wires(modeId);end
        else
            wires=ld5_canonical_wires();
        end
        for j=1:size(wires,1)
            if OS45_LAB=="LD4" then
                a=ld4_terminal_code(wires(j,1));z=ld4_terminal_code(wires(j,2));
            else
                a=ld5_terminal_code(wires(j,1));z=ld5_terminal_code(wires(j,2));
            end
            lines($+1)=string(modeId)+ascii(9)+a+ascii(9)+z;
        end
    end
    mputl(lines,OS45_OUT+"wires.tsv");
    mputl(toJSON(cfg),OS45_OUT+"config.json");
    os45_witness("ready",%t);
    mputl("READY",OS45_OUT+"ready");
catch
    [err,code,line,fn]=lasterror();
    mputl("OS45 READY FAILED: "+strcat(err," | ")+" at "+fn+":"+string(line),OS45_OUT+"failure");
    exit(1);
end
