// Shared Scilab UI; numerical calculation and grading remain in the C++ core.
function h = ld7_button(p, pos, label, cb, fs, bg)
    if argn(2) < 5 then fs = 13; end
    if argn(2) < 6 then bg = [0.94 0.96 0.96]; end
    code = ""; hint = "";
    try
        [code, registered, hint] = ld7_button_info(cb);
    catch
        code = "";
    end
    if code <> "" then label = "[" + code + "] " + label; end
    h = student_button(p, pos, "<html><center>" + label + "</center></html>", cb);
    h.tag = code; h.tooltipstring = hint; h.fontsize = fs; h.backgroundcolor = bg;
    if sum(bg) < 1.5 then h.foregroundcolor = [1 1 1]; end
endfunction

function [term_xy, boxes] = ld7_layout()
    // All terminals sit outside their own component, with 36 x 40 px targets.
    // Vertical plan: control rows 2–18 %, V 22–35 %, R 40–53 %, E/K/A 58–71 %,
    // septynių eilučių žurnalas [V02] 74–98 %. Laidų koridoriai: 19,5 / 37,5 / 55,5 %.
    boxes = struct("V", [54 22 19 13], "R", [54 40 19 13], ...
        "E", [7 58 15 13], "K", [38.5 58 12 13], "A", [66 58 14 13]);
    term_xy = struct("V_P", [51 28.5], "V_N", [76 28.5], ...
        "R_A", [51 46.5], "R_B", [76 46.5], ...
        "E_N", [4.5 64.5], "E_P", [24.5 64.5], "K1", [35.5 64.5], "K2", [53.5 64.5], ...
        "A_P", [63.5 64.5], "A_N", [83 64.5]);
endfunction

function xy = ld7_terminal_xy(id)
    [tt, bb] = ld7_layout(); xy = tt(id)/100;
endfunction

function txt = ld7_terminal_button_text(id)
    select id
    case "E_P" then txt = "+"; case "E_N" then txt = "−";
    case "K1" then txt = "1"; case "K2" then txt = "2";
    case "A_P" then txt = "+"; case "A_N" then txt = "−";
    case "R_A" then txt = "a"; case "R_B" then txt = "b";
    case "V_P" then txt = "+"; case "V_N" then txt = "−";
    end
endfunction

function ld7_track_board(h)
    global LD7;
    if h <> [] then
        for item = matrix(h, 1, -1); LD7.ui.boardHandles($+1) = item; end
    end
endfunction

function ld7_clear_board()
    global LD7;
    for k = 1:length(LD7.ui.boardHandles)
        h = LD7.ui.boardHandles(k);
        if is_handle_valid(h) then delete(h); end
    end
    LD7.ui.boardHandles = list(); LD7.term.handles = list(); LD7.term.handleIds = emptystr(0, 1);
    // Only the permanent controls survive. No stale terminal handles accumulate.
    LD7.ui.dynamic = LD7.ui.controls;
endfunction

function ld7_polyline(points, col)
    global LD7;
    for k = 1:size(points, 1)-1
        ld7_track_board(student_wire(LD7.ui.circuitFrame, points(k,:), points(k+1,:), col));
    end
endfunction

