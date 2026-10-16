// Test-only witnesses observe real OS input; they do not inject student state.
mode(-1);funcprot(0);
global LD11 OS11_ROOT OS11_OUT OS11_SEQ;
OS11_ROOT=getenv("OS11_ROOT")+"/";OS11_OUT=getenv("OS11_OUT")+"/";OS11_SEQ=0;
function os11_witness(action,geometry)
    global LD11 OS11_OUT OS11_SEQ;
    OS11_SEQ=OS11_SEQ+1;
    if geometry then
        fd=mopen(OS11_OUT+"geometry.tsv","wt");geometry_dump(LD11.fig,"current",fd);mclose(fd);
    end
    mainReading=findobj("tag","reading:A");powerReading=findobj("tag","reading:W");capReading=findobj("tag","reading:CK");
    st=struct("seq",OS11_SEQ,"event",action,"step",LD11.step,"done_count",sum(LD11.done), ...
        "wire_count",size(LD11.wires,1),"pending",LD11.pending,"power",LD11.powerOn, ...
        "switch",LD11.switchOn,"journal_count",size(LD11.journal,1),"journal",LD11.journal, ...
        "answers",LD11.answers(LD11.step,:),"status",LD11.ui.statusMain.string, ...
        "assessment",LD11.assessment,"practice",LD11.practice_used, ...
        "main_current",mainReading.string, ...
        "active_power",powerReading.string,"capacitor",capReading.string,"journal_display",LD11.ui.journalList.string);
    mputl(toJSON(st),OS11_OUT+"state.json");
endfunction
try
    exec(OS11_ROOT+"studentui/LD11/LD11_LOAD.sce",-1);
    cfg=ld11_variant_config(17);
    LD11=struct("cfg",cfg,"student",student_profile(17,"Realūs pelės veiksmai","TEST","LD11"),"ui",struct("headless",%f));
    ld11_start();exec(OS11_ROOT+"tools/ergonomics.sci",-1);
catch
    mputl(strcat(lasterror()," | "),OS11_OUT+"failure");exit(1);
end
global OS11_ORIG_ld11_terminal_click;OS11_ORIG_ld11_terminal_click=ld11_terminal_click;
global OS11_ORIG_ld11_toggle_power;OS11_ORIG_ld11_toggle_power=ld11_toggle_power;
global OS11_ORIG_ld11_toggle_switch;OS11_ORIG_ld11_toggle_switch=ld11_toggle_switch;
global OS11_ORIG_ld11_set_mode;OS11_ORIG_ld11_set_mode=ld11_set_mode;
global OS11_ORIG_ld11_measure;OS11_ORIG_ld11_measure=ld11_measure;
global OS11_ORIG_ld11_student_primary;OS11_ORIG_ld11_student_primary=ld11_student_primary;
global OS11_ORIG_ld11_answers_changed;OS11_ORIG_ld11_answers_changed=ld11_answers_changed;
global OS11_ORIG_ld11_jump_step;OS11_ORIG_ld11_jump_step=ld11_jump_step;

function ld11_terminal_click(id)
    global OS11_ORIG_ld11_terminal_click;
    OS11_ORIG_ld11_terminal_click(id);os11_witness("terminal",%f);
endfunction

function ld11_toggle_power()
    global OS11_ORIG_ld11_toggle_power;
    OS11_ORIG_ld11_toggle_power();os11_witness("power",%f);
endfunction

function ld11_toggle_switch()
    global OS11_ORIG_ld11_toggle_switch;
    OS11_ORIG_ld11_toggle_switch();os11_witness("switch",%f);
endfunction

function ld11_set_mode(k)
    global OS11_ORIG_ld11_set_mode;
    OS11_ORIG_ld11_set_mode(k);os11_witness("mode",%f);
endfunction

function ld11_measure()
    global OS11_ORIG_ld11_measure;
    OS11_ORIG_ld11_measure();os11_witness("measure",%f);
endfunction

function ld11_student_primary()
    global OS11_ORIG_ld11_student_primary;
    OS11_ORIG_ld11_student_primary();os11_witness("primary",%t);
endfunction

function ld11_answers_changed()
    global OS11_ORIG_ld11_answers_changed;
    OS11_ORIG_ld11_answers_changed();os11_witness("answer",%f);
endfunction

function ld11_jump_step(n)
    global OS11_ORIG_ld11_jump_step;
    OS11_ORIG_ld11_jump_step(n);os11_witness("back",%t);
endfunction

LD11.ui.studentPrimary.tag="OS_PRIMARY";LD11.ui.controls($).tag="OS_BACK";
LD11.fig.figure_name="LD11 · OS INPUT TEST";show_window(LD11.fig);
mputl(toJSON(cfg),OS11_OUT+"config.json");os11_witness("ready",%t);
