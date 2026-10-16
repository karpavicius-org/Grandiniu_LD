function ld9_invalidate_wiring()
    global LD9;
    LD9.report_wires = emptystr(0, 2);
    if LD9.journal <> [] then LD9.journal = []; end
    LD9.done(:) = %f; LD9.lastMeasurement = %nan;
endfunction

function ld9_terminal_click(id)
    global LD9;
    if ~ld9_wiring_editable() | ~or(ld9_terminal_ids() == id) then return; end
    if LD9.powerOn then ld9_set_status("Prieš keisdami laidus išjunkite maitinimą.", "error", ""); return; end
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
    bench_autosave("LD9");
endfunction

function ld9_toggle_power()
    global LD9;
    LD9.powerOn = ~LD9.powerOn;
    if ~LD9.powerOn then LD9.switchOn = %f; end
    ld9_render_wires();
    if LD9.powerOn then ld9_set_status("Generatorius įjungtas.", "ok", "Uždarykite jungiklį ir spauskite Matuoti.");
    else ld9_set_status("Generatorius išjungtas.", "info", "Galima keisti grandinės laidus."); end
endfunction

function ld9_toggle_switch()
    global LD9;
    if ~LD9.powerOn then ld9_set_status("Pirmiausia įjunkite maitinimą.", "error", ""); return; end
    LD9.switchOn = ~LD9.switchOn; ld9_render_wires();
    if LD9.switchOn then ld9_set_status("Jungiklis uždarytas.", "ok", "Spauskite Matuoti – rodmenys išsisaugos automatiškai.");
    else ld9_set_status("Jungiklis atviras.", "info", ""); end
endfunction

function ld9_set_freq(k)
    global LD9;
    if LD9.demoMode | ~ld9_valid_index(k, 3) then return; end
    LD9.freqPoint = k;
    ld9_render_wires();
    names = ["0,5·f0 (žemiau rezonanso)";"f0 (rezonansas)";"2·f0 (aukščiau rezonanso)"];
    ld9_set_status(msprintf("Dažnis: %s — %g Hz.", names(k), ld9_current_frequency()), "info", "Pasirinkite R, L, C arba šaltinio įtampą ir spauskite Matuoti.");
endfunction

function ld9_set_target(t)
    global LD9;
    if LD9.demoMode | ~ld9_valid_index(t, 4) then return; end
    LD9.target = t;
    ld9_render_wires();
    names = ["UR — voltmetras prie R";"UL — voltmetras prie L";"UC — voltmetras prie C";"U — voltmetras prie generatoriaus"];
    ld9_set_status(names(t), "info", "Įjungę maitinimą ir uždarę jungiklį spauskite Matuoti.");
endfunction

