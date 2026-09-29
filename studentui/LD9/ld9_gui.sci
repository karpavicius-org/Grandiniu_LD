// Shared Scilab UI; numerical calculation and grading remain in the C++ core.
function h = ld9_button(p, pos, label, cb, fs, bg)
    if argn(2) < 5 then fs = 13; end
    if argn(2) < 6 then bg = [0.94 0.96 0.96]; end
    code = ""; hint = "";
    try
        [code, registered, hint] = ld9_button_info(cb);
    catch
        code = "";
    end
    if code <> "" then label = "[" + code + "] " + label; end
    h = student_button(p, pos, "<html><center>" + label + "</center></html>", cb);
    h.tag = code; h.tooltipstring = hint; h.fontsize = fs; h.backgroundcolor = bg;
    if sum(bg) < 1.5 then h.foregroundcolor = [1 1 1]; end
endfunction

function [term_xy, boxes] = ld9_layout()
    // All terminals sit outside their own component, with 36 x 40 px targets.
    // Planas (iš apačios): dažnio ir taikinio eilutės 2–18 %, GEN/K/A eilutė
    // 22–35 %, V kairėje 40–56 %, R-L-C stovas dešinėje 40–80 %, žurnalas 80–98 %.
    // Koridoriai: 20 % (grąžinimas), 37,5 % (prie R), 53 % ir 67 % (tarp pakopų).
    boxes = struct("GEN", [7 22 15 13], "K", [38.5 22 12 13], "A", [66 22 14 13], ...
        "R", [75 40 16 12], "L", [75 54 16 12], "C", [75 68 16 12], "V", [6 40 21 16]);
    term_xy = struct("GEN_N", [4.5 28.5], "GEN_P", [24.5 28.5], "K1", [35.5 28.5], ...
        "K2", [53.5 28.5], "A_P", [63.5 28.5], "A_N", [83 28.5], ...
        "R_A", [72.5 46], "R_B", [93.5 46], "L_A", [72.5 60], "L_B", [93.5 60], ...
        "C_A", [72.5 74], "C_B", [93.5 74]);
endfunction

function xy = ld9_terminal_xy(id)
    [tt, bb] = ld9_layout(); xy = tt(id)/100;
endfunction

function txt = ld9_terminal_button_text(id)
    select id
    case "GEN_P" then txt = "+"; case "GEN_N" then txt = "−";
    case "K1" then txt = "1"; case "K2" then txt = "2";
    case "A_P" then txt = "+"; case "A_N" then txt = "−";
    case "R_A" then txt = "a"; case "R_B" then txt = "b";
    case "L_A" then txt = "1"; case "L_B" then txt = "2";
    case "C_A" then txt = "1"; case "C_B" then txt = "2";
    end
endfunction

function ld9_track_board(h)
    global LD9;
    if h <> [] then
        for item = matrix(h, 1, -1); LD9.ui.boardHandles($+1) = item; end
    end
endfunction

function ld9_clear_board()
    global LD9;
    for k = 1:length(LD9.ui.boardHandles)
        h = LD9.ui.boardHandles(k);
        if is_handle_valid(h) then delete(h); end
    end
    LD9.ui.boardHandles = list(); LD9.term.handles = list(); LD9.term.handleIds = emptystr(0, 1);
    LD9.ui.dynamic = LD9.ui.controls;
endfunction

function ld9_polyline(points, col)
    global LD9;
    for k = 1:size(points, 1)-1
        ld9_track_board(student_wire(LD9.ui.circuitFrame, points(k,:), points(k+1,:), col));
    end
endfunction

