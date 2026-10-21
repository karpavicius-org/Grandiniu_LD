// Measurement-only protocols. Every instrument value comes from an unchanged
// original native model. Arithmetic results occur only in mo_analysis_N.
function c=mo7_component(name,ids,labels)
    c=struct("name",name,"ids",matrix(ids,-1,1),"labels",matrix(labels,-1,1));
endfunction

function t=mo7_trial(key,title,condition,why,topology,wires,x)
    t=struct("key",key,"title",title,"condition",condition,"why",why, ...
        "topology",topology,"wires",wires,"x",x,"revision","physical-instruments-v5.1");
endfunction

function r=mo7_reading(ids,names,units,values)
    values=matrix(values,-1,1);
    if ~isreal(values) | or(isnan(values)) | or(isinf(values)) then error("Prietaiso modelis nepateikė baigtinių rodmenų.");end
    r=struct("ids",matrix(ids,-1,1),"names",matrix(names,-1,1), ...
        "units",matrix(units,-1,1),"values",values);
endfunction

function mo7_check(wires,t)
    if ~mo_wires_equal(wires,t.wires) then error("Laidai neatitinka šio bandymo. Pataisykite paryškintą jungimą.");end
endfunction

function v=mo7_value(rec,id)
    k=find(rec.reading.ids==id);
    if size(k,"*")<>1 then error("Atlikto bandymo rodmenyse nėra "+id+".");end
    v=rec.reading.values(k);
endfunction

function components=mo7_dc_components(kind)
    components=list(mo7_component("Šaltinis E",["E_P";"E_N"],["+";"−"]), ...
        mo7_component("Jungiklis K",["K1";"K2"],["1";"2"]), ...
        mo7_component("Ampermetras A",["A_P";"A_N"],["+";"−"]));
    if kind==7 then
        components($+1)=mo7_component("Reostatas R",["R_A";"R_B"],["a";"b"]);
    else
        for k=1:3
            components($+1)=mo7_component("Rezistorius R"+string(k),["R"+string(k)+"_A";"R"+string(k)+"_B"],["a";"b"]);
        end
    end
    components($+1)=mo7_component("Voltmetras V",["V_P";"V_N"],["+";"−"]);
endfunction

function components=mo7_ac_components(kind)
    components=list(mo7_component("Generatorius",["GEN_P";"GEN_N"],["+";"−"]), ...
        mo7_component("Jungiklis K",["K1";"K2"],["1";"2"]), ...
        mo7_component("Ampermetras A",["A_P";"A_N"],["+";"−"]));
    if kind==11 then
        components($+1)=mo7_component("Ritė RL",["RL_A";"RL_B"],["a";"b"]);
    else
        components($+1)=mo7_component("Rezistorius R",["R_A";"R_B"],["a";"b"]);
        components($+1)=mo7_component("Ritė L",["L_A";"L_B"],["a";"b"]);
    end
    components($+1)=mo7_component("Kondensatorius C",["C_A";"C_B"],["a";"b"]);
    components($+1)=mo7_component("Voltmetras V",["V_P";"V_N"],["+";"−"]);
    if kind==11 then
        components($+1)=mo7_component("Vatmetro srovės ritė",["W_I_P";"W_I_N"],["I+";"I−"]);
        components($+1)=mo7_component("Vatmetro įtampos ritė",["W_U_P";"W_U_N"],["U+";"U−"]);
    end
endfunction

