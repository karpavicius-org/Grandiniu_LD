// LD1 adapter: retain the original V2 circuit frame, components and wires.
// The RT controller owns the task card and student actions; this file only
// prepares the existing stand and displays an already measured instrument value.
function v=rt_prepare_1(root,st,cfg)
    global LD1;
    LD1=struct("base",root+"LD1/","cfg",cfg,"student",st, ...
        "assessment",%t,"guided",%f,"practice_used",%f, ...
        "automatic_numbers",%f,"measurement_workflow",%t,"rt_mode",%t, ...
        "rt_geometry_key","","rt_layout_dirty",%t,"rt_port_ids",emptystr(0,1), ...
        "rt_geometry_builds",0,"rt_full_renders",0,"rt_wire_renders",0);
    ld1_init_state();
    ld1_init_terminals();
    ld1_create_gui();
    v=struct("fig",LD1.fig,"board",LD1.ui.circuitFrame, ...
        "task",LD1.ui.ctrlFrame,"primary",LD1.ui.checkStep, ...
        "measure",LD1.ui.measure,"journal",[]);
endfunction

function rt_apply_1(t,phase)
    global LD1 MO;
    LD1.step=1;
    if t.panel=="parallel" then
        LD1.step=5;
        if t.meter=="A" then LD1.step=8; end
    end
    LD1.panel=t.panel;
    LD1.VR1=t.resistance;
    LD1.meterMode=t.meter;
    LD1.realistic=%f;
    LD1.powerOn=or(phase==["copy" "between" "complete"]);
    LD1.demoMode=%f; LD1.guided=%f; LD1.wiring_help=%f;
    LD1.lastMeasurement=%nan; LD1.lastMeasurementUnit="";
    LD1.lastMeasurementStep=0;
    if LD1.powerOn & typeof(MO.current)=="st" then
        if isfield(MO.current,"values") & isfield(MO.current,"units") then
            if size(MO.current.values,"*")==1 then
                LD1.lastMeasurement=MO.current.values(1);
                LD1.lastMeasurementUnit=MO.current.units(1);
                LD1.lastMeasurementStep=LD1.step;
            end
        end
    end
    ld1_update_actual_values();
    LD1.wires=MO.wires;
    LD1.pendingTerminal=MO.pending;
    LD1.rt_port_ids=unique(matrix(t.wires,-1,1));
    geometry=t.panel+":"+t.meter+":"+string(LD1.step);
    if geometry<>LD1.rt_geometry_key then
        // Exact original panel coordinates, without the old clear-and-draw.
        ld1_configure_panel_geometry(t.panel);
        LD1.rt_geometry_key=geometry;LD1.rt_layout_dirty=%t;
        LD1.rt_geometry_builds=LD1.rt_geometry_builds+1;
    end
endfunction

function rt_draw_1()
    global LD1;
    if LD1.rt_layout_dirty then
        // The full original board is created once for this geometry.
        ld1_redraw_panel_classic();
        LD1.rt_layout_dirty=%f;LD1.rt_full_renders=LD1.rt_full_renders+1;
        ld1_ui_font(LD1.ui.circuitFrame);
    elseif ~mo_wires_equal(LD1.wires,LD1.rt_drawn_wires) then
        ld1_rt_refresh_wires();
    end
    // Keep instrument faces and handles; change only their actual text.
    source="0 V DC";sourceState="Išjungta";
    if LD1.powerOn then source=string(LD1.cfg.E)+" V DC";sourceState="Įjungta";end
    ld1_rt_set_text(LD1.ui.sourceDisplay,source);
    ld1_rt_set_text(LD1.ui.sourceState,sourceState);
    ld1_rt_set_text(LD1.ui.vrText,string(LD1.VR1)+" Ω");
    name="AMPERMETRAS";if LD1.meterMode=="V" then name="VOLTMETRAS";end
    ld1_rt_set_text(LD1.ui.meterName,name);
    if isnan(LD1.lastMeasurement) then
        ld1_rt_set_text(LD1.ui.meterDisplay,"— "+LD1.meterMode);
        ld1_rt_set_text(LD1.ui.meterState,"Dar nematuota");
    else
        value=LD1.lastMeasurement;
        if abs(value)<0.005 then value=0; end
        ld1_rt_set_text(LD1.ui.meterDisplay,mo_display(value)+" "+LD1.lastMeasurementUnit);
        ld1_rt_set_text(LD1.ui.meterState,"Išmatuota");
    end
    for k=1:size(LD1.term.handleIds,"*")
        h=LD1.term.handles(k);id=LD1.term.handleIds(k);
        bg=[0.08 0.39 0.37];fg=[1 1 1];
        if or(matrix(LD1.wires,-1,1)==id) then bg=[0.14 0.54 0.34];end
        if LD1.pendingTerminal==id then bg=[0.08 0.40 0.70];end
        if ~and(h.backgroundcolor==bg) then h.backgroundcolor=bg;end
        if ~and(h.foregroundcolor==fg) then h.foregroundcolor=fg;end
        h.tooltipstring=ld1_terminal_name(id);
    end
