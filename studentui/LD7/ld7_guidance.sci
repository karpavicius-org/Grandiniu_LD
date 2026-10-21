// Opt-in guide: computes visible hints only. Actions remain explicit student clicks.
function ld7_guide_show()
    global LD7;
    if typeof(LD7)<>"st" then return; end
    LD7.guide_enabled=%t; ld7_guide_refresh();
endfunction

function ld7_guide_close()
    global LD7;
    if typeof(LD7)=="st" then LD7.guide_enabled=%f; end
    student_guide_hide("LD7"); ld7_guide_refresh();
endfunction

function yes=ld7_guide_has_wire(wires,pair)
    yes=%f;
    for j=1:size(wires,1)
        if and(wires(j,:)==pair) | and(wires(j,:)==pair([2 1])) then yes=%t; return; end
    end
endfunction

function text=ld7_guide_terminal(id)
    text="["+ld7_terminal_code(id)+"] "+ld7_terminal_name(id);
endfunction

function [lines,tag]=ld7_guide_wire_next(canon)
    global LD7;
    tag="";lines=emptystr(0,1);
    missing=emptystr(0,2);extra=emptystr(0,2);
    for k=1:size(canon,1)
        if ~ld7_guide_has_wire(LD7.wires,canon(k,:)) then missing($+1,:)=canon(k,:); end
    end
    for j=1:size(LD7.wires,1)
        duplicate=%f;
        for k=1:j-1
            if and(LD7.wires(j,:)==LD7.wires(k,:)) | and(LD7.wires(j,:)==LD7.wires(k,[2 1])) then duplicate=%t;end
        end
        if ~ld7_guide_has_wire(canon,LD7.wires(j,:)) | duplicate then extra($+1,:)=LD7.wires(j,:);end
    end
    if size(missing,1)==0 & size(extra,1)==0 & LD7.pending=="" then return;end
    if LD7.powerOn then tag="B01";lines="DABAR spauskite geltoną Maitinimas: prieš taisydami laidus išjunkite šaltinį.";return;end
    pair=emptystr(0,2);remove=%f;
    if size(extra,1)>0 then pair=extra(1,:);remove=%t;
    elseif size(missing,1)>0 then pair=missing(1,:);end
    id="";
    if LD7.pending<>"" then
        if ~remove then
            for k=1:size(missing,1)
                if or(missing(k,:)==LD7.pending) then pair=missing(k,:);break;end
            end
        end
        if size(pair,"*")==2 & or(pair==LD7.pending) then
            id=pair(1);if id==LD7.pending then id=pair(2);end
        else
            id=LD7.pending;tag=ld7_terminal_code(id);
            lines="DABAR dar kartą spauskite geltoną "+ld7_guide_terminal(id)+". Tai atšauks netinkamą pirmą pasirinkimą.";return;
        end
    elseif size(pair,"*")==2 then id=pair(1);end
    if id=="" then return;end
    tag=ld7_terminal_code(id);
    if remove then
        lines=["DABAR spauskite geltoną "+ld7_guide_terminal(id)+".";"Pašaliname netinkamą laidą. Vedlys po paspaudimo pažymės jo antrą galą."];
    elseif LD7.pending<>"" then
        lines=["DABAR spauskite geltoną "+ld7_guide_terminal(id)+".";"Taip užbaigsite pasirinktą laidą. Kitas gnybtas bus pažymėtas automatiškai."];
    else
        lines=["DABAR spauskite geltoną "+ld7_guide_terminal(id)+".";"Pradedame kitą reikalingą laidą. Paskui vedlys pažymės antrą galą."];
    end
endfunction

function yes=ld7_guide_answer_ready(step,slot,wanted)
    global LD7;
    value=ld7_parse_number(LD7.answers(step,slot));
    yes=~isnan(value) & ~isinf(value);
    relative=.02;absolute=1e-9;
    if step==3 then if slot==1 then relative=.03;else relative=.01;end;end
    if step==6 then relative=0;absolute=0;end
    if yes then yes=abs(value-wanted)<=absolute+relative*abs(wanted);end
endfunction

function [lines,tag,value]=ld7_guide_number(step,slot,wanted,explanation)
    value=msprintf("%.10g",wanted);tag=ld7_answer_code(step,slot);
    lines=["DABAR į geltoną lauką ["+tag+"] įrašykite "+value+" (tik skaičių).";explanation];
