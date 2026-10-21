// LD2-4: measure, inspect and choose. One workflow for UI, help and readiness.
function ld2_workflow_upgrade()
    global LD2;
    if isfield(LD2.state,"workflow_revision") then
        if LD2.state.workflow_revision==4 then return; end
    end
    // Keep real readings and identity; old numerical answers are not choices.
    LD2.state.comparisons=zeros(1,12);
    LD2.state.resonance_choice=0;
    for s=[3 4 6 7 9 10]
        LD2.state.answers_text(s,:)=emptystr(1,8);
        LD2.state.answers(s,:)=%nan*ones(1,8);
        LD2.state.completed(s)=0;
    end
    // A previous five-field half-power answer cannot be interpreted as BW.
    LD2.state.answers_text(11,:)=emptystr(1,8);
    LD2.state.answers(11,:)=%nan*ones(1,8);
    LD2.state.completed([11 12])=0;
    if ~isfield(LD2.state,"auto_actions") then LD2.state.auto_actions=emptystr(0,1); end
    LD2.state.auto_recording=%f;
    LD2.state.workflow_revision=4;
    LD2.state.completed(3)=LD2.state.completed(2);
    LD2.state.completed(6)=LD2.state.completed(5);
endfunction

function title=ld2_workflow_title(step)
    titles=["Darbo eiga";"Sujunkite RC";"";"Matuokite ir palyginkite"; ...
        "Sujunkite RL";"";"Matuokite ir palyginkite";"Sujunkite RLC"; ...
        "Pasirinkite rezonansą";"Palyginkite įtampas";"Apskaičiuokite skirtumą";"Išsaugokite darbą"];
    title=titles(step);
endfunction

function label=ld2_primary_label(step)
    global LD2;
    label="Toliau →";
    if ~LD2.state.assessment & ~LD2.state.completed(step) then label="Patikrinti";end
    if step==1 then label="Pradėti →";end
    if step==12 then label="Išsaugoti ataskaitą";end
endfunction

function [question,details]=ld2_workflow_question(step)
    question=""; details=emptystr(0,1);
    select step
    case 4 then
        question="Ar apskaičiuota E sutampa su šaltinio įtampa?";
        details=["Programa apskaičiuoja E = sqrt(UR² + UC²)."; ...
            "Palyginkite dvi parodytas įtampas. Skaičių perrašyti nereikia."];
    case 7 then
        question="Ar apskaičiuota E sutampa su šaltinio įtampa?";
        details=["Programa apskaičiuoja E = sqrt(UR² + UL²)."; ...
            "Palyginkite dvi parodytas įtampas. Skaičių perrašyti nereikia."];
    case 9 then
        question="Kuriame taške UR didžiausia?";
        details=["Stendas parenka tris dažnius ir išmatuoja UR kiekviename."; ...
            "Pasirinkite eilutę su didžiausia UR. Jos dažnis yra rastas rezonansas."];
    case 10 then
        question="Ar mažiausia ULC artima nuliui?";
        details=["UL ir UC maksimumai pasiekiami skirtingais dažniais."; ...
            "Ties rezonansu priešingų fazių UL ir UC kompensuojasi."; ...
            "Palyginkite parodytą mažiausią ULC su 0 V."];
    case 11 then
        question="BW = f2 - f1, Hz";
        details=["Stendas pats randa f1 ir f2 ties URmax/sqrt(2)."; ...
            "Iš didesnio dažnio atimkite mažesnį. Įrašykite vieną skaičių Hz."; ...
            "Pavyzdys su kitais skaičiais: 5200 - 5000 = 200 Hz."];
    end
endfunction

