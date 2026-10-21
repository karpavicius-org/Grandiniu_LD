// Opt-in visible guidance. Opening it does not perform an experiment or fill answers.
function ld5_guide_show()
    global LD5;
    if typeof(LD5)<>"st" then return; end
    LD5.guide_enabled=%t;
    ld5_guide_refresh();
endfunction

function [lines,tag,value]=ld5_guide_next()
    global LD5;
    c=LD5.cfg;n=LD5.step;tag="LD5_PRIMARY";value="";
    purpose="KAM: potenciometras yra reguliuojama varža. Išbandome tris jo padėtis ir stebime, kaip jos keičia išėjimo įtampą. Tai įtampos reguliatoriaus principas.";
    lines="DABAR spauskite geltoną pagrindinį mygtuką dešinėje.";
    if LD5.demoMode then lines="DABAR spauskite pagrindinį mygtuką ir grįžkite į savo darbą. Šiuo metu matote pavyzdį.";return;end
    if n==1 then
        [wlines,wtag]=ld5_guide_wire_next(ld5_canonical_wires());
        if wtag<>"" then tag=wtag;lines=[wlines;purpose;"Vedlys pažymi vieną kitą kontaktą. Užbaigus laidą pažymės kito laido pradžią."];return;end
    end
    if LD5.done(n) then
        if n==6 & and(LD5.done) then lines="DABAR spauskite geltoną ĮRAŠYTI ATASKAITĄ. Programa sukurs jūsų matavimų HTML failą.";
        else lines="DABAR spauskite geltoną TOLIAU →. Šio etapo duomenys jau užfiksuoti.";end
        lines=[lines;purpose];return;
    end
    if n==1 then lines=["DABAR spauskite geltoną pagrindinį mygtuką: visi 7 laidai sujungti, pereisime prie pirmo bandymo.";purpose];return;end
    if or(n==[2 3]) then
        [wok,why]=ld5_wiring_valid(LD5.wires);
        if ~wok then tag="LD5_BACK";lines=["DABAR spauskite geltoną ← Atgal. Grįžkite iki 1 etapo; ten vedlys parodys, kaip pataisyti laidus.";why];return;end
        if n==2 then
            rv=c.RV*c.P2/100;u=c.E*rv/(c.R1+rv);
            [lines,tag,value]=ld5_guide_input(1,u,msprintf("TEORIJA: aktyvi RV dalis = %g × %g/100 = %.10g Ω. U2 = E × RVd/(R1+RVd) = %g × %.10g/(%g+%.10g) = %.10g V.",c.RV,c.P2,rv,c.E,rv,c.R1,rv,u));
            if tag<>"" then lines=[lines;purpose];return;end
            indices=[2];
        else indices=[1 2 3];end
        [lines,tag]=ld5_guide_measure_next(indices);
        if tag<>"" then lines=[lines;purpose];return;end
    elseif n>=4 then
        for k=1:3
            if size(ld5_journal_rows(k),1)==0 then
                tag="LD5_BACK";lines=msprintf("DABAR spauskite geltoną ← Atgal: trūksta P%d bandymo. Grįžkite iki 3 etapo; ten vedlys pažymės trūkstamą padėtį ir matavimą.",k);return;
            end
        end
        rv1=c.RV*c.P1/100;rv2=c.RV*c.P2/100;rv3=c.RV*c.P3/100;
        u1=c.E*rv1/(c.R1+rv1);u2=c.E*rv2/(c.R1+rv2);u3=c.E*rv3/(c.R1+rv3);
        if n==4 then
            nums=[u1 u3 u3-u1 100*(u3-u1)/c.E];
            formulas=[msprintf("P1: aktyvi RV dalis = %g × %g/100 = %.10g Ω; U1 = %g × %.10g/(%g+%.10g) = %.10g V.",c.RV,c.P1,rv1,c.E,rv1,c.R1,rv1,u1); ...
                msprintf("P3: aktyvi RV dalis = %g × %g/100 = %.10g Ω; U3 = %g × %.10g/(%g+%.10g) = %.10g V.",c.RV,c.P3,rv3,c.E,rv3,c.R1,rv3,u3); ...
                msprintf("REGULIAVIMO DIAPAZONAS: ΔU = U3 − U1 = %.10g − %.10g = %.10g V. Tai įtampos pokytis tarp dviejų kraštinių bandytų padėčių.",u3,u1,u3-u1); ...
                msprintf("Diapazonas procentais nuo šaltinio: 100 × ΔU/E = 100 × %.10g/%g = %.10g %%.",u3-u1,c.E,nums(4))];
        elseif n==5 then
            nums=[1000*c.E/(c.R1+rv2) 100*rv2/(c.R1+rv2)];
            formulas=[msprintf("P2 SROVĖ: I2 = 1000 × E/(R1+RVd2) = 1000 × %g/(%g+%.10g) = %.10g mA.",c.E,c.R1,rv2,nums(1)); ...
                msprintf("VARŽŲ SANTYKIS: 100 × RVd2/(R1+RVd2) = 100 × %.10g/(%g+%.10g) = %.10g %%. Tai aktyvios varžos dalis visoje grandinėje, ne rankenėlės padėtis %g %%.",rv2,c.R1,rv2,nums(2),c.P2)];
        else
            a=ld5_journal_rows(1);b=ld5_journal_rows(2);d=ld5_journal_rows(3);
            ordered=a(1,1)<b(1,1) & b(1,1)<d(1,1);
            agrees=max(abs([a(1,1)-u1 b(1,1)-u2 d(1,1)-u3]))<=0.02*max([u1 u2 u3]);
            first=2;second=2;if ordered then first=1;end;if agrees then second=1;end
            nums=[first second];
            formulas=[msprintf("IŠVADA IŠ JŪSŲ ŽURNALO: P1=%g %% → %.10g V; P2=%g %% → %.10g V; P3=%g %% → %.10g V. Didinant aktyvią RV dalį įtampa didėja. 1 – Taip, 2 – Ne.",c.P1,a(1,1),c.P2,b(1,1),c.P3,d(1,1)); ...
                msprintf("PALYGINIMAS: žurnalas [%.10g; %.10g; %.10g] V, daliklio formulė [%.10g; %.10g; %.10g] V. Sutampant rodmenims dėsnis pasitvirtina. 1 – Taip, 2 – Ne.",a(1,1),b(1,1),d(1,1),u1,u2,u3)];
        end
        for k=1:size(nums,"*")
            [lines,tag,value]=ld5_guide_input(k,nums(k),formulas(k));
            if tag<>"" then lines=[lines;purpose];return;end
        end
    end
    tag="LD5_PRIMARY";value="";lines=["DABAR spauskite geltoną pagrindinį mygtuką dešinėje. Reikalingi bandymai ir laukai paruošti; užfiksuosime etapą.";purpose];
