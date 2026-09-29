// ============================================================================
// LD3 veiksmų logika: laidai, matavimai, etapų tikrinimas, pagalbiniai langai.
// ============================================================================

function ld3_terminal_click(id)
    global LD3;
    if LD3.demoMode then ld3_set_status("Pavyzdyje laidai jau sujungti.","info","Grįžkite paspaudę [B07]."); return; end
    if LD3.step ~= 1 & ~LD3.done(1) then
        ld3_set_status("Pirmiausia užbaikite 1 etapo sujungimą.","error","Mygtuku ← Atgal grįžkite į 1 etapą.");
        return;
    end
    if LD3.pending == "" then
        LD3.pending = id;
        ld3_set_status("Pasirinktas [T" + part(ld3_terminal_code(id), 2:3) + "] " + ld3_terminal_name(id) + ".","info","Dabar spauskite antrąjį sujungiamo gnybtą.");
    else
        if id == LD3.pending then
            LD3.pending = "";
            ld3_set_status("Pasirinkimas atšauktas.","info","");
            return;
        end
        // Gnybtas talpina ne daugiau 2 laidų (zondai prispaudžiami ant rezistoriaus gnybtų).
        uses = 0;
        for m = 1:size(LD3.wires, 1)
            if LD3.wires(m,1) == id | LD3.wires(m,2) == id then uses = uses + 1; end
        end
        if uses >= 2 then
            LD3.pending = "";
            ld3_set_status("Gnybtas [T" + part(ld3_terminal_code(id), 2:3) + "] jau su dviem laidais.","error","Zondus prispauskite ant rezistoriaus gnybtų; čia vietos nėra.");
            return;
        end
        LD3.wires($+1, :) = [LD3.pending, id];
        LD3.pending = "";
        ld3_set_status("Laidas pridėtas (" + string(size(LD3.wires,1)) + "/6).","ok","");
        if size(LD3.wires, 1) >= 6 then
            [wok, wwhy] = ld3_wiring_valid(LD3.wires);
            if wok then ld3_set_status("Sujungimas teisingas! Galima tikrinti 1 etapą.","ok","Spauskite apatinį TIKRINTI mygtuką."); end
        end
    end
    if isfield(LD3, "ui") then
        if ~isfield(LD3.ui, "headless") | ~LD3.ui.headless then ld3_render_wires(); end
    end
    bench_autosave("LD3");
endfunction

function ld3_toggle_power()
    global LD3;
    LD3.powerOn = ~LD3.powerOn;
    if LD3.powerOn then
        ld3_set_status("[B01] Maitinimas įJUNGTAS.","ok","Dabar uždarykite jungiklį [B02].");
    else
        ld3_set_status("[B01] Maitinimas iŠJUNGTAS.","info","Įtampa nustatoma mygtukais [B10]–[B12].");
    end
    ld3_render_wires(); bench_autosave("LD3");
endfunction

function ld3_toggle_switch()
    global LD3;
    if ~LD3.powerOn then
        ld3_set_status("Negalima jungti be maitinimo.","error","Pirmiausia [B01] MAITINIMAS.");
        return;
    end
    LD3.switchOn = ~LD3.switchOn;
    if LD3.switchOn then ld3_set_status("[B02] Jungiklis UŽDARYTAS.","ok","Nustatykite įtampą [B10]–[B12] ir matuokite [B03]."); end
    ld3_render_wires(); bench_autosave("LD3");
endfunction

function ld3_set_voltage(v)
    global LD3;
    if argn(2) < 1 then v = 0; end
    LD3.voltage = max(0, min(12, round(v)));
    if isfield(LD3, "ui") then
        if isfield(LD3.ui, "headless") then
            if LD3.ui.headless then bench_autosave("LD3"); return; end
        end
        if isfield(LD3.ui, "voltLabel") & is_handle_valid(LD3.ui.voltLabel) then
            LD3.ui.voltLabel.string = msprintf("%d V", LD3.voltage);
        end
        if isfield(LD3.ui, "voltSlider") & is_handle_valid(LD3.ui.voltSlider) then
            LD3.ui.voltSlider.value = LD3.voltage;
        end
        ld3_render_wires();
    end
    bench_autosave("LD3");
endfunction