function p=mo_protocol_7(cfg)
    trials=list();
    for k=1:5
        r=cfg("R"+string(k));
        t=mo7_trial("p"+string(k),"Apkrova P"+string(k), ...
            "Šaltinis E="+mo_num(cfg.E)+" V. Reostatas automatiškai nustatytas: R="+mo_num(r)+" Ω.", ...
            "Matuojame to paties šaltinio apkrovos įtampą ir srovę. P1–P5 didinama apkrovos varža; pabaigoje palyginsime visus penkis rodmenis.", ...
            "ld7_darbine",ld7_canonical_wires(1),r);
        t.mode=1;t.position=k;trials($+1)=t;
    end
    t=mo7_trial("te","Tuščioji eiga", ...
        "Šaltinis E="+mo_num(cfg.E)+" V. Prijungtas tik voltmetras; modelio voltmetro varža 1 MΩ.", ...
        "Matuojame beveik neapkrauto šaltinio įtampą. Ampermetras šiame jungime nedalyvauja, todėl jo rodmens neprašome.", ...
        "ld7_tuscioji",ld7_canonical_wires(2),1e6);t.mode=2;t.position=0;trials($+1)=t;
    t=mo7_trial("tj","Virtualus trumpasis jungimas", ...
        "Tai kompiuterinio modelio bandymas. Išorinė varža 1 µΩ; srovę riboja šaltinio vidinė varža.", ...
        "Matuojame tik virtualaus ampermetro srovę. Realiame fiziniame šaltinyje šio jungimo nekartokite.", ...
        "ld7_virtualus_tj",ld7_canonical_wires(3),1e-6);t.mode=3;t.position=0;trials($+1)=t;
    p=struct("lab","LD7","title","Šaltinis ir apkrova","aim","Sujunkite grandinę ir palyginkite šaltinio įtampą bei srovę keičiant apkrovą.", ...
        "background",["Šaltinio įtampa apkrovus gali sumažėti. Keisdami išorinę varžą stebime, kaip kartu keičiasi įtampa ir srovė.";"Penkiose apkrovos padėtyse laidai tie patys. Tuščiajai eigai ir virtualiam trumpajam jungimui reikalingi atskiri sujungimai."], ...
        "trials",trials,"components",mo7_dc_components(7),"xlabel","Apkrovos varža, Ω");
endfunction

function r=mo_measure_7(cfg,t,wires)
    mo7_check(wires,t);global LD7;
    LD7=struct("cfg",cfg,"wires",wires,"wireMode",t.mode,"position",t.position,"powerOn",%t,"switchOn",%t);
    [u,i,ok,why,load]=ld7_measure_values();if ~ok then error(why);end
    select t.mode
    case 1 then r=mo7_reading(["U";"I"],["Voltmetro rodmuo";"Ampermetro rodmuo"],["V";"mA"],[u;i]);
    case 2 then r=mo7_reading("U0","Voltmetro rodmuo be apkrovos","V",u);
    case 3 then r=mo7_reading("Ik","Virtualaus ampermetro rodmuo","mA",i);
    end
endfunction

function lines=mo_analysis_7(cfg,records)
    u1=mo7_value(records(1),"U");i1=mo7_value(records(1),"I");u5=mo7_value(records(5),"U");i5=mo7_value(records(5),"I");
    r=1000*(u5-u1)/(i1-i5);powers=zeros(1,5);
    for k=1:5;powers(k)=mo7_value(records(k),"U")*mo7_value(records(k),"I");end
    [peak,k]=max(powers);up=mo7_value(records(k),"U");
    lines=["Padidinus apkrovą nuo "+mo_num(cfg.R1)+" iki "+mo_num(cfg.R5)+" Ω, srovė sumažėjo nuo "+mo_num(i1)+" iki "+mo_num(i5)+" mA, o apkrovos įtampa padidėjo nuo "+mo_num(u1)+" iki "+mo_num(u5)+" V. Didesnė srovė sukelia didesnį įtampos kritimą šaltinio viduje."; ...
        "Iš dviejų matavimų apskaičiuota vidinę varžą r=1000·(U5−U1)/(I1−I5)="+mo_num(r)+" Ω."; ...
        "Apskaičiuotos apkrovų galios P=U·I. Didžiausia tarp penkių bandymų galia "+mo_num(peak)+" mW gauta P"+string(k)+" padėtyje, kai R="+mo_num(cfg("R"+string(k)))+" Ω. Ši apkrova artima apskaičiuotai vidinei varžai."; ...
        "Šiame taške apskaičiuotas naudingumas η=100·U/E="+mo_num(100*up/cfg.E)+" %. Didžiausios galios taške dalis galios vis tiek išsiskiria šaltinio viduje."; ...
        "Atskirai išmatuota beveik neapkrauto šaltinio U0="+mo_num(mo7_value(records(6),"U0"))+" V ir tik virtualaus trumpojo jungimo srovė Ik="+mo_num(mo7_value(records(7),"Ik"))+" mA."];
