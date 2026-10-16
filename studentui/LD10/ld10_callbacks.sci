function ld10_invalidate_wiring()
    global LD10;
    LD10.report_wires = emptystr(0, 2);
    if LD10.journal <> [] then LD10.journal = []; end
    LD10.done(:) = %f; LD10.lastMeasurement = %nan;
endfunction

function ld10_terminal_click(id)
    global LD10;
    if ~ld10_wiring_editable() | ~or(ld10_terminal_ids() == id) then return; end
    if LD10.powerOn then ld10_set_status("Prieš keisdami laidus išjunkite maitinimą.", "error", ""); return; end
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
    bench_autosave("LD10");
endfunction

function ld10_toggle_power()
    global LD10;
    LD10.powerOn = ~LD10.powerOn;
    if ~LD10.powerOn then LD10.switchOn = %f; end
    ld10_render_wires();
    if LD10.powerOn then ld10_set_status("Generatorius įjungtas.", "ok", "Uždarykite jungiklį ir spauskite Matuoti.");
    else ld10_set_status("Generatorius išjungtas.", "info", "Galima keisti grandinės laidus."); end
endfunction

function ld10_toggle_switch()
    global LD10;
    if ~LD10.powerOn then ld10_set_status("Pirmiausia įjunkite maitinimą.", "error", ""); return; end
    LD10.switchOn = ~LD10.switchOn; ld10_render_wires();
    if LD10.switchOn then ld10_set_status("Jungiklis uždarytas.", "ok", "Spauskite Matuoti – rodmenys išsisaugos automatiškai.");
    else ld10_set_status("Jungiklis atviras.", "info", ""); end
endfunction

function ld10_set_freq(k)
    global LD10;
    if LD10.demoMode | ~ld10_valid_index(k, 3) then return; end
    LD10.freqPoint = k;
    ld10_render_wires();
    names = ["0,5·f0 (žemiau rezonanso)";"f0 (rezonansas)";"2·f0 (aukščiau rezonanso)"];
    ld10_set_status(msprintf("Dažnis: %s — %g Hz.", names(k), ld10_current_frequency()), "info", "Pasirinkite R, L, C arba šaltinio srovę ir spauskite Matuoti.");
endfunction

function ld10_set_target(t)
    global LD10;
    if LD10.demoMode | ~ld10_valid_index(t, 4) then return; end
    LD10.target = t;
    ld10_render_wires();
    names = ["IR — ampermetras R šakoje";"IL — ampermetras L šakoje";"IC — ampermetras C šakoje";"I — ampermetras pagrindinėje linijoje"];
    ld10_set_status(names(t), "info", "Įjunkite maitinimą, uždarykite jungiklį ir spauskite Matuoti.");
endfunction

function ld10_measure()
    global LD10;
    if LD10.demoMode then return; end
    if ~or(LD10.step == [2 3 4]) then
        ld10_set_status("Matuojama 2, 3 ir 4 etapuose.", "error", "Kiekvienam etapui — savas dažnis ir visi keturi taikiniai."); return;
    end
    kk = [0.5 1 2];
    if LD10.freqPoint <> LD10.step - 1 then
        names = ["0,5·f0";"f0";"2·f0"];
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
    ld10_render_journal(); ld10_render_wires(); bench_autosave("LD10");
    ld10_set_status(msprintf("Užfiksuota: I = %.3f mA; U = %.4f V.", current, voltage), "ok", "Išmatuokite visas keturias sroves šiame dažnio taške.");
endfunction

function ok = ld10_close_enough(value, expected, relative, absolute)
    if argn(2) < 3 then relative = .02; end
    if argn(2) < 4 then absolute = 1e-9; end
    ok = %f;
    if isnan(value) | isinf(value) | isnan(expected) | isinf(expected) then return; end
    ok = abs(value - expected) <= absolute + relative*abs(expected);
endfunction

