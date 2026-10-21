// RT bridge: original V2 figure, circuit renderer, contacts and device cards.
// No model, geometry, canonical wiring or calculation widget is replaced here.
function v=rt_prepare_10(root,st,cfg)
    global LD10;
    LD10=struct("root",root,"cfg",cfg,"student",st,"assessment",%t,"practice_used",%f,"autosave_enabled",%f);
    ld10_init_state();
    ld10_build_gui();
    v=struct("fig",LD10.fig,"board",LD10.ui.circuitFrame,"task",LD10.ui.right, ...
        "primary",LD10.ui.studentPrimary,"measure",LD10.ui.controls(10),"journal",LD10.ui.journalList);
endfunction

function rt_apply_10(t,phase)
    global LD10 MO;
    // The controller supplies submitted wires; this bridge never creates any.
    if isfield(MO,"pending") then LD10.pending=MO.pending;end
    LD10.demoMode=%f;
    LD10.rt_phase=phase;
    LD10.rt_measured=%f;
    if phase<>"wiring" & isfield(MO,"current") then
        if typeof(MO.current)=="st" then
            if isfield(MO.current,"values") then LD10.rt_measured=size(MO.current.values,"*")>0;end
        end
    end
    LD10.powerOn=LD10.rt_measured;LD10.switchOn=LD10.rt_measured;
    LD10.freqPoint=t.freqPoint;LD10.target=t.target;LD10.step=t.freqPoint+1;
    if phase=="wiring" then LD10.step=1;end
endfunction

function s=rt10_format(x)
    if abs(x)<.005 then x=0;end
    s=mo_display(x);
endfunction

function rt10_text(tag,text)
    global LD10;
    h=student_guide_find(LD10.fig,tag);
    if h==[] then error("Originaliame LD10 stende trūksta "+tag+".");end
    h.string=text;
endfunction

function rt_draw_10()
    global LD10;
    drawing=LD10.fig.immediate_drawing;LD10.fig.immediate_drawing="off";
    ld10_render_wires();
    a="— mA";v="— V";
    if LD10.rt_measured then
        [u,i,ok,why]=ld10_measure_values();if ~ok then error(why);end
        a=rt10_format(i)+" mA";v=rt10_format(u)+" V";
    end
    rt10_text("reading:A",a);rt10_text("reading:V",v);
    h=student_guide_find(LD10.fig,"reading:A");
    h.tooltipstring="Vienas ampermetras matuoja srovę savo tikrajame laidų kelyje.";
    LD10.fig.immediate_drawing=drawing;
endfunction

function [handles,ids]=rt_ports_10()
    global LD10;
    handles=LD10.term.handles;ids=matrix(LD10.term.handleIds,-1,1);
endfunction
