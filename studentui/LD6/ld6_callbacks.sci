function ld6_invalidate_mode()
    global LD6;
    mode=LD6.wireMode; LD6.report_wires(mode)=emptystr(0,2);
    if LD6.journal<>[] then LD6.journal(find(LD6.journal(:,3)==mode),:)=[]; end
    select mode
    case 1 then LD6.done([1 2])=%f;
    case 2 then LD6.done([3 4])=%f;
    case 3 then LD6.done(4)=%f;
    case 4 then LD6.done(5)=%f;
    end
    LD6.done(6)=%f; LD6.lastMeasurement=%nan;
endfunction

function ld6_terminal_click(id)
    global LD6;
    if ~ld6_wiring_editable() | ~or(ld6_terminal_ids()==id) then return; end
    if LD6.powerOn then
        LD6.pending="";
        ld6_set_status("Prieš keisdami laidus išjunkite maitinimą.","error","Maitinimas turi būti išjungtas prieš bet kokį perjungimą.");
        bench_autosave("LD6"); return;
    end
    if LD6.pending=="" then
        LD6.pending=id;
        ld6_set_status("Pasirinktas "+ld6_terminal_name(id)+".","info","Spauskite kitą gnybtą. Pakartoję esamo laido galus jį pašalinsite.");
    else
        first=LD6.pending; LD6.pending="";
        if first<>id then
            existing=0;
            for row=1:size(LD6.wires,1)
                if and(LD6.wires(row,:)==[first id]) | and(LD6.wires(row,:)==[id first]) then existing=row; break; end
            end
            if existing>0 then
                LD6.wires(existing,:)=[]; ld6_set_status("Laidas pašalintas.","ok","");
            else
                if sum(LD6.wires==first)>=2 | sum(LD6.wires==id)>=2 then
                    ld6_set_status("Gnybte jau yra du laidai.","error","Pirma pašalinkite netinkamą laidą.");
                    ld6_render_wires(); bench_autosave("LD6"); return;
                end
                LD6.wires($+1,:)=[first id]; ld6_set_status("Laidas pridėtas.","ok","");
            end
            LD6.wires_by_mode(LD6.wireMode)=LD6.wires;
            LD6.switchOn=%f; ld6_invalidate_mode();
        end
    end
    ld6_render_wires(); ld6_render_journal(); ld6_student_sync(); bench_autosave("LD6");
endfunction

function ld6_toggle_power()
    global LD6;
    LD6.powerOn=~LD6.powerOn;
    if ~LD6.powerOn then LD6.switchOn=%f; end
    ld6_render_wires();
    if LD6.powerOn then ld6_set_status("Maitinimas įjungtas.","ok","Uždarykite jungiklį.");
    else ld6_set_status("Maitinimas išjungtas.","info","Galima saugiai keisti šio etapo laidus."); end
    bench_autosave("LD6");
endfunction

function ld6_toggle_switch()
    global LD6;
    if ~LD6.powerOn then ld6_set_status("Pirmiausia įjunkite maitinimą.","error",""); return; end
    LD6.switchOn=~LD6.switchOn; ld6_render_wires();
    if LD6.switchOn then ld6_set_status("Jungiklis uždarytas.","ok","Spauskite Matuoti.");
    else ld6_set_status("Jungiklis atviras.","info",""); end
    bench_autosave("LD6");
endfunction

function ld6_set_mode(mode)
    global LD6;
    if LD6.demoMode | ~ld6_valid_index(mode,4) then return; end
    if mode<>LD6.wireMode then
        LD6.wires_by_mode(LD6.wireMode)=LD6.wires;
        LD6.wireMode=mode; LD6.wires=LD6.wires_by_mode(mode);
        LD6.powerOn=%f; LD6.switchOn=%f; LD6.pending=""; LD6.lastMeasurement=%nan;
    end
    ld6_render_wires();
    ld6_set_status("Režimas: "+ld6_mode_name(mode),"info","Maitinimas išjungtas. Šio režimo laidai išliko; jungimo seką rasite Pagalboje.");
    bench_autosave("LD6");
endfunction

function ld6_measure()
    global LD6;
    if LD6.demoMode then return; end
    if ~or(LD6.step==[2 3 4 5]) | LD6.wireMode<>ld6_stage_mode(LD6.step) then
        ld6_set_status("Pasirinkite šio etapo jungimą.","error","Reikiamas režimas nurodytas užduotyje."); return;
    end
    [voltage,current,ok,message,branches]=ld6_measure_values();
    if ~ok then ld6_set_status(message,"error",""); return; end
    if ld6_journal_rows(LD6.wireMode)<>[] then
        ld6_set_status("Šis režimas jau išmatuotas.","info","Rodmenys išsaugoti žurnale."); return;
    end
    LD6.journal($+1,:)=[voltage current LD6.wireMode branches];
    LD6.report_wires(LD6.wireMode)=LD6.wires;
    LD6.lastMeasurement=current;
    ld6_render_journal(); ld6_render_wires();
    ld6_set_status(msprintf("Užfiksuota: U = %.4f V; I = %.3f mA.",voltage,current),"ok","Neigiamas ženklas reiškia priešingą srovės kryptį.");
    bench_autosave("LD6");