function ld10_check_step(check_answers)
    global LD10;
    if argn(2)<1 then check_answers=%t; end
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
                names = ["rezistoriaus IR";"ritės IL";"kondensatoriaus IC";"bendrosios srovės I"];
                ld10_set_status(msprintf("Trūksta matavimo: %s šiame dažnio taške.", names(target)), "error", "Pasirinkite nurodytą srovę ir spauskite Matuoti."); return;
            end
        end
    end
    expected = ld10_expected_answers();
    for index = 1:12
        [answer_step, slot] = ld10_answer_slot(index);
        if answer_step <> step then continue; end
        raw=stripblanks(LD10.answers(step,slot));
        if raw=="" then
            ld10_set_status(msprintf("Trūksta %d atsakymo.",slot),"error","Užpildykite šio etapo lauką."); return;
        end
        if step==6 then
            if ~or(raw==["1" "2"]) then
                ld10_set_status("Pasirinkite Taip arba Ne.","error","Išvadas pasirinkite iš sąrašo."); return;
            end
        else
            parsed=ld10_parse_number(raw);
            if isnan(parsed) | isinf(parsed) then
                ld10_set_status(msprintf("%d atsakymą įrašykite kaip skaičių.",slot),"error", ...
                    "Tinka taškas arba kablelis. Vieneto ir formulės į lauką nerašykite."); return;
            end
        end
        if ~check_answers then continue; end
        value = ld10_parse_number(LD10.answers(step, slot)); relative = .02; absolute = 1e-9;
        if step == 1 then relative = .01; end
        if step == 3 & slot == 1 then relative = .03; end
        if step == 3 & slot == 2 then relative = 0; absolute = .02; end
        if step == 6 then relative = 0; absolute = 0; end
        if ~ld10_close_enough(value, expected(step, slot), relative, absolute) then
            ld10_set_status(msprintf("Patikrinkite %d atsakymą.",slot), "error", "Formulės ir vienetai: Pagalba → Teorija ir paaiškinimai."); return;
        end
    end
    LD10.done(step) = %t; ld10_render_stage();
    text=string(step)+" etapas patikrintas.";
    if ~check_answers then text=string(step)+" etapo atsakymai įrašyti."; end
    ld10_set_status(text, "ok", "");
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
    select step
    case 1 then text = "Išjunkite maitinimą ir sujunkite R, L, C šakas tarp tų pačių dviejų mazgų. Apskaičiuokite f0. Laidų seka ir formulė – Pagalboje.";
    case 2 then text = "Pasirinkite 0,5·f0. Įjunkite maitinimą ir uždarykite jungiklį. Paeiliui pasirinkite IR, IL, IC ir I; kiekvieną kartą spauskite Matuoti. Rodmenų perrašyti nereikia.";
    case 3 then text = "Pasirinkite f0 ir išmatuokite tas pačias keturias sroves. Iš šio taško žurnalo apskaičiuokite kokybę Q=IL/I ir skirtumą IL−IC. Formulės – Pagalboje.";
    case 4 then text = "Pasirinkite 2·f0 ir išmatuokite IR, IL, IC bei I. Palyginkite su ankstesniais taškais. Rodmenys išsisaugo žurnale.";
    case 5 then text = "Naudokite žurnalo pirmojo taško (0,5·f0) U, IR, IL, IC ir I. Apskaičiuokite šešis nurodytus dydžius. Formulės ir vienetai – Pagalba → Teorija ir paaiškinimai.";
    case 6 then text = "Remdamiesi trijų taškų matavimais ir teorija, kiekvienai išvadai pasirinkite Taip arba Ne. Atsakę spauskite Toliau, tada Išsaugoti ataskaitą.";
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
        raw=handle.string;
        if handle.style=="popupmenu" then
            raw=""; if handle.value>1 then raw=string(handle.value-1);end
        end
        if LD10.answers(step,slot)<>raw then LD10.done(step)=%f;end
        LD10.answers(step,slot)=raw;
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
        text($+1) = msprintf("%d. [%s]–[%s]: %s → %s", index, ld10_terminal_code(wires(index,1)), ld10_terminal_code(wires(index,2)), ld10_terminal_name(wires(index,1)), ld10_terminal_name(wires(index,2)));
    end
    text = [text; ""; "Srovę pasirenkate IR, IL, IC, I mygtukais; ampermetro laidų keisti nereikia."; "Pasirinkite etape nurodytą dažnį: 0,5·f0, f0 arba 2·f0."; "Lygiagretus jungimas: visos šakos tarp tų pačių dviejų mazgų."];
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
    window = figure("figure_name", "LD10 · " + title, "axes_size", [560 420], ...
        "menubar_visible", "off", "toolbar_visible", "off", "infobar_visible", "off");
    uicontrol(window, "style", "listbox", "units", "normalized", "position", [.02 .10 .96 .84], ...
        "string", wrapped, "fontname", "SansSerif", "fontunits", "pixels", "fontsize", 12);
    uicontrol(window, "style", "pushbutton", "units", "normalized", "position", [.35 .02 .30 .06], ...
        "string", "Uždaryti", "tag", "H01", "callback", "close()");
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
    if LD10.assessment then
        ld10_set_status("Pavyzdys atsiskaitymo režime nepasiekiamas.","error","Perjunkite į Mokymąsi per Pagalbą."); return;
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
    global LD10;
    if LD10.demoMode then ld10_toggle_solution();end
    ld10_save_answers(); bench_autosave("LD10");
    if isfield(LD10,"autosave_error") then if LD10.autosave_error<>"" then return;end;end
    ld10_init_state(); LD10.assessment=%t; LD10.practice_used=%f;
    LD10.autosave_paths=emptystr(0,1); LD10.autosave_error="";
    ld10_render_stage(); ld10_set_status("Pradėtas naujas atsiskaitymas.","info","Ankstesnis darbas išsaugotas atskirai."); bench_autosave("LD10");
endfunction

function ld10_answers_changed()
    ld10_save_answers(); ld10_student_sync(); bench_autosave("LD10");
endfunction