endfunction

function [lines,tag]=ld5_guide_measure_next(indices)
    global LD5;
    lines=emptystr(0,1);tag="";k=0;
    for index=matrix(indices,1,-1)
        if size(ld5_journal_rows(index),1)==0 then k=index;break;end
    end
    if k==0 then return;end
    if ~LD5.powerOn then tag="B01";lines="DABAR spauskite geltoną Maitinimas: įjungsime sujungtą daliklį.";
    elseif ~LD5.switchOn then tag="B02";lines="DABAR spauskite geltoną Jungiklis: uždarysime srovės kelią.";
    elseif LD5.position<>k then
        tag="B"+string(9+k);lines=msprintf("DABAR spauskite geltoną P%d = %g %%. Nustatysime šią potenciometro padėtį; po to matuosime jos išėjimo įtampą.",k,LD5.cfg("P"+string(k)));
    else tag="B03";lines=msprintf("DABAR spauskite geltoną Matuoti: užfiksuosime P%d padėties įtampą ir srovę. Rodmenys automatiškai lieka žurnale.",k);end
endfunction

function ld5_guide_close()
    global LD5;
    if typeof(LD5)=="st" then LD5.guide_enabled=%f; end
    if exists("student_guide_hide")==1 then student_guide_hide("LD5"); end
    ld5_guide_refresh();
endfunction