function ld7_render_wires()
    global LD7;
    if ~isfield(LD7, "ui") then return; end
    if isfield(LD7.ui, "headless") then if LD7.ui.headless then return; end; end
    if ~isfield(LD7.ui, "circuitFrame") then return; end
    if ~is_handle_valid(LD7.ui.circuitFrame) then return; end
    drawing = LD7.fig.immediate_drawing; LD7.fig.immediate_drawing = "off";
    ld7_clear_board(); p = LD7.ui.circuitFrame;
    ports = [];
    for id = matrix(ld7_terminal_ids(), 1, -1); ports($+1,:) = [ld7_terminal_xy(id) 36 40]; end
    p.user_data = struct("ports", ports);
    student_begin_wires(p);
    for k = 1:size(LD7.wires, 1)
        a = LD7.wires(k,1); b = LD7.wires(k,2); p1 = ld7_terminal_xy(a); p2 = ld7_terminal_xy(b);
        col = [0.22 0.40 0.42];
        if or([a b] == "V_P") | or([a b] == "V_N") then col = [0.52 0.25 0.48]; end
        // Canonical routing is independent of which endpoint is clicked first.
        if (a == "V_N" & b == "E_N") | (b == "V_N" & a == "E_N") then
            // TE zondas aplink lentą: koridoriumi tarp V ir R, kairiuoju kraštu.
            if a == "V_N" then pts = [p1; p1(1) 0.375; 0.015 0.375; 0.015 p2(2); p2];
            else pts = [p1; 0.015 p1(2); 0.015 0.375; p2(1) 0.375; p2]; end
        elseif (a == "A_N" & b == "R_A") | (b == "A_N" & a == "R_A") | ...
               (a == "A_N" & b == "E_N") | (b == "A_N" & a == "E_N") then
            pts = [p1; p1(1) 0.555; p2(1) 0.555; p2];
        elseif (a == "E_N" & b == "R_B") | (b == "E_N" & a == "R_B") then
            if a == "E_N" then pts = [p1; .015 p1(2); .015 .195; p2(1) .195; p2];
            else pts = [p1; p1(1) .195; .015 .195; .015 p2(2); p2]; end
        elseif or([a b] == "V_P") | or([a b] == "V_N") then
            if a == "V_P" | a == "V_N" then pts = [p1; p2(1) p1(2); p2];
            else pts = [p1; p1(1) p2(2); p2]; end
        elseif abs(p1(1)-p2(1)) < 1e-9 | abs(p1(2)-p2(2)) < 1e-9 then pts = [p1; p2];
        else
            // Invalid student wiring stays visible and is rejected by the core.
            xm = (p1(1)+p2(1))/2; pts = [p1; xm p1(2); xm p2(2); p2];
        end
        ld7_polyline(pts, col);
    end
    [tt, bb] = ld7_layout(); ids = ["E" "K" "A" "R" "V"];
    names = ["E ŠALTINIS";"JUNGIKLIS";"AMPERMETRAS";"R REOSTATAS";"VOLTMETRAS"];
    if LD7.wireMode == 2 then names(3) = "A (nenaud.)"; names(4) = "R (nenaud.)"; end
    if LD7.wireMode == 3 then names(4) = "R (nenaud.)"; names(5) = "V (nenaud.)"; end
    switchText = "Atviras"; if LD7.switchOn then switchText = "Uždarytas"; end
    [u, i, valid, reason, load] = ld7_measure_values();
    ampText = "— mA"; voltText = "— V";
    if valid then ampText = msprintf("%.3f mA", i); voltText = msprintf("%.4f V", u); end
    if LD7.wireMode == 2 then ampText = "— mA"; end
    if LD7.wireMode == 3 then voltText = "≈0 V"; end
    rText = "?"; if LD7.done(3) then rText = msprintf("%g Ω", LD7.cfg.r); end
    eText = "<html><center>" + msprintf("%g V", LD7.cfg.E) + "<br>r = " + rText + "</center></html>";
    rCard = "—";
    if LD7.wireMode == 1 & LD7.position > 0 then
        rCard = "<html><center>P" + string(LD7.position) + "<br>" + msprintf("%g Ω", load) + "</center></html>";
    elseif LD7.wireMode <> 1 then
        rCard = "—";
    end
    vals = [eText, switchText, ampText, rCard, voltText];
    pairs = ["E_N" "E_P";"K1" "K2";"A_P" "A_N";"R_A" "R_B";"V_P" "V_N"];
    for k = 1:5
        r = bb(ids(k))/100; bg = [0.94 0.97 0.97];
        if ids(k) == "R" then bg = [0.98 0.96 0.88]; end
        if ids(k) == "V" | ids(k) == "A" then bg = [0.95 0.97 0.99]; end
        for j = 1:2
            xy = tt(pairs(k,j))/100; edge = [r(1) xy(2)]; if xy(1) > r(1)+r(3)/2 then edge(1) = r(1)+r(3); end
            ld7_track_board(student_wire(p, xy, edge, [0.41 0.49 0.51], "lead:" + ids(k)));
        end
        fr = student_frame(p, r, bg); fr.tag = "component:" + ids(k); ld7_track_board(fr);
        h = student_text(fr, [0.06 0.66 0.88 0.24], names(k), 12, %t, bg); h.horizontalalignment = "center";
        h = student_text(fr, [0.04 0.04 0.92 0.58], vals(k), 14, %t, bg); h.horizontalalignment = "center";
        h.tag = "reading:" + ids(k);
        if k == 1 then h.tooltipstring = "Šaltinio EV ir vidinė varža r. r reikšmė atsivers 3 etapui patvirtinus [A03.01]."; end
        if k == 4 then h.tooltipstring = "Reostatas: penkios padėtys P1–P5 pagal variantą. Verčių ieškokite ant mygtukų [B13]–[B17]."; end
    end
    tids = ld7_terminal_ids();
    for id = matrix(tids, 1, -1)
        bg = [0.08 0.39 0.37]; if id == LD7.pending then bg = [0.60 0.39 0.06]; end
        cb = "ld7_terminal_click(""" + id + """)";
        h = student_terminal(p, ld7_terminal_xy(id), ld7_terminal_button_text(id), ld7_terminal_code(id), cb, ld7_terminal_name(id), bg);
        h.horizontalalignment = "center";
        if ~ld7_wiring_editable() then h.enable = "off"; end
        LD7.term.handles($+1) = h; LD7.term.handleIds($+1, 1) = id; LD7.ui.dynamic($+1) = h; ld7_track_board(h);
    end
    ld7_track_board(student_end_wires(p));
    for k = 1:3
        h = LD7.ui.controls(k); h.backgroundcolor = [0.94 0.96 0.96]; h.foregroundcolor = [0.08 0.20 0.22];
        if LD7.wireMode == k then h.backgroundcolor = [0.08 0.39 0.37]; h.foregroundcolor = [1 1 1]; end
    end
    for k = 4:8
        h = LD7.ui.controls(k); h.backgroundcolor = [0.94 0.96 0.96]; h.foregroundcolor = [0.08 0.20 0.22];
        h.enable = "off"; if LD7.wireMode == 1 & ~LD7.demoMode then h.enable = "on"; end
        if LD7.wireMode == 1 & LD7.position == k-3 then
            h.backgroundcolor = [0.08 0.39 0.37]; h.foregroundcolor = [1 1 1];
        end
    end
    LD7.ui.controls(11).enable = "off";
    if ~LD7.demoMode & ((LD7.step == 2 & LD7.wireMode == 1) | (LD7.step == 5 & or(LD7.wireMode == [2 3]))) then
        LD7.ui.controls(11).enable = "on";
    end
    ld7_font(p);
    LD7.fig.immediate_drawing = drawing;
endfunction

function ld7_render_journal()
    global LD7;
    if ~isfield(LD7, "ui") then return; end
    if ~isfield(LD7.ui, "journalList") then return; end
    rows = emptystr(0, 1);
    for tag = 1:5
        measurements = ld7_journal_rows(tag);
        for k = 1:size(measurements, 1)
            rows($+1) = msprintf("P%d  %g Ω   %.4f V   %.3f mA   %.2f mW", ...
                tag, measurements(k,3), measurements(k,1), measurements(k,2), measurements(k,4));
        end
    end
    te = ld7_journal_rows(6);
    for k = 1:size(te, 1)
        rows($+1) = msprintf("TE (tuščioji eiga)   %.4f V", te(k,1));
    end
    tj = ld7_journal_rows(7);
    for k = 1:size(tj, 1)
        rows($+1) = msprintf("TJ (trumpasis jungimas)   %.3f mA", tj(k,2));
    end
    if rows == [] then rows = "Matavimų dar nėra."; end
    LD7.ui.journalList.string = rows;
endfunction

function ld7_render_stage()
    global LD7;
    if ~isfield(LD7, "ui") then return; end
    if isfield(LD7.ui, "headless") then if LD7.ui.headless then return; end; end
    if ~isfield(LD7.ui, "answerEdits") then return; end
    row = 0;
    for k = 1:12
        [st, sl] = ld7_answer_slot(k); h = LD7.ui.answerEdits(k); lab = LD7.ui.answerLabels(k);
        h.visible = "off"; lab.visible = "off";
        if st == LD7.step then
            yy = 0.56 - row*0.095; row = row + 1;
            lab.position = [0.07 yy 0.53 0.075]; h.position = [0.63 yy 0.30 0.075];
            h.string = LD7.answers(st, sl); h.visible = "on"; lab.visible = "on";
            h.enable = "on"; if LD7.demoMode then h.enable = "off"; end
        end
    end
    LD7.ui.instructionLine(1).string = student_wrap(ld7_step_instruction(LD7.step), 38);
    LD7.ui.progress.string = string(LD7.step) + " / 6 etapas";
    if LD7.demoMode then LD7.ui.progress.string = "PAVYZDYS"; end
    LD7.ui.identity.string = student_caption(LD7.student);
    ld7_render_wires(); ld7_render_journal(); ld7_student_sync();
endfunction

function ld7_resize(id)
    global LD7;
    if typeof(LD7) <> "st" then return; end
    if ~isfield(LD7, "fig") then return; end
    if ~is_handle_valid(LD7.fig) then return; end
    if LD7.fig.figure_id <> id then return; end
    // Recompute fixed pixel terminal targets and crossing gaps. Keep raw edits.
    ld7_render_wires();
endfunction

function ld7_build_gui()
    global LD7;
    f = figure("resize","off","default_axes", "off", "dockable", "off", "menubar", "none", "toolbar", "none", "visible", "off");
    f.axes_size = [1280 720]; f.figure_position = [10 10]; f.infobar_visible = "off";
    f.figure_name = "LD7 · Įtampos, srovės ir galios suderinamumas"; f.background = color(246,248,249); LD7.fig = f;
    LD7.ui = struct("headless", %f, "boardHandles", list(), "dynamic", [], "controls", []);
    LD7.term = struct("handles", list(), "handleIds", emptystr(0, 1));
    student_text(f, [0.03 0.925 0.65 0.05], "LD7 / Įtampos, srovės ir galios suderinamumas", 22, %t, [0.965 0.973 0.977]);
    LD7.ui.progress = student_text(f, [0.705 0.93 0.15 0.044], "", 14, %f, [0.965 0.973 0.977]);
    LD7.ui.identity = student_text(f, [0.03 0.895 0.94 0.025], "", 12, %f, [0.965 0.973 0.977]);
    student_button(f, [0.87 0.93 0.105 0.044], "Pagalba", "ld7_show_actions()");
    p = student_frame(f, [0.025 0.12 0.655 0.77]); LD7.ui.circuitFrame = p;
    right = student_frame(f, [0.70 0.12 0.275 0.77]); LD7.ui.right = right;
    student_text(p, [0.79 0.03 0.19 0.13], student_wrap("Laidas: spauskite abu galus. Pakartoję — pašalinsite. Tarpas sankirtoje: nesujungta.", 20), 12, %f);
    // Measurement journal for five positions and both special modes.
    LD7.ui.journalList = uicontrol(p, "style", "listbox", "units", "normalized", ...
        "position", [0.04 0.74 0.73 0.24], "string", "Matavimai", ...
        "fontname", "DejaVu Sans", "fontunits", "pixels", "fontsize", 12, "tag", "V02");
    controls = [];
    modes = ["Darbinė";"Tuščioji eiga";"Virtualus TJ"];
    for k = 1:3
        cb = "ld7_set_mode(" + string(k) + ")";
        controls($+1) = ld7_button(p, [0.02+(k-1)*0.245 0.105 0.235 0.075], modes(k), cb, 12);
    end
    for k = 1:5
        cb = "ld7_set_position(" + string(k) + ")";
        label = msprintf("P%d<br>%g Ω", k, LD7.cfg("R" + string(k)));
        controls($+1) = ld7_button(p, [0.02+(k-1)*0.152 0.020 0.142 0.070], label, cb, 11);
    end
    controls($+1) = ld7_button(p, [0.80 0.40 0.18 0.06], "Maitinimas", "ld7_toggle_power()", 12);
    controls($+1) = ld7_button(p, [0.80 0.30 0.18 0.06], "Jungiklis", "ld7_toggle_switch()", 12);
    controls($+1) = ld7_button(p, [0.80 0.20 0.18 0.06], "Matuoti", "ld7_measure()", 13, [0.08 0.39 0.37]);
    LD7.ui.instructionLine(1) = student_text(right, [0.07 0.66 0.86 0.29], "", 14, %f);
    LD7.ui.instructionLine(1).verticalalignment = "top";
    labels = ["[A03.01] r = ΔU/ΔI, Ω";"[A03.02] E = U1+I1·r, V"; ...
        "[A04.01] P1 = U1·I1, mW";"[A04.02] P3 = U3·I3, mW";"[A04.03] P5 = U5·I5, mW"; ...
        "[A04.04] Pmax = E²/(4r), mW";"[A04.05] η3 = U3/E · 100"; ...
        "[A05.01] U0 (TE), V";"[A05.02] Ik = E/r, mA"; ...
        "[A06.01] P max kai R = r?";"[A06.02] η = 50 %?";"[A06.03] U krinta dėl r?"];
    LD7.ui.answerEdits = []; LD7.ui.answerLabels = [];
    for k = 1:12
        LD7.ui.answerLabels($+1) = student_text(right, [0.07 0.5 0.53 0.075], student_wrap(labels(k), 22), 14, %f);
        [st, sl] = ld7_answer_slot(k);
        h = uicontrol(right, "style", "edit", "units", "normalized", "position", [0.63 0.5 0.30 0.075], ...
            "string", "", "fontunits", "pixels", "fontsize", 14, "fontname", "DejaVu Sans", ...
            "tag", ld7_answer_code(st, sl), "callback", "ld7_answers_changed()", "backgroundcolor", [0.94 0.96 0.96]);
        LD7.ui.answerEdits($+1) = h;
    end
    LD7.ui.studentPrimary = ld7_button(right, [0.07 0.085 0.86 0.075], "Tikrinti", "ld7_student_primary()", 15, [0.08 0.39 0.37]);
    controls($+1) = LD7.ui.studentPrimary;
    controls($+1) = ld7_button(right, [0.07 0.015 0.37 0.045], "← Atgal", "ld7_jump_step(LD7.step-1)", 12);
    controls($+1) = ld7_button(right, [0.48 0.015 0.45 0.045], "Žemėlapis", "ld7_show_stand_map()", 12);
    LD7.ui.controls = controls; LD7.ui.dynamic = controls;
    LD7.ui.statusMain = student_text(f, [0.025 0.055 0.95 0.035], "", 13, %t, [0.94 0.96 0.96]);
    LD7.ui.statusFix = student_text(f, [0.025 0.020 0.95 0.035], "", 12, %f, [0.94 0.96 0.96]);
    ld7_font(f); student_finish_window(f); f.visible = "on"; ld7_render_stage();
    f.resizefcn = "ld7_resize(" + string(f.figure_id) + ")";
endfunction

function ld7_show_actions()
    choice = messagebox("Pagalba ir darbo veiksmai", "LD7", "info", ...
        ["[B04] Kaip sujungti" "[B05] Žemėlapis" "[B07] Pavyzdys" "[B08] Ataskaita" "[B06] Atkurti stendą" "[B09] Iš naujo" "Grįžti"], "modal");
    select choice
    case 1 then ld7_show_wiring_guide(); case 2 then ld7_show_stand_map();
    case 3 then ld7_toggle_solution(); case 4 then bench_export_current("LD7");
    case 5 then ld7_restore_stage(); case 6 then ld7_restart();
    end
endfunction

// Java logical font exists on both Windows and Linux; no external font install.
function ld7_font(parent)
    for h = matrix(parent.children, 1, -1)
        if h.type == "uicontrol" then
            h.fontname = "SansSerif";
            ld7_font(h);
        end
    end
endfunction
