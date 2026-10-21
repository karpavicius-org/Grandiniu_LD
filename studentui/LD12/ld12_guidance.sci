// Opt-in guide: computes visible hints only. Actions remain explicit student clicks.
function ld12_guide_show()
    global LD12;
    if typeof(LD12)<>"st" then return; end
    LD12.guide_enabled=%t; ld12_guide_refresh();
endfunction

function ld12_guide_close()
    global LD12;
    if typeof(LD12)=="st" then LD12.guide_enabled=%f; end
    student_guide_hide("LD12"); ld12_guide_refresh();
endfunction

function yes=ld12_guide_has_wire(wires,pair)
    yes=%f;
    for j=1:size(wires,1)
        if and(wires(j,:)==pair) | and(wires(j,:)==pair([2 1])) then yes=%t; return; end
    end
endfunction

function text=ld12_guide_terminal(id)
    text="["+ld12_terminal_code(id)+"] "+ld12_terminal_name(id);
endfunction

function [lines,tag]=ld12_guide_wire_next(canon)
    global LD12;
    tag="";lines=emptystr(0,1);
    missing=emptystr(0,2);extra=emptystr(0,2);
    for k=1:size(canon,1)
        if ~ld12_guide_has_wire(LD12.wires,canon(k,:)) then missing($+1,:)=canon(k,:); end
    end
    for j=1:size(LD12.wires,1)
        duplicate=%f;
        for k=1:j-1
            if and(LD12.wires(j,:)==LD12.wires(k,:)) | and(LD12.wires(j,:)==LD12.wires(k,[2 1])) then duplicate=%t;end
        end
        if ~ld12_guide_has_wire(canon,LD12.wires(j,:)) | duplicate then extra($+1,:)=LD12.wires(j,:);end
    end
    if size(missing,1)==0 & size(extra,1)==0 & LD12.pending=="" then return;end
    if LD12.powerOn then tag="B01";lines="DABAR spauskite geltoną Maitinimas: prieš taisydami laidus išjunkite šaltinį.";return;end
    pair=emptystr(0,2);remove=%f;
    if size(extra,1)>0 then pair=extra(1,:);remove=%t;
    elseif size(missing,1)>0 then pair=missing(1,:);end
    id="";
    if LD12.pending<>"" then
        if ~remove then
            for k=1:size(missing,1)
                if or(missing(k,:)==LD12.pending) then pair=missing(k,:);break;end
            end
        end
        if size(pair,"*")==2 & or(pair==LD12.pending) then
            id=pair(1);if id==LD12.pending then id=pair(2);end
        else
            id=LD12.pending;tag=ld12_terminal_code(id);
            lines="DABAR dar kartą spauskite geltoną "+ld12_guide_terminal(id)+". Tai atšauks netinkamą pirmą pasirinkimą.";return;
        end
    elseif size(pair,"*")==2 then id=pair(1);end
    if id=="" then return;end
    tag=ld12_terminal_code(id);
    if remove then
        lines=["DABAR spauskite geltoną "+ld12_guide_terminal(id)+".";"Pašaliname netinkamą laidą. Vedlys po paspaudimo pažymės jo antrą galą."];
    elseif LD12.pending<>"" then
        lines=["DABAR spauskite geltoną "+ld12_guide_terminal(id)+".";"Taip užbaigsite pasirinktą laidą. Kitas gnybtas bus pažymėtas automatiškai."];
    else
        lines=["DABAR spauskite geltoną "+ld12_guide_terminal(id)+".";"Pradedame kitą reikalingą laidą. Paskui vedlys pažymės antrą galą."];
    end
endfunction

function yes=ld12_guide_answer_ready(step,slot,wanted)
    global LD12;
    entered=ld12_parse_number(LD12.answers(step,slot));
    relative=.02;absolute=1e-9;
    if step==1 then relative=.01;end
    if step==3 then relative=0;absolute=.005;end
    if step==6 then relative=0;absolute=0;end
    yes=~isnan(entered) & ~isinf(entered);
    if yes then yes=abs(entered-wanted)<=absolute+relative*abs(wanted);end
endfunction

