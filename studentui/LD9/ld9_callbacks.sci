function ld9_invalidate_wiring()
    global LD9;
    LD9.report_wires = emptystr(0, 2);
    if LD9.journal <> [] then LD9.journal = []; end
    LD9.done(:) = %f; LD9.lastMeasurement = %nan;
endfunction

function ld9_terminal_click(id)
    global LD9;
    if ~ld9_wiring_editable() | ~or(ld9_terminal_ids() == id) then return; end
    if LD9.powerOn then ld9_set_status("Prieš keisdami laidus išjunkite [B01].", "error", ""); return; end
    if LD9.pending == "" then
        LD9.pending = id;
        ld9_set_status("Pasirinktas [" + ld9_terminal_code(id) + "] " + ld9_terminal_name(id), "info", "Spauskite kitą gnybtą. Pakartoję esamo laido galus jį pašalinsite.");
    else
        first = LD9.pending; LD9.pending = "";
        if first <> id then
            existing = 0;
            for row = 1:size(LD9.wires, 1)
                if and(LD9.wires(row,:) == [first id]) | and(LD9.wires(row,:) == [id first]) then existing = row; break; end
            end
            if existing > 0 then
                LD9.wires(existing,:) = []; ld9_set_status("Laidas pašalintas.", "ok", "");
            else
                if sum(LD9.wires == first) >= 2 | sum(LD9.wires == id) >= 2 then
                    ld9_set_status("Gnybte jau yra du laidai.", "error", "Pirma pašalinkite netinkamą laidą.");
                    ld9_render_wires(); return;
                end
                LD9.wires($+1,:) = [first id]; ld9_set_status("Laidas pridėtas.", "ok", "");
            end
            LD9.switchOn = %f; ld9_invalidate_wiring();
        end
    end
    ld9_render_wires(); ld9_render_journal(); ld9_student_sync();
endfunction

function ld9_toggle_power()
    global LD9;
    LD9.powerOn = ~LD9.powerOn;
    if ~LD9.powerOn then LD9.switchOn = %f; end
    ld9_render_wires();
    if LD9.powerOn then ld9_set_status("Generatorius įjungtas.", "ok", "Uždarykite jungiklį [B02] ir matuokite [B03].");
    else ld9_set_status("Generatorius išjungtas.", "info", "Galima keisti grandinės laidus."); end
endfunction

function ld9_toggle_switch()
    global LD9;
    if ~LD9.powerOn then ld9_set_status("Pirma įjunkite [B01].", "error", ""); return; end
    LD9.switchOn = ~LD9.switchOn; ld9_render_wires();
    if LD9.switchOn then ld9_set_status("Jungiklis uždarytas.", "ok", "Rodmenis įrašykite [B03].");
    else ld9_set_status("Jungiklis atviras.", "info", ""); end
endfunction

function ld9_set_freq(k)
    global LD9;
    if LD9.demoMode | ~ld9_valid_index(k, 3) then return; end
    LD9.freqPoint = k;
    ld9_render_wires();
    names = ["0,5·f0 (žemiau rezonanso)";"f0 (rezonansas)";"2·f0 (aukščiau rezonanso)"];
    ld9_set_status(msprintf("Dažnis: %s — %g Hz.", names(k), ld9_current_frequency()), "info", "Rinkitės voltmetro taikinį [B13]–[B16] ir matuokite [B03].");
endfunction

function ld9_set_target(t)
    global LD9;
    if LD9.demoMode | ~ld9_valid_index(t, 4) then return; end
    LD9.target = t;
    ld9_render_wires();
    names = ["UR — voltmetras prie R";"UL — voltmetras prie L";"UC — voltmetras prie C";"U — voltmetras prie generatoriaus"];
    ld9_set_status(names(t), "info", "Įjungę maitinimą matuokite [B03].");
endfunction