function ld3_measure()
    global LD3;
    [u, i, ok, msg] = ld3_measure_values();
    if ~ok then ld3_set_status(msg, "error", ""); return; end
    if LD3.step ~= 2 & LD3.step ~= 3 then
        ld3_set_status("Matavimai atliekami 2 ir 3 etapuose.","info","Etapą rodo skaičius viršuje; grįžkite mygtuku ← Atgal.");
        return;
    end
    jeigu = %t;
    // Taškas jau užfiksuotas šiam įtampos lygiui?
    for m = 1:size(LD3.journal, 1)
        if abs(LD3.journal(m,1) - u) < 1e-9 then jeigu = %f; end
    end
    if ~jeigu then
        ld3_set_status("Šis įtampos taškas jau užfiksuotas.","error","Nustatykite kitą reikšmę mygtuku [B11] ar [B12].");
        return;
    end
    if size(LD3.journal, 1) >= 3 then
        ld3_set_status("Visi trys taškai jau užfiksuoti.","info","Eikite toliau.");
        return;
    end
    LD3.journal($+1, :) = [u, i];
    LD3.lastMeasurement = i;
    ld3_set_status(msprintf("Užfiksuota: U = %g V, I = %.2f mA (%d/3 taškai).", u, i, size(LD3.journal,1)), "ok", ...
        msprintf("Rodmuo matomas [V02] lange ir matavimų sąraše."));
    if isfield(LD3, "ui") then
        if ~isfield(LD3.ui, "headless") | ~LD3.ui.headless then ld3_render_journal(); ld3_render_wires(); end
    end
    bench_autosave("LD3");
endfunction

function ok = ld3_close_enough(userValue, expectedValue)
    global LD3;
    if isnan(userValue) | isnan(expectedValue) then ok = %f; return; end
    scale = max([abs(expectedValue), 1e-9]);
    ok = abs(userValue - expectedValue) <= 0.02 * scale;
endfunction

function ld3_check_step(check_answers)
    global LD3;
    if argn(2)<1 then check_answers=%t; end
    n = LD3.step;
    if LD3.done(n) then ld3_set_status("Etapas jau atliktas.","ok","Spauskite TOLIAU."); return; end
    select n
    case 1 then
        [wok, wwhy] = ld3_wiring_valid(LD3.wires);
        if ~wok then ld3_set_status(wwhy, "error", "Seką rasite: Pagalba → [B04] Kaip sujungti."); return; end
        LD3.done(1) = %t;
        ld3_set_status("1 etapas baigtas: stendas sujungtas teisingai.","ok","[E02] atveria teorinę prognozę.");
    case 2 then
        if stripblanks(LD3.answers(2,1))=="" then
            ld3_set_status("Įrašykite teorinę srovę [A02.01], mA.","error","Atsakymą vertins dėstytojo programa."); return;
        end
        if check_answers then
            v = ld3_parse_number(LD3.answers(2,1));
            e = LD3.cfg.U1 / LD3.cfg.R * 1000;
            if isnan(v) then ld3_set_status("Įrašykite skaitinę teorinę srovę [A02.01], mA.","error","I = U1 / R · 1000."); return; end
            if ~ld3_close_enough(v, e) then
                ld3_set_status("Teorinė srovė [A02.01] netiksli.","error",msprintf("Tikimasi ≈ %.2f mA (I = U1/R·1000).", e)); return; end
        end
        if size(LD3.journal,1) < 1 then
            ld3_set_status("Trūksta pirmo matavimo.","error","Spauskite [B10] U1 ir [B03] MATUOTI."); return; end
        LD3.done(2) = %t;
        ld3_set_status("2 etapas baigtas.","ok","[E03] — dar du taškai.");
    case 3 then
        if size(LD3.journal,1) < 3 then
            truksta = 3 - size(LD3.journal,1);
            ld3_set_status("Trūksta " + string(truksta) + " matavimo taškų.","error","Nustatykite [B11] U2 / [B12] U3 ir [B03] MATUOTI."); return; end
        LD3.done(3) = %t;
        ld3_set_status("3 etapas baigtas: trys taškai užfiksuoti.","ok","[E04] — skaičiavimai.");
    case 4 then
        exp = ld3_expected_answers();
        for k = 1:4
            if stripblanks(LD3.answers(4,k))=="" then
                ld3_set_status(msprintf("Įrašykite [%s].", ld3_answer_code(4,k)), "error", "Atsakymą vertins dėstytojo programa."); return;
            end
            if check_answers then
                v = ld3_parse_number(LD3.answers(4,k));
                if isnan(v) then
                    ld3_set_status(msprintf("Įrašykite skaičių [%s].", ld3_answer_code(4,k)), "error", "R = U / I (I mA → dalyti iš 1000)."); return; end
                if ~ld3_close_enough(v, ld3_parse_number(exp(4,k))) then
                    ld3_set_status(msprintf("[%s] netikslus.", ld3_answer_code(4,k)), "error", ...
                        msprintf("Tikimasi ≈ %s.", exp(4,k))); return; end
            end
        end
        LD3.done(4) = %t;
        ld3_set_status("4 etapas baigtas.","ok","[E05] — I(U) charakteristika.");
    case 5 then
        if stripblanks(LD3.answers(5,1))=="" then
            ld3_set_status("Įrašykite R iš nuolydžio [A05.01], Ω.","error","Atsakymą vertins dėstytojo programa."); return;
        end
        if check_answers then
            v = ld3_parse_number(LD3.answers(5,1));
            e = LD3.cfg.R;
            if isnan(v) then ld3_set_status("Įrašykite skaitinę R reikšmę [A05.01], Ω.","error","R = ΔU / ΔI (I mA → ΔI/1000)."); return; end
            if ~ld3_close_enough(v, e) then
                ld3_set_status("[A05.01] netikslus.","error",msprintf("Tikimasi ≈ %g Ω.", e)); return; end
        end
        LD3.done(5) = %t;
        ld3_set_status("5 etapas baigtas.","ok","[E06] — išvados.");
    case 6 then
        for k=1:2
            if stripblanks(LD3.answers(6,k))=="" then
                ld3_set_status(msprintf("Įrašykite [%s].",ld3_answer_code(6,k)),"error","1 – Taip, 2 – Ne."); return;
            end
        end
        if check_answers then
            if LD3.answers(6,1) ~= "1" then ld3_set_status("[A06.01]: atsakymas neteisingas.","error","Palyginkite tris matavimų taškus [V02] sąraše."); return; end
            if LD3.answers(6,2) ~= "1" then ld3_set_status("[A06.02]: atsakymas neteisingas.","error","Palyginkite [A04.01]–[A04.03]."); return; end
        end
        LD3.done(6) = %t;
        ld3_set_status("6 etapas baigtas: darbas atliktas!","ok","[B08] ATASKAITA DĖSTYTOJUI sukuria HTML ataskaitą.");
    end
    if isfield(LD3, "ui") then
        if ~isfield(LD3.ui, "headless") | ~LD3.ui.headless then ld3_render_stage(); end
    end
    if ~check_answers then ld3_set_status(string(n)+" etapo atsakymai įrašyti.","ok","Teisingumą vertins dėstytojo programa."); end
