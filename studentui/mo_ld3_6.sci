// LD3–LD6 measurement-only protocols. Student actions are wiring and copying
// actual instrument readings. Legacy models/configuration are not modified.

function c=mo36_component(name,ids,labels)
    c=struct("name",name,"ids",matrix(ids,-1,1),"labels",matrix(labels,-1,1));
endfunction

function t=mo36_trial(key,title,condition,why,topology,wires,x)
    t=struct("key",key,"title",title,"condition",condition,"why",why, ...
        "topology",topology,"wires",wires,"x",x);
endfunction

function r=mo36_reading(u,i,ok,message,lab)
    if ~ok then error(lab+": "+message);end
    if or(isnan([u;i])) | or(isinf([u;i])) then error(lab+": modelis negrąžino baigtinių prietaisų rodmenų.");end
    r=struct("ids",["U";"I"],"names",["Voltmetro rodmuo";"Ampermetro rodmuo"], ...
        "units",["V";"mA"],"values",[u;i]);
endfunction

function value=mo36_record_value(rec,id)
    indices=find(rec.reading.ids==id);
    if size(indices,"*")<>1 then error("Ataskaitoje trūksta vieno aiškiai apibrėžto "+id+" rodmens.");end
    value=rec.reading.values(indices(1));
    if isnan(value) | isinf(value) then error("Ataskaitos rodmuo turi būti baigtinis skaičius.");end
endfunction

function mo36_require_records(records,count,lab)
    if length(records)<>count then error(lab+": analizei reikia visų "+string(count)+" atliktų bandymų.");end
endfunction

function p=mo_protocol_3(cfg)
    components=list( ...
        mo36_component("Maitinimo šaltinis",["E_N";"E_P"],["−";"+"]), ...
        mo36_component("Jungiklis",["K1";"K2"],["1";"2"]), ...
        mo36_component("Ampermetras",["A_P";"A_N"],["+";"−"]), ...
        mo36_component("Rezistorius R",["R1A";"R1B"],["a";"b"]), ...
        mo36_component("Voltmetras",["V_P";"V_N"],["+";"−"]));
    trials=list();
    why=["Pirmiausia užfiksuojame srovę esant mažiausiai įtampai. Šis rodmuo bus kitų dviejų bandymų palyginimo pradžia."; ...
        "Keičiasi tik šaltinio įtampa. Rezistorius ir laidai lieka tie patys, todėl srovės pokytį galėsime susieti su įtampos pokyčiu."; ...
        "Trečias taškas parodys, ar tas pats srovės ir įtampos ryšys išlieka dar padidinus įtampą. Palyginimą ir išvadą parengs programa."];
    for k=1:3
        voltage=cfg("U"+string(k));
        t=mo36_trial("u"+string(k),string(k)+" bandymas · "+mo_num(voltage)+" V", ...
            "Šaltinis automatiškai nustatytas: "+mo_num(voltage)+" V. Tas pats "+mo_num(cfg.R)+" Ω rezistorius; laidų nekeiskite.", ...
            why(k),"ld3-same-resistor",ld3_canonical_wires(),voltage);
        if k==1 then
            t.condition="Šaltinis automatiškai nustatytas: "+mo_num(voltage)+" V. Pirmiausia sujunkite parodytus kabelius.";
        end
        t.voltage=voltage;trials($+1)=t;
    end
    p=struct("lab","LD3","title","Omo dėsnio tyrimas","aim", ...
        "Stebime, kaip to paties rezistoriaus srovė keičiasi didinant įtampą. Jums reikia sujungti laidus ir perrašyti prietaisų rodmenis; įtampas nustato ir išvadą parengia programa.", ...
        "background",["Voltmetras rodo įtampą V, ampermetras – srovę mA. Vieną kartą sujungta grandinė naudojama visiems trims bandymams."; ...
        "Trys įtampos nėra trys laisvai pasirenkami variantai. Tai trys iš eilės automatiškai parengti to paties rezistoriaus bandymai."], ...
        "trials",trials,"components",components,"xlabel","Šaltinio įtampa, V");