function ld9_measure()
    global LD9;
    if LD9.demoMode then return; end
    if ~or(LD9.step == [2 3 4]) then
        ld9_set_status("Matuojama 2, 3 ir 4 etapuose.", "error", "Kiekvienam etapui — savas dažnis ir visi keturi taikiniai."); return;
    end
    kk = [0.5 1 2];
    if LD9.freqPoint <> LD9.step - 1 then
        names = ["[B10] 0,5·f0";"[B11] f0";"[B12] 2·f0"];
        ld9_set_status("Šiam etapui nustatykite dažnį " + names(LD9.step-1) + ".", "error", ""); return;
    end
    [voltage, current, ok, message] = ld9_measure_values();
    if ~ok then ld9_set_status(message, "error", ""); return; end
    tag = LD9.step - 1; target = LD9.target;
    if ld9_journal_rows(tag, target) <> [] then
        ld9_set_status("Šis taškas ir taikinys jau išmatuoti.", "info", "Rodmenys išsaugoti žurnale."); return;
    end
    f = kk(LD9.freqPoint)/sqrt(LD9.cfg.L*LD9.cfg.C)/(2*%pi);
    LD9.journal($+1,:) = [voltage, current, tag, f, target];
    LD9.lastMeasurement = current;
    ld9_render_journal(); ld9_render_wires();
    ld9_set_status(msprintf("Užfiksuota: U = %.4f V; I = %.3f mA.", voltage, current), "ok", "Taškui išmatuokite visus keturis taikinius.");
endfunction

function ok = ld9_close_enough(value, expected, relative, absolute)
    if argn(2) < 3 then relative = .02; end
    if argn(2) < 4 then absolute = 1e-9; end
    ok = %f;
    if isnan(value) | isinf(value) | isnan(expected) | isinf(expected) then return; end
    ok = abs(value - expected) <= absolute + relative*abs(expected);
endfunction

function ld9_check_step(check_answers)
    global LD9;
    if argn(2)<1 then check_answers=%t; end
    if LD9.demoMode then return; end
    ld9_save_answers(); step = LD9.step;
    if ~ld9_valid_index(step, 6) then return; end
    if LD9.done(step) then return; end
    if step == 1 then
        [valid, message] = ld9_wiring_valid(LD9.wires);
        if ~valid then ld9_set_status(message, "error", "Pagalba → Kaip sujungti."); return; end
        LD9.report_wires = LD9.wires;
    end
    if or(step == [2 3 4]) then
        tag = step - 1;
        for target = 1:4
            if ld9_journal_rows(tag, target) == [] then
                names = ["UR [B13]";"UL [B14]";"UC [B15]";"U [B16]"];
                ld9_set_status(msprintf("Trūksta matavimo: %s šiame dažnio taške.", names(target)), "error", "Nustatykite dažnį ir taikinį, tada [B03]."); return;
            end
        end
    end
    expected = ld9_expected_answers();
    for index = 1:12
        [answer_step, slot] = ld9_answer_slot(index);
        if answer_step <> step then continue; end
        if ~check_answers then
            if stripblanks(LD9.answers(step,slot))=="" then
                ld9_set_status("Įrašykite ["+ld9_answer_code(step,slot)+"].","error","Atsakymą vertins dėstytojo programa."); return;
            end
            continue;
        end
        value = ld9_parse_number(LD9.answers(step, slot)); relative = .02; absolute = 1e-9;
        if step == 1 then relative = .01; end
        if step == 3 & slot == 1 then relative = .03; end
        if step == 3 & slot == 2 then relative = 0; absolute = .02; end
        if step == 6 then relative = 0; absolute = 0; end
        if ~ld9_close_enough(value, expected(step, slot), relative, absolute) then
            ld9_set_status("Patikrinkite [" + ld9_answer_code(step, slot) + "].", "error", "Peržiūrėkite formulę užduotyje ir vienetus."); return;
        end
    end
    LD9.done(step) = %t; ld9_render_stage();
    text=string(step)+" etapas patikrintas.";
    if ~check_answers then text=string(step)+" etapo atsakymai įrašyti."; end
    ld9_set_status(text, "ok", "");
endfunction

function ld9_next_step()
    global LD9;
    if LD9.step >= 6 | ~LD9.done(LD9.step) then return; end
    ld9_set_step(LD9.step + 1);
