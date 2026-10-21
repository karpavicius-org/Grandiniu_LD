// Opt-in guide: computes visible hints only. Actions remain explicit student clicks.
function ld9_guide_show()
    global LD9;
    if typeof(LD9)<>"st" then return; end
    LD9.guide_enabled=%t; ld9_guide_refresh();
endfunction

function ld9_guide_close()
    global LD9;
    if typeof(LD9)=="st" then LD9.guide_enabled=%f; end
    student_guide_hide("LD9"); ld9_guide_refresh();
endfunction

function yes=ld9_guide_has_wire(wires,pair)
    yes=%f;
    for j=1:size(wires,1)
        if and(wires(j,:)==pair) | and(wires(j,:)==pair([2 1])) then yes=%t; return; end
    end
endfunction

function text=ld9_guide_terminal(id)
    text="["+ld9_terminal_code(id)+"] "+ld9_terminal_name(id);
endfunction

function [lines,tag]=ld9_guide_wire_next(canon)
    global LD9;
    tag="";lines=emptystr(0,1);
    missing=emptystr(0,2);extra=emptystr(0,2);
    for k=1:size(canon,1)
        if ~ld9_guide_has_wire(LD9.wires,canon(k,:)) then missing($+1,:)=canon(k,:); end
    end
    for j=1:size(LD9.wires,1)
        duplicate=%f;
        for k=1:j-1
            if and(LD9.wires(j,:)==LD9.wires(k,:)) | and(LD9.wires(j,:)==LD9.wires(k,[2 1])) then duplicate=%t;end
        end
        if ~ld9_guide_has_wire(canon,LD9.wires(j,:)) | duplicate then extra($+1,:)=LD9.wires(j,:);end
    end
    if size(missing,1)==0 & size(extra,1)==0 & LD9.pending=="" then return;end
    if LD9.powerOn then tag="B01";lines="DABAR spauskite geltoną Maitinimas: prieš taisydami laidus išjunkite šaltinį.";return;end
    pair=emptystr(0,2);remove=%f;
    if size(extra,1)>0 then pair=extra(1,:);remove=%t;
    elseif size(missing,1)>0 then pair=missing(1,:);end
    id="";
    if LD9.pending<>"" then
        if ~remove then
            for k=1:size(missing,1)
                if or(missing(k,:)==LD9.pending) then pair=missing(k,:);break;end
            end
        end
        if size(pair,"*")==2 & or(pair==LD9.pending) then
            id=pair(1);if id==LD9.pending then id=pair(2);end
        else
            id=LD9.pending;tag=ld9_terminal_code(id);
            lines="DABAR dar kartą spauskite geltoną "+ld9_guide_terminal(id)+". Tai atšauks netinkamą pirmą pasirinkimą.";return;
        end
    elseif size(pair,"*")==2 then id=pair(1);end
    if id=="" then return;end
    tag=ld9_terminal_code(id);
    if remove then
        lines=["DABAR spauskite geltoną "+ld9_guide_terminal(id)+".";"Pašaliname netinkamą laidą. Vedlys po paspaudimo pažymės jo antrą galą."];
    elseif LD9.pending<>"" then
        lines=["DABAR spauskite geltoną "+ld9_guide_terminal(id)+".";"Taip užbaigsite pasirinktą laidą. Kitas gnybtas bus pažymėtas automatiškai."];
    else
        lines=["DABAR spauskite geltoną "+ld9_guide_terminal(id)+".";"Pradedame kitą reikalingą laidą. Paskui vedlys pažymės antrą galą."];
    end
endfunction

function yes=ld9_guide_answer_ready(step,slot,wanted)
    global LD9;
    value=ld9_parse_number(LD9.answers(step,slot));
    yes=~isnan(value) & ~isinf(value);
    relative=.02;absolute=1e-9;
    if step==1 then relative=.01;end
    if step==3 & slot==1 then relative=.03;end
    if step==3 & slot==2 then relative=0;absolute=.02;end
    if step==6 then relative=0;absolute=0;end
    if yes then yes=abs(value-wanted)<=absolute+relative*abs(wanted);end
endfunction

