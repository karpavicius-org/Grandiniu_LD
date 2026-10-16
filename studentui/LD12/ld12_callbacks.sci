function ld12_invalidate_mode()
    global LD12;
    mode = LD12.wireMode; LD12.report_wires(mode) = emptystr(0, 2);
    if LD12.journal <> [] then LD12.journal(find(LD12.journal(:,3) == mode), :) = []; end
    select mode
    case 1 then LD12.done([1 2 5]) = %f;
    case 2 then LD12.done([3 4 5]) = %f;
    end
    LD12.done(6) = %f; LD12.lastMeasurement = %nan;
endfunction

function ld12_terminal_click(id)
    global LD12;
    if ~ld12_wiring_editable() | ~or(ld12_terminal_ids() == id) then return; end
    if LD12.powerOn then ld12_set_status("Prieš keisdami laidus išjunkite maitinimą.", "error", ""); return; end
    if LD12.pending == "" then
        LD12.pending = id;
        ld12_set_status("Pasirinktas [" + ld12_terminal_code(id) + "] " + ld12_terminal_name(id), "info", "Spauskite kitą gnybtą. Pakartoję esamo laido galus jį pašalinsite.");
    else
        first = LD12.pending; LD12.pending = "";
        if first <> id then
            existing = 0;
            for row = 1:size(LD12.wires, 1)
                if and(LD12.wires(row,:) == [first id]) | and(LD12.wires(row,:) == [id first]) then existing = row; break; end
            end
            if existing > 0 then
                LD12.wires(existing,:) = []; ld12_set_status("Laidas pašalintas.", "ok", "");
            else
                if sum(LD12.wires == first) >= 2 | sum(LD12.wires == id) >= 2 then
                    ld12_set_status("Gnybte jau yra du laidai.", "error", "Pirma pašalinkite netinkamą laidą.");
                    ld12_render_wires(); return;
                end
                LD12.wires($+1,:) = [first id]; ld12_set_status("Laidas pridėtas.", "ok", "");
            end
            LD12.switchOn = %f; ld12_invalidate_mode();
        end
    end
    ld12_render_wires(); ld12_render_journal(); ld12_student_sync(); bench_autosave("LD12");
endfunction

function ld12_toggle_power()
    global LD12;
    LD12.powerOn = ~LD12.powerOn;
    if ~LD12.powerOn then LD12.switchOn = %f; end
    ld12_render_wires(); bench_autosave("LD12");
    if LD12.powerOn then ld12_set_status("Generatorius įjungtas.", "ok", "Uždarykite jungiklį ir spauskite Matuoti.");
    else ld12_set_status("Generatorius išjungtas.", "info", "Galima keisti grandinės laidus."); end
endfunction

function ld12_toggle_switch()
    global LD12;
    if ~LD12.powerOn then ld12_set_status("Pirma įjunkite maitinimą.", "error", ""); return; end
    LD12.switchOn = ~LD12.switchOn; ld12_render_wires(); bench_autosave("LD12");
    if LD12.switchOn then ld12_set_status("Jungiklis uždarytas.", "ok", "Spauskite Matuoti – rodmenys bus įrašyti į žurnalą.");
    else ld12_set_status("Jungiklis atviras.", "info", ""); end
endfunction

function ld12_set_mode(mode)
    global LD12;
    if LD12.demoMode | ~ld12_valid_index(mode, 2) then return; end
    if mode <> LD12.wireMode then
        LD12.wires_by_mode(LD12.wireMode) = LD12.wires;
        LD12.wireMode = mode; LD12.wires = LD12.wires_by_mode(mode);
        LD12.powerOn = %f; LD12.switchOn = %f; LD12.pending = ""; LD12.lastMeasurement = %nan;
    end
    ld12_render_wires();
    names = ["ŽVAIGŽDĖ — imtuvai tarp linijos ir neutralio";"TRIKAMPIS — imtuvai tarp linijų"];
    ld12_set_status("Režimas: " + names(mode), "info", "Šio režimo laidai išliko. Seka: Pagalba → Kaip sujungti.");
    bench_autosave("LD12");
endfunction

