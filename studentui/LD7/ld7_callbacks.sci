function ld7_invalidate_mode()
    global LD7;
    mode = LD7.wireMode; LD7.report_wires(mode) = emptystr(0, 2);
    if LD7.journal <> [] then
        if mode == 1 then LD7.journal(find(LD7.journal(:,3) <= 5), :) = [];
        else LD7.journal(find(LD7.journal(:,3) == 4 + mode), :) = [];
        end
    end
    select mode
    case 1 then LD7.done([1 2 3 4]) = %f;
    case 2 then LD7.done(5) = %f;
    case 3 then LD7.done(5) = %f;
    end
    LD7.done(6) = %f; LD7.lastMeasurement = %nan;
endfunction

function ld7_terminal_click(id)
    global LD7;
    if ~ld7_wiring_editable() | ~or(ld7_terminal_ids() == id) then return; end
    if LD7.powerOn then
        LD7.pending="";
        ld7_set_status("Prieš keisdami laidus išjunkite maitinimą.", "error", "Maitinimas turi būti išjungtas prieš bet kokį perjungimą.");
        bench_autosave("LD7"); return;
    end
    if LD7.pending == "" then
        LD7.pending = id;
        ld7_set_status("Pasirinktas [" + ld7_terminal_code(id) + "] " + ld7_terminal_name(id), "info", "Spauskite kitą gnybtą. Pakartoję esamo laido galus jį pašalinsite.");
    else
        first = LD7.pending; LD7.pending = "";
        if first <> id then
            existing = 0;
            for row = 1:size(LD7.wires, 1)
                if and(LD7.wires(row,:) == [first id]) | and(LD7.wires(row,:) == [id first]) then existing = row; break; end
            end
            if existing > 0 then
                LD7.wires(existing,:) = []; ld7_set_status("Laidas pašalintas.", "ok", "");
            else
                if sum(LD7.wires == first) >= 2 | sum(LD7.wires == id) >= 2 then
                    ld7_set_status("Gnybte jau yra du laidai.", "error", "Pirma pašalinkite netinkamą laidą.");
                    ld7_render_wires(); bench_autosave("LD7"); return;
                end
                LD7.wires($+1,:) = [first id]; ld7_set_status("Laidas pridėtas.", "ok", "");
            end
            LD7.wires_by_mode(LD7.wireMode) = LD7.wires;
            LD7.switchOn = %f; ld7_invalidate_mode();
        end
    end
    ld7_render_wires(); ld7_render_journal(); ld7_student_sync(); bench_autosave("LD7");
endfunction

function ld7_toggle_power()
    global LD7;
    LD7.powerOn = ~LD7.powerOn;
    if ~LD7.powerOn then LD7.switchOn = %f; end
    ld7_render_wires();
    if LD7.powerOn then ld7_set_status("Maitinimas įjungtas.", "ok", "Darbinėje grandinėje uždarykite jungiklį [B02].");
    else ld7_set_status("Maitinimas išjungtas.", "info", "Galima saugiai keisti šio etapo laidus."); end
    bench_autosave("LD7");
endfunction

function ld7_toggle_switch()
    global LD7;
    if ~LD7.powerOn then ld7_set_status("Pirma įjunkite [B01].", "error", ""); return; end
    LD7.switchOn = ~LD7.switchOn; ld7_render_wires();
    if LD7.switchOn then ld7_set_status("Jungiklis uždarytas.", "ok", "Rodmenis įrašykite [B03].");
    else ld7_set_status("Jungiklis atviras.", "info", ""); end
    bench_autosave("LD7");
endfunction

function ld7_set_mode(mode)
    global LD7;
    if LD7.demoMode | ~ld7_valid_index(mode, 3) then return; end
    if mode <> LD7.wireMode then
        LD7.wires_by_mode(LD7.wireMode) = LD7.wires;
        LD7.wireMode = mode; LD7.wires = LD7.wires_by_mode(mode);
        LD7.powerOn = %f; LD7.switchOn = %f; LD7.pending = ""; LD7.lastMeasurement = %nan;
        if mode <> 1 then LD7.position = 0; end
    end
    ld7_render_wires();
    ld7_set_status("Režimas: " + ld7_mode_name(mode), "info", "Maitinimas išjungtas. Šio režimo laidai išliko; jungimo seką rasite Pagalboje.");
    bench_autosave("LD7");
