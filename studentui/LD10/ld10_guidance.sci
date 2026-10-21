// Opt-in guide: computes visible hints only. Actions remain explicit student clicks.
function ld10_guide_show()
    global LD10;
    if typeof(LD10)<>"st" then return; end
    LD10.guide_enabled=%t; ld10_guide_refresh();
endfunction

function ld10_guide_close()
    global LD10;
    if typeof(LD10)=="st" then LD10.guide_enabled=%f; end
    student_guide_hide("LD10"); ld10_guide_refresh();
endfunction

function yes=ld10_guide_has_wire(wires,pair)
    yes=%f;
    for j=1:size(wires,1)
        if and(wires(j,:)==pair) | and(wires(j,:)==pair([2 1])) then yes=%t; return; end
    end
endfunction

function text=ld10_guide_terminal(id)
    text="["+ld10_terminal_code(id)+"] "+ld10_terminal_name(id);
endfunction

function [lines,tag]=ld10_guide_wire_next(canon)
    global LD10;
    tag="";lines=emptystr(0,1);
    missing=emptystr(0,2);extra=emptystr(0,2);
    for k=1:size(canon,1)
        if ~ld10_guide_has_wire(LD10.wires,canon(k,:)) then missing($+1,:)=canon(k,:); end
    end
    for j=1:size(LD10.wires,1)
        duplicate=%f;
        for k=1:j-1
            if and(LD10.wires(j,:)==LD10.wires(k,:)) | and(LD10.wires(j,:)==LD10.wires(k,[2 1])) then duplicate=%t;end
        end
        if ~ld10_guide_has_wire(canon,LD10.wires(j,:)) | duplicate then extra($+1,:)=LD10.wires(j,:);end
    end
    if size(missing,1)==0 & size(extra,1)==0 & LD10.pending=="" then return;end
    if LD10.powerOn then tag="B01";lines="DABAR spauskite geltoną Maitinimas: prieš taisydami laidus išjunkite šaltinį.";return;end
    pair=emptystr(0,2);remove=%f;
    if size(extra,1)>0 then pair=extra(1,:);remove=%t;
    elseif size(missing,1)>0 then pair=missing(1,:);end
    id="";
    if LD10.pending<>"" then
        if ~remove then
            for k=1:size(missing,1)
                if or(missing(k,:)==LD10.pending) then pair=missing(k,:);break;end
            end
        end
        if size(pair,"*")==2 & or(pair==LD10.pending) then
            id=pair(1);if id==LD10.pending then id=pair(2);end
        else
            id=LD10.pending;tag=ld10_terminal_code(id);
            lines="DABAR dar kartą spauskite geltoną "+ld10_guide_terminal(id)+". Tai atšauks netinkamą pirmą pasirinkimą.";return;
        end
    elseif size(pair,"*")==2 then id=pair(1);end
    if id=="" then return;end
    tag=ld10_terminal_code(id);
    if remove then
        lines=["DABAR spauskite geltoną "+ld10_guide_terminal(id)+".";"Pašaliname netinkamą laidą. Vedlys po paspaudimo pažymės jo antrą galą."];
    elseif LD10.pending<>"" then
        lines=["DABAR spauskite geltoną "+ld10_guide_terminal(id)+".";"Taip užbaigsite pasirinktą laidą. Kitas gnybtas bus pažymėtas automatiškai."];
    else
        lines=["DABAR spauskite geltoną "+ld10_guide_terminal(id)+".";"Pradedame kitą reikalingą laidą. Paskui vedlys pažymės antrą galą."];
    end
endfunction

function yes=ld10_guide_answer_ready(step,slot,wanted)
    global LD10;
    value=ld10_parse_number(LD10.answers(step,slot));
    yes=~isnan(value) & ~isinf(value);
    relative=.02;absolute=1e-9;
    if step==1 then relative=.01;end
    if step==3 & slot==1 then relative=.03;end
    if step==3 & slot==2 then relative=0;absolute=.02;end
    if step==6 then relative=0;absolute=0;end
    if yes then yes=abs(value-wanted)<=absolute+relative*abs(wanted);end
endfunction

function [lines,tag,value]=ld10_guide_number(step,slot,wanted,explanation)
    value=msprintf("%.10g",wanted);tag=ld10_answer_code(step,slot);
    lines=["DABAR į geltoną lauką ["+tag+"] įrašykite "+value+" (tik skaičių).";explanation];
endfunction

