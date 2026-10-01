// Shared Scilab UI; numerical calculation and grading remain in the C++ core.
function h = ld8_button(p, pos, label, cb, fs, bg)
    if argn(2) < 5 then fs = 13; end
    if argn(2) < 6 then bg = [0.94 0.96 0.96]; end
    code = ""; hint = "";
    try
        [code, registered, hint] = ld8_button_info(cb);
    catch
        code = "";
    end
    if code <> "" then label = "[" + code + "] " + label; end
    h = student_button(p, pos, "<html><center>" + label + "</center></html>", cb);
    h.tag = code; h.tooltipstring = hint; h.fontsize = fs; h.backgroundcolor = bg;
    if sum(bg) < 1.5 then h.foregroundcolor = [1 1 1]; end
endfunction

function [term_xy, boxes] = ld8_layout()
    // All terminals sit outside their own component, with 36 x 40 px targets.
    // Planas (iš apačios): režimų eilutė 10,5–18 %, E/K/A eilutė 22–35 %,
    // V kairėje 40–56 %, R1–R3 stovas dešinėje 40–80 %, žurnalas [V02] 80–98 %.
    // Laidų koridoriai: 20 % (apatinis), 36,5/38,5 % (voltmetro zondai),
    // 37,5 % (prie R1), 53 % ir 67 % (tarp stovo pakopų), 98 % (dešinysis).
    boxes = struct("E", [7 22 15 13], "K", [38.5 22 12 13], "A", [66 22 14 13], ...
        "R1", [75 40 16 12], "R2", [75 54 16 12], "R3", [75 68 16 12], "V", [6 40 21 16]);
    term_xy = struct("E_N", [4.5 28.5], "E_P", [24.5 28.5], "K1", [35.5 28.5], ...
        "K2", [53.5 28.5], "A_P", [63.5 28.5], "A_N", [83 28.5], ...
        "R1_A", [72.5 46], "R1_B", [93.5 46], "R2_A", [72.5 60], "R2_B", [93.5 60], ...
        "R3_A", [72.5 74], "R3_B", [93.5 74], "V_P", [3.5 48], "V_N", [30.5 48]);
endfunction

function xy = ld8_terminal_xy(id)
    [tt, bb] = ld8_layout(); xy = tt(id)/100;
endfunction

function txt = ld8_terminal_button_text(id)
    select id
    case "E_P" then txt = "+"; case "E_N" then txt = "−";
    case "K1" then txt = "1"; case "K2" then txt = "2";
    case "A_P" then txt = "+"; case "A_N" then txt = "−";
    case "R1_A" then txt = "a"; case "R1_B" then txt = "b";
    case "R2_A" then txt = "a"; case "R2_B" then txt = "b";
    case "R3_A" then txt = "a"; case "R3_B" then txt = "b";
    case "V_P" then txt = "+"; case "V_N" then txt = "−";
    end
endfunction

function ld8_track_board(h)
    global LD8;
    if h <> [] then
        for item = matrix(h, 1, -1); LD8.ui.boardHandles($+1) = item; end
    end
endfunction

function ld8_clear_board()
    global LD8;
    for k = 1:length(LD8.ui.boardHandles)
        h = LD8.ui.boardHandles(k);
        if is_handle_valid(h) then delete(h); end
    end
    LD8.ui.boardHandles = list(); LD8.term.handles = list(); LD8.term.handleIds = emptystr(0, 1);
    // Only the permanent controls survive. No stale terminal handles accumulate.
    LD8.ui.dynamic = LD8.ui.controls;
endfunction

function ld8_polyline(points, col)
    global LD8;
    for k = 1:size(points, 1)-1
        ld8_track_board(student_wire(LD8.ui.circuitFrame, points(k,:), points(k+1,:), col));
    end
endfunction