function [lines,tag,value]=ld12_guide_number(step,slot,wanted,explanation)
    value=msprintf("%.10g",wanted);tag=ld12_answer_code(step,slot);
    lines=["DABAR į geltoną lauką ["+tag+"] įrašykite "+value+" (tik skaičių).";explanation];
endfunction

function lines=ld12_guide_finish()
    global LD12;
    if LD12.demoMode then lines="DABAR spauskite geltoną GRĮŽTI Į SAVO DARBĄ.";
    elseif LD12.step==6 & and(LD12.done) then lines="DABAR spauskite geltoną IŠSAUGOTI ATASKAITĄ. HTML failą programa išsaugos pati.";
    elseif LD12.step==6 & LD12.done(6) then lines="DABAR spauskite geltoną UŽBAIGTI PRALEISTĄ ETAPĄ. Programa grąžins į trūkstamą etapą.";
    elseif LD12.done(LD12.step) then lines="DABAR spauskite geltoną TOLIAU →. Šis etapas jau įrašytas.";
    elseif LD12.assessment then lines="DABAR spauskite geltoną TOLIAU →. Taip patvirtinsite šio etapo duomenis.";
    else lines="DABAR spauskite geltoną TIKRINTI. Jei etapas teisingas, programa iškart tęs darbą.";end
endfunction

function ld12_guide_refresh()
    global LD12;
    if typeof(LD12)<>"st" then return;end
    if ~isfield(LD12,"step") | ~isfield(LD12,"ui") then return;end
    if isfield(LD12.ui,"headless") then if LD12.ui.headless then return;end;end
    if ~isfield(LD12,"fig") then return;end
    if ~is_handle_valid(LD12.fig) then return;end
    enabled=%f;if isfield(LD12,"guide_enabled") then enabled=LD12.guide_enabled;end
    tag="";value="";
    if enabled then
        [lines,tag,value]=ld12_guide_next();
        if isfield(LD12.ui,"instructionLine") then LD12.ui.instructionLine(1).string=student_wrap(lines(1),38);end
        details=[lines;"";"KAM ATLIEKAME ŠĮ BANDYMĄ";ld12_guide_purpose();""; ...
            "Geltonai pažymėtas vienas kitas veiksmas tikrame stende. Galite jį atlikti pele arba pagalbos lange paspausti pasiūlytą veiksmą."; ...
            "Vien atvėrus pagalbą laidai, matavimai, atsakymai ir darbo režimas nepasikeičia."; ...
            "Skaičių laukuose rašykite tik skaičių; tinka kablelis arba taškas. Matavimai žurnale įrašomi automatiškai."; ...
            "Baigę išsaugokite originalų HTML. Patvirtinimo lange Atverti ataskaitą parodo turinį, Atverti ataskaitų aplanką – failo vietą."];
        student_guide_update("LD12","Etapas "+string(LD12.step)+" iš 6",details,%t);
    else
        student_guide_hide("LD12");
        if isfield(LD12.ui,"instructionLine") then LD12.ui.instructionLine(1).string=student_wrap(ld12_step_instruction(LD12.step),38);end
    end
    student_guide_focus("LD12",LD12.fig,tag,enabled);
    student_guide_action_refresh("LD12",LD12.fig,tag,value,enabled);
endfunction