endfunction

function p=mo_protocol_8(cfg)
    modes=["Nuosekliai";"Lygiagrečiai";"Mišriai"];trials=list();
    for mode=1:3
        for target=0:3
            label="Visa grandinė";purpose="Išmatuokite bendrą įtampą ir šaltinio srovę.";
            if target>0 then
                label="Rezistorius R"+string(target);
                purpose="Voltmetras prie R"+string(target)+", ampermetras jo srovės kelyje.";
            end
            plan=ld8_instrument_plan(mode,target);
            t=mo7_trial("m"+string(mode)+"r"+string(target),modes(mode)+" · "+label, ...
                "E="+mo_num(cfg.E)+" V; R1="+mo_num(cfg.R1)+", R2="+mo_num(cfg.R2)+", R3="+mo_num(cfg.R3)+" Ω.", ...
                purpose,"ld8_mode"+string(mode),plan.wires,mode);
            t.mode=mode;t.target=target;t.purpose=purpose;trials($+1)=t;
        end
    end
    p=struct("lab","LD8","title","Rezistorių įtampos ir srovės","aim","Sujunkite tris grandines, išmatuokite visą grandinę ir kiekvieną rezistorių.", ...
        "background",["Keisdami jungimą, palyginsime tų pačių rezistorių įtampas ir sroves.";"Voltmetro zondai jungiami abipus elemento; ampermetras įjungiamas nuosekliai į matuojamos srovės kelią."], ...
        "trials",trials,"components",mo7_dc_components(8),"xlabel","Jungimas: 1 nuoseklusis, 2 lygiagretusis, 3 mišrusis");
endfunction

function r=mo_measure_8(cfg,t,wires)
    mo7_check(wires,t);global LD8;
    LD8=struct("cfg",cfg,"wires",wires,"wireMode",t.mode,"powerOn",%t,"switchOn",%t);
    [u,i,ok,why]=ld8_measure_values();if ~ok then error(why);end
    if t.target==0 then
        r=mo7_reading(["U";"I"],["Bendros įtampos voltmetras";"Bendros srovės ampermetras"],["V";"mA"],[u;i]);
    else
        id=string(t.target);uname="Voltmetro rodmuo prie R"+id;iname="Ampermetro rodmuo R"+id+" kelyje";
        if t.mode==1 | (t.mode==3 & t.target==1) then
            r=mo7_reading("U"+id,uname,"V",u);
        else r=mo7_reading(["U"+id;"I"+id],[uname;iname],["V";"mA"],[u;i]);end
    end
endfunction

function lines=mo_analysis_8(cfg,records)
    u=zeros(1,3);i=u;rt=u;sumu=u;
    for k=1:3
        b=4*(k-1);u(k)=mo7_value(records(b+1),"U");i(k)=mo7_value(records(b+1),"I");rt(k)=1000*u(k)/i(k);
        sumu(k)=mo7_value(records(b+2),"U1")+mo7_value(records(b+3),"U2")+mo7_value(records(b+4),"U3");
    end
    ip=mo7_value(records(6),"I1")+mo7_value(records(7),"I2")+mo7_value(records(8),"I3");
    im=mo7_value(records(11),"I2")+mo7_value(records(12),"I3");
    lines=["Bendros srovės: nuosekliai "+mo_num(i(1))+", lygiagrečiai "+mo_num(i(2))+", mišriai "+mo_num(i(3))+" mA. Apskaičiuotos Rt=1000·U/I: "+mo_num(rt(1))+", "+mo_num(rt(2))+", "+mo_num(rt(3))+" Ω."; ...
        "Nuosekliai tas pats srovės kelias eina per R1, R2 ir R3. Išmatuotų įtampų suma U1+U2+U3="+mo_num(sumu(1))+" V sutampa su šaltinio U="+mo_num(u(1))+" V."; ...
        "Lygiagrečiai kiekvieno rezistoriaus įtampa lygi šaltinio įtampai. Atskirai išmatuotų šakų srovių suma I1+I2+I3="+mo_num(ip)+" mA sutampa su bendrąja I="+mo_num(i(2))+" mA."; ...
        "Mišriai R1 teka visa šaltinio srovė, paskui ji pasidalija į R2 ir R3. I2+I3="+mo_num(im)+" mA sutampa su bendrąja I="+mo_num(i(3))+" mA. R2 ir R3 įtampos vienodos."];
