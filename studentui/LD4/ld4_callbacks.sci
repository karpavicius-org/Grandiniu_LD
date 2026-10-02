// ============================================================================
// LD4 veiksmų logika: laidai, matavimai (R1/R2/serija), 7 etapų tikrinimas.
// ============================================================================

function ld4_terminal_click(id)
    global LD4;
    if LD4.demoMode then return; end
    if ~or(LD4.step==[1 6]) then return; end
    if ~or(ld4_terminal_ids()==id) then return; end
    if LD4.powerOn then
        LD4.pending="";
        ld4_set_status("Prieš keisdami laidus išjunkite maitinimą.","error","Spauskite [B01] MAITINIMAS, tada junkite laidus.");
        bench_autosave("LD4"); return;
    end
    if LD4.pending=="" then
        LD4.pending=id;
        ld4_set_status("Pasirinktas ["+ld4_terminal_code(id)+"] "+ld4_terminal_name(id),"info","Spauskite kitą gnybtą. Esamas laidas tarp tų pačių gnybtų bus pašalintas.");
    else
        first=LD4.pending; LD4.pending="";
        if first<>id then
            found=0;
            for k=1:size(LD4.wires,1)
                if and(LD4.wires(k,:)==[first id]) | and(LD4.wires(k,:)==[id first]) then found=k; break; end
            end
            if found>0 then
                LD4.wires(found,:)=[];
                ld4_set_status("Laidas pašalintas.","ok","");
            else
                uses1=sum(LD4.wires==first); uses2=sum(LD4.wires==id);
                if uses1>=2 | uses2>=2 then
                    ld4_set_status("Gnybte jau yra du laidai.","error","Pirma pašalinkite netinkamą laidą, paspausdami abu jo galus.");
                    ld4_render_wires(); bench_autosave("LD4"); return;
                end
                LD4.wires($+1,:)=[first id];
                ld4_set_status("Laidas pridėtas.","ok","Laidą pašalinsite dar kartą paspaudę abu jo galus.");
            end
            LD4.done(LD4.step)=%f; LD4.report_wires(LD4.step)=emptystr(0,2);
            LD4.lastMeasurement=%nan;
        end
    end
    ld4_render_wires(); ld4_student_sync(); bench_autosave("LD4");
endfunction

function ld4_toggle_power()
    global LD4;
    LD4.powerOn = ~LD4.powerOn;
    if LD4.powerOn then
        ld4_set_status("[B01] Maitinimas ĮJUNGTAS.","ok","Dabar uždarykite jungiklį [B02].");
    else
        LD4.switchOn=%f;
        ld4_set_status("[B01] Maitinimas IŠJUNGTAS.","info","Jungiklis atidarytas; dabar saugu keisti laidus.");
    end
    ld4_render_wires(); bench_autosave("LD4");
endfunction

function ld4_toggle_switch()
    global LD4;
    if ~LD4.powerOn then ld4_set_status("Negalima jungti be maitinimo.","error","Pirmiausia [B01] MAITINIMAS."); return; end
    LD4.switchOn = ~LD4.switchOn;
    if LD4.switchOn then ld4_set_status("[B02] Jungiklis UŽDARYTAS.","ok","Nustatykite įtampą [B10]–[B12] ir matuokite [B03].");
    else ld4_set_status("[B02] Jungiklis ATIDARYTAS.","info",""); end
    ld4_render_wires(); bench_autosave("LD4");
endfunction

