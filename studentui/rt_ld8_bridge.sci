// RT bridge: original V2 figure, circuit renderer, contacts and device cards.
// No model, geometry, canonical wiring or calculation widget is replaced here.
function v=rt_prepare_8(root,st,cfg)
    global LD8;
    LD8=struct("root",root,"cfg",cfg,"student",st,"assessment",%t,"practice_used",%f,"autosave_enabled",%f);
    ld8_init_state();
    ld8_build_gui();
    v=struct("fig",LD8.fig,"board",LD8.ui.circuitFrame,"task",LD8.ui.right, ...
        "primary",LD8.ui.studentPrimary,"measure",LD8.ui.controls(6),"journal",LD8.ui.journalList);
endfunction

function rt_apply_8(t,phase)
    global LD8 MO;
    // The controller supplies submitted wires; this bridge never creates any.
    if isfield(MO,"pending") then LD8.pending=MO.pending;end
    LD8.demoMode=%f;
    LD8.rt_phase=phase;
    LD8.rt_measured=%f;
    if phase<>"wiring" & isfield(MO,"current") then
        if typeof(MO.current)=="st" then
            if isfield(MO.current,"values") then LD8.rt_measured=size(MO.current.values,"*")>0;end
        end
    end
    LD8.powerOn=LD8.rt_measured;LD8.switchOn=LD8.rt_measured;
    LD8.wireMode=t.mode;LD8.target=t.target;steps=[1 3 4];LD8.step=steps(t.mode);
endfunction

function s=rt8_format(x)
    if abs(x)<.005 then x=0;end
    s=mo_display(x);
endfunction

function rt8_text(tag,text)
    global LD8;
    h=student_guide_find(LD8.fig,tag);
    if h==[] then error("Originaliame LD8 stende trūksta "+tag+".");end
    h.string=text;
endfunction

function rt_draw_8()
    global LD8;
    drawing=LD8.fig.immediate_drawing;LD8.fig.immediate_drawing="off";
    ld8_render_wires();
    a="— mA";v="— V";
    if LD8.rt_measured then
        [u,i,ok,why]=ld8_measure_values();if ~ok then error(why);end
        a=rt8_format(i)+" mA";v=rt8_format(u)+" V";
    end
    rt8_text("reading:A",a);rt8_text("reading:V",v);
    LD8.fig.immediate_drawing=drawing;
endfunction

function [handles,ids]=rt_ports_8()
    global LD8;
    handles=LD8.term.handles;ids=matrix(LD8.term.handleIds,-1,1);
endfunction
