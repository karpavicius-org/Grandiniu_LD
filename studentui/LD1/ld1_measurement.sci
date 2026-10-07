// LD1-3: measure and compare. Numerical fields are never student answers.
function yes=ld1_measurement_workflow()
    global LD1; yes=%f;
    if typeof(LD1)<>"st" then return; end
    if isfield(LD1,"measurement_workflow") then yes=LD1.measurement_workflow; end
endfunction

function values=ld1_network_probes(sol,names)
    values=%nan*ones(1,size(names,"*"));
    if ~sol.ok then return; end
    for k=1:size(names,"*")
        index=find(sol.edgeNames==names(k));
        if index<>[] then values(k)=1000*abs(sol.edgeCurrents(index(1))); end
    end
endfunction

function ld1_capture_probes(sol)
    global LD1;
    if LD1.panel=="series" then LD1.seriesProbes(LD1.step,:)=ld1_network_probes(sol,["R1" "VR1"]);
    else LD1.branchProbes(LD1.step,:)=ld1_network_probes(sol,["R3" "R2"]); end
endfunction

function ld1_student_run()
    global LD1;
    if LD1.powerOn then ld1_toggle_power(); else ld1_measure(); end
endfunction

function ld1_measurement_instruction()
    global LD1;
    titles=["Sujunkite grandinę";"Pamatuokite srovę";"Palyginkite sroves";"Pakeiskite varžą"; ...
        "Sujunkite dvi šakas";"Pamatuokite įtampą";"Stebėkite įtampą";"Palyginkite šakų sroves";"Peržiūrėkite darbą"];
    tips=["Sujunkite 4 laidus. Jungimo pagalba paryškina kontaktų porą. Pasirinkite jungimo tipą."; ...
        "Spauskite Įjungti ir matuoti. Rodmenys įsirašo patys. Skaičių įvesti nereikia."; ...
        "Palyginkite automatinių taškų sroves per R1 ir VR1. Matavimo kartoti nereikia."; ...
        "Pasirinkite 500 Ω. Rodmuo atsinaujina pats. Palyginkite srovę prieš ir po."; ...
        "Sujunkite dvi šakas ir voltmetrą. Atsakykite, kaip ŠAKOS sujungtos tarpusavyje."; ...
        "Spauskite Įjungti ir matuoti. Palyginkite voltmetro rodmenį su šaltinio įtampa."; ...
        "Pasirinkite 500 Ω. Rodmuo atsinaujina pats. Palyginkite įtampą prieš ir po."; ...
        "Prijunkite 2 ampermetro laidus ir įjunkite. Palyginkite I su automatinių šakų rodmenų suma."; ...
        "Čia bandymo rodmenys ir jūsų išvados. Išsaugokite vieną HTML ataskaitą dėstytojui."];
    if ld1_guided() & LD1.step<9 then tips(LD1.step)="Mokymosi stendas paruoštas. Stebėkite rodmenis ir pasirinkite savo išvadą."; end
    caption=string(LD1.step)+" / 9 · "+titles(LD1.step);
    if LD1.demoMode then caption="Pavyzdys · "+string(LD1.step)+" / 9"; end
    LD1.ui.instructionTitle.string=student_wrap(caption,26);
    LD1.ui.instructionLine(1).string=student_wrap(tips(LD1.step),37);
    LD1.ui.instructionLine(1).visible="on";
    for k=2:5; LD1.ui.instructionLine(k).visible="off"; end
    explanations=["Vienoje kilpoje sujungti rezistoriai ir ampermetras. Ampermetras jungiamas nuosekliai."; ...
        "Virtualūs matavimo taškai vienu bandymu užfiksuoja sroves per abu rezistorius. Jie neperjungia jūsų laidų."; ...
        "Nuosekliame jungime srovė neturi kur išsišakoti. Todėl skirtingose kilpos vietose ji vienoda."; ...
        "Šaltinio įtampa nekinta. Sumažinus bendrą varžą, per grandinę teka didesnė srovė."; ...
        "Viena šaka yra R3, kita — nuosekliai sujungti R2 ir VR1. Klausiama apie šakų tarpusavio jungimą."; ...
        "Voltmetras prijungtas tarp A ir B, lygiagrečiai šakoms. Jo rodmuo lyginamas su šaltinio įtampa."; ...
        "Šiame darbe naudojamas idealus įtampos šaltinis. Keičiant apkrovos varžą jo įtampa nekinta, nors srovė keičiasi."; ...
        "Ampermetras matuoja srovę prieš išsišakojimą. Virtualūs matavimo taškai užfiksuoja abi šakų sroves. Jų sumą suskaičiuoja programa."; ...
        "Skaitinius duomenis įrašo programa. Dėstytojas vertina jūsų jungimus ir pasirinktus atsakymus."];
    LD1.studentDetail=[tips(LD1.step);"";explanations(LD1.step);""; ...
        "Skaičiavimų įvesti nereikia. Formulės pateiktos Teorijoje kaip papildomas paaiškinimas."; ...
        "Rodmenys yra virtualaus grandinės modelio matavimai. Papildomus matavimo taškus programa nuskaito automatiškai."; ...
        "Toliau išsaugo atsakymą. Atgal leidžia grįžti ir jį pataisyti."];
