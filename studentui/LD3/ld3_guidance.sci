// One visible next action. Opening the guide changes no experiment data.
function ld3_guide_show()
    global LD3;
    if typeof(LD3)<>"st" then return; end
    LD3.guide_enabled=%t; ld3_guide_refresh();
endfunction

function ld3_guide_close()
    global LD3;
    if typeof(LD3)=="st" then
        LD3.guide_enabled=%f;
        if isfield(LD3,"fig") & exists("student_guide_focus")==1 then
            if is_handle_valid(LD3.fig) then student_guide_focus("LD3",LD3.fig,"",%f); end
        end
    end
    if exists("student_guide_hide")==1 then student_guide_hide("LD3"); end
endfunction

function ld3_guide_refresh()
    global LD3;
    if typeof(LD3)<>"st" then return; end
    if ~isfield(LD3,"guide_enabled") | ~isfield(LD3,"ui") then return; end
    if isfield(LD3.ui,"headless") then if LD3.ui.headless then return; end; end
    if ~isfield(LD3,"step") then return; end
    if LD3.step<1 | LD3.step>6 then return; end
    [lines,tag,value]=ld3_guide_next();
    titles=["Sujunkite grandinę";"1 bandymas iš 3";"2 ir 3 bandymai";"Tas pats rezistorius";"Varža iš dviejų taškų";"Ką parodė bandymai?"];
    if exists("student_guide_update")==1 then
        student_guide_update("LD3",string(LD3.step)+" / 6 · "+titles(LD3.step),lines,LD3.guide_enabled);
    end
    if isfield(LD3,"fig") then
        if is_handle_valid(LD3.fig) then
            if exists("student_guide_focus")==1 then student_guide_focus("LD3",LD3.fig,tag,LD3.guide_enabled); end
            if exists("student_guide_action_refresh")==1 then student_guide_action_refresh("LD3",LD3.fig,tag,value,LD3.guide_enabled); end
        end
    end
endfunction

function text=ld3_guide_terminal(id)
    text="["+ld3_terminal_code(id)+"] "+ld3_terminal_name(id);
endfunction

