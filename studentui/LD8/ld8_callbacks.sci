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
    if LD8.powerOn then ld8_set_status("Prieš keisdami laidus išjunkite maitinimą.", "error", "Prieš keisdami jungimą, išjunkite šaltinį."); return; end
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
    if LD8.powerOn then ld8_set_status("Maitinimas įjungtas.", "ok", "Uždarykite jungiklį ir spauskite Matuoti.");
    else ld8_set_status("Maitinimas išjungtas.", "info", "Galima keisti šio etapo laidus."); end
endfunction

function ld8_toggle_switch()
    global LD8;
    if ~LD8.powerOn then ld8_set_status("Pirmiausia įjunkite maitinimą.", "error", ""); return; end
    LD8.switchOn = ~LD8.switchOn; ld8_render_wires();
    if LD8.switchOn then ld8_set_status("Jungiklis uždarytas.", "ok", "Spauskite Matuoti – rodmenys išsisaugos automatiškai.");
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
    next = "Matavimas išsaugotas. Spauskite Įrašyti ir toliau.";
    if or(LD8.step == [3 4]) then next = "Apskaičiuokite teorinę varžą Rt ir spauskite Įrašyti ir toliau."; end
    ld8_set_status(msprintf("%s: U = %.4f V; I = %.3f mA.", ld8_mode_name(tag), voltage, current), "ok", next);
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
    for index = 1:9
        [answer_step, slot] = ld8_answer_slot(index);
        if answer_step <> step then continue; end
        raw = stripblanks(LD8.answers(step,slot));
        if raw=="" then
            ld8_set_status(msprintf("Trūksta %d atsakymo.",slot),"error", ...
                "Užpildykite šio etapo lauką; atsakymą dėstytojas įvertins automatiškai."); return;
        end
        if step == 6 then
            if ~or(raw==["1" "2"]) then
                ld8_set_status("Pasirinkite Taip arba Ne.","error","Išvadas pasirinkite iš sąrašo."); return;
            end
        else
            // A mathematical expression is not a number; wrong physics remains
            // acceptable raw evidence in assessment, not a submission blocker.
            parsed=ld8_parse_number(raw);
            if isnan(parsed) | isinf(parsed) then
                ld8_set_status(msprintf("%d atsakymą įrašykite kaip skaičių.",slot),"error", ...
                    "Naudokite tašką arba kablelį. Vieneto ir formulės į lauką nerašykite."); return;
            end
        end
        if ~check_answers then continue; end
        value = ld8_parse_number(raw); relative = .02; absolute = 1e-9;
        if or(step == [2 3 4]) then relative = .01; end
        if step == 6 then relative = 0; absolute = 0; end
        if ~ld8_close_enough(value, expected(step, slot), relative, absolute) then
            ld8_set_status(msprintf("Patikrinkite %d atsakymą.",slot), "error", ...
                "Peržiūrėkite šio etapo formulę Pagalba → Teorija ir paaiškinimai."); return;
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
    case 1 then text = msprintf("1. Be maitinimo sujunkite: šaltinis → jungiklis → ampermetras → R1 → R2 → R3 → šaltinis. Voltmetrą prijunkite prie šaltinio. 2. Įjunkite maitinimą, uždarykite jungiklį, paspauskite Matuoti. E=%g V.",cfg.E);
    case 2 then text = "Iš priskirtų trijų rezistorių reikšmių apskaičiuokite nuosekliosios grandinės teorinę varžą Rt=R1+R2+R3, Ω. Žurnale matavimas jau yra – rodmenų perrašyti nereikia.";
    case 3 then text = "Išjungę maitinimą, sujunkite tris rezistorius lygiagrečiai tarp tų pačių dviejų mazgų. Išmatuokite U ir I. Apskaičiuokite teorinę Rt=1/(1/R1+1/R2+1/R3), Ω.";
    case 4 then text = "Išjungę maitinimą, sujunkite R1 nuosekliai su lygiagrečiais R2 ir R3. Išmatuokite U ir I. Apskaičiuokite teorinę Rt=R1+R2·R3/(R2+R3), Ω.";
    case 5 then text = "Naudodami lygiagrečios grandinės U iš 3 etapo, apskaičiuokite tris šakų sroves: I1=1000·U/R1, I2=1000·U/R2, I3=1000·U/R3 (mA). Patikrinkite: I1+I2+I3≈I bendroji.";
    case 6 then text = "Palyginę tris Rt ir lygiagrečias šakų sroves, atsakykite į tris išvadas. Kiekvienai pasirinkite Taip arba Ne – skaičių rašyti nereikia.";
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
        raw=handle.string;
        if handle.style=="popupmenu" then
            raw=""; if handle.value>1 then raw=string(handle.value-1);end
        end
        if LD8.answers(step, slot) <> raw then LD8.done(step) = %f; end
        LD8.answers(step, slot) = raw;
    end
endfunction