function ld9_measure()
    global LD9;
    if LD9.demoMode then return; end
    if ~or(LD9.step == [2 3 4]) then
        ld9_set_status("Matuojama 2, 3 ir 4 etapuose.", "error", "Kiekvienam etapui — savas dažnis ir visi keturi taikiniai."); return;
    end
    kk = [0.5 1 2];
    if LD9.freqPoint <> LD9.step - 1 then
        names = ["0,5·f0";"f0";"2·f0"];
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
    count=0; for t=1:4; if ld9_journal_rows(tag,t)<>[] then count=count+1;end;end
    next="Pasirinkite kitą įtampą ir vėl spauskite Matuoti.";
    if count==4 then next="Visos keturios įtampos išsaugotos. Užpildykite šio etapo atsakymus ir spauskite Toliau.";end
    ld9_set_status(msprintf("Užfiksuota %d iš 4: U = %.4f V; I = %.3f mA.",count,voltage,current),"ok",next);
    bench_autosave("LD9");
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
                names = ["rezistoriaus UR";"ritės UL";"kondensatoriaus UC";"šaltinio U"];
                ld9_set_status(msprintf("Trūksta matavimo: %s šiame dažnio taške.", names(target)), "error", "Pasirinkite nurodytą įtampą ir spauskite Matuoti."); return;
            end
        end
    end
    expected = ld9_expected_answers();
    for index = 1:12
        [answer_step, slot] = ld9_answer_slot(index);
        if answer_step <> step then continue; end
        raw=stripblanks(LD9.answers(step,slot));
        if raw=="" then
            ld9_set_status(msprintf("Trūksta %d atsakymo.",slot),"error","Užpildykite šio etapo lauką."); return;
        end
        if step==6 then
            if ~or(raw==["1" "2"]) then
                ld9_set_status("Pasirinkite Taip arba Ne.","error","Išvadas pasirinkite iš sąrašo."); return;
            end
        else
            parsed=ld9_parse_number(raw);
            if isnan(parsed) | isinf(parsed) then
                ld9_set_status(msprintf("%d atsakymą įrašykite kaip skaičių.",slot),"error", ...
                    "Tinka taškas arba kablelis. Vieneto ir formulės į lauką nerašykite."); return;
            end
        end
        if ~check_answers then continue; end
        value = ld9_parse_number(LD9.answers(step, slot)); relative = .02; absolute = 1e-9;
        if step == 1 then relative = .01; end
        if step == 3 & slot == 1 then relative = .03; end
        if step == 3 & slot == 2 then relative = 0; absolute = .02; end
        if step == 6 then relative = 0; absolute = 0; end
        if ~ld9_close_enough(value, expected(step, slot), relative, absolute) then
            ld9_set_status(msprintf("Patikrinkite %d atsakymą.",slot), "error", "Formulės ir vienetai: Pagalba → Teorija ir paaiškinimai."); return;
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
    case 1 then text = "Be maitinimo sujunkite vieną grandinę: generatorius → jungiklis → ampermetras → R → L → C → generatorius. Apskaičiuokite f0. Laidų seka ir formulė – Pagalboje.";
    case 2 then text = "Pasirinkite 0,5·f0. Įjunkite maitinimą ir uždarykite jungiklį. Paeiliui pasirinkite UR, UL, UC ir U; kiekvieną kartą spauskite Matuoti. Rodmenų perrašyti nereikia.";
    case 3 then text = "Pasirinkite f0 ir išmatuokite tas pačias keturias įtampas. Iš šio taško žurnalo apskaičiuokite kokybę Q=UL/U ir skirtumą UL−UC. Kaip skaičiuoti – Pagalboje.";
    case 4 then text = "Pasirinkite 2·f0 ir išmatuokite UR, UL, UC bei U. Palyginkite su ankstesniais taškais: kas pasikeitė? Rodmenys išsisaugo žurnale.";
    case 5 then text = "Naudokite žurnalo pirmojo taško (0,5·f0) U, I, UR, UL, UC. Apskaičiuokite šešis nurodytus dydžius. Visos formulės ir vienetai – Pagalba → Teorija ir paaiškinimai.";
    case 6 then text = "Remdamiesi trijų taškų matavimais ir teorija, kiekvienai išvadai pasirinkite Taip arba Ne. Atsakę spauskite Toliau, tada Išsaugoti ataskaitą.";
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
        raw=handle.string;
        if handle.style=="popupmenu" then
            raw=""; if handle.value>1 then raw=string(handle.value-1);end
        end
        if LD9.answers(step,slot)<>raw then LD9.done(step)=%f;end
        LD9.answers(step,slot)=raw;
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
        text($+1) = msprintf("%d. [%s]–[%s]: %s → %s", index, ld9_terminal_code(wires(index,1)), ld9_terminal_code(wires(index,2)), ld9_terminal_name(wires(index,1)),ld9_terminal_name(wires(index,2)));
    end
    text = [text; ""; "Voltmetro vietą pasirenkate mygtukais UR, UL, UC, U; zondų laidų jungti nereikia."; "Pasirinkite etape nurodytą dažnį: 0,5·f0, f0 arba 2·f0."];
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
    window = figure("figure_name", "LD9 · " + title, "axes_size", [560 420], ...
        "menubar_visible", "off", "toolbar_visible", "off", "infobar_visible", "off");
    uicontrol(window, "style", "listbox", "units", "normalized", "position", [.02 .10 .96 .84], ...
        "string", wrapped, "fontname", "SansSerif", "fontunits", "pixels", "fontsize", 12);
    uicontrol(window, "style", "pushbutton", "units", "normalized", "position", [.35 .02 .30 .06], ...
        "string", "Uždaryti", "tag", "H01", "callback", "close()");
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
    global LD9;
    if LD9.demoMode then ld9_toggle_solution();end
    ld9_save_answers(); bench_autosave("LD9");
    if isfield(LD9,"autosave_error") then if LD9.autosave_error<>"" then return;end;end
    ld9_init_state(); LD9.assessment=%t; LD9.practice_used=%f;
    LD9.autosave_paths=emptystr(0,1); LD9.autosave_error="";
    ld9_render_stage(); ld9_set_status("Pradėtas naujas atsiskaitymas.","info","Ankstesnis darbas išsaugotas atskirai."); bench_autosave("LD9");
endfunction

