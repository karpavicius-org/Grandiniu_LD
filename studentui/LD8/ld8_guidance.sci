// Opt-in, state-aware guide. Reading this file never performs an experiment.
function ld8_guide_show()
    global LD8;
    if typeof(LD8)<>"st" then return; end
    LD8.guide_enabled=%t; ld8_guide_refresh();
endfunction

function ld8_guide_close()
    global LD8;
    if typeof(LD8)<>"st" then return; end
    LD8.guide_enabled=%f;
    if exists("student_guide_hide")==1 then student_guide_hide("LD8"); end
    ld8_guide_refresh();
endfunction

function text=ld8_guide_contact(id)
    text="["+ld8_terminal_code(id)+"] "+ld8_terminal_name(id);
endfunction

function present=ld8_guide_has_wire(wires,pair)
    present=%f;
    for k=1:size(wires,1)
        if and(wires(k,:)==pair) | and(wires(k,:)==pair([2 1])) then present=%t; return; end
    end
endfunction

function [lines,tag]=ld8_guide_wire_target(mode)
    global LD8;
    lines=emptystr(0,1); tag="";
    if LD8.wireMode<>mode then
        tag=msprintf("B%02d",9+mode);
        lines="DABAR spauskite geltoną „"+ld8_mode_name(mode)+"“. Šio sujungimo laidai saugomi atskirai."; return;
    end
    canon=ld8_canonical_wires(mode); bad=emptystr(0,2); missing=emptystr(0,2);
    for k=1:size(LD8.wires,1)
        duplicate=%f;
        for j=1:k-1
            if and(LD8.wires(k,:)==LD8.wires(j,:)) | and(LD8.wires(k,:)==LD8.wires(j,[2 1])) then duplicate=%t; end
        end
        if ~ld8_guide_has_wire(canon,LD8.wires(k,:)) | duplicate then bad($+1,:)=LD8.wires(k,:); end
    end
    for k=1:size(canon,1)
        if ~ld8_guide_has_wire(LD8.wires,canon(k,:)) then missing($+1,:)=canon(k,:); end
    end
    if size(bad,1)==0 & size(missing,1)==0 & LD8.pending=="" then return; end
    if LD8.powerOn then
        tag="B01"; lines="DABAR spauskite geltoną Maitinimas, kad šaltinis išsijungtų. Tada vedlys parodys taisomą kontaktą."; return;
    end
    if ~ld8_wiring_editable() then
        tag="LD8_BACK"; lines="DABAR spauskite geltoną ← Atgal. Laidus taisykite šio sujungimo matavimo etape."; return;
    end
    if LD8.pending<>"" then
        target="";
        if size(bad,1)>0 then
            pair=bad(1,:);
            if LD8.pending==pair(1) then target=pair(2); elseif LD8.pending==pair(2) then target=pair(1); end
            action="pašalinsite netinkamą laidą";
        else
            for k=1:size(missing,1)
                if LD8.pending==missing(k,1) then target=missing(k,2); break; end
                if LD8.pending==missing(k,2) then target=missing(k,1); break; end
            end
            action="užbaigsite pradėtą laidą";
        end
        if target=="" then
            tag=ld8_terminal_code(LD8.pending);
            lines="DABAR dar kartą spauskite geltoną "+ld8_guide_contact(LD8.pending)+" – atšauksite nereikalingą pasirinkimą.";
        else
            tag=ld8_terminal_code(target);
            lines="DABAR spauskite geltoną "+ld8_guide_contact(target)+" – "+action+". Pirmas galas jau pasirinktas.";
        end
        return;
    end
    if size(bad,1)>0 then
        pair=bad(1,:); tag=ld8_terminal_code(pair(1));
        lines="DABAR spauskite geltoną "+ld8_guide_contact(pair(1))+". Tada vedlys pažymės antrą netinkamo laido galą, kad laidą pašalintumėte."; return;
    end
    pair=missing(1,:); tag=ld8_terminal_code(pair(1));
    lines="DABAR spauskite geltoną "+ld8_guide_contact(pair(1))+". Tada geltonai užsidegs "+ld8_guide_contact(pair(2))+" – antras šio laido galas.";
endfunction

function [lines,tag,value]=ld8_guide_answer(step,slot,number,explanation)
    global LD8;
    tag=""; value=""; lines=emptystr(0,1);
    raw=LD8.answers(step,slot); entered=ld8_parse_number(raw);
    relative=.02; absolute=1e-9;
    if or(step==[2 3 4]) then relative=.01; end
    if step==6 then relative=0; absolute=0; end
    // Choice callbacks/check_step store literal codes; a restored "1.0"
    // must be repaired even though it parses as the number 1.
    if step==6 then needed=stripblanks(raw)<>string(number);
    elseif stripblanks(raw)=="" | isnan(entered) | isinf(entered) then needed=%t;
    else needed=abs(entered-number)>absolute+relative*abs(number); end
    if ~needed then return; end
    tag=ld8_answer_code(step,slot); value=msprintf("%.10g",number);
    lines=["DABAR į geltoną lauką ["+tag+"] įrašykite "+value+". Vieneto ir formulės į lauką nerašykite.";explanation];
    if step==6 then
        choice="Ne"; if number==1 then choice="Taip"; end
        lines=["DABAR geltoname sąraše ["+tag+"] pasirinkite „"+choice+"“.";explanation];
    end
