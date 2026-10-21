// LD2 measurement-transcription adapter for the ORIGINAL native circuit board.
// Circuit drawing, component identities, lead geometry and wire routes stay in
// ld2_render_stand / ld2_draw_phase_stand. No replacement board is created.
function v=rt_prepare_2(root,st,cfg)
    global LD2;
    LD2=struct("root",root+"LD2/","cfg",cfg,"state",ld2_initial_state(cfg), ...
        "ui",struct("headless",%f,"suppress_render",%f), ...
        "example_active",%f,"example_backup",struct(),"rt_mode",%t, ...
        "rt_requested_ids",emptystr(0,1),"rt_phase","wiring");
    LD2.state.student=st; LD2.state.assessment=%t;
    ld2_build_gui();
    // These are the original primary and original physical experiment controls.
    // Their callbacks/labels are attached to the common RT controller afterwards.
    LD2.state.step=4;
    ld2_render_action_row(); ld2_render_controls();
    measure=[];
    for h=matrix(LD2.ui.stand.children,1,-1)
        if h.type=="uicontrol" then
            if h.tag=="LD2_RUN" then measure=h; end
        end
    end
    if measure==[] then error("LD2: originalus matavimo mygtukas nerastas."); end
    LD2.ui.rtMeasure=measure;
    LD2.ui.dynamic=[];
    // LD2 has no always-visible original journal control; do not fabricate one.
    v=struct("fig",LD2.ui.figure,"board",LD2.ui.stand,"task",LD2.ui.right, ...
        "primary",LD2.ui.studentPrimary,"measure",measure,"journal",[]);
endfunction

function rt_apply_2(t,phase)
    global LD2 MO;
    LD2.rt_mode=%t; LD2.rt_phase=phase;
    LD2.rt_requested_ids=unique(matrix(t.wires,-1,1));
    select t.phase
    case "RC" then LD2.state.step=4;
    case "RL" then LD2.state.step=7;
    case "RLC" then LD2.state.step=9;
    else error("LD2: nežinoma originalaus stendo grandinė.");
    end
    LD2.state.freq=t.frequency;
    // Copy the student's actual graph, including both voltmeter probes.
    // No canonical graph is inserted by this adapter.
    LD2.wires=MO.wires;
    LD2.state(convstr(t.phase,"l")+"_connections")=MO.wires;
    LD2.state.selected_terminal=MO.pending;
    LD2.state.power=phase<>"wiring";
    LD2.state.amp_live=%nan; LD2.state.volt_live=%nan;
    LD2.state.volt_live_target="";
    if phase<>"wiring" & typeof(MO.current)=="st" then
        if isfield(MO.current,"values") & isfield(MO.current,"units") then
            for k=1:size(MO.current.values,"*")
                if MO.current.units(k)=="mA" then
                    LD2.state.amp_live=MO.current.values(k)/1000;
                elseif MO.current.units(k)=="V" then
                    LD2.state.volt_live=MO.current.values(k);
                    LD2.state.volt_live_target=t.target;
                end
            end
        end
    end
endfunction

function rt_draw_2()
    global LD2;
    // Board redraw owns only original stand descendants. The original primary
    // and the common task-card controls in ui.right remain untouched.
    for h=matrix(LD2.ui.stand.children,1,-1)
        if h<>LD2.ui.rtMeasure then delete(h); end
    end
    LD2.ui.dynamic=[];
    ld2_render_stand();
    for h=matrix(LD2.ui.stand.children,1,-1)
        if h.type=="uicontrol" then
            if h.style=="text" & size(h.position,"*")==4 then
                // The old subtitle described a different automatic procedure;
                // keep its existing place and typography, with current context.
                if abs(h.position(2)-0.79)<1d-8 then
                    text="Sujunkite parodytus grandinės ir voltmetro zondų kabelius.";
                    if LD2.rt_phase<>"wiring" then text="Prietaisų rodmenis perrašykite dešinėje."; end
                    h.string=student_wrap(text,72);
                end
            end
        end
    end
endfunction

function [handles,ids]=rt_ports_2()
    global LD2;
    handles=[]; ids=emptystr(0,1);
    allids=ld2_terminal_ids();
    for id=matrix(allids,1,-1)
        code=ld2_terminal_code(id);
        for h=matrix(LD2.ui.stand.children,1,-1)
            if h.type=="uicontrol" then
                if h.style=="pushbutton" & h.tag==code & h.visible=="on" then
                    handles($+1)=h; ids($+1,1)=id;
                end
            end
        end
    end
endfunction

// The original LD2 board normally exposes probe sockets only after its old
// automatic experiment. In RT these same physical sockets are manual targets.
// Outside RT the original active-terminal policy is retained verbatim.
function active=ld2_active_terminals(step)
    global LD2;
    if isfield(LD2,"rt_mode") then
        if LD2.rt_mode then active=LD2.rt_requested_ids; return; end
    end
    active=emptystr(0,1);
    if or(step==[2 5 8]) then
        req=ld2_required_main(ld2_phase_for_step(step)); active=matrix(req,-1,1);
    end
endfunction

// Narrow presentation adaptation: actual instrument values already supplied by
// MO.current use the same two-decimal format as the transcription task.
function txt=ld2_amp_display_text()
    global LD2;
    phase=ld2_phase_for_step(LD2.state.step);
    [ok,missing]=ld2_validate_main(phase);
    if ~ok | ~LD2.state.power | isnan(LD2.state.amp_live) then txt="— mA"; return; end
    if isfield(LD2,"rt_mode") then
        if LD2.rt_mode then txt=mo_display(LD2.state.amp_live*1000)+" mA"; return; end
    end
    txt=ld2_num(LD2.state.amp_live*1000,3)+" mA";
endfunction

function txt=ld2_volt_display_text()
    global LD2;
    phase=ld2_phase_for_step(LD2.state.step);
    target=ld2_detect_voltage_target(phase);
    if target=="" | ~LD2.state.power then txt="— V"; return; end
    x=LD2.state.volt_live;
    if LD2.state.volt_live_target<>target then x=%nan; end
    if isnan(x) then txt="— V"; return; end
    if isfield(LD2,"rt_mode") then
        if LD2.rt_mode then txt=mo_display(x)+" V"; return; end
    end
    txt=ld2_num(x,3)+" V";
endfunction