function lines=ld2_workflow_readings(step)
    global LD2;
    lines=emptystr(0,1);
    [action,ready]=ld2_auto_stage_status(step);
    if ~ready then return; end
    select step
    case 4 then
        ur=LD2.state.rc_UR; ux=LD2.state.rc_UC; ue=LD2.state.rc_UE;
        lines=[msprintf("I = %.3f mA",LD2.state.rc_I*1000); ...
            msprintf("UR = %.3f V; UC = %.3f V",ur,ux); ...
            msprintf("Apskaičiuota E = %.3f V",sqrt(ur^2+ux^2)); ...
            msprintf("Šaltinio įtampa = %.3f V",ue)];
    case 7 then
        ur=LD2.state.rl_UR; ux=LD2.state.rl_UL; ue=LD2.state.rl_UE;
        lines=[msprintf("I = %.3f mA",LD2.state.rl_I*1000); ...
            msprintf("UR = %.3f V; UL = %.3f V",ur,ux); ...
            msprintf("Apskaičiuota E = %.3f V",sqrt(ur^2+ux^2)); ...
            msprintf("Šaltinio įtampa = %.3f V",ue)];
    case 10 then
        [fl,ul,ok]=ld2_peak_best("UL"); [fc,uc,ok]=ld2_peak_best("UC");
        [fz,uz,ok]=ld2_peak_best("ULC");
        lines=[msprintf("UL max = %.3f V",ul);msprintf("UC max = %.3f V",uc); ...
            msprintf("ULC min = %.3f V",uz);"Visi matavimo taškai išsaugoti."];
    case 11 then
        lines=[msprintf("f1 = %.3f Hz",LD2.state.f1_meas); ...
            msprintf("f2 = %.3f Hz",LD2.state.f2_meas); ...
            msprintf("BW = %.3f - %.3f",LD2.state.f2_meas,LD2.state.f1_meas)];
    end
endfunction

function [ok,why]=ld2_workflow_ready()
    global LD2;
    ok=%f; why=""; step=LD2.state.step;
    if step==1 then ok=%t; return; end
    [action,measured]=ld2_auto_stage_status(step);
    [wired,missing]=ld2_validate_main(ld2_phase_for_step(step));
    if ~wired then measured=%f;end
    if ~measured then why="Pirmiausia spauskite „"+action+"“ po grandine."; return; end
    if or(step==[4 7 10]) then
        if ~or(LD2.state.comparisons(step)==[1 2]) then
            why="Palyginkite parodytus rodmenis ir pasirinkite Taip arba Ne."; return;
        end
    elseif step==9 then
        i=LD2.state.resonance_choice;
        if i<1 | i>size(LD2.state.res_f,"*") then
            why="Pasirinkite vieną iš trijų matavimo eilučių dešinėje."; return;
        end
    elseif step==11 then
        bw=ld2_safe_number(LD2.state.answers_text(11,1));
        if isnan(bw) | isinf(bw) then
            why="Įrašykite vieną skaičių: BW = f2 - f1 (Hz)."; return;
        end
    elseif step==12 then
        stages=ld2_visible_steps();stages=stages(1:$-1);
        missing=stages(find(LD2.state.completed(stages)<>1));
        if size(missing,"*")>0 then
            why="Dar neužbaigtas etapas: "+ld2_step_title(missing(1))+". Raskite jį per Darbo meniu → Tęsti arba atkurti darbą → Etapai.";
            return;
        end
    end
    ok=%t;
endfunction

function ld2_choose_comparison(value)
    global LD2;
    step=LD2.state.step;
    if LD2.example_active | ~or(step==[4 7 10]) | ~or(value==[1 2]) then return; end
    [label,ready]=ld2_auto_stage_status(step);if ~ready then return; end
    LD2.state.comparisons(step)=value;
    LD2.state.completed(step)=0;LD2.state.completed(12)=0;
    ld2_render_step();bench_autosave("LD2");
    ld2_set_status("Jūsų pasirinkimas įrašytas. Spauskite Toliau.","info");
endfunction

function ld2_choose_resonance(index)
    global LD2;
    if LD2.example_active | LD2.state.step<>9 then return; end
    [label,ready]=ld2_auto_stage_status(9);
    if ~ready | index<1 | index>size(LD2.state.res_f,"*") then return; end
    LD2.state.resonance_choice=index;
    LD2.state.answers_text(9,1)=ld2_num(LD2.state.res_f(index),8);
    LD2.state.answers(9,1)=LD2.state.res_f(index);
    LD2.state.completed(9)=0;LD2.state.completed(12)=0;
    ld2_render_step();bench_autosave("LD2");
    ld2_set_status("Jūsų pasirinktas dažnis įrašytas. Spauskite Toliau.","info");