endfunction

function ok=ld6_close_enough(value,expected,relative,absolute)
    if argn(2)<3 then relative=.02; end
    if argn(2)<4 then absolute=1e-9; end
    ok=%f;
    if isnan(value) | isinf(value) | isnan(expected) | isinf(expected) then return; end
    ok=abs(value-expected)<=absolute+relative*abs(expected);
endfunction

function ld6_check_step(check_answers)
    global LD6;
    if argn(2)<1 then check_answers=%t; end
    if LD6.demoMode then return; end
    ld6_save_answers(); step=LD6.step;
    if ~ld6_valid_index(step,6) then return; end
    if LD6.done(step) then ld6_set_status("Etapas jau atliktas.","ok","Spauskite Toliau."); return; end

    if step==1 then
        if LD6.wireMode<>1 then ld6_set_status("Pirmiausia pasirinkite E1 režimą.","error",""); return; end
        [valid,message]=ld6_wiring_valid(LD6.wires);
        if ~valid then ld6_set_status(message,"error","Jei reikia, atverkite Pagalba → Kaip sujungti."); return; end
        LD6.report_wires(1)=LD6.wires;
    elseif or(step==[2 3 4 5]) then
        modes=ld6_stage_mode(step); if step==4 then modes=[2 3]; end
        for mode=modes
            if ld6_journal_rows(mode)==[] then
                ld6_set_status("Trūksta matavimo: "+ld6_mode_name(mode)+".","error","Sujunkite grandinę, įjunkite maitinimą, uždarykite jungiklį ir spauskite Matuoti."); return;
            end
        end
    end

    expected=ld6_expected_answers();
    labels=emptystr(6,8);
    labels(2,1)="E1 apkrovos srovę";
    labels(4,1)="nuoseklių šaltinių bendrą EV EΣ";
    labels(4,2)="priešpriešinių šaltinių bendrą EV EΔ";
    labels(5,1)="lygiagrečių šaltinių ekvivalentinę EV Eeq";
    labels(5,2)="lygiagrečių šaltinių ekvivalentinę vidinę varžą req";
    labels(6,1)="pirmą išvadą";
    labels(6,2)="antrą išvadą";

    for index=1:7
        [answer_step,slot]=ld6_answer_slot(index);
        if answer_step<>step then continue; end
        raw=stripblanks(LD6.answers(step,slot));
        if raw=="" then
            ld6_set_status("Įrašykite "+labels(step,slot)+".","error","Atsakymo teisingumą vertins dėstytojo programa."); return;
        end
        if step==6 then
            if raw<>"1" & raw<>"2" then
                ld6_set_status("Abiem išvadoms pasirinkite tik 1 arba 2.","error","1 – Taip, 2 – Ne."); return;
            end
            if check_answers then
                if raw<>string(expected(step,slot)) then
                    ld6_set_status("Išvada neteisinga.","error","Palyginkite savo keturių jungimo režimų matavimus."); return;
                end
            end
        else
            value=ld6_parse_number(raw);
            if isnan(value) then
                ld6_set_status("Įrašykite skaičių: "+labels(step,slot)+".","error","Tinka kablelis arba taškas; formulės ir vieneto į lauką nerašykite."); return;
            end
            if check_answers then
                if ~ld6_close_enough(value,expected(step,slot),.01,1e-9) then
                    ld6_set_status("Patikrinkite "+labels(step,slot)+".","error","Naudokite priskirtas E1, E2, r1 ir r2 reikšmes; išlaikykite ženklą."); return;
                end
            end
        end
    end

    LD6.done(step)=%t; ld6_render_stage();
    if check_answers then ld6_set_status(string(step)+" etapas patikrintas.","ok","Spauskite Toliau.");
    else ld6_set_status(string(step)+" etapo duomenys įrašyti.","ok","Teisingumą vertins dėstytojo programa."); end
endfunction

function ld6_next_step()
    global LD6;
    if LD6.step>=6 then return; end
    if ~LD6.done(LD6.step) then
        if LD6.assessment then
            ld6_set_status("Atsiskaityme neužbaigto etapo praleisti negalima.","warn","Užbaikite dabartinį etapą.");
            return;
        end
        LD6.skipped(LD6.step)=%t;
        ld6_set_status("Etapas praleistas.","info","Galite prie jo grįžti vėliau.");
    end
    ld6_set_step(LD6.step+1);