function ld4_set_resistor(k)
    // [B13]: perjungia matavimo grandinę į R2 (3 etape).
    global LD4;
    if LD4.step ~= 3 then
        ld4_set_status("Rezistorius keičiamas tik 3 etape.","info","[E03] atidaro R2 tyrimo etapą.");
        return;
    end
    // Perjungiant topologiją stendas visada deenergizuojamas.
    LD4.powerOn=%f; LD4.switchOn=%f; LD4.pending=""; LD4.lastMeasurement=%nan;
    LD4.wires = ld4_canonical_wires(2);
    LD4.wireMode = 2; LD4.done(3)=%f;
    ld4_set_status("Grandinė perjungta į R2; maitinimas automatiškai išjungtas.","ok","Vėl įjunkite [B01], uždarykite [B02], tada matuokite.");
    if isfield(LD4, "ui") then
        if ~isfield(LD4.ui, "headless") | ~LD4.ui.headless then ld4_render_wires(); end
    end
    bench_autosave("LD4");
endfunction

function ld4_set_voltage(v)
    global LD4;
    if ~or(v==[LD4.cfg.U1 LD4.cfg.U2 LD4.cfg.U3]) then return; end
    LD4.voltage=v; LD4.lastMeasurement=%nan;
    ld4_render_wires(); bench_autosave("LD4");
endfunction

function ld4_measure()
    global LD4;
    [u, i, ok, msg] = ld4_measure_values();
    if ~ok then ld4_set_status(msg, "error", ""); return; end
    if LD4.step ~= 2 & LD4.step ~= 3 & LD4.step ~= 6 then
        ld4_set_status("Matavimai atliekami 2, 3 ir 6 etapuose.","info","Etapus keičia [E01]–[E07].");
        return;
    end
    m = ld4_wire_mode();
    tag = 1; if m == 2 then tag = 2; elseif m == "S" then tag = 3; end
    if tag==3 & abs(u-LD4.cfg.U3)>1e-9 then
        ld4_set_status("Nuoseklų jungimą matuokite ties U3.","error","Paspauskite [B12], tada [B03]."); return;
    end
    rows = ld4_journal_rows(tag);
    for mm = 1:size(rows, 1)
        if abs(rows(mm,1) - u) < 1e-9 then
            ld4_set_status("Šis įtampos taškas šiam rezistoriui jau užfiksuotas.","error","Nustatykite kitą reikšmę [B11]/[B12].");
            return;
        end
    end
    if tag ~= 3 & size(rows, 1) >= 3 then
        ld4_set_status("Visi trys taškai užfiksuoti.","info","Eikite toliau.");
        return;
    end
    LD4.journal($+1, :) = [u, i, tag];
    LD4.lastMeasurement = i;
    if tag==3 then LD4.report_wires(6)=LD4.wires; end
    kokia = "R1"; if tag == 2 then kokia = "R2"; elseif tag == 3 then kokia = "R1+R2"; end
    if tag==3 then
        ld4_set_status(msprintf("Užfiksuota (%s): U = %g V, I = %.2f mA.", kokia, u, i), "ok","Nuoseklus taškas įrašytas į [V02].");
    else
        ld4_set_status(msprintf("Užfiksuota (%s): U = %g V, I = %.2f mA (%d/3).", kokia, u, i, size(ld4_journal_rows(tag),1)), "ok","Rodmuo [V02] ir matavimų sąrašas.");
    end
    if isfield(LD4, "ui") then
        if ~isfield(LD4.ui, "headless") | ~LD4.ui.headless then ld4_render_journal(); ld4_render_wires(); end
    end
    bench_autosave("LD4");
endfunction

function ok = ld4_close_enough(userValue, expectedValue, rel, absolute)
    if argn(2)<3 then rel=0.02; end
    if argn(2)<4 then absolute=0.005; end
    ok=%f;
    if isnan(userValue) | isnan(expectedValue) | isinf(userValue) | isinf(expectedValue) then return; end
    ok=abs(userValue-expectedValue)<=absolute+rel*abs(expectedValue);
endfunction

