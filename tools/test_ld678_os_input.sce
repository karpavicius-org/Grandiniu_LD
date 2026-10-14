// OS-level input acceptance. The external driver only clicks and types in the
// real native window; these wrappers OBSERVE resulting callbacks, never drive them.
mode(-1); funcprot(0);
global OS_INPUT_LAB OS_INPUT_SEQ OS_INPUT_OUT LD6 LD7 LD8;
OS_INPUT_LAB=getenv("OS_INPUT_LAB");
OS_INPUT_OUT=getenv("OS_INPUT_OUT")+"/";
OS_INPUT_SEQ=0;
OS_INPUT_SOURCE=getenv("OS_INPUT_SOURCE")+"/";
global OS_OLD6_TERM OS_OLD6_POWER OS_OLD6_SWITCH OS_OLD6_MEASURE OS_OLD6_PRIMARY OS_OLD6_MODE;
global OS_OLD7_TERM OS_OLD7_POWER OS_OLD7_SWITCH OS_OLD7_MEASURE OS_OLD7_PRIMARY OS_OLD7_MODE OS_OLD7_POS;
global OS_OLD8_TERM OS_OLD8_POWER OS_OLD8_SWITCH OS_OLD8_MEASURE OS_OLD8_PRIMARY OS_OLD8_MODE;

function os_input_witness(action,geometry)
    global OS_INPUT_LAB OS_INPUT_SEQ OS_INPUT_OUT LD6 LD7 LD8;
    if argn(2)<2 then geometry=%f;end
    OS_INPUT_SEQ=OS_INPUT_SEQ+1;
    select OS_INPUT_LAB
    case "LD6" then b=LD6;
    case "LD7" then b=LD7;
    case "LD8" then b=LD8;
    else error("Unexpected lab");
    end
    if geometry then
        fd=mopen(OS_INPUT_OUT+"geometry.tsv","wt");
        geometry_dump(b.fig,"native",fd);
        mclose(fd);
    end
    st=struct("seq",OS_INPUT_SEQ,"event",action,"lab",OS_INPUT_LAB, ...
        "step",b.step,"mode",b.wireMode,"wire_count",size(b.wires,1), ...
        "pending",b.pending,"power",b.powerOn,"switch",b.switchOn, ...
        "journal",size(b.journal,1),"done_count",sum(b.done),"done",b.done,"answers",b.answers, ...
        "status",b.ui.statusMain.string);
    mputl(toJSON(st),OS_INPUT_OUT+"state.json");
endfunction


try
    root=OS_INPUT_SOURCE+"studentui/";
    select OS_INPUT_LAB
    case "LD6" then
        exec(root+"LD6/LD6_LOAD.sce",-1);
        cfg=ld6_variant_config(17);
        LD6=struct("cfg",cfg,"student",student_profile(17,"Realūs paspaudimai","TEST","LD6"),"ui",struct("headless",%f));
        // Preserve the uninstrumented production entrypoints.
        OS_OLD6_TERM=ld6_terminal_click; OS_OLD6_POWER=ld6_toggle_power;
        OS_OLD6_SWITCH=ld6_toggle_switch; OS_OLD6_MEASURE=ld6_measure;
        OS_OLD6_PRIMARY=ld6_student_primary; OS_OLD6_MODE=ld6_set_mode;
        ld6_start(); b=LD6;
        count=4;
    case "LD7" then
        exec(root+"LD7/LD7_LOAD.sce",-1);
        cfg=ld7_variant_config(17);
        LD7=struct("cfg",cfg,"student",student_profile(17,"Realūs paspaudimai","TEST","LD7"),"ui",struct("headless",%f));
        OS_OLD7_TERM=ld7_terminal_click; OS_OLD7_POWER=ld7_toggle_power;
        OS_OLD7_SWITCH=ld7_toggle_switch; OS_OLD7_MEASURE=ld7_measure;
        OS_OLD7_PRIMARY=ld7_student_primary; OS_OLD7_MODE=ld7_set_mode;
        OS_OLD7_POS=ld7_set_position;
        ld7_start(); b=LD7;
        count=3;
    case "LD8" then
        exec(root+"LD8/LD8_LOAD.sce",-1);
        cfg=ld8_variant_config(17);
        LD8=struct("cfg",cfg,"student",student_profile(17,"Realūs paspaudimai","TEST","LD8"),"ui",struct("headless",%f));
        OS_OLD8_TERM=ld8_terminal_click; OS_OLD8_POWER=ld8_toggle_power;
        OS_OLD8_SWITCH=ld8_toggle_switch; OS_OLD8_MEASURE=ld8_measure;
        OS_OLD8_PRIMARY=ld8_student_primary; OS_OLD8_MODE=ld8_set_mode;
        ld8_start(); b=LD8;
        count=3;
    else error("Expected LD6, LD7 or LD8.");
    end