endfunction

function p=mo_protocol_9(cfg)
    f0=1/(2*%pi*sqrt(cfg.L*cfg.C));factors=[.5 1 2];titles=["Žemiau rezonanso";"Rezonansas";"Aukščiau rezonanso"];
    targets=["UR prie rezistoriaus";"UL prie ritės";"UC prie kondensatoriaus";"Generatoriaus įtampa su prijungta apkrova"];trials=list();
    purposes=["Matuojame rezistoriaus įtampą, kuri parodo bendros srovės pokytį."; ...
        "Matuojame ritės įtampą, kad palygintume ją su kondensatoriaus įtampa."; ...
        "Matuojame kondensatoriaus įtampą ir stebime jos kitimą didinant dažnį."; ...
        "Matuojame generatoriaus įtampą su prijungta apkrova kaip palyginimo pagrindą."];
    for k=1:3
        for target=1:4
            f=factors(k)*f0;plan=ld9_instrument_plan(target);
            t=mo7_trial("f"+string(k)+"t"+string(target),titles(k)+" · "+targets(target), ...
                "f="+mo_num(f)+" Hz, generatorius U="+mo_num(cfg.E)+" V.", ...
                purposes(target)+" Perjunkite V zondus į nurodyto elemento gnybtus; A lieka viename srovės kelyje.","ld9_rlc",plan.wires,f);
            t.freqPoint=k;t.target=target;t.purpose=purposes(target);trials($+1)=t;
        end
    end
    p=struct("lab","LD9","title","Nuosekliosios RLC grandinės rezonansas","aim","Sujunkite tikrus prietaisų laidus ir perrašykite rodmenis trijuose dažniuose.", ...
        "background",["Dažnis keičiamas iš 0,5·f0 į f0 ir 2·f0: palyginsime rodmenis prieš rezonansą, ties juo ir po jo.";"Perjunkite V zondus į nurodyto elemento gnybtus; A lieka viename srovės kelyje.";"Srovę kiekviename dažnyje perrašykite tik su pirmu matavimu."], ...
        "trials",trials,"components",mo7_ac_components(9),"xlabel","Dažnis, Hz");
endfunction

function r=mo_measure_9(cfg,t,wires)
    mo7_check(wires,t);global LD9;
    LD9=struct("cfg",cfg,"wires",wires,"freqPoint",t.freqPoint,"target",t.target,"powerOn",%t,"switchOn",%t);
    [u,i,ok,why]=ld9_measure_values();if ~ok then error(why);end
    ids=["UR";"UL";"UC";"U"];names=["Voltmetro rodmuo ties rezistoriumi";"Voltmetro rodmuo ties rite";"Voltmetro rodmuo ties kondensatoriumi";"Generatoriaus įtampa su prijungta apkrova"];
    if t.target==1 then r=mo7_reading(["UR";"I"],[names(1);"Ampermetro rodmuo"],["V";"mA"],[u;i]);
    else r=mo7_reading(ids(t.target),names(t.target),"V",u);end
    r.wave=mo7_ac_wave(9,cfg,t);
endfunction

