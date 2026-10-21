// Opt-in visible guidance. Opening it does not perform an experiment or fill answers.
function ld6_guide_show()
    global LD6;
    if typeof(LD6)<>"st" then return; end
    LD6.guide_enabled=%t;
    ld6_guide_refresh();
endfunction

function [lines,tag,value]=ld6_guide_next()
    global LD6;
    c=LD6.cfg;n=LD6.step;tag="LD6_PRIMARY";value="";
    purpose="KAM: tuos pačius du šaltinius jungiame keturiais būdais. Matuojame, ar jie vienas kitą sustiprina, silpnina ir kaip elgiasi lygiagrečiai.";
    lines="DABAR spauskite geltoną pagrindinį mygtuką dešinėje.";
    if LD6.demoMode then lines="DABAR spauskite pagrindinį mygtuką ir grįžkite į savo darbą. Šiuo metu matote pavyzdį.";return;end
    if n<=5 then
        mode=ld6_stage_mode(n);
        if LD6.wireMode<>mode then
            tag="B"+string(9+mode);lines=["DABAR spauskite geltoną „"+ld6_mode_name(mode)+"“. Atversime šio jungimo laidus; maitinimas bus išjungtas.";purpose];return;
        end
        if n==2 then
            [valid,why]=ld6_wiring_valid(LD6.wires);
            if ~valid then tag="LD6_BACK";lines=["DABAR spauskite geltoną ← Atgal: pirmame etape vedlys padės pataisyti E1 laidus.";why];return;end
        else
            [wlines,wtag]=ld6_guide_wire_next(ld6_canonical_wires(mode));
            if wtag<>"" then tag=wtag;lines=[wlines;"Šio etapo jungimas: "+ld6_mode_name(mode)+".";purpose];return;end
        end
    end
    if LD6.done(n) then
        if n==6 & and(LD6.done) then lines="DABAR spauskite geltoną ĮRAŠYTI ATASKAITĄ. Programa sukurs jūsų keturių bandymų HTML failą.";
        elseif n==6 then lines="DABAR spauskite geltoną UŽBAIGTI PRALEISTĄ ETAPĄ. Grįšime į pirmą neužbaigtą darbo dalį.";
        else lines="DABAR spauskite geltoną TOLIAU →. Šio etapo duomenys jau užfiksuoti.";end
        lines=[lines;purpose];return;
    end
    if n==1 then lines=["DABAR spauskite geltoną pagrindinį mygtuką: E1 grandinės 6 laidai sujungti. Maitinimą įjungsime matavimo etape.";purpose];return;end
    if n==2 then
        current=1000*c.E1/(c.R+c.r1);
        [lines,tag,value]=ld6_guide_input(1,current,msprintf("TEORIJA: I = 1000 × E1/(R+r1) = 1000 × %g/(%g+%g) = %.10g mA. Įtraukiame ir šaltinio vidinę varžą r1.",c.E1,c.R,c.r1,current));
        if tag<>"" then lines=[lines;purpose];return;end
    end
    if or(n==[2 3 4 5]) then
        if n==4 & size(ld6_journal_rows(2),1)==0 then tag="LD6_BACK";lines="DABAR spauskite geltoną ← Atgal: prieš palyginant E1+E2 ir E1−E2 reikia užfiksuoti nuoseklaus jungimo matavimą.";return;end
        if size(ld6_journal_rows(mode),1)==0 then
            if ~LD6.powerOn then tag="B01";lines="DABAR spauskite geltoną Maitinimas: įjungsime teisingai sujungtus šaltinius.";
            elseif ~LD6.switchOn then tag="B02";lines="DABAR spauskite geltoną Jungiklis: uždarysime srovės kelią.";
            else tag="B03";lines="DABAR spauskite geltoną Matuoti: į žurnalą įrašysime „"+ld6_mode_name(mode)+"“ įtampą ir sroves. Rodmenų perrašyti nereikia.";end
            lines=[lines;purpose];return;
        end
    end
    if n==4 then
        nums=[c.E1+c.E2 c.E1-c.E2];
        formulas=[msprintf("NUOSEKLIAI TA PAČIA KRYPTIMI šaltinių EV sumuojamos: EΣ = E1+E2 = %g+%g = %.10g V.",c.E1,c.E2,nums(1)); ...
            msprintf("PRIEŠPRIEŠIAIS šaltiniai veikia priešingai: EΔ = E1−E2 = %g−%g = %.10g V. Išlaikykite ženklą; tai nurodo kryptį.",c.E1,c.E2,nums(2))];
    elseif n==5 then
        eq=(c.E1/c.r1+c.E2/c.r2)/(1/c.r1+1/c.r2);req=1/(1/c.r1+1/c.r2);nums=[eq req];
        formulas=[msprintf("LYGIAGREČIAI: Eeq = (E1/r1+E2/r2)/(1/r1+1/r2) = (%g/%g+%g/%g)/(1/%g+1/%g) = %.10g V. Tai EV, ne apkrautos grandinės voltmetro U.",c.E1,c.r1,c.E2,c.r2,c.r1,c.r2,eq); ...
            msprintf("Vidinės varžos sujungtos lygiagrečiai: req = 1/(1/r1+1/r2) = 1/(1/%g+1/%g) = %.10g Ω.",c.r1,c.r2,req)];
    elseif n==6 then
        rows1=ld6_journal_rows(1);rows2=ld6_journal_rows(2);rows3=ld6_journal_rows(3);rows4=ld6_journal_rows(4);
        if size(rows1,1)==0 | size(rows2,1)==0 | size(rows3,1)==0 | size(rows4,1)==0 then tag="LD6_BACK";lines="DABAR spauskite geltoną ← Atgal: išvadoms būtini visų keturių režimų rodmenys. Grįždami vedliu užfiksuokite trūkstamą režimą.";return;end
        measured_sum=rows2(1,1)+rows2(1,2)/1000*(c.r1+c.r2);measured_diff=rows3(1,1)+rows3(1,2)/1000*(c.r1+c.r2);
        first=2;if abs(measured_sum-(c.E1+c.E2))<1e-6 & abs(measured_diff-(c.E1-c.E2))<1e-6 then first=1;end
        second=2;if abs(rows4(1,1)-(c.E1+c.E2))<=1e-6 then second=1;end
        nums=[first second];
        formulas=[msprintf("IŠ JŪSŲ MATAVIMŲ: pridėjus vidinį įtampos kritimą gauname nuosekliai %.10g V ≈ E1+E2 = %g V; priešpriešiais %.10g V ≈ E1−E2 = %g V. EV sudedamos su krypties ženklais. 1 – Taip, 2 – Ne.",measured_sum,c.E1+c.E2,measured_diff,c.E1-c.E2); ...
            msprintf("IŠ JŪSŲ LYGIAGRETAUS BANDYMO: apkrovos U = %.10g V; E1+E2 = %g V. Šios reikšmės nelygios: lygiagrečiai įtampos nesusideda. 1 – Taip, 2 – Ne.",rows4(1,1),c.E1+c.E2)];
    else nums=[];formulas=emptystr(0,1);end
    for k=1:size(nums,"*")
        [lines,tag,value]=ld6_guide_input(k,nums(k),formulas(k));
        if tag<>"" then lines=[lines;purpose];return;end
    end
    tag="LD6_PRIMARY";value="";lines=["DABAR spauskite geltoną pagrindinį mygtuką dešinėje. Reikalingi bandymai ir laukai paruošti; užfiksuosime etapą.";purpose];