function ld9_close()
    global LD9;
    if ~isfield(LD9,"fig") then return;end
    if ~is_handle_valid(LD9.fig) then return;end
    if LD9.demoMode then ld9_toggle_solution();end
    bench_autosave("LD9");
    if isfield(LD9,"autosave_error") then if LD9.autosave_error<>"" then return;end;end
    delete(LD9.fig);
endfunction

function ld9_answers_changed()
    ld9_save_answers(); ld9_student_sync(); bench_autosave("LD9");
endfunction

function lines=ld9_theory_lines(step)
    lines=["LD9 · NUOSEKLI RLC GRANDINĖ"; ...
        "Srovė I ta pati per R, L ir C. Įtampos nėra sudedamos aritmetiškai."; ...
        "Žurnale U – šaltinio įtampa, UR/UL/UC – elementų įtampos (V), I – mA."; ...
        "f0=1/(2π·sqrt(L·C)); L[mH]/1000 → H, C[nF]/10^9 → F."; ...
        "Ties f0 induktyvioji ir talpinė reaktyviosios varžos kompensuojasi."; ...
        "Kokybė Q=UL/U yra be vieneto. Reaktyvioji galia Q matuojama mvar – tai kitas dydis.";""];
    select step
    case 1 then lines=[lines;"1 ETAPAS · SUJUNGIMAS IR DAŽNIS"; ...
        "Laidas: spauskite du jo galus. Pakartoję tą pačią porą laidą pašalinsite."; ...
        "Iš variantui priskirtų L ir C apskaičiuokite f0, pirmiausia paversdami į H ir F."; ...
        "Į lauką įrašykite skaičių Hz vienetais, bet be vieneto ir be formulės."];
    case 2 then lines=[lines;"2 ETAPAS · ŽEMIAU REZONANSO"; ...
        "Pasirinkite 0,5·f0, įjunkite maitinimą ir uždarykite jungiklį."; ...
        "Pasirinkite UR ir Matuoti; tą patį pakartokite UL, UC ir U."; ...
        "I įrašoma kartu su įtampa; papildomo srovės matavimo ar kopijavimo nereikia."];
    case 3 then lines=[lines;"3 ETAPAS · REZONANSAS"; ...
        "Ties f0 išmatuokite keturias įtampas. Naudokite tik šio taško žurnalo eilutę."; ...
        "Kokybė Q=UL/U: padalykite voltus iš voltų; vieneto nėra."; ...
        "Apskaičiuokite UL−UC voltų vienetais. Nedidelis skirtumas gali atsirasti apvalinant."];
    case 4 then lines=[lines;"4 ETAPAS · AUKŠČIAU REZONANSO"; ...
        "Pasirinkite 2·f0 ir vėl išmatuokite UR, UL, UC bei U."; ...
        "Palyginkite trijų dažnių sroves bei ritės ir kondensatoriaus įtampas."];
    case 5 then lines=[lines;"5 ETAPAS · SKAIČIAVIMAI IŠ 0,5·f0 TAŠKO"; ...
        "Imkite U, I, UR, UL, UC iš pirmojo dažnio taško; I žurnale pateikta mA."; ...
        "1. Įtampų trikampis: Utr=sqrt(UR^2+(UL−UC)^2), V."; ...
        "2. Pilnutinė varža: Z=1000·U/I_mA, Ω. Nepamirškite 1000."; ...
        "3. Galios faktorius: cos φ=UR/U (be vieneto)."; ...
        "4. Aktyvioji galia: P=UR·I_mA, mW."; ...
        "5. Reaktyvioji galia: Q=(UL−UC)·I_mA, mvar. Išsaugokite ženklą."; ...
        "6. Pilnutinė galia: S=U·I_mA, mVA."; ...
        "V·mA duoda mW/mvar/mVA, todėl galioms papildomo ×1000 nereikia."; ...
        "Savikontrolė: Utr≈U, P^2+Q^2≈S^2, cos φ≈P/S. Tai ne papildomi įvesties laukai."];
    case 6 then lines=[lines;"6 ETAPAS · IŠVADOS"; ...
        "Įvertinkite fazės poslinkį, UL ir UC santykį bei grandinės pobūdį."; ...
        "Kiekvieną teiginį pasirinkite iš Taip / Ne sąrašo."; ...
        "Atsiskaityme saugomas jūsų pasirinkimas; teisingumą įvertins dėstytojas."];
    end
endfunction

function ld9_show_theory()
    global LD9;
    ld9_text_window("Teorija ir paaiškinimai",ld9_theory_lines(LD9.step));
endfunction
