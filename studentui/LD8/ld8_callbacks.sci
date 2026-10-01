function ld8_invalidate_mode()
    global LD8;
    mode = LD8.wireMode; LD8.report_wires(mode) = emptystr(0, 2);
    if LD8.journal <> [] then LD8.journal(find(LD8.journal(:,3) == mode), :) = []; end
    select mode
    case 1 then LD8.done([1 2]) = %f;
    case 2 then LD8.done([3 5]) = %f;
    case 3 then LD8.done(4) = %f;
    end
    LD8.done(6) = %f; LD8.lastMeasurement = %nan;
endfunction

function ld8_terminal_click(id)
    global LD8;
    if ~ld8_wiring_editable() | ~or(ld8_terminal_ids() == id) then return; end
    if LD8.powerOn then ld8_set_status("Prieš keisdami laidus išjunkite [B01].", "error", ""); return; end
    changed = %f;
    if LD8.pending == "" then
        LD8.pending = id;
        ld8_set_status("Pasirinktas [" + ld8_terminal_code(id) + "] " + ld8_terminal_name(id), "info", "Spauskite kitą gnybtą. Pakartoję esamo laido galus jį pašalinsite.");
    else
        first = LD8.pending; LD8.pending = "";
        if first <> id then
            existing = 0;
            for row = 1:size(LD8.wires, 1)
                if and(LD8.wires(row,:) == [first id]) | and(LD8.wires(row,:) == [id first]) then existing = row; break; end
            end
            if existing > 0 then
                LD8.wires(existing,:) = []; ld8_set_status("Laidas pašalintas.", "ok", "");
            else
                if sum(LD8.wires == first) >= 2 | sum(LD8.wires == id) >= 2 then
                    ld8_set_status("Gnybte jau yra du laidai.", "error", "Pirma pašalinkite netinkamą laidą.");
                    ld8_render_wires(); return;
                end
                LD8.wires($+1,:) = [first id]; ld8_set_status("Laidas pridėtas.", "ok", "");
            end
            LD8.wires_by_mode(LD8.wireMode) = LD8.wires;
            LD8.switchOn = %f; ld8_invalidate_mode(); changed=%t;
        end
    end
    ld8_render_wires(); ld8_render_journal(); ld8_student_sync();
    if changed then bench_autosave("LD8"); end
endfunction

function ld8_toggle_power()
    global LD8;
    LD8.powerOn = ~LD8.powerOn;
    if ~LD8.powerOn then LD8.switchOn = %f; end
    ld8_render_wires();
    if LD8.powerOn then ld8_set_status("Maitinimas įjungtas.", "ok", "Uždarykite jungiklį [B02] ir matuokite [B03].");
    else ld8_set_status("Maitinimas išjungtas.", "info", "Galima keisti šio etapo laidus."); end
endfunction

function ld8_toggle_switch()
    global LD8;
    if ~LD8.powerOn then ld8_set_status("Pirma įjunkite [B01].", "error", ""); return; end
    LD8.switchOn = ~LD8.switchOn; ld8_render_wires();
    if LD8.switchOn then ld8_set_status("Jungiklis uždarytas.", "ok", "Rodmenis įrašykite [B03].");
    else ld8_set_status("Jungiklis atviras.", "info", ""); end
endfunction

function ld8_set_mode(mode)
    global LD8;
    if LD8.demoMode | ~ld8_valid_index(mode, 3) then return; end
    if mode <> LD8.wireMode then
        LD8.wires_by_mode(LD8.wireMode) = LD8.wires;
        LD8.wireMode = mode; LD8.wires = LD8.wires_by_mode(mode);
        LD8.powerOn = %f; LD8.switchOn = %f; LD8.pending = ""; LD8.lastMeasurement = %nan;
    end
    ld8_render_wires();
    ld8_set_status("Režimas: " + ld8_mode_name(mode), "info", "Šio režimo laidai išliko. Seką rasite Pagalboje.");
endfunction