endfunction

function r=mo_measure_3(cfg,t,wires)
    if ~mo_wires_equal(wires,t.wires) then error("LD3: laidai neatitinka šio bandymo schemos.");end
    global LD3;saved=LD3;
    try
        LD3=struct("cfg",cfg,"wires",wires,"powerOn",%t,"switchOn",%t,"voltage",t.voltage);
        [u,i,ok,message]=ld3_measure_values();
        r=mo36_reading(u,i,ok,message,"LD3");
    catch
        message=lasterror();LD3=saved;error(strcat(message," "));
    end
    LD3=saved;
endfunction

function lines=mo_analysis_3(cfg,records)
    mo36_require_records(records,3,"LD3");u=zeros(3,1);i=zeros(3,1);
    lines="Atlikti trys to paties rezistoriaus bandymai. Keitėsi tik automatiškai nustatyta šaltinio įtampa; grandinės sujungimas liko tas pats.";
    for k=1:3
        u(k)=mo36_record_value(records(k),"U");i(k)=mo36_record_value(records(k),"I");
        lines($+1)=string(k)+" bandymas: voltmetras "+mo_num(u(k))+" V, ampermetras "+mo_num(i(k))+" mA.";
    end
    if or(i==0) | u(1)==0 then
        lines($+1)="Dalis rodmenų yra nuliniai. Iš jų negalima patikimai apskaičiuoti varžos ar srovių santykių; šie duomenys nepatvirtina įprasto Omo dėsnio palyginimo.";return;
    end
    resistance=1000*u./i;
    lines($+1)="Programa apskaičiavo: antro bandymo įtampa padidėjo "+mo_num(u(2)/u(1))+" karto, srovė – "+mo_num(i(2)/i(1))+" karto. Trečio bandymo atitinkami santykiai: "+mo_num(u(3)/u(1))+" ir "+mo_num(i(3)/i(1))+" karto.";
    lines($+1)="Programos apskaičiuotos varžos iš U ir I rodmenų: "+mo_num(resistance(1))+" Ω; "+mo_num(resistance(2))+" Ω; "+mo_num(resistance(3))+" Ω. Tai apskaičiuoti dydžiai, ne papildomi prietaisų rodmenys.";
    if max(resistance)-min(resistance)<=1e-7*max(1,max(abs(resistance))) then
        lines($+1)="Išvada: didinant įtampą srovė padidėjo tiek pat kartų, o to paties rezistoriaus varža liko pastovi. Rodmenys patvirtina Omo dėsnį.";
    else
        lines($+1)="Išvada: iš pateiktų rodmenų gautos varžos nesutampa; šie duomenys nepatvirtina pastovios varžos ryšio.";
    end
endfunction