function route = ld8_route(a, b)
    global LD8;
    // Kanoniniai maršrutai nepriklausomai nuo paspaudimo eilės (absoliučiai taškai).
    route = [];
    if (a == "V_P" & b == "E_P") | (a == "E_P" & b == "V_P") then
        route = [[.035 .48];[.035 .365];[.245 .365];[.245 .285]];
    elseif (a == "V_N" & b == "E_N") | (a == "E_N" & b == "V_N") then
        route = [[.305 .48];[.305 .385];[.015 .385];[.015 .285];[.045 .285]];
    elseif (a == "A_N" & b == "R1_A") | (a == "R1_A" & b == "A_N") then
        route = [[.83 .285];[.83 .375];[.725 .375];[.725 .46]];
    elseif ((a == "R1_B" & b == "R2_A") | (a == "R2_A" & b == "R1_B")) & LD8.wireMode <> 2 then
        route = [[.935 .46];[.935 .53];[.725 .53];[.725 .60]];
    elseif (a == "R2_B" & b == "R3_A") | (a == "R3_A" & b == "R2_B") then
        route = [[.935 .60];[.935 .67];[.725 .67];[.725 .74]];
    elseif (a == "R3_B" & b == "E_N") | (a == "E_N" & b == "R3_B") then
        route = [[.935 .74];[.98 .74];[.98 .20];[.045 .20];[.045 .285]];
    elseif (a == "R1_B" & b == "E_N") | (a == "E_N" & b == "R1_B") then
        route = [[.935 .46];[.98 .46];[.98 .20];[.045 .20];[.045 .285]];
    end
endfunction

