function ld10_invalidate_wiring()
    global LD10;
    LD10.report_wires = emptystr(0, 2);
    if LD10.journal <> [] then LD10.journal = []; end
    LD10.done(:) = %f; LD10.lastMeasurement = %nan;
endfunction

function ld10_terminal_click(id)
    global LD10;
    if ~ld10_wiring_editable() | ~or(ld10_terminal_ids() == id) then return; end
    if LD10.powerOn then ld10_set_status("Prieš keisdami laidus išjunkite [B01].", "error", ""); return; end
    if LD10.pending == "" then
        LD10.pending = id;
        ld10_set_status("Pasirinktas [" + ld10_terminal_code(id) + "] " + ld10_terminal_name(id), "info", "Spauskite kitą gnybtą. Pakartoję esamo laido galus jį pašalinsite.");
    else
        first = LD10.pending; LD10.pending = "";
        if first <> id then
            existing = 0;
            for row = 1:size(LD10.wires, 1)
                if and(LD10.wires(row,:) == [first id]) | and(LD10.wires(row,:) == [id first]) then existing = row; break; end
            end
            if existing > 0 then
                LD10.wires(existing,:) = []; ld10_set_status("Laidas pašalintas.", "ok", "");
            else
                if sum(LD10.wires == first) >= 2 | sum(LD10.wires == id) >= 2 then
                    ld10_set_status("Gnybte jau yra du laidai.", "error", "Pirma pašalinkite netinkamą laidą.");
                    ld10_render_wires(); return;
                end
                LD10.wires($+1,:) = [first id]; ld10_set_status("Laidas pridėtas.", "ok", "");
            end
            LD10.switchOn = %f; ld10_invalidate_wiring();
        end
    end
    ld10_render_wires(); ld10_render_journal(); ld10_student_sync();
endfunction

function ld10_toggle_power()
    global LD10;
    LD10.powerOn = ~LD10.powerOn;
    if ~LD10.powerOn then LD10.switchOn = %f; end
    ld10_render_wires();
    if LD10.powerOn then ld10_set_status("Generatorius įjungtas.", "ok", "Uždarykite jungiklį [B02] ir matuokite [B03].");
    else ld10_set_status("Generatorius išjungtas.", "info", "Galima keisti grandinės laidus."); end
endfunction

function ld10_toggle_switch()
    global LD10;
    if ~LD10.powerOn then ld10_set_status("Pirma įjunkite [B01].", "error", ""); return; end
    LD10.switchOn = ~LD10.switchOn; ld10_render_wires();
    if LD10.switchOn then ld10_set_status("Jungiklis uždarytas.", "ok", "Rodmenis įrašykite [B03].");
    else ld10_set_status("Jungiklis atviras.", "info", ""); end
endfunction

function ld10_set_freq(k)
    global LD10;
    if LD10.demoMode | ~ld10_valid_index(k, 3) then return; end
    LD10.freqPoint = k;
    ld10_render_wires();
    names = ["0,5·f0 (žemiau rezonanso)";"f0 (rezonansas)";"2·f0 (aukščiau rezonanso)"];
    ld10_set_status(msprintf("Dažnis: %s — %g Hz.", names(k), ld10_current_frequency()), "info", "Rinkitės ampermetro taikinį [B13]–[B16] ir matuokite [B03].");
endfunction

function ld10_set_target(t)
    global LD10;
    if LD10.demoMode | ~ld10_valid_index(t, 4) then return; end
    LD10.target = t;
    ld10_render_wires();
    names = ["IR — ampermetras R šakoje";"IL — ampermetras L šakoje";"IC — ampermetras C šakoje";"I — ampermetras pagrindinėje linijoje"];
    ld10_set_status(names(t), "info", "Įjungę maitinimą matuokite [B03].");
endfunction