function [step, slot] = ld8_answer_slot(index)
    mapping = [2 1;3 1;4 1;5 1;5 2;5 3;6 1;6 2;6 3];
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
        text($+1) = msprintf("%d. %s → %s   [%s–%s]",index,ld8_contact_short(wires(index,1)), ...
            ld8_contact_short(wires(index,2)),ld8_terminal_code(wires(index,1)),ld8_terminal_code(wires(index,2)));
    end
    notes = ["Voltmetro zondus visada junkite prie šaltinio + ir − gnybtų."];
    if LD8.wireMode == 2 then
        notes = [notes; "Lygiagrečiai: kiekviena varža jungiama tarp tų pačių dviejų mazgų."; "Tarpinis taškas turės du laidus — tai normalu."];
    elseif LD8.wireMode == 3 then
        notes = [notes; "Mišriai: R2 ir R3 lygiagrečiai, jų pora nuosekliai su R1."; "Bendras R2·R3 mazgas turės po du laidus."];
    else
        notes = [notes; "Nuosekliai: grandinė eina per visas tris varžas viena pakopa."];
    end
    text = [text; ""; notes; ""; "Pakartoję tų pačių gnybtų paspaudimus, laidą pašalinsite."];
    ld8_text_window("Kaip sujungti", text);
endfunction

// Short physical names in hints; registry Txx identifiers remain audit metadata.
function label = ld8_contact_short(id)
    select id
    case "E_P" then label="Šaltinis +";
    case "E_N" then label="Šaltinis −";
    case "K1" then label="Jungiklis 1";
    case "K2" then label="Jungiklis 2";
    case "A_P" then label="Ampermetras +";
    case "A_N" then label="Ampermetras −";
    case "V_P" then label="Voltmetras +";
    case "V_N" then label="Voltmetras −";
    case "R1_A" then label="R1 a";
    case "R1_B" then label="R1 b";
    case "R2_A" then label="R2 a";
    case "R2_B" then label="R2 b";
    case "R3_A" then label="R3 a";
    case "R3_B" then label="R3 b";
    else label=id;
    end
endfunction

function ld8_show_theory()
    global LD8;
    lines=["LD8 · TEORIJA IR PAAIŠKINIMAI";"";
        "Nuosekliai: ta pati srovė teka per visas tris varžas; Rt = R1+R2+R3.";
        "Lygiagrečiai: įtampa visose šakose vienoda; 1/Rt=1/R1+1/R2+1/R3.";
        "Mišriai: pirmiausia R23=R2·R3/(R2+R3), paskui Rt=R1+R23.";
        "Ampermetras matuoja bendrą srovę; voltmetras – šaltinio įtampą.";
        "I(mA)=1000·U(V)/R(Ω). Eksperimentinė Re=1000·U/I_mA.";
        "Rodmenys automatiškai įrašomi į žurnalą ir HTML ataskaitą.";
        "Išbandymų rezultatus reikia suprasti, bet nekopijuoti į atsakymų laukus.";""];

    select LD8.step
    case 1 then
        lines=[lines;"1 ETAPAS · NUOSEKLI GRANDINĖ";
            "Paspauskite dviejų gnybtų poras, kad sujungtumėte vieną laidą.";
            "Išjunkite maitinimą, jei reikės taisyti sujungimą.";
            "Įjungę šaltinį, uždarykite jungiklį ir pasirinkite Matuoti."];
    case 2 then
        lines=[lines;"2 ETAPAS · TEORINĖ VARŽA";
            "Sudėkite savo variantui priskirtas R1, R2 ir R3 reikšmes.";
            "Įrašykite vieną teorinę Rt skaičiumi (Ω), be vieneto.";
            "Matuotų U ir I perrašyti nereikia."];
    case 3 then
        lines=[lines;"3 ETAPAS · LYGIAGRETUS JUNGIMAS";
            "Kiekvienas iš trijų rezistorių jungiamas tarp tų pačių mazgų.";
            "Pirmiausia sujunkite, tada išmatuokite U ir I.";
            "Rt apskaičiuokite sumuodami laidžius 1/R, o ne pačias varžas."];
    case 4 then
        lines=[lines;"4 ETAPAS · MIŠRUS JUNGIMAS";
            "R2 ir R3 lygiagrečiai; jų bendroji varža R23.";
            "R1 prie šios poros sujungtas nuosekliai: Rt=R1+R23.";
            "Atlikite vieną matavimą ir įrašykite vieną teorinę Rt."];
    case 5 then
        lines=[lines;"5 ETAPAS · KIRCHHOFO SROVIŲ DĖSNIS";
            "Naudokite žurnalo U iš lygiagrečios grandinės matavimo.";
            "Apskaičiuokite kiekvienos šakos I1, I2 ir I3 mA.";
            "Patikrinkite jų sumą prieš žurnalo bendrą srovę I."];
    case 6 then
        lines=[lines;"6 ETAPAS · IŠVADOS";
            "Palyginkite nuoseklią, lygiagrečią ir mišrią Rt.";
            "Atskirai įvertinkite, ar šakų srovių suma atitinka bendrą srovę.";
            "Pasirinkite Taip arba Ne, remdamiesi savo rezultatais."];
    end
    ld8_text_window("Teorija ir paaiškinimai",lines);
endfunction

function ld8_show_stand_map()
    [ids, callbacks, labels, hints] = ld8_button_registry();
    text = ["LD8 · STENDO ŽEMĖLAPIS";"T01/T02 – šaltinis E (+ ir −).";"T03/T04 – jungiklis."; ...
        "T05/T06 – ampermetras; T07/T08 – R1."; "T09/T10 – R2; T11/T12 – R3."; ...
        "T13/T14 – voltmetro zondai. Ženklai rodo poliškumą."; ""];
    for index = 1:size(ids, "*"); text($+1) = "[" + ids(index) + "] " + labels(index); end
    text = [text; ""; "Etapai E01–E06. V02 – trijų grandinių žurnalas."; ...
        "A02.01/A03.01/A04.01 – teorinės Rt, matavimai saugomi automatiškai."; ...
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