function ld4_check_step(check_answers)
    global LD4;
    if argn(2)<1 then check_answers=%t; end
    n = LD4.step;
    if LD4.demoMode then return; end
    if n <= 7 & LD4.done(n) then ld4_set_status("Etapas jau atliktas.","ok","Spauskite TOLIAU."); return; end
    select n
    case 1 then
        [wok, wwhy] = ld4_wiring_valid(LD4.wires);
        if ~wok then ld4_set_status(wwhy, "error", "Seką rodo [B04] KAIP SUJUNGTI."); return; end
        LD4.wireMode = 1;
        LD4.done(1) = %t; LD4.report_wires(1)=LD4.wires;
        ld4_set_status("1 etapas baigtas: R1 grandinė sujungta.","ok","[E02] — teorinė prognozė.");
    case 2 then
        if stripblanks(LD4.answers(2,1))=="" then
            ld4_set_status("Įrašykite teorinę srovę [A02.01], mA.","error","Atsakymą vertins dėstytojo programa."); return;
        end
        if check_answers then
            v = ld4_parse_number(LD4.answers(2,1));
            e = LD4.cfg.U1 / LD4.cfg.R1nom * 1000;
            if isnan(v) then ld4_set_status("Įrašykite skaitinę teorinę srovę [A02.01], mA.","error","I = U1 / R1 · 1000."); return; end
            if ~ld4_close_enough(v, e,0.01,1e-9) then ld4_set_status("Teorinė srovė [A02.01] netiksli.","error",msprintf("Tikimasi ≈ %.2f mA.", e)); return; end
        end
        if size(ld4_journal_rows(1), 1) < 3 then
            ld4_set_status("Trūksta R1 matavimo taškų.","error","[B10]/[B11]/[B12] ir [B03] — trys taškai."); return;
        end
        LD4.done(2) = %t;
        ld4_set_status("2 etapas baigtas (R1: trys taškai).","ok","[E03] — perjunkite į R2 per [B13].");
    case 3 then
        if LD4.wireMode ~= 2 & size(ld4_journal_rows(2), 1) == 0 then
            ld4_set_status("Perjunkite grandinę į R2.","error","Spauskite [B13] Į R2 REZISTORIŲ."); return;
        end
        if size(ld4_journal_rows(2), 1) < 3 then
            ld4_set_status("Trūksta R2 matavimo taškų.","error","[B10]/[B11]/[B12] ir [B03] — trys taškai."); return;
        end
        LD4.done(3) = %t;
        ld4_set_status("3 etapas baigtas (R2: trys taškai).","ok","[E04] — skaičiavimai.");
    case 4 then
        exp = ld4_expected_answers();
        etik = ["A04.01 R1m";"A04.02 R2m";"A04.03 δ1 %";"A04.04 δ2 %"];
        for k = 1:4
            if stripblanks(LD4.answers(4,k))=="" then
                ld4_set_status("Įrašykite [" + etik(k) + "].","error","Atsakymą vertins dėstytojo programa."); return;
            end
            e = ld4_parse_number(exp(4,k));
            if isnan(e) then ld4_set_status("Trūksta matavimų šiam skaičiavimui.","error","Patikrinkite 2–3 etapų žurnalą."); return; end
            if check_answers then
                v = ld4_parse_number(LD4.answers(4,k));
                if isnan(v) then ld4_set_status("Įrašykite skaičių [" + etik(k) + "].","error","R = 1000·U/I_mA; δ = (Rm/Rnom − 1)·100 %."); return; end
                tol = 0.02; if k >= 3 then tol = 0.05; end
                if ~ld4_close_enough(v,e,tol,0.005) then
                    ld4_set_status("[" + etik(k) + "] netikslus.","error",msprintf("Tikimasi ≈ %s.", exp(4,k))); return; end
            end
        end
        LD4.done(4) = %t;
        ld4_set_status("4 etapas baigtas.","ok","[E05] — charakteristikos.");
    case 5 then
        exp = ld4_expected_answers();
        etik = ["A05.01 R1 (nuolydis)";"A05.02 R2 (nuolydis)";"A05.03 G2, mS"];
        for k = 1:3
            if stripblanks(LD4.answers(5,k))=="" then
                ld4_set_status("Įrašykite [" + etik(k) + "].","error","Atsakymą vertins dėstytojo programa."); return;
            end
            e = ld4_parse_number(exp(5,k));
            if isnan(e) then ld4_set_status("Trūksta matavimų.","error","Žiūrėkite 2–3 etapų žurnalą."); return; end
            if check_answers then
                v = ld4_parse_number(LD4.answers(5,k));
                if isnan(v) then ld4_set_status("Įrašykite skaičių [" + etik(k) + "].","error","R = 1000·ΔU/ΔI_mA; G = 1000/R, mS."); return; end
                if ~ld4_close_enough(v, e) then
                    ld4_set_status("[" + etik(k) + "] netikslus.","error",msprintf("Tikimasi ≈ %s.", exp(5,k))); return; end
            end
        end
        LD4.done(5) = %t;
        ld4_set_status("5 etapas baigtas.","ok","[E06] — nuoseklus jungimas.");
    case 6 then
        [wok, wwhy] = ld4_wiring_valid(LD4.wires);
        if ~wok then ld4_set_status(wwhy, "error","Nuoseklus: R1B→[T09] R2A laidu, zondai [T11]→[T07], [T12]→[T10]."); return; end
        if size(ld4_journal_rows(3), 1) < 1 then
            ld4_set_status("Trūksta nuosekliojo jungimo matavimo.","error","[B12] U3 → [B03] MATUOTI."); return;
        end
        if stripblanks(LD4.answers(6,1))=="" then
            ld4_set_status("Įrašykite Rs [A06.01], Ω.","error","Atsakymą vertins dėstytojo programa."); return;
        end
        exp = ld4_expected_answers(); e = ld4_parse_number(exp(6,1));
        if isnan(e) then ld4_set_status("Trūksta nuosekliojo matavimo.","error","Patikrinkite [V02]."); return; end
        if check_answers then
            v = ld4_parse_number(LD4.answers(6,1));
            if isnan(v) then ld4_set_status("Įrašykite skaitinę Rs reikšmę [A06.01], Ω.","error","Rs = 1000·U/I_mA."); return; end
            if ~ld4_close_enough(v, e) then
                ld4_set_status("[A06.01] netikslus.","error",msprintf("Tikimasi ≈ %s (Rs = R1 + R2).", exp(6,1))); return; end
        end
        LD4.wireMode = "S";
        LD4.done(6) = %t; LD4.report_wires(6)=LD4.wires;
        ld4_set_status("6 etapas baigtas: nuoseklus jungimas užfiksuotas.","ok","[E07] — išvados.");
    case 7 then
        for k=1:2
            if stripblanks(LD4.answers(7,k))=="" then
                ld4_set_status(msprintf("Įrašykite [A07.0%d].",k),"error","1 – Taip, 2 – Ne."); return;
            end
        end
        if check_answers then
            if ld4_parse_number(LD4.answers(7,1)) ~= 1 then ld4_set_status("[A07.01]: atsakymas neteisingas.","error","1 – Taip, 2 – Ne."); return; end
            if ld4_parse_number(LD4.answers(7,2)) ~= 1 then ld4_set_status("[A07.02]: atsakymas neteisingas.","error","Ar δ ≤ 5 %?"); return; end
        end
        LD4.done(7) = %t;
        ld4_set_status("7 etapas baigtas: darbas atliktas!","ok","[B08] ATASKAITA DĖSTYTOJUI sukuria HTML ataskaitą.");
    end
    if isfield(LD4, "ui") then
        if ~isfield(LD4.ui, "headless") | ~LD4.ui.headless then ld4_render_stage(); end
    end
    if ~check_answers & or(n==[2 4 5 6 7]) then
        ld4_set_status(string(n)+" etapo atsakymai įrašyti.","ok","Teisingumą vertins dėstytojo programa.");
    end