endfunction

function ld7_set_position(k)
    global LD7;
    if LD7.demoMode | ~ld7_valid_index(k, 5) then return; end
    if LD7.wireMode <> 1 then
        ld7_set_status("Padėtys renkamos tik darbinėje grandinėje.", "info", "");
        return;
    end
    LD7.position = k;
    ld7_render_wires();
    ld7_set_status(msprintf("Padėtis P%d: R = %g Ω.", k, LD7.cfg("R" + string(k))), "info", "Įjungę maitinimą matuokite [B03].");
    bench_autosave("LD7");
endfunction

function ld7_measure()
    global LD7;
    if LD7.demoMode then return; end
    if ~((LD7.step == 2 & LD7.wireMode == 1) | (LD7.step == 5 & or(LD7.wireMode == [2 3]))) then
        ld7_set_status("Matavimai atliekami 2 ir 5 etapuose.", "error", "Pasirinkite užduotyje nurodytą režimą."); return;
    end
    [voltage, current, ok, message, load] = ld7_measure_values();
    if ~ok then ld7_set_status(message, "error", ""); return; end
    if LD7.wireMode == 1 then tag = LD7.position; else tag = 4 + LD7.wireMode; end
    if ld7_journal_rows(tag) <> [] then
        if LD7.wireMode == 1 then
            ld7_set_status(msprintf("Padėtis P%d jau išmatuota.", tag), "info", "Rodmenys išsaugoti žurnale.");
        else
            ld7_set_status("Šis režimas jau išmatuotas.", "info", "Rodmenys išsaugoti žurnale.");
        end
        return;
    end
    LD7.journal($+1,:) = [voltage, current, tag, load, voltage*current];
    LD7.report_wires(LD7.wireMode) = LD7.wires;
    LD7.lastMeasurement = current;
    ld7_render_journal(); ld7_render_wires();
    if LD7.wireMode == 1 then
        ld7_set_status(msprintf("P%d užfiksuota: R = %g Ω; U = %.4f V; I = %.3f mA.", tag, load, voltage, current), "ok", "Galią P3 apskaičiuosite patys iš U ir I.");
    elseif LD7.wireMode == 2 then
        ld7_set_status(msprintf("TE: U0 = %.4f V (srovė ≈ %.4f mA).", voltage, current), "ok", "Tuščiosios eigos įtampa artima šaltinio EV.");
    else
        ld7_set_status(msprintf("Virtualus TJ: Ik = %.3f mA (įtampa ≈ %.4f V).", current, voltage), "ok", "Tai kontroliuojamas virtualus trumpasis jungimas; srovę riboja vidinė varža r.");
    end
    bench_autosave("LD7");
endfunction

function ok = ld7_close_enough(value, expected, relative, absolute)
    if argn(2) < 3 then relative = .02; end
    if argn(2) < 4 then absolute = 1e-9; end
    ok = %f;
    if isnan(value) | isinf(value) | isnan(expected) | isinf(expected) then return; end
    ok = abs(value - expected) <= absolute + relative*abs(expected);
endfunction