endfunction

function lines=ld2_workflow_help(step)
    global LD2;
    advance="Spauskite „"+ld2_primary_label(step)+"“.";
    if ld2_primary_label(step)=="Patikrinti" then
        advance=advance+" Kai etapas patikrintas, spauskite „Toliau →“.";
    end
    lines=[ld2_stage_purpose(step);""];
    if step==LD2.state.step then
        [guide,focus,button,answer]=ld2_guide_next();
        lines=[lines;"DABAR";guide;""];
    end
    lines=[lines;"VISA ŠIO ETAPO EIGA"];
    if or(step==[2 5 8]) then
        pairs=ld2_required_main(ld2_phase_for_step(step));
        lines=[lines;"1. Stendo apačioje spauskite „Sujungti grandinę“. Šis mygtukas paruoš tik šio etapo laidus."; ...
            "2. Patikrinkite, ar matote sujungtus laidus ir žymą „Bandymas atliktas“."; ...
            "3. Dešinėje apačioje "+advance;"";"JEIGU NORITE LAIDUS SUJUNGTI PELE"];
        for k=1:size(pairs,1)
            lines=[lines;string(k)+". Vieną kartą spauskite "+ld2_guide_terminal(pairs(k,1))+ ...
                ", tada vieną kartą "+ld2_guide_terminal(pairs(k,2))+"."];
        end
        lines=[lines;"Gnybtas – mažas kontaktas su T numeriu schemoje. Po dviejų paspaudimų atsiranda vienas laidas."; ...
            "Jei pažymėjote ne tą pirmą gnybtą, paspauskite jį dar kartą: pasirinkimas bus atšauktas."; ...
            "Jei jau atsirado ne tas laidas, apačioje spauskite „Atšaukti laidą“ ir teisingą porą sujunkite iš naujo."; ...
            "Kai visi laidai sujungti, "+advance];
    elseif step==1 then
        lines=[lines;"1. Lango viršuje patikrinkite savo vardą, grupę ir variantą."; ...
            "2. Jei duomenys neteisingi: „Darbo meniu“ → „Mano duomenys ir variantas“ → „Studentas ir priskirtos reikšmės“ → „Keisti duomenis“."; ...
            "3. Įrašykite dėstytojo priskirtą eilės numerį nuo 1 iki 64, vardą ir pavardę bei grupę. Patvirtinkite parodytas reikšmes."; ...
            "4. Dešinėje apačioje spauskite „Pradėti →“."; ...
            "Toliau bandymų rodmenis įrašo stendas. Jūs palyginsite juos, pasirinksite išvadas ir vieną kartą įrašysite dažnių skirtumą."];
    elseif step==12 then
        lines=[lines;"1. Spauskite „Sudaryti dažninę kreivę“."; ...
            "2. Spauskite „Grafikas“, kad pamatytumėte, kaip UR kinta didinant dažnį. Užvėrę grafiko langą grįžkite į stendą."; ...
            "3. Spauskite „Suvestinė“ ir peržiūrėkite išsaugotus rezultatus."; ...
            "4. Jei dėstytojas prašo savo paaiškinimo, spauskite „Įrašyti išvadas“. Atsivėrusiame lange „LD2 – jūsų išvados“ spauskite teksto lauką, įrašykite savo paaiškinimą ir patvirtinkite mygtuku OK. Cancel atšaukia įvedimą. Šį tekstą perskaitys dėstytojas."; ...
            "5. Spauskite „Išsaugoti ataskaitą“. Programa pati sukurs HTML failą ir parodys jo kelią."; ...
            "6. Patvirtinimo lange spauskite „Atverti ataskaitų aplanką“. Raskite failą, kurio vardas prasideda LD2-V ir baigiasi .html."; ...
            "7. Pateikite šį originalų HTML failą dėstytojo nurodytu būdu. Uždarius patvirtinimą failas lieka išsaugotas."; ...
            "Jei rodomas pranešimas apie neužbaigtą etapą: „Darbo meniu“ → „Tęsti arba atkurti darbą“ → „Etapai“; pasirinkite pranešime nurodytą etapą."];
    else
        [action,ready]=ld2_auto_stage_status(step);
        lines=[lines;"1. Spauskite „"+action+"“ po grandine."; ...
            "2. Palaukite, kol dešinėje pasirodys rodmenys. Programa pati įjungia virtualų šaltinį, prijungia zondus ir įrašo rodmenis."];
        if step==4 | step==7 then
            lines=[lines;"3. Dešinėje perskaitykite eilutes „Apskaičiuota E“ ir „Šaltinio įtampa“. Abi reikšmės nurodytos voltais (V)."; ...
                "4. Palyginkite tas dvi reikšmes. Po klausimu pele pasirinkite „Taip“ arba „Ne“. Skaičių į atskirą lauką čia rašyti nereikia."];
        elseif step==9 then
            lines=[lines;"3. Dešinėje matysite tris pasirenkamas eilutes. Kiekvienoje yra dažnis (Hz) ir rezistoriaus įtampa UR (V)."; ...
                "4. Palyginkite trijų eilučių UR reikšmes. Spauskite visą eilutę, kurioje UR didžiausia. Atsiradusi varnelė rodo jūsų pasirinkimą."; ...
                "5. Jei apsigalvojote, tiesiog spauskite kitą eilutę. Pasirinktos eilutės dažnį programa išsaugos kaip jūsų rastą rezonanso dažnį."];
        elseif step==10 then
            lines=[lines;"3. Dešinėje raskite eilutę „ULC min“. Tai mažiausia išmatuota bendra ritės ir kondensatoriaus įtampa."; ...
                "4. Palyginkite ją su 0 V ir po klausimu pasirinkite „Taip“ arba „Ne“. UL max ir UC max rodmenų perrašyti nereikia."];
        elseif step==11 then
            lines=[lines;"3. Dešinėje perskaitykite f1 ir f2. Hz reiškia hercus – dažnio vienetą."; ...
                "4. Apskaičiuokite BW = f2 - f1: iš didesnio parodyto dažnio atimkite mažesnį."];
            if ready then
                lines=[lines;msprintf("Jūsų rodmenys: f2 = %.3f Hz; f1 = %.3f Hz. Atlikite atimtį %.3f - %.3f.", ...
                    LD2.state.f2_meas,LD2.state.f1_meas,LD2.state.f2_meas,LD2.state.f1_meas)];
            end
            lines=[lines;"5. Pele spauskite baltą lauką šalia „BW, Hz“. Jei jame jau yra tekstas, pažymėkite jį Ctrl+A."; ...
                "6. Įrašykite tik gautą skaičių: be BW=, be Hz ir be atimties ženklo. Galima vartoti kablelį arba tašką."; ...
                "7. Paspauskite Tab arba pele spauskite už įvedimo lauko. Pavyzdžiui, kitų skaičių 5200 - 5000 rezultatas įrašomas kaip 200."];
        end
        if ready then lines=[lines;"";"JŪSŲ IŠSAUGOTI RODMENYS";ld2_workflow_readings(step)];end
        lines=[lines;"";"Kai savo atsakymą pasirinkote ar įrašėte, dešinėje apačioje "+advance; ...
            "Jei mygtukas dar neaktyvus, patikrinkite, ar atlikote bandymą ir pateikėte atsakymą. Pasirinkimą galima pataisyti iki perėjimo arba grįžus mygtuku „Atgal“."];
    end
    lines=[lines;"";"Pagalbos langas atsinaujina po veiksmo stende. Mygtukas „Baigti vedimą“ jį uždaro; jūsų duomenys išlieka."; ...
        "Pagalbos atvėrimas savaime nekeičia atsiskaitymo režimo ir nepildo jūsų atsakymų."];
endfunction
