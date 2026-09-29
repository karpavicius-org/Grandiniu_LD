function ld11_invalidate_mode()
    global LD11;
    mode = LD11.wireMode; LD11.report_wires(mode) = emptystr(0, 2);
    if LD11.journal <> [] then LD11.journal(find(LD11.journal(:,3) == mode), :) = []; end
    select mode
    case 1 then LD11.done([1 2 3]) = %f;
    case 2 then LD11.done([4 5]) = %f;
    end
    LD11.done(6) = %f; LD11.lastMeasurement = %nan;
endfunction

function ld11_terminal_click(id)
    global LD11;
    if ~ld11_wiring_editable() | ~or(ld11_terminal_ids() == id) then return; end
    if LD11.powerOn then ld11_set_status("Prieš keisdami laidus išjunkite [B01].", "error", ""); return; end
    if LD11.pending == "" then
        LD11.pending = id;
        ld11_set_status("Pasirinktas [" + ld11_terminal_code(id) + "] " + ld11_terminal_name(id), "info", "Spauskite kitą gnybtą. Pakartoję esamo laido galus jį pašalinsite.");
    else
        first = LD11.pending; LD11.pending = "";
        if first <> id then
            existing = 0;
            for row = 1:size(LD11.wires, 1)
                if and(LD11.wires(row,:) == [first id]) | and(LD11.wires(row,:) == [id first]) then existing = row; break; end
            end
            if existing > 0 then
                LD11.wires(existing,:) = []; ld11_set_status("Laidas pašalintas.", "ok", "");
            else
                if sum(LD11.wires == first) >= 2 | sum(LD11.wires == id) >= 2 then
                    ld11_set_status("Gnybte jau yra du laidai.", "error", "Pirma pašalinkite netinkamą laidą.");
                    ld11_render_wires(); return;
                end
                LD11.wires($+1,:) = [first id]; ld11_set_status("Laidas pridėtas.", "ok", "");
            end
            LD11.switchOn = %f; ld11_invalidate_mode();
        end
    end
    ld11_render_wires(); ld11_render_journal(); ld11_student_sync();
endfunction

function ld11_toggle_power()
    global LD11;
    LD11.powerOn = ~LD11.powerOn;
    if ~LD11.powerOn then LD11.switchOn = %f; end
    ld11_render_wires();
    if LD11.powerOn then ld11_set_status("Generatorius įjungtas.", "ok", "Uždarykite jungiklį [B02] ir matuokite [B03].");
    else ld11_set_status("Generatorius išjungtas.", "info", "Galima keisti grandinės laidus."); end
endfunction

function ld11_toggle_switch()
    global LD11;
    if ~LD11.powerOn then ld11_set_status("Pirma įjunkite [B01].", "error", ""); return; end
    LD11.switchOn = ~LD11.switchOn; ld11_render_wires();
    if LD11.switchOn then ld11_set_status("Jungiklis uždarytas.", "ok", "Rodmenis įrašykite [B03].");
    else ld11_set_status("Jungiklis atviras.", "info", ""); end
endfunction

function ld11_set_mode(mode)
    global LD11;
    if LD11.demoMode | ~ld11_valid_index(mode, 2) then return; end
    if mode <> LD11.wireMode then
        LD11.wires_by_mode(LD11.wireMode) = LD11.wires;
        LD11.wireMode = mode; LD11.wires = LD11.wires_by_mode(mode);
        LD11.powerOn = %f; LD11.switchOn = %f; LD11.pending = ""; LD11.lastMeasurement = %nan;
    end
    ld11_render_wires();
    names = ["BE Ck — tik rišlė (R, L)";"SU Ck — kondensatorius lygiagrečiai rišlei"];
    ld11_set_status("Režimas: " + names(mode), "info", "Šio režimo laidai išliko. Seką rasite Pagalboje.");
endfunction