function [lines,tag,value]=ld3_guide_next()
    global LD3;
    lines=emptystr(0,1);tag="";value="";
    if typeof(LD3)<>"st" then return; end
    if ~isfield(LD3,"step") | ~isfield(LD3,"cfg") then return; end
    c=LD3.cfg;
    purpose=msprintf("KAM TAI DAROME? Tas pats R = %g Ω rezistorius. Keičiame tik įtampą: %g V → %g V → %g V. Matuojame, kaip dėl to keičiasi srovė.",c.R,c.U1,c.U2,c.U3);
    if LD3.demoMode then lines=["DABAR: grįžkite į savo darbą per Pagalba → Daugiau veiksmų → Parodyti pavyzdį / mano darbą.";purpose];return;end
    if LD3.step==1 then
        if LD3.powerOn then
            tag="B01";lines=["DABAR: spauskite geltoną Maitinimas, kad jį išjungtumėte. Laidus jungiame tik išjungę šaltinį.";purpose];return;
        end
        canon=ld3_canonical_wires();missing=emptystr(0,2);bad=%f;
        for j=1:size(LD3.wires,1)
            match=0;
            for k=1:size(canon,1)
                if and(LD3.wires(j,:)==canon(k,:)) | and(LD3.wires(j,:)==canon(k,[2 1])) then match=match+1;end
            end
            for k=1:j-1
                if and(LD3.wires(j,:)==LD3.wires(k,:)) | and(LD3.wires(j,:)==LD3.wires(k,[2 1])) then match=0;end
            end
            if match<>1 then bad=%t;end
        end
        for k=1:size(canon,1)
            hit=%f;
            for j=1:size(LD3.wires,1)
                if and(LD3.wires(j,:)==canon(k,:)) | and(LD3.wires(j,:)==canon(k,[2 1])) then hit=%t;end
            end
            if ~hit then missing($+1,:)=canon(k,:);end
        end
        if LD3.pending<>"" then
            target=LD3.pending;context="Pasirinktas netinkamas pradinis kontaktas. Spauskite jį dar kartą: taip atšauksite pasirinkimą.";
            if ~bad then
                for k=1:size(missing,1)
                    if or(missing(k,:)==LD3.pending) then
                        target=missing(k,1);if target==LD3.pending then target=missing(k,2);end
                        context="Užbaikite pradėtą laidą: spauskite "+ld3_guide_terminal(target)+".";break;
                    end
                end
            end
            tag=ld3_terminal_code(target);lines=["DABAR: "+context;"Geltonai pažymėtas būtent kitas kontaktas. Laidas atsiras po šio paspaudimo, jei užbaigiate porą.";purpose];return;
        end
        if bad then tag="B06";lines=["DABAR: spauskite geltoną Išvalyti laidus. Yra netinkamas arba pakartotas laidas; po išvalymo vedlys vėl rodys kontaktus po vieną.";purpose];return;end
        if size(missing,1)>0 then
            tag=ld3_terminal_code(missing(1,1));
            lines=["DABAR: spauskite geltoną "+ld3_guide_terminal(missing(1,1))+"."; ...
                "Tada geltonai bus pažymėtas "+ld3_guide_terminal(missing(1,2))+". Paspaudę jį sujungsite vieną laidą."; ...
                msprintf("Jau sujungta %d iš 6 laidų. Teisingų laidų kartoti nereikia.",size(LD3.wires,1));purpose];return;
        end
        tag="LD3_PRIMARY";lines=["DABAR: visi 6 laidai sujungti. Spauskite geltoną pagrindinį mygtuką ir pradėkite pirmą bandymą.";purpose];return;
    end
    if LD3.step==2 | LD3.step==3 then
        [journalOK,why]=ld3_journal_order_valid();
        if ~journalOK then
            tag="B06";lines=["DABAR: spauskite geltoną Pradėti matavimus iš naujo. "+why; ...
                "Programa išvalys netinkamą matavimų seką ir grąžins į pirmą bandymą. Naujus rodmenis užfiksuosite iš virtualaus stendo.";purpose];return;
        end
    end
    if LD3.step==2 then
        theory=1000*c.U1/c.R;
        if ld3_guide_number_missing(2,1) then
            tag="A02.01";value=msprintf("%.10g",theory);
            lines=["DABAR: į geltoną lauką I1 teorinė, mA įrašykite "+value+". Galite naudoti vedlio įvedimo mygtuką."; ...
                msprintf("I1 = 1000 × U1 / R = 1000 × %g / %g = %.10g mA. Daugiklis 1000 amperus paverčia miliamperais.",c.U1,c.R,theory); ...
                "Tai prognozė prieš pirmą matavimą. Toliau patikrinsime ją ampermetro rodmeniu.";purpose];return;
        end
        if size(LD3.journal,1)<1 then [lines,tag]=ld3_guide_trial(1);lines=[lines;purpose];return;end
        tag="LD3_PRIMARY";lines=["DABAR: pirmas bandymas užfiksuotas. Spauskite geltoną pagrindinį mygtuką ir palyginkite dar du bandymus."; ...
            msprintf("Pirmas rodmuo: U1 = %g V; I1 = %.10g mA. Toliau pakeisime tik įtampą; rezistorius liks tas pats.",LD3.journal(1,1),LD3.journal(1,2));purpose];return;
    end
    if LD3.step==3 then
        if size(LD3.journal,1)<1 then tag="LD3_BACK";lines=["DABAR: spauskite geltoną ← Atgal ir užfiksuokite pirmą bandymą.";purpose];return;end
        if size(LD3.journal,1)<3 then
            [lines,tag]=ld3_guide_trial(size(LD3.journal,1)+1);lines=[lines;purpose;"KĄ LYGINAME? Kai įtampa padidėja, tikriname, ar tiek pat kartų padidėja srovė."];return;
        end
        tag="LD3_PRIMARY";lines=["DABAR: visi trys bandymai užfiksuoti. Spauskite geltoną pagrindinį mygtuką: iš šių rodmenų apskaičiuosime varžą.";ld3_guide_journal();ld3_guide_comparison();purpose];return;
    end
    if LD3.step>=4 & LD3.step<=6 then
        [journalOK,why]=ld3_journal_order_valid();
        if ~journalOK | size(LD3.journal,1)<>3 then
            tag="LD3_BACK";lines=["DABAR: spauskite geltoną ← Atgal, kol grįšite į matavimų etapą. Reikalingi visi trys jūsų varianto rodmenys.";purpose];return;
        end
        u=LD3.journal(:,1);i=LD3.journal(:,2);
        if or(i==0) | or(isnan(i)) then tag="LD3_BACK";lines=["DABAR: grįžkite į matavimus. Iš nulinės arba neįrašytos srovės varžos apskaičiuoti negalima.";purpose];return;end
        resistances=1000*u./i;
        select LD3.step
        case 4 then
            values=[resistances;mean(resistances)];tags=["A04.01";"A04.02";"A04.03";"A04.04"];
            labels=["R pagal U1";"R pagal U2";"R pagal U3";"R vidurkis"];
            detail=emptystr(0,1);
            for k=1:3;detail($+1)=msprintf("%d bandymas: R = 1000 × %.10g / %.10g = %.10g Ω.",k,u(k),i(k),values(k));end
            detail($+1)=msprintf("Vidurkis = (%.10g + %.10g + %.10g) / 3 = %.10g Ω.",values(1),values(2),values(3),values(4));
            for k=1:4
                if ld3_guide_number_missing(4,k) then
                    tag=tags(k);value=msprintf("%.10g",values(k));
                    lines=["DABAR: į geltoną "+labels(k)+", Ω lauką įrašykite "+value+". Galite naudoti vedlio įvedimo mygtuką.";detail; ...
                        "KĄ TAI REIŠKIA? Keičiant įtampą gauname tą pačią varžą: rezistorius nebuvo keičiamas. Srovė pateikta mA, todėl formulėje reikia 1000.";purpose];return;
                end
            end
            tag="LD3_PRIMARY";lines=["DABAR: varžų laukai užpildyti. Spauskite geltoną pagrindinį mygtuką.";detail;"Iš trijų matavimų gautos vienodos varžos. Toliau patikrinsime dar kitu skaičiavimo keliu.";purpose];return;
        case 5 then
            du=u(3)-u(1);di=i(3)-i(1);
            if di==0 then tag="LD3_BACK";lines=["DABAR: grįžkite ir patikrinkite matavimus. Pirmo ir trečio bandymo srovės negali sutapti, kai skiriasi įtampos.";purpose];return;end
            result=1000*du/di;
            detail=[msprintf("ΔU = %.10g − %.10g = %.10g V.",u(3),u(1),du); ...
                msprintf("ΔI = %.10g − %.10g = %.10g mA.",i(3),i(1),di); ...
                msprintf("R = 1000 × ΔU / ΔI = 1000 × %.10g / %.10g = %.10g Ω.",du,di,result)];
            if ld3_guide_number_missing(5,1) then tag="A05.01";value=msprintf("%.10g",result);lines=["DABAR: į geltoną R iš nuolydžio, Ω lauką įrašykite "+value+". Galite naudoti vedlio įvedimo mygtuką.";detail;"Kodėl dar kartą? Iš dviejų taškų pokyčių gauname tą pačią rezistoriaus varžą.";purpose];return;end
            tag="LD3_PRIMARY";lines=["DABAR: spauskite geltoną pagrindinį mygtuką ir pereikite prie išvadų.";detail;purpose];return;
        case 6 then
            detail=[ld3_guide_journal();ld3_guide_comparison(); ...
                msprintf("Apskaičiuotos varžos: %.10g Ω; %.10g Ω; %.10g Ω. Keičiant įtampą jos sutampa.",resistances(1),resistances(2),resistances(3)); ...
                "IŠVADA: tam pačiam rezistoriui srovė didėja proporcingai įtampai; varža lieka pastovi. Tai Omo dėsnis I = U / R."];
            if LD3.done(6) then tag="LD3_PRIMARY";lines=["DABAR: spauskite geltoną ĮRAŠYTI ATASKAITĄ. Išsaugotą originalų HTML pateikite dėstytojui.";detail;ld3_guide_export()];return;end
            for k=1:2
                raw=stripblanks(LD3.answers(6,k));
                if raw<>"1" & raw<>"2" then
                    tag="A06.0"+string(k);value="1";
                    if k==1 then question="Ar I(U) tiesinė?";else question="Ar R pastovi?";end
                    lines=["DABAR: geltoname lauke „"+question+"“ pasirinkimo kodas 1 reiškia Taip, 2 – Ne. Šių rodmenų atsakymas: 1. Galite naudoti vedlio įvedimo mygtuką.";detail];return;
                end
            end
            tag="LD3_PRIMARY";lines=["DABAR: spauskite geltoną pagrindinį mygtuką ir užfiksuokite savo išvadas. Po to įrašysite ataskaitą.";detail];return;
        end
    end