endfunction

function ld1_measurement_sync()
    global LD1;
    // Snapshot restore briefly uses step 0 while rebuilding the board.
    if LD1.step<1 | LD1.step>9 then return; end
    modeName="Mokymasis"; if LD1.assessment & ~LD1.practice_used then modeName="Atsiskaitymas"; end
    LD1.fig.figure_name="LD1 · "+modeName+" · Matuokite ir palyginkite";
    LD1.ui.studentProgress.string=string(LD1.step)+" / 9 etapas";
    LD1.ui.next.visible="off"; LD1.ui.power.visible="off";
    ld1_show(LD1.ui.standFrame,LD1.step<9);
    ld1_show(LD1.ui.measure,LD1.step<9); ld1_enable(LD1.ui.measure,~LD1.demoMode);
    caption="Įjungti ir matuoti"; if LD1.powerOn then caption="Išjungti"; end
    LD1.ui.measure.string=caption;
    ld1_show(LD1.ui.wiringGuide,LD1.step<9);
    LD1.ui.wiringGuide.string="Jungimo pagalba";
    ld1_show(LD1.ui.undoWire,LD1.step<9); LD1.ui.undoWire.string="Atšaukti laidą";
    ld1_enable(LD1.ui.undoWire,~LD1.powerOn & ~LD1.demoMode & ~ld1_guided() & or(LD1.step==[1 5 8]));
    ld1_enable(LD1.ui.wiringGuide,~LD1.demoMode & ~ld1_guided() & or(LD1.step==[1 5 8]));
    for h=[LD1.ui.modeA LD1.ui.modeV]; h.enable="off"; end
    LD1.ui.modeA.string="A (DC)"; LD1.ui.modeV.string="V (DC)";
    for h=[LD1.ui.vr0 LD1.ui.vr500 LD1.ui.vr1000]
        ld1_enable(h,or(LD1.step==[4 7]) & ~LD1.demoMode & ~ld1_guided());
    end
    ld1_enable(LD1.ui.vrSlider,%f);
    LD1.ui.vr0.string="0 Ω"; LD1.ui.vr500.string="500 Ω"; LD1.ui.vr1000.string="1 kΩ";
    LD1.ui.standMap.string="Kontaktai";
    LD1.ui.standMap.tooltipstring="Kontaktų žinynas: komponentai ir jų T numeriai.";
    LD1.ui.example.string="Pavyzdys"; LD1.ui.example.tooltipstring="Pavyzdys skirtas mokymuisi. Prieš perjungiant paklausiama.";
    if LD1.demoMode then LD1.ui.checkStep.string="Grįžti į savo darbą";
    elseif LD1.step==9 then LD1.ui.checkStep.string="Išsaugoti ataskaitą";
    elseif LD1.assessment | LD1.done(LD1.step) then LD1.ui.checkStep.string="Toliau →";
    else LD1.ui.checkStep.string="Patikrinti"; end
    LD1.ui.checkStep.enable="on";
    if ~isfield(LD1.ui,"measureRows") then return; end
    for k=1:3; LD1.ui.qEdit(k).visible="off"; LD1.ui.qLabel(k).visible="off"; LD1.ui.measureRows(k).visible="off"; end
    typeControls=[LD1.ui.typeSeries LD1.ui.typeParallel LD1.ui.typeMixed];
    for h=typeControls; h.visible="off"; end
    LD1.ui.yes.visible="off"; LD1.ui.no.visible="off"; LD1.ui.yesNoQuestion.visible="off";
    LD1.ui.answerTitle.string="MATAVIMAI IR JŪSŲ IŠVADA";
    LD1.ui.answerTitle.visible="on"; LD1.ui.answerTitle.position=[0 0.88 1 0.12];
    LD1.ui.answerFrame.visible="on"; LD1.ui.answerFrame.position=[0.07 0.18 0.86 0.29];
    if LD1.step==9 then LD1.ui.answerFrame.visible="off"; ld1_measurement_instruction(); return; end
    n=LD1.step; rows=emptystr(0,1); question="";
    series=LD1.seriesProbes(n,:); branches=LD1.branchProbes(n,:); measured=LD1.stepMeas(n);
    if LD1.demoMode & LD1.powerOn then
        sol=ld1_solve_network(); series=ld1_network_probes(sol,["R1" "VR1"]); branches=ld1_network_probes(sol,["R3" "R2"]);
        measured=LD1.lastMeasurement;
    end
    select n
    case 1 then question="Kaip sujungti rezistoriai?";
    case 2 then
        rows=["Per R1: "+ld1_result_value(series(1),3,"mA");"Per VR1: "+ld1_result_value(series(2),3,"mA");"Automatiniai matavimo taškai"];
    case 3 then
        rows=["Per R1: "+ld1_result_value(series(1),3,"mA");"Per VR1: "+ld1_result_value(series(2),3,"mA")]; question="Ar srovės vienodos?";
    case 4 then
        before=LD1.stepMeas(3); if LD1.demoMode then before=1000*LD1.cfg.E/(LD1.cfg.R1+1000); end
        rows=["Prieš: "+ld1_result_value(before,3,"mA");"Po: "+ld1_result_value(measured,3,"mA")]; question="Kaip pasikeitė srovė?";
    case 5 then question="Kaip sujungtos dvi šakos?";
    case 6 then
        rows=["Šaltinis: "+ld1_result_value(LD1.cfg.E,3,"V");"Voltmetras: "+ld1_result_value(measured,3,"V")]; question="Ar įtampos sutampa?";
    case 7 then
        before=LD1.stepMeas(6); if LD1.demoMode then before=LD1.cfg.E; end
        rows=["Prieš: "+ld1_result_value(before,3,"V");"Po: "+ld1_result_value(measured,3,"V")]; question="Kaip pasikeitė įtampa?";
    case 8 then
        rows=["Šaka R3: "+ld1_result_value(branches(1),3,"mA");"Šaka R2 + VR1: "+ld1_result_value(branches(2),3,"mA"); ...
            "Šakų suma: "+ld1_result_value(sum(branches),3,"mA")]; question="Ar ampermetro I lygi sumai?";
    end
    for k=1:size(rows,"*")
        LD1.ui.measureRows(k).string=rows(k); LD1.ui.measureRows(k).visible="on";
        LD1.ui.measureRows(k).position=[0 0.68-(k-1)*0.18 1 0.17];
    end
    if question<>"" then LD1.ui.yesNoQuestion.string=question; LD1.ui.yesNoQuestion.visible="on"; end
    if or(n==[1 5 4 7]) then
        labels=["Nuosekliai" "Lygiagrečiai" "Mišriai"];
        if n==4 | n==7 then labels=["Padidėjo" "Sumažėjo" "Nepakito"]; end
        for k=1:3
            h=typeControls(k); h.string=labels(k); h.visible="on";
            if n==4 | n==7 then h.position=[(k-1)/3 0 1/3 0.19];
            else h.position=[0 0.62-(k-1)*0.20 1 0.18]; end
        end
        if n==5 then LD1.ui.typeMixed.visible="off"; end
        LD1.ui.yesNoQuestion.position=[0 0.25 1 0.15];
        if n==1 | n==5 then LD1.ui.yesNoQuestion.position=[0 0.84 1 0.15]; LD1.ui.answerTitle.visible="off"; end
        if LD1.demoMode & (n==4 | n==7) then
            if n==4 then LD1.ui.typeSeries.value=1; else LD1.ui.typeMixed.value=1; end
        end
    elseif n<>2 then
        LD1.ui.yesNoQuestion.position=[0 0.18 1 0.12];
        LD1.ui.yes.visible="on"; LD1.ui.no.visible="on";
        LD1.ui.yes.position=[0 0 0.46 0.17]; LD1.ui.no.position=[0.5 0 0.46 0.17];
    end
    ld1_measurement_instruction();
