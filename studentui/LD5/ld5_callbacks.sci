// ============================================================================
// LD5 veiksmų logika: laidai, trys daliklio padėtys, 6 etapų tikrinimas.
// ============================================================================

function ld5_terminal_click(id)
    global LD5;
    if LD5.demoMode then return; end
    if LD5.step<>1 then return; end
    if ~or(ld5_terminal_ids()==id) then return; end
    if LD5.powerOn then
        LD5.pending="";
        ld5_set_status("Prieš keisdami laidus išjunkite maitinimą.","error","Išjunkite maitinimą ir tada keiskite laidus.");
        bench_autosave("LD5"); return;
    end
    if LD5.pending=="" then
        LD5.pending=id;
        ld5_set_status("Pasirinktas "+ld5_terminal_name(id)+".","info","Spauskite kitą gnybtą. Esamas laidas tarp tų pačių gnybtų bus pašalintas.");
    else
        first=LD5.pending; LD5.pending="";
        if first<>id then
            found=0;
            for k=1:size(LD5.wires,1)
                if and(LD5.wires(k,:)==[first id]) | and(LD5.wires(k,:)==[id first]) then found=k; break; end
            end
            if found>0 then
                LD5.wires(found,:)=[];
                ld5_set_status("Laidas pašalintas.","ok","");
            else
                uses1=sum(LD5.wires==first); uses2=sum(LD5.wires==id);
                if uses1>=2 | uses2>=2 then
                    ld5_set_status("Gnybte jau yra du laidai.","error","Pirma pašalinkite netinkamą laidą, paspausdami abu jo galus.");
                    ld5_render_wires(); bench_autosave("LD5"); return;
                end
                LD5.wires($+1,:)=[first id];
                ld5_set_status("Laidas pridėtas.","ok","Laidą pašalinsite dar kartą paspaudę abu jo galus.");
            end
            LD5.done(:)=%f; LD5.report_wires(1)=emptystr(0,2);
            LD5.journal=[]; LD5.powerOn=%f; LD5.switchOn=%f;
            LD5.lastMeasurement=%nan;
        end
    end
    ld5_render_wires(); ld5_render_journal(); ld5_student_sync(); bench_autosave("LD5");
endfunction

function ld5_toggle_power()
    global LD5;
    LD5.powerOn = ~LD5.powerOn;
    if LD5.powerOn then
        ld5_set_status("Maitinimas įjungtas.","ok","Dabar uždarykite jungiklį.");
    else
        LD5.switchOn=%f;
        ld5_set_status("Maitinimas išjungtas.","info","Jungiklis atidarytas; dabar saugu keisti laidus.");
    end
    ld5_render_wires(); bench_autosave("LD5");
endfunction

function ld5_toggle_switch()
    global LD5;
    if ~LD5.powerOn then ld5_set_status("Negalima uždaryti jungiklio be maitinimo.","error","Pirmiausia įjunkite maitinimą."); return; end
    LD5.switchOn = ~LD5.switchOn;
    if LD5.switchOn then ld5_set_status("Jungiklis uždarytas.","ok","Pasirinkite P1, P2 arba P3 ir spauskite Matuoti.");
    else ld5_set_status("Jungiklis atidarytas.","info",""); end
    ld5_render_wires(); bench_autosave("LD5");
endfunction

function ld5_set_position(k)
    // [B10]–[B12]: potenciometro padėtis (1, 2 arba 3).
    global LD5;
    if ~ld5_valid_index(k,3) then return; end
    LD5.position = k;
    p = LD5.cfg("P" + string(k));
    ld5_set_status(msprintf("Potenciometras: padėtis %d (%d %%).", k, p), "ok", "Dabar spauskite Matuoti.");
    ld5_render_wires(); bench_autosave("LD5");
endfunction

function ld5_set_voltage(v)
    // LD5: įtampa fiksuota E (daliklis), slankiklio nėra — tuščias suderinamumui.
endfunction

