// Test-only witnesses observe real OS input; they do not inject student state.
mode(-1);funcprot(0);
global LD10 OS10_ROOT OS10_OUT OS10_SEQ;
OS10_ROOT=getenv("OS10_ROOT")+"/";OS10_OUT=getenv("OS10_OUT")+"/";OS10_SEQ=0;
function os10_witness(action,geometry)
    global LD10 OS10_OUT OS10_SEQ;
    OS10_SEQ=OS10_SEQ+1;
    if geometry then
        fd=mopen(OS10_OUT+"geometry.tsv","wt");geometry_dump(LD10.fig,"current",fd);mclose(fd);
    end
    st=struct("seq",OS10_SEQ,"event",action,"step",LD10.step,"done_count",sum(LD10.done), ...
        "wire_count",size(LD10.wires,1),"pending",LD10.pending,"power",LD10.powerOn, ...
        "switch",LD10.switchOn,"journal_count",size(LD10.journal,1),"journal",LD10.journal, ...
        "answers",LD10.answers(LD10.step,:),"status",LD10.ui.statusMain.string, ...
        "assessment",LD10.assessment,"practice",LD10.practice_used);
    mputl(toJSON(st),OS10_OUT+"state.json");
endfunction
try
    exec(OS10_ROOT+"studentui/LD10/LD10_LOAD.sce",-1);
    cfg=ld10_variant_config(17);
    LD10=struct("cfg",cfg,"student",student_profile(17,"Realūs pelės veiksmai","TEST","LD10"),"ui",struct("headless",%f));
    ld10_start();exec(OS10_ROOT+"tools/ergonomics.sci",-1);
catch
    mputl(strcat(lasterror()," | "),OS10_OUT+"failure");exit(1);
end
global OS10_ORIG_ld10_terminal_click;OS10_ORIG_ld10_terminal_click=ld10_terminal_click;
global OS10_ORIG_ld10_toggle_power;OS10_ORIG_ld10_toggle_power=ld10_toggle_power;
global OS10_ORIG_ld10_toggle_switch;OS10_ORIG_ld10_toggle_switch=ld10_toggle_switch;
global OS10_ORIG_ld10_set_freq;OS10_ORIG_ld10_set_freq=ld10_set_freq;
global OS10_ORIG_ld10_set_target;OS10_ORIG_ld10_set_target=ld10_set_target;
global OS10_ORIG_ld10_measure;OS10_ORIG_ld10_measure=ld10_measure;
global OS10_ORIG_ld10_student_primary;OS10_ORIG_ld10_student_primary=ld10_student_primary;
global OS10_ORIG_ld10_answers_changed;OS10_ORIG_ld10_answers_changed=ld10_answers_changed;
global OS10_ORIG_ld10_jump_step;OS10_ORIG_ld10_jump_step=ld10_jump_step;

function ld10_terminal_click(id)
    global OS10_ORIG_ld10_terminal_click;
    OS10_ORIG_ld10_terminal_click(id);os10_witness("terminal",%f);
endfunction

function ld10_toggle_power()
    global OS10_ORIG_ld10_toggle_power;
    OS10_ORIG_ld10_toggle_power();os10_witness("power",%f);
endfunction

function ld10_toggle_switch()
    global OS10_ORIG_ld10_toggle_switch;
    OS10_ORIG_ld10_toggle_switch();os10_witness("switch",%f);
endfunction

function ld10_set_freq(k)
    global OS10_ORIG_ld10_set_freq;
    OS10_ORIG_ld10_set_freq(k);os10_witness("frequency",%f);
endfunction

function ld10_set_target(t)
    global OS10_ORIG_ld10_set_target;
    OS10_ORIG_ld10_set_target(t);os10_witness("target",%f);
endfunction

function ld10_measure()
    global OS10_ORIG_ld10_measure;
    OS10_ORIG_ld10_measure();os10_witness("measure",%f);
endfunction

function ld10_student_primary()
    global OS10_ORIG_ld10_student_primary;
    OS10_ORIG_ld10_student_primary();os10_witness("primary",%t);
endfunction

function ld10_answers_changed()
    global OS10_ORIG_ld10_answers_changed;
    OS10_ORIG_ld10_answers_changed();os10_witness("answer",%f);
endfunction

function ld10_jump_step(n)
    global OS10_ORIG_ld10_jump_step;
    OS10_ORIG_ld10_jump_step(n);os10_witness("back",%t);
endfunction

LD10.ui.studentPrimary.tag="OS_PRIMARY";LD10.ui.controls($).tag="OS_BACK";
LD10.fig.figure_name="LD10 · OS INPUT TEST";show_window(LD10.fig);
mputl(toJSON(cfg),OS10_OUT+"config.json");os10_witness("ready",%t);