endfunction

function ld6_guide_close()
    global LD6;
    if typeof(LD6)=="st" then LD6.guide_enabled=%f; end
    if exists("student_guide_hide")==1 then student_guide_hide("LD6"); end
    ld6_guide_refresh();
endfunction

function text=ld6_guide_terminal(id)
    text="["+ld6_terminal_code(id)+"] "+ld6_terminal_name(id);
endfunction

function yes=ld6_guide_has_wire(a,b)
    global LD6;
    yes=%f;
    for k=1:size(LD6.wires,1)
        if and(LD6.wires(k,:)==[a b]) | and(LD6.wires(k,:)==[b a]) then yes=%t; return; end
    end
endfunction

function lines=ld6_guide_wiring(mode)
    global LD6;
    lines=emptystr(0,1);
    if LD6.wireMode<>mode then
        lines($+1)="Pirmiausia stendo apačioje paspauskite režimą „"+ld6_mode_name(mode)+"“. Jo laidai saugomi atskirai.";
        lines($+1)="Pasirinkus režimą maitinimas išjungiamas. Šis langas atsinaujins pagal pasirinkto režimo laidus.";
        return;
    end
    canonical=ld6_canonical_wires(mode);
    if LD6.powerOn then lines($+1)="Prieš keisdami bent vieną laidą paspauskite „Maitinimas“, kad maitinimas būtų išjungtas."; end
    if LD6.pending<>"" then
        target="";
        for k=1:size(canonical,1)
            a=canonical(k,1); b=canonical(k,2);
            if ~ld6_guide_has_wire(a,b) then
                if a==LD6.pending then target=b; break; end
                if b==LD6.pending then target=a; break; end
            end
        end
        if target<>"" then
            lines($+1)="DABAR pasirinktas "+ld6_guide_terminal(LD6.pending)+". Antru paspaudimu pasirinkite "+ld6_guide_terminal(target)+".";
        else
            lines($+1)="DABAR pasirinktas "+ld6_guide_terminal(LD6.pending)+". Norėdami pradėti toliau išvardytą porą spauskite šį gnybtą dar kartą ir atšaukite pasirinkimą.";
        end
        lines($+1)="Pirmiausia užbaikite arba atšaukite šį pažymėtą gnybtą. Tik po to tęskite kitus laidus; šis langas atsinaujins po paspaudimo.";
        return;
    end
    lines($+1)="Laidui: pele spauskite pirmą nurodytą gnybtą, tada antrą. Tas pats veiksmas su jau esančiu laidu jį pašalina.";
    lines($+1)="Jei pirmą gnybtą pasirinkote netyčia, dar kartą spauskite tą patį gnybtą: pasirinkimas atšaukiamas, laidas nesukuriamas.";
    for k=1:size(LD6.wires,1)
        pair=LD6.wires(k,:); valid=%f;
        for j=1:size(canonical,1)
            if and(pair==canonical(j,:)) | and(pair==canonical(j,[2 1])) then valid=%t; break; end
        end
        if ~valid then lines($+1)="PAŠALINKITE netinkamą laidą: spauskite "+ld6_guide_terminal(pair(1))+", tada "+ld6_guide_terminal(pair(2))+"."; end
    end
    for k=1:size(canonical,1)
        a=canonical(k,1); b=canonical(k,2); mark="TRŪKSTA: ";
        if ld6_guide_has_wire(a,b) then mark="Sujungta: "; end
        lines($+1)=msprintf("%d. ",k)+mark+ld6_guide_terminal(a)+" → "+ld6_guide_terminal(b)+".";
    end
    lines($+1)="Voltmetro zondai jungiami prie R lygiagrečiai: [T11] prie [T09], [T12] prie [T10]. Jų neįterpkite nuosekliai į srovės kelią.";
