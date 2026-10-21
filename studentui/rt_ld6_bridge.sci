// Measurement-only controller bridge to the ORIGINAL LD6 physical board.
// No model, terminal position, component position or wire route is replaced.
function v=rt_prepare_6(root,st,cfg)
    global LD6;
    LD6=struct("root",root,"cfg",cfg,"student",st);
    ld6_init_state(); LD6.autosave_enabled=%f;
    ld6_build_gui();
    v=struct("fig",LD6.fig,"board",LD6.ui.circuitFrame,"task",LD6.ui.right, ...
        "primary",LD6.ui.studentPrimary,"measure",LD6.ui.controls(7),"journal",LD6.ui.journalList);
endfunction

function rt_apply_6(t,phase)
    global LD6 MO;
    LD6.wireMode=t.mode; LD6.step=t.mode+1;
    LD6.rt_trial=t; LD6.rt_phase=phase;
    LD6.demoMode=%f; LD6.pending=MO.pending;
    LD6.powerOn=%f; LD6.switchOn=%f; LD6.lastMeasurement=%nan;
    // A trial has visible readings only after its actual measurement. The
    // controller owns wires and journal; this bridge fabricates neither.
    if phase<>"wiring" & isfield(MO.current,"ids") then
        LD6.powerOn=%t; LD6.switchOn=%t;
        idx=find(MO.current.ids=="I");
        if size(idx,"*")==1 then LD6.lastMeasurement=MO.current.values(idx(1));end
    end
endfunction

function rt_draw_6()
    global LD6 MO;
    ld6_render_wires();
    texts=["— mA";"— V"];
    if LD6.rt_phase<>"wiring" & isfield(MO.current,"ids") then
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
        h=student_guide_find(LD6.fig,"reading:"+ids(j));
        if h<>[] then h.string=texts(j);end
    end
endfunction

function [handles,ids]=rt_ports_6()
    global LD6;
    handles=[];
    for k=1:length(LD6.term.handles); handles($+1)=LD6.term.handles(k);end
    ids=matrix(LD6.term.handleIds,-1,1);
endfunction