function ld7_check_step(check_answers)
    global LD7;
    if argn(2)<1 then check_answers=%t; end
    if LD7.demoMode then return; end
    ld7_save_answers(); step = LD7.step;
    if ~ld7_valid_index(step, 6) then return; end
    if LD7.done(step) then return; end
    if step == 1 then
        if LD7.wireMode <> 1 then ld7_set_status("Pirma sujunkite darbinę grandinę [B10].", "error", ""); return; end
        [valid, message] = ld7_wiring_valid(LD7.wires);
        if ~valid then ld7_set_status(message, "error", "Pagalba → Kaip sujungti."); return; end
        LD7.report_wires(1) = LD7.wires;
    elseif step == 2 then
        for tag = 1:5
            if ld7_journal_rows(tag) == [] then
                ld7_set_status(msprintf("Trūksta matavimo: padėtis P%d.", tag), "error", "Įjunkite maitinimą, uždarykite jungiklį ir spauskite Matuoti."); return;
            end
        end
    elseif step == 5 then
        for tag = [6 7]
            if ld7_journal_rows(tag) == [] then
                name = "tuščioji eiga"; if tag == 7 then name = "virtualus TJ"; end
                ld7_set_status("Trūksta matavimo: " + name + ".", "error", "Sujunkite atitinkamą grandinę ir spauskite Matuoti."); return;
            end
        end
    end
    expected = ld7_expected_answers();
    for index = 1:8
        [answer_step, slot] = ld7_answer_slot(index);
        if answer_step <> step then continue; end
        if stripblanks(LD7.answers(step,slot))=="" then
            ld7_set_status("Įrašykite [" + ld7_answer_code(step, slot) + "].", "error", "Atsakymą vertins dėstytojo programa."); return;
        end
        if step == 6 & ~or(stripblanks(LD7.answers(step,slot)) == ["1" "2"]) then
            ld7_set_status("Pasirinkite Taip arba Ne.", "error", "Išvadas pasirinkite iš sąrašo."); return;
        end
        // Catch syntax errors, not wrong physics: assessment must still keep
        // valid numeric answers even when their calculated values are incorrect.
        if step <> 6 then
            parsed = ld7_parse_number(LD7.answers(step,slot));
            if isnan(parsed) | isinf(parsed) then
                ld7_set_status("Įrašykite skaičių.", "error", "Naudokite kablelį arba tašką. Vieneto ir formulės į atsakymo lauką nerašykite."); return;
            end
        end
        if ~check_answers then continue; end
        value = ld7_parse_number(LD7.answers(step, slot)); relative = .02; absolute = 1e-9;
        if step == 3 then if slot == 1 then relative = .03; else relative = .01; end; end
        if step == 6 then relative = 0; absolute = 0; end
        reference = expected(step, slot);
        // Match C++ marking: a physically acceptable rounded r is used
        // consistently in dependent calculations, not penalized twice.
        if (step == 3 & slot == 2) | (step == 4 & slot == 2) then
            r_used = ld7_parse_number(LD7.answers(3,1));
            if ~isnan(r_used) & r_used > 0 then
                if ld7_close_enough(r_used,LD7.cfg.r,.03,1e-9) then
                    if step == 3 then
                        first = ld7_reference(1,1);
                        reference = first(2)*r_used/1000;
                    else
                        reference = 1000*LD7.cfg.E^2/(4*r_used);
                    end
                end
            end
        end
        if ~ld7_close_enough(value, reference, relative, absolute) then
            ld7_set_status("Patikrinkite [" + ld7_answer_code(step, slot) + "].", "error", "Peržiūrėkite formules užduotyje ir vienetus (mA, mW)."); return;
        end
    end
    LD7.done(step) = %t; ld7_render_stage();
    if check_answers then ld7_set_status(string(step) + " etapas patikrintas.", "ok", "");
    else ld7_set_status(string(step) + " etapo atsakymai įrašyti.", "ok", "Teisingumą vertins dėstytojo programa."); end
endfunction

function ld7_next_step()
    global LD7;
    if LD7.step >= 6 | ~LD7.done(LD7.step) then return; end
    ld7_set_step(LD7.step + 1);
endfunction

function ld7_set_step(step)
    global LD7;
    if ~ld7_valid_index(step, 6) then return; end
    if LD7.demoMode then ld7_toggle_solution(); end
    ld7_save_answers(); LD7.pending = ""; LD7.step = step;
    ld7_set_mode(ld7_stage_mode(step)); ld7_render_stage(); bench_autosave("LD7");
endfunction

