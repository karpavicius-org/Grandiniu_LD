// Opt-in, state-aware guide. Reading this file never performs an experiment.
function ld11_guide_show()
    global LD11;
    if typeof(LD11)<>"st" then return; end
    LD11.guide_enabled=%t; ld11_guide_refresh();
endfunction

function ld11_guide_close()
    global LD11;
    if typeof(LD11)<>"st" then return; end
    LD11.guide_enabled=%f;
    if exists("student_guide_hide")==1 then student_guide_hide("LD11"); end
    ld11_guide_refresh();
endfunction

function text=ld11_guide_contact(id)
    text="["+ld11_terminal_code(id)+"] "+ld11_terminal_name(id);
endfunction

function present=ld11_guide_has_wire(wires,pair)
    present=%f;
    for k=1:size(wires,1)
        if and(wires(k,:)==pair) | and(wires(k,:)==pair([2 1])) then present=%t; return; end
    end
endfunction

function [lines,tag]=ld11_guide_wire_target(mode)
    global LD11;
    lines=emptystr(0,1); tag="";
    if LD11.wireMode<>mode then
        tag=msprintf("B%02d",9+mode);
        lines="DABAR spauskite geltoną „"+ld11_guide_mode_name(mode)+"“. Šio sujungimo laidai saugomi atskirai."; return;
    end
    canon=ld11_canonical_wires(mode); bad=emptystr(0,2); missing=emptystr(0,2);
    for k=1:size(LD11.wires,1)
        duplicate=%f;
        for j=1:k-1
            if and(LD11.wires(k,:)==LD11.wires(j,:)) | and(LD11.wires(k,:)==LD11.wires(j,[2 1])) then duplicate=%t; end
        end
        if ~ld11_guide_has_wire(canon,LD11.wires(k,:)) | duplicate then bad($+1,:)=LD11.wires(k,:); end
    end
    for k=1:size(canon,1)
        if ~ld11_guide_has_wire(LD11.wires,canon(k,:)) then missing($+1,:)=canon(k,:); end
    end
    if size(bad,1)==0 & size(missing,1)==0 & LD11.pending=="" then return; end
    if LD11.powerOn then
        tag="B01"; lines="DABAR spauskite geltoną Maitinimas, kad šaltinis išsijungtų. Tada vedlys parodys taisomą kontaktą."; return;
    end
    if ~ld11_wiring_editable() then
        tag="LD11_BACK"; lines="DABAR spauskite geltoną ← Atgal. Laidus taisykite šio sujungimo matavimo etape."; return;
    end
    if LD11.pending<>"" then
        target="";
        if size(bad,1)>0 then
            pair=bad(1,:);
            if LD11.pending==pair(1) then target=pair(2); elseif LD11.pending==pair(2) then target=pair(1); end
            action="pašalinsite netinkamą laidą";
        else
            for k=1:size(missing,1)
                if LD11.pending==missing(k,1) then target=missing(k,2); break; end
                if LD11.pending==missing(k,2) then target=missing(k,1); break; end
            end
            action="užbaigsite pradėtą laidą";
        end
        if target=="" then
            tag=ld11_terminal_code(LD11.pending);
            lines="DABAR dar kartą spauskite geltoną "+ld11_guide_contact(LD11.pending)+" – atšauksite nereikalingą pasirinkimą.";
        else
            tag=ld11_terminal_code(target);
            lines="DABAR spauskite geltoną "+ld11_guide_contact(target)+" – "+action+". Pirmas galas jau pasirinktas.";
        end
        return;
    end
    if size(bad,1)>0 then
        pair=bad(1,:); tag=ld11_terminal_code(pair(1));
        lines="DABAR spauskite geltoną "+ld11_guide_contact(pair(1))+". Tada vedlys pažymės antrą netinkamo laido galą, kad laidą pašalintumėte."; return;
    end
    pair=missing(1,:); tag=ld11_terminal_code(pair(1));
    lines="DABAR spauskite geltoną "+ld11_guide_contact(pair(1))+". Tada geltonai užsidegs "+ld11_guide_contact(pair(2))+" – antras šio laido galas.";
endfunction

