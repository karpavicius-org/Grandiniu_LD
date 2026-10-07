// ============================================================================
// LD3 veiksmų logika: laidai, matavimai, etapų tikrinimas, pagalbiniai langai.
// ============================================================================

function ld3_terminal_click(id)
    global LD3;
    if LD3.demoMode then ld3_set_status("Pavyzdyje laidai jau sujungti.","info","Grįžkite į savo darbą per Pagalbą."); return; end
    if LD3.step ~= 1 & ~LD3.done(1) then
        ld3_set_status("Pirmiausia užbaikite 1 etapo sujungimą.","error","Mygtuku ← Atgal grįžkite į 1 etapą.");
        return;
    end
    if LD3.pending == "" then
        LD3.pending = id;
        ld3_set_status("Pasirinktas "+ld3_terminal_name(id)+".","info","Dabar spauskite antrąjį sujungiamo gnybtą.");
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
            ld3_set_status("Šis gnybtas jau turi du laidus.","error","Pasirinkite kitą schemoje nurodytą gnybtą.");
            return;
        end
        LD3.wires($+1, :) = [LD3.pending, id];
        LD3.pending = "";
        ld3_set_status("Laidas pridėtas (" + string(size(LD3.wires,1)) + "/6).","ok","");
        if size(LD3.wires, 1) >= 6 then
            [wok, wwhy] = ld3_wiring_valid(LD3.wires);
            if wok then ld3_set_status("Sujungimas užbaigtas.","ok","Spauskite Toliau."); end
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
        ld3_set_status("Maitinimas įjungtas.","ok","Dabar uždarykite jungiklį.");
    else
        ld3_set_status("Maitinimas išjungtas.","info","Įtampą pasirinkite vienu iš U1, U2 arba U3 mygtukų.");
    end
    ld3_render_wires(); bench_autosave("LD3");
endfunction

function ld3_toggle_switch()
    global LD3;
    if ~LD3.powerOn then
        ld3_set_status("Negalima uždaryti jungiklio be maitinimo.","error","Pirmiausia įjunkite maitinimą.");
        return;
    end
    LD3.switchOn = ~LD3.switchOn;
    if LD3.switchOn then ld3_set_status("Jungiklis uždarytas.","ok","Pasirinkite U1, U2 arba U3 ir spauskite Matuoti."); end
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
        ld3_set_status("Šis įtampos taškas jau užfiksuotas.","error","Pasirinkite kitą U reikšmę.");
        return;
    end
    if size(LD3.journal, 1) >= 3 then
        ld3_set_status("Visi trys taškai jau užfiksuoti.","info","Eikite toliau.");
        return;
    end
    LD3.journal($+1, :) = [u, i];
    LD3.lastMeasurement = i;
    ld3_set_status(msprintf("Užfiksuota: U = %g V, I = %.2f mA (%d/3 taškai).", u, i, size(LD3.journal,1)), "ok", ...
        msprintf("Rodmuo įrašytas į matavimų sąrašą."));
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
    n=LD3.step;
    if LD3.done(n) then ld3_set_status("Etapas jau atliktas.","ok","Spauskite Toliau."); return; end
    select n
    case 1 then
        [wok,wwhy]=ld3_wiring_valid(LD3.wires);
        if ~wok then ld3_set_status(wwhy,"error","Jei reikia, atverkite Pagalba → Kaip sujungti."); return; end
        LD3.done(1)=%t;
        ld3_set_status("Grandinė sujungta ir 1 etapas užfiksuotas.","ok","Spauskite Toliau.");
    case 2 then
        raw=stripblanks(LD3.answers(2,1));
        if raw=="" then ld3_set_status("Įrašykite teorinę srovę I1, mA.","error","Atsakymo teisingumą vertins dėstytojo programa."); return; end
        v=ld3_parse_number(raw);
        if isnan(v) then ld3_set_status("Teorinė srovė turi būti skaičius.","error","Tinka kablelis arba taškas; formulės ir vieneto į lauką nerašykite."); return; end
        if check_answers then
            e=LD3.cfg.U1/LD3.cfg.R*1000;
            if ~ld3_close_enough(v,e) then ld3_set_status("Teorinė srovė netiksli.","error",msprintf("Tikimasi ≈ %.2f mA.",e)); return; end
        end
        if size(LD3.journal,1)<1 then ld3_set_status("Trūksta pirmo matavimo.","error","Pasirinkite U1 ir spauskite Matuoti."); return; end
        LD3.done(2)=%t;
        ld3_set_status("2 etapas užfiksuotas.","ok","Spauskite Toliau.");
    case 3 then
        if size(LD3.journal,1)<3 then
            truksta=3-size(LD3.journal,1);
            ld3_set_status("Trūksta "+string(truksta)+" matavimo taškų.","error","Pamatuokite likusias U2 ir U3 reikšmes."); return;
        end
        LD3.done(3)=%t;
        ld3_set_status("Trys matavimo taškai užfiksuoti.","ok","Spauskite Toliau.");
    case 4 then
        exp=ld3_expected_answers();
        labels=["R1";"R2";"R3";"R vidurkis"];
        for k=1:4
            raw=stripblanks(LD3.answers(4,k));
            if raw=="" then ld3_set_status("Įrašykite "+labels(k)+", Ω.","error","Atsakymo teisingumą vertins dėstytojo programa."); return; end
            v=ld3_parse_number(raw);
            if isnan(v) then ld3_set_status(labels(k)+" turi būti skaičius.","error","Tinka kablelis arba taškas; vieneto į lauką nerašykite."); return; end
            if check_answers then
                if ~ld3_close_enough(v,ld3_parse_number(exp(4,k))) then
                    ld3_set_status(labels(k)+" reikšmė netiksli.","error",msprintf("Tikimasi ≈ %s Ω.",exp(4,k))); return;
                end
            end
        end
        LD3.done(4)=%t;
        ld3_set_status("4 etapas užfiksuotas.","ok","Spauskite Toliau.");
    case 5 then
        raw=stripblanks(LD3.answers(5,1));
        if raw=="" then ld3_set_status("Įrašykite R iš nuolydžio, Ω.","error","Atsakymo teisingumą vertins dėstytojo programa."); return; end
        v=ld3_parse_number(raw);
        if isnan(v) then ld3_set_status("R iš nuolydžio turi būti skaičius.","error","Tinka kablelis arba taškas; vieneto į lauką nerašykite."); return; end
        if check_answers then
            e=LD3.cfg.R;
            if ~ld3_close_enough(v,e) then ld3_set_status("R iš nuolydžio netiksli.","error",msprintf("Tikimasi ≈ %g Ω.",e)); return; end
        end
        LD3.done(5)=%t;
        ld3_set_status("5 etapas užfiksuotas.","ok","Spauskite Toliau.");
    case 6 then
        for k=1:2
            raw=stripblanks(LD3.answers(6,k));
            if raw<>"1" & raw<>"2" then
                ld3_set_status("Abiem išvadoms pasirinkite 1 arba 2.","error","1 – Taip, 2 – Ne."); return;
            end
        end
        if check_answers then
            if LD3.answers(6,1)<>"1" then ld3_set_status("Pirma išvada neteisinga.","error","Palyginkite tris I(U) matavimo taškus."); return; end
            if LD3.answers(6,2)<>"1" then ld3_set_status("Antra išvada neteisinga.","error","Palyginkite tris apskaičiuotas R reikšmes."); return; end
        end
        LD3.done(6)=%t;
        ld3_set_status("Darbas užfiksuotas.","ok","Spauskite Išsaugoti ataskaitą.");
    end
    if isfield(LD3,"ui") then
        if ~isfield(LD3.ui,"headless") | ~LD3.ui.headless then ld3_render_stage(); end
    end
    if ~check_answers then ld3_set_status(string(n)+" etapo duomenys įrašyti.","ok","Teisingumą vertins dėstytojo programa."); end