function ld5_guide_refresh()
    global LD5;
    if typeof(LD5)<>"st" then return; end
    if ~isfield(LD5,"step") | ~isfield(LD5,"ui") then return; end
    if isfield(LD5.ui,"headless") then if LD5.ui.headless then return; end; end
    if ~isfield(LD5,"fig") then return; end
    if LD5.step<1 | LD5.step>6 then return; end
    enabled=%f; if isfield(LD5,"guide_enabled") then enabled=LD5.guide_enabled; end
    lines=emptystr(0,1); tag=""; value="";
    if enabled then [lines,tag,value]=ld5_guide_next(); end
    if isfield(LD5.ui,"instructionLine") then
        if enabled then LD5.ui.instructionLine(1).string=student_wrap(lines(1),38);
        else LD5.ui.instructionLine(1).string=student_wrap(ld5_step_instruction(LD5.step),38); end
    end
    if exists("student_guide_update")==1 then student_guide_update("LD5",string(LD5.step)+" / 6 · kitas veiksmas",lines,enabled); end
    if exists("student_guide_focus")==1 then student_guide_focus("LD5",LD5.fig,tag,enabled); end
    if exists("student_guide_action_refresh")==1 then student_guide_action_refresh("LD5",LD5.fig,tag,value,enabled); end
endfunction

function text=ld5_guide_terminal(id)
    text="["+ld5_terminal_code(id)+"] "+ld5_terminal_name(id);
endfunction

function lines=ld5_guide_wires(canon)
    global LD5;
    lines=emptystr(0,1); removal=emptystr(0,1); missing=emptystr(0,2);
    for j=1:size(LD5.wires,1)
        matches=0;
        for k=1:size(canon,1)
            if and(LD5.wires(j,:)==canon(k,:)) | and(LD5.wires(j,:)==canon(k,[2 1])) then matches=matches+1; end
        end
        duplicate=%f;
        for previous=1:j-1
            if and(LD5.wires(j,:)==LD5.wires(previous,:)) | and(LD5.wires(j,:)==LD5.wires(previous,[2 1])) then duplicate=%t; end
        end
        if matches==0 | duplicate then
            removal($+1)="Pašalinkite nereikalingą laidą: pele spauskite "+ld5_guide_terminal(LD5.wires(j,1))+", tada "+ld5_guide_terminal(LD5.wires(j,2))+". Šis esamas laidas išnyks.";
        end
    end
    for k=1:size(canon,1)
        found=%f;
        for j=1:size(LD5.wires,1)
            if and(LD5.wires(j,:)==canon(k,:)) | and(LD5.wires(j,:)==canon(k,[2 1])) then found=%t; end
        end
        if ~found then missing($+1,:)=canon(k,:); end
    end
    // Resolve the pending click BEFORE describing another pair. Otherwise the
    // next suggested first endpoint would itself complete an unintended wire.
    active=0;
    if LD5.pending<>"" then
        if ~LD5.powerOn & size(removal,"*")==0 then
            for k=1:size(missing,1)
                if or(missing(k,:)==LD5.pending) then active=k;break;end
            end
        end
        if active>0 then
            pair=missing(active,:); other=pair(1);if other==LD5.pending then other=pair(2);end
            lines($+1)="Jau pasirinktas "+ld5_guide_terminal(LD5.pending)+". Dabar pele spauskite "+ld5_guide_terminal(other)+". Šis vienas paspaudimas užbaigs pasirinktą laidą.";
        else
            lines($+1)="Pirmiausia atšaukite pasirinktą "+ld5_guide_terminal(LD5.pending)+": pele spauskite tą patį kontaktą dar kartą. Tik atšaukę rinkitės kitą porą.";
        end
        lines=[lines;"";"LIKUSI LAIDŲ SEKA – tik užbaigę arba atšaukę aukščiau nurodytą pasirinkimą:"];
    end
    if LD5.powerOn then lines($+1)="Pele spauskite Maitinimas ir išjunkite šaltinį; tada keiskite laidus."; end
    lines=[lines;removal];
    for k=1:size(missing,1)
        if k==active then continue;end
        lines($+1)="Pele spauskite "+ld5_guide_terminal(missing(k,1))+", tada "+ld5_guide_terminal(missing(k,2))+". Tarp jų atsiras laidas.";
    end
    if size(missing,1)==0 then lines($+1)="Visos reikiamos kontaktų poros sujungtos. Patikrinkite, ar nėra papildomų laidų."; end