function lines=mo_analysis_9(cfg,records)
    i=zeros(1,3);ul=i;uc=i;ur=i;
    for k=1:3
        base=4*(k-1);i(k)=mo7_value(records(base+1),"I");ur(k)=mo7_value(records(base+1),"UR");ul(k)=mo7_value(records(base+2),"UL");uc(k)=mo7_value(records(base+3),"UC");
    end
    lines=["Didinant dažnį nuo 0,5·f0 per f0 iki 2·f0, srovė buvo "+mo_num(i(1))+", "+mo_num(i(2))+", "+mo_num(i(3))+" mA. Iš trijų bandymų didžiausia srovė ties f0 – nuosekliosios grandinės rezonansu."; ...
        "Ties f0 išmatuota UL="+mo_num(ul(2))+" V ir UC="+mo_num(uc(2))+" V. Jų moduliai sutampa, bet poveikiai priešingi, todėl kompensuojasi; rezistoriaus UR="+mo_num(ur(2))+" V tampa artima generatoriaus įtampai."; ...
        "Žemiau f0: UL="+mo_num(ul(1))+" V, UC="+mo_num(uc(1))+" V – vyrauja kondensatoriaus poveikis. Aukščiau f0: UL="+mo_num(ul(3))+" V, UC="+mo_num(uc(3))+" V – vyrauja ritės poveikis."; ...
        "Keitėsi tik dažnis. Todėl rodmenų pokytį siejame su ritės ir kondensatoriaus priklausomybe nuo dažnio, o ne su kita sujungta grandine."];
endfunction

function p=mo_protocol_10(cfg)
    f0=1/(2*%pi*sqrt(cfg.L*cfg.C));factors=[.5 1 2];titles=["Žemiau rezonanso";"Rezonansas";"Aukščiau rezonanso"];
    targets=["IR rezistoriaus šakoje";"IL ritės šakoje";"IC kondensatoriaus šakoje";"I prieš šakotę"];trials=list();
    purposes=["Matuojame rezistoriaus šakos srovę kaip atskaitą kitoms srovėms."; ...
        "Matuojame ritės šakos srovę ir stebime, kaip ji mažėja didinant dažnį."; ...
        "Matuojame kondensatoriaus šakos srovę ir stebime, kaip ji didėja didinant dažnį."; ...
        "Matuojame bendrą šaltinio srovę, kad rastume jos minimumą ties rezonansu."];
    for k=1:3
        for target=1:4
            f=factors(k)*f0;plan=ld10_instrument_plan(target);
            t=mo7_trial("f"+string(k)+"t"+string(target),titles(k)+" · "+targets(target), ...
                "f="+mo_num(f)+" Hz, generatorius U="+mo_num(cfg.E)+" V.", ...
                purposes(target)+" Įjunkite vieną A į nurodytos srovės kelią; V lieka prie generatoriaus.","ld10_rlc",plan.wires,f);
            t.freqPoint=k;t.target=target;t.purpose=purposes(target);trials($+1)=t;
        end
    end
    p=struct("lab","LD10","title","Lygiagrečiosios RLC grandinės rezonansas","aim","Sujunkite tikrus prietaisų laidus ir perrašykite rodmenis trijuose dažniuose.", ...
        "background",["Dažnis keičiamas iš 0,5·f0 į f0 ir 2·f0: palyginsime rodmenis prieš rezonansą, ties juo ir po jo.";"Įjunkite vieną A į nurodytos srovės kelią; V lieka prie generatoriaus.";"Generatoriaus įtampą kiekviename dažnyje perrašykite tik su pirmu matavimu."], ...
        "trials",trials,"components",mo7_ac_components(10),"xlabel","Dažnis, Hz");
endfunction

function r=mo_measure_10(cfg,t,wires)
    mo7_check(wires,t);global LD10;
    LD10=struct("cfg",cfg,"wires",wires,"freqPoint",t.freqPoint,"target",t.target,"powerOn",%t,"switchOn",%t);
    [u,i,ok,why]=ld10_measure_values();if ~ok then error(why);end
    ids=["IR";"IL";"IC";"I"];names=["Ampermetro rodmuo rezistoriaus šakoje";"Ampermetro rodmuo ritės šakoje";"Ampermetro rodmuo kondensatoriaus šakoje";"Bendrosios srovės ampermetro rodmuo"];
    if t.target==1 then r=mo7_reading(["IR";"U"],[names(1);"Voltmetro rodmuo"],["mA";"V"],[i;u]);
    else r=mo7_reading(ids(t.target),names(t.target),"mA",i);end
    r.wave=mo7_ac_wave(10,cfg,t);
endfunction