function ld12_set_phase(k)
    global LD12;
    if LD12.demoMode | ~ld12_valid_index(k,3) then return;end
    LD12.phase=k;ld12_render_wires();bench_autosave("LD12");
    ld12_set_status("Matuojamas imtuvas: "+ld12_branch_name(LD12.wireMode,k),"info", ...
        "Kortelėse rodoma šio imtuvo Uf ir If. Matuoti įrašys juos į žurnalą.");
endfunction

function ld12_measure()
    global LD12;
    if LD12.demoMode then return; end
    if ~or(LD12.step == [2 4]) | LD12.wireMode <> ld12_stage_mode(LD12.step) then
        ld12_set_status("Matuojama 2 ir 4 etapuose atitinkamu režimu.", "error", "Režimą nurodo užduotis."); return;
    end
    [u, i, ok, message] = ld12_measure_values();
    if ~ok then ld12_set_status(message, "error", ""); return; end
    if ld12_journal_rows(LD12.wireMode) <> [] then
        ld12_set_status("Šio jungimo matavimas jau yra žurnale.", "info", "Simetriniams imtuvams pakanka vieno matavimo."); return;
    end
    // Režimui užtenka vieno fazės matavimo (simetrinė grandinė); faze rodoma pasirinkta.
    LD12.journal($+1,:) = [u, i, LD12.wireMode, LD12.phase, 0];
    LD12.report_wires(LD12.wireMode) = LD12.wires;
    LD12.lastMeasurement = i;
    ld12_render_journal(); ld12_render_wires(); bench_autosave("LD12");
    ld12_set_status(msprintf("Užfiksuota: Uf = %.4f V; If = %.3f mA (imtuvas R%d).", u, i, LD12.phase), "ok", ...
        "Simetrinėje grandinėje visos trys fazės vienodos.");
endfunction

function ok = ld12_close_enough(value, expected, relative, absolute)
    if argn(2) < 3 then relative = .02; end
    if argn(2) < 4 then absolute = 1e-9; end
    ok = %f;
    if isnan(value) | isinf(value) | isnan(expected) | isinf(expected) then return; end
    ok = abs(value - expected) <= absolute + relative*abs(expected);
endfunction

function ld12_check_step(check_answers)
    global LD12;
    if argn(2)<1 then check_answers=%t; end
    if LD12.demoMode then return; end
    ld12_save_answers(); step = LD12.step;
    if ~ld12_valid_index(step, 6) then return; end
    if LD12.done(step) then return; end
    select step
    case 1 then
        if LD12.wireMode <> 1 then ld12_set_status("Pasirinkite Žvaigždė ir sujunkite imtuvus.", "error", ""); return; end
        [valid, message] = ld12_wiring_valid(LD12.wires);
        if ~valid then ld12_set_status(message, "error", "Pagalba → Kaip sujungti."); return; end
        LD12.report_wires(1) = LD12.wires;
    case 3 then
        if LD12.wireMode <> 2 then ld12_set_status("Pasirinkite Trikampis ir sujunkite imtuvus.", "error", ""); return; end
        [valid, message] = ld12_wiring_valid(LD12.wires);
        if ~valid then ld12_set_status(message, "error", "Pagalba → Kaip sujungti."); return; end
        LD12.report_wires(2) = LD12.wires;
    end
    if or(step == [2 4]) then
        if ld12_journal_rows(ld12_stage_mode(step)) == [] then
            name = "žvaigždė"; if step == 4 then name = "trikampis"; end
            ld12_set_status("Trūksta matavimo (" + name + ").", "error", "Pasirinkite R1, R2 arba R3, įjunkite maitinimą, uždarykite jungiklį ir spauskite Matuoti."); return;
        end
    end
    expected = ld12_expected_answers();
    for index = 1:10
        [answer_step, slot] = ld12_answer_slot(index);
        if answer_step <> step then continue; end
        raw=stripblanks(LD12.answers(step,slot));
        if raw=="" then
            ld12_set_status(msprintf("Trūksta %d atsakymo.",slot),"error","Užpildykite šio etapo lauką."); return;
        end
        if step==6 then
            if ~or(raw==["1" "2"]) then
                ld12_set_status("Pasirinkite Taip arba Ne.","error","Išvadas pasirinkite iš sąrašo."); return;
            end
        else
            parsed=ld12_parse_number(raw);
            if isnan(parsed) | isinf(parsed) then
                ld12_set_status(msprintf("%d atsakymą įrašykite kaip skaičių.",slot),"error", ...
                    "Tinka taškas arba kablelis. Vieneto ir formulės į lauką nerašykite."); return;
            end
        end
        if ~check_answers then continue; end
        value = ld12_parse_number(LD12.answers(step, slot)); relative = .02; absolute = 1e-9;
        if step == 1 | step == 3 then relative = .01; end
        if step == 3 & slot == 1 then relative = 0; absolute = .005; end
        if step == 6 then relative = 0; absolute = 0; end
        if ~ld12_close_enough(value, expected(step, slot), relative, absolute) then
            ld12_set_status(msprintf("Patikrinkite %d atsakymą.",slot), "error", "Formulės ir vienetai: Pagalba → Teorija ir paaiškinimai."); return;
        end
    end
    LD12.done(step) = %t; ld12_render_stage();
    text=string(step)+" etapas patikrintas.";
    if ~check_answers then text=string(step)+" etapo atsakymai įrašyti."; end
    ld12_set_status(text, "ok", "");