function p=mo_protocol_4(cfg)
    components=list( ...
        mo36_component("Maitinimo šaltinis",["E_N";"E_P"],["−";"+"]), ...
        mo36_component("Jungiklis",["K1";"K2"],["1";"2"]), ...
        mo36_component("Ampermetras",["A_P";"A_N"],["+";"−"]), ...
        mo36_component("Rezistorius R1",["R1A";"R1B"],["a";"b"]), ...
        mo36_component("Rezistorius R2",["R2A";"R2B"],["a";"b"]), ...
        mo36_component("Voltmetras",["V_P";"V_N"],["+";"−"]));
    trials=list();
    for mode=1:2
        for k=1:3
            voltage=cfg("U"+string(k));n=(mode-1)*3+k;
            if mode==1 then why="Matuojame pirmą rezistorių prie trijų automatiškai nustatytų įtampų. Taip patikrinsime, ar jo varža išlieka ta pati.";
            else why="Dabar tomis pačiomis trimis įtampomis tiriame antrą rezistorių. Tai leis palyginti skirtingų rezistorių sroves tomis pačiomis sąlygomis.";end
            if k>1 then why="Laidai lieka tie patys; programa pakeitė tik įtampą. Lyginsime šio rezistoriaus srovę su ankstesniu jo bandymu.";end
            t=mo36_trial("r"+string(mode)+"u"+string(k),string(n)+" bandymas · R"+string(mode)+" · "+mo_num(voltage)+" V", ...
                "Automatiškai nustatyta "+mo_num(voltage)+" V įtampa; matuojamas rezistorius R"+string(mode)+".", ...
                why,"ld4-r"+string(mode),ld4_canonical_wires(mode),voltage);
            t.mode=mode;t.model_step=mode+1;t.voltage=voltage;trials($+1)=t;
        end
    end
    t=mo36_trial("series","7 bandymas · R1 ir R2 nuosekliai", ...
        "Automatiškai nustatyta "+mo_num(cfg.U3)+" V įtampa. Dabar R1 ir R2 sujungiami nuosekliai.", ...
        "Palyginsime abiejų rezistorių nuoseklų jungimą su atskirais rezistoriais. Iš rodmenų programa parodys, kad nuosekliai sujungtų rezistorių varžos sudedamos.", ...
        "ld4-series",ld4_canonical_wires("S"),cfg.U3);
    t.mode="S";t.model_step=6;t.voltage=cfg.U3;trials($+1)=t;
    p=struct("lab","LD4","title","Dviejų rezistorių tyrimas","aim", ...
        "Iš prietaisų rodmenų palyginame du rezistorius ir jų nuoseklų jungimą. Jums skaičiuoti nereikia: programa pati nustato įtampas, apdoroja rodmenis ir parengia išvadą.", ...
        "background",["R1 ir R2 pirmiausia tiriami atskirai prie tų pačių trijų įtampų. Tada atliekamas vienas jų nuoseklaus jungimo bandymas."; ...
        "Kol keičiasi tik įtampa, laidai lieka tie patys. Kai keičiasi tiriamas rezistorius ar jungimo būdas, stendas paprašo sujungti naują schemą."], ...
        "trials",trials,"components",components,"xlabel","Šaltinio įtampa, V");
endfunction

function r=mo_measure_4(cfg,t,wires)
    if ~mo_wires_equal(wires,t.wires) then error("LD4: laidai neatitinka šio rezistoriaus bandymo schemos.");end
    global LD4;saved=LD4;
    try
        LD4=struct("cfg",cfg,"wires",wires,"powerOn",%t,"switchOn",%t,"voltage",t.voltage,"step",t.model_step,"wireMode",t.mode);
        [u,i,ok,message]=ld4_measure_values();
        r=mo36_reading(u,i,ok,message,"LD4");
    catch
        message=lasterror();LD4=saved;error(strcat(message," "));
    end
    LD4=saved;
endfunction

function lines=mo_analysis_4(cfg,records)
    mo36_require_records(records,7,"LD4");u=zeros(7,1);i=zeros(7,1);
    lines="Pirmi trys bandymai atlikti su R1, kiti trys – su R2 tomis pačiomis įtampomis. Septintas bandymas atliktas su abiem rezistoriais, sujungtais nuosekliai.";
    for k=1:7
        u(k)=mo36_record_value(records(k),"U");i(k)=mo36_record_value(records(k),"I");
        lines($+1)=records(k).trial.title+": U = "+mo_num(u(k))+" V; I = "+mo_num(i(k))+" mA.";
    end
    if or(i==0) then lines($+1)="Bent vienas srovės rodmuo nulinis; iš visų bandymų negalima patikimai apskaičiuoti varžų palyginimo.";return;end
    resistances=1000*u./i;r1=mean(resistances(1:3));r2=mean(resistances(4:6));rs=resistances(7);
    lines($+1)="Programa iš prietaisų rodmenų apskaičiavo vidutines varžas: R1 = "+mo_num(r1)+" Ω, R2 = "+mo_num(r2)+" Ω. Tai programos apskaičiuoti dydžiai, ne papildomi perrašomi rodmenys.";
    lines($+1)="Programos apskaičiuotas nuokrypis nuo nominalo: R1 – "+mo_num(100*(r1/cfg.R1nom-1))+" %, R2 – "+mo_num(100*(r2/cfg.R2nom-1))+" %. Nominalai: "+mo_num(cfg.R1nom)+" Ω ir "+mo_num(cfg.R2nom)+" Ω.";
    lines($+1)="Iš nuoseklaus jungimo rodmenų programa apskaičiavo "+mo_num(rs)+" Ω; atskirų varžų suma yra "+mo_num(r1+r2)+" Ω.";
    if abs(rs-r1-r2)<=1e-7*max(1,abs(rs)) then
        lines($+1)="Išvada: nuosekliai sujungtų rezistorių varžos susideda. Prie tos pačios įtampos didesnės bendros varžos grandine teka mažesnė srovė.";
    else lines($+1)="Išvada: pateikti nuoseklaus jungimo rodmenys nesutampa su iš atskirų bandymų apskaičiuota varžų suma.";end