function ld8_measure()
    global LD8;
    if LD8.demoMode then return; end
    if ~or(LD8.step == [1 3 4]) | LD8.wireMode <> ld8_stage_mode(LD8.step) then
        ld8_set_status("Matuojama 1, 3 ir 4 etapuose atitinkamu režimu.", "error", "Režimą nurodo užduotis."); return;
    end
    [voltage, current, ok, message] = ld8_measure_values();
    if ~ok then ld8_set_status(message, "error", ""); return; end
    tag = LD8.wireMode;
    if ld8_journal_rows(tag) <> [] then
        ld8_set_status("Šis režimas jau išmatuotas.", "info", "Rodmenys išsaugoti žurnale."); return;
    end
    resistance = voltage/current*1000;
    LD8.journal($+1,:) = [voltage, current, tag, resistance, voltage*current];
    LD8.report_wires(LD8.wireMode) = LD8.wires;
    LD8.lastMeasurement = current;
    ld8_render_journal(); ld8_render_wires();
    ld8_set_status(msprintf("%s: U = %.4f V; I = %.3f mA.", ld8_mode_name(tag), voltage, current), "ok", ...
        msprintf("Re = U/I = %.1f Ω — užsirašykite skaičiavimams.", resistance));
    bench_autosave("LD8");
endfunction

function ok = ld8_close_enough(value, expected, relative, absolute)
    if argn(2) < 3 then relative = .02; end
    if argn(2) < 4 then absolute = 1e-9; end
    ok = %f;
    if isnan(value) | isinf(value) | isnan(expected) | isinf(expected) then return; end
    ok = abs(value - expected) <= absolute + relative*abs(expected);
endfunction

function ld8_check_step(check_answers)
    global LD8;
    if argn(2)<1 then check_answers=%t; end
    if LD8.demoMode then return; end
    ld8_save_answers(); step = LD8.step;
    if ~ld8_valid_index(step, 6) then return; end
    if LD8.done(step) then return; end
    select step
    case 1 then
        if LD8.wireMode <> 1 then ld8_set_status("Pirma sujungite nuoseklią grandinę [B10].", "error", ""); return; end
        [valid, message] = ld8_wiring_valid(LD8.wires);
        if ~valid then ld8_set_status(message, "error", "Pagalba → Kaip sujungti."); return; end
    case 3 then
        if LD8.wireMode <> 2 then ld8_set_status("Sujunkite lygiagrečią grandinę [B11].", "error", ""); return; end
        [valid, message] = ld8_wiring_valid(LD8.wires);
        if ~valid then ld8_set_status(message, "error", "Pagalba → Kaip sujungti."); return; end
    case 4 then
        if LD8.wireMode <> 3 then ld8_set_status("Sujunkite mišrią grandinę [B12].", "error", ""); return; end
        [valid, message] = ld8_wiring_valid(LD8.wires);
        if ~valid then ld8_set_status(message, "error", "Pagalba → Kaip sujungti."); return; end
    end
    if or(step == [1 3 4]) then
        if ld8_journal_rows(ld8_stage_mode(step)) == [] then
            if step == 1 then name = "nuoseklioji"; elseif step == 3 then name = "lygiagretė"; else name = "mišrioji"; end
            ld8_set_status("Trūksta matavimo: " + name + " grandinė.", "error", "Įjunkite [B01], uždarykite [B02] ir matuokite [B03]."); return;
        end
        // Laidų įrodymas sušaldomas patikrinimo momentu (ir matavimo metu).
        LD8.report_wires(ld8_stage_mode(step)) = LD8.wires;
    end
    expected = ld8_expected_answers();
    for index = 1:12
        [answer_step, slot] = ld8_answer_slot(index);
        if answer_step <> step then continue; end
        if ~check_answers then
            if stripblanks(LD8.answers(step,slot))=="" then
                ld8_set_status("Įrašykite ["+ld8_answer_code(step,slot)+"].","error","Atsakymą vertins dėstytojo programa."); return;
            end
            continue;
        end
        value = ld8_parse_number(LD8.answers(step, slot)); relative = .02; absolute = 1e-9;
        if or(step == [2 3 4]) & slot == 1 then relative = .01; end
        if step == 6 then relative = 0; absolute = 0; end
        if ~ld8_close_enough(value, expected(step, slot), relative, absolute) then
            ld8_set_status("Patikrinkite [" + ld8_answer_code(step, slot) + "].", "error", "Peržiūrėkite formulę užduotyje ir vienetus (Ω, mA)."); return;
        end
    end
    LD8.done(step) = %t; ld8_render_stage();
    text=string(step)+" etapas patikrintas.";
    if ~check_answers then text=string(step)+" etapo atsakymai įrašyti."; end
    ld8_set_status(text, "ok", "");
endfunction

function ld8_next_step()
    global LD8;
    if LD8.step >= 6 | ~LD8.done(LD8.step) then return; end
    ld8_set_step(LD8.step + 1);
endfunction

function ld8_set_step(step)
    global LD8;
    if ~ld8_valid_index(step, 6) then return; end
    if LD8.demoMode then ld8_toggle_solution(); end
    ld8_save_answers(); LD8.pending = ""; LD8.step = step;
    ld8_set_mode(ld8_stage_mode(step)); ld8_render_stage();