endfunction

function ok=ld1_measurement_inputs_present()
    global LD1; ok=%f;
    if LD1.step<=4 then [valid,msg,fix]=ld1_validate_series_topology();
    elseif LD1.step<=7 then [valid,msg,fix]=ld1_validate_parallel_voltage_topology();
    else [valid,msg,fix]=ld1_validate_parallel_total_current_topology(); end
    if ~valid then ld1_set_status(msg,"error",fix); return; end
    target=1000; if LD1.step==4 | LD1.step==7 then target=500; end
    if LD1.step==8 then target=0; end
    if LD1.VR1<>target then ld1_set_status("Pasirinkite "+string(target)+" Ω.","warn","Varžos pasirinkimas yra dešinėje."); return; end
    if or(LD1.step==[2 3 4 6 7 8]) & isnan(LD1.stepMeas(LD1.step)) then
        ld1_set_status("Rodmuo dar neįrašytas.","warn","Spauskite Įjungti ir matuoti."); return;
    end
    if LD1.step<=4 & LD1.step>=2 then
        if or(isnan(LD1.seriesProbes(LD1.step,:))) then ld1_set_status("Trūksta srovės rodmenų.","warn","Išjunkite ir vėl įjunkite bandymą."); return; end
    end
    if LD1.step==8 & or(isnan(LD1.branchProbes(8,:))) then ld1_set_status("Trūksta šakų rodmenų.","warn","Išjunkite ir vėl įjunkite bandymą."); return; end
    if LD1.step==4 & isnan(LD1.stepMeas(3)) then ld1_set_status("Trūksta ankstesnio srovės matavimo.","warn","Grįžkite į srovės matavimo etapą."); return; end
    if LD1.step==7 & isnan(LD1.stepMeas(6)) then ld1_set_status("Trūksta ankstesnio įtampos matavimo.","warn","Grįžkite į įtampos matavimo etapą."); return; end
    if or(LD1.step==[1 4 5 7]) then
        choice=LD1.ui.typeSeries.value+LD1.ui.typeParallel.value+LD1.ui.typeMixed.value;
    else choice=1; if LD1.step<>2 then choice=LD1.ui.yes.value+LD1.ui.no.value; end; end
    if choice<>1 then ld1_set_status("Pasirinkite atsakymą po rodmenimis.","warn",""); return; end
    ok=%t;