endfunction

function lines=ld6_guide_lines()
    global LD6;
    lines=emptystr(0,1);
    if typeof(LD6)<>"st" then return; end
    if ~isfield(LD6,"step") | ~isfield(LD6,"cfg") then return; end
    c=LD6.cfg; n=LD6.step;
    lines=["Pagalba tik paaiškina veiksmus. Juos stende atliekate patys; atsakymai ir režimas nekeičiami."; ...
        msprintf("Jūsų dydžiai: E1=%g V; E2=%g V; R=%g Ω; r1=%g Ω; r2=%g Ω.",c.E1,c.E2,c.R,c.r1,c.r2)];
    if LD6.demoMode then
        lines($+1)="Dabar rodomas mokymosi PAVYZDYS. Paspauskite „GRĮŽTI Į SAVO DARBĄ“, jei norite tęsti savo bandymą. Pagalbos atvėrimas pats pavyzdžio neįjungia.";
        return;
    end
    if n<=5 then
        mode=ld6_stage_mode(n);
        lines($+1)="Šio etapo režimas: „"+ld6_mode_name(mode)+"“.";
        if n<>2 then lines=[lines;ld6_guide_wiring(mode)]; end
        if n==2 then
            if LD6.wireMode<>1 then lines($+1)="Pirmiausia stendo apačioje spauskite „E1“. Matavimas šiame etape priimamas tik E1 režime."; end
            lines($+1)="E1 grandinė išliko po 1 etapo. 2 etape laidai nekeičiami. Jei reikia juos pataisyti, „← Atgal“ grįžkite į 1 etapą, išjunkite maitinimą ir sutvarkykite jungimą.";
        end
        if n>=2 then
            rows=ld6_journal_rows(mode);
            if rows==[] then
                if LD6.wireMode==mode then
                    [wiring_ok,unused_reason]=ld6_wiring_valid(LD6.wires);
                    if ~wiring_ok then
                        lines($+1)="DABAR užbaikite arba pataisykite aukščiau išvardytas gnybtų poras; tik tada įjunkite maitinimą ir matuokite.";
                    elseif ~LD6.powerOn then lines($+1)="DABAR, kai laidai sujungti: spauskite „Maitinimas“. Būsena turi tapti „Maitinimas įjungtas“.";
                    elseif ~LD6.switchOn then lines($+1)="DABAR spauskite „Jungiklis“, kad jis taptų uždarytas.";
                    else lines($+1)="DABAR spauskite „Matuoti“. Sėkmės pranešime ir žurnale turi atsirasti šio režimo U ir I."; end
                end
                lines($+1)="Matavimo seka: „Maitinimas“ → „Jungiklis“ → „Matuoti“. Įjungtų valdiklių antrą kartą nespauskite, nes jie persijungia į priešingą būseną.";
            else
                lines($+1)=msprintf("Šio režimo žurnale jau užfiksuota: U=%.4f V, I=%.3f mA; E1 srovė=%.3f mA, E2 srovė=%.3f mA.",rows(1,1),rows(1,2),rows(1,3),rows(1,4));
                lines($+1)="Šių rodmenų į atsakymų laukus perrašyti nereikia: jie automatiškai liko matavimų žurnale ir HTML ataskaitoje.";
            end
        end
    end
    if LD6.done(n) then
        advance="Etapas jau įrašytas: spauskite matomą „TOLIAU →“.";
    elseif LD6.assessment then
        advance="Užbaigę veiksmus spauskite matomą „TOLIAU →“; jei duomenų pakanka, atsidarys kitas etapas.";
    else
        advance="Mokymosi režime dabar matomas „TIKRINTI“. Spauskite „TIKRINTI“: sėkmingai patikrinus programa iškart atvers kitą etapą. Jei rodo klaidą, pataisykite ir spauskite „TIKRINTI“ dar kartą.";
    end
    select n
    case 1 then
        lines($+1)="Kai visos šešios poros sujungtos, maitinimą palikite išjungtą. "+advance+"";
    case 2 then
        lines($+1)=msprintf("Skaičiuotuvu apskaičiuokite I=1000·E1/(R+r1)=1000·%g/(%g+%g), mA. 1000 paverčia A į mA.",c.E1,c.R,c.r1);
        lines($+1)="Pele spauskite lauką [A02.01] „Tik E1: teorinė apkrovos I, mA“. Įveskite savo apskaičiuotą skaičių mA; vieneto ir formulės į lauką nerašykite.";
        lines($+1)="Atlikite E1 matavimą, jei jo dar nėra žurnale. "+advance+"";
    case 3 then
        lines($+1)="Šiame etape skaitinių atsakymų laukų nėra. Užfiksuokite nuoseklaus jungimo U ir I. "+advance+"";
    case 4 then
        lines($+1)=msprintf("[A04.01] „Nuosekliai: bendra EV EΣ, V“: apskaičiuokite EΣ=E1+E2=%g+%g, V ir įveskite gautą skaičių.",c.E1,c.E2);
        lines($+1)=msprintf("[A04.02] „Priešpriešiais: bendra EV EΔ, V“: apskaičiuokite EΔ=E1−E2=%g−%g, V ir įveskite skaičių su jo ženklu. Neigiamo rezultato nekeiskite teigiamu.",c.E1,c.E2);
        if ld6_journal_rows(2)==[] then lines($+1)="Dar trūksta ankstesnio nuoseklaus jungimo matavimo. Per „← Atgal“ grįžkite į 3 etapą ir užfiksuokite jį mygtuku „Matuoti“."; end
        lines($+1)="Patikrinkite, ar abu EV laukai užpildyti ir yra abiejų režimų matavimai. "+advance+"";
    case 5 then
        lines($+1)=msprintf("[A05.01] „Lygiagrečiai: ekvivalentinė EV Eeq, V“: Eeq=(E1/r1+E2/r2)/(1/r1+1/r2)=(%g/%g+%g/%g)/(1/%g+1/%g). Apskaičiuokite ir įveskite skaičių V.",c.E1,c.r1,c.E2,c.r2,c.r1,c.r2);
        lines($+1)=msprintf("[A05.02] „Lygiagrečiai: ekvivalentinė vidinė req, Ω“: req=1/(1/r1+1/r2)=1/(1/%g+1/%g). Apskaičiuokite ir įveskite skaičių Ω.",c.r1,c.r2);
        lines($+1)="Eeq yra ekvivalentinė šaltinio EV; jos nesupainiokite su apkrautos grandinės voltmetro U rodmeniu. Laukuose rašykite tik skaičius; tinka kablelis arba taškas.";
        lines($+1)="Užfiksuokite lygiagretaus režimo matavimą ir užpildykite abu laukus. "+advance+"";
    case 6 then
        lines($+1)="Stendo žurnale palyginkite E1, nuoseklaus, priešpriešinio ir lygiagretaus režimų rodmenis. Šiame etape naujo matavimo nereikia.";
        for mode=1:4
            rows=ld6_journal_rows(mode);
            if rows<>[] then lines($+1)=msprintf("%s: žurnalo U=%.4f V, I=%.3f mA.",ld6_mode_name(mode),rows(1,1),rows(1,2)); end
        end
        lines($+1)="Pele pasirinkite [A06.01] „Ar nuosekliai EV sudedamos su ženklais? 1 Taip / 2 Ne“. Palyginkite EΣ=E1+E2 ir EΔ=E1−E2; įveskite savo pasirinkimą 1 arba 2.";
        lines($+1)=msprintf("Pele pasirinkite [A06.02] „Ar lygiagrečiai U = E1 + E2? 1 Taip / 2 Ne“. Žurnalo lygiagretų U palyginkite su %g+%g V; įveskite savo pasirinkimą 1 arba 2.",c.E1,c.E2);
        if and(LD6.done) then
            lines($+1)="Visi etapai įrašyti. Spauskite „ĮRAŠYTI ATASKAITĄ“. Programa automatiškai sukuria HTML failą; failo vardo ranka įvesti nereikia.";
        elseif LD6.done(6) then
            lines($+1)="Išvados jau įrašytos, bet yra neužbaigtų ankstesnių etapų. Spauskite „UŽBAIGTI PRALEISTĄ ETAPĄ“: programa atvers pirmą neužbaigtą etapą. Jį užbaikite ir grįžkite iki ataskaitos.";
        elseif LD6.assessment then
            lines($+1)="Įvedę abi išvadas spauskite matomą „TOLIAU →“. Kai visi etapai įrašyti, mygtukas tampa „ĮRAŠYTI ATASKAITĄ“; paspauskite jį ataskaitai išsaugoti.";
        else
            lines($+1)="Mokymosi režime įvedę abi išvadas spauskite matomą „TIKRINTI“. Kai išvados patikrintos ir visi etapai įrašyti, mygtukas tampa „ĮRAŠYTI ATASKAITĄ“; paspauskite jį ataskaitai išsaugoti.";
        end
        lines($+1)="Išsaugojimo patvirtinime patikrinkite parodytą HTML kelią. „Atverti ataskaitą“ parodo turinį, „Atverti ataskaitų aplanką“ atveria failo vietą, „Grįžti į darbą“ uždaro patvirtinimą. Originalų .html failą pateikite dėstytojui pagal jo nurodymus; juodraštis ar ekrano nuotrauka jo nepakeičia.";
    end
    if n<6 & LD6.done(n) then lines($+1)="Šio etapo duomenys jau įrašyti. Spauskite „TOLIAU →“; iš naujo matuoti nereikia, jei laidų nekeičiate."; end
    lines($+1)="Vedimą galite išjungti šio pagalbos lango uždarymo mygtuku. Vėl įjunkite per „Pagalba“ → „Vesti žingsnis po žingsnio“.";
