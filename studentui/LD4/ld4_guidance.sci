// Opt-in visible guidance. Opening it does not perform an experiment or fill answers.
function ld4_guide_show()
    global LD4;
    if typeof(LD4)<>"st" then return; end
    LD4.guide_enabled=%t;
    ld4_guide_refresh();
endfunction

function [lines,tag,value]=ld4_guide_next()
    global LD4;
    c=LD4.cfg; n=LD4.step; tag="LD4_PRIMARY"; value="";
    purpose="KAM: tam pačiam rezistoriui keičiame įtampą, matuojame srovę ir tikriname, ar U/I lieka pastovus. Tada palyginame du rezistorius ir jų nuoseklų jungimą.";
    lines="DABAR spauskite geltoną pagrindinį mygtuką dešinėje.";
    if LD4.demoMode then lines="DABAR spauskite pagrindinį mygtuką ir grįžkite į savo darbą. Šiuo metu matote pavyzdį."; return; end
    if or(n==[1 6]) then
        mode=1; if n==6 then mode="S"; end
        [wlines,wtag]=ld4_guide_wire_next(ld4_canonical_wires(mode));
        if wtag<>"" then lines=[wlines;purpose;"Jungiant maitinimas lieka išjungtas. Teisingų laidų perjungti nereikia: vedlys parodo tik trūkstamą arba šalintiną laidą."]; tag=wtag; return; end
    end
    if LD4.done(n) then
        if n==7 then lines="DABAR spauskite geltoną ĮRAŠYTI ATASKAITĄ. Programa sukurs jūsų matavimų HTML failą.";
        else lines="DABAR spauskite geltoną TOLIAU →. Šio etapo duomenys jau užfiksuoti."; end
        lines=[lines;purpose]; return;
    end
    if n==1 then lines=["DABAR spauskite geltoną pagrindinį mygtuką: 6 laidai sujungti, pereisime prie R1 matavimų.";purpose]; return; end
    if n==2 then
        [wok,why]=ld4_wiring_valid(LD4.wires);
        if ~wok then tag="LD4_BACK"; lines=["DABAR spauskite geltoną ← Atgal. Pirmajame etape vedlys padės pataisyti R1 laidus.";why]; return; end
        [lines,tag,value]=ld4_guide_input(1,1000*c.U1/c.R1nom,msprintf("TEORIJA: I = 1000 × U/Rnom = 1000 × %g/%g = %.10g mA. Tai prognozė pagal ant rezistoriaus užrašytą nominalą.",c.U1,c.R1nom,1000*c.U1/c.R1nom));
        if tag<>"" then lines=[lines;purpose]; return; end
        [lines,tag]=ld4_guide_measure_next(1,[1 2 3]);
        if tag<>"" then lines=[lines;purpose]; return; end
    elseif n==3 then
        if size(ld4_journal_rows(1),1)<3 then tag="LD4_BACK"; lines="DABAR spauskite geltoną ← Atgal: pirma užfiksuosime visus tris R1 matavimus."; return; end
        if LD4.wireMode<>2 then tag="B13"; lines=["DABAR spauskite geltoną Į R2: programa perjungs laidus į antrą rezistorių ir saugiai išjungs maitinimą.";"KAM: tomis pačiomis trimis įtampomis ištirsime kitą rezistorių ir palyginsime jo varžą su užrašytu nominalu."]; return; end
        [lines,tag]=ld4_guide_measure_next(2,[1 2 3]);
        if tag<>"" then lines=[lines;purpose]; return; end
    elseif or(n==[4 5]) then
        a=ld4_journal_rows(1); b=ld4_journal_rows(2);
        if size(a,1)<3 | size(b,1)<3 then tag="LD4_BACK"; lines="DABAR spauskite geltoną ← Atgal: trūksta ankstesnio rezistorių matavimo. Grįžkite iki matavimo etapo; vedlys pažymės trūkstamą bandymą."; return; end
        r1=mean(1000*a(:,1)./a(:,2)); r2=mean(1000*b(:,1)./b(:,2));
        if n==4 then
            nums=[r1 r2 (r1/c.R1nom-1)*100 (r2/c.R2nom-1)*100];
            formulas=[msprintf("IŠ JŪSŲ R1 ŽURNALO: kiekvienai eilutei R = 1000 × U(V)/I(mA); trijų varžų vidurkis = %.10g Ω.",r1); ...
                msprintf("IŠ JŪSŲ R2 ŽURNALO: trijų 1000 × U(V)/I(mA) reikšmių vidurkis = %.10g Ω.",r2); ...
                msprintf("R1 nuokrypis = (Rvid/Rnom − 1) × 100 = (%.10g/%g − 1) × 100 = %.10g %%. Išlaikykite ženklą.",r1,c.R1nom,nums(3)); ...
                msprintf("R2 nuokrypis = (%.10g/%g − 1) × 100 = %.10g %%. Išlaikykite ženklą.",r2,c.R2nom,nums(4))];
        else
            rs1=1000*(a(3,1)-a(1,1))/(a(3,2)-a(1,2)); rs2=1000*(b(3,1)-b(1,1))/(b(3,2)-b(1,2));
            nums=[rs1 rs2 1000/rs2];
            formulas=[msprintf("R1 iš kreivės: R = 1000 × (U3−U1)/(I3−I1) = 1000 × (%g−%g)/(%.10g−%.10g) = %.10g Ω.",a(3,1),a(1,1),a(3,2),a(1,2),rs1); ...
                msprintf("R2 iš kreivės: R = 1000 × (%g−%g)/(%.10g−%.10g) = %.10g Ω.",b(3,1),b(1,1),b(3,2),b(1,2),rs2); ...
                msprintf("Laidis nusako, kaip lengvai teka srovė: G2 = 1000/R2 = 1000/%.10g = %.10g mS.",rs2,1000/rs2)];
        end
        for k=1:size(nums,"*")
            [lines,tag,value]=ld4_guide_input(k,nums(k),formulas(k));
            if tag<>"" then lines=[lines;purpose]; return; end
        end
    elseif n==6 then
        [lines,tag]=ld4_guide_measure_next(3,[3]);
        if tag<>"" then lines=[lines;"KAM: sudėjus rezistorius nuosekliai, bendra varža turi būti lygi abiejų atskirų varžų sumai."]; return; end
        a=ld4_journal_rows(3); r=1000*a(1,1)/a(1,2);
        [lines,tag,value]=ld4_guide_input(1,r,msprintf("IŠ JŪSŲ NUOSEKLAUS BANDYMO: RΣ = 1000 × U/I = 1000 × %g/%.10g = %.10g Ω. Palyginkite su ankstesnių R1 ir R2 suma.",a(1,1),a(1,2),r));
        if tag<>"" then return; end
    elseif n==7 then
        a=ld4_journal_rows(1); b=ld4_journal_rows(2);
        if size(a,1)<3 | size(b,1)<3 then tag="LD4_BACK"; lines="DABAR spauskite geltoną ← Atgal: išvadoms pirmiausia reikia abiejų rezistorių trijų matavimo taškų."; return; end
        r1s=1000*a(:,1)./a(:,2); r2s=1000*b(:,1)./b(:,2);
        r1=mean(r1s);r2=mean(r2s);d1=(r1/c.R1nom-1)*100;d2=(r2/c.R2nom-1)*100;
        linear=max(abs(r1s/r1-1))<0.01 & max(abs(r2s/r2-1))<0.01;
        answer=2;if linear then answer=1;end
        [lines,tag,value]=ld4_guide_input(1,answer,msprintf("IŠVADA IŠ ŽURNALO: keičiant U, R1 U/I lieka apie %.10g Ω, R2 – apie %.10g Ω. Todėl abiejų I(U) tiesinės; 1 reiškia Taip, 2 – Ne.",r1,r2));
        if tag<>"" then return; end
        answer=2;if abs(d1)<=5 & abs(d2)<=5 then answer=1;end
        [lines,tag,value]=ld4_guide_input(2,answer,msprintf("IŠVADA: R1 nuokrypis %.10g %%, R2 %.10g %%. Jų absoliučias reikšmes lyginame su 5 %% riba; 1 – abu telpa, 2 – bent vienas netelpa.",d1,d2));
        if tag<>"" then return; end
    end
    tag="LD4_PRIMARY"; value="";
    lines=["DABAR spauskite geltoną pagrindinį mygtuką dešinėje. Reikalingi bandymai ir laukai paruošti; užfiksuosime šį etapą.";purpose];