function route = ld9_route(a, b)
    // Kanoniniai maršrutai nepriklausomai nuo paspaudimo eilės (absoliučiai taškai).
    route = [];
    if (a == "A_N" & b == "R_A") | (a == "R_A" & b == "A_N") then
        route = [[.83 .285];[.83 .375];[.725 .375];[.725 .46]];
    elseif (a == "R_B" & b == "L_A") | (a == "L_A" & b == "R_B") then
        route = [[.935 .46];[.935 .53];[.725 .53];[.725 .60]];
    elseif (a == "L_B" & b == "C_A") | (a == "C_A" & b == "L_B") then
        route = [[.935 .60];[.935 .67];[.725 .67];[.725 .74]];
    elseif (a == "C_B" & b == "GEN_N") | (a == "GEN_N" & b == "C_B") then
        route = [[.935 .74];[.98 .74];[.98 .20];[.045 .20];[.045 .285]];
    end
endfunction

function ld9_render_wires()
    global LD9;
    if ~isfield(LD9, "ui") then return; end
    if isfield(LD9.ui, "headless") then if LD9.ui.headless then return; end; end
    if ~isfield(LD9.ui, "circuitFrame") then return; end
    if ~is_handle_valid(LD9.ui.circuitFrame) then return; end
    drawing = LD9.fig.immediate_drawing; LD9.fig.immediate_drawing = "off";
    ld9_clear_board(); p = LD9.ui.circuitFrame;
    ports = [];
    for id = matrix(ld9_terminal_ids(), 1, -1); ports($+1,:) = [ld9_terminal_xy(id) 36 40]; end
    p.user_data = struct("ports", ports);
    student_begin_wires(p);
    for k = 1:size(LD9.wires, 1)
        a = LD9.wires(k,1); b = LD9.wires(k,2);
        p1 = ld9_terminal_xy(a); p2 = ld9_terminal_xy(b);
        pts = ld9_route(a, b);
        if pts == [] then
            if abs(p1(1)-p2(1)) < 1e-9 | abs(p1(2)-p2(2)) < 1e-9 then pts = [p1; p2];
            else
                xm = (p1(1)+p2(1))/2; pts = [p1; xm p1(2); xm p2(2); p2];
            end
        end
        ld9_polyline(pts, [0.22 0.40 0.42]);
    end
    [tt, bb] = ld9_layout(); ids = ["GEN" "K" "A" "R" "L" "C" "V"];
    names = ["GEN ~";"JUNGIKLIS";"AMPERMETRAS";"R";"L";"C";"VOLTMETRAS"];
    switchText = "Atviras"; if LD9.switchOn then switchText = "Uždarytas"; end
    [u, i, valid, reason] = ld9_measure_values();
    freqText = "f = ?";
    if LD9.freqPoint > 0 then freqText = msprintf("f = %g Hz", ld9_current_frequency()); end
    voltText = "— V";
    if valid then voltText = msprintf("%.4f V", u); end
    ampText = "— mA";
    if valid then ampText = msprintf("%.3f mA", i); end
    vals = [msprintf("5 V ~ · %s", freqText), switchText, ampText, ...
        msprintf("%g Ω", LD9.cfg.R), msprintf("%g mH", LD9.cfg.LmH), msprintf("%g nF", LD9.cfg.CnF), voltText];
    pairs = ["GEN_N" "GEN_P";"K1" "K2";"A_P" "A_N";"R_A" "R_B";"L_A" "L_B";"C_A" "C_B";"" ""];
    for k = 1:7
        r = bb(ids(k))/100; bg = [0.94 0.97 0.97];
        if ids(k) == "R" then bg = [0.98 0.96 0.88]; end
        if ids(k) == "A" | ids(k) == "V" then bg = [0.95 0.97 0.99]; end
        if k < 7 then
            for j = 1:2
                xy = tt(pairs(k,j))/100; edge = [r(1) xy(2)]; if xy(1) > r(1)+r(3)/2 then edge(1) = r(1)+r(3); end
                ld9_track_board(student_wire(p, xy, edge, [0.41 0.49 0.51], "lead:" + ids(k)));
            end
        end
        fr = student_frame(p, r, bg); fr.tag = "component:" + ids(k); ld9_track_board(fr);
        h = student_text(fr, [0.06 0.66 0.88 0.24], names(k), 12, %t, bg); h.horizontalalignment = "center";
        h = student_text(fr, [0.04 0.04 0.92 0.58], vals(k), 13, %t, bg); h.horizontalalignment = "center";
        h.tag = "reading:" + ids(k);
        if k == 7 then h.tooltipstring = "Vienas voltmetras: taikinys renkamas mygtukais [B13]–[B16]."; end
        if k == 5 then h.tooltipstring = msprintf("Rišlė: L = %g mH.", LD9.cfg.LmH); end
        if k == 6 then h.tooltipstring = msprintf("Kondensatorius: C = %g nF.", LD9.cfg.CnF); end
    end
    tids = ld9_terminal_ids();
    for id = matrix(tids, 1, -1)
        bg = [0.08 0.39 0.37]; if id == LD9.pending then bg = [0.60 0.39 0.06]; end
        cb = "ld9_terminal_click(""" + id + """)";
        h = student_terminal(p, ld9_terminal_xy(id), ld9_terminal_button_text(id), ld9_terminal_code(id), cb, ld9_terminal_name(id), bg);
        h.horizontalalignment = "center";
        if ~ld9_wiring_editable() then h.enable = "off"; end
        LD9.term.handles($+1) = h; LD9.term.handleIds($+1, 1) = id; LD9.ui.dynamic($+1) = h; ld9_track_board(h);
    end
    ld9_track_board(student_end_wires(p));
    for k = 1:3
        h = LD9.ui.controls(k); h.backgroundcolor = [0.94 0.96 0.96]; h.foregroundcolor = [0.08 0.20 0.22];
        if LD9.freqPoint == k then h.backgroundcolor = [0.08 0.39 0.37]; h.foregroundcolor = [1 1 1]; end
    end
    for k = 4:7
        h = LD9.ui.controls(k); h.backgroundcolor = [0.94 0.96 0.96]; h.foregroundcolor = [0.08 0.20 0.22];
        if LD9.target == k-3 then h.backgroundcolor = [0.52 0.25 0.48]; h.foregroundcolor = [1 1 1]; end
    end
    LD9.ui.controls(10).enable = "off";
    if ~LD9.demoMode & or(LD9.step == [2 3 4]) then LD9.ui.controls(10).enable = "on"; end
    ld9_font(p);
    LD9.fig.immediate_drawing = drawing;
endfunction

function ld9_render_journal()
    global LD9;
    if ~isfield(LD9, "ui") then return; end
    if ~isfield(LD9.ui, "journalList") then return; end
    rows = emptystr(0, 1);
    names = ["f1 = 0,5·f0";"f0  (rezonansas)";"f2 = 2·f0"];
    targets = ["UR";"UL";"UC";"U"];
    for tag = 1:3
        for target = 1:4
            m = ld9_journal_rows(tag, target);
            for k = 1:size(m, 1)
                rows($+1) = msprintf("%s  %s   %.4f V   %.3f mA", names(tag), targets(target), m(k,1), m(k,2));
            end
        end
    end
    if rows == [] then rows = "Matavimų dar nėra."; end
    LD9.ui.journalList.string = rows;
endfunction

function ld9_render_stage()
    global LD9;
    if ~isfield(LD9, "ui") then return; end
    if isfield(LD9.ui, "headless") then if LD9.ui.headless then return; end; end
    if ~isfield(LD9.ui, "answerEdits") then return; end
    row = 0;
    for k = 1:12
        [st, sl] = ld9_answer_slot(k); h = LD9.ui.answerEdits(k); lab = LD9.ui.answerLabels(k);
        h.visible = "off"; lab.visible = "off";
        if st == LD9.step then
            yy = 0.60 - row*0.085; row = row + 1;
            lab.position = [0.07 yy 0.53 0.075]; h.position = [0.63 yy 0.30 0.075];
            h.string = LD9.answers(st, sl); h.visible = "on"; lab.visible = "on";
            h.enable = "on"; if LD9.demoMode then h.enable = "off"; end
        end
    end
    LD9.ui.instructionLine(1).string = student_wrap(ld9_step_instruction(LD9.step), 38);
    LD9.ui.progress.string = string(LD9.step) + " / 6 etapas";
    if LD9.demoMode then LD9.ui.progress.string = "PAVYZDYS"; end
    LD9.ui.identity.string = student_caption(LD9.student);
    ld9_render_wires();
    ld9_render_journal(); ld9_student_sync();
endfunction

function ld9_resize(id)
    global LD9;
    if typeof(LD9) <> "st" then return; end
    if ~isfield(LD9, "fig") then return; end
    if ~is_handle_valid(LD9.fig) then return; end
    if LD9.fig.figure_id <> id then return; end
    // Recompute fixed pixel terminal targets and crossing gaps. Keep raw edits.
    ld9_render_wires();
endfunction

function ld9_build_gui()
    global LD9;
    f = figure("resize", "off", "default_axes", "off", "dockable", "off", "menubar", "none", "toolbar", "none", "visible", "off");
    f.axes_size = [1280 720]; f.figure_position = [10 10]; f.infobar_visible = "off";
    f.figure_name = "LD9 · Nuosekliai sujungtos RLC grandinės: trikampiai ir įtampų rezonansas"; f.background = color(246,248,249); LD9.fig = f;
    LD9.ui = struct("headless", %f, "boardHandles", list(), "dynamic", [], "controls", []);
    LD9.term = struct("handles", list(), "handleIds", emptystr(0, 1));
    student_text(f, [0.03 0.925 0.65 0.05], "LD9 / Nuosekli RLC grandinė: trikampiai ir įtampų rezonansas", 20, %t, [0.965 0.973 0.977]);
    LD9.ui.progress = student_text(f, [0.705 0.93 0.15 0.044], "", 14, %f, [0.965 0.973 0.977]);
    LD9.ui.identity = student_text(f, [0.03 0.895 0.94 0.025], "", 12, %f, [0.965 0.973 0.977]);
    student_button(f, [0.87 0.93 0.105 0.044], "Pagalba", "ld9_show_actions()");
    p = student_frame(f, [0.025 0.12 0.655 0.77]); LD9.ui.circuitFrame = p;
    right = student_frame(f, [0.70 0.12 0.275 0.77]); LD9.ui.right = right;
    student_text(p, [0.40 0.63 0.30 0.10], student_wrap("Laidas: spauskite abu galus. Pakartoję — pašalinsite. Tarpas sankirtoje: nesujungta.", 20), 12, %f);
    // Dvylikos matavimų žurnalas (3 dažnio taškai × 4 voltmetro taikiniai).
    LD9.ui.journalList = uicontrol(p, "style", "listbox", "units", "normalized", ...
        "position", [0.04 0.80 0.64 0.18], "string", "Matavimai", ...
        "fontname", "DejaVu Sans", "fontunits", "pixels", "fontsize", 12, "tag", "V02");
    controls = [];
    freqs = ["0,5·f0";"f0";"2·f0"];
    for k = 1:3
        cb = "ld9_set_freq(" + string(k) + ")";
        controls($+1) = ld9_button(p, [0.02+(k-1)*0.245 0.105 0.235 0.075], freqs(k), cb, 12);
    end
    targets = ["UR · R";"UL · L";"UC · C";"U · GEN"];
    for k = 1:4
        cb = "ld9_set_target(" + string(k) + ")";
        controls($+1) = ld9_button(p, [0.02+(k-1)*0.185 0.020 0.175 0.070], targets(k), cb, 11);
    end
    controls($+1) = ld9_button(p, [0.40 0.56 0.18 0.06], "Maitinimas", "ld9_toggle_power()", 12);
    controls($+1) = ld9_button(p, [0.40 0.46 0.18 0.06], "Jungiklis", "ld9_toggle_switch()", 12);
    controls($+1) = ld9_button(p, [0.40 0.36 0.18 0.06], "Matuoti", "ld9_measure()", 13, [0.08 0.39 0.37]);
    LD9.ui.instructionLine(1) = student_text(right, [0.07 0.72 0.86 0.22], "", 14, %f);
    LD9.ui.instructionLine(1).verticalalignment = "top";
    labels = ["[A01.01] f0 = 1/(2π√(LC)), Hz"; ...
        "[A03.01] Q = UL(f0)/U";"[A03.02] UL−UC ties f0, V"; ...
        "[A05.01] √(UR²+(UL−UC)²) f1, V";"[A05.02] Z = U/I f1, Ω";"[A05.03] cos φ = UR/U f1"; ...
        "[A05.04] P = UR·I f1, mW";"[A05.05] Q = (UL−UC)·I f1, mvar";"[A05.06] S = U·I f1, mVA"; ...
        "[A06.01] φ = 0 ties f0?";"[A06.02] UL = UC ties f0?";"[A06.03] Žemiau talpinė, aukščiau indukcinė?"];
    LD9.ui.answerEdits = []; LD9.ui.answerLabels = [];
    for k = 1:12
        LD9.ui.answerLabels($+1) = student_text(right, [0.07 0.5 0.53 0.075], student_wrap(labels(k), 22), 14, %f);
        [st, sl] = ld9_answer_slot(k);
        h = uicontrol(right, "style", "edit", "units", "normalized", "position", [0.63 0.5 0.30 0.075], ...
            "string", "", "fontunits", "pixels", "fontsize", 14, "fontname", "DejaVu Sans", ...
            "tag", ld9_answer_code(st, sl), "callback", "ld9_answers_changed()", "backgroundcolor", [0.94 0.96 0.96]);
        LD9.ui.answerEdits($+1) = h;
    end
    LD9.ui.studentPrimary = ld9_button(right, [0.07 0.085 0.86 0.075], "Tikrinti", "ld9_student_primary()", 15, [0.08 0.39 0.37]);
    controls($+1) = LD9.ui.studentPrimary;
    controls($+1) = ld9_button(right, [0.07 0.015 0.37 0.045], "← Atgal", "ld9_jump_step(LD9.step-1)", 12);
    controls($+1) = ld9_button(right, [0.48 0.015 0.45 0.045], "Žemėlapis", "ld9_show_stand_map()", 12);
    LD9.ui.controls = controls; LD9.ui.dynamic = controls;
    LD9.ui.statusMain = student_text(f, [0.025 0.055 0.95 0.035], "", 13, %t, [0.94 0.96 0.96]);
    LD9.ui.statusFix = student_text(f, [0.025 0.020 0.95 0.035], "", 12, %f, [0.94 0.96 0.96]);
    ld9_font(f); student_finish_window(f); f.visible = "on"; ld9_render_stage();
    f.resizefcn = "ld9_resize(" + string(f.figure_id) + ")";
endfunction

function ld9_show_actions()
    choice = messagebox("Pagalba ir darbo veiksmai", "LD9", "info", ...
        ["[B04] Kaip sujungti" "[B05] Žemėlapis" "[B07] Pavyzdys" "[B08] Ataskaita" "[B06] Atkurti stendą" "[B09] Iš naujo" "Grįžti"], "modal");
    select choice
    case 1 then ld9_show_wiring_guide(); case 2 then ld9_show_stand_map();
    case 3 then ld9_toggle_solution(); case 4 then bench_export_current("LD9");
    case 5 then ld9_restore_stage(); case 6 then ld9_restart();
    end
endfunction

// Java logical font exists on both Windows and Linux; no external font install.
function ld9_font(parent)
    for h = matrix(parent.children, 1, -1)
        if h.type == "uicontrol" then
            h.fontname = "SansSerif";
            ld9_font(h);
        end
    end
endfunction