endfunction

function lines=ld5_guide_power()
    global LD5;
    lines=emptystr(0,1);
    if ~LD5.powerOn then lines($+1)="Pele spauskite Maitinimas (dešinėje nuo grandinės)."; end
    if ~LD5.switchOn then lines($+1)="Pele spauskite Jungiklis (po mygtuku Maitinimas), kad uždarytumėte grandinę."; end
endfunction

function lines=ld5_guide_lines()
    global LD5;
    lines=emptystr(0,1);
    if typeof(LD5)<>"st" then return; end
    if ~isfield(LD5,"step") | ~isfield(LD5,"cfg") then return; end
    if LD5.step<1 | LD5.step>6 then return; end
    c=LD5.cfg;
    lines=["Vedimas įjungtas jūsų pasirinkimu. Langas atsinaujina po veiksmų; uždarymas vedimą išjungia."; ...
        msprintf("Jūsų reikšmės: E = %g V; faktinė R1 = %g Ω; faktinė RV = %g Ω.",c.E,c.R1,c.RV); ...
        msprintf("Padėtys: P1 = %g %%, P2 = %g %%, P3 = %g %%. Skaičiavimams naudokite šias faktines varžas.",c.P1,c.P2,c.P3)];
    if LD5.demoMode then lines($+1)="Dabar matote pavyzdį. Per Pagalba → Daugiau veiksmų → Parodyti pavyzdį / mano darbą grįžkite į savo darbą."; return; end
    if LD5.step==6 & and(LD5.done) then
        lines=[lines;"Jūsų išvados jau užfiksuotos. Pele spauskite ĮRAŠYTI ATASKAITĄ dešinės skilties apačioje.";ld5_guide_export()];
        return;
    end
    select LD5.step
    case 1 then
        lines=[lines;"Daliklio grandinėje reikalingi 7 laidai. Dabartinis pasirinkimas ir likusių laidų seka pateikti žemiau.";ld5_guide_wires(ld5_canonical_wires()); ...
            "Voltmetras jungiamas lygiagrečiai aktyviai RV daliai. Kai sujungėte laidus, pele spauskite TOLIAU → dešinės skilties apačioje."];
    case 2 then
        lines=[lines;msprintf("P2 aktyvi varža RVd2 = %g × %g / 100, Ω. Tai tik panaudota potenciometro dalis.",c.RV,c.P2); ...
            msprintf("Apskaičiuokite U2 = %g × RVd2 / (%g + RVd2), V.",c.E,c.R1); ...
            "Pele spauskite U2 teorinė, V [A02.01], įveskite savo apskaičiuotą skaičių be vieneto. Formulės į lauką nerašykite."; ...
            ld5_guide_power();ld5_guide_measurements([2]); ...
            "Kai savo teorinę U2 įrašėte ir P2 rodmenys įrašyti, pele spauskite TOLIAU →."];
    case 3 then
        lines=[lines;ld5_guide_power();ld5_guide_measurements([1 3]); ...
            "Šiame etape atsakymo laukų nėra. Kai sąraše turite visų trijų padėčių matavimus, pele spauskite TOLIAU →."];
    case 4 then
        lines=[lines;ld5_guide_journal(); ...
            "Atskirai P1 ir P3 apskaičiuokite RVd = RV × padėtis(%) / 100, Ω."; ...
            "Tada kiekvienai padėčiai apskaičiuokite U = E × RVd / (R1 + RVd), V, naudodami viršuje nurodytas faktines varžas."; ...
            "Pele spauskite U1 teorinė, V [A04.01], įveskite savo U1. Į U3 teorinė, V [A04.02] įveskite savo U3."; ...
            "Apskaičiuokite ΔU = U3 − U1, V. Pele spauskite Reguliavimo diapazonas ΔU, V [A04.03] ir įveskite savo rezultatą."; ...
            msprintf("Apskaičiuokite 100 × ΔU / %g. Savo procentus įveskite į Diapazonas nuo E, %% [A04.04].",c.E); ...
            "Laukuose rašykite tik skaičius; tada pele spauskite TOLIAU →."];
    case 5 then
        lines=[lines;ld5_guide_journal(); ...
            msprintf("Padėčiai P2 = %g %% apskaičiuokite RVd2 = %g × %g / 100, Ω.",c.P2,c.RV,c.P2); ...
            msprintf("Apskaičiuokite I2 = 1000 × %g / (%g + RVd2), mA. 1000 paverčia A į mA.",c.E,c.R1); ...
            "Pele spauskite Srovė I2, mA [A05.01] ir įveskite savo apskaičiuotą srovę."; ...
            msprintf("Apskaičiuokite santykį 100 × RVd2 / (%g + RVd2). Tai aktyvios RV dalies santykis su visa grandinės varža, o ne pati P2 padėtis.",c.R1); ...
            "Pele spauskite Aktyvios RV dalies santykis, % [A05.02], įveskite savo procentus be % ženklo; spauskite TOLIAU →."];
    case 6 then
        lines=[lines;ld5_guide_journal(); ...
            "Palyginkite P1, P2 ir P3 išėjimo įtampas. Ar galima keisti išėjimo įtampą keičiant aktyvią RV dalį?"; ...
            "Pele spauskite Ar įtampa reguliuojama sklandžiai? 1 Taip / 2 Ne [A06.01] ir įveskite savo pasirinkimo kodą 1 arba 2."; ...
            "Palyginkite savo teorines U1, U2, U3 su atitinkamų padėčių matavimais."; ...
            "Pele spauskite Ar dalikio dėsnis galioja? 1 Taip / 2 Ne [A06.02] ir įveskite savo pasirinkimo kodą 1 arba 2."; ...
            "Spauskite TOLIAU → išvadoms užfiksuoti, tada ĮRAŠYTI ATASKAITĄ. Originalų sukurtą HTML pateikite dėstytojui."; ...
            ld5_guide_export()];
    end
    if ~LD5.assessment & ~LD5.done(LD5.step) then
        lines=strsubst(lines,"TOLIAU →","TIKRINTI");
        lines($+1)="Mokymosi režime mygtukas TIKRINTI patikrina jūsų įvestį. Jei gausite klaidos paaiškinimą, pataisykite atsakymą ir tikrinkite dar kartą.";
    end
    if LD5.done(LD5.step) then lines($+1)="Dabartinis etapas jau užfiksuotas. Galite pereiti toliau."; end