endfunction

function [lines,tag]=ld4_guide_measure_next(mode,indices)
    global LD4;
    lines=emptystr(0,1);tag="";rows=ld4_journal_rows(mode); k=0;
    for index=matrix(indices,1,-1)
        found=%f;target=LD4.cfg("U"+string(index));
        if size(rows,1)>0 then found=or(abs(rows(:,1)-target)<1e-9); end
        if ~found then k=index;break;end
    end
    if k==0 then return;end
    if ~LD4.powerOn then tag="B01";lines="DABAR spauskite geltoną Maitinimas: įjungsime sujungtą grandinę.";
    elseif ~LD4.switchOn then tag="B02";lines="DABAR spauskite geltoną Jungiklis: uždarysime srovės kelią.";
    elseif LD4.voltage<>LD4.cfg("U"+string(k)) then
        tag="B"+string(9+k);lines=msprintf("DABAR spauskite geltoną U%d = %g V. Tai %d-asis to paties rezistoriaus bandymo taškas.",k,LD4.cfg("U"+string(k)),k);
    else tag="B03";lines=msprintf("DABAR spauskite geltoną Matuoti: įrašysime U%d = %g V ir gautą srovę į žurnalą. Rodmenų perrašyti nereikia.",k,LD4.cfg("U"+string(k)));end