endfunction

function lines=ld7_guide_finish()
    global LD7;
    if LD7.demoMode then lines="DABAR spauskite geltoną GRĮŽTI Į SAVO DARBĄ.";
    elseif LD7.step==6 & and(LD7.done) then lines="DABAR spauskite geltoną ĮRAŠYTI ATASKAITĄ. HTML failą programa išsaugos pati.";
    elseif LD7.step==6 & LD7.done(6) then lines="DABAR spauskite geltoną UŽBAIGTI PRALEISTĄ ETAPĄ. Programa grąžins į trūkstamą etapą.";
    elseif LD7.done(LD7.step) then lines="DABAR spauskite geltoną TOLIAU →. Šis etapas jau įrašytas.";
    elseif LD7.assessment then lines="DABAR spauskite geltoną ĮRAŠYTI IR TOLIAU →. Taip patvirtinsite šio etapo duomenis.";
    else lines="DABAR spauskite geltoną TIKRINTI. Jei etapas teisingas, programa iškart tęs darbą.";end
endfunction

function ld7_guide_refresh()
    global LD7;
    if typeof(LD7)<>"st" then return;end
    if ~isfield(LD7,"step") | ~isfield(LD7,"ui") then return;end
    if isfield(LD7.ui,"headless") then if LD7.ui.headless then return;end;end
    if ~isfield(LD7,"fig") then return;end
    if ~is_handle_valid(LD7.fig) then return;end
    enabled=%f;if isfield(LD7,"guide_enabled") then enabled=LD7.guide_enabled;end
    tag="";value="";
    if enabled then
        [lines,tag,value]=ld7_guide_next();
        if isfield(LD7.ui,"instructionLine") then LD7.ui.instructionLine(1).string=student_wrap(lines(1),38);end
        details=[lines;"";"KAM ATLIEKAME ŠĮ BANDYMĄ";ld7_guide_purpose();""; ...
            "Geltonai pažymėtas vienas kitas veiksmas tikrame stende. Galite jį atlikti pele arba pagalbos lange paspausti pasiūlytą veiksmą."; ...
            "Vien atvėrus pagalbą laidai, matavimai, atsakymai ir darbo režimas nepasikeičia."; ...
            "Skaičių laukuose rašykite tik skaičių; tinka kablelis arba taškas. Matavimai žurnale įrašomi automatiškai."; ...
            "Baigę išsaugokite originalų HTML. Patvirtinimo lange Atverti ataskaitą parodo turinį, Atverti ataskaitų aplanką – failo vietą."];
        student_guide_update("LD7","Etapas "+string(LD7.step)+" iš 6",details,%t);
    else
        student_guide_hide("LD7");
        if isfield(LD7.ui,"instructionLine") then LD7.ui.instructionLine(1).string=student_wrap(ld7_step_instruction(LD7.step),38);end
    end
    student_guide_focus("LD7",LD7.fig,tag,enabled);
    student_guide_action_refresh("LD7",LD7.fig,tag,value,enabled);
endfunction

function lines=ld7_guide_purpose()
    global LD7;
    select LD7.step
    case 1 then lines="Jungsime šaltinį, jungiklį, ampermetrą ir keičiamą apkrovą. Voltmetras rodys apkrovos įtampą. Toliau išsiaiškinsime, kodėl apkrovus šaltinį jo įtampa sumažėja.";
    case 2 then lines="P1–P5 yra penkios tos pačios apkrovos varžos. Kiekvienoje padėtyje užfiksuojame U ir I. Mažesnė apkrovos varža leidžia tekėti didesnei srovei, todėl daugiau įtampos prarandama šaltinio viduje.";
    case 3 then lines="Iš dviejų savo bandymų apskaičiuojame šaltinio vidinę varžą r. Tai nėra papildoma išorinė detalė: ji paaiškina skirtumą tarp šaltinio E ir apkrovos U.";
    case 4 then lines="P=U·I parodo apkrovai perduodamą galią. Didžiausia galia ir didžiausias naudingumas nėra tas pats: kai apkrova R lygi vidinei r, apkrova gauna pusę šaltinio įtampos ir naudingumas yra apie 50 %.";
    case 5 then lines="Tuščioji eiga parodo įtampą beveik be apkrovos. Virtualus trumpasis jungimas parodo ribojamą srovę, kai apkrova beveik nulinė. Abu palyginame su darbiniais matavimais; tai kompiuterinio modelio bandymai.";
    case 6 then
        p=ld7_journal_rows(3);a=ld7_journal_rows(1);b=ld7_journal_rows(5);
        lines="Išvados apibendrina tuos pačius jūsų matavimus, o ne naują užduotį.";
        if p<>[] then lines($+1)=msprintf("P3: R=%g Ω, U=%.6g V, I=%.6g mA, P=%.6g mW, η=%.6g %%. Tai suderinimo taškas R=r.",p(1,3),p(1,1),p(1,2),p(1,1)*p(1,2),100*p(1,1)/LD7.cfg.E);end
        if a<>[] & b<>[] then lines($+1)=msprintf("P1: I=%.6g mA ir U=%.6g V; P5: I=%.6g mA ir U=%.6g V. Didesnę srovę lydi mažesnė apkrovos įtampa.",a(1,2),a(1,1),b(1,2),b(1,1));end
    end