endfunction

function [lines,tag,value]=ld8_guide_next()
    global LD8;
    lines=emptystr(0,1); tag=""; value="";
    if typeof(LD8)<>"st" then return; end
    if ~isfield(LD8,"step") | ~isfield(LD8,"cfg") then return; end
    st=LD8.step; c=LD8.cfg;
    if ~ld8_valid_index(st,6) then return; end
    if LD8.demoMode then
        tag="LD8_PRIMARY"; lines="DABAR spauskite geltoną GRĮŽTI Į SAVO DARBĄ. Toliau dirbsime su jūsų matavimais."; return;
    end
    if LD8.done(st) then
        tag="LD8_PRIMARY";
        if st==6 & and(LD8.done) then lines="Darbas užbaigtas. DABAR spauskite geltoną ĮRAŠYTI ATASKAITĄ ir pateikite sukurtą HTML dėstytojui.";
        elseif st==6 then lines="DABAR spauskite geltoną UŽBAIGTI PRALEISTĄ ETAPĄ. Programa grąžins ten, kur dar trūksta darbo.";
        else lines="Etapas jau įrašytas. DABAR spauskite geltoną TOLIAU →."; end
        return;
    end
    if or(st==[1 3 4]) then
        mode=ld8_stage_mode(st); [lines,tag]=ld8_guide_wire_target(mode);
        if tag<>"" then return; end
        if ld8_journal_rows(mode)==[] then
            if ~LD8.powerOn then tag="B01"; lines="Visi laidai sujungti. DABAR spauskite geltoną Maitinimas, kad įjungtumėte šaltinį."; return; end
            if ~LD8.switchOn then tag="B02"; lines="DABAR spauskite geltoną Jungiklis. Uždaryta grandine galės tekėti srovė."; return; end
            tag="B03"; lines="DABAR spauskite geltoną Matuoti. Tikro virtualaus modelio U ir I rodmenys automatiškai išliks žurnale; jų perrašyti nereikia."; return;
        end
    end
    select st
    case 2 then
        number=c.R1+c.R2+c.R3;
        [lines,tag,value]=ld8_guide_answer(2,1,number,msprintf("Nuosekliai varžos susideda: Rt = %g + %g + %g = %.10g Ω. Ta pati srovė eina per visus tris rezistorius.",c.R1,c.R2,c.R3,number));
    case 3 then
        number=1/(1/c.R1+1/c.R2+1/c.R3);
        [lines,tag,value]=ld8_guide_answer(3,1,number,msprintf("Lygiagrečiai yra trys srovės keliai: Rt = 1/(1/%g + 1/%g + 1/%g) = %.10g Ω. Dėl papildomų kelių bendra varža sumažėja.",c.R1,c.R2,c.R3,number));
    case 4 then
        number=c.R1+c.R2*c.R3/(c.R2+c.R3);
        [lines,tag,value]=ld8_guide_answer(4,1,number,msprintf("R2 ir R3 lygiagrečiai, o R1 prieš jų šakas: Rt = %g + %g·%g/(%g+%g) = %.10g Ω.",c.R1,c.R2,c.R3,c.R2,c.R3,number));
    case 5 then
        row=ld8_journal_rows(2);
        if row==[] then tag="LD8_BACK"; lines="Trūksta lygiagrečios grandinės matavimo. DABAR spauskite geltoną ← Atgal; grįžkite į 3 etapą ir išmatuokite."; return; end
        u=row($,1);
        for k=1:3
            r=c("R"+string(k)); number=1000*u/r;
            [lines,tag,value]=ld8_guide_answer(5,k,number,msprintf("Žurnale išmatuota U = %.10g V. Šakos srovė I%d = 1000·U/R%d = 1000·%.10g/%g = %.10g mA. 1000 paverčia A į mA.",u,k,k,u,r,number));
            if tag<>"" then return; end
        end
    case 6 then
        r=zeros(1,3);
        for k=1:3
            row=ld8_journal_rows(k);
            if row==[] then tag="LD8_BACK"; lines="Trūksta vieno iš trijų sujungimų matavimo. DABAR spauskite geltoną ← Atgal ir grįžkite į to sujungimo matavimo etapą."; return; end
            r(k)=1000*row($,1)/row($,2);
        end
        comparisons=[r(1)>r(2)&r(1)>r(3),r(2)<r(1)&r(2)<r(3),%f];
        row=ld8_journal_rows(2); u=row($,1); total=row($,2); branch=1000*u*[1/c.R1 1/c.R2 1/c.R3];
        comparisons(3)=abs(sum(branch)-total)<=max(1e-8,abs(total)*.02);
        explanations=[msprintf("Iš jūsų matavimų: Rt nuosekliai %.6g Ω, lygiagrečiai %.6g Ω, mišriai %.6g Ω. Nuoseklioji varža didžiausia: srovei reikia įveikti visus tris rezistorius paeiliui.",r(1),r(2),r(3)); ...
            msprintf("Lygiagrečioji Rt = %.6g Ω yra mažiausia: srovė pasidalija į tris kelius. Tuo pačiu šaltiniu gaunama didžiausia bendra srovė.",r(2)); ...
            msprintf("Šakų srovės %.6g + %.6g + %.6g = %.6g mA; žurnalo bendra srovė %.6g mA. Į mazgą įtekanti srovė lygi ištekančių šakų srovių sumai.",branch(1),branch(2),branch(3),sum(branch),total)];
        for k=1:3
            number=2; if comparisons(k) then number=1; end
            [lines,tag,value]=ld8_guide_answer(6,k,number,explanations(k));
            if tag<>"" then return; end
        end
    end
    if tag<>"" then return; end
    tag="LD8_PRIMARY";
    if LD8.assessment then lines="Šio etapo matavimas ir atsakymai paruošti. DABAR spauskite geltoną ĮRAŠYTI IR TOLIAU →.";
    else lines="Šio etapo veiksmai paruošti. DABAR spauskite geltoną TIKRINTI. Jei viskas teisinga, programa pati atvers kitą etapą."; end