endfunction

function ld4_guide_close()
    global LD4;
    if typeof(LD4)=="st" then LD4.guide_enabled=%f; end
    if exists("student_guide_hide")==1 then student_guide_hide("LD4"); end
    ld4_guide_refresh();
endfunction

function ld4_guide_refresh()
    global LD4;
    if typeof(LD4)<>"st" then return; end
    if ~isfield(LD4,"step") | ~isfield(LD4,"ui") then return; end
    if isfield(LD4.ui,"headless") then if LD4.ui.headless then return; end; end
    if ~isfield(LD4,"fig") then return; end
    if LD4.step<1 | LD4.step>7 then return; end
    enabled=%f; if isfield(LD4,"guide_enabled") then enabled=LD4.guide_enabled; end
    lines=emptystr(0,1); tag=""; value="";
    if enabled then [lines,tag,value]=ld4_guide_next(); end
    if isfield(LD4.ui,"instructionLine") then
        if enabled then LD4.ui.instructionLine(1).string=student_wrap(lines(1),38);
        else LD4.ui.instructionLine(1).string=student_wrap(ld4_step_instruction(LD4.step),38); end
    end
    if exists("student_guide_update")==1 then student_guide_update("LD4",string(LD4.step)+" / 7 · kitas veiksmas",lines,enabled); end
    if exists("student_guide_focus")==1 then student_guide_focus("LD4",LD4.fig,tag,enabled); end
    if exists("student_guide_action_refresh")==1 then student_guide_action_refresh("LD4",LD4.fig,tag,value,enabled); end
endfunction

function text=ld4_guide_terminal(id)
    text="["+ld4_terminal_code(id)+"] "+ld4_terminal_name(id);
endfunction