function lines=ld10_guide_finish()
    global LD10;
    if LD10.demoMode then lines="DABAR spauskite geltoną GRĮŽTI Į SAVO DARBĄ.";
    elseif LD10.step==6 & and(LD10.done) then lines="DABAR spauskite geltoną IŠSAUGOTI ATASKAITĄ. HTML failą programa išsaugos pati.";
    elseif LD10.step==6 & LD10.done(6) then lines="DABAR spauskite geltoną UŽBAIGTI PRALEISTĄ ETAPĄ. Programa grąžins į trūkstamą etapą.";
    elseif LD10.done(LD10.step) then lines="DABAR spauskite geltoną TOLIAU →. Šis etapas jau įrašytas.";
    elseif LD10.assessment then lines="DABAR spauskite geltoną TOLIAU →. Taip patvirtinsite šio etapo duomenis.";
    else lines="DABAR spauskite geltoną TIKRINTI. Jei etapas teisingas, programa iškart tęs darbą.";end
endfunction

function ld10_guide_refresh()
    global LD10;
    if typeof(LD10)<>"st" then return;end
    if ~isfield(LD10,"step") | ~isfield(LD10,"ui") then return;end
    if isfield(LD10.ui,"headless") then if LD10.ui.headless then return;end;end
    if ~isfield(LD10,"fig") then return;end
    if ~is_handle_valid(LD10.fig) then return;end
    enabled=%f;if isfield(LD10,"guide_enabled") then enabled=LD10.guide_enabled;end
    tag="";value="";
    if enabled then
        [lines,tag,value]=ld10_guide_next();
        if isfield(LD10.ui,"instructionLine") then LD10.ui.instructionLine(1).string=student_wrap(lines(1),38);end
        details=[lines;"";"KAM ATLIEKAME ŠĮ BANDYMĄ";ld10_guide_purpose();""; ...
            "Geltonai pažymėtas vienas kitas veiksmas tikrame stende. Galite jį atlikti pele arba pagalbos lange paspausti pasiūlytą veiksmą."; ...
            "Vien atvėrus pagalbą laidai, matavimai, atsakymai ir darbo režimas nepasikeičia."; ...
            "Skaičių laukuose rašykite tik skaičių; tinka kablelis arba taškas. Matavimai žurnale įrašomi automatiškai."; ...
            "Baigę išsaugokite originalų HTML. Patvirtinimo lange Atverti ataskaitą parodo turinį, Atverti ataskaitų aplanką – failo vietą."];
        student_guide_update("LD10","Etapas "+string(LD10.step)+" iš 6",details,%t);
    else
        student_guide_hide("LD10");
        if isfield(LD10.ui,"instructionLine") then LD10.ui.instructionLine(1).string=student_wrap(ld10_step_instruction(LD10.step),38);end
    end
    student_guide_focus("LD10",LD10.fig,tag,enabled);
    student_guide_action_refresh("LD10",LD10.fig,tag,value,enabled);
endfunction

function lines=ld10_guide_purpose()
    global LD10;
    select LD10.step
    case 1 then lines="R, L ir C yra trys lygiagrečios šakos tarp tų pačių dviejų mazgų. Visose šakose ta pati įtampa. Apskaičiuotas f0 bus vidurinis iš trijų dažnio bandymų: 0,5·f0 → f0 → 2·f0.";
    case 2 then lines="Pirmas bandymas 0,5·f0 yra žemiau rezonanso. Paeiliui išmatuojame R, L, C šakų sroves ir bendrąją šaltinio srovę. Schemos ampermetras visada rodo bendrąją I; pasirinkta šakos srovė rodoma laukelyje MATAVIMAI ir žurnale. Laidų tarp matavimų keisti nereikia.";
    case 3 then lines="Antras bandymas f0 yra srovių rezonansas. Ritės ir kondensatoriaus srovės kompensuojasi; bendroji šaltinio srovė tampa mažiausia ir lygi R šakos srovei. Kokybė Q=IL/I parodo, kiek kartų ritės srovė didesnė už šaltinio srovę; tai santykis be vieneto.";
    case 4 then lines="Trečias bandymas 2·f0 yra aukščiau rezonanso. Grandinės ir įtampos nekeičiame: keičiasi tik dažnis. Palyginsime, kada vyrauja ritės srovė IL, kada kondensatoriaus IC ir kada šaltinio srovė I mažiausia.";
    case 5 then lines="Naudojame pirmojo dažnio 0,5·f0 žurnalą. Srovės turi skirtingas fazes, todėl jų modulių negalima sudėti IR+IL+IC. Bendrąją srovę gauname iš srovių trikampio: sqrt(IR²+(IL−IC)²). Kokybė Q be vieneto ir reaktyvioji galia mvar yra skirtingi dydžiai.";
    case 6 then
        lines="Išvados remiasi jūsų trijų dažnių srovėmis. Esant rezonansui svarbus ne didžiausias, o mažiausias šaltinio srovės rodmuo.";
        names=["0,5·f0";"f0";"2·f0"];
        for k=1:3
            r=ld10_journal_rows(k,1);l=ld10_journal_rows(k,2);c=ld10_journal_rows(k,3);i=ld10_journal_rows(k,4);
            if r<>[] & l<>[] & c<>[] & i<>[] then lines($+1)=msprintf("%s: IR=%.7g mA; IL=%.7g mA; IC=%.7g mA; I=%.7g mA.",names(k),r($,2),l($,2),c($,2),i($,2));end
        end
    end