endfunction

function ld12_next_step()
    global LD12;
    if LD12.step >= 6 | ~LD12.done(LD12.step) then return; end
    ld12_set_step(LD12.step + 1);
endfunction

function ld12_set_step(step)
    global LD12;
    if ~ld12_valid_index(step, 6) then return; end
    if LD12.demoMode then ld12_toggle_solution(); end
    ld12_save_answers(); LD12.pending = ""; LD12.step = step;
    ld12_set_mode(ld12_stage_mode(step)); ld12_render_stage();
endfunction

function text = ld12_step_instruction(step)
    select step
    case 1 then text="Be maitinimo sujunkite tris imtuvus žvaigžde. Laidų seka: Pagalba → Kaip sujungti. Apskaičiuokite fazinę įtampą Uf = Ul/√3, V.";
    case 2 then text="Pasirinkite imtuvą R1, R2 arba R3. Įjunkite maitinimą, uždarykite jungiklį ir spauskite Matuoti. Apskaičiuokite If = 1000·Uf/R, mA, ir palyginkite su žurnalu.";
    case 3 then text="Sujunkite imtuvus trikampiu: kiekvieną tarp dviejų linijų. Neutralis N nenaudojamas. Laidų seka – Pagalboje. Apskaičiuokite trikampio Uf, V: ji lygi Ul.";
    case 4 then text="Pasirinkite imtuvą, įjunkite maitinimą, uždarykite jungiklį ir spauskite Matuoti. Apskaičiuokite If = 1000·Uf/R, mA. Ampermetras rodo imtuvo, fazinę srovę.";
    case 5 then text="Iš abiejų jungimų matavimų apskaičiuokite trikampio Il ir abiejų jungimų galias. Naudojant I [mA], V·mA duoda mW: papildomo ×1000 nereikia. Formulės – Pagalboje.";
    case 6 then text="Palyginkite žvaigždės ir trikampio sroves bei galias, kai Ul ir R tie patys. Kiekvienam teiginiui pasirinkite Taip arba Ne. Tada išsaugokite ataskaitą.";
    else text="";
    end
endfunction

function ld12_save_answers()
    global LD12;
    if LD12.demoMode | ~isfield(LD12, "ui") then return; end
    if isfield(LD12.ui, "headless") then if LD12.ui.headless then return; end; end
    if ~isfield(LD12.ui, "answerEdits") then return; end
    for index = 1:size(LD12.ui.answerEdits, "*")
        handle = LD12.ui.answerEdits(index);
        if ~is_handle_valid(handle) then continue; end
        [step, slot] = ld12_answer_slot(index);
        if step <> LD12.step | handle.visible <> "on" then continue; end
        raw=handle.string;
        if handle.style=="popupmenu" then
            raw=""; if handle.value>1 then raw=string(handle.value-1);end
        end
        if LD12.answers(step,slot)<>raw then LD12.done(step)=%f;end
        LD12.answers(step,slot)=raw;
    end
endfunction

function [step, slot] = ld12_answer_slot(index)
    mapping = [1 1;2 1;3 1;4 1;5 1;5 2;5 3;6 1;6 2;6 3];
    step = mapping(index, 1); slot = mapping(index, 2);
endfunction