function ld11_measure()
    global LD11;
    if LD11.demoMode then return; end
    if ~or(LD11.step == [2 4]) | LD11.wireMode <> ld11_stage_mode(LD11.step) then
        ld11_set_status("Matuojama 2 ir 4 etapuose atitinkamu režimu.", "error", "Režimą nurodo užduotis."); return;
    end
    [u, i, ok, message, p] = ld11_measure_values();
    if ~ok then ld11_set_status(message, "error", ""); return; end
    tag = LD11.wireMode;
    if ld11_journal_rows(tag) <> [] then
        ld11_set_status("Šis režimas jau išmatuotas.", "info", "Rodmenys išsaugoti žurnale."); return;
    end
    LD11.journal($+1,:) = [u, i, tag, p, tag];
    LD11.report_wires(LD11.wireMode) = LD11.wires;
    LD11.lastMeasurement = i;
    ld11_render_journal(); ld11_render_wires();
    ld11_set_status(msprintf("Užfiksuota: U = %.4f V; I = %.3f mA; P = %.3f mW.", u, i, p), "ok", "Vatmetras rodo aktyviąją galią.");
endfunction

function ok = ld11_close_enough(value, expected, relative, absolute)
    if argn(2) < 3 then relative = .02; end
    if argn(2) < 4 then absolute = 1e-9; end
    ok = %f;
    if isnan(value) | isinf(value) | isnan(expected) | isinf(expected) then return; end
    ok = abs(value - expected) <= absolute + relative*abs(expected);
endfunction

function ld11_check_step(check_answers)
    global LD11;
    if argn(2)<1 then check_answers=%t; end
    if LD11.demoMode then return; end
    ld11_save_answers(); step = LD11.step;
    if ~ld11_valid_index(step, 6) then return; end
    if LD11.done(step) then return; end
    select step
    case 1 then
        if LD11.wireMode <> 1 then ld11_set_status("Pirma sujunkite rišlę [B10].", "error", ""); return; end
        [valid, message] = ld11_wiring_valid(LD11.wires);
        if ~valid then ld11_set_status(message, "error", "Pagalba → Kaip sujungti."); return; end
        LD11.report_wires(1) = LD11.wires;
    case 4 then
        if LD11.wireMode <> 2 then ld11_set_status("Sujungite Ck lygiagrečiai rišlei [B11].", "error", ""); return; end
        [valid, message] = ld11_wiring_valid(LD11.wires);
        if ~valid then ld11_set_status(message, "error", "Pagalba → Kaip sujungti."); return; end
    end
    if or(step == [2 4]) then
        if ld11_journal_rows(ld11_stage_mode(step)) == [] then
            name = "be Ck"; if step == 4 then name = "su Ck"; end
            ld11_set_status("Trūksta matavimo (" + name + ").", "error", "Įjunkite [B01], uždarykite [B02] ir matuokite [B03]."); return;
        end
        if step == 4 then LD11.report_wires(2) = LD11.wires; end
    end
    expected = ld11_expected_answers();
    for index = 1:12
        [answer_step, slot] = ld11_answer_slot(index);
        if answer_step <> step then continue; end
        if ~check_answers then
            if stripblanks(LD11.answers(step,slot))=="" then
                ld11_set_status("Įrašykite ["+ld11_answer_code(step,slot)+"].","error","Atsakymą vertins dėstytojo programa."); return;
            end
            continue;
        end
        value = ld11_parse_number(LD11.answers(step, slot)); relative = .02; absolute = 1e-9;
        if step == 1 | step == 3 then relative = .01; end
        if step == 3 & slot == 1 then relative = .03; end
        if step == 6 then relative = 0; absolute = 0; end
        if ~ld11_close_enough(value, expected(step, slot), relative, absolute) then
            ld11_set_status("Patikrinkite [" + ld11_answer_code(step, slot) + "].", "error", "Peržiūrėkite formulę užduotyje ir vienetus."); return;
        end
    end
    LD11.done(step) = %t; ld11_render_stage();
    text=string(step)+" etapas patikrintas.";
    if ~check_answers then text=string(step)+" etapo atsakymai įrašyti."; end
    ld11_set_status(text, "ok", "");
endfunction

function ld11_next_step()
    global LD11;
    if LD11.step >= 6 | ~LD11.done(LD11.step) then return; end
    ld11_set_step(LD11.step + 1);
endfunction