function ld10_close()
    global LD10;
    if ~isfield(LD10,"fig") then return;end
    if ~is_handle_valid(LD10.fig) then return;end
    if LD10.demoMode then ld10_toggle_solution();end
    bench_autosave("LD10");
    if isfield(LD10,"autosave_error") then if LD10.autosave_error<>"" then return;end;end
    delete(LD10.fig);
endfunction

function lines=ld10_theory_lines(step)
    lines=["LD10 · LYGIAGRETĖ RLC GRANDINĖ"; ...
        "R, L ir C šakos prijungtos prie tų pačių dviejų mazgų. Įtampa U visose šakose vienoda."; ...
        "IR – R šakos, IL – L šakos, IC – C šakos srovė; I – bendroji šaltinio srovė."; ...
        "Schemos ampermetras rodo bendrąją I; pasirinkta srovė rodoma laukelyje Matavimai."; ...
        "Žurnale U pateikta V, visos srovės – mA. Srovių moduliai nesudedami aritmetiškai."; ...
        "f0=1/(2π·sqrt(L·C)); L[mH]/1000 → H, C[nF]/10^9 → F."; ...
        "Ties f0 srovės IL ir IC kompensuojasi, todėl bendroji I yra mažiausia ir lygi IR."; ...
        "Kokybė Q=IL/I yra be vieneto. Reaktyvioji galia Q matuojama mvar – tai kitas dydis.";""];
    select step
    case 1 then lines=[lines;"1 ETAPAS · SUJUNGIMAS IR DAŽNIS"; ...
        "Laidas: spauskite du jo galus. Pakartoję tą pačią porą laidą pašalinsite."; ...
        "R, L ir C jungiami lygiagrečiai; laidų seka – Pagalba → Kaip sujungti."; ...
        "Iš variantui priskirtų L ir C apskaičiuokite f0, paversdami į H ir F."; ...
        "Į lauką įrašykite skaičių Hz vienetais, bet be vieneto ir be formulės."];
    case 2 then lines=[lines;"2 ETAPAS · ŽEMIAU REZONANSO"; ...
        "Pasirinkite 0,5·f0, įjunkite maitinimą ir uždarykite jungiklį."; ...
        "Pasirinkite IR ir Matuoti; tą patį pakartokite IL, IC ir bendrajai I."; ...
        "Mygtukai perkelia virtualų ampermetrą; laidų keisti nereikia. U įrašoma kartu."; ...
        "Žemiau f0 IL didesnė už IC: grandinės pobūdis indukcinis."];
    case 3 then lines=[lines;"3 ETAPAS · REZONANSAS"; ...
        "Ties f0 išmatuokite keturias sroves. Naudokite tik šio taško žurnalo eilutę."; ...
        "Kokybė Q=IL/I: padalykite mA iš mA, vieneto nėra."; ...
        "Apskaičiuokite IL−IC mA vienetais. Nedidelis skirtumas galimas apvalinant."; ...
        "IL ir IC gali būti didesnės už I, nes jos yra priešingų fazių ir kompensuojasi."];
    case 4 then lines=[lines;"4 ETAPAS · AUKŠČIAU REZONANSO"; ...
        "Pasirinkite 2·f0 ir vėl išmatuokite IR, IL, IC bei I."; ...
        "Aukščiau f0 IC didesnė už IL: grandinės pobūdis talpinis."; ...
        "Palyginkite I visuose trijuose dažniuose; U išlieka ta pati."];
    case 5 then lines=[lines;"5 ETAPAS · SKAIČIAVIMAI IŠ 0,5·f0 TAŠKO"; ...
        "Imkite U, IR, IL, IC ir I iš pirmojo dažnio taško. Srovės žurnale pateiktos mA."; ...
        "1. Srovių trikampis: Itr=sqrt(IR^2+(IL−IC)^2), mA."; ...
        "2. Pilnutinis laidumas: Y=I_mA/U, mS. mA/V duoda mS; ×1000 nereikia."; ...
        "3. Galios faktorius: cos φ=IR/I (be vieneto)."; ...
        "4. Aktyvioji galia: P=U·IR_mA, mW."; ...
        "5. Reaktyvioji galia: Q=U·(IL_mA−IC_mA), mvar. Išsaugokite ženklą."; ...
        "6. Pilnutinė galia: S=U·I_mA, mVA."; ...
        "V·mA duoda mW/mvar/mVA, todėl galioms papildomo ×1000 nereikia."; ...
        "Savikontrolė: Itr≈I, P^2+Q^2≈S^2, cos φ≈P/S. Tai ne papildomi įvesties laukai."];
    case 6 then lines=[lines;"6 ETAPAS · IŠVADOS"; ...
        "Palyginkite I trijuose dažniuose, IL ir IC rezonanse bei grandinės pobūdį."; ...
        "Kiekvieną teiginį pasirinkite iš Taip / Ne sąrašo."; ...
        "Atsiskaityme saugomas jūsų pasirinkimas; teisingumą įvertins dėstytojas."];
    end
endfunction

function ld10_show_theory()
    global LD10;
    ld10_text_window("Teorija ir paaiškinimai",ld10_theory_lines(LD10.step));
endfunction