function ld10_measure()
    global LD10;
    if LD10.demoMode then return; end
    if ~or(LD10.step == [2 3 4]) then
        ld10_set_status("Matuojama 2, 3 ir 4 etapuose.", "error", "Kiekvienam etapui — savas dažnis ir visi keturi taikiniai."); return;
    end
    kk = [0.5 1 2];
    if LD10.freqPoint <> LD10.step - 1 then
        names = ["[B10] 0,5·f0";"[B11] f0";"[B12] 2·f0"];
        ld10_set_status("Šiam etapui nustatykite dažnį " + names(LD10.step-1) + ".", "error", ""); return;
    end
    [voltage, current, ok, message] = ld10_measure_values();
    if ~ok then ld10_set_status(message, "error", ""); return; end
    tag = LD10.step - 1; target = LD10.target;
    if ld10_journal_rows(tag, target) <> [] then
        ld10_set_status("Šis taškas ir taikinys jau išmatuoti.", "info", "Rodmenys išsaugoti žurnale."); return;
    end
    f = kk(LD10.freqPoint)/sqrt(LD10.cfg.L*LD10.cfg.C)/(2*%pi);
    LD10.journal($+1,:) = [voltage, current, tag, f, target];
    LD10.lastMeasurement = current;
    ld10_render_journal(); ld10_render_wires();
    ld10_set_status(msprintf("Užfiksuota: I = %.3f mA; U = %.4f V.", current, voltage), "ok", "Taškui išmatuokite visus keturis taikinius.");
endfunction

function ok = ld10_close_enough(value, expected, relative, absolute)
    if argn(2) < 3 then relative = .02; end
    if argn(2) < 4 then absolute = 1e-9; end
    ok = %f;
    if isnan(value) | isinf(value) | isnan(expected) | isinf(expected) then return; end
    ok = abs(value - expected) <= absolute + relative*abs(expected);
endfunction

function ld10_check_step()
    global LD10;
    if LD10.demoMode then return; end
    ld10_save_answers(); step = LD10.step;
    if ~ld10_valid_index(step, 6) then return; end
    if LD10.done(step) then return; end
    if step == 1 then
        [valid, message] = ld10_wiring_valid(LD10.wires);
        if ~valid then ld10_set_status(message, "error", "Pagalba → Kaip sujungti."); return; end
        LD10.report_wires = LD10.wires;
    end
    if or(step == [2 3 4]) then
        tag = step - 1;
        for target = 1:4
            if ld10_journal_rows(tag, target) == [] then
                names = ["IR [B13]";"IL [B14]";"IC [B15]";"I [B16]"];
                ld10_set_status(msprintf("Trūksta matavimo: %s šiame dažnio taške.", names(target)), "error", "Nustatykite dažnį ir taikinį, tada [B03]."); return;
            end
        end
    end
    expected = ld10_expected_answers();
    for index = 1:12
        [answer_step, slot] = ld10_answer_slot(index);
        if answer_step <> step then continue; end
        value = ld10_parse_number(LD10.answers(step, slot)); relative = .02; absolute = 1e-9;
        if step == 1 then relative = .01; end
        if step == 3 & slot == 1 then relative = .03; end
        if step == 3 & slot == 2 then relative = 0; absolute = .02; end
        if step == 6 then relative = 0; absolute = 0; end
        if ~ld10_close_enough(value, expected(step, slot), relative, absolute) then
            ld10_set_status("Patikrinkite [" + ld10_answer_code(step, slot) + "].", "error", "Peržiūrėkite formulę užduotyje ir vienetus (mA, mS)."); return;
        end
    end
    LD10.done(step) = %t; ld10_render_stage();
    ld10_set_status(string(step) + " etapas patikrintas.", "ok", "");
endfunction

function ld10_next_step()
    global LD10;
    if LD10.step >= 6 | ~LD10.done(LD10.step) then return; end
    ld10_set_step(LD10.step + 1);
endfunction

function ld10_set_step(step)
    global LD10;
    if ~ld10_valid_index(step, 6) then return; end
    if LD10.demoMode then ld10_toggle_solution(); end
    ld10_save_answers(); LD10.pending = ""; LD10.step = step;
    ld10_render_stage();