endfunction

function ld3_next_step()
    global LD3;
    if LD3.step >= 6 then return; end
    if ~LD3.done(LD3.step) then
        LD3.skipped(LD3.step) = %t;
        ld3_set_status("Etapas praleistas (pažymėtas geltonai).","info","Grįžti galima [E] mygtukais.");
    end
    ld3_set_step(LD3.step + 1);
endfunction

function ld3_set_step(n)
    global LD3;
    if n < 1 | n > 6 then return; end
    ld3_save_answers();
    LD3.step = n;
    if isfield(LD3, "ui") then
        if ~isfield(LD3.ui, "headless") | ~LD3.ui.headless then
            ld3_render_stage();
            if isfield(LD3.ui, "instructionLine") & is_handle_valid(LD3.ui.instructionLine(1)) then
                LD3.ui.instructionLine(1).string = student_wrap(ld3_step_instruction(n),38);
            end
        end
    end
    bench_autosave("LD3");
endfunction

function s = ld3_step_instruction(n)
    global LD3;
    cfg = LD3.cfg;
    select n
    case 1 then s = "Sujunkite stendą: [T01]→[T03], [T04]→[T05], [T06]→[T07], [T08]→[T02] (galvos kontūras), o voltmetro zondai [T09]→[T07], [T10]→[T08] lygiagrečiai R1. Maitinimas [B01] dar išjungtas.";
    case 2 then s = msprintf("Apskaičiuokite teorinę srovę I1 = U1/R·1000 (U1=%d V, R=%d Ω) ir įrašykite [A02.01]. Tada [B01] maitinimas, [B02] jungiklis, [B10] U1, [B03] MATUOTI.", cfg.U1, cfg.R);
    case 3 then s = msprintf("Spauskite [B11] U2=%d V → [B03]; tada [B12] U3=%d V → [B03]. Užfiksuoti visi 3 taškai.", cfg.U2, cfg.U3);
    case 4 then s = "Apskaičiuokite ir įrašykite [A04.01]–[A04.03] (R=U/I iš kiekvieno taško) ir vidurkį [A04.04].";
    case 5 then s = "Charakteristikos I(U) taškai rodomi stende. Apskaičiuokite R iš nuolydžio: R=(U3−U1)/((I3−I1)/1000) → [A05.01].";
    case 6 then s = "Atsakykite [A06.01] (ar I(U) tiesinė?) ir [A06.02] (ar R pastovi?) – 1 Taip, 2 Ne. Tada Pagalba → [B08] Ataskaita.";
    else s = "";
    end