function ld11_set_step(step)
    global LD11;
    if ~ld11_valid_index(step, 6) then return; end
    if LD11.demoMode then ld11_toggle_solution(); end
    ld11_save_answers(); LD11.pending = ""; LD11.step = step;
    ld11_set_mode(ld11_stage_mode(step)); ld11_render_stage();
endfunction

function text = ld11_step_instruction(step)
    global LD11;
    cfg = LD11.cfg;
    select step
    case 1 then text = msprintf("[B10] Sujungite rišlę be maitinimo: generatorius → jungiklis → ampermetras → rišlė (R, L) → grįžimas. Seka: Pagalba → [B04]. [A01.01] Apskaičiuokite pradinį galios faktorių cos φ0 = R/Z; R = %g Ω, L = %g mH, f = 50 Hz.", cfg.R, cfg.LmH);
    case 2 then text = "Įjunkite [B01], uždarykite [B02] ir matuokite [B03]: žurnale atsiras U, I ir P (vatmetras). [A02.01] S = U·I; [A02.02] Q = √(S²−P²); [A02.03] cos φ = P/S (I — mA, tad S — mVA).";
    case 3 then text = "[A03.01] Apskaičiuokite kompensuojantį kondensatorių: Ck = XL/(ω·(R²+XL²)), ω = 2π·50. Atsakymą rašykite mikrofaradais (µF). Stende Ck paruoštas — tikrinkite [B11].";
    case 4 then text = "[B11] Sujungite Ck lygiagrečiai rišlei (abu nauji laidai). Įjunkite, uždarykite jungiklį ir matuokite [B03]: U2, I2, P2.";
    case 5 then text = "Iš antrojo matavimo: [A05.01] S2 = U·I2; [A05.02] Q2 = √(S2²−P2²); [A05.03] cos φ2 = P2/S2; [A05.04] ΔS = S − S2. Palyginkite S2 < S, I2 < I, cos φ2 > cos φ.";
    case 6 then text = "[A06.01] Ar aktyvioji galia P po kompensacijos nepakito? [A06.02] Ar srovė I sumažėjo? [A06.03] Ar cos φ padidėjo? 1 – Taip, 2 – Ne.";
    else text = "";
    end
endfunction

function ld11_save_answers()
    global LD11;
    if LD11.demoMode | ~isfield(LD11, "ui") then return; end
    if isfield(LD11.ui, "headless") then if LD11.ui.headless then return; end; end
    if ~isfield(LD11.ui, "answerEdits") then return; end
    for index = 1:size(LD11.ui.answerEdits, "*")
        handle = LD11.ui.answerEdits(index);
        if ~is_handle_valid(handle) then continue; end
        [step, slot] = ld11_answer_slot(index);
        if step <> LD11.step | handle.visible <> "on" then continue; end
        if LD11.answers(step, slot) <> handle.string then LD11.done(step) = %f; end
        LD11.answers(step, slot) = handle.string;
    end
endfunction

function [step, slot] = ld11_answer_slot(index)
    mapping = [1 1;2 1;2 2;2 3;3 1;5 1;5 2;5 3;5 4;6 1;6 2;6 3];
    step = mapping(index, 1); slot = mapping(index, 2);
endfunction

function ld11_test_answers(step, values)
    global LD11;
    for index = 1:size(values, "*"); LD11.answers(step, index) = msprintf("%.17g", values(index)); end
endfunction

function ld11_show_wiring_guide()
    global LD11;
    text = ["LD11 · " + names_rezhimas(); ""; "Išjunkite generatorių prieš jungdami laidus."];
    wires = ld11_canonical_wires(LD11.wireMode);
    for index = 1:size(wires, 1)
        text($+1) = msprintf("%d. [%s]–[%s]: %s → %s", index, ld11_terminal_code(wires(index,1)), ld11_terminal_code(wires(index,2)), wires(index,1), wires(index,2));
    end
    text = [text; ""; "Režimas renkamas mygtukais [B10] (be Ck) ir [B11] (su Ck)."; "Vatmetras rodo aktyviąją galią P — jo jungti nereikia."; "Kompensacija: Ck lygiagrečiai rišlei tarp tų pačių mazgų."];
    ld11_text_window("Kaip sujungti", text);
endfunction