endfunction

function ld9_set_step(step)
    global LD9;
    if ~ld9_valid_index(step, 6) then return; end
    if LD9.demoMode then ld9_toggle_solution(); end
    ld9_save_answers(); LD9.pending = ""; LD9.step = step;
    ld9_render_stage();
endfunction

function text = ld9_step_instruction(step)
    global LD9;
    cfg = LD9.cfg;
    select step
    case 1 then text = msprintf("Sujunkite nuoseklią grandinę be maitinimo: generatorius → jungiklis → ampermetras → R → L → C → grįžimas. Seka: Pagalba → [B04]. [A01.01] Apskaičiuokite teorinį rezonanso dažnį f0 = 1/(2π·√(L·C)); L = %g mH, C = %g nF.", cfg.LmH, cfg.CnF);
    case 2 then text = "[B10] Nustatykite 0,5·f0. Išmatuokite I ir visus keturis įtempimus: [B13] UR, [B14] UL, [B15] UC, [B16] U — kiekvienam mygtukui [B03].";
    case 3 then text = "[B11] Nustatykite f0. Išmatuokite I, UR, UL, UC, U. [A03.01] Q = UL/U; [A03.02] UL − UC (turėtų būti ≈ 0).";
    case 4 then text = "[B12] Nustatykite 2·f0. Išmatuokite I, UR, UL, UC, U.";
    case 5 then text = "Iš pirmojo taško (0,5·f0) matavimų: [A05.01] įtampų trikampis √(UR²+(UL−UC)²), V; [A05.02] Z = 1000·U/I, Ω (I — mA); [A05.03] cos φ = UR/U; [A05.04] P = UR·I, mW; [A05.05] Q = (UL−UC)·I, mvar; [A05.06] S = U·I, mVA.";
    case 6 then text = "[A06.01] Ties f0 φ = 0? [A06.02] Ties f0 UL = UC? [A06.03] Žemiau f0 grandinė talpinė, aukščiau — indukcinė? 1 – Taip, 2 – Ne.";
    else text = "";
    end
endfunction

function ld9_save_answers()
    global LD9;
    if LD9.demoMode | ~isfield(LD9, "ui") then return; end
    if isfield(LD9.ui, "headless") then if LD9.ui.headless then return; end; end
    if ~isfield(LD9.ui, "answerEdits") then return; end
    for index = 1:size(LD9.ui.answerEdits, "*")
        handle = LD9.ui.answerEdits(index);
        if ~is_handle_valid(handle) then continue; end
        [step, slot] = ld9_answer_slot(index);
        if step <> LD9.step | handle.visible <> "on" then continue; end
        if LD9.answers(step, slot) <> handle.string then LD9.done(step) = %f; end
        LD9.answers(step, slot) = handle.string;
    end
endfunction

function [step, slot] = ld9_answer_slot(index)
    mapping = [1 1;3 1;3 2;5 1;5 2;5 3;5 4;5 5;5 6;6 1;6 2;6 3];
    step = mapping(index, 1); slot = mapping(index, 2);
endfunction

function ld9_test_answers(step, values)
    global LD9;
    for index = 1:size(values, "*"); LD9.answers(step, index) = msprintf("%.17g", values(index)); end
endfunction

function ld9_show_wiring_guide()
    global LD9;
    text = ["LD9 · Nuosekli RLC grandinė"; ""; "Išjunkite generatorių prieš jungdami laidus."];
    wires = ld9_canonical_wires();
    for index = 1:size(wires, 1)
        text($+1) = msprintf("%d. [%s]–[%s]: %s → %s", index, ld9_terminal_code(wires(index,1)), ld9_terminal_code(wires(index,2)), wires(index,1), wires(index,2));
    end
    text = [text; ""; "Voltmetras jungiamas mygtukais [B13]–[B16] — zondų kilnojti nereikia."; "Dažnis nustatomas mygtukais [B10]–[B12] pagal etapą."];
    ld9_text_window("Kaip sujungti", text);
endfunction