endfunction

function p=mo_protocol_5(cfg)
    components=list( ...
        mo36_component("Maitinimo šaltinis",["E_N";"E_P"],["−";"+"]), ...
        mo36_component("Jungiklis",["K1";"K2"],["1";"2"]), ...
        mo36_component("Ampermetras",["A_P";"A_N"],["+";"−"]), ...
        mo36_component("Rezistorius R1",["R1A";"R1B"],["a";"b"]), ...
        mo36_component("Potenciometro aktyvioji dalis",["RVA";"RVB"],["a";"b"]), ...
        mo36_component("Voltmetras",["V_P";"V_N"],["+";"−"]));
    trials=list();
    for k=1:3
        position=cfg("P"+string(k));
        why="Programa nustatė kitą potenciometro padėtį; laidų ir šaltinio įtampos nekeiskite. Palyginsime, kaip nuo šios padėties keičiasi išėjimo įtampa ir grandinės srovė.";
        if k==1 then why="Pirmas įtampos daliklio bandymas. Užfiksuojame išėjimo įtampą ir srovę; kiti du bandymai parodys potenciometro padėties poveikį.";end
        t=mo36_trial("p"+string(k),string(k)+" bandymas · potenciometras "+mo_num(position)+" %", ...
            "Šaltinis automatiškai nustatytas: "+mo_num(cfg.E)+" V. Potenciometro aktyvioji dalis automatiškai nustatyta: "+mo_num(position)+" %.", ...
            why,"ld5-divider",ld5_canonical_wires(),position);
        t.position=k;trials($+1)=t;
    end
    p=struct("lab","LD5","title","Įtampos daliklio tyrimas","aim", ...
        "Stebime, kaip potenciometro padėtis keičia išėjimo įtampą. Visas tris padėtis nustato programa; jūs sujungiate tą pačią grandinę ir perrašote voltmetro bei ampermetro rodmenis.", ...
        "background",["Voltmetras prijungtas prie potenciometro aktyviosios dalies, todėl rodo išėjimo įtampą. Ampermetras rodo visos nuoseklios grandinės srovę."; ...
        "Visuose trijuose bandymuose naudojami tie patys laidai ir tas pats šaltinis. Palyginimą bei išvadą programa parengs iš jūsų užfiksuotų rodmenų."], ...
        "trials",trials,"components",components,"xlabel","Potenciometro aktyvioji dalis, %");
endfunction

function r=mo_measure_5(cfg,t,wires)
    if ~mo_wires_equal(wires,t.wires) then error("LD5: laidai neatitinka įtampos daliklio bandymo schemos.");end
    global LD5;saved=LD5;
    try
        LD5=struct("cfg",cfg,"wires",wires,"powerOn",%t,"switchOn",%t,"position",t.position);
        [u,i,ok,message]=ld5_measure_values();
        r=mo36_reading(u,i,ok,message,"LD5");
    catch
        message=lasterror();LD5=saved;error(strcat(message," "));
    end
    LD5=saved;
endfunction