endfunction

function ld3_save_answers()
    global LD3;
    if ~isfield(LD3, "ui") then return; end
    if isfield(LD3.ui, "headless") then
        if LD3.ui.headless then return; end
    end
    if isfield(LD3.ui, "answerEdits") then
        for k = 1:size(LD3.ui.answerEdits, "*")
            h = LD3.ui.answerEdits(k);
            if is_handle_valid(h) & h.visible=="on" then
                [st, sl] = ld3_answer_slot(k);
                if h.string<>LD3.answers(st,sl) then LD3.done(st)=%f; end
                LD3.answers(st, sl) = h.string;
            end
        end
    end
endfunction

function ld3_answers_changed()
    global LD3;
    if LD3.demoMode then return; end
    ld3_save_answers(); ld3_student_sync(); bench_autosave("LD3");
endfunction

function [st, sl] = ld3_answer_slot(k)
    // UI atsakymų laukų eilė → (etapas, lizdas).
    mapa = [2 1; 4 1; 4 2; 4 3; 4 4; 5 1; 6 1; 6 2];
    st = mapa(k, 1); sl = mapa(k, 2);
endfunction

function ld3_test_answers(step, values)
    global LD3;
    for k = 1:size(values, "*")
        LD3.answers(step, k) = msprintf("%.10g", values(k));
    end
endfunction

function ld3_show_wiring_guide()
    global LD3;
    txt = ["LD3 · KAIP SUJUNGTI · " + ld3_stage_code(LD3.step) + " etapas"; "";
           ld3_step_instruction(LD3.step); "";
           "Sekos pavyzdys (1 etapas):";
           "1) laidu sujungti [T01] (šaltinis +) su [T03] (jungiklio įėjimas);";
           "2) [T04] (jungiklio išėjimas) su [T05] (ampermetras +);";
           "3) [T06] (ampermetras −) su [T07] (R1 gnybtas a);";
           "4) [T08] (R1 gnybtas b) su [T02] (šaltinis −);";
           "5) [T09] (voltmetras +) su [T07];";
           "6) [T10] (voltmetras −) su [T08].";
           "";
           "Klaidą taiso Pagalba → [B06] Atkurti stendą."];
    ld3_text_window("KAIP SUJUNGTI", txt);
endfunction

function ld3_show_stand_map()
    global LD3;
    [bids, cbs, blabels, bhints] = ld3_button_registry();
    txt = ["LD3 · STENDO ŽEMĖLAPIS (bankas " + LD3.student.bank + ")"; "";
           "GNYBTAI:"];
    tids = ld3_terminal_ids();
    for k = 1:size(tids, "*")
        txt($+1) = msprintf("  [T%02d] %s", k, ld3_terminal_name(tids(k)));
    end
    txt($+1) = ""; txt($+1) = "MYGTUKAI:";
    for k = 1:size(bids, "*")
        txt($+1) = "  [" + bids(k) + "] " + blabels(k);
    end
    txt($+1) = ""; txt($+1) = "ETAPAI: [E01]–[E06]; LAUKELIAI: [A02.01], [A04.01]–[A04.04], [A05.01], [A06.01]–[A06.02]; įtampos mygtukai [B10]–[B12], [V02] rodmuo.";
    ld3_text_window("STENDO ŽEMĖLAPIS", txt);
endfunction

function ld3_text_window(title, lines)
    global LD3;
    if isfield(LD3, "ui") then
        if isfield(LD3.ui, "headless") then
            if LD3.ui.headless then return; end
        end
    end
    f = figure("figure_name", "LD3 · " + title, "axes_size", [520 420], ...
               "menubar_visible", "off", "toolbar_visible", "off", "infobar_visible", "off");
    uicontrol(f, "style", "listbox", "units", "normalized", "position", [0.02 0.10 0.96 0.84], ...
              "string", lines, "fontname", "DejaVu Sans", "fontunits", "pixels", "fontsize", 12);
    uicontrol(f, "style", "pushbutton", "units", "normalized", "position", [0.35 0.02 0.3 0.06], ...
              "string", "[H01] Uždaryti", "tag", "H01", "callback", "close()");