function ld8_render_wires()
    global LD8;
    if ~isfield(LD8, "ui") then return; end
    if isfield(LD8.ui, "headless") then if LD8.ui.headless then return; end; end
    if ~isfield(LD8.ui, "circuitFrame") then return; end
    if ~is_handle_valid(LD8.ui.circuitFrame) then return; end
    drawing = LD8.fig.immediate_drawing; LD8.fig.immediate_drawing = "off";
    ld8_clear_board(); p = LD8.ui.circuitFrame;
    ports = [];
    for id = matrix(ld8_terminal_ids(), 1, -1); ports($+1,:) = [ld8_terminal_xy(id) 36 40]; end
    p.user_data = struct("ports", ports);
    student_begin_wires(p);
    for k = 1:size(LD8.wires, 1)
        a = LD8.wires(k,1); b = LD8.wires(k,2);
        p1 = ld8_terminal_xy(a); p2 = ld8_terminal_xy(b);
        col = [0.22 0.40 0.42];
        if or([a b] == "V_P") | or([a b] == "V_N") then col = [0.52 0.25 0.48]; end
        pts = ld8_route(a, b);
        if pts == [] then
            if abs(p1(1)-p2(1)) < 1e-9 | abs(p1(2)-p2(2)) < 1e-9 then pts = [p1; p2];
            else
                xm = (p1(1)+p2(1))/2; pts = [p1; xm p1(2); xm p2(2); p2];
            end
        end
        ld8_polyline(pts, col);
    end
    [tt, bb] = ld8_layout(); ids = ["E" "K" "A" "R1" "R2" "R3" "V"];
    names = ["E ŠALTINIS";"JUNGIKLIS";"AMPERMETRAS";"R1";"R2";"R3";"VOLTMETRAS"];
    switchText = "Atviras"; if LD8.switchOn then switchText = "Uždarytas"; end
    [u, i, valid, reason] = ld8_measure_values();
    ampText = "— mA"; voltText = "— V";
    if valid then ampText = msprintf("%.3f mA", i); voltText = msprintf("%.4f V", u); end
    vals = [msprintf("%g V", LD8.cfg.E), switchText, ampText, ...
        msprintf("%g Ω", LD8.cfg.R1), msprintf("%g Ω", LD8.cfg.R2), msprintf("%g Ω", LD8.cfg.R3), voltText];
    pairs = ["E_N" "E_P";"K1" "K2";"A_P" "A_N";"R1_A" "R1_B";"R2_A" "R2_B";"R3_A" "R3_B";"V_P" "V_N"];
    for k = 1:7
        r = bb(ids(k))/100; bg = [0.94 0.97 0.97];
        if or(k == [4 5 6]) then bg = [0.98 0.96 0.88]; end
        if k == 3 | k == 7 then bg = [0.95 0.97 0.99]; end
        for j = 1:2
            xy = tt(pairs(k,j))/100; edge = [r(1) xy(2)]; if xy(1) > r(1)+r(3)/2 then edge(1) = r(1)+r(3); end
            ld8_track_board(student_wire(p, xy, edge, [0.41 0.49 0.51], "lead:" + ids(k)));
        end
        fr = student_frame(p, r, bg); fr.tag = "component:" + ids(k); ld8_track_board(fr);
        h = student_text(fr, [0.06 0.66 0.88 0.24], names(k), 12, %t, bg); h.horizontalalignment = "center";
        h = student_text(fr, [0.04 0.04 0.92 0.58], vals(k), 14, %t, bg); h.horizontalalignment = "center";
        h.tag = "reading:" + ids(k);
        if or(k == [4 5 6]) then
            h.tooltipstring = msprintf("Tiriamasis rezistorius: nominalas %g Ω ±5 %%.", cfg_value(ids(k)));
        end
    end
    tids = ld8_terminal_ids();
    for id = matrix(tids, 1, -1)
        bg = [0.08 0.39 0.37]; if id == LD8.pending then bg = [0.60 0.39 0.06]; end
        cb = "ld8_terminal_click(""" + id + """)";
        h = student_terminal(p, ld8_terminal_xy(id), ld8_terminal_button_text(id), ld8_terminal_code(id), cb, ld8_terminal_name(id), bg);
        h.horizontalalignment = "center";
        if ~ld8_wiring_editable() then h.enable = "off"; end
        LD8.term.handles($+1) = h; LD8.term.handleIds($+1, 1) = id; LD8.ui.dynamic($+1) = h; ld8_track_board(h);
    end
    ld8_track_board(student_end_wires(p));
    for k = 1:3
        h = LD8.ui.controls(k); h.backgroundcolor = [0.94 0.96 0.96]; h.foregroundcolor = [0.08 0.20 0.22];
        if LD8.wireMode == k then h.backgroundcolor = [0.08 0.39 0.37]; h.foregroundcolor = [1 1 1]; end
    end
    LD8.ui.controls(6).enable = "off";
    if ~LD8.demoMode & or(LD8.step == [1 3 4]) & LD8.wireMode == ld8_stage_mode(LD8.step) then
        LD8.ui.controls(6).enable = "on";
    end
    ld8_font(p);
    LD8.fig.immediate_drawing = drawing;
endfunction

function value = cfg_value(id)
    global LD8;
    value = LD8.cfg(id + "nom");
endfunction

function ld8_render_journal()
    global LD8;
    if ~isfield(LD8, "ui") then return; end
    if ~isfield(LD8.ui, "journalList") then return; end
    if ~is_handle_valid(LD8.ui.journalList) then return; end
    rows = emptystr(0, 1);
    names = ["Nuosekliai";"Lygiagrečiai";"Mišriai"];
    for tag = 1:3
        measurements = ld8_journal_rows(tag);
        for k = 1:size(measurements, 1)
            rows($+1) = msprintf("%s   %.4f V   %.3f mA   Re = %.1f Ω", ...
                names(tag), measurements(k,1), measurements(k,2), measurements(k,1)/measurements(k,2)*1000);
        end
    end
    if rows == [] then rows = "Matavimų dar nėra."; end
    LD8.ui.journalList.string = rows;
endfunction

function ld8_render_stage()
    global LD8;
    if ~isfield(LD8, "ui") then return; end
    if isfield(LD8.ui, "headless") then if LD8.ui.headless then return; end; end
    if ~isfield(LD8.ui, "answerEdits") then return; end
    if ~is_handle_valid(LD8.fig) then return; end
    row = 0;
    for k = 1:12
        [st, sl] = ld8_answer_slot(k); h = LD8.ui.answerEdits(k); lab = LD8.ui.answerLabels(k);
        h.visible = "off"; lab.visible = "off";
        if st == LD8.step then
            yy = 0.56 - row*0.095; row = row + 1;
            lab.position = [0.07 yy 0.53 0.075]; h.position = [0.63 yy 0.30 0.075];
            h.string = LD8.answers(st, sl); h.visible = "on"; lab.visible = "on";
            h.enable = "on"; if LD8.demoMode then h.enable = "off"; end
        end
    end
    LD8.ui.instructionLine(1).string = student_wrap(ld8_step_instruction(LD8.step), 38);
    regime="ATSISKAITYMAS"; if ~LD8.assessment then regime="MOKYMASIS"; end
    LD8.ui.progress.string = string(LD8.step) + " / 6 etapas · " + regime;
    if LD8.demoMode then LD8.ui.progress.string = "PAVYZDYS"; end
    LD8.ui.identity.string = student_caption(LD8.student);
    ld8_render_wires(); ld8_render_journal(); ld8_student_sync();
endfunction

function ld8_resize(id)
    global LD8;
    if typeof(LD8) <> "st" then return; end
    if ~isfield(LD8, "fig") then return; end
    if ~is_handle_valid(LD8.fig) then return; end
    if LD8.fig.figure_id <> id then return; end
    // Recompute fixed pixel terminal targets and crossing gaps. Keep raw edits.
    ld8_render_wires();
endfunction

function ld8_build_gui()
    global LD8;
    f = figure("resize", "off", "default_axes", "off", "dockable", "off", "menubar", "none", "toolbar", "none", "visible", "off");
    f.axes_size = [1280 720]; f.figure_position = [10 10]; f.infobar_visible = "off";
    f.figure_name = "LD8 · Nuosekliojo, lygiagretaus ir mišriojo jungimo tyrimas"; f.background = color(246,248,249); LD8.fig = f;
    LD8.ui = struct("headless", %f, "boardHandles", list(), "dynamic", [], "controls", []);
    LD8.term = struct("handles", list(), "handleIds", emptystr(0, 1));
    student_text(f, [0.03 0.925 0.65 0.05], "LD8 / Nuosekliojo, lygiagretaus ir mišriojo jungimo tyrimas", 22, %t, [0.965 0.973 0.977]);
    LD8.ui.progress = student_text(f, [0.705 0.93 0.15 0.044], "", 14, %f, [0.965 0.973 0.977]);
    LD8.ui.identity = student_text(f, [0.03 0.895 0.94 0.025], "", 12, %f, [0.965 0.973 0.977]);
    student_button(f, [0.87 0.93 0.105 0.044], "Pagalba", "ld8_show_actions()");
    p = student_frame(f, [0.025 0.12 0.655 0.77]); LD8.ui.circuitFrame = p;
    right = student_frame(f, [0.70 0.12 0.275 0.77]); LD8.ui.right = right;
    student_text(p, [0.40 0.63 0.30 0.10], student_wrap("Laidas: spauskite abu galus. Pakartoję — pašalinsite. Tarpas sankirtoje: nesujungta.", 30), 12, %f);
    // Trijų grandinių matavimų žurnalas.
    LD8.ui.journalList = uicontrol(p, "style", "listbox", "units", "normalized", ...
        "position", [0.04 0.80 0.64 0.18], "string", "Matavimai", ...
        "fontname", "DejaVu Sans", "fontunits", "pixels", "fontsize", 12, "tag", "V02");
    controls = [];
    modes = ["Nuosekliai";"Lygiagrečiai";"Mišriai"];
    for k = 1:3
        cb = "ld8_set_mode(" + string(k) + ")";
        controls($+1) = ld8_button(p, [0.02+(k-1)*0.245 0.105 0.235 0.075], modes(k), cb, 12);
    end
    controls($+1) = ld8_button(p, [0.40 0.56 0.18 0.06], "Maitinimas", "ld8_toggle_power()", 12);
    controls($+1) = ld8_button(p, [0.40 0.46 0.18 0.06], "Jungiklis", "ld8_toggle_switch()", 12);
    controls($+1) = ld8_button(p, [0.40 0.36 0.18 0.06], "Matuoti", "ld8_measure()", 13, [0.08 0.39 0.37]);
    LD8.ui.instructionLine(1) = student_text(right, [0.07 0.66 0.86 0.29], "", 14, %f);
    LD8.ui.instructionLine(1).verticalalignment = "top";
    labels = ["[A02.01] Rt = R1+R2+R3, Ω";"[A02.02] Re = U/I, Ω"; ...
        "[A03.01] Rt = 1/(Σ1/R), Ω";"[A03.02] Re = U/I, Ω"; ...
        "[A04.01] Rt = R1+R2·R3/(R2+R3), Ω";"[A04.02] Re = U/I, Ω"; ...
        "[A05.01] I1 = U/R1, mA";"[A05.02] I2 = U/R2, mA";"[A05.03] I3 = U/R3, mA"; ...
        "[A06.01] Rt nuosekl. didžiausia?";"[A06.02] Rt lygiagr. mažiausia?";"[A06.03] ΣI šakų = I bendrai?"];
    LD8.ui.answerEdits = []; LD8.ui.answerLabels = [];
    for k = 1:12
        LD8.ui.answerLabels($+1) = student_text(right, [0.07 0.5 0.53 0.075], student_wrap(labels(k), 22), 14, %f);
        [st, sl] = ld8_answer_slot(k);
        h = uicontrol(right, "style", "edit", "units", "normalized", "position", [0.63 0.5 0.30 0.075], ...
            "string", "", "fontunits", "pixels", "fontsize", 14, "fontname", "DejaVu Sans", ...
            "tag", ld8_answer_code(st, sl), "callback", "ld8_answers_changed()", "backgroundcolor", [0.94 0.96 0.96]);
        LD8.ui.answerEdits($+1) = h;
    end
    LD8.ui.studentPrimary = ld8_button(right, [0.07 0.085 0.86 0.075], "Tikrinti", "ld8_student_primary()", 15, [0.08 0.39 0.37]);
    controls($+1) = LD8.ui.studentPrimary;
    controls($+1) = ld8_button(right, [0.07 0.015 0.37 0.045], "← Atgal", "ld8_jump_step(LD8.step-1)", 12);
    controls($+1) = ld8_button(right, [0.48 0.015 0.45 0.045], "Žemėlapis", "ld8_show_stand_map()", 12);
    LD8.ui.controls = controls; LD8.ui.dynamic = controls;
    LD8.ui.statusMain = student_text(f, [0.025 0.055 0.95 0.035], "", 13, %t, [0.94 0.96 0.96]);
    LD8.ui.statusFix = student_text(f, [0.025 0.020 0.95 0.035], "", 12, %f, [0.94 0.96 0.96]);
    ld8_font(f); student_finish_window(f); f.visible = "on"; ld8_render_stage();
    f.closerequestfcn = "ld8_close()";
    f.resizefcn = "ld8_resize(" + string(f.figure_id) + ")";
endfunction

function ld8_show_actions()
    global LD8;
    if ~isfield(LD8,"fig") then return; end
    if ~is_handle_valid(LD8.fig) then return; end
    choice=x_choose(["Tęsti išsaugotą darbą";"[B04] Kaip sujungti";"[B08] Išsaugoti ataskaitą";"Mokymosi / atsiskaitymo režimas";"Daugiau veiksmų";"Studentas ir priskirtos reikšmės"],"LD8 · Pagalba");
    select choice
    case 1 then bench_open_snapshot("LD8");
    case 2 then ld8_show_wiring_guide();
    case 3 then bench_export_current("LD8");
    case 4 then bench_mode("LD8"); ld8_student_sync(); bench_autosave("LD8");
    case 6 then ld8_text_window("Studentas ir priskirtos reikšmės",[student_caption(LD8.student);"";student_parameter_lines("LD8",LD8.cfg)]);
    case 5 then
        extra=x_choose(["[B05] Žemėlapis";"[B07] Pavyzdys";"[B06] Atkurti stendą";"[B09] Pradėti iš naujo"],"LD8 · Daugiau veiksmų");
        select extra
        case 1 then ld8_show_stand_map();
        case 2 then ld8_toggle_solution();
        case 3 then ld8_restore_stage();
        case 4 then
            if messagebox("Pradėti darbą iš naujo? Atsakymai bus išvalyti.","LD8","question",["Pradėti" "Grįžti"],"modal")==1 then ld8_restart(); end
        end
    end
endfunction

// Java logical font exists on both Windows and Linux; no external font install.
function ld8_font(parent)
    for h = matrix(parent.children, 1, -1)
        if h.type == "uicontrol" then
            h.fontname = "SansSerif";
            ld8_font(h);
        end
    end
endfunction
