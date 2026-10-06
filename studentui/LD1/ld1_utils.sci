function v = ld1_parse_number(s)
    v=bench_safe_number(s);
endfunction

function tf = ld1_close_enough(userValue, expectedValue)
    global LD1;
    if isnan(userValue) | isnan(expectedValue) then
        tf = %f;
        return;
    end
    scale = max([abs(expectedValue), 1e-9]);
    tf = abs(userValue - expectedValue) <= LD1.cfg.answer_tolerance * scale;
endfunction

function s = ld1_num(v, digits)
    if argn(2) < 2 then digits = 3; end
    if isnan(v) then
        s = "—";
        return;
    end
    fmt = "%0." + string(digits) + "f";
    s = msprintf(fmt, v);
endfunction

function ld1_set_status(msg, kind, fix)
    // Dviejų eilučių būsenos juosta: kas negerai + kaip tiksliai pataisyti.
    global LD1;
    if argn(2) < 2 then kind = "info"; end
    if argn(2) < 3 then fix = ""; end
    if ~isfield(LD1, "ui") then return; end
    if ~isfield(LD1.ui, "statusMain") then return; end

    LD1.ui.statusMain.string = msg;
    LD1.ui.statusFix.string = fix;

    select kind
    case "ok" then
        bg=[0.86 0.95 0.86]; fg=[0.05 0.35 0.08];
    case "warn" then
        bg=[1.00 0.95 0.78]; fg=[0.45 0.25 0.00];
    case "error" then
        bg=[1.00 0.87 0.87]; fg=[0.55 0.05 0.05];
    else
        bg=[0.90 0.93 0.97]; fg=[0.10 0.18 0.28];
    end

    LD1.ui.statusFrame.backgroundcolor=bg;
    LD1.ui.statusMain.backgroundcolor=bg;
    LD1.ui.statusFix.backgroundcolor=bg;
    LD1.ui.statusMain.foregroundcolor=fg;
    LD1.ui.statusFix.foregroundcolor=fg;
    if exists("ld1_student_sync")==1 then ld1_student_sync(); end
endfunction

function ld1_show(h, tf)
    if tf then h.visible = "on"; else h.visible = "off"; end
endfunction

function ld1_enable(h, tf)
    if ~is_handle_valid(h) then return; end
    if tf then h.enable = "on"; else h.enable = "off"; end
endfunction

function i = ld1_term_index(id)
    global LD1;
    i = find(LD1.term.ids == id);
    if isempty(i) then i = 0; else i = i(1); end
endfunction

function xy = ld1_get_xy(id)
    global LD1;
    i = ld1_term_index(id);
    if i == 0 then
        xy = [%nan %nan];
    else
        xy = LD1.term.xy(i,:);
    end
endfunction

function tf = ld1_is_active_term(id)
    global LD1;
    tf = or(LD1.term.active == id);
endfunction

function tf = ld1_wire_exists(a, b)
    global LD1;
    tf = %f;
    if size(LD1.wires, 1) == 0 then return; end
    for k = 1:size(LD1.wires,1)
        if (LD1.wires(k,1) == a & LD1.wires(k,2) == b) | ..
           (LD1.wires(k,1) == b & LD1.wires(k,2) == a) then
            tf = %t;
            return;
        end
    end
endfunction

function n = ld1_terminal_wire_count(id)
    global LD1;
    n=0;
    if size(LD1.wires,1)==0 then return; end
    for k=1:size(LD1.wires,1)
        if LD1.wires(k,1)==id | LD1.wires(k,2)==id then n=n+1; end
    end
endfunction

function ld1_remove_wire(a, b)
    global LD1;
    if size(LD1.wires,1) == 0 then return; end
    keep = [];
    for k = 1:size(LD1.wires,1)
        same = (LD1.wires(k,1) == a & LD1.wires(k,2) == b) | ..
               (LD1.wires(k,1) == b & LD1.wires(k,2) == a);
        if ~same then keep($+1) = k; end
    end
    if isempty(keep) then
        LD1.wires = emptystr(0,2);
    else
        LD1.wires = LD1.wires(keep,:);
    end
endfunction

function ld1_add_wire(a, b)
    global LD1;
    if a == b then return; end
    if ld1_wire_exists(a,b) then
        ld1_remove_wire(a,b);
    else
        if size(LD1.wires,1) == 0 then
            LD1.wires = [a b];
        else
            LD1.wires($+1,:) = [a b];
        end
    end
endfunction

function p = ld1_find_root(parent, i)
    p = i;
    while parent(p) <> p
        p = parent(p);
    end
endfunction

function parent = ld1_union(parent, a, b)
    ra = ld1_find_root(parent, a);
    rb = ld1_find_root(parent, b);
    if ra <> rb then parent(rb) = ra; end
endfunction

function [parent, roots] = ld1_wire_roots()
    global LD1;
    n = size(LD1.term.ids, "*");
    parent = 1:n;

    if isfield(LD1,"panel") & LD1.panel=="parallel" then
        a1=ld1_term_index("NODE_A1"); a2=ld1_term_index("NODE_A2");
        a3=ld1_term_index("NODE_A3"); a4=ld1_term_index("NODE_A4");
        b1=ld1_term_index("NODE_B1"); b2=ld1_term_index("NODE_B2");
        b3=ld1_term_index("NODE_B3"); b4=ld1_term_index("NODE_B4");
        if a1>0 & a2>0 then parent=ld1_union(parent,a1,a2); end
        if a1>0 & a3>0 then parent=ld1_union(parent,a1,a3); end
        if a1>0 & a4>0 then parent=ld1_union(parent,a1,a4); end
        if b1>0 & b2>0 then parent=ld1_union(parent,b1,b2); end
        if b1>0 & b3>0 then parent=ld1_union(parent,b1,b3); end
        if b1>0 & b4>0 then parent=ld1_union(parent,b1,b4); end
    end

    if size(LD1.wires,1) > 0 then
        for k = 1:size(LD1.wires,1)
            ia = ld1_term_index(LD1.wires(k,1));
            ib = ld1_term_index(LD1.wires(k,2));
            if ia > 0 & ib > 0 then parent = ld1_union(parent, ia, ib); end
        end
    end
    roots = zeros(1,n);
    for i = 1:n
        roots(i) = ld1_find_root(parent, i);
    end
endfunction

function same = ld1_same_node(id1, id2, roots)
    i1 = ld1_term_index(id1);
    i2 = ld1_term_index(id2);
    same = (i1 > 0 & i2 > 0 & roots(i1) == roots(i2));
endfunction

function setv = ld1_endpoint_root_set(id1, id2, roots)
    i1 = ld1_term_index(id1);
    i2 = ld1_term_index(id2);
    setv = [roots(i1) roots(i2)];
endfunction

function tf = ld1_unordered_pair_equal(a, b)
    tf = ((a(1)==b(1) & a(2)==b(2)) | (a(1)==b(2) & a(2)==b(1)));
endfunction

function e = ld1_random_relative(maxAbs)
    // Vienas santykinis atsitiktinis nuokrypis [-maxAbs; +maxAbs].
    e = grand(1,1,"unf",-maxAbs,maxAbs);
endfunction