function [lines,tag,value]=ld9_guide_number(step,slot,wanted,explanation)
    value=msprintf("%.10g",wanted);tag=ld9_answer_code(step,slot);
    lines=["DABAR į geltoną lauką ["+tag+"] įrašykite "+value+" (tik skaičių).";explanation];
endfunction

function lines=ld9_guide_finish()
    global LD9;
    if LD9.demoMode then lines="DABAR spauskite geltoną GRĮŽTI Į SAVO DARBĄ.";
    elseif LD9.step==6 & and(LD9.done) then lines="DABAR spauskite geltoną IŠSAUGOTI ATASKAITĄ. HTML failą programa išsaugos pati.";
    elseif LD9.step==6 & LD9.done(6) then lines="DABAR spauskite geltoną UŽBAIGTI PRALEISTĄ ETAPĄ. Programa grąžins į trūkstamą etapą.";
    elseif LD9.done(LD9.step) then lines="DABAR spauskite geltoną TOLIAU →. Šis etapas jau įrašytas.";
    elseif LD9.assessment then lines="DABAR spauskite geltoną TOLIAU →. Taip patvirtinsite šio etapo duomenis.";
    else lines="DABAR spauskite geltoną TIKRINTI. Jei etapas teisingas, programa iškart tęs darbą.";end
endfunction

function ld9_guide_refresh()
    global LD9;
    if typeof(LD9)<>"st" then return;end
    if ~isfield(LD9,"step") | ~isfield(LD9,"ui") then return;end
    if isfield(LD9.ui,"headless") then if LD9.ui.headless then return;end;end
    if ~isfield(LD9,"fig") then return;end
    if ~is_handle_valid(LD9.fig) then return;end
    enabled=%f;if isfield(LD9,"guide_enabled") then enabled=LD9.guide_enabled;end
    tag="";value="";
    if enabled then
        [lines,tag,value]=ld9_guide_next();
        if isfield(LD9.ui,"instructionLine") then LD9.ui.instructionLine(1).string=student_wrap(lines(1),38);end
        details=[lines;"";"KAM ATLIEKAME ŠĮ BANDYMĄ";ld9_guide_purpose();""; ...
            "Geltonai pažymėtas vienas kitas veiksmas tikrame stende. Galite jį atlikti pele arba pagalbos lange paspausti pasiūlytą veiksmą."; ...
            "Vien atvėrus pagalbą laidai, matavimai, atsakymai ir darbo režimas nepasikeičia."; ...
            "Skaičių laukuose rašykite tik skaičių; tinka kablelis arba taškas. Matavimai žurnale įrašomi automatiškai."; ...
            "Baigę išsaugokite originalų HTML. Patvirtinimo lange Atverti ataskaitą parodo turinį, Atverti ataskaitų aplanką – failo vietą."];
        student_guide_update("LD9","Etapas "+string(LD9.step)+" iš 6",details,%t);
    else
        student_guide_hide("LD9");
        if isfield(LD9.ui,"instructionLine") then LD9.ui.instructionLine(1).string=student_wrap(ld9_step_instruction(LD9.step),38);end
    end
    student_guide_focus("LD9",LD9.fig,tag,enabled);
    student_guide_action_refresh("LD9",LD9.fig,tag,value,enabled);
endfunction

function lines=ld9_guide_purpose()
    global LD9;
    select LD9.step
    case 1 then lines="Ta pati srovė tekės nuosekliai per rezistorių R, ritę L ir kondensatorių C. f0 yra dažnis, ties kuriuo ritės ir kondensatoriaus poveikiai kompensuojasi. Jį naudosime trijų bandymų atskaitai.";
    case 2 then lines="Pirmas bandymas 0,5·f0 yra žemiau rezonanso. Išmatuojame R, L, C ir generatoriaus įtampas, kad paskui palygintume, kaip pasikeičia jų santykis.";
    case 3 then lines="Antras bandymas f0 yra rezonansas. L ir C įtampos turi būti beveik vienodos, o srovė didžiausia iš šių trijų dažnių. Q=UL/U parodo, kiek kartų ritės įtampa didesnė už generatoriaus įtampą.";
    case 4 then lines="Trečias bandymas 2·f0 yra aukščiau rezonanso. Grandinės nekeičiate – keičiate tik dažnį. Tai leidžia įtampų ir srovės pokytį susieti būtent su dažniu.";
    case 5 then lines="Skaičiuojame iš pirmojo bandymo žurnalo. UR ir UL−UC sudaro statmenas įtampų trikampio kraštines; todėl U nėra paprasta trijų rodmenų suma. Galioms naudojama ta pati išmatuota srovė.";
    case 6 then
        lines="Palyginame tuos pačius tris dažnius ir iš jų darome išvadas.";
        names=["0,5·f0";"f0";"2·f0"];
        for k=1:3
            r=ld9_journal_rows(k,1);l=ld9_journal_rows(k,2);c=ld9_journal_rows(k,3);
            if r<>[] & l<>[] & c<>[] then lines($+1)=msprintf("%s: I=%.7g mA; UR=%.7g V; UL=%.7g V; UC=%.7g V.",names(k),r($,2),r($,1),l($,1),c($,1));end
        end
    end
