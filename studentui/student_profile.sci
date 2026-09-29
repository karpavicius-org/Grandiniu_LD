// Shared registration and immutable variant identity for both laboratories.
function st=student_empty(lab)
    st=struct("number",0,"name","","group","","variant_id","", "bank",lab+"-64-A-2026");
    if lab=="LD6" then st.bank="LD6-64-B-2026"; end
endfunction

function st=student_profile(number,name,group,lab)
    if type(number)==10 then
        raw=stripblanks(number);
        if size(regexp(raw,"/^[0-9]+$/"),"*")==0 then error("Eilės numerį rašykite skaitmenimis nuo 1 iki 64."); end
        number=strtod(raw);
    end
    if type(number)<>1 then error("Eilės numeris turi būti skaičius."); end
    if size(number,"*")<>1 then error("Įveskite vieną eilės numerį."); end
    if ~isreal(number) then error("Eilės numeris turi būti realus skaičius."); end
    if isnan(number) | isinf(number) then error("Netinkamas eilės numeris."); end
    if number<1 | number>64 | floor(number)<>number then error("Eilės numeris turi būti sveikas nuo 1 iki 64."); end
    name=stripblanks(name); group=stripblanks(group);
    if name=="" then error("Įveskite vardą ir pavardę."); end
    if group=="" then error("Įveskite grupę."); end
    if size(strindex(name,ascii(10)),"*")>0 | size(strindex(name,ascii(13)),"*")>0 then error("Vardas ir pavardė turi būti vienoje eilutėje."); end
    if size(strindex(group,ascii(10)),"*")>0 | size(strindex(group,ascii(13)),"*")>0 then error("Grupė turi būti vienoje eilutėje."); end
    if length(name)>64 then error("Vardas ir pavardė per ilgi (iki 64 ženklų)."); end
    if length(group)>64 then error("Grupės pavadinimas per ilgas (iki 64 ženklų)."); end
    st=struct("number",number,"name",name,"group",group, ...
        "variant_id",msprintf("%s-V%02d",lab,number),"bank",lab+"-64-A-2026");
    if lab=="LD6" then st.bank="LD6-64-B-2026"; end
endfunction

function lines=student_parameter_lines(lab,cfg)
    if lab=="LD1" then
        lines=[msprintf("Šaltinis: %.1f V DC.",cfg.E); ...
            msprintf("R1 = %.0f Ω; R2 = %.0f Ω; R3 = %.0f Ω.",cfg.R1,cfg.R2,cfg.R3); ...
            "VR1 keičiamas pagal etapą: 1000, 500 arba 0 Ω."];
    elseif lab=="LD3" then
        lines=[msprintf("R (tiriamasis rezistorius) = %.0f Ω.",cfg.R); ...
            msprintf("U1 = %.0f V; U2 = %.0f V; U3 = %.0f V (matavimo taškai).",cfg.U1,cfg.U2,cfg.U3)];
    elseif lab=="LD4" then
        lines=[msprintf("R1 nom. = %.0f Ω ±5%%; R2 nom. = %.0f Ω ±5%%.",cfg.R1nom,cfg.R2nom); ...
            msprintf("U1 = %.0f V; U2 = %.0f V; U3 = %.0f V (matavimo taškai).",cfg.U1,cfg.U2,cfg.U3)];
    elseif lab=="LD5" then
        lines=[msprintf("R1 nom. = %.0f Ω ±5%%; RV nom. = %.0f Ω ±5%%; E = %.0f V.",cfg.R1nom,cfg.RVnom,cfg.E); ...
            msprintf("Potenciometro padėtys: %d %%, %d %%, %d %%.",cfg.P1,cfg.P2,cfg.P3)];
    elseif lab=="LD6" then
        lines=[msprintf("E1 = %.0f V (fiksuotas); E2 = %.0f V (pagal variantą).",cfg.E1,cfg.E2); ...
            msprintf("Apkrova R = %.1f Ω (nom. %.0f Ω ±5%%).",cfg.R,cfg.Rnom); ...
            msprintf("Šaltinių vidinės varžos: r1 = %g Ω; r2 = %g Ω.",cfg.r1,cfg.r2); ...
            "Tiriami vienas E1, abu nuosekliai, priešpriešiais ir lygiagrečiai."];
    elseif lab=="LD7" then
        lines=[msprintf("Šaltinis: E = %.0f V (vidinė varža nežymima — nustatysite 3 etape).",cfg.E); ...
            msprintf("Reostato padėtys: P1 = %.1f Ω; P2 = %.1f Ω; P3 = %.1f Ω; P4 = %.1f Ω; P5 = %.1f Ω.",cfg.R1,cfg.R2,cfg.R3,cfg.R4,cfg.R5)];
    elseif lab=="LD8" then
        lines=[msprintf("Šaltinis: E = %.0f V. Trys tiriamieji rezistoriai (nominalai ±5 %%):",cfg.E); ...
            msprintf("R1 = %.1f Ω (nom. %.0f); R2 = %.1f Ω (nom. %.0f); R3 = %.1f Ω (nom. %.0f).",cfg.R1,cfg.R1nom,cfg.R2,cfg.R2nom,cfg.R3,cfg.R3nom)];
    elseif lab=="LD9" then
        lines=[msprintf("Generatorius: E = %.0f V RMS. Nuosekli RLC grandinė:",cfg.E); ...
            msprintf("R = %.2f Ω; L = %g mH; C = %g nF.",cfg.R,cfg.LmH,cfg.CnF); ...
            "Rezonanso dažnį f0 apskaičiuosite pirmajame etape."];
    elseif lab=="LD10" then
        lines=[msprintf("Generatorius: E = %.0f V RMS. Lygiagretė RLC grandinė:",cfg.E); ...
            msprintf("R = %.2f Ω; L = %g mH; C = %g nF.",cfg.R,cfg.LmH,cfg.CnF); ...
            "Rezonanso dažnį f0 apskaičiuosite pirmajame etape."];
    elseif lab=="LD11" then
        lines=[msprintf("Generatorius: E = %.0f V RMS, f = 50 Hz. Rišlė (R, L nuosekliai):",cfg.E); ...
            msprintf("R = %g Ω; L = %g mH. Kompensuojantis kondensatorius Ck stende paruoštas.",cfg.R,cfg.LmH); ...
            "Pradinį cos φ0 ir Ck apskaičiuosite patys."];
    elseif lab=="LD12" then
        lines=[msprintf("Trifazis šaltinis: Ul = %g V, 50 Hz, simetrinis.",cfg.Ul); ...
            msprintf("Trys vienodi imtuvai: R = %g Ω.",cfg.R); ...
            "Jungsime žvaigžde ir trikampiu."];
    else
        lines=[msprintf("RC: %.1f V RMS; %.1f Hz; R8 = %.0f Ω; C2 = %.2f µF.",cfg.E_RC,cfg.F_RC,cfg.R8,cfg.C2*1e6); ...
            msprintf("RL: %.1f V RMS; %.1f Hz; R9 = %.0f Ω; L1 = %.3f H.",cfg.E_RL,cfg.F_RL,cfg.R9,cfg.L1); ...
            msprintf("RLC: %.1f V RMS; R13 = %.0f Ω; L3 = %.0f mH; C4 = %.0f nF.",cfg.E_RLC,cfg.R13,cfg.L3*1e3,cfg.C4*1e9)];
    end