function ld12_test_answers(step, values)
    global LD12;
    for index = 1:size(values, "*"); LD12.answers(step, index) = msprintf("%.17g", values(index)); end
endfunction

function ld12_show_wiring_guide()
    global LD12;
    text = ["LD12 · " + ld12_mode_name(); ""; "Išjunkite trifazį šaltinį prieš jungdami laidus."];
    wires = ld12_canonical_wires(LD12.wireMode);
    for index = 1:size(wires, 1)
        text($+1) = msprintf("%d. [%s]–[%s]: %s → %s", index, ld12_terminal_code(wires(index,1)), ld12_terminal_code(wires(index,2)), ld12_terminal_name(wires(index,1)), ld12_terminal_name(wires(index,2)));
    end
    text = [text; ""; "Jungimą parenka etapas; palyginimui galite rinktis Žvaigždė arba Trikampis."; "R1, R2 ir R3 mygtukai pasirenka matuojamą imtuvą; prietaisų laidų keisti nereikia."; "Žvaigždėje imtuvai tarp linijos ir N; trikampyje – tarp linijų, N nejungiamas."];
    ld12_text_window("Kaip sujungti", text);
endfunction

function ld12_show_stand_map()
    [ids, callbacks, labels, hints] = ld12_button_registry();
    text = ["LD12 · STENDO ŽEMĖLAPIS";"T01/T02/T03 – linijos L1/L2/L3; T04 – neutralis N.";"T05/T06 – R1; T07/T08 – R2; T09/T10 – R3."; ...
        "Matuojamas imtuvas: R1, R2 arba R3 ([B12]–[B14]). Voltmetras ir ampermetras — pagalbinės kortelės."; ""];
    for index = 1:size(ids, "*"); text($+1) = "[" + ids(index) + "] " + labels(index); end
    text = [text; ""; "Etapai E01–E06. V02 – dviejų jungimų matavimų žurnalas."; ...
        "A01 – Uf žvaigždėje; A02 – fazinė srovė žvaigždėje."; ...
        "A03/A04 – trikampio įtampa ir srovė; A05 – Il, PΔ, PY. A06 – išvados."];
    ld12_text_window("Žemėlapis", text);
endfunction

function ld12_text_window(title, lines)
    global LD12;
    if LD12.ui.headless then return; end
    wrapped=emptystr(0,1);
    for line=matrix(lines,1,-1)
        words=tokens(line," ");current="";
        for k=1:size(words,"*")
            if length(current)+length(words(k))+1>72 & current<>"" then
                wrapped($+1)=current;current="";
            end
            if current<>"" then current=current+" ";end
            current=current+words(k);
        end
        wrapped($+1)=current;
    end
    window = figure("figure_name", "LD12 · " + title, "axes_size", [560 420], ...
        "menubar_visible", "off", "toolbar_visible", "off", "infobar_visible", "off");
    uicontrol(window, "style", "listbox", "units", "normalized", "position", [.02 .10 .96 .84], ...
        "string", wrapped, "fontname", "SansSerif", "fontunits", "pixels", "fontsize", 12);
    uicontrol(window, "style", "pushbutton", "units", "normalized", "position", [.35 .02 .30 .06], ...
        "string", "Uždaryti", "tag", "H01", "callback", "close()");
endfunction

function ld12_toggle_solution()
    global LD12;
    if LD12.demoMode then
        LD12.demoMode = %f;
        for field = ["wires" "answers" "wireMode" "journal" "powerOn" "switchOn" "lastMeasurement" "phase"]
            LD12(field) = LD12.backup(field);
        end
        LD12.pending = ""; ld12_render_stage(); ld12_set_status("Grįžta į savo darbą.", "info", ""); return;
    end
    if LD12.assessment then
        ld12_set_status("Pavyzdys atsiskaitymo režime nepasiekiamas.","error","Perjunkite į Mokymąsi per Pagalbą."); return;
    end
    ld12_save_answers(); LD12.backup = struct();
    for field = ["wires" "answers" "wireMode" "journal" "powerOn" "switchOn" "lastMeasurement" "phase"]
        LD12.backup(field) = LD12(field);
    end
    LD12.practice_used = %t; LD12.demoMode = %t; LD12.pending = "";
    LD12.wires = ld12_canonical_wires(LD12.wireMode); LD12.powerOn = %t; LD12.switchOn = %t;
    LD12.journal = [];
    if ~ld12_valid_index(LD12.phase,3) then LD12.phase=1;end
    [u, i, ok, message] = ld12_measure_values();
    if ok then LD12.journal = [u, i, LD12.wireMode, LD12.phase, 0]; end
    ld12_render_stage(); ld12_set_status("PAVYZDYS: šio režimo sujungimas ir matavimas.", "info", "Grįžkite į savo darbą pagrindiniu mygtuku.");