function lines=ld4_guide_wires(canon)
    global LD4;
    lines=emptystr(0,1); removal=emptystr(0,1); missing=emptystr(0,2);
    for j=1:size(LD4.wires,1)
        matches=0;
        for k=1:size(canon,1)
            if and(LD4.wires(j,:)==canon(k,:)) | and(LD4.wires(j,:)==canon(k,[2 1])) then matches=matches+1; end
        end
        duplicate=%f;
        for previous=1:j-1
            if and(LD4.wires(j,:)==LD4.wires(previous,:)) | and(LD4.wires(j,:)==LD4.wires(previous,[2 1])) then duplicate=%t; end
        end
        if matches==0 | duplicate then
            removal($+1)="Pašalinkite nereikalingą laidą: pele spauskite "+ld4_guide_terminal(LD4.wires(j,1))+", tada "+ld4_guide_terminal(LD4.wires(j,2))+". Šis esamas laidas išnyks.";
        end
    end
    for k=1:size(canon,1)
        found=%f;
        for j=1:size(LD4.wires,1)
            if and(LD4.wires(j,:)==canon(k,:)) | and(LD4.wires(j,:)==canon(k,[2 1])) then found=%t; end
        end
        if ~found then missing($+1,:)=canon(k,:); end
    end
    // Resolve the pending click BEFORE describing another pair. Otherwise the
    // next suggested first endpoint would itself complete an unintended wire.
    active=0;
    if LD4.pending<>"" then
        if ~LD4.powerOn & size(removal,"*")==0 then
            for k=1:size(missing,1)
                if or(missing(k,:)==LD4.pending) then active=k;break;end
            end
        end
        if active>0 then
            pair=missing(active,:); other=pair(1);if other==LD4.pending then other=pair(2);end
            lines($+1)="Jau pasirinktas "+ld4_guide_terminal(LD4.pending)+". Dabar pele spauskite "+ld4_guide_terminal(other)+". Šis vienas paspaudimas užbaigs pasirinktą laidą.";
        else
            lines($+1)="Pirmiausia atšaukite pasirinktą "+ld4_guide_terminal(LD4.pending)+": pele spauskite tą patį kontaktą dar kartą. Tik atšaukę rinkitės kitą porą.";
        end
        lines=[lines;"";"LIKUSI LAIDŲ SEKA – tik užbaigę arba atšaukę aukščiau nurodytą pasirinkimą:"];
    end
    if LD4.powerOn then lines($+1)="Pele spauskite Maitinimas ir išjunkite šaltinį; tada keiskite laidus."; end
    lines=[lines;removal];
    for k=1:size(missing,1)
        if k==active then continue;end
        lines($+1)="Pele spauskite "+ld4_guide_terminal(missing(k,1))+", tada "+ld4_guide_terminal(missing(k,2))+". Tarp jų atsiras laidas.";
    end
    if size(missing,1)==0 then lines($+1)="Visos reikiamos kontaktų poros sujungtos. Patikrinkite, ar nėra papildomų laidų."; end
endfunction

function lines=ld4_guide_power()
    global LD4;
    lines=emptystr(0,1);
    if ~LD4.powerOn then lines($+1)="Pele spauskite Maitinimas (dešinėje nuo grandinės)."; end
    if ~LD4.switchOn then lines($+1)="Pele spauskite Jungiklis (po mygtuku Maitinimas), kad uždarytumėte grandinę."; end
endfunction