endfunction

function ld4_next_step()
    global LD4;
    if LD4.step >= 7 then return; end
    if ~LD4.done(LD4.step) then
        LD4.skipped(LD4.step) = %t;
        ld4_set_status("Etapas praleistas (pažymėtas geltonai).","info","Grįžti galima [E] mygtukais.");
    end
    ld4_set_step(LD4.step + 1);
endfunction

function ld4_set_step(n)
    global LD4;
    if n < 1 | n > 7 then return; end
    ld4_save_answers();
    LD4.step = n;
    if or(n==[3 6]) then
        LD4.powerOn=%f; LD4.switchOn=%f; LD4.pending=""; LD4.lastMeasurement=%nan;
    end
    if isfield(LD4, "ui") then
        if ~isfield(LD4.ui, "headless") | ~LD4.ui.headless then ld4_render_stage(); end
    end
    bench_autosave("LD4");
endfunction

function s = ld4_step_instruction(n)
    global LD4;
    cfg = LD4.cfg;
    select n
    case 1 then s = "Sujunkite grandinę su R1: [T01]→[T03], [T04]→[T05], [T06]→[T07], [T08]→[T02], zondai [T11]→[T07], [T12]→[T08]. Maitinimas [B01] išjungtas.";
    case 2 then s = msprintf("Apskaičiuokite teorinę I1 = U1/R1nom·1000 (U1=%d V, R1nom=%d Ω) → [A02.01]. Tada [B01], [B02], [B10] U1=%d V, [B03]; [B11] U2=%d V, [B03]; [B12] U3=%d V, [B03].", cfg.U1, cfg.R1nom, cfg.U1, cfg.U2, cfg.U3);
    case 3 then s = "Spauskite [B13] Į R2 REZISTORIŲ. Perjungiant maitinimas automatiškai išjungiamas. Tada vėl [B01], [B02] ir išmatuokite [B10] U1, [B11] U2, [B12] U3 su [B03].";
    case 4 then s = msprintf("Apskaičiuokite [A04.01] R1m ir [A04.02] R2m: R = 1000·U/I_mA, Ω; tada [A04.03] δ1 %% ir [A04.04] δ2 %% nuo nominalų (%d / %d Ω).", cfg.R1nom, cfg.R2nom);
    case 5 then s = "Iš žurnalo taškų: [A05.01] R1 ir [A05.02] R2 iš I(U) nuolydžių: R = 1000·ΔU/ΔI_mA, Ω; [A05.03] G2 = 1000/R2, mS.";
    case 6 then s = "Maitinimas išjungtas. Iš R2 į nuoseklų: pašalinkite [T06]–[T09] ir [T11]–[T09]. Pridėkite [T06]–[T07], [T08]–[T09], [T11]–[T07]. Tada [B01], [B02], [B12], [B03]; Rs = 1000·U/I_mA, Ω → [A06.01].";
    case 7 then s = "[A07.01] Ar abiejų rezistorių I(U) tiesinės? [A07.02] Ar δ telpa ±5 %? (1 – Taip, 2 – Ne). Tada [B08] ataskaita.";
    else s = "";
    end