endfunction

function ld12_restore_stage()
    global LD12;
    if LD12.demoMode then ld12_toggle_solution(); return; end
    LD12.powerOn = %f; LD12.switchOn = %f; LD12.pending = ""; LD12.lastMeasurement = %nan;
    if ld12_wiring_editable() then
        LD12.wires = emptystr(0, 2); ld12_invalidate_mode();
    end
    ld12_render_stage(); ld12_set_status("Šio etapo stendas atkurtas.", "info", ""); bench_autosave("LD12");
endfunction

function ld12_restart()
    global LD12;
    if LD12.demoMode then ld12_toggle_solution();end
    ld12_save_answers(); bench_autosave("LD12");
    if isfield(LD12,"autosave_error") then if LD12.autosave_error<>"" then return;end;end
    ld12_init_state(); LD12.assessment=%t; LD12.practice_used=%f;
    LD12.autosave_paths=emptystr(0,1); LD12.autosave_error="";
    ld12_render_stage(); ld12_set_status("Pradėtas naujas atsiskaitymas.","info","Ankstesnis darbas išsaugotas atskirai."); bench_autosave("LD12");
endfunction

function ld12_answers_changed()
    ld12_save_answers(); ld12_student_sync(); bench_autosave("LD12");
endfunction

function name = ld12_mode_name()
    global LD12;
    if LD12.wireMode == 1 then name = "Žvaigždė"; else name = "Trikampis"; end
endfunction

function ld12_close()
    global LD12;
    if ~isfield(LD12,"fig") then return;end
    if ~is_handle_valid(LD12.fig) then return;end
    if LD12.demoMode then ld12_toggle_solution();end
    bench_autosave("LD12");
    if isfield(LD12,"autosave_error") then if LD12.autosave_error<>"" then return;end;end
    delete(LD12.fig);
endfunction

function name=ld12_branch_name(mode,branch)
    name="—";if ~ld12_valid_index(branch,3) then return;end
    ends=["L1–N";"L2–N";"L3–N"];
    if mode==2 then ends=["L1–L2";"L2–L3";"L3–L1"];end
    name="R"+string(branch)+" · "+ends(branch);
endfunction