endfunction

function [lines,tag,value]=ld10_guide_next()
    global LD10;
    lines=emptystr(0,1);tag="LD10_PRIMARY";value="";st=LD10.step;
    if LD10.demoMode | LD10.done(st) then lines=ld10_guide_finish();return;end
    if st==1 then
        [lines,wire]=ld10_guide_wire_next(ld10_canonical_wires());if wire<>"" then tag=wire;return;end
        f0=1/(2*%pi*sqrt(LD10.cfg.L*LD10.cfg.C));
        if ~ld10_guide_answer_ready(1,1,f0) then
            [lines,tag,value]=ld10_guide_number(1,1,f0,msprintf("f0 = 1/(2·π·sqrt(L·C)), kai L=%g mH/1000=%g H ir C=%g nF/1000000000=%g F. Rezultatas Hz; šis dažnis bus vidurinis bandymas.",LD10.cfg.LmH,LD10.cfg.L,LD10.cfg.CnF,LD10.cfg.C));return;
        end
        lines=ld10_guide_finish();return;
    end
    if or(st==[2 3 4]) then
        [ready,why]=ld10_wiring_valid(LD10.wires);
        if ~ready then tag="LD10_BACK";lines="DABAR spauskite geltoną ← Atgal iki 1 etapo. Ten vedlys padės pataisyti grandinės laidus.";return;end
        point=st-1;missing=0;
        for j=1:4;if ld10_journal_rows(point,j)==[] then missing=j;break;end;end
        if missing<>0 then
            names=["0,5·f0";"f0";"2·f0"];
            if LD10.freqPoint<>point then
                tag=msprintf("B%02d",point+9);frequency=ld10_stage_freq(st)/(2*%pi*sqrt(LD10.cfg.L*LD10.cfg.C));
                lines=msprintf("DABAR spauskite geltoną %s. Šio bandymo dažnis yra %.8g Hz; grandinės laidų keisti nereikia.",names(point),frequency);return;
            end
            if ~LD10.powerOn then tag="B01";lines="DABAR spauskite geltoną Maitinimas: įjunkite generatorių.";return;end
            if ~LD10.switchOn then tag="B02";lines="DABAR spauskite geltoną Jungiklis: uždarykite grandinę.";return;end
            names=["IR · R";"IL · L";"IC · C";"I · BENDRA"];
            if LD10.target<>missing then
                tag=msprintf("B%02d",missing+12);lines=["DABAR spauskite geltoną "+names(missing)+". Pasirenkame būtent šią srovę.";"Pasirinktos šakos rodmuo rodomas laukelyje MATAVIMAI; schemos ampermetras toliau rodo bendrąją šaltinio srovę I."];return;
            end
            tag="B03";lines="DABAR spauskite geltoną Matuoti. "+names(missing)+" srovė ir bendroji įtampa automatiškai pateks į žurnalą.";return;
        end
        if st==3 then
            l=ld10_journal_rows(2,2);c=ld10_journal_rows(2,3);i=ld10_journal_rows(2,4);
            if i($,2)==0 then tag="LD10_BACK";lines="DABAR grįžkite geltonu ← Atgal ir patikrinkite matavimus: iš nulinės bendrosios srovės kokybės Q apskaičiuoti negalima.";return;end
            vals=[l($,2)/i($,2) l($,2)-c($,2)];
            why=[msprintf("Kokybė Q = IL/I = %.8g/%.8g. Dalijame mA iš mA, todėl vieneto nėra. Tai srovių santykis, ne reaktyvioji galia.",l($,2),i($,2)); ...
                msprintf("IL−IC = %.8g−%.8g, mA. Rezonanse skirtumas artimas nuliui: priešingų fazių L ir C šakų srovės kompensuojasi.",l($,2),c($,2))];
            for j=1:2
                if ~ld10_guide_answer_ready(3,j,vals(j)) then [lines,tag,value]=ld10_guide_number(3,j,vals(j),why(j));return;end
            end
        end
        lines=["Visos keturios šio dažnio srovės ir bendroji įtampa išsaugotos žurnale.";ld10_guide_finish()];return;
    end
    if st==5 then
        r=ld10_journal_rows(1,1);l=ld10_journal_rows(1,2);c=ld10_journal_rows(1,3);i=ld10_journal_rows(1,4);
        if r==[] | l==[] | c==[] | i==[] then tag="LD10_BACK";lines="DABAR spauskite geltoną ← Atgal iki 2 etapo ir išmatuokite trūkstamas 0,5·f0 sroves. Skaičiuojame tik iš jūsų užfiksuotų rodmenų.";return;end
        ir=r($,2);il=l($,2);ic=c($,2);ii=i($,2);uu=i($,1);
        if uu==0 | ii==0 then tag="LD10_BACK";lines="DABAR grįžkite į matavimus geltonu ← Atgal ir patikrinkite įtampą bei bendrąją srovę. Iš nulinio rodmens šių santykių apskaičiuoti negalima.";return;end
        vals=[sqrt(ir^2+(il-ic)^2) ii/uu ir/ii uu*ir uu*(il-ic) uu*ii];
        why=[msprintf("Itr = sqrt(IR²+(IL−IC)²) = sqrt(%.8g²+(%.8g−%.8g)²), mA. Šakų srovių moduliai nesudedami aritmetiškai, nes jų fazės skiriasi.",ir,il,ic); ...
            msprintf("Y = I/U = %.8g/%.8g, mS. mA/V jau duoda mS; papildomo ×1000 arba /1000 nereikia.",ii,uu); ...
            msprintf("cos φ = IR/I = %.8g/%.8g, be vieneto. Dalijame R šakos srovę iš bendrosios šaltinio srovės.",ir,ii); ...
            msprintf("P = U·IR = %.8g·%.8g, mW. V·mA duoda mW; aktyvioji galia tenka rezistoriui R.",uu,ir); ...
            msprintf("Reaktyvioji galia = U·(IL−IC) = %.8g·(%.8g−%.8g), mvar. Žemiau f0 vyrauja ritė, todėl ženklas teigiamas. Šios galios nepainiokite su kokybe Q be vieneto.",uu,il,ic); ...
            msprintf("S = U·I = %.8g·%.8g, mVA. Naudojama bendroji srovė I, ne atskiros šakos rodmuo.",uu,ii)];
        for j=1:6
            if ~ld10_guide_answer_ready(5,j,vals(j)) then [lines,tag,value]=ld10_guide_number(5,j,vals(j),why(j));return;end
        end
        lines=ld10_guide_finish();return;
    end
    if st==6 then
        currents=zeros(1,3);inductors=zeros(1,3);capacitors=zeros(1,3);
        for k=1:3
            i=ld10_journal_rows(k,4);l=ld10_journal_rows(k,2);c=ld10_journal_rows(k,3);
            if i==[] | l==[] | c==[] then tag="LD10_BACK";lines="DABAR spauskite geltoną ← Atgal ir užbaikite trijų dažnių matavimus. Išvadas pagrindžiame žurnalu.";return;end
            currents(k)=i($,2);inductors(k)=l($,2);capacitors(k)=c($,2);
        end
        minimum=currents(2)<=min(currents([1 3]))+1e-9;
        equal=abs(inductors(2)-capacitors(2))<=max(.02,.02*abs(inductors(2)));
        kinds=inductors(1)>capacitors(1) & capacitors(3)>inductors(3);
        conclusions=[minimum equal kinds];vals=2*ones(1,3);vals(find(conclusions))=1;
        why=[msprintf("Jūsų šaltinio srovės: I(0,5·f0)=%.7g mA, I(f0)=%.7g mA, I(2·f0)=%.7g mA. Ties f0 ji mažiausia: L ir C šakų srovės kompensuojasi.",currents(1),currents(2),currents(3)); ...
            msprintf("Ties f0 užfiksuota IL=%.7g mA ir IC=%.7g mA. Lygios priešingų fazių srovės kompensuojasi šaltinio linijoje, nors pačiose šakose jos teka.",inductors(2),capacitors(2)); ...
            msprintf("Žemiau f0: IL=%.7g mA > IC=%.7g mA, vyrauja ritė (indukcinis pobūdis). Aukščiau f0: IC=%.7g mA > IL=%.7g mA, vyrauja kondensatorius (talpinis pobūdis).",inductors(1),capacitors(1),capacitors(3),inductors(3))];
        for j=1:3
            if LD10.answers(6,j)<>string(vals(j)) then
                tag=ld10_answer_code(6,j);value=string(vals(j));choice="Ne";if vals(j)==1 then choice="Taip";end
                lines=["DABAR geltoname sąraše ["+tag+"] pasirinkite "+choice+".";why(j)];return;
            end
        end
        lines=ld10_guide_finish();return;
    end
endfunction