function text = ld7_step_instruction(step)
    global LD7;
    cfg = LD7.cfg;
    select step
    case 1 then text = msprintf("Be maitinimo sujunkite: šaltinis → jungiklis → ampermetras → reostatas → šaltinis. Voltmetrą prijunkite prie reostato. Jungimo seką rasite Pagalboje. E = %g V.", cfg.E);
    case 2 then text = "Įjunkite maitinimą ir uždarykite jungiklį. Paeiliui parinkite P1–P5 ir kiekvienoje padėtyje spauskite Matuoti. Penki U ir I rodmenys automatiškai išliks žurnale.";
    case 3 then text = "Iš P1 ir P5 rodmenų apskaičiuokite r = 1000·(U5−U1)/(I1−I5), Ω. Tada raskite vidinį įtampos kritimą Ur = I1·r/1000, V (I1 žurnale yra mA).";
    case 4 then text = "Iš žurnalo apskaičiuokite P3 = U3·I3, mW. Tada raskite Pmax = 1000·E²/(4r), mW, ir naudingumą η3 = U3/E·100 %. Galių rodmenų perrašyti nereikia.";
    case 5 then text = "Išjunkite maitinimą. Pasirinkite Tuščiąją eigą, sujunkite pagal Pagalbą ir išmatuokite. Pakartokite tik virtualiu TJ režimu. Abu rodmenys įrašomi automatiškai. Realaus šaltinio netrumpinkite.";
    case 6 then text = "Pagal visus matavimus pasirinkite tris išvadas: kada galia didžiausia, koks naudingumas esant R = r ir kodėl dėl srovės mažėja įtampa. Kiekvienai rinkitės Taip arba Ne.";
    else text = "";
    end
endfunction

function ld7_save_answers()
    global LD7;
    if LD7.demoMode | ~isfield(LD7, "ui") then return; end
    if isfield(LD7.ui, "headless") then if LD7.ui.headless then return; end; end
    if ~isfield(LD7.ui, "answerEdits") then return; end
    for index = 1:size(LD7.ui.answerEdits, "*")
        handle = LD7.ui.answerEdits(index);
        if ~is_handle_valid(handle) then continue; end
        [step, slot] = ld7_answer_slot(index);
        if step <> LD7.step | handle.visible <> "on" then continue; end
        raw = handle.string;
        if handle.style == "popupmenu" then
            raw = ""; if handle.value > 1 then raw = string(handle.value-1); end
        end
        if LD7.answers(step, slot) <> raw then LD7.done(step) = %f; end
        LD7.answers(step, slot) = raw;
    end
endfunction

function [step, slot] = ld7_answer_slot(index)
    mapping = [3 1;3 2;4 1;4 2;4 3;6 1;6 2;6 3];
    step = mapping(index, 1); slot = mapping(index, 2);
endfunction

function ld7_test_answers(step, values)
    global LD7;
    for index = 1:size(values, "*"); LD7.answers(step, index) = msprintf("%.17g", values(index)); end
endfunction

function name = ld7_mode_name(mode)
    names = ["Darbinė";"Tuščioji eiga";"Virtualus TJ"]; name = names(mode);
endfunction

function ld7_show_wiring_guide()
    global LD7;
    text = ["LD7 · " + ld7_mode_name(LD7.wireMode); ""; "Išjunkite maitinimą prieš jungdami laidus."];
    wires = ld7_canonical_wires(LD7.wireMode);
    for index = 1:size(wires, 1)
        text($+1) = msprintf("%d. [%s]–[%s]: %s → %s", index, ld7_terminal_code(wires(index,1)), ld7_terminal_code(wires(index,2)), wires(index,1), wires(index,2));
    end
    notes = ["Reostato varža priklauso nuo padėties [B13]–[B17]."];
    if LD7.wireMode == 1 then
        notes = [notes; "Voltmetro zondai visada prie reostato R galų."; "Šaltinio vidinė varža r modeliuojama šaltinio viduje ir lemia U(I), Pmax bei η."];
    elseif LD7.wireMode == 2 then
        notes = [notes; "TE: reostatas ir ampermetras nenaudojami — srovės beveik nėra."; "Šaltinio vidinė varža riboja tik mažą voltmetro srovę."];
    else
        notes = [notes; "TJ šiame stende yra tik virtualus kontroliuojamas scenarijus."; "Ampermetras modelyje pakeičia R, o srovę riboja vidinė r: Ik = 1000·E/r, mA."; "Realiame stende trumpąjį jungimą atlikite tik pagal laboratorijos ir dėstytojo procedūrą su srovės ribojimu."];
    end
    text = [text; ""; notes];
    ld7_text_window("Kaip sujungti", text);