function ld5_measure()
    global LD5;
    if LD5.demoMode then return; end
    [u, i, ok, msg] = ld5_measure_values();
    if ~ok then ld5_set_status(msg, "error", ""); return; end
    if LD5.step ~= 2 & LD5.step ~= 3 then
        ld5_set_status("Matavimai atliekami 2 ir 3 etapuose.","info","Pirmiausia patikrinkite sujungimą.");
        return;
    end
    tag = LD5.position;
    if size(ld5_journal_rows(tag), 1) >= 1 then
        ld5_set_status("Ši padėtis jau užfiksuota.","error","Pasirinkite kitą potenciometro padėtį.");
        return;
    end
    LD5.journal($+1, :) = [u, i, tag];
    LD5.lastMeasurement = i;
    ld5_set_status(msprintf("Užfiksuota (padėtis %d): U = %.2f V, I = %.2f mA.", tag, u, i), "ok","Rodmuo įrašytas į matavimų sąrašą.");
    if isfield(LD5, "ui") then
        if ~isfield(LD5.ui, "headless") | ~LD5.ui.headless then ld5_render_journal(); ld5_render_wires(); end
    end
    bench_autosave("LD5");
endfunction

function ok = ld5_close_enough(userValue, expectedValue, rel, absolute)
    if argn(2)<3 then rel=0.02; end
    if argn(2)<4 then absolute=1e-9; end
    ok=%f;
    if isnan(userValue) | isnan(expectedValue) | isinf(userValue) | isinf(expectedValue) then return; end
    ok=abs(userValue-expectedValue)<=absolute+rel*abs(expectedValue);
endfunction

function ld5_check_step(check_answers)
    global LD5;
    if argn(2)<1 then check_answers=%t; end
    if LD5.demoMode then return; end
    ld5_save_answers();
    n=LD5.step;
    if ~ld5_valid_index(n,6) then return; end
    if LD5.done(n) then ld5_set_status("Etapas jau atliktas.","ok","Spauskite Toliau."); return; end
    exp=ld5_expected_answers();
    select n
    case 1 then
        [wok,wwhy]=ld5_wiring_valid(LD5.wires);
        if ~wok then ld5_set_status(wwhy,"error","Jei reikia, atverkite Pagalba → Kaip sujungti."); return; end
        LD5.report_wires(1)=LD5.wires; LD5.done(1)=%t;
        ld5_set_status("Įtampos daliklio grandinė sujungta.","ok","Spauskite Toliau.");
    case 2 then
        raw=stripblanks(LD5.answers(2,1));
        if raw=="" then ld5_set_status("Įrašykite teorinę U2, V.","error","Atsakymo teisingumą vertins dėstytojo programa."); return; end
        v=ld5_parse_number(raw);
        if isnan(v) then ld5_set_status("Teorinė U2 turi būti skaičius.","error","Tinka kablelis arba taškas; formulės ir vieneto į lauką nerašykite."); return; end
        if check_answers then
            e=exp(2,1);
            if ~ld5_close_enough(v,e,0.01) then ld5_set_status("Teorinė U2 netiksli.","error",msprintf("Tikimasi ≈ %.2f V.",e)); return; end
        end
        if size(ld5_journal_rows(2),1)<1 then ld5_set_status("Trūksta 2-os padėties matavimo.","error","Pasirinkite P2 ir spauskite Matuoti."); return; end
        LD5.done(2)=%t; ld5_set_status("2 padėties matavimas užfiksuotas.","ok","Spauskite Toliau.");
    case 3 then
        if size(ld5_journal_rows(1),1)<1 then ld5_set_status("Trūksta 1-os padėties matavimo.","error","Pasirinkite P1 ir spauskite Matuoti."); return; end
        if size(ld5_journal_rows(3),1)<1 then ld5_set_status("Trūksta 3-ios padėties matavimo.","error","Pasirinkite P3 ir spauskite Matuoti."); return; end
        LD5.done(3)=%t; ld5_set_status("Visos trys potenciometro padėtys užfiksuotos.","ok","Spauskite Toliau.");
    case 4 then
        labels=["U1 teorinė";"U3 teorinė";"Reguliavimo diapazonas ΔU";"Diapazonas nuo E"];
        for k=1:4
            raw=stripblanks(LD5.answers(4,k));
            if raw=="" then ld5_set_status("Įrašykite "+labels(k)+".","error","Atsakymo teisingumą vertins dėstytojo programa."); return; end
            v=ld5_parse_number(raw);
            if isnan(v) then ld5_set_status(labels(k)+" turi būti skaičius.","error","Tinka kablelis arba taškas; vieneto į lauką nerašykite."); return; end
            if check_answers then
                e=exp(4,k); rel=0.02; if k<=2 then rel=0.01; end
                if ~ld5_close_enough(v,e,rel) then ld5_set_status(labels(k)+" reikšmė netiksli.","error",msprintf("Tikimasi ≈ %.4g.",e)); return; end
            end
        end
        LD5.done(4)=%t; ld5_set_status("4 etapas užfiksuotas.","ok","Spauskite Toliau.");
    case 5 then
        labels=["Srovė I2";"Aktyvios RV dalies santykis"];
        for k=1:2
            raw=stripblanks(LD5.answers(5,k));
            if raw=="" then ld5_set_status("Įrašykite "+labels(k)+".","error","Atsakymo teisingumą vertins dėstytojo programa."); return; end
            v=ld5_parse_number(raw);
            if isnan(v) then ld5_set_status(labels(k)+" turi būti skaičius.","error","Tinka kablelis arba taškas; vieneto į lauką nerašykite."); return; end
            if check_answers then
                e=exp(5,k);
                if ~ld5_close_enough(v,e) then ld5_set_status(labels(k)+" reikšmė netiksli.","error",msprintf("Tikimasi ≈ %.4g.",e)); return; end
            end
        end
        LD5.done(5)=%t; ld5_set_status("5 etapas užfiksuotas.","ok","Spauskite Toliau.");
    case 6 then
        for k=1:2
            raw=stripblanks(LD5.answers(6,k));
            if raw<>"1" & raw<>"2" then ld5_set_status("Abiem išvadoms pasirinkite 1 arba 2.","error","1 – Taip, 2 – Ne."); return; end
        end
        if check_answers then
            if LD5.answers(6,1)<>"1" then ld5_set_status("Pirma išvada neteisinga.","error","Palyginkite tris išėjimo įtampos reikšmes."); return; end
            if LD5.answers(6,2)<>"1" then ld5_set_status("Antra išvada neteisinga.","error","Palyginkite matavimus su įtampos daliklio formule."); return; end
        end
        LD5.done(6)=%t; ld5_set_status("Darbas užfiksuotas.","ok","Spauskite Įrašyti ataskaitą.");
    end
    if isfield(LD5,"ui") then
        if ~isfield(LD5.ui,"headless") | ~LD5.ui.headless then ld5_render_stage(); end
    end
    if ~check_answers & or(n==[2 4 5 6]) then
        ld5_set_status(string(n)+" etapo duomenys įrašyti.","ok","Teisingumą vertins dėstytojo programa.");
    end