endfunction

function text = ld10_step_instruction(step)
    global LD10;
    cfg = LD10.cfg;
    select step
    case 1 then text = msprintf("Sujunkite lygiagrečią grandinę be maitinimo: generatorius → jungiklis → ampermetras → mazgas, iš kurio R, L ir C šakos grįžta į antrąjį mazgą. Seka: Pagalba → [B04]. [A01.01] Apskaičiuokite teorinį rezonanso dažnį f0 = 1/(2π·√(L·C)); L = %g mH, C = %g nF.", cfg.LmH, cfg.CnF);
    case 2 then text = "[B10] Nustatykite 0,5·f0. Perkelkite ampermetrą ir išmatuokite keturias sroves: [B13] IR (R šakoje), [B14] IL, [B15] IC, [B16] I (pagrindinėje linijoje). U visose šakose vienoda.";
    case 3 then text = "[B11] Nustatykite f0. Išmatuokite IR, IL, IC, I. [A03.01] Q = IL/I; [A03.02] IL − IC (turėtų būti ≈ 0). Stebėkite: I minimalus!";
    case 4 then text = "[B12] Nustatykite 2·f0. Išmatuokite IR, IL, IC, I.";
    case 5 then text = "Iš pirmojo taško (0,5·f0) matavimų: [A05.01] srovių trikampis √(IR²+(IL−IC)²), mA; [A05.02] Y = I/U, mS (I — mA); [A05.03] cos φ = IR/I; [A05.04] P = U·IR, mW; [A05.05] Q = U·(IL−IC), mvar; [A05.06] S = U·I, mVA.";
    case 6 then text = "[A06.01] Ties f0 bendroji srovė I minimali? [A06.02] Ties f0 IL = IC? [A06.03] Žemiau f0 grandinė indukcinė, aukščiau — talpinė? 1 – Taip, 2 – Ne. Palyginkite su nuosekliąja grandine (LD9)!";
    else text = "";
    end
endfunction

function ld10_save_answers()
    global LD10;
    if LD10.demoMode | ~isfield(LD10, "ui") then return; end
    if isfield(LD10.ui, "headless") then if LD10.ui.headless then return; end; end
    if ~isfield(LD10.ui, "answerEdits") then return; end
    for index = 1:size(LD10.ui.answerEdits, "*")
        handle = LD10.ui.answerEdits(index);
        if ~is_handle_valid(handle) then continue; end
        [step, slot] = ld10_answer_slot(index);
        if step <> LD10.step | handle.visible <> "on" then continue; end
        if LD10.answers(step, slot) <> handle.string then LD10.done(step) = %f; end
        LD10.answers(step, slot) = handle.string;
    end
endfunction

function [step, slot] = ld10_answer_slot(index)
    mapping = [1 1;3 1;3 2;5 1;5 2;5 3;5 4;5 5;5 6;6 1;6 2;6 3];
    step = mapping(index, 1); slot = mapping(index, 2);
endfunction

function ld10_test_answers(step, values)
    global LD10;
    for index = 1:size(values, "*"); LD10.answers(step, index) = msprintf("%.17g", values(index)); end
endfunction

function ld10_show_wiring_guide()
    global LD10;
    text = ["LD10 · Lygiagretė RLC grandinė"; ""; "Išjunkite generatorių prieš jungdami laidus."];
    wires = ld10_canonical_wires();
    for index = 1:size(wires, 1)
        text($+1) = msprintf("%d. [%s]–[%s]: %s → %s", index, ld10_terminal_code(wires(index,1)), ld10_terminal_code(wires(index,2)), wires(index,1), wires(index,2));
    end
    text = [text; ""; "Ampermetras perkeliamas mygtukais [B13]–[B16] — laidų keisti nereikia."; "Dažnis nustatomas mygtukais [B10]–[B12] pagal etapą."; "Lygiagretus jungimas: visos šakos tarp tų pačių dviejų mazgų."];
    ld10_text_window("Kaip sujungti", text);
