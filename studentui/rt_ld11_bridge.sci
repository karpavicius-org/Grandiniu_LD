// RT bridge: original V2 figure, circuit renderer, contacts and device cards.
// Meter leads are real canonical cables; cfg.Ck is cloned per trial in SI F.
function v=rt_prepare_11(root,st,cfg)
    global LD11;
    LD11=struct("root",root,"cfg",cfg,"student",st,"assessment",%t,"practice_used",%f,"autosave_enabled",%f);
    LD11.rt_base_cfg=cfg;
    ld11_init_state();
    ld11_build_gui();
    v=struct("fig",LD11.fig,"board",LD11.ui.circuitFrame,"task",LD11.ui.right, ...
        "primary",LD11.ui.studentPrimary,"measure",LD11.ui.controls(5),"journal",LD11.ui.journalList);
endfunction

function rt_apply_11(t,phase)
    global LD11 MO;
    // The controller supplies submitted wires; this bridge never creates any.
    if isfield(MO,"pending") then LD11.pending=MO.pending;end
    LD11.demoMode=%f;
    LD11.rt_phase=phase;
    LD11.rt_measured=%f;
    if phase<>"wiring" & isfield(MO,"current") then
        if typeof(MO.current)=="st" then
            if isfield(MO.current,"values") then LD11.rt_measured=size(MO.current.values,"*")>0;end
        end
    end
    LD11.powerOn=LD11.rt_measured;LD11.switchOn=LD11.rt_measured;
    LD11.wireMode=t.mode;
    LD11.cfg=LD11.rt_base_cfg;
    LD11.cfg.Ck=t.capacitance;
    if t.mode==1 then LD11.step=2;if phase=="wiring" then LD11.step=1;end
    else LD11.step=4;end
endfunction

function s=rt11_format(x)
    if abs(x)<.005 then x=0;end
    s=mo_display(x);
endfunction

function rt11_text(tag,text)
    global LD11;
    h=student_guide_find(LD11.fig,tag);
    if h==[] then error("Originaliame LD11 stende trūksta "+tag+".");end
    h.string=text;
endfunction

function rt_draw_11()
    global LD11;
    drawing=LD11.fig.immediate_drawing;LD11.fig.immediate_drawing="off";
    ld11_render_wires();
    a="— mA";v="— V";w="— mW";
    if LD11.rt_measured then
        [u,i,ok,why,p]=ld11_measure_values();if ~ok then error(why);end
        a=rt11_format(i)+" mA";v=rt11_format(u)+" V";w=rt11_format(p)+" mW";
    end
    rt11_text("reading:A",a);rt11_text("reading:V",v);rt11_text("reading:W",w);
    LD11.fig.immediate_drawing=drawing;
endfunction

function [handles,ids]=rt_ports_11()
    global LD11;
    handles=LD11.term.handles;ids=matrix(LD11.term.handleIds,-1,1);
endfunction