endfunction

function ld5_next_step()
    global LD5;
    if LD5.step>=6 then return; end
    if ~LD5.done(LD5.step) then
        if LD5.assessment then
            ld5_set_status("Atsiskaityme neužbaigto etapo praleisti negalima.","warn","Užbaikite dabartinį etapą.");
            return;
        end
        LD5.skipped(LD5.step)=%t;
        ld5_set_status("Etapas praleistas.","info","Galite prie jo grįžti vėliau.");
    end
    ld5_set_step(LD5.step+1);
endfunction

function ld5_set_step(n)
    global LD5;
    if ~ld5_valid_index(n,6) then return; end
    if LD5.demoMode then ld5_toggle_solution(); end
    ld5_save_answers();
    LD5.pending="";
    LD5.step = n;
    if isfield(LD5, "ui") then
        if ~isfield(LD5.ui, "headless") | ~LD5.ui.headless then ld5_render_stage(); end
    end
    bench_autosave("LD5");
endfunction

function s = ld5_step_instruction(n)
    global LD5;
    cfg=LD5.cfg;
    select n
    case 1 then s="Sujunkite įtampos daliklį: šaltinis → jungiklis → ampermetras → R1 → RV → šaltinis. Voltmetrą prijunkite lygiagrečiai aktyviai RV daliai. Maitinimas turi būti išjungtas.";
    case 2 then s=msprintf("Apskaičiuokite teorinę U2, kai E=%g V, R1=%g Ω, RV=%g Ω ir P2=%d %%. Tada įjunkite maitinimą, uždarykite jungiklį, pasirinkite P2 ir spauskite Matuoti.",cfg.E,cfg.R1,cfg.RV,cfg.P2);
    case 3 then s=msprintf("Pamatuokite likusias dvi padėtis: P1=%d %% ir P3=%d %%. Kiekvienai pasirinkite padėtį ir spauskite Matuoti.",cfg.P1,cfg.P3);
    case 4 then s="Apskaičiuokite teorines U1 ir U3, reguliavimo diapazoną ΔU = U3 − U1 ir šį diapazoną procentais nuo šaltinio įtampos E.";
    case 5 then s=msprintf("Padėčiai P2=%d %% apskaičiuokite grandinės srovę I2 ir aktyvios RV dalies santykį su visa R1 + RVd varža.",cfg.P2);
    case 6 then s="Padarykite dvi išvadas: ar išėjimo įtampa reguliuojama sklandžiai ir ar matavimai atitinka įtampos daliklio dėsnį. 1 – Taip, 2 – Ne.";
    else s="";
    end