endfunction

function text = ld8_step_instruction(step)
    global LD8;
    cfg = LD8.cfg;
    select step
    case 1 then text = msprintf("[B10] Sujunkite nuoseklią grandinę be maitinimo: E → jungiklis → ampermetras → R1 → R2 → R3; voltmetro zondai prie šaltinio [T01]/[T02]. Seka: Pagalba → [B04]. Tada įjunkite [B01], uždarykite [B02] ir matuokite [B03].", cfg.E);
    case 2 then text = "[A02.01] Apskaičiuokite teorinę varžą: Rt = R1 + R2 + R3. [A02.02] Eksperimentinę: Re = U/I (I — amperais). Lyginkite — jos turėtų sutapti.";
    case 3 then text = "[B11] Sujunkite lygiagrečią grandinę: visos trys varžos tarp tų pačių mazgų. Išmatuokite U ir I. [A03.01] Rt = 1/(1/R1+1/R2+1/R3); [A03.02] Re = U/I.";
    case 4 then text = "[B12] Sujunkite mišrią grandinę: R1 nuosekliai su lygiagrečiais R2 ir R3. Išmatuokite. [A04.01] Rt = R1 + R2·R3/(R2+R3); [A04.02] Re = U/I.";
    case 5 then text = "Lygiagrečiosios grandinės šakų srovės esant U iš 3 etapo: [A05.01] I1 = U/R1; [A05.02] I2 = U/R2; [A05.03] I3 = U/R3 (mA). Patikrinkite: I1+I2+I3 = I.";
    case 6 then text = "[A06.01] Ar nuoseklioji Rt didesnė už kiekvieną varžą? [A06.02] Ar lygiagretė Rt mažesnė už mažiausią? [A06.03] Ar šakų srovių suma lygi bendrai srovei? 1 – Taip, 2 – Ne.";
    else text = "";
    end
endfunction

function ld8_save_answers()
    global LD8;
    if LD8.demoMode | ~isfield(LD8, "ui") then return; end
    if isfield(LD8.ui, "headless") then if LD8.ui.headless then return; end; end
    if ~isfield(LD8.ui, "answerEdits") then return; end
    for index = 1:size(LD8.ui.answerEdits, "*")
        handle = LD8.ui.answerEdits(index);
        if ~is_handle_valid(handle) then continue; end
        [step, slot] = ld8_answer_slot(index);
        if step <> LD8.step | handle.visible <> "on" then continue; end
        if LD8.answers(step, slot) <> handle.string then LD8.done(step) = %f; end
        LD8.answers(step, slot) = handle.string;
    end
endfunction

function [step, slot] = ld8_answer_slot(index)
    mapping = [2 1;2 2;3 1;3 2;4 1;4 2;5 1;5 2;5 3;6 1;6 2;6 3];
    step = mapping(index, 1); slot = mapping(index, 2);
endfunction

function ld8_test_answers(step, values)
    global LD8;
    for index = 1:size(values, "*"); LD8.answers(step, index) = msprintf("%.17g", values(index)); end
endfunction

function name = ld8_mode_name(mode)
    names = ["Nuosekliai";"Lygiagrečiai";"Mišriai"]; name = names(mode);
endfunction

function ld8_show_wiring_guide()
    global LD8;
    text = ["LD8 · " + ld8_mode_name(LD8.wireMode); ""; "Išjunkite maitinimą prieš jungdami laidus."];
    wires = ld8_canonical_wires(LD8.wireMode);
    for index = 1:size(wires, 1)
        text($+1) = msprintf("%d. [%s]–[%s]: %s → %s", index, ld8_terminal_code(wires(index,1)), ld8_terminal_code(wires(index,2)), wires(index,1), wires(index,2));
    end
    notes = ["Voltmetro zondai visada prie šaltinio galų [T01]/[T02]."];
    if LD8.wireMode == 2 then
        notes = [notes; "Lygiagrečiai: kiekviena varža jungiama tarp tų pačių dviejų mazgų."; "Tarpinis taškas turės du laidus — tai normalu."];
    elseif LD8.wireMode == 3 then
        notes = [notes; "Mišriai: R2 ir R3 lygiagrečiai, jų pora nuosekliai su R1."; "Bendras R2·R3 mazgas turės po du laidus."];
    else
        notes = [notes; "Nuosekliai: grandinė eina per visas tris varžas viena pakopa."];
    end
    text = [text; ""; notes];
    ld8_text_window("Kaip sujungti", text);