function lines=ld4_guide_lines()
    global LD4;
    lines=emptystr(0,1);
    if typeof(LD4)<>"st" then return; end
    if ~isfield(LD4,"step") | ~isfield(LD4,"cfg") then return; end
    if LD4.step<1 | LD4.step>7 then return; end
    c=LD4.cfg;
    lines=["Vedimas įjungtas jūsų pasirinkimu. Langas atsinaujina po veiksmų; uždarymas vedimą išjungia."; ...
        msprintf("Jūsų nominalai: R1nom = %g Ω; R2nom = %g Ω. Įtampos U1 = %g V, U2 = %g V, U3 = %g V.",c.R1nom,c.R2nom,c.U1,c.U2,c.U3)];
    if LD4.demoMode then lines($+1)="Dabar matote pavyzdį. Per Pagalba → Daugiau veiksmų → Parodyti pavyzdį / mano darbą grįžkite į savo darbą."; return; end
    if LD4.step==7 & LD4.done(7) then
        lines=[lines;"Jūsų išvados jau užfiksuotos. Pele spauskite ĮRAŠYTI ATASKAITĄ dešinės skilties apačioje.";ld4_guide_export()];
        return;
    end
    select LD4.step
    case 1 then
        lines=[lines;"R1 matavimo grandinėje reikalingi 6 laidai. Dabartinis pasirinkimas ir likusių laidų seka pateikti žemiau.";ld4_guide_wires(ld4_canonical_wires(1)); ...
            "Kai sujungti 6 laidai, pele spauskite TOLIAU → dešinės skilties apačioje."];
    case 2 then
        lines=[lines;msprintf("Teorinė I1 skaičiuojama pagal nominalą: I1 = 1000 × %g / %g, mA.",c.U1,c.R1nom); ...
            "Pele spauskite I1 teorinė, mA [A02.01], įveskite savo apskaičiuotą skaičių be vieneto."; ...
            ld4_guide_power();ld4_guide_measurements(1,[1 2 3]); ...
            "R1 turi turėti tris žurnalo eilutes. Užpildę teorinę srovę ir išmatavę tris taškus, spauskite TOLIAU →."];
    case 3 then
        if LD4.wireMode<>2 then
            lines($+1)="Pele spauskite Į R2 (grandinės apačioje). Šis esamas stendo valdiklis perjungia laidus į R2 ir automatiškai išjungia maitinimą.";
            lines($+1)="Po perjungimo vėl spauskite Maitinimas, tada Jungiklis. Toliau išmatuokite U1, U2 ir U3, kaskart spausdami Matuoti.";
        else
            lines=[lines;"Grandinė jau perjungta į R2; Į R2 pakartotinai spausti nereikia.";ld4_guide_power();ld4_guide_measurements(2,[1 2 3])];
        end
        lines($+1)="Kai R2 turi tris matavimo taškus, spauskite TOLIAU →. Šiame etape atsakymo laukų nėra.";
    case 4 then
        lines=[lines;ld4_guide_journal(1);ld4_guide_journal(2); ...
            "Kiekvienam R1 bandymui apskaičiuokite R = 1000 × U(V)/I(mA). Sudėkite tris R ir padalykite iš 3."; ...
            "Pele spauskite R1 iš matavimų, Ω [A04.01] ir įveskite savo vidurkį. R2 eilutėms pakartokite tą patį ir įveskite į R2 iš matavimų, Ω [A04.02]."; ...
            msprintf("Nuokrypis δ = (Rvid/Rnom − 1) × 100 %%. Naudokite atitinkamus nominalus R1nom = %g Ω ir R2nom = %g Ω.",c.R1nom,c.R2nom); ...
            "Savo δ1 įveskite į R1 nuokrypis, % [A04.03]; δ2 į R2 nuokrypis, % [A04.04]. Išlaikykite nuokrypio ženklą + arba −; laukuose rašykite tik skaičius."; ...
            "Baigę pele spauskite TOLIAU →."];
    case 5 then
        lines=[lines;ld4_guide_journal(1);ld4_guide_journal(2); ...
            "Atskirai R1 ir R2 paimkite žurnalo taškus ties mažiausia U1 ir didžiausia U3."; ...
            "Apskaičiuokite R = 1000 × (U3 − U1)/(I3 − I1), Ω; žurnalo srovės yra mA."; ...
            "Pele spauskite R1 iš nuolydžio, Ω [A05.01] ir įveskite savo R1; į R2 iš nuolydžio, Ω [A05.02] įveskite savo R2."; ...
            "Apskaičiuokite G2 = 1000 / R2, mS. Savo rezultatą įveskite į G2, mS [A05.03]. 1 S = 1000 mS."; ...
            "Laukuose rašykite tik skaičius. Tada spauskite TOLIAU →."];
    case 6 then
        lines=[lines;"Savarankiškai pakeiskite esamą R2 grandinę į R1 ir R2 nuoseklų jungimą. Žemiau pateikiama dabartinio pasirinkimo ir likusių laidų seka.";ld4_guide_wires(ld4_canonical_wires("S")); ...
            "Voltmetras turi apimti abu rezistorius; iš viso reikalingi 7 laidai.";ld4_guide_power();ld4_guide_measurements(3,[3]); ...
            "Iš nuoseklaus jungimo žurnalo U ir I apskaičiuokite RΣ = 1000 × U(V)/I(mA), Ω."; ...
            "Pele spauskite R1 + R2 iš matavimo, Ω [A06.01] ir įveskite savo apskaičiuotą varžą; spauskite TOLIAU →."];
    case 7 then
        lines=[lines;"Palyginkite R1 ir R2 trijų taškų I(U) priklausomybes."; ...
            "Pele spauskite Ar abi I(U) tiesinės? 1 Taip / 2 Ne [A07.01] ir įveskite savo kodą 1 arba 2."; ...
            "Palyginkite savo δ1 ir δ2 absoliučias reikšmes su 5 %."; ...
            "Pele spauskite Ar nuokrypis ≤ 5 %? 1 Taip / 2 Ne [A07.02] ir įveskite savo kodą 1 arba 2."; ...
            "Spauskite TOLIAU → išvadoms užfiksuoti, tada ĮRAŠYTI ATASKAITĄ. Originalų sukurtą HTML pateikite dėstytojui."; ...
            ld4_guide_export()];
    end
    if ~LD4.assessment & ~LD4.done(LD4.step) then
        lines=strsubst(lines,"TOLIAU →","TIKRINTI");
        lines($+1)="Mokymosi režime mygtukas TIKRINTI patikrina jūsų įvestį. Jei gausite klaidos paaiškinimą, pataisykite atsakymą ir tikrinkite dar kartą.";
    end
    if LD4.done(LD4.step) then lines($+1)="Dabartinis etapas jau užfiksuotas. Galite pereiti toliau."; end