endfunction

function ld4_save_answers()
    global LD4;
    if ~isfield(LD4, "ui") then return; end
    if isfield(LD4.ui, "headless") then if LD4.ui.headless then return; end end
    if isfield(LD4.ui, "answerEdits") then
        for k = 1:size(LD4.ui.answerEdits, "*")
            h = LD4.ui.answerEdits(k);
            if is_handle_valid(h) then
                [st, sl] = ld4_answer_slot(k);
                if st<>LD4.step | h.visible<>"on" then continue; end
                if LD4.answers(st,sl)<>h.string then LD4.done(st)=%f; end
                LD4.answers(st, sl) = h.string;
            end
        end
    end
endfunction

function [st, sl] = ld4_answer_slot(k)
    mapa = [2 1; 4 1; 4 2; 4 3; 4 4; 5 1; 5 2; 5 3; 6 1; 7 1; 7 2];
    st = mapa(k, 1); sl = mapa(k, 2);
endfunction

function ld4_test_answers(step, values)
    global LD4;
    for k = 1:size(values, "*")
        LD4.answers(step, k) = msprintf("%.10g", values(k));
    end
endfunction

function ld4_show_wiring_guide()
    global LD4;
    txt = ["LD4 · KAIP SUJUNGTI · " + ld4_stage_code(LD4.step) + " etapas"; "";
           ld4_step_instruction(LD4.step); "";
           "R1 grandinė (1 etapas): [T01]→[T03] → [T04]→[T05] → [T06]→[T07] → [T08]→[T02]; zondai [T11]→[T07], [T12]→[T08].";
           "R2 (3 etapas): tas pats per [B13] automatiškai ([T09]/[T10] vietoje [T07]/[T08]).";
           "Nuoseklus (6 etapas): [T08]→[T09] jungia R1 su R2 eilėje; [T10]→[T02] grąžina."];
    ld4_text_window("KAIP SUJUNGTI", txt);
