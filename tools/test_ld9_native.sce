// Test-only witnesses observe real OS input; they do not inject student state.
mode(-1);funcprot(0);
global LD9 OS9_ROOT OS9_OUT OS9_SEQ;
OS9_ROOT=getenv("OS9_ROOT")+"/";OS9_OUT=getenv("OS9_OUT")+"/";OS9_SEQ=0;
function os9_witness(action,geometry)
    global LD9 OS9_OUT OS9_SEQ;
    OS9_SEQ=OS9_SEQ+1;
    if geometry then
        fd=mopen(OS9_OUT+"geometry.tsv","wt");geometry_dump(LD9.fig,"current",fd);mclose(fd);
    end
    st=struct("seq",OS9_SEQ,"event",action,"step",LD9.step,"done_count",sum(LD9.done), ...
        "wire_count",size(LD9.wires,1),"pending",LD9.pending,"power",LD9.powerOn, ...
        "switch",LD9.switchOn,"journal_count",size(LD9.journal,1),"journal",LD9.journal, ...
        "answers",LD9.answers(LD9.step,:),"status",LD9.ui.statusMain.string, ...
        "assessment",LD9.assessment,"practice",LD9.practice_used);
    mputl(toJSON(st),OS9_OUT+"state.json");
endfunction
try
    exec(OS9_ROOT+"studentui/LD9/LD9_LOAD.sce",-1);
    cfg=ld9_variant_config(17);
    LD9=struct("cfg",cfg,"student",student_profile(17,"Realūs pelės veiksmai","TEST","LD9"),"ui",struct("headless",%f));
    ld9_start();exec(OS9_ROOT+"tools/ergonomics.sci",-1);
catch
    mputl(strcat(lasterror()," | "),OS9_OUT+"failure");exit(1);
end
global OS9_ORIG_ld9_terminal_click;OS9_ORIG_ld9_terminal_click=ld9_terminal_click;
global OS9_ORIG_ld9_toggle_power;OS9_ORIG_ld9_toggle_power=ld9_toggle_power;
global OS9_ORIG_ld9_toggle_switch;OS9_ORIG_ld9_toggle_switch=ld9_toggle_switch;
global OS9_ORIG_ld9_set_freq;OS9_ORIG_ld9_set_freq=ld9_set_freq;
global OS9_ORIG_ld9_set_target;OS9_ORIG_ld9_set_target=ld9_set_target;
global OS9_ORIG_ld9_measure;OS9_ORIG_ld9_measure=ld9_measure;
global OS9_ORIG_ld9_student_primary;OS9_ORIG_ld9_student_primary=ld9_student_primary;
global OS9_ORIG_ld9_answers_changed;OS9_ORIG_ld9_answers_changed=ld9_answers_changed;
global OS9_ORIG_ld9_jump_step;OS9_ORIG_ld9_jump_step=ld9_jump_step;

function ld9_terminal_click(id)
    global OS9_ORIG_ld9_terminal_click;
    OS9_ORIG_ld9_terminal_click(id);os9_witness("terminal",%f);
endfunction

function ld9_toggle_power()
    global OS9_ORIG_ld9_toggle_power;
    OS9_ORIG_ld9_toggle_power();os9_witness("power",%f);
endfunction

function ld9_toggle_switch()
    global OS9_ORIG_ld9_toggle_switch;
    OS9_ORIG_ld9_toggle_switch();os9_witness("switch",%f);
endfunction

function ld9_set_freq(k)
    global OS9_ORIG_ld9_set_freq;
    OS9_ORIG_ld9_set_freq(k);os9_witness("frequency",%f);
endfunction

function ld9_set_target(t)
    global OS9_ORIG_ld9_set_target;
    OS9_ORIG_ld9_set_target(t);os9_witness("target",%f);
endfunction

function ld9_measure()
    global OS9_ORIG_ld9_measure;
    OS9_ORIG_ld9_measure();os9_witness("measure",%f);
endfunction

function ld9_student_primary()
    global OS9_ORIG_ld9_student_primary;
    OS9_ORIG_ld9_student_primary();os9_witness("primary",%t);
endfunction

function ld9_answers_changed()
    global OS9_ORIG_ld9_answers_changed;
    OS9_ORIG_ld9_answers_changed();os9_witness("answer",%f);
endfunction

function ld9_jump_step(n)
    global OS9_ORIG_ld9_jump_step;
    OS9_ORIG_ld9_jump_step(n);os9_witness("back",%t);
endfunction

LD9.ui.studentPrimary.tag="OS_PRIMARY";LD9.ui.controls($).tag="OS_BACK";
LD9.fig.figure_name="LD9 · OS INPUT TEST";show_window(LD9.fig);
mputl(toJSON(cfg),OS9_OUT+"config.json");os9_witness("ready",%t);