endfunction

function ld6_set_step(step)
    global LD6;
    if ~ld6_valid_index(step,6) then return; end
    if LD6.demoMode then ld6_toggle_solution(); end
    ld6_save_answers(); LD6.pending=""; LD6.step=step;
    ld6_set_mode(ld6_stage_mode(step)); ld6_render_stage(); bench_autosave("LD6");
endfunction

function text=ld6_step_instruction(step)
    global LD6;
    cfg=LD6.cfg;
    select step
    case 1 then text="Sujunkite grandinę tik su šaltiniu E1: E1 → jungiklis → ampermetras → apkrova R → E1. Voltmetrą prijunkite prie R galų. Maitinimas turi būti išjungtas.";
    case 2 then text=msprintf("Apskaičiuokite E1 apkrovos srovę I = 1000·E1/(R+r1), kai E1=%g V, R=%g Ω ir r1=%g Ω. Tada įjunkite maitinimą, uždarykite jungiklį ir spauskite Matuoti. Rodmenų perrašyti nereikia.",cfg.E1,cfg.R,cfg.r1);
    case 3 then text="Išjunkite maitinimą ir sujunkite šaltinius nuosekliai: E1− su E2+. Tada įjunkite maitinimą, uždarykite jungiklį ir spauskite Matuoti. Rodmenys lieka žurnale.";
    case 4 then text="Išjunkite maitinimą ir sujunkite šaltinius priešpriešiais. Išmatuokite grandinę. Tada apskaičiuokite šaltinių bendras EV: EΣ = E1 + E2 ir EΔ = E1 − E2. EΔ ženklą išlaikykite.";
    case 5 then text=msprintf("Išjunkite maitinimą ir sujunkite šaltinius lygiagrečiai: + su +, − su −. Išmatuokite grandinę. Apskaičiuokite Eeq=(E1/r1+E2/r2)/(1/r1+1/r2) ir req=1/(1/r1+1/r2), kai r1=r2=%g Ω. Rodmenų perrašyti nereikia.",cfg.r1);
    case 6 then text="Pagal keturių režimų matavimus padarykite dvi išvadas: ar nuosekliai EV sudedamos su ženklais ir ar lygiagrečiai apkrovos įtampa lygi E1+E2. 1 – Taip, 2 – Ne.";
    else text="";
    end
endfunction

function ld6_save_answers()
    global LD6;
    if LD6.demoMode | ~isfield(LD6,"ui") then return; end
    if isfield(LD6.ui,"headless") then if LD6.ui.headless then return; end; end
    if ~isfield(LD6.ui,"answerEdits") then return; end
    for index=1:size(LD6.ui.answerEdits,"*")
        handle=LD6.ui.answerEdits(index);
        if ~is_handle_valid(handle) then continue; end
        [step,slot]=ld6_answer_slot(index);
        if step<>LD6.step | handle.visible<>"on" then continue; end
        if LD6.answers(step,slot)<>handle.string then LD6.done(step)=%f; end
        LD6.answers(step,slot)=handle.string;
    end
endfunction

function [step,slot]=ld6_answer_slot(index)
    mapping=[2 1;4 1;4 2;5 1;5 2;6 1;6 2];
    step=mapping(index,1); slot=mapping(index,2);
endfunction

function ld6_test_answers(step,values)
    global LD6;
    for index=1:size(values,"*"); LD6.answers(step,index)=msprintf("%.17g",values(index)); end
endfunction

function name=ld6_mode_name(mode)
    names=["E1";"Nuosekliai";"Priešpriešiais";"Lygiagrečiai"]; name=names(mode);
endfunction

function ld6_show_wiring_guide()
    global LD6;
    text=["LD6 · "+ld6_mode_name(LD6.wireMode);"";"Išjunkite maitinimą prieš jungdami laidus."];
    wires=ld6_canonical_wires(LD6.wireMode);
    for index=1:size(wires,1)
        text($+1)=msprintf("%d. [%s]–[%s]: %s → %s",index,ld6_terminal_code(wires(index,1)),ld6_terminal_code(wires(index,2)),wires(index,1),wires(index,2));
    end
    text=[text;"";"Voltmetro zondai visada jungiami prie R galų.";"Šaltinių vidinės varžos r1 = r2 = 10 Ω.";"Lygiagrečiai sujungus nevienodas EV, srovė gali";"tekėti į mažesnės EV šaltinį. Jos ženklas neigiamas."];
    ld6_text_window("Kaip sujungti",text);
endfunction