endfunction

function ld6_guide_refresh()
    global LD6;
    if typeof(LD6)<>"st" then return; end
    if ~isfield(LD6,"step") | ~isfield(LD6,"ui") then return; end
    if isfield(LD6.ui,"headless") then if LD6.ui.headless then return; end; end
    if ~isfield(LD6,"fig") then return; end
    if LD6.step<1 | LD6.step>6 then return; end
    enabled=%f; if isfield(LD6,"guide_enabled") then enabled=LD6.guide_enabled; end
    lines=emptystr(0,1); tag=""; value="";
    if enabled then [lines,tag,value]=ld6_guide_next(); end
    if isfield(LD6.ui,"instructionLine") then
        if enabled then LD6.ui.instructionLine(1).string=student_wrap(lines(1),38);
        else LD6.ui.instructionLine(1).string=student_wrap(ld6_step_instruction(LD6.step),38); end
    end
    if exists("student_guide_update")==1 then student_guide_update("LD6",string(LD6.step)+" / 6 · kitas veiksmas",lines,enabled); end
    if exists("student_guide_focus")==1 then student_guide_focus("LD6",LD6.fig,tag,enabled); end
    if exists("student_guide_action_refresh")==1 then student_guide_action_refresh("LD6",LD6.fig,tag,value,enabled); end