endfunction

function lines=ld4_guide_measurements(tag,indices)
    global LD4;
    lines=emptystr(0,1); rows=ld4_journal_rows(tag);
    names=["R1";"R2";"R1+R2"];
    for k=matrix(indices,1,-1)
        target=LD4.cfg("U"+string(k)); hit=[];
        if size(rows,1)>0 then hit=find(abs(rows(:,1)-target)<1e-9); end
        if hit<>[] then
            lines($+1)=msprintf("%s ties U%d jau išmatuota: U = %.10g V; I = %.10g mA. Šio taško nekartokite.",names(tag),k,rows(hit(1),1),rows(hit(1),2));
        else
            lines($+1)=msprintf("Pele spauskite U%d = %g V, tada Matuoti. %s rodmenys automatiškai atsiras matavimų sąraše.",k,target,names(tag));
        end
    end
endfunction

function lines=ld4_guide_journal(tag)
    rows=ld4_journal_rows(tag); names=["R1";"R2";"R1+R2"];
    lines="Jūsų "+names(tag)+" rodmenys:";
    if size(rows,1)==0 then lines($+1)="Rodmenų dar nėra. Mygtuku ← Atgal grįžkite į šio jungimo matavimo etapą."; end
    for k=1:size(rows,1)
        lines($+1)=msprintf("U = %.10g V; I = %.10g mA.",rows(k,1),rows(k,2));
    end
endfunction

function lines=ld4_guide_export()
    global LD4;
    title="Ataskaita išsaugota";
    if ~LD4.assessment | LD4.practice_used then title="Mokymosi ataskaita išsaugota";end
    lines=["Programa pati įrašo HTML failą ir atveria patvirtinimą „"+title+"“."; ...
        "Patvirtinimo lange pele spauskite Atverti ataskaitą: atverkite HTML ir peržiūrėkite jo turinį."; ...
        "Grįžkite į patvirtinimo langą ir spauskite Atverti ataskaitų aplanką. Raskite tame lange nurodytą HTML failą; pateikite dėstytojui šį originalų failą."; ...
        "Norėdami grįžti į laboratorinį stendą, patvirtinimo lange spauskite Grįžti į darbą. Failas jau išsaugotas."];
    if ~LD4.assessment | LD4.practice_used then lines($+1)="Tai mokymosi ataskaita; į atsiskaitymo pažymių suvestinę ji neįtraukiama.";end