function lines=mo_analysis_5(cfg,records)
    mo36_require_records(records,3,"LD5");u=zeros(3,1);i=zeros(3,1);
    lines="Visi trys bandymai atlikti su tuo pačiu įtampos dalikliu ir tuo pačiu šaltiniu. Programa keitė tik potenciometro aktyviąją dalį.";
    for k=1:3
        u(k)=mo36_record_value(records(k),"U");i(k)=mo36_record_value(records(k),"I");
        lines($+1)="Padėtis "+mo_num(cfg("P"+string(k)))+" %: išėjimo įtampa "+mo_num(u(k))+" V; srovė "+mo_num(i(k))+" mA.";
    end
    lines($+1)="Programa apskaičiavo, kad nuo pirmos iki trečios padėties išėjimo įtampa pasikeitė "+mo_num(u(3)-u(1))+" V. Šis pokytis yra apskaičiuotas dydis, ne atskiras prietaiso rodmuo.";
    lines($+1)="Programos apskaičiuotos išėjimo įtampos dalys nuo šaltinio įtampos: "+mo_num(100*u(1)/cfg.E)+" %, "+mo_num(100*u(2)/cfg.E)+" % ir "+mo_num(100*u(3)/cfg.E)+" %. Potenciometro padėties procentas ir išėjimo įtampos procentas nėra tas pats dydis.";
    if u(1)<u(2) & u(2)<u(3) & i(1)>i(2) & i(2)>i(3) then
        lines($+1)="Išvada: didinant aktyviąją potenciometro dalį išėjimo įtampa didėjo, o visos grandinės srovė mažėjo. Daliklis leidžia pakeisti išėjimo įtampą nekeičiant šaltinio.";
    else lines($+1)="Išvada: pateikti rodmenys nerodo nuoseklaus išėjimo įtampos didėjimo ir grandinės srovės mažėjimo.";end
endfunction

function p=mo_protocol_6(cfg)
    components=list( ...
        mo36_component("Pirmas šaltinis E1",["E1_N";"E1_P"],["−";"+"]), ...
        mo36_component("Antras šaltinis E2",["E2_N";"E2_P"],["−";"+"]), ...
        mo36_component("Jungiklis",["K1";"K2"],["1";"2"]), ...
        mo36_component("Ampermetras",["A_P";"A_N"],["+";"−"]), ...
        mo36_component("Apkrovos rezistorius",["R_A";"R_B"],["a";"b"]), ...
        mo36_component("Voltmetras",["V_P";"V_N"],["+";"−"]));
    titles=["vienas šaltinis E1";"du šaltiniai nuosekliai suderintai";"du šaltiniai nuosekliai priešpriešiais";"du šaltiniai lygiagrečiai"];
    conditions=["Naudojamas tik E1 = "+mo_num(cfg.E1)+" V šaltinis."; ...
        "E1 = "+mo_num(cfg.E1)+" V ir E2 = "+mo_num(cfg.E2)+" V jungiami nuosekliai taip, kad jų poveikiai susidėtų."; ...
        "E1 = "+mo_num(cfg.E1)+" V ir E2 = "+mo_num(cfg.E2)+" V jungiami nuosekliai priešpriešiais."; ...
        "E1 = "+mo_num(cfg.E1)+" V ir E2 = "+mo_num(cfg.E2)+" V jungiami lygiagrečiai. Modelis įtraukia abiejų šaltinių vidines varžas."];
    why=["Pirmas bandymas yra palyginimo pradžia. Matuojame apkrovos įtampą ir srovę, kai ją maitina vienas šaltinis."; ...
        "Palyginsime šiuos rodmenis su vieno šaltinio bandymu. Šiame jungime abiejų šaltinių poveikiai nukreipti ta pačia kryptimi."; ...
        "Pamatysime, kas pasikeičia apvertus antro šaltinio jungimo kryptį. Minuso ženklas rodmenyje reiškia priešingą atskaitai kryptį; jį reikia perrašyti kartu su skaičiumi."; ...
        "Palyginsime lygiagretų jungimą su nuosekliu. Lygiagrečiai sujungtų šaltinių įtampos nesudedamos; rezultatą lemia abu šaltiniai ir jų vidinės varžos."];
    trials=list();
    for mode=1:4
        t=mo36_trial("mode"+string(mode),string(mode)+" bandymas · "+titles(mode),conditions(mode),why(mode), ...
            "ld6-mode"+string(mode),ld6_canonical_wires(mode),mode);
        t.mode=mode;trials($+1)=t;
    end
    p=struct("lab","LD6","title","Maitinimo šaltinių jungimo tyrimas","aim", ...
        "Palyginame keturis maitinimo šaltinių jungimus pagal tikrus virtualaus voltmetro ir ampermetro rodmenis. Jums reikia sujungti nurodytą schemą ir perrašyti rodmenis; skaičiavimus bei išvadas atlieka programa.", ...
        "background",["Visuose bandymuose naudojamas tas pats apkrovos rezistorius. Keičiasi tik šaltinių jungimo būdas."; ...
        "Voltmetras rodo apkrovos įtampą, ampermetras – apkrovos srovę. Modelis įtraukia šaltinių vidines varžas, todėl apkrovos įtampa nėra tiesiog užrašas ant šaltinio."], ...
        "trials",trials,"components",components,"xlabel","Šaltinių jungimo režimas");