endfunction

function lines=ld5_guide_measurements(indices)
    global LD5;
    lines=emptystr(0,1);
    for k=matrix(indices,1,-1)
        rows=ld5_journal_rows(k); p=LD5.cfg("P"+string(k));
        if size(rows,1)>0 then
            lines($+1)=msprintf("P%d (%g %%) jau išmatuota: U = %.10g V; I = %.10g mA. Šios padėties nekartokite.",k,p,rows(1,1),rows(1,2));
        else
            lines($+1)=msprintf("Pele spauskite P%d = %g %% grandinės apačioje, tada Matuoti. Įtampa ir srovė automatiškai įsirašys į matavimų sąrašą.",k,p);
        end
    end
endfunction

function lines=ld5_guide_journal()
    global LD5;
    lines="Jūsų jau užfiksuoti rodmenys:";
    for k=1:3
        rows=ld5_journal_rows(k);
        if size(rows,1)>0 then
            lines($+1)=msprintf("P%d (%g %%): U = %.10g V; I = %.10g mA.",k,LD5.cfg("P"+string(k)),rows(1,1),rows(1,2));
        else
            lines($+1)=msprintf("P%d matavimo dar nėra. Mygtuku ← Atgal grįžkite į 2 arba 3 etapą ir išmatuokite šią padėtį.",k);
        end
    end
endfunction

function lines=ld5_guide_export()
    global LD5;
    title="Ataskaita išsaugota";
    if ~LD5.assessment | LD5.practice_used then title="Mokymosi ataskaita išsaugota";end
    lines=["Programa pati įrašo HTML failą ir atveria patvirtinimą „"+title+"“."; ...
        "Patvirtinimo lange pele spauskite Atverti ataskaitą: atverkite HTML ir peržiūrėkite jo turinį."; ...
        "Grįžkite į patvirtinimo langą ir spauskite Atverti ataskaitų aplanką. Raskite tame lange nurodytą HTML failą; pateikite dėstytojui šį originalų failą."; ...
        "Norėdami grįžti į laboratorinį stendą, patvirtinimo lange spauskite Grįžti į darbą. Failas jau išsaugotas."];
    if ~LD5.assessment | LD5.practice_used then lines($+1)="Tai mokymosi ataskaita; į atsiskaitymo pažymių suvestinę ji neįtraukiama.";end