endfunction

function ld7_show_theory()
    global LD7;
    lines = ["LD7 · TEORIJA IR PAAIŠKINIMAI";"";
        "Šaltinio E įtampa dalijasi tarp apkrovos R ir vidinės varžos r.";
        "Ampermetras jungiamas nuosekliai, voltmetras – lygiagrečiai apkrovai.";
        "I (mA) = 1000·E/(R+r). Apkrovos U (V) = E − I(mA)·r/1000.";
        "Galiai: P (mW) = U(V)·I(mA). Naudingumui: η (%) = 100·U/E.";
        "Tuščioji eiga: apkrovos srovė labai maža; TJ tik virtualus.";
        "Matavimo žurnalo rodmenis perrašinėti nereikia.";""];
    select LD7.step
    case 1 then
        lines=[lines;"DABARTINIS ETAPAS · JUNGIMAS";
            "Junkite laidus išjungę maitinimą. Pirma sujunkite srovės kelią,";
            "tada voltmetro zondus prie apkrovos. Pagalboje rasite kontaktus."];
    case 2 then
        lines=[lines;"DABARTINIS ETAPAS · PENKI MATAVIMAI";
            "Kiekvienoje P1–P5 padėtyje vieną kartą paspauskite Matuoti.";
            "Stebėkite: didėjant reostato varžai, srovė ir apkrovos įtampa kinta.";
            "Matavimai saugomi žurnale automatiškai."];
    case 3 then
        lines=[lines;"DABARTINIS ETAPAS · VIDINĖ VARŽA";
            "Palyginkite du to paties šaltinio matavimo taškus P1 ir P5.";
            "r = 1000·(U5−U1)/(I1−I5) (Ω), kai srovė I rodoma mA.";
            "Vidinės varžos įtampos kritimas Ur = I1·r/1000 (V).";
            "Įrašykite skaičius, ne formules ar matavimo vienetus."];
    case 4 then
        lines=[lines;"DABARTINIS ETAPAS · GALIA";
            "Naudokite savus P3 matavimus ir 3 etape nustatytą r.";
            "P3 = U3·I3 (mW), Pmax = 1000·E²/(4r) (mW).";
            "η3 = 100·U3/E (%). Nereikia kopijuoti žurnalo rodmenų."];
    case 5 then
        lines=[lines;"DABARTINIS ETAPAS · SPECIALIEJI REŽIMAI";
            "Maitinimą prieš perjungimą išjunkite. Pakeiskite laidus.";
            "Tuščiojoje eigoje registruojama U0; virtualiame TJ – Ik.";
            "Tai kompiuterinis modelis, ne realaus šaltinio trumpinimo instrukcija."];
    case 6 then
        lines=[lines;"DABARTINIS ETAPAS · IŠVADOS";
            "Palyginkite penkis P1–P5 matavimo taškus.";
            "Svarbu galios maksimumas, naudingumas ir vidinės varžos vaidmuo.";
            "Pasirinkite Taip arba Ne, remdamiesi savais rodmenimis."];
    end
    ld7_text_window("Teorija ir paaiškinimai",lines);
endfunction

function ld7_show_stand_map()
    [ids, callbacks, labels, hints] = ld7_button_registry();
    text = ["LD7 · STENDO ŽEMĖLAPIS";"T01/T02 – šaltinis E (+ ir −).";"T03/T04 – jungiklis."; ...
        "T05/T06 – ampermetras; T07/T08 – reostatas R."; "T09/T10 – voltmetro zondai. Ženklai rodo poliškumą."; ""];
    for index = 1:size(ids, "*"); text($+1) = "[" + ids(index) + "] " + labels(index); end
    text = [text; ""; "Etapai E01–E06. V02 – matavimų žurnalas."; ...
        "A03.01/A03.02 – vidinė varža ir vidinis įtampos kritimas."; ...
        "A04.01–A04.03 – galia ir naudingumas."; ...
        "5 etapas – automatiniai TE ir virtualaus TJ rodmenys."; ...
        "A06.01–A06.03 – išvados."];
    ld7_text_window("Žemėlapis", text);