endfunction

// Pure next-wire selection: remove an incorrect wire before adding another.
function [lines,tag]=ld4_guide_wire_next(canon)
    global LD4;
    lines=emptystr(0,1); tag=""; bad=emptystr(0,2); missing=emptystr(0,2);
    for j=1:size(LD4.wires,1)
        pair=LD4.wires(j,:); good=%f; duplicate=%f;
        for k=1:size(canon,1)
            if and(pair==canon(k,:)) | and(pair==canon(k,[2 1])) then good=%t; end
        end
        for k=1:j-1
            if and(pair==LD4.wires(k,:)) | and(pair==LD4.wires(k,[2 1])) then duplicate=%t; end
        end
        if ~good | duplicate then bad($+1,:)=pair; end
    end
    for k=1:size(canon,1)
        found=%f;
        for j=1:size(LD4.wires,1)
            if and(canon(k,:)==LD4.wires(j,:)) | and(canon(k,:)==LD4.wires(j,[2 1])) then found=%t; end
        end
        if ~found then missing($+1,:)=canon(k,:); end
    end
    if size(bad,1)==0 & size(missing,1)==0 & LD4.pending=="" then return; end
    if LD4.powerOn then
        tag="B01"; lines="DABAR spauskite geltoną Maitinimas: prieš keičiant laidus šaltinį reikia išjungti."; return;
    end
    pair=emptystr(0,2); remove=%f;
    if size(bad,1)>0 then pair=bad(1,:); remove=%t;
    elseif LD4.pending<>"" then
        for k=1:size(missing,1)
            if or(missing(k,:)==LD4.pending) then pair=missing(k,:); break; end
        end
    elseif size(missing,1)>0 then pair=missing(1,:);
    end
    if LD4.pending<>"" then
        target=LD4.pending; cancel=%t;
        if size(pair,"*")==2 then
            if pair(1)==LD4.pending then target=pair(2); cancel=%f;
            elseif pair(2)==LD4.pending then target=pair(1); cancel=%f; end
        end
        tag=ld4_terminal_code(target);
        if cancel then lines="DABAR dar kartą spauskite geltoną "+ld4_guide_terminal(target)+": atšauksite netyčia pradėtą laidą.";
        elseif remove then lines="DABAR spauskite geltoną "+ld4_guide_terminal(target)+": šis antras paspaudimas pašalins netinkamą laidą.";
        else lines="DABAR spauskite geltoną "+ld4_guide_terminal(target)+": užbaigsite vieną reikiamą laidą."; end
    else
        tag=ld4_terminal_code(pair(1));
        if remove then lines="DABAR spauskite geltoną "+ld4_guide_terminal(pair(1))+". Po jo pažymėsiu kitą netinkamo laido galą; pašalinsime tik tą laidą.";
        else lines="DABAR spauskite geltoną "+ld4_guide_terminal(pair(1))+". Tada geltonai pažymėsiu antrą šio laido galą."; end
    end
endfunction

function [lines,tag,value]=ld4_guide_input(slot,number,formula)
    global LD4;
    lines=emptystr(0,1); tag=""; value="";
    raw=LD4.answers(LD4.step,slot); actual=ld4_parse_number(raw);
    if LD4.step==7 then
        // The conclusion fields accept literal codes 1 or 2, not 1.0/1e0.
        if raw==string(number) then return; end
    elseif ~isnan(actual) then
        if abs(actual-number)<=1e-8+0.005*abs(number) then return; end
    end
    value=msprintf("%.10g",number); tag=ld4_answer_code(LD4.step,slot);
    lines=["DABAR į geltoną lauką ["+tag+"] įrašykite "+value+" (tik skaičių).";formula; ...
        "Mygtukas pagalbos lange įrašo tik šią parodytą reikšmę. Galite ją įvesti ir klaviatūra."];
endfunction