function [lines,tag,value]=ld11_guide_answer(step,slot,number,explanation)
    global LD11;
    tag=""; value=""; lines=emptystr(0,1);
    raw=LD11.answers(step,slot); entered=ld11_parse_number(raw);
    relative=.02; absolute=1e-9;
    if step==1 then relative=.01; end
    if step==3 then relative=.03; end
    if step==6 then relative=0; absolute=0; end
    // Choice callbacks/check_step store literal codes; a restored "1.0"
    // must be repaired even though it parses as the number 1.
    if step==6 then needed=stripblanks(raw)<>string(number);
    elseif stripblanks(raw)=="" | isnan(entered) | isinf(entered) then needed=%t;
    else needed=abs(entered-number)>absolute+relative*abs(number); end
    if ~needed then return; end
    tag=ld11_answer_code(step,slot); value=msprintf("%.10g",number);
    lines=["DABAR į geltoną lauką ["+tag+"] įrašykite "+value+". Vieneto ir formulės į lauką nerašykite.";explanation];
    if step==6 then
        choice="Ne"; if number==1 then choice="Taip"; end
        lines=["DABAR geltoname sąraše ["+tag+"] pasirinkite „"+choice+"“.";explanation];
    end
endfunction

function name=ld11_guide_mode_name(mode)
    names=["BE Ck";"SU Ck"];name=names(mode);
endfunction

