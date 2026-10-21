// Measurement-only controller bridge to the ORIGINAL LD5 physical board.
// No model, terminal position, component position or wire route is replaced.
function v=rt_prepare_5(root,st,cfg)
    global LD5;
    LD5=struct("root",root,"cfg",cfg,"student",st);
    ld5_init_state(); LD5.autosave_enabled=%f;
    ld5_build_gui();
    v=struct("fig",LD5.fig,"board",LD5.ui.circuitFrame,"task",LD5.ui.right, ...
        "primary",LD5.ui.studentPrimary,"measure",LD5.ui.controls(6),"journal",LD5.ui.journalList);
endfunction

function rt_apply_5(t,phase)
    global LD5 MO;
    LD5.position=t.position; LD5.step=2;
    LD5.rt_trial=t; LD5.rt_phase=phase;
    LD5.demoMode=%f; LD5.pending=MO.pending;
    LD5.powerOn=%f; LD5.switchOn=%f; LD5.lastMeasurement=%nan;
    // A trial has visible readings only after its actual measurement. The
    // controller owns wires and journal; this bridge fabricates neither.
    if phase<>"wiring" & isfield(MO.current,"ids") then
        LD5.powerOn=%t; LD5.switchOn=%t;
        idx=find(MO.current.ids=="I");
        if size(idx,"*")==1 then LD5.lastMeasurement=MO.current.values(idx(1));end
    end
endfunction

function rt_draw_5()
    global LD5 MO;
    ld5_render_wires();
    texts=["— mA";"— V"];
    if LD5.rt_phase<>"wiring" & isfield(MO.current,"ids") then
        ids=["I";"U"]; units=["mA";"V"];
        for j=1:2
            idx=find(MO.current.ids==ids(j));
            if size(idx,"*")==1 then
                value=MO.current.values(idx(1));
                if abs(value)<1d-10 then value=0;end
                texts(j)=mo_display(value)+" "+units(j);
            end
        end
    end
    ids=["A";"V"];
    for j=1:2
        h=student_guide_find(LD5.fig,"reading:"+ids(j));
        if h<>[] then h.string=texts(j);end
    end
endfunction

function [handles,ids]=rt_ports_5()
    global LD5;
    handles=[];
    for k=1:length(LD5.term.handles); handles($+1)=LD5.term.handles(k);end
    ids=matrix(LD5.term.handleIds,-1,1);
endfunction