function lines=mo_analysis_10(cfg,records)
    ir=zeros(1,3);il=ir;ic=ir;total=ir;
    for k=1:3
        base=4*(k-1);ir(k)=mo7_value(records(base+1),"IR");il(k)=mo7_value(records(base+2),"IL");ic(k)=mo7_value(records(base+3),"IC");total(k)=mo7_value(records(base+4),"I");
    end
    lines=["Didinant dažnį nuo 0,5·f0 per f0 iki 2·f0, bendroji srovė buvo "+mo_num(total(1))+", "+mo_num(total(2))+", "+mo_num(total(3))+" mA. Iš trijų bandymų mažiausia bendroji srovė ties f0 – lygiagrečiosios grandinės rezonansu."; ...
        "Ties f0 išmatuota IL="+mo_num(il(2))+" mA ir IC="+mo_num(ic(2))+" mA. Priešingi reaktyvieji poveikiai kompensuojasi. Bendroji srovė "+mo_num(total(2))+" mA artima rezistoriaus šakos IR="+mo_num(ir(2))+" mA."; ...
        "Žemiau f0 IL="+mo_num(il(1))+" mA ir IC="+mo_num(ic(1))+" mA; aukščiau f0 IL="+mo_num(il(3))+" mA ir IC="+mo_num(ic(3))+" mA. Didinant dažnį ritės srovė mažėja, o kondensatoriaus didėja."; ...
        "Šakų srovių modulių paprastai negalima tiesiog sudėti: svarbūs jų fazių skirtumai. Rezonansas nekeičia laidų – jį atskleidžia dažnio ir srovių palyginimas."];
endfunction

function p=mo_protocol_11(cfg)
    factors=[0 .5 1 2];names=["Be kondensatoriaus";"Dalinė kompensacija";"Artima kompensacija";"Padidinta talpa"];trials=list();
    for k=1:4
        c=factors(k)*cfg.Ck;mode=2;if k==1 then mode=1;end
        plan=ld11_instrument_plan(mode);
        t=mo7_trial("c"+string(k-1),names(k)+" · U, I ir P", ...
            "U="+mo_num(cfg.E)+" V, f=50 Hz; C="+mo_num(c*1e6)+" µF.", ...
            "Palyginkite srovę ir aktyviąją galią, palaipsniui didinant lygiagrečią talpą.", ...
            "ld11_mode"+string(mode),plan.wires,c*1e6);
        t.mode=mode;t.capFactor=factors(k);t.capacitance=c;t.purpose="Išmatuokite U, I ir P su nurodyta talpa.";trials($+1)=t;
    end
    p=struct("lab","LD11","title","Galios faktoriaus gerinimas","aim","Palyginkite keturis tos pačios ritės kompensavimo režimus.", ...
        "background",["A ir vatmetro srovės ritė įjungti nuosekliai prieš apkrovos šakotę. V ir vatmetro įtampos ritė prijungti lygiagrečiai.";"Talpa ruošiama automatiškai: be C, 0,5·Ck, Ck ir 2·Ck. Patikrinsime ir per didelės talpos poveikį."], ...
        "trials",trials,"components",mo7_ac_components(11),"xlabel","Kondensatoriaus talpa, µF");
endfunction

function r=mo_measure_11(cfg,t,wires)
    mo7_check(wires,t);global LD11;
    actualCfg=cfg;actualCfg.Ck=t.capacitance;
    LD11=struct("cfg",actualCfg,"wires",wires,"wireMode",t.mode,"powerOn",%t,"switchOn",%t);
    [u,i,ok,why,p]=ld11_measure_values();if ~ok then error(why);end
    r=mo7_reading(["U";"I";"P"],["Voltmetro rodmuo";"Ampermetro rodmuo";"Vatmetro aktyvioji galia"],["V";"mA";"mW"],[u;i;p]);
    r.wave=mo7_ac_wave(11,actualCfg,t);
endfunction