function [lines,tag,value]=ld11_guide_next()
    global LD11;
    lines=emptystr(0,1);tag="";value="";
    if typeof(LD11)<>"st" then return;end
    if ~isfield(LD11,"step") | ~isfield(LD11,"cfg") then return;end
    st=LD11.step;c=LD11.cfg;
    if ~ld11_valid_index(st,6) then return;end
    if LD11.demoMode then
        tag="LD11_PRIMARY";lines="DABAR spauskite geltoną GRĮŽTI Į SAVO DARBĄ. Toliau naudosime jūsų matavimus.";return;
    end
    if LD11.done(st) then
        tag="LD11_PRIMARY";
        if st==6 & and(LD11.done) then lines="Darbas baigtas. DABAR spauskite geltoną IŠSAUGOTI ATASKAITĄ; originalų HTML pateikite dėstytojui.";
        elseif st==6 then lines="DABAR spauskite geltoną UŽBAIGTI PRALEISTĄ ETAPĄ. Programa atvers pirmą trūkstamą etapą.";
        else lines="Šis etapas jau įrašytas. DABAR spauskite geltoną TOLIAU →.";end
        return;
    end
    w=2*%pi*50;xl=w*c.L;z=sqrt(c.R^2+xl^2);
    if or(st==[1 2 4]) then
        mode=ld11_stage_mode(st);[lines,tag]=ld11_guide_wire_target(mode);
        if tag<>"" then return;end
        if or(st==[2 4]) & ld11_journal_rows(mode)==[] then
            if ~LD11.powerOn then tag="B01";lines="Laidai sujungti. DABAR spauskite geltoną Maitinimas, kad įjungtumėte generatorių.";return;end
            if ~LD11.switchOn then tag="B02";lines="DABAR spauskite geltoną Jungiklis. Jį uždarę leisite srovei tekėti grandine.";return;end
            tag="B03";lines="DABAR spauskite geltoną Matuoti. Virtualaus stendo U, I ir P rodmenys bus automatiškai įrašyti į žurnalą.";return;
        end
    end
    select st
    case 1 then
        number=c.R/z;
        [lines,tag,value]=ld11_guide_answer(1,1,number,msprintf("Pradinis cos φ0 = R/Z. XL = 2·π·50·%g = %.10g Ω; Z = sqrt(%g²+%.10g²) = %.10g Ω; cos φ0 = %.10g (be vieneto). Rodiklis artėja prie 1, kai mažesnė srovės dalis skirta reaktyviam energijos mainui.",c.L,xl,c.R,xl,z,number));
    case 2 then
        row=ld11_journal_rows(1);u=row($,1);i=row($,2);p=row($,4);s=u*i;
        numbers=[s,sqrt(max(0,s^2-p^2)),p/s];
        explanations=[msprintf("Išmatuota BE Ck: U = %.10g V; I = %.10g mA. Apskaičiuota pilnutinė galia S = U·I = %.10g mVA. V·mA jau duoda mVA; iš 1000 papildomai dauginti nereikia.",u,i,numbers(1)); ...
            msprintf("Išmatuota aktyvioji P = %.10g mW; apskaičiuota S = %.10g mVA. Reaktyvioji Q = sqrt(S²−P²) = %.10g mvar. Ji apibūdina energijos mainus su ritės magnetiniu lauku.",p,s,numbers(2)); ...
            msprintf("Išmatuota P = %.10g mW; iš U ir I apskaičiuota S = %.10g mVA. Galios faktorius cos φ = P/S = %.10g, be vieneto.",p,s,numbers(3))];
        for k=1:3
            [lines,tag,value]=ld11_guide_answer(2,k,numbers(k),explanations(k));if tag<>"" then return;end
        end
    case 3 then
        ideal=xl/(w*(c.R^2+xl^2))*1e6;number=c.Ck*1e6;
        [lines,tag,value]=ld11_guide_answer(3,1,number,msprintf("Kondensatorius kompensuoja ritės reaktyviąją galią. Ck = XL/[ω·(R²+XL²)] = %.10g µF, kai ω = 2·π·50, L = %g H. Stende naudojama iki 0,01 µF apvalinta talpa: %.10g µF. Šią talpą įrašome į atsakymo lauką; komponento keisti nereikia.",ideal,c.L,number));
    case 5 then
        before=ld11_journal_rows(1);after=ld11_journal_rows(2);
        if before==[] | after==[] then tag="LD11_BACK";lines="Trūksta vieno iš dviejų matavimų. DABAR spauskite geltoną ← Atgal ir grįžkite į 2 etapą (BE Ck) arba 4 etapą (SU Ck).";return;end
        u=after($,1);i=after($,2);p=after($,4);s=u*i;s1=before($,1)*before($,2);
        residual=abs(xl/(c.R^2+xl^2)-w*c.Ck);
        numbers=[s,1000*u^2*residual,p/s,s1-s];
        explanations=[msprintf("Po Ck prijungimo išmatuota U2 = %.10g V, I2 = %.10g mA. Pilnutinė galia apskaičiuojama: S2 = U2·I2 = %.10g mVA.",u,i,numbers(1)); ...
            msprintf("Q2 nėra tiesioginis matavimas. Skaičiuojame iš išmatuotos U2 = %.10g V ir žinomų R, L, Ck: Q2 = 1000·U2²·abs[XL/(R²+XL²)−ω·Ck] = %.10g mvar. Ck stende apvalinta iki 0,01 µF, todėl Q2 gali likti maža, bet ne nulinė. Šis būdas patikimesnis nei atimti beveik vienodus apvalintų S2 ir P2 kvadratus.",u,numbers(2)); ...
            msprintf("Išmatuota P2 = %.10g mW; iš U2 ir I2 apskaičiuota S2 = %.10g mVA. cos φ2 = P2/S2 = %.10g. Palyginkite su pradiniu rodikliu: jis priartėjo prie 1.",p,s,numbers(3)); ...
            msprintf("Iš pirmo matavimo S1 = U1·I1 = %.10g mVA; iš antro S2 = %.10g mVA. Pilnutinės galios sumažėjimas ΔS = S1−S2 = %.10g mVA. Tai nėra aktyviosios galios P sumažėjimas.",s1,s,numbers(4))];
        for k=1:4
            [lines,tag,value]=ld11_guide_answer(5,k,numbers(k),explanations(k));if tag<>"" then return;end
        end
    case 6 then
        before=ld11_journal_rows(1);after=ld11_journal_rows(2);
        if before==[] | after==[] then tag="LD11_BACK";lines="Išvadoms reikia abiejų matavimų. DABAR spauskite geltoną ← Atgal ir grįžkite į trūkstamą matavimo etapą.";return;end
        p1=before($,4);p2=after($,4);i1=before($,2);i2=after($,2);
        cos1=p1/(before($,1)*i1);cos2=p2/(after($,1)*i2);
        comparisons=[abs(p2-p1)<=max(1e-6,.02*abs(p1)),i2<i1,cos2>cos1];
        explanations=[msprintf("Išmatuota P1 = %.10g mW ir P2 = %.10g mW: aktyvioji galia nepakito. Ta pati ritė tebevartoja tiek pat aktyviosios galios; kondensatorius jos darbo nepakeitė.",p1,p2); ...
            msprintf("Išmatuota I1 = %.10g mA ir I2 = %.10g mA: bendra šaltinio srovė sumažėjo. Kondensatorius dalį reaktyviųjų energijos mainų atlieka vietoje, todėl tinklu nebereikia perduoti tokios didelės srovės.",i1,i2); ...
            msprintf("Iš jūsų U, I ir P: cos φ1 = %.10g, cos φ2 = %.10g. Rodiklis padidėjo ir priartėjo prie 1. Gauname tą patį aktyvųjį darbą su mažesne bendra srove; tai galios faktoriaus gerinimas.",cos1,cos2)];
        for k=1:3
            number=2;if comparisons(k) then number=1;end
            [lines,tag,value]=ld11_guide_answer(6,k,number,explanations(k));if tag<>"" then return;end
        end
    end
    if tag<>"" then return;end
    tag="LD11_PRIMARY";
    if LD11.assessment then lines="Šio etapo veiksmai ir atsakymai paruošti. DABAR spauskite geltoną TOLIAU →.";
    else lines="Šio etapo veiksmai ir atsakymai paruošti. DABAR spauskite geltoną TIKRINTI. Patikrinusi programa pati atvers kitą etapą.";end