function ld9_show_stand_map()
    [ids, callbacks, labels, hints] = ld9_button_registry();
    text = ["LD9 · STENDO ŽEMĖLAPIS";"T01/T02 – generatorius (~, 5 V RMS).";"T03/T04 – jungiklis."; ...
        "T05/T06 – ampermetras; T07/T08 – R."; "T09/T10 – L; T11/T12 – C."; ...
        "Voltmetro taikiniai: [B13]–[B16]."; ""];
    for index = 1:size(ids, "*"); text($+1) = "[" + ids(index) + "] " + labels(index); end
    text = [text; ""; "Etapai E01–E06. V02 – 12 matavimų žurnalas."; ...
        "A01.01 – teorinis f0; A03 – kokybė Q ir UL−UC."; ...
        "A05.01–A05.06 – trikampiai f1 taške. A06 – išvados."];
    ld9_text_window("Žemėlapis", text);
endfunction

function ld9_text_window(title, lines)
    global LD9;
    if LD9.ui.headless then return; end
    window = figure("figure_name", "LD9 · " + title, "axes_size", [560 420], ...
        "menubar_visible", "off", "toolbar_visible", "off", "infobar_visible", "off");
    uicontrol(window, "style", "listbox", "units", "normalized", "position", [.02 .10 .96 .84], ...
        "string", lines, "fontname", "SansSerif", "fontunits", "pixels", "fontsize", 12);
    uicontrol(window, "style", "pushbutton", "units", "normalized", "position", [.35 .02 .30 .06], ...
        "string", "[H01] Uždaryti", "tag", "H01", "callback", "close()");
endfunction

function ld9_toggle_solution()
    global LD9;
    if LD9.demoMode then
        LD9.demoMode = %f;
        for field = ["wires" "answers" "journal" "powerOn" "switchOn" "lastMeasurement" "freqPoint" "target"]
            LD9(field) = LD9.backup(field);
        end
        LD9.pending = ""; ld9_render_stage(); ld9_set_status("Grįžta į savo darbą.", "info", ""); return;
    end
    if LD9.assessment then
        ld9_set_status("Pavyzdys atsiskaitymo režime nepasiekiamas.","error","Perjunkite į Mokymąsi per Pagalbą."); return;
    end
    ld9_save_answers(); LD9.backup = struct();
    for field = ["wires" "answers" "journal" "powerOn" "switchOn" "lastMeasurement" "freqPoint" "target"]
        LD9.backup(field) = LD9(field);
    end
    LD9.practice_used = %t; LD9.demoMode = %t; LD9.pending = "";
    LD9.wires = ld9_canonical_wires(); LD9.powerOn = %t; LD9.switchOn = %t;
    LD9.journal = [];
    if or(LD9.step == [2 3 4]) then
        LD9.freqPoint = LD9.step - 1; LD9.target = 4;
        for target = 1:4
            LD9.target = target;
            [voltage, current, ok, message] = ld9_measure_values();
            if ok then LD9.journal($+1,:) = [voltage, current, LD9.step-1, ld9_current_frequency(), target]; end
        end
        LD9.target = 4;
    end
    ld9_render_stage(); ld9_set_status("PAVYZDYS: šio taško matavimai.", "info", "Grįžkite į savo darbą pagrindiniu mygtuku.");
endfunction

function ld9_restore_stage()
    global LD9;
    if LD9.demoMode then ld9_toggle_solution(); return; end
    LD9.powerOn = %f; LD9.switchOn = %f; LD9.pending = ""; LD9.lastMeasurement = %nan;
    if ld9_wiring_editable() then
        LD9.wires = emptystr(0, 2); ld9_invalidate_wiring();
    end
    ld9_render_stage(); ld9_set_status("Šio etapo stendas atkurtas.", "info", "");
endfunction

function ld9_restart()
    ld9_init_state(); ld9_render_stage(); ld9_set_status("Darbas pradėtas iš naujo.", "info", "Studentas, variantas, režimas ir mokymosi žyma išliko."); bench_autosave("LD9");
endfunction

function ld9_answers_changed()
    ld9_save_answers(); ld9_student_sync(); bench_autosave("LD9");
endfunction