endfunction

function ld4_show_stand_map()
    global LD4;
    [bids, cbs, blabels, bhints] = ld4_button_registry();
    txt = ["LD4 · STENDO ŽEMĖLAPIS (bankas " + LD4.student.bank + ")"; "";
           "GNYBTAI (T01–T12): šaltinis, jungiklis, ampermetras, R1 (a/b), R2 (a/b), voltmetras."; "";
           "MYGTUKAI:"];
    for k = 1:size(bids, "*")
        txt($+1) = "  [" + bids(k) + "] " + blabels(k);
    end
    txt($+1) = ""; txt($+1) = "ETAPAI: [E01]–[E07]; LAUKELIAI: [A02.01], [A04.01]–[A04.04], [A05.01]–[A05.03], [A06.01], [A07.01]–[A07.02]; [V02] rodmuo.";
    ld4_text_window("STENDO ŽEMĖLAPIS", txt);
endfunction

function ld4_text_window(title, lines)
    global LD4;
    if isfield(LD4, "ui") then
        if isfield(LD4.ui, "headless") then if LD4.ui.headless then return; end end
    end
    f = figure("figure_name", "LD4 · " + title, "axes_size", [520 420], ...
               "menubar_visible", "off", "toolbar_visible", "off", "infobar_visible", "off");
    uicontrol(f, "style", "listbox", "units", "normalized", "position", [0.02 0.10 0.96 0.84], ...
              "string", lines, "fontname", "DejaVu Sans", "fontunits", "pixels", "fontsize", 12);
    uicontrol(f, "style", "pushbutton", "units", "normalized", "position", [0.35 0.02 0.3 0.06], ...
              "string", "[H01] Uždaryti", "tag", "H01", "callback", "close()");
endfunction