function lines=mo_analysis_11(cfg,records)
    currents=zeros(1,4);powers=currents;cosphi=currents;q=currents;caps=currents;
    xl=2*%pi*50*cfg.L;
    for k=1:4
        u=mo7_value(records(k),"U");currents(k)=mo7_value(records(k),"I");powers(k)=mo7_value(records(k),"P");
        cosphi(k)=powers(k)/(u*currents(k));caps(k)=records(k).trial.capacitance;
        q(k)=1000*u^2*(xl/(cfg.R^2+xl^2)-2*%pi*50*caps(k));
    end
    lines=["Didinant C nuo 0 iki 0,5·Ck, Ck ir 2·Ck, išmatuotos srovės "+mo_num(currents(1))+", "+mo_num(currents(2))+", "+mo_num(currents(3))+", "+mo_num(currents(4))+" mA. Aktyvioji ritės galia išlieka "+mo_num(powers(1))+" mW."; ...
        "Apskaičiuotas galios faktorius cos φ=P/(U·I): "+mo_num(cosphi(1))+", "+mo_num(cosphi(2))+", "+mo_num(cosphi(3))+", "+mo_num(cosphi(4))+". Artima kompensacija sumažina šaltinio srovę; per didelė talpa ją vėl padidina."; ...
        "Reaktyvioji apkrovos galia Q=U²·(XL/(R²+XL²)−ωC): "+mo_num(q(1))+", "+mo_num(q(2))+", "+mo_num(q(3))+", "+mo_num(q(4))+" mvar. Teigiama Q reiškia induktyvų poveikį, neigiama – talpinį."; ...
        "Ck apvalinta iki 0,01 µF, todėl artimos kompensacijos Q likutis gali būti mažas abiejų ženklų. Didinant talpą ženklas išlaikomas: perkompensavimo negalima paslėpti moduliu."; ...
        "S=U·I, cos φ=P/S. Kompensacija sumažina reaktyviosios energijos mainus su šaltiniu, bet nekeičia tos pačios ritės aktyviojo darbo."];
endfunction

function p=mo_protocol_12(cfg)
    trials=list();modes=["Žvaigždė";"Trikampis"];kinds=["phase";"line"];labels=["fazės Uf ir If";"linijos Ul ir Il"];
    for mode=1:2
        for k=1:2
            measurement=kinds(k);plan=ld12_instrument_plan(mode,measurement);key="y";if mode==2 then key="d";end
            why="A įjungtas į R1 šaką, V zondai abipus R1: matuojama vieno imtuvo fazė.";
            if k==2 then why="A įjungtas į L1 prieš šakotę, V zondai tarp L1 ir L2: matuojama linija.";end
            t=mo7_trial(key+"_"+measurement,modes(mode)+" · "+labels(k), ...
                "Ul="+mo_num(cfg.Ul)+" V, f=50 Hz; trys vienodi R="+mo_num(cfg.R)+" Ω.",why, ...
                "ld12_mode"+string(mode),plan.wires,mode);
            t.mode=mode;t.measurement=measurement;t.phase=1;t.purpose=why;trials($+1)=t;
        end
    end
    components=list(mo7_component("Trifazis šaltinis",["L1";"L2";"L3";"N"],["L1";"L2";"L3";"N"]));
    for k=1:3;components($+1)=mo7_component("Imtuvas R"+string(k),["R"+string(k)+"_A";"R"+string(k)+"_B"],["a";"b"]);end
    components($+1)=mo7_component("Ampermetras A",["A_P";"A_N"],["+";"−"]);
    components($+1)=mo7_component("Voltmetras V",["V_P";"V_N"],["+";"−"]);
    p=struct("lab","LD12","title","Žvaigždė ir trikampis: fazė bei linija","aim","Išmatuokite fazės ir linijos įtampą bei srovę abiem jungimais.", ...
        "background",["Uf – įtampa abipus vieno imtuvo, If – jo srovė. Ul – įtampa tarp dviejų linijų, Il – srovė prieš linijos šakotę.";"Imtuvai vienodi, šaltinis simetrinis. Prietaisus perkelsime į tikrą matavimo vietą ir palyginsime fazinius bei linijinius dydžius."], ...
        "trials",trials,"components",components,"xlabel","Jungimas: 1 žvaigždė, 2 trikampis");
endfunction