endfunction

function ld1_rt_set_text(h,text)
    if ~isequal(h.string,text) then h.string=text;end
endfunction

function ld1_rt_refresh_wires()
    global LD1;
    if isfield(LD1.ui,"rtWireHandles") then
        for h=matrix(LD1.ui.rtWireHandles,1,-1)
            if is_handle_valid(h) then delete(h);end
        end
    end
    // Use only actual current-trial sockets for clipping. Hidden legacy sockets
    // must not leave unexplained gaps in an otherwise continuous cable.
    data=LD1.ui.circuitFrame.user_data;data.ports=[];
    for id=matrix(LD1.rt_port_ids,1,-1)
        data.ports($+1,:)=[ld1_get_xy(id)/100 36 40];
    end
    LD1.ui.circuitFrame.user_data=data;student_begin_wires(LD1.ui.circuitFrame);
    data=LD1.ui.circuitFrame.user_data;data.segments=LD1.ui.rtStaticSegments;
    LD1.ui.circuitFrame.user_data=data;LD1.ui.rtRoutes=list();
    for k=1:size(LD1.wires,1)
        a=LD1.wires(k,1);b=LD1.wires(k,2);
        points=ld1_rt_wire_path(a,b);
        col=[0.22 0.40 0.42];
        if LD1.panel=="parallel" & LD1.meterMode=="A" then
            if or([a b]=="M_P") then col=[0.14 0.35 0.65];end
            if or([a b]=="M_N") then col=[0.65 0.27 0.16];end
        end
        LD1.ui.rtRoutes($+1)=struct("pair",[a b],"points",points,"color",col);
        for j=1:size(points,1)-1
            ld1_board_segment(points(j,1),points(j,2),points(j+1,1),points(j+1,2),col);
        end
    end
    LD1.ui.rtWireHandles=student_end_wires(LD1.ui.circuitFrame);
    LD1.rt_drawn_wires=LD1.wires;LD1.rt_wire_renders=LD1.rt_wire_renders+1;
endfunction

function points=ld1_rt_wire_path(a,b)
    global LD1;
    p=ld1_get_xy(a)/100;q=ld1_get_xy(b)/100;
    points=[p;[(p(1)+q(1))/2 p(2)];[(p(1)+q(1))/2 q(2)];q];
    if LD1.panel<>"parallel" | LD1.meterMode<>"A" then return;end
    // The two branch-meter leads used to share the exact same vertical line.
    // Keep every original socket in place and give each complete cable its
    // own upper corridor. Real bus crossings retain the stock clear overpass.
    first="";last="";channel=0;
    if or([a b]=="NODE_A2") & or([a b]=="M_P") then first="NODE_A2";last="M_P";channel=0.36;
    elseif or([a b]=="NODE_A3") & or([a b]=="M_P") then first="NODE_A3";last="M_P";channel=0.38;
    elseif or([a b]=="M_N") & or([a b]=="R3_1") then first="M_N";last="R3_1";channel=0.60;
    elseif or([a b]=="M_N") & or([a b]=="R2_1") then first="M_N";last="R2_1";channel=0.865;
    end
    if first=="" then return;end
    start=ld1_get_xy(first)/100;finish=ld1_get_xy(last)/100;
    if last=="M_P" then
        points=[start;start(1) 0.885;channel 0.885;channel finish(2);finish];
    else
        points=[start;start(1) 0.90;channel 0.90;channel finish(2);finish];
    end
    if a<>first then points=points($:-1:1,:);end
endfunction

function [handles,ids]=rt_ports_1()
    global LD1;
    handles=LD1.term.handles;
    ids=matrix(LD1.term.handleIds,-1,1);
endfunction