function ld11_show_stand_map()
    [ids, callbacks, labels, hints] = ld11_button_registry();
    text = ["LD11 · STENDO ŽEMĖLAPIS";"T01/T02 – generatorius (~, 50 Hz).";"T03/T04 – jungiklis."; ...
        "T05/T06 – ampermetras; T07/T08 – rišlė (R, L)."; "T09/T10 – kondensatorius Ck."; ...
        "Vatmetras P ir voltmetras U — pagalbinės kortelės."; ""];
    for index = 1:size(ids, "*"); text($+1) = "[" + ids(index) + "] " + labels(index); end
    text = [text; ""; "Etapai E01–E06. V02 – dviejų režimų matavimų žurnalas."; ...
        "A01 – pradinis cos φ0; A02 – S, Q, cos φ be Ck."; ...
        "A03 – teorinis Ck; A05 – S2, Q2, cos φ2, ΔS. A06 – išvados."];
    ld11_text_window("Žemėlapis", text);
endfunction

function ld11_text_window(title, lines)
    global LD11;
    if LD11.ui.headless then return; end
    window = figure("figure_name", "LD11 · " + title, "axes_size", [560 420], ...
        "menubar_visible", "off", "toolbar_visible", "off", "infobar_visible", "off");
    uicontrol(window, "style", "listbox", "units", "normalized", "position", [.02 .10 .96 .84], ...
        "string", lines, "fontname", "SansSerif", "fontunits", "pixels", "fontsize", 12);
    uicontrol(window, "style", "pushbutton", "units", "normalized", "position", [.35 .02 .30 .06], ...
        "string", "[H01] Uždaryti", "tag", "H01", "callback", "close()");
endfunction

function ld11_toggle_solution()
    global LD11;
    if LD11.demoMode then
        LD11.demoMode = %f;
        for field = ["wires" "answers" "wireMode" "journal" "powerOn" "switchOn" "lastMeasurement"]
            LD11(field) = LD11.backup(field);
        end
        LD11.pending = ""; ld11_render_stage(); ld11_set_status("Grįžta į savo darbą.", "info", ""); return;
    end
    if LD11.assessment then
        ld11_set_status("Pavyzdys atsiskaitymo režime nepasiekiamas.","error","Perjunkite į Mokymąsi per Pagalbą."); return;
    end
    ld11_save_answers(); LD11.backup = struct();
    for field = ["wires" "answers" "wireMode" "journal" "powerOn" "switchOn" "lastMeasurement"]
        LD11.backup(field) = LD11(field);
    end
    LD11.practice_used = %t; LD11.demoMode = %t; LD11.pending = "";
    LD11.wires = ld11_canonical_wires(LD11.wireMode); LD11.powerOn = %t; LD11.switchOn = %t;
    LD11.journal = [];
    [u, i, ok, message, p] = ld11_measure_values();
    if ok then LD11.journal = [u, i, LD11.wireMode, p, LD11.wireMode]; end
    ld11_render_stage(); ld11_set_status("PAVYZDYS: šio režimo sujungimas ir matavimas.", "info", "Grįžkite į savo darbą pagrindiniu mygtuku.");
endfunction

function ld11_restore_stage()
    global LD11;
    if LD11.demoMode then ld11_toggle_solution(); return; end
    LD11.powerOn = %f; LD11.switchOn = %f; LD11.pending = ""; LD11.lastMeasurement = %nan;
    if ld11_wiring_editable() then
        LD11.wires = emptystr(0, 2); ld11_invalidate_mode();
    end
    ld11_render_stage(); ld11_set_status("Šio etapo stendas atkurtas.", "info", "");
endfunction

function ld11_restart()
    ld11_init_state(); ld11_render_stage(); ld11_set_status("Darbas pradėtas iš naujo.", "info", "Studentas, variantas, režimas ir mokymosi žyma išliko."); bench_autosave("LD11");
endfunction

function ld11_answers_changed()
    ld11_save_answers(); ld11_student_sync(); bench_autosave("LD11");
endfunction

function name = names_rezhimas()
    global LD11;
    if LD11.wireMode == 1 then name = "Rišlė be kondensatoriaus"; else name = "Rišlė su Ck"; end
endfunction