endfunction

function missing=ld3_guide_number_missing(step,slot)
    global LD3;
    raw=stripblanks(LD3.answers(step,slot));missing=raw=="";
    if ~missing then missing=isnan(ld3_parse_number(raw));end
endfunction

function [lines,tag]=ld3_guide_trial(k)
    global LD3;
    target=LD3.cfg("U"+string(k));
    context=msprintf("%d BANDYMAS IŠ 3: nustatome %g V ir išmatuojame srovę tame pačiame rezistoriuje.",k,target);
    if ~LD3.powerOn then tag="B01";lines=["DABAR: spauskite geltoną Maitinimas, kad įjungtumėte šaltinį.";context];return;end
    if ~LD3.switchOn then tag="B02";lines=["DABAR: spauskite geltoną Jungiklis. Taip uždarysite grandinę ir srovė galės tekėti.";context];return;end
    if LD3.voltage<>target then tag="B"+string(9+k);lines=[msprintf("DABAR: spauskite geltoną U%d = %g V. Kiti įtampos mygtukai skirti kitiems bandymams.",k,target);context];return;end
    tag="B03";lines=["DABAR: spauskite geltoną Matuoti. Programa įrašys virtualaus stendo voltmetro ir ampermetro rodmenis; perrašyti jų nereikia.";context];