endfunction

function [lines,tag,value]=ld9_guide_next()
    global LD9;
    lines=emptystr(0,1);tag="LD9_PRIMARY";value="";st=LD9.step;
    if LD9.demoMode | LD9.done(st) then lines=ld9_guide_finish();return;end
    if st==1 then
        [lines,wire]=ld9_guide_wire_next(ld9_canonical_wires());if wire<>"" then tag=wire;return;end
        f0=1/(2*%pi*sqrt(LD9.cfg.L*LD9.cfg.C));
        if ~ld9_guide_answer_ready(1,1,f0) then
            [lines,tag,value]=ld9_guide_number(1,1,f0,msprintf("f0 = 1/(2·π·sqrt(L·C)), kai L=%g H ir C=%g F. Rezultatas Hz; šiuo dažniu atliksime vidurinį bandymą.",LD9.cfg.L,LD9.cfg.C));return;
        end
        lines=ld9_guide_finish();return;
    end
    if or(st==[2 3 4]) then
        [ready,why]=ld9_wiring_valid(LD9.wires);
        if ~ready then tag="LD9_BACK";lines="DABAR spauskite geltoną ← Atgal iki 1 etapo. Ten vedlys padės pataisyti grandinės laidus.";return;end
        point=st-1;missing=0;
        for j=1:4;if ld9_journal_rows(point,j)==[] then missing=j;break;end;end
        if missing<>0 then
            names=["0,5·f0";"f0";"2·f0"];
            if LD9.freqPoint<>point then tag=msprintf("B%02d",point+9);lines="DABAR spauskite geltoną "+names(point)+". Pasirenkame šio bandymo dažnį.";return;end
            if ~LD9.powerOn then tag="B01";lines="DABAR spauskite geltoną Maitinimas: įjunkite generatorių.";return;end
            if ~LD9.switchOn then tag="B02";lines="DABAR spauskite geltoną Jungiklis: uždarykite grandinę.";return;end
            names=["UR · R";"UL · L";"UC · C";"U · GEN"];
            if LD9.target<>missing then tag=msprintf("B%02d",missing+12);lines="DABAR spauskite geltoną "+names(missing)+". Voltmetras bus prijungtas prie šio elemento.";return;end
            tag="B03";lines="DABAR spauskite geltoną Matuoti. "+names(missing)+" rodmuo ir srovė automatiškai pateks į žurnalą.";return;
        end
        if st==3 then
            l=ld9_journal_rows(2,2);c=ld9_journal_rows(2,3);u=ld9_journal_rows(2,4);
            vals=[l($,1)/u($,1) l($,1)-c($,1)];
            why=[msprintf("Q = UL/U = %.8g/%.8g. Tai įtampų santykis be vieneto.",l($,1),u($,1)); ...
                msprintf("UL−UC = %.8g−%.8g, V. Ties rezonansu skirtumas artimas nuliui: šių elementų poveikiai kompensuojasi.",l($,1),c($,1))];
            for j=1:2
                if ~ld9_guide_answer_ready(3,j,vals(j)) then [lines,tag,value]=ld9_guide_number(3,j,vals(j),why(j));return;end
            end
        end
        lines=["Visos keturios šio dažnio įtampos ir srovė išsaugotos žurnale.";ld9_guide_finish()];return;
    end
    if st==5 then
        r=ld9_journal_rows(1,1);l=ld9_journal_rows(1,2);c=ld9_journal_rows(1,3);u=ld9_journal_rows(1,4);
        if r==[] | l==[] | c==[] | u==[] then tag="LD9_BACK";lines="DABAR spauskite geltoną ← Atgal iki 2 etapo ir išmatuokite trūkstamas 0,5·f0 įtampas. Skaičiuojame iš šių rodmenų.";return;end
        ur=r($,1);ul=l($,1);uc=c($,1);uu=u($,1);ii=u($,2);
        vals=[sqrt(ur^2+(ul-uc)^2) 1000*uu/ii ur/uu ur*ii (ul-uc)*ii uu*ii];
        why=[msprintf("Utr = sqrt(UR²+(UL−UC)²) = sqrt(%.8g²+(%.8g−%.8g)²), V.",ur,ul,uc); ...
            msprintf("Z = 1000·U/I = 1000·%.8g/%.8g, Ω. 1000 būtinas, nes I pateikta mA.",uu,ii); ...
            msprintf("cos φ = UR/U = %.8g/%.8g, be vieneto.",ur,uu); ...
            msprintf("P = UR·I = %.8g·%.8g, mW.",ur,ii); ...
            msprintf("Reaktyvioji galia = (UL−UC)·I = (%.8g−%.8g)·%.8g, mvar. Neigiamas ženklas čia teisingas: vyrauja kondensatorius.",ul,uc,ii); ...
            msprintf("S = U·I = %.8g·%.8g, mVA.",uu,ii)];
        for j=1:6
            if ~ld9_guide_answer_ready(5,j,vals(j)) then [lines,tag,value]=ld9_guide_number(5,j,vals(j),why(j));return;end
        end
        lines=ld9_guide_finish();return;
    end
    if st==6 then
        a=ld9_journal_rows(1,1);b=ld9_journal_rows(2,1);c=ld9_journal_rows(3,1);l=ld9_journal_rows(2,2);cap=ld9_journal_rows(2,3);
        if a==[] | b==[] | c==[] | l==[] | cap==[] then tag="LD9_BACK";lines="DABAR spauskite geltoną ← Atgal ir užbaikite trijų dažnių matavimus. Išvadas pagrindžiame žurnalu.";return;end
        la=ld9_journal_rows(1,2);ca=ld9_journal_rows(1,3);lc=ld9_journal_rows(3,2);cc=ld9_journal_rows(3,3);u=ld9_journal_rows(2,4);
        if la==[] | ca==[] | lc==[] | cc==[] | u==[] then tag="LD9_BACK";lines="DABAR spauskite geltoną ← Atgal ir užbaikite trūkstamus įtampų matavimus.";return;end
        equal=abs(l($,1)-cap($,1))<=max(.02,.02*abs(l($,1)));
        zero=equal & abs(b($,1)/u($,1)-1)<=.02;
        kinds=la($,1)<ca($,1) & lc($,1)>cc($,1);
        conclusions=[zero equal kinds];vals=2*ones(1,3);vals(find(conclusions))=1;
        why=[msprintf("Ties f0 UL=%.7g V ir UC=%.7g V kompensuojasi; UR/U=%.7g. Reaktyvioji dalis lygi nuliui, todėl fazės poslinkis lygus nuliui.",l($,1),cap($,1),b($,1)/u($,1)); ...
            msprintf("Ties f0 išmatuota UL=%.7g V ir UC=%.7g V. Šios įtampos lygios, nes XL=XC.",l($,1),cap($,1)); ...
            msprintf("Žemiau f0: UL=%.7g V < UC=%.7g V, vyrauja kondensatorius. Aukščiau f0: UL=%.7g V > UC=%.7g V, vyrauja ritė.",la($,1),ca($,1),lc($,1),cc($,1))];
        for j=1:3
            if LD9.answers(6,j)<>string(vals(j)) then
                tag=ld9_answer_code(6,j);value=string(vals(j));choice="Ne";if vals(j)==1 then choice="Taip";end
                lines=["DABAR geltoname sąraše ["+tag+"] pasirinkite "+choice+".";why(j)];return;
            end
        end
        lines=ld9_guide_finish();return;
    end
endfunction
