// RT bridge: original V2 figure, circuit renderer, contacts and device cards.
// Meter positions are real canonical cables; measurements follow the full graph.
function v=rt_prepare_12(root,st,cfg)
    global LD12;
    LD12=struct("root",root,"cfg",cfg,"student",st,"assessment",%t,"practice_used",%f,"autosave_enabled",%f);
    ld12_init_state();
    ld12_build_gui();
    v=struct("fig",LD12.fig,"board",LD12.ui.circuitFrame,"task",LD12.ui.right, ...
        "primary",LD12.ui.studentPrimary,"measure",LD12.ui.controls(8),"journal",LD12.ui.journalList);
endfunction

function rt_apply_12(t,phase)
    global LD12 MO;
    // The controller supplies submitted wires; this bridge never creates any.
    if isfield(MO,"pending") then LD12.pending=MO.pending;end
    LD12.demoMode=%f;
    LD12.rt_phase=phase;
    LD12.rt_measured=%f;
    if phase<>"wiring" & isfield(MO,"current") then
        if typeof(MO.current)=="st" then
            if isfield(MO.current,"values") then LD12.rt_measured=size(MO.current.values,"*")>0;end
        end
    end
    LD12.powerOn=LD12.rt_measured;LD12.switchOn=LD12.rt_measured;
    LD12.wireMode=t.mode;LD12.rt_measurement=t.measurement;
    LD12.phase=1; // legacy caption/control compatibility; never selects a reading
    if t.mode==1 then LD12.step=2;if phase=="wiring" then LD12.step=1;end
    else LD12.step=4;if phase=="wiring" then LD12.step=3;end;end
endfunction

function s=rt12_format(x)
    if abs(x)<.005 then x=0;end
    s=mo_display(x);
endfunction

function rt12_text(tag,text)
    global LD12;
    h=student_guide_find(LD12.fig,tag);
    if h==[] then error("Originaliame LD12 stende trūksta "+tag+".");end
    h.string=text;
endfunction

function rt_draw_12()
    global LD12;
    drawing=LD12.fig.immediate_drawing;LD12.fig.immediate_drawing="off";
    ld12_render_wires();
    a="— mA";v="— V";
    if LD12.rt_measured then
        [u,i,ok,why]=ld12_measure_values();if ~ok then error(why);end
        a=rt12_format(i)+" mA";v=rt12_format(u)+" V";
    end
    rt12_text("reading:A",a);rt12_text("reading:V",v);
    LD12.fig.immediate_drawing=drawing;
endfunction

function [handles,ids]=rt_ports_12()
    global LD12;
    handles=LD12.term.handles;ids=matrix(LD12.term.handleIds,-1,1);
endfunction