endfunction

function ld7_text_window(title, lines)
    global LD7;
    if LD7.ui.headless then return; end
    window = figure("figure_name", "LD7 · " + title, "axes_size", [560 420], ...
        "menubar_visible", "off", "toolbar_visible", "off", "infobar_visible", "off");
    uicontrol(window, "style", "listbox", "units", "normalized", "position", [.02 .10 .96 .84], ...
        "string", lines, "fontname", "SansSerif", "fontunits", "pixels", "fontsize", 12);
    uicontrol(window, "style", "pushbutton", "units", "normalized", "position", [.35 .02 .30 .06], ...
        "string", "[H01] Uždaryti", "tag", "H01", "callback", "close()");
endfunction

function ld7_toggle_solution()
    global LD7;
    if LD7.demoMode then
        LD7.demoMode = %f;
        for field = ["wires" "answers" "wireMode" "journal" "powerOn" "switchOn" "lastMeasurement" "position"]
            LD7(field) = LD7.backup(field);
        end
        LD7.pending = ""; ld7_render_stage(); ld7_set_status("Grįžta į savo darbą.", "info", ""); bench_autosave("LD7"); return;
    end
    if LD7.assessment then
        ld7_set_status("Pavyzdys atsiskaitymo režime nepasiekiamas.", "error", "Perjunkite į Mokymąsi per Pagalbą."); return;
    end
    ld7_save_answers(); LD7.backup = struct();
    for field = ["wires" "answers" "wireMode" "journal" "powerOn" "switchOn" "lastMeasurement" "position"]
        LD7.backup(field) = LD7(field);
    end
    LD7.practice_used = %t; LD7.demoMode = %t; LD7.pending = "";
    LD7.wires = ld7_canonical_wires(LD7.wireMode); LD7.powerOn = %t; LD7.switchOn = %t;
    LD7.journal = [];
    if LD7.wireMode == 1 then
        for k = 1:5
            LD7.position = k;
            [voltage, current, ok, message, load] = ld7_measure_values();
            if ok then LD7.journal($+1,:) = [voltage, current, k, load, voltage*current]; end
        end
        LD7.position = 3;
    else
        [voltage, current, ok, message, load] = ld7_measure_values();
        if ok then LD7.journal = [voltage, current, 4 + LD7.wireMode, load, voltage*current]; end
    end
    ld7_render_stage(); ld7_set_status("PAVYZDYS: šio režimo sujungimas ir matavimai.", "info", "Grįžkite į savo darbą pagrindiniu mygtuku.");
endfunction

function ld7_restore_stage()
    global LD7;
    if LD7.demoMode then ld7_toggle_solution(); return; end
    LD7.powerOn = %f; LD7.switchOn = %f; LD7.pending = ""; LD7.lastMeasurement = %nan;
    if ld7_wiring_editable() then
        LD7.wires = emptystr(0, 2); LD7.wires_by_mode(LD7.wireMode) = LD7.wires; ld7_invalidate_mode();
    end
    ld7_render_stage(); ld7_set_status("Šio etapo stendas atkurtas; maitinimas išjungtas.", "info", "");
    bench_autosave("LD7");
endfunction

function ld7_restart()
    ld7_init_state(); ld7_render_stage(); ld7_set_status("Darbas pradėtas iš naujo.", "info", "Studentas, variantas, režimas ir mokymosi žyma išliko."); bench_autosave("LD7");
endfunction

function ld7_answers_changed()
    ld7_save_answers(); ld7_student_sync(); bench_autosave("LD7");
endfunction

function ld7_close()
    global LD7;
    if ~isfield(LD7,"fig") then return; end
    if ~is_handle_valid(LD7.fig) then return; end
    if LD7.demoMode then ld7_toggle_solution(); end
    ld7_save_answers(); bench_autosave("LD7");
    if isfield(LD7,"autosave_error") then
        if LD7.autosave_error<>"" then
            ld7_set_status("Nepavyko išsaugoti juodraščio.","error","Langas paliktas atvertas, kad neprarastumėte darbo."); return;
        end
    end
    delete(LD7.fig);
endfunction