catch
    [err,code,line,fn]=lasterror();
    mputl("INITIALIZATION FAILED: "+strcat(err," | ")+" at "+fn+":"+string(line),OS_INPUT_OUT+"failure");
    disp(err);exit(1);
end

// OBSERVERS. The original production function always runs first. All acts are
// verified through the independent native control callback chain.
function ld6_terminal_click(id)
    global OS_OLD6_TERM;
    OS_OLD6_TERM(id);os_input_witness("terminal",%f);
endfunction
function ld6_toggle_power()
    global OS_OLD6_POWER;
    OS_OLD6_POWER();os_input_witness("power",%f);
endfunction
function ld6_toggle_switch()
    global OS_OLD6_SWITCH;
    OS_OLD6_SWITCH();os_input_witness("switch",%f);
endfunction
function ld6_measure()
    global OS_OLD6_MEASURE;
    OS_OLD6_MEASURE();os_input_witness("measure",%f);
endfunction
function ld6_student_primary()
    global OS_OLD6_PRIMARY;
    OS_OLD6_PRIMARY();os_input_witness("primary",%t);
endfunction
function ld6_set_mode(n)
    global OS_OLD6_MODE;
    OS_OLD6_MODE(n);os_input_witness("mode",%t);
endfunction

function ld7_terminal_click(id)
    global OS_OLD7_TERM;
    OS_OLD7_TERM(id);os_input_witness("terminal",%f);
endfunction
function ld7_toggle_power()
    global OS_OLD7_POWER;
    OS_OLD7_POWER();os_input_witness("power",%f);
endfunction
function ld7_toggle_switch()
    global OS_OLD7_SWITCH;
    OS_OLD7_SWITCH();os_input_witness("switch",%f);
endfunction
function ld7_measure()
    global OS_OLD7_MEASURE;
    OS_OLD7_MEASURE();os_input_witness("measure",%f);
endfunction
function ld7_student_primary()
    global OS_OLD7_PRIMARY;
    OS_OLD7_PRIMARY();os_input_witness("primary",%t);
endfunction
function ld7_set_mode(n)
    global OS_OLD7_MODE;
    OS_OLD7_MODE(n);os_input_witness("mode",%t);
endfunction
function ld7_set_position(n)
    global OS_OLD7_POS;
    OS_OLD7_POS(n);os_input_witness("position",%f);
endfunction

function ld8_terminal_click(id)
    global OS_OLD8_TERM;
    OS_OLD8_TERM(id);os_input_witness("terminal",%f);
endfunction
function ld8_toggle_power()
    global OS_OLD8_POWER;
    OS_OLD8_POWER();os_input_witness("power",%f);
endfunction
function ld8_toggle_switch()
    global OS_OLD8_SWITCH;
    OS_OLD8_SWITCH();os_input_witness("switch",%f);
endfunction
function ld8_measure()
    global OS_OLD8_MEASURE;
    OS_OLD8_MEASURE();os_input_witness("measure",%f);
endfunction
function ld8_student_primary()
    global OS_OLD8_PRIMARY;
    OS_OLD8_PRIMARY();os_input_witness("primary",%t);
endfunction
function ld8_set_mode(n)
    global OS_OLD8_MODE;
    OS_OLD8_MODE(n);os_input_witness("mode",%t);
endfunction

try
    // The driver's target geometry is taken from actual visible controls.
    exec(OS_INPUT_SOURCE+"tools/ergonomics.sci",-1);
    b.ui.studentPrimary.tag="OS_PRIMARY";
    b.fig.figure_name=OS_INPUT_LAB+" · OS INPUT TEST";
    show_window(b.fig);
    lines=emptystr(0,1);
    for modeId=1:count
        select OS_INPUT_LAB
        case "LD6" then w=ld6_canonical_wires(modeId);
        case "LD7" then w=ld7_canonical_wires(modeId);
        case "LD8" then w=ld8_canonical_wires(modeId);
        end
        for j=1:size(w,1)
            select OS_INPUT_LAB
            case "LD6" then a=ld6_terminal_code(w(j,1));z=ld6_terminal_code(w(j,2));
            case "LD7" then a=ld7_terminal_code(w(j,1));z=ld7_terminal_code(w(j,2));
            case "LD8" then a=ld8_terminal_code(w(j,1));z=ld8_terminal_code(w(j,2));
            end
            lines($+1)=string(modeId)+ascii(9)+a+ascii(9)+z;
        end
    end
    mputl(lines,OS_INPUT_OUT+"wires.tsv");
    mputl(toJSON(cfg),OS_INPUT_OUT+"config.json");
    os_input_witness("ready",%t);
    mputl("READY",OS_INPUT_OUT+"ready");
catch
    [err,code,line,fn]=lasterror();
    mputl("STARTUP FAILED: "+strcat(err," | ")+" at "+fn+":"+string(line),OS_INPUT_OUT+"failure");
    disp(err);
    exit(1);
end
