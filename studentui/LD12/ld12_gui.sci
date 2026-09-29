// Shared Scilab UI; numerical calculation and grading remain in the C++ core.
function h = ld12_button(p, pos, label, cb, fs, bg)
    if argn(2) < 5 then fs = 13; end
    if argn(2) < 6 then bg = [0.94 0.96 0.96]; end
    code = ""; hint = "";
    try
        [code, registered, hint] = ld12_button_info(cb);
    catch
        code = "";
    end
    if code <> "" then label = "[" + code + "] " + label; end
    h = student_button(p, pos, "<html><center>" + label + "</center></html>", cb);
    h.tag = code; h.tooltipstring = hint; h.fontsize = fs; h.backgroundcolor = bg;
    if sum(bg) < 1.5 then h.foregroundcolor = [1 1 1]; end
endfunction

function [term_xy, boxes] = ld12_layout()
    // Terminalai SAVO elemento išorėje, koridoriai ne per dėžutes:
    // SRC [6 24 14 20] pakeltas virš mygtukų eilės; N apatiniame kairiajame
    // kampe; vertikalūs koridoriai x = .31/.33/.35 (tarp kairiojo stulpelio,
    // K ir imtuvų stovo); apatinis bendras koridorius y = .19–.22.
    boxes = struct("SRC", [6 22 14 26], "K", [40 44 12 13], "VM", [62 20 11 13], ...
        "R1", [75 40 16 12], "R2", [75 54 16 12], "R3", [75 68 16 12], "V", [6 62 16 14], "A", [6 46 16 14]);
    term_xy = struct("N", [3 23], "L1", [26 42], "L2", [26 33], "L3", [26 24], ...
        "K1", [38 50.5], "K2", [53.5 50.5], ...
        "R1_A", [72.5 46], "R1_B", [93.5 46], "R2_A", [72.5 60], "R2_B", [93.5 60], ...
        "R3_A", [72.5 74], "R3_B", [93.5 74]);
endfunction

function xy = ld12_terminal_xy(id)
    [tt, bb] = ld12_layout(); xy = tt(id)/100;
endfunction

function txt = ld12_terminal_button_text(id)
    select id
    case "L1" then txt = "1"; case "L2" then txt = "2"; case "L3" then txt = "3"; case "N" then txt = "N";
    case "K1" then txt = "1"; case "K2" then txt = "2";
    case "R1_A" then txt = "a"; case "R1_B" then txt = "b";
    case "R2_A" then txt = "a"; case "R2_B" then txt = "b";
    case "R3_A" then txt = "a"; case "R3_B" then txt = "b";
    end
endfunction

function ld12_track_board(h)
    global LD12;
    if h <> [] then
        for item = matrix(h, 1, -1); LD12.ui.boardHandles($+1) = item; end
    end
endfunction

function ld12_clear_board()
    global LD12;
    for k = 1:length(LD12.ui.boardHandles)
        h = LD12.ui.boardHandles(k);
        if is_handle_valid(h) then delete(h); end
    end
    LD12.ui.boardHandles = list(); LD12.term.handles = list(); LD12.term.handleIds = emptystr(0, 1);
    LD12.ui.dynamic = LD12.ui.controls;
endfunction

function ld12_polyline(points, col)
    global LD12;
    for k = 1:size(points, 1)-1
        ld12_track_board(student_wire(LD12.ui.circuitFrame, points(k,:), points(k+1,:), col));
    end
endfunction