endfunction

function text=student_caption(st)
    text="";
    if st.number>0 then text=st.name+" · "+st.group+" · "+st.variant_id; end
endfunction

function [ok,st,cfg]=student_enroll(lab,previous)
    global BENCH_STUDENT;
    if argn(2)<2 then
        previous=student_empty(lab);
        if typeof(BENCH_STUDENT)=="st" then previous=BENCH_STUDENT; end
    end
    no=""; if previous.number>0 then no=string(previous.number); end
    defaults=[no;previous.name;previous.group]; ok=%f; st=previous; cfg=[];
    while %t
        values=x_mdialog([lab+" · Jūsų duomenys";"Eilės numeris priskiria pastovias stendo reikšmes."], ...
            ["Eilės numeris sąraše (1–64)";"Vardas ir pavardė";"Grupė"],defaults);
        if size(values,"*")==0 then return; end
        defaults=values;
        try
            st=student_profile(values(1),values(2),values(3),lab);
            if lab=="LD1" then cfg=ld1_variant_config(st.number);
            elseif lab=="LD3" then
                cfg=ld3_variant_config(st.number);
                [valid,why]=ld3_validate_config(cfg); if ~valid then error(why); end
            elseif lab=="LD4" then
                cfg=ld4_variant_config(st.number);
                [valid,why]=ld4_validate_config(cfg); if ~valid then error(why); end
            elseif lab=="LD5" then
                cfg=ld5_variant_config(st.number);
                [valid,why]=ld5_validate_config(cfg); if ~valid then error(why); end
            elseif lab=="LD6" then
                cfg=ld6_variant_config(st.number);
                [valid,why]=ld6_validate_config(cfg); if ~valid then error(why); end
            elseif lab=="LD7" then
                cfg=ld7_variant_config(st.number);
                [valid,why]=ld7_validate_config(cfg); if ~valid then error(why); end
            elseif lab=="LD8" then
                cfg=ld8_variant_config(st.number);
                [valid,why]=ld8_validate_config(cfg); if ~valid then error(why); end
            elseif lab=="LD9" then
                cfg=ld9_variant_config(st.number);
                [valid,why]=ld9_validate_config(cfg); if ~valid then error(why); end
            elseif lab=="LD10" then
                cfg=ld10_variant_config(st.number);
                [valid,why]=ld10_validate_config(cfg); if ~valid then error(why); end
            elseif lab=="LD11" then
                cfg=ld11_variant_config(st.number);
                [valid,why]=ld11_validate_config(cfg); if ~valid then error(why); end
            elseif lab=="LD12" then
                cfg=ld12_variant_config(st.number);
                [valid,why]=ld12_validate_config(cfg); if ~valid then error(why); end
            else
                cfg=ld2_variant_config(st.number);
                [valid,why]=ld2_validate_config(cfg); if ~valid then error(why); end
            end
        catch
            messagebox(lasterror(),"Patikrinkite duomenis","error","modal"); continue;
        end
        pick=messagebox([student_caption(st);"";student_parameter_lines(lab,cfg); ...
            "";"Šios reikšmės bus naudojamos visuose darbo etapuose."], ...
            "Jūsų priskirtos reikšmės","info",["Pradėti" "Taisyti"],"modal");
        if pick==1 then ok=%t; return; end
        if pick==0 then return; end
    end
endfunction

function student_remember(st)
    global BENCH_STUDENT;
    BENCH_STUDENT=st;
endfunction

function lines=student_csv_lines(st)
    q=ascii(34);
    function out=quote(txt)
        out=q+strsubst(string(txt),q,q+q)+q;
    endfunction
    lines=["Laukas;Reiksme";"Eiles_numeris;"+string(st.number); ...
        "Vardas_pavarde;"+quote(st.name);"Grupe;"+quote(st.group); ...
        "Variantas;"+quote(st.variant_id);"Variantu_bankas;"+quote(st.bank)];
endfunction