function lines=ld12_guide_purpose()
    global LD12;
    c=LD12.cfg;
    lines=[msprintf("Tie patys trys vienodi imtuvai R=%g Ω jungiami dviem būdais prie to paties šaltinio Ul=%g V. Ul yra įtampa tarp dviejų šaltinio linijų; Uf yra įtampa ties vienu imtuvu.",c.R,c.Ul); ...
        "Palyginame tik jungimo būdą: imtuvų ir šaltinio reikšmės nesikeičia."];
    select LD12.step
    case 1 then lines($+1)="Žvaigždėje vieni trijų imtuvų galai susijungia bendrame taške N. Kitas kiekvieno imtuvo galas jungiamas prie savo linijos. Todėl vienam imtuvui tenka Uf=Ul/√3, o ne visa Ul.";
    case 2 then lines($+1)="Pamatuojame vieno žvaigždės imtuvo Uf ir If. Trys R yra vienodi, o šaltinis simetrinis, todėl visų imtuvų Uf ir If moduliai vienodi. Vieno imtuvo matavimo pakanka; kitų dviejų nematuotų rodmenų į žurnalą nekuriame.";
    case 3 then lines($+1)="Trikampyje kiekvienas imtuvas yra tarp dviejų linijų. Neutralis N nebejungiamas. Todėl vienas imtuvas gauna visą Ul – √3 karto didesnę įtampą nei žvaigždėje.";
    case 4 then lines($+1)="Pamatuojame vieno trikampio imtuvo Uf ir If. Ampermetras rodo srovę per šį imtuvą – fazinę If. Srovė šaltinio linijoje Il bus apskaičiuota kitame etape; ji nėra šio ampermetro tiesioginis rodmuo.";
    case 5 then lines($+1)="Iš dviejų tikrai užfiksuotų vieno imtuvo matavimų skaičiuojame abiejų simetrinių trijų imtuvų galias ir trikampio linijinę srovę. Tai apskaičiuoti dydžiai, o ne papildomi matavimai. V × mA = mW; papildomo dauginimo iš 1000 nereikia.";
    case 6 then
        y=ld12_journal_rows(1);d=ld12_journal_rows(2);
        lines($+1)="Išvados paaiškina, kodėl tų pačių imtuvų trikampio srovės ir galia didesnės, kai šaltinio Ul ta pati.";
        if y<>[] & d<>[] then
            lines($+1)=msprintf("Jūsų žvaigždės imtuvas: Uf=%.8g V, If=%.8g mA. Trikampio imtuvas: Uf=%.8g V, If=%.8g mA.",y(1,1),y(1,2),d(1,1),d(1,2));
            lines($+1)=msprintf("Iš šių rodmenų: PY=%.8g mW, PΔ=%.8g mW, santykis PΔ/PY=%.8g. Trikampyje vieno imtuvo įtampa √3 karto didesnė, todėl jo galia U²/R yra 3 kartus didesnė.",3*y(1,1)*y(1,2),3*d(1,1)*d(1,2),d(1,1)*d(1,2)/(y(1,1)*y(1,2)));
        end
    end
endfunction