function lines=ld12_theory_lines(step)
    global LD12;
    cfg=LD12.cfg;
    lines=["LD12 · ŽVAIGŽDĖ IR TRIKAMPIS"; ...
        msprintf("Jūsų variantas: linijinė Ul=%g V; kiekvienas imtuvas R=%g Ω; f=50 Hz.",cfg.Ul,cfg.R); ...
        "Trys vienodi rezistoriai – simetrinė aktyvioji apkrova. cos φ=1. Rodmenys yra efektinės RMS vertės."; ...
        "Ul – įtampa tarp dviejų linijų. Uf – įtampa vieno imtuvo galuose."; ...
        "If – srovė per vieną imtuvą. Il – srovė viename šaltinio linijos laide."; ...
        "R1 / R2 / R3 pasirenka matuojamą imtuvą. Voltmetras rodo jo Uf, ampermetras – jo If."; ...
        "Įmontuoto bendro trifazio jungiklio ir prietaisų atskirais laidais jungti nereikia."; ...
        "Matuoti automatiškai įrašo Uf [V] ir If [mA]. Simetrinei grandinei užtenka vieno imtuvo matavimo kiekviename jungime."; ...
        "Į laukus rašykite skaičius, be vieneto ir be formulės. Tinka taškas arba kablelis.";""];
    select step
    case 1 then lines=[lines;"1 ETAPAS · SUJUNGIMAS ŽVAIGŽDE"; ...
        "Išjungę maitinimą sujunkite šešis laidus pagal Pagalba → Kaip sujungti."; ...
        "R1, R2 ir R3 pradžios jungiamos prie L1, L2 ir L3; galai sujungiami kartu ir prie N."; ...
        "Laidui pridėti spauskite abu jo gnybtus; pakartoję tą pačią porą laidą pašalinsite."; ...
        "Uf=Ul/√3 [V]. Pavyzdžiui, naudokite šaltinyje nurodytą Ul, ne kitą įtampą."];
    case 2 then lines=[lines;"2 ETAPAS · ŽVAIGŽDĖS MATAVIMAS"; ...
        "Pasirinkite R1, R2 arba R3, įjunkite maitinimą, uždarykite jungiklį ir spauskite Matuoti."; ...
        "Pasirinkus R1 matuojama tarp L1–N; R2 – L2–N; R3 – L3–N."; ...
        "Žurnale – virtualaus prietaiso rodmuo. Atsakymo lauke apskaičiuokite If=1000·Uf/R [mA]."; ...
        "Uf[V]/R[Ω] duoda A, todėl srovei mA vienetais reikia ×1000."; ...
        "Žvaigždėje If=Il. Palyginkite skaičiavimą su ampermetro ir žurnalo rodmeniu."];
    case 3 then lines=[lines;"3 ETAPAS · SUJUNGIMAS TRIKAMPIU"; ...
        "Etapas išjungia maitinimą ir parenka atskirą trikampio sujungimą. Žvaigždės laidai išsaugoti palyginimui."; ...
        "Šeši laidai sujungia R1 tarp L1–L2, R2 tarp L2–L3 ir R3 tarp L3–L1."; ...
        "Neutralis N trikampyje nejungiamas. Visa laidų seka – Pagalba → Kaip sujungti."; ...
        "Trikampyje kiekvienas imtuvas prijungtas tarp dviejų linijų, todėl Uf=Ul [V]."];
    case 4 then lines=[lines;"4 ETAPAS · TRIKAMPIO MATAVIMAS"; ...
        "Pasirinkite imtuvą, įjunkite maitinimą, uždarykite jungiklį ir spauskite Matuoti."; ...
        "R1 matuojamas tarp L1–L2; R2 – L2–L3; R3 – L3–L1."; ...
        "Apskaičiuokite If=1000·Uf/R [mA], kur Uf=Ul. Palyginkite su matavimu."; ...
        "Ampermetras rodo fazinę srovę If per rezistorių. Linijinė srovė Il čia yra kitas dydis, ją skaičiuosite 5 etape."];
    case 5 then lines=[lines;"5 ETAPAS · LINIJINĖ SROVĖ IR GALIA"; ...
        "Imkite abiejų jungimų Uf [V], If [mA] iš žurnalo; Ul [V] – iš šaltinio arba priskirtų reikšmių."; ...
        "1. Trikampio linijinė srovė: Il=√3·If_TRIKAMPIS [mA]."; ...
        "Fazorių skirtumas duoda √3·If, o ne 2·If: gretimų šakų srovės skiriasi faze."; ...
        "2. Trikampio galia: PΔ=√3·Ul·Il [mW]. Patikra kitu keliu: PΔ=3·Uf_TRIKAMPIS·If_TRIKAMPIS."; ...
        "3. Žvaigždės galia: PY=3·Uf_ŽVAIGŽDĖ·If_ŽVAIGŽDĖ [mW]."; ...
        "V·mA duoda mW: šioms galios formulėms papildomo ×1000 nereikia."; ...
        "Neapvalinkite tarpinių rezultatų. Savikontrolė: PΔ/PY≈3, kai tie patys Ul ir R."];
    case 6 then lines=[lines;"6 ETAPAS · IŠVADOS"; ...
        "Palyginkite jungimus: žvaigždėje If=Il; trikampyje Il=√3·If."; ...
        "Esant tam pačiam Ul ir tiems patiems trims R, trikampio galia tris kartus didesnė."; ...
        "Kiekvienam teiginiui pasirinkite Taip arba Ne. Atsiskaityme saugomas jūsų pasirinkimas."; ...
        "Užbaigę šešis etapus išsaugokite ataskaitą. Teisingumą įvertins dėstytojo programa."];
    end
endfunction

function ld12_show_theory()
    global LD12;
    ld12_text_window("Teorija ir paaiškinimai",ld12_theory_lines(LD12.step));
endfunction