endfunction

// Pure next-wire selection: remove an incorrect wire before adding another.
function [lines,tag]=ld6_guide_wire_next(canon)
    global LD6;
    lines=emptystr(0,1); tag=""; bad=emptystr(0,2); missing=emptystr(0,2);
    for j=1:size(LD6.wires,1)
        pair=LD6.wires(j,:); good=%f; duplicate=%f;
        for k=1:size(canon,1)
            if and(pair==canon(k,:)) | and(pair==canon(k,[2 1])) then good=%t; end
        end
        for k=1:j-1
            if and(pair==LD6.wires(k,:)) | and(pair==LD6.wires(k,[2 1])) then duplicate=%t; end
        end
        if ~good | duplicate then bad($+1,:)=pair; end
    end
    for k=1:size(canon,1)
        found=%f;
        for j=1:size(LD6.wires,1)
            if and(canon(k,:)==LD6.wires(j,:)) | and(canon(k,:)==LD6.wires(j,[2 1])) then found=%t; end
        end
        if ~found then missing($+1,:)=canon(k,:); end
    end
    if size(bad,1)==0 & size(missing,1)==0 & LD6.pending=="" then return; end
    if LD6.powerOn then
        tag="B01"; lines="DABAR spauskite geltoną Maitinimas: prieš keičiant laidus šaltinį reikia išjungti."; return;
    end
    pair=emptystr(0,2); remove=%f;
    if size(bad,1)>0 then pair=bad(1,:); remove=%t;
    elseif LD6.pending<>"" then
        for k=1:size(missing,1)
            if or(missing(k,:)==LD6.pending) then pair=missing(k,:); break; end
        end
    elseif size(missing,1)>0 then pair=missing(1,:);
    end
    if LD6.pending<>"" then
        target=LD6.pending; cancel=%t;
        if size(pair,"*")==2 then
            if pair(1)==LD6.pending then target=pair(2); cancel=%f;
            elseif pair(2)==LD6.pending then target=pair(1); cancel=%f; end
        end
        tag=ld6_terminal_code(target);
        if cancel then lines="DABAR dar kartą spauskite geltoną "+ld6_guide_terminal(target)+": atšauksite netyčia pradėtą laidą.";
        elseif remove then lines="DABAR spauskite geltoną "+ld6_guide_terminal(target)+": šis antras paspaudimas pašalins netinkamą laidą.";
        else lines="DABAR spauskite geltoną "+ld6_guide_terminal(target)+": užbaigsite vieną reikiamą laidą."; end
    else
        tag=ld6_terminal_code(pair(1));
        if remove then lines="DABAR spauskite geltoną "+ld6_guide_terminal(pair(1))+". Po jo pažymėsiu kitą netinkamo laido galą; pašalinsime tik tą laidą.";
        else lines="DABAR spauskite geltoną "+ld6_guide_terminal(pair(1))+". Tada geltonai pažymėsiu antrą šio laido galą."; end
    end
endfunction

function [lines,tag,value]=ld6_guide_input(slot,number,formula)
    global LD6;
    lines=emptystr(0,1); tag=""; value="";
    raw=LD6.answers(LD6.step,slot); actual=ld6_parse_number(raw);
    if LD6.step==6 then
        // The conclusion fields accept literal codes 1 or 2, not 1.0/1e0.
        if raw==string(number) then return; end
    elseif ~isnan(actual) then
        if abs(actual-number)<=1e-8+0.005*abs(number) then return; end
    end
    value=msprintf("%.10g",number); tag=ld6_answer_code(LD6.step,slot);
    lines=["DABAR į geltoną lauką ["+tag+"] įrašykite "+value+" (tik skaičių).";formula; ...
        "Mygtukas pagalbos lange įrašo tik šią parodytą reikšmę. Galite ją įvesti ir klaviatūra."];
endfunction
