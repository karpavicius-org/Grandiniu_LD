// Test-only witnesses observe real OS input; they do not inject student state.
mode(-1);funcprot(0);
global LD12 OS12_ROOT OS12_OUT OS12_SEQ;
OS12_ROOT=getenv("OS12_ROOT")+"/";OS12_OUT=getenv("OS12_OUT")+"/";OS12_SEQ=0;
function os12_witness(action,geometry)
    global LD12 OS12_OUT OS12_SEQ;
    OS12_SEQ=OS12_SEQ+1;
    if geometry then
        fd=mopen(OS12_OUT+"geometry.tsv","wt");geometry_dump(LD12.fig,"current",fd);mclose(fd);
    end
    mainReading=findobj("tag","reading:A");voltReading=findobj("tag","reading:V");branchReading=findobj("tag","reading:VM");
    st=struct("seq",OS12_SEQ,"event",action,"step",LD12.step,"done_count",sum(LD12.done), ...
        "wire_count",size(LD12.wires,1),"pending",LD12.pending,"power",LD12.powerOn, ...
        "switch",LD12.switchOn,"journal_count",size(LD12.journal,1),"journal",LD12.journal, ...
        "answers",LD12.answers(LD12.step,:),"status",LD12.ui.statusMain.string, ...
        "assessment",LD12.assessment,"practice",LD12.practice_used, ...
        "main_current",mainReading.string, ...
        "voltage",voltReading.string,"branch",branchReading.string,"phase",LD12.phase,"journal_display",LD12.ui.journalList.string);
    mputl(toJSON(st),OS12_OUT+"state.json");
endfunction
try
    exec(OS12_ROOT+"studentui/LD12/LD12_LOAD.sce",-1);
    cfg=ld12_variant_config(17);
    LD12=struct("cfg",cfg,"student",student_profile(17,"Realūs pelės veiksmai","TEST","LD12"),"ui",struct("headless",%f));
    ld12_start();exec(OS12_ROOT+"tools/ergonomics.sci",-1);
catch
    mputl(strcat(lasterror()," | "),OS12_OUT+"failure");exit(1);
end
global OS12_ORIG_ld12_terminal_click;OS12_ORIG_ld12_terminal_click=ld12_terminal_click;
global OS12_ORIG_ld12_toggle_power;OS12_ORIG_ld12_toggle_power=ld12_toggle_power;
global OS12_ORIG_ld12_toggle_switch;OS12_ORIG_ld12_toggle_switch=ld12_toggle_switch;
global OS12_ORIG_ld12_set_mode;OS12_ORIG_ld12_set_mode=ld12_set_mode;
global OS12_ORIG_ld12_set_phase;OS12_ORIG_ld12_set_phase=ld12_set_phase;
global OS12_ORIG_ld12_measure;OS12_ORIG_ld12_measure=ld12_measure;
global OS12_ORIG_ld12_student_primary;OS12_ORIG_ld12_student_primary=ld12_student_primary;
global OS12_ORIG_ld12_answers_changed;OS12_ORIG_ld12_answers_changed=ld12_answers_changed;
global OS12_ORIG_ld12_jump_step;OS12_ORIG_ld12_jump_step=ld12_jump_step;

function ld12_terminal_click(id)
    global OS12_ORIG_ld12_terminal_click;
    OS12_ORIG_ld12_terminal_click(id);os12_witness("terminal",%f);
endfunction

function ld12_toggle_power()
    global OS12_ORIG_ld12_toggle_power;
    OS12_ORIG_ld12_toggle_power();os12_witness("power",%f);
endfunction

function ld12_toggle_switch()
    global OS12_ORIG_ld12_toggle_switch;
    OS12_ORIG_ld12_toggle_switch();os12_witness("switch",%f);
endfunction

function ld12_set_mode(k)
    global OS12_ORIG_ld12_set_mode;
    OS12_ORIG_ld12_set_mode(k);os12_witness("mode",%f);
endfunction

function ld12_set_phase(k)
    global OS12_ORIG_ld12_set_phase;
    OS12_ORIG_ld12_set_phase(k);os12_witness("phase",%f);
endfunction

function ld12_measure()
    global OS12_ORIG_ld12_measure;
    OS12_ORIG_ld12_measure();os12_witness("measure",%f);
endfunction

function ld12_student_primary()
    global OS12_ORIG_ld12_student_primary;
    OS12_ORIG_ld12_student_primary();os12_witness("primary",%t);
endfunction

function ld12_answers_changed()
    global OS12_ORIG_ld12_answers_changed;
    OS12_ORIG_ld12_answers_changed();os12_witness("answer",%f);
endfunction

function ld12_jump_step(n)
    global OS12_ORIG_ld12_jump_step;
    OS12_ORIG_ld12_jump_step(n);os12_witness("back",%t);
endfunction

LD12.ui.studentPrimary.tag="OS_PRIMARY";LD12.ui.controls($).tag="OS_BACK";
LD12.fig.figure_name="LD12 · OS INPUT TEST";show_window(LD12.fig);
mputl(toJSON(cfg),OS12_OUT+"config.json");os12_witness("ready",%t);