endfunction

// Pure next-wire selection: remove an incorrect wire before adding another.
function [lines,tag]=ld5_guide_wire_next(canon)
    global LD5;
    lines=emptystr(0,1); tag=""; bad=emptystr(0,2); missing=emptystr(0,2);
    for j=1:size(LD5.wires,1)
        pair=LD5.wires(j,:); good=%f; duplicate=%f;
        for k=1:size(canon,1)
            if and(pair==canon(k,:)) | and(pair==canon(k,[2 1])) then good=%t; end
        end
        for k=1:j-1
            if and(pair==LD5.wires(k,:)) | and(pair==LD5.wires(k,[2 1])) then duplicate=%t; end
        end
        if ~good | duplicate then bad($+1,:)=pair; end
    end
    for k=1:size(canon,1)
        found=%f;
        for j=1:size(LD5.wires,1)
            if and(canon(k,:)==LD5.wires(j,:)) | and(canon(k,:)==LD5.wires(j,[2 1])) then found=%t; end
        end
        if ~found then missing($+1,:)=canon(k,:); end
    end
    if size(bad,1)==0 & size(missing,1)==0 & LD5.pending=="" then return; end
    if LD5.powerOn then
        tag="B01"; lines="DABAR spauskite geltoną Maitinimas: prieš keičiant laidus šaltinį reikia išjungti."; return;
    end
    pair=emptystr(0,2); remove=%f;
    if size(bad,1)>0 then pair=bad(1,:); remove=%t;
    elseif LD5.pending<>"" then
        for k=1:size(missing,1)
            if or(missing(k,:)==LD5.pending) then pair=missing(k,:); break; end
        end
    elseif size(missing,1)>0 then pair=missing(1,:);
    end
    if LD5.pending<>"" then
        target=LD5.pending; cancel=%t;
        if size(pair,"*")==2 then
            if pair(1)==LD5.pending then target=pair(2); cancel=%f;
            elseif pair(2)==LD5.pending then target=pair(1); cancel=%f; end
        end
        tag=ld5_terminal_code(target);
        if cancel then lines="DABAR dar kartą spauskite geltoną "+ld5_guide_terminal(target)+": atšauksite netyčia pradėtą laidą.";
        elseif remove then lines="DABAR spauskite geltoną "+ld5_guide_terminal(target)+": šis antras paspaudimas pašalins netinkamą laidą.";
        else lines="DABAR spauskite geltoną "+ld5_guide_terminal(target)+": užbaigsite vieną reikiamą laidą."; end
    else
        tag=ld5_terminal_code(pair(1));
        if remove then lines="DABAR spauskite geltoną "+ld5_guide_terminal(pair(1))+". Po jo pažymėsiu kitą netinkamo laido galą; pašalinsime tik tą laidą.";
        else lines="DABAR spauskite geltoną "+ld5_guide_terminal(pair(1))+". Tada geltonai pažymėsiu antrą šio laido galą."; end
    end
endfunction

function [lines,tag,value]=ld5_guide_input(slot,number,formula)
    global LD5;
    lines=emptystr(0,1); tag=""; value="";
    raw=LD5.answers(LD5.step,slot); actual=ld5_parse_number(raw);
    if LD5.step==6 then
        // The conclusion fields accept literal codes 1 or 2, not 1.0/1e0.
        if raw==string(number) then return; end
    elseif ~isnan(actual) then
        if abs(actual-number)<=1e-8+0.005*abs(number) then return; end
    end
    value=msprintf("%.10g",number); tag=ld5_answer_code(LD5.step,slot);
    lines=["DABAR į geltoną lauką ["+tag+"] įrašykite "+value+" (tik skaičių).";formula; ...
        "Mygtukas pagalbos lange įrašo tik šią parodytą reikšmę. Galite ją įvesti ir klaviatūra."];
endfunction