function route = ld12_route(a, b)
    route = [];
    if (a == "L1" & b == "R1_A") | (a == "R1_A" & b == "L1") then
        // Aplink K dėžutę (x 40–52, y 44–57): žemyn iki y = .385, tada dešinėn.
        route = [[.26 .42];[.31 .42];[.31 .385];[.70 .385];[.70 .46];[.725 .46]];
    elseif (a == "L2" & b == "R2_A") | (a == "R2_A" & b == "L2") then
        route = [[.26 .33];[.33 .33];[.33 .60];[.725 .60]];
    elseif (a == "L3" & b == "R3_A") | (a == "R3_A" & b == "L3") then
        route = [[.26 .24];[.35 .24];[.35 .74];[.725 .74]];
    elseif (a == "R1_B" & b == "R2_B") | (a == "R2_B" & b == "R1_B") then
        route = [[.935 .46];[.935 .60]];
    elseif (a == "R2_B" & b == "R3_B") | (a == "R3_B" & b == "R2_B") then
        route = [[.935 .60];[.935 .74]];
    elseif (a == "R3_B" & b == "N") | (a == "N" & b == "R3_B") then
        route = [[.935 .74];[.975 .74];[.975 .19];[.03 .19];[.03 .23]];
    elseif (a == "R1_B" & b == "L2") | (a == "L2" & b == "R1_B") then
        route = [[.935 .46];[.96 .46];[.96 .175];[.28 .175];[.28 .33];[.26 .33]];
    elseif (a == "R2_B" & b == "L3") | (a == "L3" & b == "R2_B") then
        route = [[.935 .60];[.96 .60];[.96 .185];[.28 .185];[.28 .24];[.26 .24]];
    elseif (a == "R3_B" & b == "L1") | (a == "L1" & b == "R3_B") then
        route = [[.935 .74];[.985 .74];[.985 .195];[.29 .195];[.29 .42];[.26 .42]];
    end
endfunction