function ld4_toggle_solution()
    global LD4;
    if LD4.demoMode then
        LD4.demoMode = %f;
        if isfield(LD4, "backup") then
            LD4.wires = LD4.backup.wires; LD4.answers = LD4.backup.answers;
            LD4.voltage = LD4.backup.voltage; LD4.journal = LD4.backup.journal;
            LD4.powerOn = LD4.backup.powerOn; LD4.switchOn = LD4.backup.switchOn;
            LD4.wireMode=LD4.backup.wireMode; LD4.lastMeasurement=LD4.backup.lastMeasurement;
        end
        if isfield(LD4, "ui") then
            if ~isfield(LD4.ui, "headless") | ~LD4.ui.headless then ld4_render_stage(); end
        end
        ld4_set_status("Grįžta į savo darbą.","info","Laidai ir atsakymai atkurti.");
        bench_autosave("LD4");
        return;
    end
    if LD4.assessment then
        ld4_set_status("Pavyzdys atsiskaitymo režime nepasiekiamas.","error","Perjunkite į Mokymąsi per Pagalbą."); return;
    end
    ld4_save_answers();
    LD4.backup = struct();
    LD4.backup.wires = LD4.wires; LD4.backup.answers = LD4.answers;
    LD4.backup.voltage = LD4.voltage; LD4.backup.journal = LD4.journal;
    LD4.backup.powerOn = LD4.powerOn; LD4.backup.switchOn = LD4.switchOn;
    LD4.backup.wireMode=LD4.wireMode; LD4.backup.lastMeasurement=LD4.lastMeasurement;
    LD4.practice_used=%t;
    LD4.demoMode = %t;
    LD4.wires = ld4_canonical_wires(ld4_wire_mode());
    LD4.powerOn = %t; LD4.switchOn = %t; LD4.voltage = LD4.cfg.U3;
    cfg = LD4.cfg;
    LD4.journal = [cfg.U1 cfg.U1/cfg.R1*1000 1; cfg.U2 cfg.U2/cfg.R1*1000 1; cfg.U3 cfg.U3/cfg.R1*1000 1; ...
                   cfg.U1 cfg.U1/cfg.R2*1000 2; cfg.U2 cfg.U2/cfg.R2*1000 2; cfg.U3 cfg.U3/cfg.R2*1000 2; ...
                   cfg.U3 cfg.U3/(cfg.R1+cfg.R2)*1000 3];
    ld4_set_status("PAVYZDYS rodomas (neišsaugojama).","info","Grįžkite [B07].");
    if isfield(LD4, "ui") then
        if ~isfield(LD4.ui, "headless") | ~LD4.ui.headless then ld4_render_stage(); end
    end
endfunction

function ld4_restore_stage()
    global LD4;
    if LD4.demoMode then ld4_toggle_solution(); return; end
    LD4.powerOn=%f; LD4.switchOn=%f; LD4.pending=""; LD4.lastMeasurement=%nan;
    if LD4.step == 1 then LD4.wires = []; LD4.wireMode = 1; end
    if LD4.step == 3 then LD4.wires = ld4_canonical_wires(2); LD4.wireMode = 2; end
    if LD4.step == 6 then LD4.wires = ld4_canonical_wires(2); LD4.wireMode = 2; end
    LD4.done(LD4.step)=%f; LD4.report_wires(LD4.step)=emptystr(0,2);
    ld4_set_status("Etapo stendas atkurtas; maitinimas išjungtas.","info","");
    if isfield(LD4, "ui") then
        if ~isfield(LD4.ui, "headless") | ~LD4.ui.headless then ld4_render_wires(); end
    end
    bench_autosave("LD4");
endfunction

function ld4_restart()
    global LD4;
    cfg = LD4.cfg; st = LD4.student;
    ld4_init_state();
    LD4.cfg = cfg; LD4.student = st;
    if isfield(LD4, "ui") then
        if ~isfield(LD4.ui, "headless") | ~LD4.ui.headless then ld4_render_stage(); end
    end
    ld4_set_status("Darbas pradėtas iš naujo.","info","Variantas, studentas, režimas ir mokymosi žyma išliko.");
    bench_autosave("LD4");
endfunction

function ld4_answers_changed()
    // Atsakymo laukelio redagavimas: nedelsiant saugoma į store.
    global LD4;
    ld4_save_answers(); ld4_student_sync(); bench_autosave("LD4");
endfunction

function ld4_close()
    global LD4;
    if ~isfield(LD4,"fig") then return; end
    if typeof(LD4.fig)<>"handle" then LD4.fig=[]; return; end
    if ~is_handle_valid(LD4.fig) then LD4.fig=[]; return; end
    if LD4.demoMode then ld4_toggle_solution(); end
    ld4_save_answers();
    LD4.autosave_error="";
    bench_autosave("LD4");
    if LD4.autosave_error<>"" then
        ld4_set_status("Nepavyko išsaugoti juodraščio.","error","Langas paliktas atvertas, kad neprarastumėte darbo. "+LD4.autosave_error); return;
    end
    f=LD4.fig;
    delete(f);
    LD4.fig=[];
endfunction