endfunction

function [lines,tag,value]=ld7_guide_next()
    global LD7;
    lines=emptystr(0,1);tag="LD7_PRIMARY";value="";st=LD7.step;
    if LD7.demoMode | LD7.done(st) then lines=ld7_guide_finish();return;end
    if st==1 then
        if LD7.wireMode<>1 then tag="B10";lines="DABAR spauskite geltoną Darbinė. Pradėsime nuo įprastos apkrovos grandinės.";return;end
        [lines,wire]=ld7_guide_wire_next(ld7_canonical_wires(1));
        if wire<>"" then tag=wire;return;end
        lines=ld7_guide_finish();return;
    end
    if st==2 then
        if LD7.wireMode<>1 then tag="B10";lines="DABAR spauskite geltoną Darbinė: čia matuojame penkias reostato padėtis.";return;end
        [ready,why]=ld7_wiring_valid(LD7.wires);
        if ~ready then tag="LD7_BACK";lines="DABAR spauskite geltoną ← Atgal. 1 etape vedlys padės pataisyti darbinės grandinės laidus.";return;end
        k=0;for j=1:5;if ld7_journal_rows(j)==[] then k=j;break;end;end
        if k==0 then lines=["Visi penki U ir I matavimai jau žurnale. Jų perrašyti nereikia.";ld7_guide_finish()];return;end
        if LD7.position<>k then tag=msprintf("B%02d",k+12);lines=msprintf("DABAR spauskite geltoną P%d / %g Ω. Ši apkrova dar neišmatuota.",k,LD7.cfg("R"+string(k)));return;end
        if ~LD7.powerOn then tag="B01";lines="DABAR spauskite geltoną Maitinimas: įjungiame šaltinį.";return;end
        if ~LD7.switchOn then tag="B02";lines="DABAR spauskite geltoną Jungiklis: uždarome srovės kelią.";return;end
        tag="B03";lines=msprintf("DABAR spauskite geltoną Matuoti. P%d įtampa ir srovė automatiškai išliks žurnale.",k);return;
    end
    if st==3 | st==4 then
        a=ld7_journal_rows(1);b=ld7_journal_rows(5);p=ld7_journal_rows(3);
        if a==[] | b==[] | p==[] then tag="LD7_BACK";lines="DABAR spauskite geltoną ← Atgal iki 2 etapo ir užbaikite penkis matavimus. Skaičiuojame tik iš užfiksuotų rodmenų.";return;end
        r=1000*(b(1,1)-a(1,1))/(a(1,2)-b(1,2));
        used=ld7_parse_number(LD7.answers(3,1));if ~isnan(used) & ~isinf(used) then if abs(used-r)<=.03*abs(r) then r=used;end;end
        if st==3 then
            vals=[r a(1,2)*r/1000];
            explains=[msprintf("r = 1000·(U5−U1)/(I1−I5) = 1000·(%.8g−%.8g)/(%.8g−%.8g), Ω.",b(1,1),a(1,1),a(1,2),b(1,2)); ...
                msprintf("Ur = I1·r/1000 = %.8g·%.8g/1000, V. Dalijame iš 1000, nes srovė žurnale yra mA.",a(1,2),r)];
        else
            vals=[p(1,1)*p(1,2) 1000*LD7.cfg.E^2/(4*r) 100*p(1,1)/LD7.cfg.E];
            explains=[msprintf("P3 = U3·I3 = %.8g·%.8g, mW (V × mA = mW).",p(1,1),p(1,2)); ...
                msprintf("Pmax = 1000·E²/(4r) = 1000·%g²/(4·%.8g), mW.",LD7.cfg.E,r); ...
                msprintf("η3 = 100·U3/E = 100·%.8g/%g, %%. Pusė šaltinio įtampos tenka apkrovai.",p(1,1),LD7.cfg.E)];
        end
        for j=1:size(vals,"*")
            if ~ld7_guide_answer_ready(st,j,vals(j)) then [lines,tag,value]=ld7_guide_number(st,j,vals(j),explains(j));return;end
        end
        lines=ld7_guide_finish();return;
    end
    if st==5 then
        mode=2;if ld7_journal_rows(6)<>[] then mode=3;end
        if ld7_journal_rows(6)<>[] & ld7_journal_rows(7)<>[] then lines=["Tuščiosios eigos ir virtualaus TJ rodmenys jau išsaugoti.";ld7_guide_finish()];return;end
        if LD7.wireMode<>mode then
            if LD7.powerOn then tag="B01";lines="DABAR spauskite geltoną Maitinimas ir išjunkite šaltinį prieš keisdami bandymo grandinę.";return;end
            tag=msprintf("B%02d",mode+9);
            if mode==2 then lines="DABAR spauskite geltoną Tuščioji eiga. Išmatuosime beveik neapkrauto šaltinio įtampą.";
            else lines="DABAR spauskite geltoną Virtualus TJ. Kompiuteriniame modelyje išmatuosime srovę beveik be išorinės varžos.";end
            return;
        end
        [lines,wire]=ld7_guide_wire_next(ld7_canonical_wires(mode));if wire<>"" then tag=wire;return;end
        if ~LD7.powerOn then tag="B01";lines="DABAR spauskite geltoną Maitinimas. Laidai jau teisingi.";return;end
        if mode==3 & ~LD7.switchOn then tag="B02";lines="DABAR spauskite geltoną Jungiklis: uždarome virtualią TJ grandinę.";return;end
        tag="B03";lines="DABAR spauskite geltoną Matuoti. Šio režimo rodmuo automatiškai pateks į žurnalą.";return;
    end
    if st==6 then
        a=ld7_journal_rows(1);p=ld7_journal_rows(3);b=ld7_journal_rows(5);
        if a==[] | p==[] | b==[] then tag="LD7_BACK";lines="DABAR spauskite geltoną ← Atgal ir užbaikite trūkstamus matavimus. Išvadas grindžiame žurnalu.";return;end
        powers=zeros(1,5);loads=zeros(1,5);
        for k=1:5
            row=ld7_journal_rows(k);
            if row==[] then tag="LD7_BACK";lines="DABAR spauskite geltoną ← Atgal ir užbaikite penkis apkrovos matavimus.";return;end
            powers(k)=row(1,1)*row(1,2);loads(k)=row(1,3);
        end
        r=1000*(b(1,1)-a(1,1))/(a(1,2)-b(1,2));
        [peak,which]=max(powers);
        conclusions=[abs(loads(which)-r)<=.03*abs(r),abs(100*p(1,1)/LD7.cfg.E-50)<=1,a(1,2)>b(1,2)&a(1,1)<b(1,1)];
        vals=2*ones(1,3);vals(find(conclusions))=1;
        why=[msprintf("P3 apkrova %g Ω perduoda %.7g mW; ši padėtis yra R=r. Todėl ties R=r galia didžiausia.",p(1,3),p(1,1)*p(1,2)); ...
            msprintf("P3 naudingumas = 100·%.7g/%g = %.7g %%. Tai apie 50 %%.",p(1,1),LD7.cfg.E,100*p(1,1)/LD7.cfg.E); ...
            msprintf("P1: I=%.7g mA, U=%.7g V; P5: I=%.7g mA, U=%.7g V. Didesnė srovė sukelia didesnį vidinį įtampos kritimą.",a(1,2),a(1,1),b(1,2),b(1,1))];
        for j=1:3
            if LD7.answers(6,j)<>string(vals(j)) then tag=ld7_answer_code(6,j);value=string(vals(j));choice="Ne";if vals(j)==1 then choice="Taip";end;lines=["DABAR geltoname sąraše ["+tag+"] pasirinkite "+choice+".";why(j)];return;end
        end
        lines=ld7_guide_finish();return;
    end
endfunction
