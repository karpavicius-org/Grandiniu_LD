// RT bridge: original V2 figure, circuit renderer, contacts and device cards.
// No model, geometry, canonical wiring or calculation widget is replaced here.
function v=rt_prepare_9(root,st,cfg)
    global LD9;
    LD9=struct("root",root,"cfg",cfg,"student",st,"assessment",%t,"practice_used",%f,"autosave_enabled",%f);
    ld9_init_state();
    ld9_build_gui();
    v=struct("fig",LD9.fig,"board",LD9.ui.circuitFrame,"task",LD9.ui.right, ...
        "primary",LD9.ui.studentPrimary,"measure",LD9.ui.controls(10),"journal",LD9.ui.journalList);
endfunction

function rt_apply_9(t,phase)
    global LD9 MO;
    // The controller supplies submitted wires; this bridge never creates any.
    if isfield(MO,"pending") then LD9.pending=MO.pending;end
    LD9.demoMode=%f;
    LD9.rt_phase=phase;
    LD9.rt_measured=%f;
    if phase<>"wiring" & isfield(MO,"current") then
        if typeof(MO.current)=="st" then
            if isfield(MO.current,"values") then LD9.rt_measured=size(MO.current.values,"*")>0;end
        end
    end
    LD9.powerOn=LD9.rt_measured;LD9.switchOn=LD9.rt_measured;
    LD9.freqPoint=t.freqPoint;LD9.target=t.target;LD9.step=t.freqPoint+1;
    if phase=="wiring" then LD9.step=1;end
endfunction

function s=rt9_format(x)
    if abs(x)<.005 then x=0;end
    s=mo_display(x);
endfunction

function rt9_text(tag,text)
    global LD9;
    h=student_guide_find(LD9.fig,tag);
    if h==[] then error("Originaliame LD9 stende trūksta "+tag+".");end
    h.string=text;
endfunction

function rt_draw_9()
    global LD9;
    drawing=LD9.fig.immediate_drawing;LD9.fig.immediate_drawing="off";
    ld9_render_wires();
    a="— mA";v="— V";
    if LD9.rt_measured then
        [u,i,ok,why]=ld9_measure_values();if ~ok then error(why);end
        a=rt9_format(i)+" mA";v=rt9_format(u)+" V";
    end
    rt9_text("reading:A",a);rt9_text("reading:V",v);
    h=student_guide_find(LD9.fig,"reading:V");
    targets=["UR prie rezistoriaus";"UL prie ritės";"UC prie kondensatoriaus";"U prie generatoriaus"];
    h.tooltipstring="Voltmetro zondai: "+targets(LD9.target)+".";
    LD9.fig.immediate_drawing=drawing;
endfunction

function [handles,ids]=rt_ports_9()
    global LD9;
    handles=LD9.term.handles;ids=matrix(LD9.term.handleIds,-1,1);
endfunction