endfunction

function lines=ld3_guide_lines()
    [lines,tag,value]=ld3_guide_next();
endfunction

function lines=ld3_guide_journal()
    global LD3;
    lines="JŪSŲ UŽFIKSUOTI RODMENYS:";
    for k=1:size(LD3.journal,1);lines($+1)=msprintf("%d bandymas: U = %.10g V; I = %.10g mA.",k,LD3.journal(k,1),LD3.journal(k,2));end
endfunction

function lines=ld3_guide_comparison()
    global LD3;
    lines=emptystr(0,1);
    if size(LD3.journal,1)<>3 then return;end
    u=LD3.journal(:,1);i=LD3.journal(:,2);
    if u(1)==0 | i(1)==0 then return;end
    lines=[msprintf("U2 / U1 = %.5g karto; I2 / I1 = %.5g karto. Įtampa ir srovė padidėjo tiek pat kartų.",u(2)/u(1),i(2)/i(1)); ...
        msprintf("U3 / U1 = %.5g karto; I3 / I1 = %.5g karto. Tas pats ryšys išlieka ir trečiame bandyme.",u(3)/u(1),i(3)/i(1))];
endfunction

function caption=ld3_trial_caption()
    global LD3;
    c=LD3.cfg;n=size(LD3.journal,1);
    if n<3 then
        k=n+1;caption=msprintf("Tas pats rezistorius: %g V → %g V → %g V. Užfiksuota %d/3; kitas – %g V.",c.U1,c.U2,c.U3,n,c("U"+string(k)));
    else caption="Užfiksuota 3/3 bandymų. Įtampą didinome, srovė didėjo tiek pat kartų; rezistorius liko tas pats.";end
endfunction

function lines=ld3_guide_export()
    lines=["Patvirtinimo lange Atverti ataskaitą leidžia ją perskaityti."; ...
        "Atverti ataskaitų aplanką parodys išsaugotą HTML failą. Pateikite šį originalų failą dėstytojo nurodytu būdu."];
endfunction