endfunction

function ld3_toggle_solution()
    global LD3;
    if LD3.demoMode then
        LD3.demoMode = %f;
        if isfield(LD3, "backup") then
            LD3.wires = LD3.backup.wires;
            LD3.answers = LD3.backup.answers;
            LD3.voltage = LD3.backup.voltage;
            LD3.journal = LD3.backup.journal;
            LD3.powerOn = LD3.backup.powerOn;
            LD3.switchOn = LD3.backup.switchOn;
        end
        if isfield(LD3, "ui") then
            if ~isfield(LD3.ui, "headless") | ~LD3.ui.headless then ld3_render_stage(); end
        end
        ld3_set_status("Grįžta į savo darbą.","info","Jūsų laidai ir atsakymai atkurti.");
        bench_autosave("LD3");
        return;
    end
    if LD3.assessment then
        ld3_set_status("Pavyzdys atsiskaitymo režime nepasiekiamas.","error","Perjunkite į Mokymąsi per Pagalbą."); return;
    end
    LD3.practice_used=%t;
    ld3_save_answers();
    LD3.backup = struct();
    LD3.backup.wires = LD3.wires;
    LD3.backup.answers = LD3.answers;
    LD3.backup.voltage = LD3.voltage;
    LD3.backup.journal = LD3.journal;
    LD3.backup.powerOn = LD3.powerOn;
    LD3.backup.switchOn = LD3.switchOn;
    LD3.demoMode = %t;
    LD3.wires = ld3_canonical_wires();
    LD3.powerOn = %t; LD3.switchOn = %t; LD3.voltage = LD3.cfg.U3;
    e = ld3_expected_answers();
    LD3.answers(2,1) = e(2,1);
    if size(LD3.journal,1) < 3 then LD3.journal = [LD3.cfg.U1 LD3.cfg.U1/LD3.cfg.R*1000; LD3.cfg.U2 LD3.cfg.U2/LD3.cfg.R*1000; LD3.cfg.U3 LD3.cfg.U3/LD3.cfg.R*1000]; end
    for k = 1:4 do LD3.answers(4,k) = e(4,k); end
    LD3.answers(5,1) = e(5,1);
    LD3.answers(6,1) = "1"; LD3.answers(6,2) = "1";
    ld3_set_status("PAVYZDYS rodomas (neišsaugojama kaip jūsų atsakymai).","info","Grįžkite [B07].");
    if isfield(LD3, "ui") then
        if ~isfield(LD3.ui, "headless") | ~LD3.ui.headless then ld3_render_stage(); end
    end
endfunction

function ld3_restore_stage()
    global LD3;
    if LD3.demoMode then ld3_toggle_solution(); return; end
    LD3.pending = "";
    if LD3.step == 1 then LD3.wires = []; end
    ld3_set_status("Etapo stendas atkurtas į pradinę būseną.","info","");
    if isfield(LD3, "ui") then
        if ~isfield(LD3.ui, "headless") | ~LD3.ui.headless then ld3_render_stage(); end
    end
    bench_autosave("LD3");
endfunction

function ld3_restart()
    global LD3;
    cfg = LD3.cfg; st = LD3.student;
    ld3_init_state();
    LD3.cfg = cfg; LD3.student = st;
    if isfield(LD3, "ui") then
        if ~isfield(LD3.ui, "headless") | ~LD3.ui.headless then ld3_render_stage(); end
    end
    ld3_set_status("Darbas pradėtas iš naujo.","info","Variantas, studentas, režimas ir mokymosi žyma išliko.");
    bench_autosave("LD3");
endfunction

function ld3_close()
    global LD3;
    if ~isfield(LD3,"fig") then return; end
    if ~is_handle_valid(LD3.fig) then return; end
    if LD3.demoMode then ld3_toggle_solution(); end
    ld3_save_answers(); bench_autosave("LD3");
    if isfield(LD3,"autosave_error") then
        if LD3.autosave_error<>"" then
            ld3_set_status("Nepavyko išsaugoti juodraščio.","error","Langas paliktas atvertas, kad neprarastumėte darbo."); return;
        end
    end
    delete(LD3.fig);
endfunction