endfunction

function lines=ld11_guide_lines()
    global LD11;
    [next,tag,value]=ld11_guide_next();
    lines=[next;"";"KAM ATLIEKAME ŠĮ DARBĄ"; ...
        "Palyginame tą pačią ritę prieš prijungdami kondensatorių (BE Ck) ir po jo prijungimo (SU Ck). Ieškome būdo sumažinti bendrą šaltinio srovę, išlaikant tą pačią aktyviąją galią P."; ...
        "1 etapas: keturi ritės laidai ir pradinis cos φ. 2 etapas: pirmas U, I, P matavimas ir galios. 3 etapas: kompensuojanti talpa. 4 etapas: pridedami du Ck laidai ir atliekamas antras matavimas. 5–6 etapai: skaičiavimai ir išvados iš abiejų matavimų.";"";"TIESIOGIAI UŽFIKSUOTI VIRTUALAUS STENDO RODMENYS"];
    names=["BE Ck";"SU Ck"];
    for k=1:2
        row=ld11_journal_rows(k);
        if row<>[] then lines($+1,1)=msprintf("%s: U = %.10g V; I = %.10g mA; P = %.10g mW.",names(k),row($,1),row($,2),row($,4));
        else lines($+1,1)=names(k)+": dar neišmatuota.";end
    end
    lines=[lines;"";"S, Q ir cos φ yra apskaičiuoti dydžiai. Q2 skaičiavimui naudojama išmatuota U2 ir žinomi komponentai R, L, Ck; tai nėra atskiras Q2 matavimas."; ...
        "Geltona spalva stende rodo vieną dabartinį kontaktą, mygtuką ar lauką. Galite spausti patys arba aiškiai paprašyti pagalbos atlikti parodytą veiksmą."; ...
        "Vien pagalbos atvėrimas matavimų, atsakymų ir režimo nekeičia. Skaičiai ir išvados įrašomi tik jums atskirai paspaudus jų įrašymo mygtuką."; ...
        "Uždarius pagalbą darbas ir įvesti duomenys lieka. Pabaigoje pagrindinis mygtukas išsaugo originalų HTML; pranešime bus jo vieta ir Atverti ataskaitų aplanką."];
endfunction

function ld11_guide_refresh()
    global LD11;
    if typeof(LD11)<>"st" then return; end
    if ~isfield(LD11,"step") | ~isfield(LD11,"cfg") then return; end
    if ~isfield(LD11,"ui") then return; end
    if isfield(LD11.ui,"headless") then if LD11.ui.headless then return; end; end
    if ~isfield(LD11,"fig") then return; end
    if ~is_handle_valid(LD11.fig) then return; end
    enabled=%f; if isfield(LD11,"guide_enabled") then enabled=LD11.guide_enabled; end
    tag=""; value="";
    if enabled then
        [next,tag,value]=ld11_guide_next();
        if isfield(LD11.ui,"instructionLine") then LD11.ui.instructionLine(1).string=student_wrap(next(1),38); end
    else
        if isfield(LD11.ui,"instructionLine") then LD11.ui.instructionLine(1).string=student_wrap(ld11_step_instruction(LD11.step),38); end
    end
    if exists("student_guide_focus")==1 then student_guide_focus("LD11",LD11.fig,tag,enabled); end
    if exists("student_guide_update")==1 then student_guide_update("LD11","Etapas "+string(LD11.step)+" iš 6",ld11_guide_lines(),enabled); end
    if exists("student_guide_action_refresh")==1 then student_guide_action_refresh("LD11",LD11.fig,tag,value,enabled); end
endfunction
