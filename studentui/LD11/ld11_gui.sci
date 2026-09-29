// Shared Scilab UI; numerical calculation and grading remain in the C++ core.
function h = ld11_button(p, pos, label, cb, fs, bg)
    if argn(2) < 5 then fs = 13; end
    if argn(2) < 6 then bg = [0.94 0.96 0.96]; end
    code = ""; hint = "";
    try
        [code, registered, hint] = ld11_button_info(cb);
    catch
        code = "";
    end
    if code <> "" then label = "[" + code + "] " + label; end
    h = student_button(p, pos, "<html><center>" + label + "</center></html>", cb);
    h.tag = code; h.tooltipstring = hint; h.fontsize = fs; h.backgroundcolor = bg;
    if sum(bg) < 1.5 then h.foregroundcolor = [1 1 1]; end
endfunction

function [term_xy, boxes] = ld11_layout()
    // All terminals sit outside their own component, with 36 x 40 px targets.
    // Planas (iš apačios): dažnio ir taikinio eilutės 2–18 %, GEN/K/A eilutė
    // 22–35 %, V kairėje 40–56 %, R-L-C stovas dešinėje 40–80 %, žurnalas 80–98 %.
    // Koridoriai: 20 % (grąžinimas), 37,5 % (prie R), 53 % ir 67 % (tarp pakopų).
    boxes = struct("GEN", [7 22 15 13], "K", [38.5 22 12 13], "A", [66 22 14 13], ...
        "RL", [75 40 16 12], "CK", [75 68 16 12], "V", [6 40 21 14], "W", [6 58 21 14]);
    term_xy = struct("GEN_N", [4.5 28.5], "GEN_P", [24.5 28.5], "K1", [35.5 28.5], ...
        "K2", [53.5 28.5], "A_P", [63.5 28.5], "A_N", [83 28.5], ...
        "RL_A", [72.5 46], "RL_B", [93.5 46], "C_A", [72.5 74], "C_B", [93.5 74]);
endfunction

function xy = ld11_terminal_xy(id)
    [tt, bb] = ld11_layout(); xy = tt(id)/100;
endfunction

function txt = ld11_terminal_button_text(id)
    select id
    case "GEN_P" then txt = "+"; case "GEN_N" then txt = "−";
    case "K1" then txt = "1"; case "K2" then txt = "2";
    case "A_P" then txt = "+"; case "A_N" then txt = "−";
    case "RL_A" then txt = "a"; case "RL_B" then txt = "b";
    case "C_A" then txt = "1"; case "C_B" then txt = "2";
    end
endfunction

function ld11_track_board(h)
    global LD11;
    if h <> [] then
        for item = matrix(h, 1, -1); LD11.ui.boardHandles($+1) = item; end
    end
endfunction

function ld11_clear_board()
    global LD11;
    for k = 1:length(LD11.ui.boardHandles)
        h = LD11.ui.boardHandles(k);
        if is_handle_valid(h) then delete(h); end
    end
    LD11.ui.boardHandles = list(); LD11.term.handles = list(); LD11.term.handleIds = emptystr(0, 1);
    LD11.ui.dynamic = LD11.ui.controls;
endfunction

function ld11_polyline(points, col)
    global LD11;
    for k = 1:size(points, 1)-1
        ld11_track_board(student_wire(LD11.ui.circuitFrame, points(k,:), points(k+1,:), col));
    end
endfunction

function route = ld11_route(a, b)
    // Kanoniniai maršrutai nepriklausomai nuo paspaudimo eilės (absoliučiai taškai).
    route = [];
    if (a == "A_N" & b == "RL_A") | (a == "RL_A" & b == "A_N") then
        route = [[.83 .285];[.83 .375];[.725 .375];[.725 .46]];
    elseif (a == "RL_B" & b == "GEN_N") | (a == "GEN_N" & b == "RL_B") then
        route = [[.935 .46];[.98 .46];[.98 .20];[.045 .20];[.045 .285]];
    elseif (a == "RL_A" & b == "C_A") | (a == "C_A" & b == "RL_A") then
        route = [[.725 .46];[.725 .74]];
    elseif (a == "C_B" & b == "GEN_N") | (a == "GEN_N" & b == "C_B") then
        route = [[.935 .74];[.98 .74];[.98 .20];[.045 .20];[.045 .285]];
    end