endfunction

function pair=ld1_measurement_hint_pair()
    global LD1; pair=emptystr(0,2);
    if ~ld1_measurement_workflow() then return; end
    if ~LD1.wiring_help | LD1.powerOn | LD1.demoMode | ld1_guided() then return; end
    select LD1.step
    case 1 then wires=ld1_series_canonical_wires();
    case 5 then wires=ld1_parallel_voltage_canonical_wires();
    case 8 then wires=["SRC_P" "M_P";"M_N" LD1.kclTargetA];
    else return;
    end
    for k=1:size(wires,1)
        if ~ld1_wire_exists(wires(k,1),wires(k,2)) & ld1_terminal_wire_count(wires(k,1))==0 & ld1_terminal_wire_count(wires(k,2))==0 then
            pair=wires(k,:); return;
        end
    end
endfunction

function ld1_measurement_hint_status()
    global LD1; pair=ld1_measurement_hint_pair();
    if pair<>[] then ld1_set_status("Sujunkite paryškintus kontaktus: "+ld1_terminal_code(pair(1))+" → "+ld1_terminal_code(pair(2))+".","info","Laidą prijungiate patys, paspausdami abu kontaktus.");
    else ld1_set_status("Jungimą patikrinsime įjungiant bandymą.","info","Pasirinkite atsakymą ir tęskite."); end
endfunction

