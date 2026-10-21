// Measurement-only controller bridge to the ORIGINAL LD3 physical board.
// No model, terminal position, component position or wire route is replaced.
function v=rt_prepare_3(root,st,cfg)
    global LD3;
    LD3=struct("root",root,"cfg",cfg,"student",st);
    ld3_init_state(); LD3.autosave_enabled=%f;
    ld3_build_gui();
    v=struct("fig",LD3.fig,"board",LD3.ui.circuitFrame,"task",LD3.ui.right, ...
        "primary",LD3.ui.studentPrimary,"measure",LD3.ui.controls(6),"journal",LD3.ui.journalList);
endfunction

function rt_apply_3(t,phase)
    global LD3 MO;
    LD3.voltage=t.voltage; LD3.step=1;
    LD3.rt_trial=t; LD3.rt_phase=phase;
    LD3.demoMode=%f; LD3.pending=MO.pending;
    LD3.powerOn=%f; LD3.switchOn=%f; LD3.lastMeasurement=%nan;
    // A trial has visible readings only after its actual measurement. The
    // controller owns wires and journal; this bridge fabricates neither.
    if phase<>"wiring" & isfield(MO.current,"ids") then
        LD3.powerOn=%t; LD3.switchOn=%t;
        idx=find(MO.current.ids=="I");
        if size(idx,"*")==1 then LD3.lastMeasurement=MO.current.values(idx(1));end
    end
endfunction

function rt_draw_3()
    global LD3 MO;
    ld3_render_wires();
    // LD3 originally did not tag the lower value labels; tag those same
    // existing labels rather than creating or moving any device.
    for id=["A" "V"]
        frame=student_guide_find(LD3.fig,"component:"+id);
        if frame<>[] then
            for child=matrix(frame.children,1,-1)
                if child.type=="uicontrol" then
                    if child.style=="text" & child.position(2)<0.4 then child.tag="reading:"+id;end
                end
            end
        end
    end
    if isfield(LD3.ui,"trialProgress") then
        LD3.ui.trialProgress.string=student_wrap(LD3.rt_trial.title+" · "+LD3.rt_trial.condition,100);
    end
    texts=["— mA";"— V"];
    if LD3.rt_phase<>"wiring" & isfield(MO.current,"ids") then
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
        h=student_guide_find(LD3.fig,"reading:"+ids(j));
        if h<>[] then h.string=texts(j);end
    end
endfunction

function [handles,ids]=rt_ports_3()
    global LD3;
    handles=[];
    for k=1:length(LD3.term.handles); handles($+1)=LD3.term.handles(k);end
    ids=matrix(LD3.term.handleIds,-1,1);
endfunction