endfunction

function ld8_show_stand_map()
    [ids, callbacks, labels, hints] = ld8_button_registry();
    text = ["LD8 · STENDO ŽEMĖLAPIS";"T01/T02 – šaltinis E (+ ir −).";"T03/T04 – jungiklis."; ...
        "T05/T06 – ampermetras; T07/T08 – R1."; "T09/T10 – R2; T11/T12 – R3."; ...
        "T13/T14 – voltmetro zondai. Ženklai rodo poliškumą."; ""];
    for index = 1:size(ids, "*"); text($+1) = "[" + ids(index) + "] " + labels(index); end
    text = [text; ""; "Etapai E01–E06. V02 – trijų grandinių žurnalas."; ...
        "A02/A03/A04 – teorinė ir eksperimentinė varžos."; ...
        "A05.01–A05.03 – šakų srovės. A06.01–A06.03 – išvados."];
    ld8_text_window("Žemėlapis", text);
endfunction

function ld8_text_window(title, lines)
    global LD8;
    if LD8.ui.headless then return; end
    window = figure("figure_name", "LD8 · " + title, "axes_size", [560 420], ...
        "menubar_visible", "off", "toolbar_visible", "off", "infobar_visible", "off");
    uicontrol(window, "style", "listbox", "units", "normalized", "position", [.02 .10 .96 .84], ...
        "string", lines, "fontname", "SansSerif", "fontunits", "pixels", "fontsize", 12);
    uicontrol(window, "style", "pushbutton", "units", "normalized", "position", [.35 .02 .30 .06], ...
        "string", "[H01] Uždaryti", "tag", "H01", "callback", "close()");
endfunction

function ld8_toggle_solution()
    global LD8;
    if LD8.demoMode then
        LD8.demoMode = %f;
        for field = ["wires" "answers" "wireMode" "journal" "powerOn" "switchOn" "lastMeasurement"]
            LD8(field) = LD8.backup(field);
        end
        LD8.pending = ""; ld8_render_stage(); ld8_set_status("Grįžta į savo darbą.", "info", ""); bench_autosave("LD8"); return;
    end
    if LD8.assessment then
        ld8_set_status("Pavyzdys atsiskaitymo režime nepasiekiamas.", "error", "Perjunkite į Mokymąsi per Pagalbą."); return;
    end
    ld8_save_answers(); LD8.backup = struct();
    for field = ["wires" "answers" "wireMode" "journal" "powerOn" "switchOn" "lastMeasurement"]
        LD8.backup(field) = LD8(field);
    end
    LD8.practice_used = %t; LD8.demoMode = %t; LD8.pending = "";
    LD8.wires = ld8_canonical_wires(LD8.wireMode); LD8.powerOn = %t; LD8.switchOn = %t;
    LD8.journal = [];
    [voltage, current, ok, message] = ld8_measure_values();
    if ok then LD8.journal = [voltage, current, LD8.wireMode, voltage/current*1000, voltage*current]; end
    ld8_render_stage(); ld8_set_status("PAVYZDYS: šio režimo sujungimas ir matavimas.", "info", "Grįžkite į savo darbą pagrindiniu mygtuku.");
endfunction

function ld8_restore_stage()
    global LD8;
    if LD8.demoMode then ld8_toggle_solution(); return; end
    LD8.powerOn = %f; LD8.switchOn = %f; LD8.pending = ""; LD8.lastMeasurement = %nan;
    if ld8_wiring_editable() then
        LD8.wires = emptystr(0, 2); LD8.wires_by_mode(LD8.wireMode) = LD8.wires; ld8_invalidate_mode();
    end
    ld8_render_stage(); ld8_set_status("Šio etapo stendas atkurtas.", "info", ""); bench_autosave("LD8");
endfunction

function ld8_restart()
    ld8_init_state(); ld8_render_stage(); ld8_set_status("Darbas pradėtas iš naujo.", "info", "Studentas, variantas, režimas ir mokymosi žyma išliko."); bench_autosave("LD8");
endfunction

function ld8_answers_changed()
    ld8_save_answers(); ld8_student_sync(); bench_autosave("LD8");
endfunction

function ld8_close()
    global LD8;
    if ~isfield(LD8,"fig") then return; end
    if ~is_handle_valid(LD8.fig) then return; end
    if LD8.demoMode then ld8_toggle_solution(); end
    bench_autosave("LD8");
    if isfield(LD8,"autosave_error") then
        if LD8.autosave_error<>"" then return; end
    end
    delete(LD8.fig);
endfunction