endfunction

function r=mo_measure_6(cfg,t,wires)
    if ~mo_wires_equal(wires,t.wires) then error("LD6: laidai neatitinka šio šaltinių jungimo bandymo schemos.");end
    global LD6;saved=LD6;
    try
        LD6=struct("cfg",cfg,"wires",wires,"powerOn",%t,"switchOn",%t,"wireMode",t.mode);
        [u,i,ok,message,branches]=ld6_measure_values();
        r=mo36_reading(u,i,ok,message,"LD6");
    catch
        message=lasterror();LD6=saved;error(strcat(message," "));
    end
    LD6=saved;
endfunction

function lines=mo_analysis_6(cfg,records)
    mo36_require_records(records,4,"LD6");u=zeros(4,1);i=zeros(4,1);
    lines="Tas pats apkrovos rezistorius išbandytas su vienu šaltiniu, dviem nuosekliai suderintais, dviem nuosekliai priešpriešiniais ir dviem lygiagrečiais šaltiniais.";
    for k=1:4
        u(k)=mo36_record_value(records(k),"U");i(k)=mo36_record_value(records(k),"I");
        lines($+1)=records(k).trial.title+": apkrovos įtampa "+mo_num(u(k))+" V; srovė "+mo_num(i(k))+" mA.";
    end
    lines($+1)="Programos apskaičiuotos nuoseklių šaltinių atstojamosios EVJ: suderintai "+mo_num(cfg.E1+cfg.E2)+" V, priešpriešiais "+mo_num(cfg.E1-cfg.E2)+" V. Tai apskaičiuoti šaltinių dydžiai, ne papildomi prietaisų rodmenys; apkrovos rodmenis taip pat veikia vidinės varžos.";
    equivalent=(cfg.E1/cfg.r1+cfg.E2/cfg.r2)/(1/cfg.r1+1/cfg.r2);internal=1/(1/cfg.r1+1/cfg.r2);
    lines($+1)="Lygiagretaus jungimo programos apskaičiuota atstojamoji EVJ yra "+mo_num(equivalent)+" V, vidinė varža "+mo_num(internal)+" Ω. Lygiagretus jungimas nesuteikia nuoseklaus jungimo įtampų sumos.";
    if u(3)<0 | i(3)<0 then
        lines($+1)="Trečio bandymo neigiamas rodmuo rodo, kad stipresnis priešpriešinis šaltinis pakeitė srovės ir įtampos kryptį pasirinktos prietaisų atskaitos atžvilgiu. Minusas nėra įvedimo klaida.";
    end
    lines($+1)="Išvada: net su ta pačia apkrova šaltinių jungimo būdas keičia įtampą ir srovę. Suderintas ir priešpriešinis nuoseklus jungimas turi skirtingą poveikį; lygiagretaus jungimo rezultatui svarbios abiejų šaltinių vidinės varžos. Visas šis palyginimas parengtas programoje; studentas skaičiuojamų dydžių neįvedė.";
endfunction