function r=ld1_measurement_report(r)
    global LD1;
    r.lab_revision="3"; r.rubric_version="LD1-3";
    r.answers=list(); r.observations=list();
    for step=[1 5]
        raw=""; if LD1.stepType(step)>0 then raw=string(LD1.stepType(step)); end
        r.answers($+1)=bench_answer(msprintf("s%d.type",step),raw,"choice");
    end
    for step=[3 6 8]
        raw=""; if LD1.stepYesNo(step)>0 then raw=string(LD1.stepYesNo(step)); end
        r.answers($+1)=bench_answer(msprintf("s%d.compare",step),raw,"choice");
    end
    for step=[4 7]
        raw=""; if LD1.stepType(step)>0 then raw=string(LD1.stepType(step)); end
        r.answers($+1)=bench_answer(msprintf("s%d.change",step),raw,"choice");
    end
    for step=[3 4 6 7 8]
        unit="mA"; if step==6 | step==7 then unit="V"; end
        r.observations($+1)=bench_observation(msprintf("s%d.measure",step),LD1.stepMeas(step),unit);
    end
    r.observations($+1)=bench_observation("s3.r1",LD1.seriesProbes(3,1),"mA");
    r.observations($+1)=bench_observation("s3.vr1",LD1.seriesProbes(3,2),"mA");
    r.observations($+1)=bench_observation("s8.r3",LD1.branchProbes(8,1),"mA");
    r.observations($+1)=bench_observation("s8.r2",LD1.branchProbes(8,2),"mA");
    r.evidence.measurement_workflow=%t; r.evidence.automatic_measurement=%t;
    r.evidence.automatic_calculation=%f;
    r.note="Studentas sujungia grandinę, keičia varžą ir pasirenka išvadas. Programa įrašo multimetro rodmenis ir automatinių virtualių matavimo taškų sroves. Skaičiavimų įvesti nereikia. Balai skiriami už studento jungimus ir atsakymus.";
endfunction

function ld1_measurement_check_step()
    global LD1;
    if ~ld1_measurement_inputs_present() then return; end
    ld1_save_step_inputs(); n=LD1.step; expected=1; given=LD1.stepYesNo(n);
    select n
    case 1 then given=LD1.stepType(n);
    case 2 then given=1;
    case 4 then given=LD1.stepType(n);
    case 5 then given=LD1.stepType(n); expected=2;
    case 7 then given=LD1.stepType(n); expected=3;
    end
    if given<>expected then
        ld1_set_status("Dar kartą palyginkite rodmenis.","warn",LD1.studentDetail(3)); return;
    end
    ld1_mark_done("Bandymas užfiksuotas; jūsų išvada teisinga.");
endfunction

function ld1_measurement_results(showExample)
    global LD1;
    v=LD1.stepMeas; s=LD1.seriesProbes(3,:); b=LD1.branchProbes(8,:);
    if showExample then
        s=[1 1]*1000*LD1.cfg.E/(LD1.cfg.R1+1000);
        b=1000*LD1.cfg.E./[LD1.cfg.R3 LD1.cfg.R2];
        v(3)=s(1); v(4)=1000*LD1.cfg.E/(LD1.cfg.R1+500); v(6)=LD1.cfg.E; v(7)=LD1.cfg.E; v(8)=sum(b);
    end
    answers=emptystr(1,5); stages=[3 4 6 7 8];
    for k=1:5
        n=stages(k); answer=LD1.stepYesNo(n); labels=["Taip" "Ne"];
        if n==4 | n==7 then answer=LD1.stepType(n); labels=["Padidėjo" "Sumažėjo" "Nepakito"]; end
        answers(k)="Neatsakyta"; if answer>0 then answers(k)=labels(answer); end
        if showExample then answers(k)="Pavyzdys"; end
    end
    t=["Bandymas" "Ką palyginote" "Rodmuo 1" "Rodmuo 2" "Jūsų atsakymas"; ...
       "3 · Vienos šakos srovės" "Srovės skirtinguose taškuose" "R1: "+ld1_result_value(s(1),3,"mA") "VR1: "+ld1_result_value(s(2),3,"mA") answers(1); ...
       "4 · Pakeista varža" "Srovė sumažinus VR1" "Prieš: "+ld1_result_value(v(3),3,"mA") "Po: "+ld1_result_value(v(4),3,"mA") answers(2); ...
       "6 · Įtampa tarp A ir B" "Šaltinis ir voltmetras" "Šaltinis: "+ld1_result_value(LD1.cfg.E,3,"V") "UAB: "+ld1_result_value(v(6),3,"V") answers(3); ...
       "7 · Pakeista varža" "Įtampa pakeitus VR1" "Prieš: "+ld1_result_value(v(6),3,"V") "Po: "+ld1_result_value(v(7),3,"V") answers(4); ...
       "8 · Šakų srovės" "Bendroji srovė ir šakų suma" "Suma: "+ld1_result_value(sum(b),3,"mA") "I: "+ld1_result_value(v(8),3,"mA") answers(5)];
    LD1.ui.resultsTable.string=t; ld1_results_cards(t);
endfunction