function ld6_show_stand_map()
    [ids,callbacks,labels,hints]=ld6_button_registry();
    text=["LD6 · STENDO ŽEMĖLAPIS";"T01/T02 – E1; T03/T04 – E2; T05/T06 – jungiklis.";"T07/T08 – ampermetras; T09/T10 – apkrova R.";"T11/T12 – voltmetras. Ženklai rodo poliškumą.";""];
    for index=1:size(ids,"*"); text($+1)="["+ids(index)+"] "+labels(index); end
    text=[text;"";"Etapai E01–E06. V02 – keturių režimų žurnalas.";"A02.01 – teorinė E1 srovė; A04.01/A04.02 – EΣ ir EΔ.";"A05.01/A05.02 – Eeq ir req.";"A06.01/A06.02 – išvados."];
    ld6_text_window("Žemėlapis",text);
endfunction

function ld6_text_window(title,lines)
    global LD6;
    if LD6.ui.headless then return; end
    window=figure("figure_name","LD6 · "+title,"axes_size",[560 420], ...
        "menubar_visible","off","toolbar_visible","off","infobar_visible","off");
    uicontrol(window,"style","listbox","units","normalized","position",[.02 .10 .96 .84], ...
        "string",lines,"fontname","SansSerif","fontunits","pixels","fontsize",12);
    uicontrol(window,"style","pushbutton","units","normalized","position",[.35 .02 .30 .06], ...
        "string","Uždaryti","tag","H01","callback","close()");
endfunction

function ld6_toggle_solution()
    global LD6;
    if LD6.demoMode then
        LD6.demoMode=%f;
        for field=["wires" "answers" "wireMode" "journal" "powerOn" "switchOn" "lastMeasurement"]
            LD6(field)=LD6.backup(field);
        end
        LD6.pending=""; ld6_render_stage(); ld6_set_status("Grįžta į savo darbą.","info",""); bench_autosave("LD6"); return;
    end
    if LD6.assessment then
        ld6_set_status("Pavyzdys atsiskaitymo režime nepasiekiamas.","error","Perjunkite į Mokymąsi per Pagalbą."); return;
    end
    ld6_save_answers(); LD6.backup=struct();
    for field=["wires" "answers" "wireMode" "journal" "powerOn" "switchOn" "lastMeasurement"]
        LD6.backup(field)=LD6(field);
    end
    LD6.practice_used=%t; LD6.demoMode=%t; LD6.pending="";
    LD6.wires=ld6_canonical_wires(LD6.wireMode); LD6.powerOn=%t; LD6.switchOn=%t;
    [voltage,current,ok,message,branches]=ld6_measure_values();
    LD6.journal=[]; if ok then LD6.journal=[voltage current LD6.wireMode branches]; end
    ld6_render_stage(); ld6_set_status("PAVYZDYS: šio režimo sujungimas.","info","Grįžkite į savo darbą pagrindiniu mygtuku.");
endfunction

function ld6_restore_stage()
    global LD6;
    if LD6.demoMode then ld6_toggle_solution(); return; end
    LD6.powerOn=%f; LD6.switchOn=%f; LD6.pending=""; LD6.lastMeasurement=%nan;
    if ld6_wiring_editable() then
        LD6.wires=emptystr(0,2); LD6.wires_by_mode(LD6.wireMode)=LD6.wires; ld6_invalidate_mode();
    end
    ld6_render_stage(); ld6_set_status("Šio etapo stendas atkurtas; maitinimas išjungtas.","info","");
    bench_autosave("LD6");
endfunction

function ld6_restart()
    global LD6;
    ld6_save_answers();
    bench_autosave("LD6");
    if isfield(LD6,"autosave_error") then
        if LD6.autosave_error<>"" then return; end
    end
    cfg=LD6.cfg; st=LD6.student;
    ld6_init_state();
    LD6.cfg=cfg; LD6.student=st;
    LD6.assessment=%t; LD6.practice_used=%f;
    LD6.autosave_paths=emptystr(0,1); LD6.autosave_error="";
    if isfield(LD6,"ui") then
        if ~isfield(LD6.ui,"headless") | ~LD6.ui.headless then ld6_render_stage(); end
    end
    ld6_set_status("Pradėtas naujas atsiskaitymo bandymas.","ok","Ankstesnio bandymo juodraščiai palikti atskirai.");
    bench_autosave("LD6");
endfunction

function ld6_answers_changed()
    ld6_save_answers(); ld6_student_sync(); bench_autosave("LD6");
endfunction

function ld6_close()
    global LD6;
    if ~isfield(LD6,"fig") then return; end
    if ~is_handle_valid(LD6.fig) then return; end
    if LD6.demoMode then ld6_toggle_solution(); end
    ld6_save_answers(); bench_autosave("LD6");
    if isfield(LD6,"autosave_error") then
        if LD6.autosave_error<>"" then
            ld6_set_status("Nepavyko išsaugoti juodraščio.","error","Langas paliktas atvertas, kad neprarastumėte darbo."); return;
        end
    end
    delete(LD6.fig);
endfunction