endfunction

function ld10_show_stand_map()
    [ids, callbacks, labels, hints] = ld10_button_registry();
    text = ["LD10 · STENDO ŽEMĖLAPIS";"T01/T02 – generatorius (~, 5 V RMS).";"T03/T04 – jungiklis."; ...
        "T05/T06 – ampermetras; T07/T08 – R."; "T09/T10 – L; T11/T12 – C."; ...
        "Ampermetro taikiniai: [B13]–[B16]."; ""];
    for index = 1:size(ids, "*"); text($+1) = "[" + ids(index) + "] " + labels(index); end
    text = [text; ""; "Etapai E01–E06. V02 – 12 matavimų žurnalas."; ...
        "A01.01 – teorinis f0; A03 – srovių kokybė Q ir IL−IC."; ...
        "A05.01–A05.06 – srovių trikampiai f1 taške. A06 – išvados."];
    ld10_text_window("Žemėlapis", text);
endfunction

function ld10_text_window(title, lines)
    global LD10;
    if LD10.ui.headless then return; end
    window = figure("figure_name", "LD10 · " + title, "axes_size", [560 420], ...
        "menubar_visible", "off", "toolbar_visible", "off", "infobar_visible", "off");
    uicontrol(window, "style", "listbox", "units", "normalized", "position", [.02 .10 .96 .84], ...
        "string", lines, "fontname", "SansSerif", "fontunits", "pixels", "fontsize", 12);
    uicontrol(window, "style", "pushbutton", "units", "normalized", "position", [.35 .02 .30 .06], ...
        "string", "[H01] Uždaryti", "tag", "H01", "callback", "close()");
endfunction

function ld10_toggle_solution()
    global LD10;
    if LD10.demoMode then
        LD10.demoMode = %f;
        for field = ["wires" "answers" "journal" "powerOn" "switchOn" "lastMeasurement" "freqPoint" "target"]
            LD10(field) = LD10.backup(field);
        end
        LD10.pending = ""; ld10_render_stage(); ld10_set_status("Grįžta į savo darbą.", "info", ""); return;
    end
    ld10_save_answers(); LD10.backup = struct();
    for field = ["wires" "answers" "journal" "powerOn" "switchOn" "lastMeasurement" "freqPoint" "target"]
        LD10.backup(field) = LD10(field);
    end
    LD10.practice_used = %t; LD10.demoMode = %t; LD10.pending = "";
    LD10.wires = ld10_canonical_wires(); LD10.powerOn = %t; LD10.switchOn = %t;
    LD10.journal = [];
    if or(LD10.step == [2 3 4]) then
        LD10.freqPoint = LD10.step - 1; LD10.target = 4;
        for target = 1:4
            LD10.target = target;
            [voltage, current, ok, message] = ld10_measure_values();
            if ok then LD10.journal($+1,:) = [voltage, current, LD10.step-1, ld10_current_frequency(), target]; end
        end
        LD10.target = 4;
    end
    ld10_render_stage(); ld10_set_status("PAVYZDYS: šio taško matavimai.", "info", "Grįžkite į savo darbą pagrindiniu mygtuku.");
endfunction

function ld10_restore_stage()
    global LD10;
    if LD10.demoMode then ld10_toggle_solution(); return; end
    LD10.powerOn = %f; LD10.switchOn = %f; LD10.pending = ""; LD10.lastMeasurement = %nan;
    if ld10_wiring_editable() then
        LD10.wires = emptystr(0, 2); ld10_invalidate_wiring();
    end
    ld10_render_stage(); ld10_set_status("Šio etapo stendas atkurtas.", "info", "");
endfunction

function ld10_restart()
    ld10_init_state(); ld10_render_stage(); ld10_set_status("Darbas pradėtas iš naujo.", "info", "Studentas ir variantas išliko.");
endfunction

function ld10_answers_changed()
    ld10_save_answers(); ld10_student_sync();
endfunction