endfunction

function ld3_next_step()
    global LD3;
    if LD3.step>=6 then return; end
    if ~LD3.done(LD3.step) then
        if LD3.assessment then
            ld3_set_status("Atsiskaityme neužbaigto etapo praleisti negalima.","warn","Užbaikite dabartinį etapą.");
            return;
        end
        LD3.skipped(LD3.step)=%t;
        ld3_set_status("Etapas praleistas.","info","Galite prie jo grįžti vėliau.");
    end
    ld3_set_step(LD3.step+1);
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
    cfg=LD3.cfg;
    select n
    case 1 then s="Sujunkite nuoseklią grandinę šaltinis → jungiklis → ampermetras → R1 → šaltinis. Voltmetrą prijunkite lygiagrečiai R1. Maitinimas turi būti išjungtas.";
    case 2 then s=msprintf("Apskaičiuokite teorinę srovę I1 = U1/R·1000, kai U1=%d V ir R=%d Ω. Įrašykite rezultatą, tada įjunkite maitinimą, uždarykite jungiklį, pasirinkite U1 ir spauskite Matuoti.",cfg.U1,cfg.R);
    case 3 then s=msprintf("Pamatuokite dar du taškus: pasirinkite U2=%d V ir Matuoti, tada U3=%d V ir Matuoti. Matavimų sąraše turi būti 3 taškai.",cfg.U2,cfg.U3);
    case 4 then s="Iš kiekvieno matavimo apskaičiuokite R = U/I ir įrašykite R1, R2, R3 bei jų vidurkį.";
    case 5 then s="Pagal pirmą ir trečią tašką apskaičiuokite R iš I(U) charakteristikos nuolydžio: R = ΔU / ΔI.";
    case 6 then s="Padarykite dvi išvadas: ar I(U) charakteristika tiesinė ir ar apskaičiuota R išlieka pastovi. 1 – Taip, 2 – Ne.";
    else s="";
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
              "string", "Uždaryti", "tag", "H01", "callback", "close()");
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
    ld3_set_status("Rodomas mokymosi pavyzdys. Jūsų darbas nepakeistas.","info","Per Pagalbą grįžkite į savo darbą.");
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
    ld3_save_answers();
    bench_autosave("LD3");
    if isfield(LD3,"autosave_error") then
        if LD3.autosave_error<>"" then return; end
    end
    cfg=LD3.cfg; st=LD3.student;
    ld3_init_state();
    LD3.cfg=cfg; LD3.student=st;
    LD3.assessment=%t; LD3.practice_used=%f;
    LD3.autosave_paths=emptystr(0,1); LD3.autosave_error="";
    if isfield(LD3,"ui") then
        if ~isfield(LD3.ui,"headless") | ~LD3.ui.headless then ld3_render_stage(); end
    end
    ld3_set_status("Pradėtas naujas atsiskaitymo bandymas.","ok","Ankstesnio bandymo juodraščiai palikti atskirai.");
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