function ld12_render_wires()
    global LD12;
    if ~isfield(LD12, "ui") then return; end
    if isfield(LD12.ui, "headless") then if LD12.ui.headless then return; end; end
    if ~isfield(LD12.ui, "circuitFrame") then return; end
    if ~is_handle_valid(LD12.ui.circuitFrame) then return; end
    drawing = LD12.fig.immediate_drawing; LD12.fig.immediate_drawing = "off";
    ld12_clear_board(); p = LD12.ui.circuitFrame;
    ports = [];
    for id = matrix(ld12_terminal_ids(), 1, -1); ports($+1,:) = [ld12_terminal_xy(id) 36 40]; end
    p.user_data = struct("ports", ports);
    student_begin_wires(p);
    for k = 1:size(LD12.wires, 1)
        a = LD12.wires(k,1); b = LD12.wires(k,2);
        p1 = ld12_terminal_xy(a); p2 = ld12_terminal_xy(b);
        pts = ld12_route(a, b);
        if pts == [] then
            if abs(p1(1)-p2(1)) < 1e-9 | abs(p1(2)-p2(2)) < 1e-9 then pts = [p1; p2];
            else
                xm = (p1(1)+p2(1))/2; pts = [p1; xm p1(2); xm p2(2); p2];
            end
        end
        ld12_polyline(pts, [0.22 0.40 0.42]);
    end
    [tt, bb] = ld12_layout(); ids = ["SRC" "K" "VM" "R1" "R2" "R3" "V" "A"];
    names = ["3~ ŠALTINIS";"JUNGIKLIS";"FAZĖ";"R1";"R2";"R3";"VOLTMETRAS";"AMPERMETRAS"];
    switchText = "Atviras"; if LD12.switchOn then switchText = "Uždarytas"; end
    [u, i, valid, reason] = ld12_measure_values();
    voltText = "— V";
    if valid then voltText = msprintf("%.4f V", u); end
    ampText = "— mA";
    if valid then ampText = msprintf("%.3f mA", i); end
    modeName = "ŽVAIGŽDĖ"; if LD12.wireMode == 2 then modeName = "TRIKAMPIS"; end
    phaseName = "—"; if LD12.phase > 0 then phaseName = "L" + string(LD12.phase); end
    vals = [msprintf("3~ %g V · 50 Hz", LD12.cfg.Ul), switchText, phaseName, ...
        msprintf("%g Ω", LD12.cfg.R), msprintf("%g Ω", LD12.cfg.R), msprintf("%g Ω", LD12.cfg.R), ...
        voltText, ampText];
    pairs = ["N" "L1";"K1" "K2";"" "";"" "";"" "";"" "";"" "";"" ""];
    for k = 1:8
        r = bb(ids(k))/100; bg = [0.94 0.97 0.97];
        if ids(k) == "R" then bg = [0.98 0.96 0.88]; end
        if ids(k) == "A" | ids(k) == "V" then bg = [0.95 0.97 0.99]; end
        if pairs(k,1) <> "" then
            for j = 1:2
                xy = tt(pairs(k,j))/100; edge = [r(1) xy(2)]; if xy(1) > r(1)+r(3)/2 then edge(1) = r(1)+r(3); end
                ld12_track_board(student_wire(p, xy, edge, [0.41 0.49 0.51], "lead:" + ids(k)));
            end
        end
        fr = student_frame(p, r, bg); fr.tag = "component:" + ids(k); ld12_track_board(fr);
        h = student_text(fr, [0.06 0.66 0.88 0.24], names(k), 12, %t, bg); h.horizontalalignment = "center";
        h = student_text(fr, [0.04 0.04 0.92 0.58], vals(k), 13, %t, bg); h.horizontalalignment = "center";
        h.tag = "reading:" + ids(k);
        if or(k == [4 5 6]) then h.tooltipstring = msprintf("Imtuvas: R = %g Ω (visi trys vienodi).", LD12.cfg.R); end
        if k == 7 then h.tooltipstring = "Voltmetras: įtampa U prie generatoriaus galų."; end
        if k == 8 then h.tooltipstring = "Ampermetras: pasirinktos fazės srovė."; end
    end
    tids = ld12_terminal_ids();
    for id = matrix(tids, 1, -1)
        bg = [0.08 0.39 0.37]; if id == LD12.pending then bg = [0.60 0.39 0.06]; end
        cb = "ld12_terminal_click(""" + id + """)";
        h = student_terminal(p, ld12_terminal_xy(id), ld12_terminal_button_text(id), ld12_terminal_code(id), cb, ld12_terminal_name(id), bg);
        h.horizontalalignment = "center";
        if ~ld12_wiring_editable() then h.enable = "off"; end
        LD12.term.handles($+1) = h; LD12.term.handleIds($+1, 1) = id; LD12.ui.dynamic($+1) = h; ld12_track_board(h);
    end
    ld12_track_board(student_end_wires(p));
    for k = 1:2
        h = LD12.ui.controls(k); h.backgroundcolor = [0.94 0.96 0.96]; h.foregroundcolor = [0.08 0.20 0.22];
        if LD12.wireMode == k then h.backgroundcolor = [0.08 0.39 0.37]; h.foregroundcolor = [1 1 1]; end
    end
    for k = 3:5
        h = LD12.ui.controls(k); h.backgroundcolor = [0.94 0.96 0.96]; h.foregroundcolor = [0.08 0.20 0.22];
        if LD12.phase == k-2 then h.backgroundcolor = [0.52 0.25 0.48]; h.foregroundcolor = [1 1 1]; end
    end
    // controls(8) = Matuoti (2 režimai + 3 fazės + maitinimas + jungiklis).
    LD12.ui.controls(8).enable = "off";
    if ~LD12.demoMode & or(LD12.step == [2 4]) & LD12.wireMode == ld12_stage_mode(LD12.step) then LD12.ui.controls(8).enable = "on"; end
    ld12_font(p);
    LD12.fig.immediate_drawing = drawing;
endfunction

function ld12_render_journal()
    global LD12;
    if ~isfield(LD12, "ui") then return; end
    if ~isfield(LD12.ui, "journalList") then return; end
    rows = emptystr(0, 1);
    names = ["ŽVAIGŽDĖ";"TRIKAMPIS"];
    for tag = 1:2
        m = ld12_journal_rows(tag);
        for k = 1:size(m, 1)
            rows($+1) = msprintf("%-9s L%d  U=%.4f V  I=%.3f mA", names(tag), m(k,4), m(k,1), m(k,2));
        end
    end
    if rows == [] then rows = "Matavimų dar nėra."; end
    LD12.ui.journalList.string = rows;
endfunction

function ld12_render_stage()
    global LD12;
    if ~isfield(LD12, "ui") then return; end
    if isfield(LD12.ui, "headless") then if LD12.ui.headless then return; end; end
    if ~isfield(LD12.ui, "answerEdits") then return; end
    row = 0;
    for k = 1:10
        [st, sl] = ld12_answer_slot(k); h = LD12.ui.answerEdits(k); lab = LD12.ui.answerLabels(k);
        h.visible = "off"; lab.visible = "off";
        if st == LD12.step then
            yy = 0.60 - row*0.085; row = row + 1;
            lab.position = [0.07 yy 0.53 0.075]; h.position = [0.63 yy 0.30 0.075];
            h.string = LD12.answers(st, sl); h.visible = "on"; lab.visible = "on";
            h.enable = "on"; if LD12.demoMode then h.enable = "off"; end
        end
    end
    LD12.ui.instructionLine(1).string = student_wrap(ld12_step_instruction(LD12.step), 38);
    LD12.ui.progress.string = string(LD12.step) + " / 6 etapas";
    if LD12.demoMode then LD12.ui.progress.string = "PAVYZDYS"; end
    LD12.ui.identity.string = student_caption(LD12.student);
    ld12_render_wires();
    ld12_render_journal(); ld12_student_sync();
endfunction

function ld12_resize(id)
    global LD12;
    if typeof(LD12) <> "st" then return; end
    if ~isfield(LD12, "fig") then return; end
    if ~is_handle_valid(LD12.fig) then return; end
    if LD12.fig.figure_id <> id then return; end
    // Recompute fixed pixel terminal targets and crossing gaps. Keep raw edits.
    ld12_render_wires();
endfunction

function ld12_build_gui()
    global LD12;
    f = figure("resize", "off", "default_axes", "off", "dockable", "off", "menubar", "none", "toolbar", "none", "visible", "off");
    f.axes_size = [1280 720]; f.figure_position = [10 10]; f.infobar_visible = "off";
    f.figure_name = "LD12 · Trikampiu ir žvaigzde jungiamu imtuvu tyrimas"; f.background = color(246,248,249); LD12.fig = f;
    LD12.ui = struct("headless", %f, "boardHandles", list(), "dynamic", [], "controls", []);
    LD12.term = struct("handles", list(), "handleIds", emptystr(0, 1));
    student_text(f, [0.03 0.925 0.65 0.05], "LD12 / Trifazės grandinės: žvaigždė ir trikampis", 20, %t, [0.965 0.973 0.977]);
    LD12.ui.progress = student_text(f, [0.705 0.93 0.15 0.044], "", 14, %f, [0.965 0.973 0.977]);
    LD12.ui.identity = student_text(f, [0.03 0.895 0.94 0.025], "", 12, %f, [0.965 0.973 0.977]);
    student_button(f, [0.87 0.93 0.105 0.044], "Pagalba", "ld12_show_actions()");
    p = student_frame(f, [0.025 0.12 0.655 0.77]); LD12.ui.circuitFrame = p;
    right = student_frame(f, [0.70 0.12 0.275 0.77]); LD12.ui.right = right;
    student_text(p, [0.79 0.40 0.19 0.13], student_wrap("Laidas: spauskite abu galus. Pakartoję — pašalinsite. Tarpas sankirtoje: nesujungta.", 20), 12, %f);
    // Du realūs matavimai: po vieną pasirinktą fazę simetrinei žvaigždei ir trikampiui.
    LD12.ui.journalList = uicontrol(p, "style", "listbox", "units", "normalized", ...
        "position", [0.04 0.80 0.64 0.18], "string", "Matavimai", ...
        "fontname", "DejaVu Sans", "fontunits", "pixels", "fontsize", 12, "tag", "V02");
    controls = [];
    modes = ["ŽVAIGŽDĖ";"TRIKAMPIS"];
    for k = 1:2
        cb = "ld12_set_mode(" + string(k) + ")";
        controls($+1) = ld12_button(p, [0.02+(k-1)*0.245 0.105 0.235 0.075], modes(k), cb, 12);
    end
    phases = ["FAZĖ L1";"FAZĖ L2";"FAZĖ L3"];
    for k = 1:3
        cb = "ld12_set_phase(" + string(k) + ")";
        controls($+1) = ld12_button(p, [0.02+(k-1)*0.16 0.020 0.15 0.070], phases(k), cb, 11);
    end
    controls($+1) = ld12_button(p, [0.55 0.56 0.14 0.06], "Maitinimas", "ld12_toggle_power()", 12);
    controls($+1) = ld12_button(p, [0.55 0.46 0.14 0.06], "Jungiklis", "ld12_toggle_switch()", 12);
    controls($+1) = ld12_button(p, [0.55 0.36 0.14 0.06], "Matuoti", "ld12_measure()", 13, [0.08 0.39 0.37]);
    LD12.ui.instructionLine(1) = student_text(right, [0.07 0.72 0.86 0.22], "", 14, %f);
    LD12.ui.instructionLine(1).verticalalignment = "top";
    labels = ["[A01.01] Uf = Ul/√3, V"; ...
        "[A02.01] If = 1000·Uf/R, mA"; ...
        "[A03.01] Trikampio Uf, V"; ...
        "[A04.01] If = 1000·Ul/R, mA"; ...
        "[A05.01] Il = √3·If, mA";"[A05.02] PΔ = √3·Ul·Il, mW";"[A05.03] PY = 3·Uf·If, mW"; ...
        "[A06.01] Žvaigždėje If = Il?";"[A06.02] Trikampyje Il = √3·If?";"[A06.03] PΔ = 3·PY?"];
    LD12.ui.answerEdits = []; LD12.ui.answerLabels = [];
    for k = 1:10
        LD12.ui.answerLabels($+1) = student_text(right, [0.07 0.5 0.53 0.075], student_wrap(labels(k), 22), 14, %f);
        [st, sl] = ld12_answer_slot(k);
        h = uicontrol(right, "style", "edit", "units", "normalized", "position", [0.63 0.5 0.30 0.075], ...
            "string", "", "fontunits", "pixels", "fontsize", 14, "fontname", "DejaVu Sans", ...
            "tag", ld12_answer_code(st, sl), "callback", "ld12_answers_changed()", "backgroundcolor", [0.94 0.96 0.96]);
        LD12.ui.answerEdits($+1) = h;
    end
    LD12.ui.studentPrimary = ld12_button(right, [0.07 0.085 0.86 0.075], "Tikrinti", "ld12_student_primary()", 15, [0.08 0.39 0.37]);
    controls($+1) = LD12.ui.studentPrimary;
    controls($+1) = ld12_button(right, [0.07 0.015 0.37 0.045], "← Atgal", "ld12_jump_step(LD12.step-1)", 12);
    controls($+1) = ld12_button(right, [0.48 0.015 0.45 0.045], "Žemėlapis", "ld12_show_stand_map()", 12);
    LD12.ui.controls = controls; LD12.ui.dynamic = controls;
    LD12.ui.statusMain = student_text(f, [0.025 0.055 0.95 0.035], "", 13, %t, [0.94 0.96 0.96]);
    LD12.ui.statusFix = student_text(f, [0.025 0.020 0.95 0.035], "", 12, %f, [0.94 0.96 0.96]);
    ld12_font(f);
    student_finish_window(f); f.visible = "on"; ld12_render_stage();
    f.resizefcn = "ld12_resize(" + string(f.figure_id) + ")";
endfunction

function ld12_show_actions()
    global LD12;
    choice=x_choose(["Tęsti išsaugotą darbą";"[B04] Kaip sujungti";"[B08] Išsaugoti ataskaitą"; ...
        "Mokymosi / atsiskaitymo režimas";"Daugiau veiksmų";"Studentas ir priskirtos reikšmės"],"LD12 · Pagalba");
    select choice
    case 1 then bench_open_snapshot("LD12");
    case 2 then ld12_show_wiring_guide();
    case 3 then bench_export_current("LD12");
    case 4 then bench_mode("LD12"); ld12_student_sync(); bench_autosave("LD12");
    case 6 then ld12_text_window("Studentas ir priskirtos reikšmės",[student_caption(LD12.student);"";student_parameter_lines("LD12",LD12.cfg)]);
    case 5 then
        extra=x_choose(["[B05] Žemėlapis";"[B07] Pavyzdys";"[B06] Atkurti stendą";"[B09] Pradėti iš naujo"],"LD12 · Daugiau veiksmų");
        select extra
        case 1 then ld12_show_stand_map();
        case 2 then ld12_toggle_solution();
        case 3 then ld12_restore_stage();
        case 4 then
            if messagebox("Pradėti darbą iš naujo? Atsakymai bus išvalyti.","LD12","question",["Pradėti" "Grįžti"],"modal")==1 then ld12_restart(); end
        end
    end
endfunction

// Java logical font exists on both Windows and Linux; no external font install.
function ld12_font(parent)
    for h = matrix(parent.children, 1, -1)
        if h.type == "uicontrol" then
            h.fontname = "SansSerif";
            ld12_font(h);
        end
    end
endfunction