endfunction

function lines=ld8_guide_lines()
    global LD8;
    [next,tag,value]=ld8_guide_next();
    lines=[next;"";"KAM ATLIEKAME ŠĮ DARBĄ"; ...
        "Tie patys trys rezistoriai jungiami trimis būdais. Šaltinio įtampa ta pati; keičiasi srovės keliai, todėl keičiasi bendra varža ir srovė."; ...
        "1–2 etapai: nuosekliai – vienas kelias, varžos susideda. 3 etapas: lygiagrečiai – trys keliai, bendra varža sumažėja. 4 etapas: mišriai – vienas rezistorius ir dvi šakos."; ...
        "5 etape palyginame šakų ir bendrą sroves. 6 etape iš savo trijų matavimų gauname išvadas.";"";"JŪSŲ UŽFIKSUOTI MATAVIMAI"];
    names=["Nuosekliai";"Lygiagrečiai";"Mišriai"];
    for k=1:3
        row=ld8_journal_rows(k);
        if row<>[] then
            lines($+1,1)=msprintf("%s: U = %.10g V; I = %.10g mA; Rt = 1000·U/I = %.10g Ω.",names(k),row($,1),row($,2),1000*row($,1)/row($,2));
        else lines($+1,1)=names(k)+": dar neišmatuota."; end
    end
    lines=[lines;"";"Geltona spalva stende rodo vieną veiksmą, kurį atlikti dabar. Paspaudus ji persikelia į kitą kontaktą, mygtuką ar lauką."; ...
        "Galite veikti patys arba aiškiai paprašyti vedlio atlikti parodytą veiksmą. Vien pagalbos atvėrimas matavimų, atsakymų ir režimo nekeičia."; ...
        "Skaitinis atsakymas rodomas kartu su formule ir jūsų duomenimis. Į lauką rašomas tik skaičius; vienetas pateiktas lauko pavadinime."; ...
        "Paskutinis pagrindinis mygtukas įrašo HTML ataskaitą. Patvirtinimo lange rasite jos kelią ir Atverti ataskaitų aplanką."];
endfunction

function ld8_guide_refresh()
    global LD8;
    if typeof(LD8)<>"st" then return; end
    if ~isfield(LD8,"step") | ~isfield(LD8,"cfg") then return; end
    if ~isfield(LD8,"ui") then return; end
    if isfield(LD8.ui,"headless") then if LD8.ui.headless then return; end; end
    if ~isfield(LD8,"fig") then return; end
    if ~is_handle_valid(LD8.fig) then return; end
    enabled=%f; if isfield(LD8,"guide_enabled") then enabled=LD8.guide_enabled; end
    tag=""; value="";
    if enabled then
        [next,tag,value]=ld8_guide_next();
        if isfield(LD8.ui,"instructionLine") then LD8.ui.instructionLine(1).string=student_wrap(next(1),38); end
    else
        if isfield(LD8.ui,"instructionLine") then LD8.ui.instructionLine(1).string=student_wrap(ld8_step_instruction(LD8.step),38); end
    end
    if exists("student_guide_focus")==1 then student_guide_focus("LD8",LD8.fig,tag,enabled); end
    if exists("student_guide_update")==1 then student_guide_update("LD8","Etapas "+string(LD8.step)+" iš 6",ld8_guide_lines(),enabled); end
    if exists("student_guide_action_refresh")==1 then student_guide_action_refresh("LD8",LD8.fig,tag,value,enabled); end
endfunction