endfunction

function ld11_render_wires()
    global LD11;
    if ~isfield(LD11, "ui") then return; end
    if isfield(LD11.ui, "headless") then if LD11.ui.headless then return; end; end
    if ~isfield(LD11.ui, "circuitFrame") then return; end
    if ~is_handle_valid(LD11.ui.circuitFrame) then return; end
    drawing = LD11.fig.immediate_drawing; LD11.fig.immediate_drawing = "off";
    ld11_clear_board(); p = LD11.ui.circuitFrame;
    ports = [];
    for id = matrix(ld11_terminal_ids(), 1, -1); ports($+1,:) = [ld11_terminal_xy(id) 36 40]; end
    p.user_data = struct("ports", ports);
    student_begin_wires(p);
    for k = 1:size(LD11.wires, 1)
        a = LD11.wires(k,1); b = LD11.wires(k,2);
        p1 = ld11_terminal_xy(a); p2 = ld11_terminal_xy(b);
        pts = ld11_route(a, b);
        if pts == [] then
            if abs(p1(1)-p2(1)) < 1e-9 | abs(p1(2)-p2(2)) < 1e-9 then pts = [p1; p2];
            else
                xm = (p1(1)+p2(1))/2; pts = [p1; xm p1(2); xm p2(2); p2];
            end
        end
        ld11_polyline(pts, [0.22 0.40 0.42]);
    end
    [tt, bb] = ld11_layout(); ids = ["GEN" "K" "A" "RL" "CK" "V" "W"];
    names = ["GEN ~";"JUNGIKLIS";"AMPERMETRAS";"RIŠLĖ R, L";"Ck KONDENS.";"VOLTMETRAS";"VATMETRAS"];
    switchText = "Atviras"; if LD11.switchOn then switchText = "Uždarytas"; end
    [u, i, valid, reason, pw] = ld11_measure_values();
    voltText = "— V";
    if valid then voltText = msprintf("%.4f V", u); end
    ampText = "— mA";
    if valid then ampText = msprintf("%.3f mA", i); end
    wattText = "— mW";
    if valid then wattText = msprintf("%.3f mW", pw); end
    vals = [msprintf("50 Hz ~ · %g V RMS", LD11.cfg.E), switchText, ampText, ...
        msprintf("%g Ω · %g mH", LD11.cfg.R, LD11.cfg.LmH), ...
        msprintf("%g µF", LD11.cfg.Ck*1e6), voltText, wattText];
    pairs = ["GEN_N" "GEN_P";"K1" "K2";"A_P" "A_N";"RL_A" "RL_B";"C_A" "C_B";"" "";"" ""];
    for k = 1:7
        r = bb(ids(k))/100; bg = [0.94 0.97 0.97];
        if ids(k) == "R" then bg = [0.98 0.96 0.88]; end
        if ids(k) == "A" | ids(k) == "V" then bg = [0.95 0.97 0.99]; end
        if pairs(k,1) <> "" then
            for j = 1:2
                xy = tt(pairs(k,j))/100; edge = [r(1) xy(2)]; if xy(1) > r(1)+r(3)/2 then edge(1) = r(1)+r(3); end
                ld11_track_board(student_wire(p, xy, edge, [0.41 0.49 0.51], "lead:" + ids(k)));
            end
        end
        fr = student_frame(p, r, bg); fr.tag = "component:" + ids(k); ld11_track_board(fr);
        h = student_text(fr, [0.06 0.66 0.88 0.24], names(k), 12, %t, bg); h.horizontalalignment = "center";
        h = student_text(fr, [0.04 0.04 0.92 0.58], vals(k), 13, %t, bg); h.horizontalalignment = "center";
        h.tag = "reading:" + ids(k);
        if k == 6 then h.tooltipstring = "Voltmetras: įtampa U prie generatoriaus galų."; end
        if k == 7 then h.tooltipstring = "Vatmetras: aktyrioji galia P, kurią suvartoja grandinė."; end
        if k == 4 then h.tooltipstring = msprintf("Rišlė: R = %g Ω, L = %g mH (nuosekliai).", LD11.cfg.R, LD11.cfg.LmH); end
        if k == 5 then h.tooltipstring = msprintf("Kompensuojantis kondensatorius Ck = %g µF (jungiamas [B11]).", LD11.cfg.Ck*1e6); end
    end
    tids = ld11_terminal_ids();
    for id = matrix(tids, 1, -1)
        bg = [0.08 0.39 0.37]; if id == LD11.pending then bg = [0.60 0.39 0.06]; end
        cb = "ld11_terminal_click(""" + id + """)";
        h = student_terminal(p, ld11_terminal_xy(id), ld11_terminal_button_text(id), ld11_terminal_code(id), cb, ld11_terminal_name(id), bg);
        h.horizontalalignment = "center";
        if ~ld11_wiring_editable() then h.enable = "off"; end
        LD11.term.handles($+1) = h; LD11.term.handleIds($+1, 1) = id; LD11.ui.dynamic($+1) = h; ld11_track_board(h);
    end
    ld11_track_board(student_end_wires(p));
    for k = 1:2
        h = LD11.ui.controls(k); h.backgroundcolor = [0.94 0.96 0.96]; h.foregroundcolor = [0.08 0.20 0.22];
        if LD11.wireMode == k then h.backgroundcolor = [0.08 0.39 0.37]; h.foregroundcolor = [1 1 1]; end
    end
    // controls(5) = Matuoti (2 režimai + maitinimas + jungiklis).
    LD11.ui.controls(5).enable = "off";
    if ~LD11.demoMode & or(LD11.step == [2 4]) & LD11.wireMode == ld11_stage_mode(LD11.step) then LD11.ui.controls(5).enable = "on"; end
    ld11_font(p);
    LD11.fig.immediate_drawing = drawing;
endfunction

function ld11_render_journal()
    global LD11;
    if ~isfield(LD11, "ui") then return; end
    if ~isfield(LD11.ui, "journalList") then return; end
    rows = emptystr(0, 1);
    names = ["BE Ck";"SU Ck"];
    for tag = 1:2
        m = ld11_journal_rows(tag);
        for k = 1:size(m, 1)
            rows($+1) = msprintf("%-7s  U=%.4f V  I=%.3f mA  P=%.3f mW", names(tag), m(k,1), m(k,2), m(k,4));
        end
    end
    if rows == [] then rows = "Matavimų dar nėra."; end
    LD11.ui.journalList.string = rows;
endfunction

function ld11_render_stage()
    global LD11;
    if ~isfield(LD11, "ui") then return; end
    if isfield(LD11.ui, "headless") then if LD11.ui.headless then return; end; end
    if ~isfield(LD11.ui, "answerEdits") then return; end
    row = 0;
    for k = 1:12
        [st, sl] = ld11_answer_slot(k); h = LD11.ui.answerEdits(k); lab = LD11.ui.answerLabels(k);
        h.visible = "off"; lab.visible = "off";
        if st == LD11.step then
            yy = 0.60 - row*0.085; row = row + 1;
            lab.position = [0.07 yy 0.53 0.075]; h.position = [0.63 yy 0.30 0.075];
            h.string = LD11.answers(st, sl); h.visible = "on"; lab.visible = "on";
            h.enable = "on"; if LD11.demoMode then h.enable = "off"; end
        end
    end
    LD11.ui.instructionLine(1).string = student_wrap(ld11_step_instruction(LD11.step), 38);
    LD11.ui.progress.string = string(LD11.step) + " / 6 etapas";
    if LD11.demoMode then LD11.ui.progress.string = "PAVYZDYS"; end
    LD11.ui.identity.string = student_caption(LD11.student);
    ld11_render_wires();
    ld11_render_journal(); ld11_student_sync();
endfunction

function ld11_resize(id)
    global LD11;
    if typeof(LD11) <> "st" then return; end
    if ~isfield(LD11, "fig") then return; end
    if ~is_handle_valid(LD11.fig) then return; end
    if LD11.fig.figure_id <> id then return; end
    // Recompute fixed pixel terminal targets and crossing gaps. Keep raw edits.
    ld11_render_wires();
endfunction

function ld11_build_gui()
    global LD11;
    f = figure("resize", "off", "default_axes", "off", "dockable", "off", "menubar", "none", "toolbar", "none", "visible", "off");
    f.axes_size = [1280 720]; f.figure_position = [10 10]; f.infobar_visible = "off";
    f.figure_name = "LD11 · Aktyviosios, reaktyviosios ir pilnutinės galios tyrimas"; f.background = color(246,248,249); LD11.fig = f;
    LD11.ui = struct("headless", %f, "boardHandles", list(), "dynamic", [], "controls", []);
    LD11.term = struct("handles", list(), "handleIds", emptystr(0, 1));
    student_text(f, [0.03 0.925 0.65 0.05], "LD11 / Aktyvioji, reaktyvioji ir pilnutinė galia; cos φ gerinimas", 20, %t, [0.965 0.973 0.977]);
    LD11.ui.progress = student_text(f, [0.705 0.93 0.15 0.044], "", 14, %f, [0.965 0.973 0.977]);
    LD11.ui.identity = student_text(f, [0.03 0.895 0.94 0.025], "", 12, %f, [0.965 0.973 0.977]);
    student_button(f, [0.87 0.93 0.105 0.044], "Pagalba", "ld11_show_actions()");
    p = student_frame(f, [0.025 0.12 0.655 0.77]); LD11.ui.circuitFrame = p;
    right = student_frame(f, [0.70 0.12 0.275 0.77]); LD11.ui.right = right;
    student_text(p, [0.40 0.63 0.30 0.10], student_wrap("Laidas: spauskite abu galus. Pakartoję — pašalinsite. Tarpas sankirtoje: nesujungta.", 20), 12, %f);
    // Dviejų režimų matavimų žurnalas (be Ck ir su Ck).
    LD11.ui.journalList = uicontrol(p, "style", "listbox", "units", "normalized", ...
        "position", [0.04 0.80 0.64 0.18], "string", "Matavimai", ...
        "fontname", "DejaVu Sans", "fontunits", "pixels", "fontsize", 12, "tag", "V02");
    controls = [];
    modes = ["BE Ck";"SU Ck"];
    for k = 1:2
        cb = "ld11_set_mode(" + string(k) + ")";
        controls($+1) = ld11_button(p, [0.02+(k-1)*0.245 0.105 0.235 0.075], modes(k), cb, 12);
    end
    controls($+1) = ld11_button(p, [0.40 0.56 0.18 0.06], "Maitinimas", "ld11_toggle_power()", 12);
    controls($+1) = ld11_button(p, [0.40 0.46 0.18 0.06], "Jungiklis", "ld11_toggle_switch()", 12);
    controls($+1) = ld11_button(p, [0.40 0.36 0.18 0.06], "Matuoti", "ld11_measure()", 13, [0.08 0.39 0.37]);
    LD11.ui.instructionLine(1) = student_text(right, [0.07 0.72 0.86 0.22], "", 14, %f);
    LD11.ui.instructionLine(1).verticalalignment = "top";
    labels = ["[A01.01] cos φ0 = R/Z"; ...
        "[A02.01] S = U·I, mVA";"[A02.02] Q = √(S²−P²), mvar";"[A02.03] cos φ = P/S"; ...
        "[A03.01] Ck = XL/(ω(R²+XL²)), µF"; ...
        "[A05.01] S2 = U·I2, mVA";"[A05.02] Q2, mvar";"[A05.03] cos φ2 = P2/S2";"[A05.04] ΔS = S−S2, mVA"; ...
        "[A06.01] P nepakito?";"[A06.02] I sumažėjo?";"[A06.03] cos φ padidėjo?"];
    LD11.ui.answerEdits = []; LD11.ui.answerLabels = [];
    for k = 1:12
        LD11.ui.answerLabels($+1) = student_text(right, [0.07 0.5 0.53 0.075], student_wrap(labels(k), 22), 14, %f);
        [st, sl] = ld11_answer_slot(k);
        h = uicontrol(right, "style", "edit", "units", "normalized", "position", [0.63 0.5 0.30 0.075], ...
            "string", "", "fontunits", "pixels", "fontsize", 14, "fontname", "DejaVu Sans", ...
            "tag", ld11_answer_code(st, sl), "callback", "ld11_answers_changed()", "backgroundcolor", [0.94 0.96 0.96]);
        LD11.ui.answerEdits($+1) = h;
    end
    LD11.ui.studentPrimary = ld11_button(right, [0.07 0.085 0.86 0.075], "Tikrinti", "ld11_student_primary()", 15, [0.08 0.39 0.37]);
    controls($+1) = LD11.ui.studentPrimary;
    controls($+1) = ld11_button(right, [0.07 0.015 0.37 0.045], "← Atgal", "ld11_jump_step(LD11.step-1)", 12);
    controls($+1) = ld11_button(right, [0.48 0.015 0.45 0.045], "Žemėlapis", "ld11_show_stand_map()", 12);
    LD11.ui.controls = controls; LD11.ui.dynamic = controls;
    LD11.ui.statusMain = student_text(f, [0.025 0.055 0.95 0.035], "", 13, %t, [0.94 0.96 0.96]);
    LD11.ui.statusFix = student_text(f, [0.025 0.020 0.95 0.035], "", 12, %f, [0.94 0.96 0.96]);
    ld11_font(f); student_finish_window(f); f.visible = "on"; ld11_render_stage();
    f.resizefcn = "ld11_resize(" + string(f.figure_id) + ")";
endfunction

function ld11_show_actions()
    global LD11;
    choice=x_choose(["Tęsti išsaugotą darbą";"[B04] Kaip sujungti";"[B08] Išsaugoti ataskaitą"; ...
        "Mokymosi / atsiskaitymo režimas";"Daugiau veiksmų";"Studentas ir priskirtos reikšmės"],"LD11 · Pagalba");
    select choice
    case 1 then bench_open_snapshot("LD11");
    case 2 then ld11_show_wiring_guide();
    case 3 then bench_export_current("LD11");
    case 4 then bench_mode("LD11"); ld11_student_sync(); bench_autosave("LD11");
    case 6 then ld11_text_window("Studentas ir priskirtos reikšmės",[student_caption(LD11.student);"";student_parameter_lines("LD11",LD11.cfg)]);
    case 5 then
        extra=x_choose(["[B05] Žemėlapis";"[B07] Pavyzdys";"[B06] Atkurti stendą";"[B09] Pradėti iš naujo"],"LD11 · Daugiau veiksmų");
        select extra
        case 1 then ld11_show_stand_map();
        case 2 then ld11_toggle_solution();
        case 3 then ld11_restore_stage();
        case 4 then
            if messagebox("Pradėti darbą iš naujo? Atsakymai bus išvalyti.","LD11","question",["Pradėti" "Grįžti"],"modal")==1 then ld11_restart(); end
        end
    end
endfunction

// Java logical font exists on both Windows and Linux; no external font install.
function ld11_font(parent)
    for h = matrix(parent.children, 1, -1)
        if h.type == "uicontrol" then
            h.fontname = "SansSerif";
            ld11_font(h);
        end
    end
endfunction