endfunction

function ld5_save_answers()
    global LD5;
    if LD5.demoMode then return; end
    if ~isfield(LD5, "ui") then return; end
    if isfield(LD5.ui, "headless") then if LD5.ui.headless then return; end end
    if isfield(LD5.ui, "answerEdits") then
        for k = 1:size(LD5.ui.answerEdits, "*")
            h = LD5.ui.answerEdits(k);
            if is_handle_valid(h) then
                [st, sl] = ld5_answer_slot(k);
                if st<>LD5.step | h.visible<>"on" then continue; end
                if LD5.answers(st,sl)<>h.string then LD5.done(st)=%f; end
                LD5.answers(st, sl) = h.string;
            end
        end
    end
endfunction

function [st, sl] = ld5_answer_slot(k)
    mapa = [2 1; 4 1; 4 2; 4 3; 4 4; 5 1; 5 2; 6 1; 6 2];
    st = mapa(k, 1); sl = mapa(k, 2);
endfunction

function ld5_test_answers(step, values)
    global LD5;
    for k = 1:size(values, "*")
        LD5.answers(step, k) = msprintf("%.10g", values(k));
    end
endfunction

function ld5_show_wiring_guide()
    txt=["LD5 · ĮTAMPOS DALIKLIO SUJUNGIMAS"; "";
         "Visuose etapuose naudojama ta pati grandinė.";
         "1. Šaltinis + → jungiklis: [T01]–[T03].";
         "2. Jungiklis → ampermetras +: [T04]–[T05].";
         "3. Ampermetras − → R1 a: [T06]–[T07].";
         "4. R1 b → RV a: [T08]–[T09].";
         "5. RV b → šaltinis −: [T10]–[T02].";
         "6. Voltmetras + → RV a: [T11]–[T09].";
         "7. Voltmetras − → RV b: [T12]–[T10]."; "";
         "Sujungimą keiskite 1 etape, be maitinimo.";
         "Laidą pašalinsite paspaudę abu jo gnybtus.";
         "P1, P2 ir P3 keičia aktyvią RV dalį (RVd).";
         "RVd = RV · padėtis % / 100; voltmetras matuoja U ties RVd."];
    ld5_text_window("KAIP SUJUNGTI", txt);
endfunction

function ld5_show_stand_map()
    global LD5;
    [bids, cbs, blabels, bhints] = ld5_button_registry();
    txt = ["LD5 · STENDO ŽEMĖLAPIS (bankas " + LD5.student.bank + ")"; "";
           "GNYBTAI (T01–T12): šaltinis, jungiklis, ampermetras, R1 (a/b), RV (a/b), voltmetras."; "";
           "MYGTUKAI:"];
    for k = 1:size(bids, "*")
        txt($+1) = "  [" + bids(k) + "] " + blabels(k);
    end
    txt($+1) = ""; txt($+1) = "ETAPAI: [E01]–[E06]. Grįžkite mygtuku Atgal.";
    txt($+1) = "LAUKELIAI: [A02.01], [A04.01]–[A04.04],";
    txt($+1) = "[A05.01]–[A05.02], [A06.01]–[A06.02].";
    txt($+1) = "[V02] – trijų padėčių matavimų žurnalas.";
    ld5_text_window("STENDO ŽEMĖLAPIS", txt);
endfunction

function ld5_text_window(title, lines)
    global LD5;
    if isfield(LD5, "ui") then
        if isfield(LD5.ui, "headless") then if LD5.ui.headless then return; end end
    end
    f = figure("figure_name", "LD5 · " + title, "axes_size", [520 420], ...
               "menubar_visible", "off", "toolbar_visible", "off", "infobar_visible", "off");
    uicontrol(f, "style", "listbox", "units", "normalized", "position", [0.02 0.10 0.96 0.84], ...
              "string", lines, "fontname", "SansSerif", "fontunits", "pixels", "fontsize", 12);
    uicontrol(f, "style", "pushbutton", "units", "normalized", "position", [0.35 0.02 0.3 0.06], ...
              "string", "Uždaryti", "tag", "H01", "callback", "close()");
endfunction