function [lines,tag,value]=ld12_guide_next()
    global LD12;
    lines=emptystr(0,1);tag="LD12_PRIMARY";value="";st=LD12.step;c=LD12.cfg;
    if LD12.demoMode | LD12.done(st) then lines=ld12_guide_finish();return;end
    mode=ld12_stage_mode(st);
    if or(st==[1 2 3 4]) then
        if LD12.wireMode<>mode then
            if LD12.powerOn then tag="B01";lines="DABAR spauskite geltoną Maitinimas ir išjunkite šaltinį prieš keisdami jungimą.";return;end
            tag=msprintf("B%02d",9+mode);names=["ŽVAIGŽDĖ";"TRIKAMPIS"];
            lines="DABAR spauskite geltoną "+names(mode)+". Toliau vedlys pažymės šiam jungimui reikalingus kontaktus.";return;
        end
        [valid,why]=ld12_wiring_valid(LD12.wires);
        if ~valid & ~or(st==[1 3]) then
            tag="LD12_BACK";lines="DABAR spauskite geltoną ← Atgal. Ankstesniame etape vedlys padės pataisyti šio jungimo laidus.";return;
        end
        if or(st==[1 3]) then
            [lines,wire]=ld12_guide_wire_next(ld12_canonical_wires(mode));if wire<>"" then tag=wire;return;end
        end
    end
    if st==1 then
        wanted=c.Ul/sqrt(3);
        if ~ld12_guide_answer_ready(1,1,wanted) then
            [lines,tag,value]=ld12_guide_number(1,1,wanted,msprintf("Žvaigždės Uf = Ul/√3 = %g/1,7320508 = %.10g V. Tai vieno imtuvo įtampa. Tikras matavimas bus kitame etape.",c.Ul,wanted));return;
        end
    elseif st==3 then
        if ~ld12_guide_answer_ready(3,1,c.Ul) then
            [lines,tag,value]=ld12_guide_number(3,1,c.Ul,msprintf("Trikampyje imtuvas prijungtas tarp dviejų linijų, todėl Uf = Ul = %g V. N šiame jungime nenaudojamas.",c.Ul));return;
        end
    elseif st==2 | st==4 then
        row=ld12_journal_rows(mode);
        if row==[] then
            if ~ld12_valid_index(LD12.phase,3) then tag="B12";lines="DABAR spauskite geltoną R1 · U,I. Pasirenkame vieną iš trijų vienodų imtuvų matavimui.";return;end
            if ~LD12.powerOn then tag="B01";lines="DABAR spauskite geltoną Maitinimas: įjunkite trifazį šaltinį.";return;end
            if ~LD12.switchOn then tag="B02";lines="DABAR spauskite geltoną Jungiklis: uždarykite grandinę.";return;end
            tag="B03";lines=msprintf("DABAR spauskite geltoną Matuoti. R%d įtampa Uf ir fazinė srovė If automatiškai pateks į žurnalą.",LD12.phase);return;
        end
        wanted=1000*row(1,1)/c.R;
        if ~ld12_guide_answer_ready(st,1,wanted) then
            [lines,tag,value]=ld12_guide_number(st,1,wanted,msprintf("If = 1000·Uf/R = 1000·%.10g/%g = %.10g mA. Naudojame tikrai išmatuotą Uf; žurnalo ampermetras rodo %.10g mA.",row(1,1),c.R,wanted,row(1,2)));return;
        end
    elseif st==5 | st==6 then
        y=ld12_journal_rows(1);d=ld12_journal_rows(2);
        if y==[] | d==[] then tag="LD12_BACK";lines="DABAR spauskite geltoną ← Atgal ir grįžkite į trūkstamo jungimo matavimo etapą (2 arba 4). Skaičiuojame tik iš išsaugotų rodmenų.";return;end
        il=sqrt(3)*d(1,2);pd=3*d(1,1)*d(1,2);py=3*y(1,1)*y(1,2);
        if st==5 then
            vals=[il pd py];
            why=[msprintf("Apskaičiuojame linijinę srovę: IlΔ = √3·IfΔ = 1,7320508·%.10g = %.10g mA. IfΔ yra išmatuota, IlΔ čia nematuota.",d(1,2),il); ...
                msprintf("Trijų vienodų trikampio imtuvų galia: PΔ = 3·UfΔ·IfΔ = 3·%.10g·%.10g = %.10g mW.",d(1,1),d(1,2),pd); ...
                msprintf("Trijų vienodų žvaigždės imtuvų galia: PY = 3·UfY·IfY = 3·%.10g·%.10g = %.10g mW.",y(1,1),y(1,2),py)];
            for j=1:3
                if ~ld12_guide_answer_ready(5,j,vals(j)) then [lines,tag,value]=ld12_guide_number(5,j,vals(j),why(j));return;end
            end
        else
            // The first two relationships follow from the actual symmetric
            // topology; line currents are derived, never invented observations.
            iyLine=1000*c.Ul/(sqrt(3)*c.R);idLine=sqrt(3)*1000*c.Ul/c.R;
            conclusions=[abs(iyLine-y(1,2))<=.02*abs(y(1,2)),abs(idLine-il)<=.02*abs(il),abs(pd/py-3)<=.02*3];
            vals=2*ones(1,3);vals(find(conclusions))=1;
            why=[msprintf("Žvaigždėje kiekviena linija maitina tik savo imtuvą, srovė nesidalija: IlY = IfY = %.10g mA. IfY išmatuota; IlY lygybė gaunama iš šio jungimo.",y(1,2)); ...
                msprintf("Simetriniame trikampyje linijinė srovė yra dviejų fazinių srovių vektorių skirtumas. Todėl IlΔ = √3·IfΔ = √3·%.10g = %.10g mA (apskaičiuota).",d(1,2),il); ...
                msprintf("Iš matavimų apskaičiavome PΔ=%.10g mW ir PY=%.10g mW. Santykis %.10g yra apie 3; Ul ir visi R abiejuose bandymuose tie patys.",pd,py,pd/py)];
            for j=1:3
                if LD12.answers(6,j)<>string(vals(j)) then
                    tag=ld12_answer_code(6,j);value=string(vals(j));choice="Ne";if vals(j)==1 then choice="Taip";end
                    lines=["DABAR geltoname sąraše ["+tag+"] pasirinkite "+choice+".";why(j)];return;
                end
            end
        end
    end
    lines=ld12_guide_finish();
endfunction
