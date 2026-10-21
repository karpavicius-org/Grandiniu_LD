// Measurement-only controller bridge to the ORIGINAL LD4 physical board.
// No model, terminal position, component position or wire route is replaced.
function v=rt_prepare_4(root,st,cfg)
    global LD4;
    LD4=struct("root",root,"cfg",cfg,"student",st);
    ld4_init_state(); LD4.autosave_enabled=%f;
    ld4_build_gui();
    v=struct("fig",LD4.fig,"board",LD4.ui.circuitFrame,"task",LD4.ui.right, ...
        "primary",LD4.ui.studentPrimary,"measure",LD4.ui.controls(7),"journal",LD4.ui.journalList);
endfunction

function rt_apply_4(t,phase)
    global LD4 MO;
    LD4.voltage=t.voltage; LD4.wireMode=t.mode; LD4.step=t.model_step;
    LD4.rt_trial=t; LD4.rt_phase=phase;
    LD4.demoMode=%f; LD4.pending=MO.pending;
    LD4.powerOn=%f; LD4.switchOn=%f; LD4.lastMeasurement=%nan;
    // A trial has visible readings only after its actual measurement. The
    // controller owns wires and journal; this bridge fabricates neither.
    if phase<>"wiring" & isfield(MO.current,"ids") then
        LD4.powerOn=%t; LD4.switchOn=%t;
        idx=find(MO.current.ids=="I");
        if size(idx,"*")==1 then LD4.lastMeasurement=MO.current.values(idx(1));end
    end
endfunction

function rt_draw_4()
    global LD4 MO;
    ld4_render_wires();
    texts=["— mA";"— V"];
    if LD4.rt_phase<>"wiring" & isfield(MO.current,"ids") then
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
        h=student_guide_find(LD4.fig,"reading:"+ids(j));
        if h<>[] then h.string=texts(j);end
    end
endfunction

function [handles,ids]=rt_ports_4()
    global LD4;
    handles=[];
    for k=1:length(LD4.term.handles); handles($+1)=LD4.term.handles(k);end
    ids=matrix(LD4.term.handleIds,-1,1);
endfunction