function ld5_toggle_solution()
    global LD5;
    if LD5.demoMode then
        LD5.demoMode = %f;
        LD5.pending="";
        if isfield(LD5, "backup") then
            LD5.wires = LD5.backup.wires; LD5.answers = LD5.backup.answers;
            LD5.position = LD5.backup.position; LD5.journal = LD5.backup.journal;
            LD5.powerOn = LD5.backup.powerOn; LD5.switchOn = LD5.backup.switchOn;
            LD5.lastMeasurement=LD5.backup.lastMeasurement;
        end
        if isfield(LD5, "ui") then
            if ~isfield(LD5.ui, "headless") | ~LD5.ui.headless then ld5_render_stage(); end
        end
        ld5_set_status("Grįžta į savo darbą.","info","Laidai ir atsakymai atkurti.");
        bench_autosave("LD5");
        return;
    end
    if LD5.assessment then
        ld5_set_status("Pavyzdys atsiskaitymo režime nepasiekiamas.","error","Perjunkite į Mokymąsi per Pagalbą."); return;
    end
    ld5_save_answers();
    LD5.backup = struct();
    LD5.backup.wires = LD5.wires; LD5.backup.answers = LD5.answers;
    LD5.backup.position = LD5.position; LD5.backup.journal = LD5.journal;
    LD5.backup.powerOn = LD5.powerOn; LD5.backup.switchOn = LD5.switchOn;
    LD5.backup.lastMeasurement=LD5.lastMeasurement;
    LD5.practice_used=%t;
    LD5.demoMode = %t;
    LD5.wires = ld5_canonical_wires();
    LD5.powerOn = %t; LD5.switchOn = %t; LD5.position = 2;
    LD5.pending=""; LD5.journal=[];
    for pos = 1:3
        LD5.position=pos;
        [u,i,ok,msg]=ld5_measure_values();
        if ok then LD5.journal($+1,:)=[u i pos]; end
    end
    LD5.position=2;
    ld5_set_status("Rodomas mokymosi pavyzdys. Jūsų darbas nepakeistas.","info","Per Pagalbą grįžkite į savo darbą.");
    if isfield(LD5, "ui") then
        if ~isfield(LD5.ui, "headless") | ~LD5.ui.headless then ld5_render_stage(); end
    end
endfunction

function ld5_restore_stage()
    global LD5;
    if LD5.demoMode then ld5_toggle_solution(); return; end
    LD5.pending = "";
    LD5.powerOn=%f; LD5.switchOn=%f; LD5.position=0; LD5.lastMeasurement=%nan;
    if LD5.step == 1 then
        LD5.wires=[]; LD5.report_wires(1)=emptystr(0,2);
        LD5.done(:)=%f; LD5.journal=[];
    end
    ld5_set_status("Etapo stendas atkurtas; maitinimas išjungtas.","info","");
    if isfield(LD5, "ui") then
        if ~isfield(LD5.ui, "headless") | ~LD5.ui.headless then ld5_render_stage(); end
    end
    bench_autosave("LD5");
endfunction

function ld5_restart()
    global LD5;
    ld5_save_answers();
    bench_autosave("LD5");
    if isfield(LD5,"autosave_error") then
        if LD5.autosave_error<>"" then return; end
    end
    cfg=LD5.cfg; st=LD5.student;
    ld5_init_state();
    LD5.cfg=cfg; LD5.student=st;
    LD5.assessment=%t; LD5.practice_used=%f;
    LD5.autosave_paths=emptystr(0,1); LD5.autosave_error="";
    if isfield(LD5,"ui") then
        if ~isfield(LD5.ui,"headless") | ~LD5.ui.headless then ld5_render_stage(); end
    end
    ld5_set_status("Pradėtas naujas atsiskaitymo bandymas.","ok","Ankstesnio bandymo juodraščiai palikti atskirai.");
    bench_autosave("LD5");
endfunction

function ld5_answers_changed()
    // Atsakymo laukelio redagavimas: nedelsiant saugoma į store.
    global LD5;
    ld5_save_answers(); ld5_student_sync(); bench_autosave("LD5");
endfunction

function ld5_close()
    global LD5;
    if ~isfield(LD5,"fig") then return; end
    if ~is_handle_valid(LD5.fig) then return; end
    if LD5.demoMode then ld5_toggle_solution(); end
    ld5_save_answers(); bench_autosave("LD5");
    if isfield(LD5,"autosave_error") then
        if LD5.autosave_error<>"" then
            ld5_set_status("Nepavyko išsaugoti juodraščio.","error","Langas paliktas atvertas, kad neprarastumėte darbo."); return;
        end
    end
    delete(LD5.fig);
endfunction
