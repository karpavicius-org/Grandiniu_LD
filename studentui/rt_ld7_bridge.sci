// RT bridge: original V2 figure, circuit renderer, contacts and device cards.
// No model, geometry, canonical wiring or calculation widget is replaced here.
function v=rt_prepare_7(root,st,cfg)
    global LD7;
    LD7=struct("root",root,"cfg",cfg,"student",st,"assessment",%t,"practice_used",%f,"autosave_enabled",%f);
    ld7_init_state();
    ld7_build_gui();
    v=struct("fig",LD7.fig,"board",LD7.ui.circuitFrame,"task",LD7.ui.right, ...
        "primary",LD7.ui.studentPrimary,"measure",LD7.ui.controls(11),"journal",LD7.ui.journalList);
endfunction

function rt_apply_7(t,phase)
    global LD7 MO;
    // The controller supplies submitted wires; this bridge never creates any.
    if isfield(MO,"pending") then LD7.pending=MO.pending;end
    LD7.demoMode=%f;
    LD7.rt_phase=phase;
    LD7.rt_measured=%f;
    if phase<>"wiring" & isfield(MO,"current") then
        if typeof(MO.current)=="st" then
            if isfield(MO.current,"values") then LD7.rt_measured=size(MO.current.values,"*")>0;end
        end
    end
    LD7.powerOn=LD7.rt_measured;LD7.switchOn=LD7.rt_measured;
    LD7.wireMode=t.mode;LD7.position=t.position;
    if t.mode==1 then
        LD7.step=2;if phase=="wiring" then LD7.step=1;end
    else LD7.step=5;end
endfunction

function s=rt7_format(x)
    if abs(x)<.005 then x=0;end
    s=mo_display(x);
endfunction

function rt7_text(tag,text)
    global LD7;
    h=student_guide_find(LD7.fig,tag);
    if h==[] then error("Originaliame LD7 stende trūksta "+tag+".");end
    h.string=text;
endfunction

function rt_draw_7()
    global LD7;
    drawing=LD7.fig.immediate_drawing;LD7.fig.immediate_drawing="off";
    ld7_render_wires();
    a="— mA";v="— V";
    if LD7.rt_measured then
        [u,i,ok,why,load]=ld7_measure_values();if ~ok then error(why);end
        if LD7.wireMode<>2 then a=rt7_format(i)+" mA";end
        if LD7.wireMode<>3 then v=rt7_format(u)+" V";end
    end
    rt7_text("reading:A",a);rt7_text("reading:V",v);
    // R is an automatically selected setting, not an unmade measurement.
    if LD7.wireMode==1 then
        rt7_text("reading:R","<html><center>P"+string(LD7.position)+"<br>"+mo_num(LD7.cfg("R"+string(LD7.position)))+" Ω</center></html>");
    end
    LD7.fig.immediate_drawing=drawing;
endfunction

function [handles,ids]=rt_ports_7()
    global LD7;
    handles=LD7.term.handles;ids=matrix(LD7.term.handleIds,-1,1);
endfunction