function r=mo_measure_12(cfg,t,wires)
    mo7_check(wires,t);global LD12;
    LD12=struct("cfg",cfg,"wires",wires,"wireMode",t.mode,"phase",1,"measurement",t.measurement,"powerOn",%t,"switchOn",%t);
    [u,i,ok,why]=ld12_measure_values();if ~ok then error(why);end
    if t.measurement=="phase" then
        r=mo7_reading(["Uf";"If"],["R1 fazinės įtampos voltmetras";"R1 fazinės srovės ampermetras"],["V";"mA"],[u;i]);
    else r=mo7_reading(["Ul";"Il"],["Linijinės įtampos voltmetras";"L1 linijinės srovės ampermetras"],["V";"mA"],[u;i]);end
    r.wave=mo7_ac_wave(12,cfg,t);
endfunction

function lines=mo_analysis_12(cfg,records)
    uy=mo7_value(records(1),"Uf");iy=mo7_value(records(1),"If");uly=mo7_value(records(2),"Ul");ily=mo7_value(records(2),"Il");
    ud=mo7_value(records(3),"Uf");id=mo7_value(records(3),"If");uld=mo7_value(records(4),"Ul");ild=mo7_value(records(4),"Il");
    py=3*uy*iy;pd=3*ud*id;
    lines=["Žvaigždėje išmatuota Uf="+mo_num(uy)+" V, Ul="+mo_num(uly)+" V; If="+mo_num(iy)+" mA, Il="+mo_num(ily)+" mA. Ul/Uf="+mo_num(uly/uy)+"≈√3, o linijos ir fazės srovės vienodos."; ...
        "Trikampyje išmatuota Uf="+mo_num(ud)+" V, Ul="+mo_num(uld)+" V; If="+mo_num(id)+" mA, Il="+mo_num(ild)+" mA. Uf=Ul, o Il/If="+mo_num(ild/id)+"≈√3."; ...
        "Trikampio linijoje A matuoja dviejų imtuvų srovių vektorinį skirtumą. Todėl Il nėra nei vienos šakos If, nei paprasta dviejų modulių suma."; ...
        "Iš simetrijos apskaičiuota bendra aktyvioji galia P=3·Uf·If: PY="+mo_num(py)+" mW, PΔ="+mo_num(pd)+" mW, santykis PΔ/PY="+mo_num(pd/py)+"≈3. Šaltinio Ul ir visų R nekeitėme."];
endfunction

// Exact same native-model phasors used for the report oscillograms.
// SI RMS; positive phase leads source U. No extra measurement rows are created.
function wave=mo7_ac_wave(lab,cfg,t)
    if or(lab==[9 10]) then
        frequency=t.x;kind=3;if lab==10 then kind=4;end
        v=bench_cpp_ac(kind,cfg.E,frequency,cfg.R,cfg.L,cfg.C);ip=-v(10);
        if lab==9 then
            labels=["U";"I";"UR";"UL";"UC"];units=["V";"A";"V";"V";"V"];
            rms=[cfg.E;v(4);v(5);v(6);v(7)];phase=[0;ip;ip;ip+90;ip-90];
        else
            labels=["U";"I";"IR";"IL";"IC"];units=["V";"A";"A";"A";"A"];
            rms=[cfg.E;v(4);v(5);v(6);v(7)];phase=[0;ip;0;-90;90];
        end
    elseif lab==11 then
        frequency=50;v=bench_cpp_ac(5,cfg.E,frequency,cfg.R,cfg.L,cfg.Ck);
        labels=["U";"I";"IRL";"IC"];units=["V";"A";"A";"A"];
        rms=[cfg.E;v(4);v(5);v(10)];phase=[0;v(9);-atan(2*%pi*frequency*cfg.L/cfg.R)*180/%pi;90];
    else
        frequency=50;v=bench_cpp_ac(6,cfg.Ul,frequency,cfg.R,1,1);uf=v(1);ifA=v(2)/1000;p=0;
        if t.mode==2 then uf=v(3);ifA=v(4)/1000;p=30;end
        labels=["Uf";"If";"U1";"U2";"U3"];units=["V";"A";"V";"V";"V"];
        rms=[uf;ifA;v(1);v(1);v(1)];phase=[p;p;0;-120;120];
    end
    wave=struct("frequency",frequency,"labels",labels,"units",units,"rms",rms,"phase_deg",phase);
endfunction
