function a=bench_answer(id,raw,unit)
    a=struct("id",id,"raw",string(raw),"unit",unit);
endfunction

function a=bench_observation(id,value,unit)
    a=struct("id",id,"value",value,"unit",unit);
endfunction

function r=bench_report_data(lab)
    global LD1 LD2 LD3 LD4 LD5 LD6 LD7 LD8 LD9 LD10 LD11 LD12;
    answers=list(); observations=list(); evidence=struct(); params=struct();
    mode="learning";practice=%f;
    if lab=="LD1" then
        if LD1.demoMode then error("Grįžkite iš pavyzdžio į savo darbą prieš išsaugodami ataskaitą."); end
        st=LD1.student; cfg=LD1.cfg;
        if isfield(LD1,"assessment") then if LD1.assessment then mode="assessment"; end; end
        if isfield(LD1,"practice_used") then practice=LD1.practice_used;end
        specs=["2" "1" "Ohm";"2" "2" "mA";"4" "1" "Ohm";"4" "2" "mA";"6" "1" "Ohm";"8" "1" "mA";"8" "2" "mA";"8" "3" "mA"];
        for k=1:size(specs,1)
            step=bench_safe_number(specs(k,1)); q=bench_safe_number(specs(k,2));
            answers($+1)=bench_answer(msprintf("s%d.q%d",step,q),LD1.stepQ(step,q),specs(k,3));
        end
        for step=[1 5]
            raw=""; if LD1.stepType(step)>0 then raw=string(LD1.stepType(step)); end
            answers($+1)=bench_answer(msprintf("s%d.type",step),raw,"choice");
        end
        for step=[3 4 6 7 8]
            raw=""; if LD1.stepYesNo(step)>0 then raw=string(LD1.stepYesNo(step)); end
            answers($+1)=bench_answer(msprintf("s%d.compare",step),raw,"choice");
            unit="mA"; if step==6 | step==7 then unit="V"; end
            observations($+1)=bench_observation(msprintf("s%d.measure",step),LD1.stepMeas(step),unit);
        end
        params=struct("E",cfg.E,"R1",cfg.R1,"R2",cfg.R2,"R3",cfg.R3);
        evidence.wiring=struct();
        for step=[1 5]
            w=emptystr(0,2); meter="";
            if isfield(LD1,"report_wires") then w=LD1.report_wires(step); meter=LD1.report_meter(step); end
            evidence.wiring(msprintf("s%d",step))=struct("pairs",bench_pairs(w),"meter",meter);
        end
        evidence.realistic=LD1.realistic;
        note="";
        evidence.automatic_calculation=%f;
        if isfield(LD1,"automatic_numbers") then
            evidence.automatic_calculation=LD1.automatic_numbers;
            if LD1.automatic_numbers then note="Skaitines reikšmes apskaičiuoja ir rodmenis įrašo programa. Studentas sujungia grandinę, keičia varžą ir palygina rezultatus."; end
        end
        if isfield(LD1,"guided_used") then
            evidence.automatic_setup=LD1.guided_used;
            if LD1.guided_used then
                note="Stendą paruošė ir matavimus atliko programa. Skaičiavimus ir palyginimus įvedė studentas.";
                if evidence.automatic_calculation then note="Stendą paruošė, skaitines reikšmes apskaičiavo ir rodmenis įrašė programa. Studentas palygino rezultatus."; end
            end
        end
    elseif lab=="LD3" then
        st=LD3.student; cfg=LD3.cfg;
        if isfield(LD3,"assessment") then if LD3.assessment then mode="assessment"; end; end
        if isfield(LD3,"practice_used") then practice=LD3.practice_used; end
        specs=["2" "1" "mA";"4" "1" "Ohm";"4" "2" "Ohm";"4" "3" "Ohm";"4" "4" "Ohm";"5" "1" "Ohm";"6" "1" "choice";"6" "2" "choice"];
        for k=1:size(specs,1)
            step=bench_safe_number(specs(k,1)); q=bench_safe_number(specs(k,2));
            answers($+1)=bench_answer(msprintf("s%d.q%d",step,q),LD3.answers(step,q),specs(k,3));
        end
        if isfield(LD3,"journal") then
            for k=1:min(3,size(LD3.journal,1))
                observations($+1)=bench_observation(msprintf("u%d",k),LD3.journal(k,1),"V");
                observations($+1)=bench_observation(msprintf("i%d",k),LD3.journal(k,2),"mA");
            end
        end
        params=struct("R",cfg.R,"U1",cfg.U1,"U2",cfg.U2,"U3",cfg.U3);
        evidence.wiring=struct("s1",struct("pairs",bench_pairs(LD3.wires),"meter","DC"));
        note="";
    elseif lab=="LD4" then
        if LD4.demoMode then error("Grįžkite iš pavyzdžio į savo darbą prieš išsaugodami ataskaitą."); end
        st=LD4.student; cfg=LD4.cfg;
        if isfield(LD4,"assessment") then if LD4.assessment then mode="assessment"; end; end
        if isfield(LD4,"practice_used") then practice=LD4.practice_used; end
        specs=["2" "1" "mA";"4" "1" "Ohm";"4" "2" "Ohm";"4" "3" "1";"4" "4" "1"; ...
               "5" "1" "Ohm";"5" "2" "Ohm";"5" "3" "mS";"6" "1" "Ohm";"7" "1" "choice";"7" "2" "choice"];
        for k=1:size(specs,1)
            step=bench_safe_number(specs(k,1)); q=bench_safe_number(specs(k,2));
            answers($+1)=bench_answer(msprintf("s%d.q%d",step,q),LD4.answers(step,q),specs(k,3));
        end
        if isfield(LD4,"journal") then
            pref=["r1" "r2" "s"];
            for tag=1:3
                rows=ld4_journal_rows(tag); n=min(3,size(rows,1));
                for k=1:n
                    observations($+1)=bench_observation(msprintf("%su%d",pref(tag),k),rows(k,1),"V");
                    observations($+1)=bench_observation(msprintf("%si%d",pref(tag),k),rows(k,2),"mA");
                end
            end
        end
        params=struct("R1nom",cfg.R1nom,"R2nom",cfg.R2nom,"R1",cfg.R1,"R2",cfg.R2, ...
                      "U1",cfg.U1,"U2",cfg.U2,"U3",cfg.U3);
        evidence.wiring=struct();
        for step=[1 6]
            w=emptystr(0,2);
            if isfield(LD4,"report_wires") then w=LD4.report_wires(step); end
            evidence.wiring("s"+string(step))=struct("pairs",bench_pairs(w),"meter","DC");
        end
        note="";
    elseif lab=="LD5" then
        if isfield(LD5,"demoMode") & LD5.demoMode then error("Grįžkite iš pavyzdžio į savo darbą prieš išsaugodami ataskaitą."); end
        st=LD5.student; cfg=LD5.cfg;
        if isfield(LD5,"assessment") then if LD5.assessment then mode="assessment"; end; end
        if isfield(LD5,"practice_used") then practice=LD5.practice_used; end
        specs=["2" "1" "V";"4" "1" "V";"4" "2" "V";"4" "3" "V";"4" "4" "1"; ...
               "5" "1" "mA";"5" "2" "1";"6" "1" "choice";"6" "2" "choice"];
        for k=1:size(specs,1)
            step=bench_safe_number(specs(k,1)); q=bench_safe_number(specs(k,2));
            answers($+1)=bench_answer(msprintf("s%d.q%d",step,q),LD5.answers(step,q),specs(k,3));
        end
        if isfield(LD5,"journal") & LD5.journal<>[] then
            // Pagal padėtį (1,2,3) — ne pagal matavimo eilę.
            for tag=1:3
                row=find(LD5.journal(:,3)==tag);
                if row<>[] then
                    observations($+1)=bench_observation(msprintf("u%d",tag),LD5.journal(row(1),1),"V");
                    observations($+1)=bench_observation(msprintf("i%d",tag),LD5.journal(row(1),2),"mA");
                end
            end
        end
        params=struct("R1nom",cfg.R1nom,"RVnom",cfg.RVnom,"R1",cfg.R1,"RV",cfg.RV,"E",cfg.E, ...
                      "P1",cfg.P1,"P2",cfg.P2,"P3",cfg.P3);
        w=emptystr(0,2);
        if isfield(LD5,"report_wires") then w=LD5.report_wires(1); end
        evidence.wiring=struct("s1",struct("pairs",bench_pairs(w),"meter","DC"));
        note="";
    elseif lab=="LD6" then
        if isfield(LD6,"demoMode") & LD6.demoMode then error("Grįžkite iš pavyzdžio."); end
        st=LD6.student; cfg=LD6.cfg;
        if isfield(LD6,"assessment") then if LD6.assessment then mode="assessment"; end; end
        if isfield(LD6,"practice_used") then practice=LD6.practice_used; end
        specs=["2" "1" "mA";"4" "1" "V";"4" "2" "mA";"4" "3" "V";"4" "4" "mA"; ...
            "5" "1" "V";"5" "2" "mA";"5" "3" "mA";"5" "4" "mA";"6" "1" "choice";"6" "2" "choice"];
        for k=1:size(specs,1)
            step=bench_safe_number(specs(k,1)); q=bench_safe_number(specs(k,2));
            answers($+1)=bench_answer(msprintf("s%d.q%d",step,q),LD6.answers(step,q),specs(k,3));
        end
        if isfield(LD6,"journal") & LD6.journal<>[] then
            for tag=1:4
                row=find(LD6.journal(:,3)==tag);
                if row<>[] then
                    observations($+1)=bench_observation(msprintf("u%d",tag),LD6.journal(row(1),1),"V");
                    observations($+1)=bench_observation(msprintf("i%d",tag),LD6.journal(row(1),2),"mA");
                    if tag==4 then
                        observations($+1)=bench_observation("parallel_i1",LD6.journal(row(1),4),"mA");
                        observations($+1)=bench_observation("parallel_i2",LD6.journal(row(1),5),"mA");
                    end
                end
            end
        end
        params=struct("E1",cfg.E1,"E2",cfg.E2,"R",cfg.R,"Rnom",cfg.Rnom,"r1",cfg.r1,"r2",cfg.r2);
        evidence.wiring=struct(); stages=[1 3 4 5];
        for mode_index=1:4
            evidence.wiring("s"+string(stages(mode_index)))=struct("pairs",bench_pairs(LD6.report_wires(mode_index)),"meter","DC");
        end
        note="";
    elseif lab=="LD7" then
        if isfield(LD7,"demoMode") & LD7.demoMode then error("Grįžkite iš pavyzdžio į savo darbą prieš išsaugodami ataskaitą."); end
        st=LD7.student; cfg=LD7.cfg;
        if isfield(LD7,"assessment") then if LD7.assessment then mode="assessment"; end; end
        if isfield(LD7,"practice_used") then practice=LD7.practice_used; end
        specs=["3" "1" "Ohm";"3" "2" "V";"4" "1" "mW";"4" "2" "mW";"4" "3" "mW";"4" "4" "mW";"4" "5" "1"; ...
               "5" "1" "V";"5" "2" "mA";"6" "1" "choice";"6" "2" "choice";"6" "3" "choice"];
        for k=1:size(specs,1)
            step=bench_safe_number(specs(k,1)); q=bench_safe_number(specs(k,2));
            answers($+1)=bench_answer(msprintf("s%d.q%d",step,q),LD7.answers(step,q),specs(k,3));
        end
        if isfield(LD7,"journal") & LD7.journal<>[] then
            for tag=1:5
                row=find(LD7.journal(:,3)==tag);
                if row<>[] then
                    observations($+1)=bench_observation(msprintf("u%d",tag),LD7.journal(row(1),1),"V");
                    observations($+1)=bench_observation(msprintf("i%d",tag),LD7.journal(row(1),2),"mA");
                end
            end
            row=find(LD7.journal(:,3)==6);
            if row<>[] then observations($+1)=bench_observation("te_u",LD7.journal(row(1),1),"V"); end
            row=find(LD7.journal(:,3)==7);
            if row<>[] then observations($+1)=bench_observation("tj_i",LD7.journal(row(1),2),"mA"); end
        end
        params=struct("E",cfg.E,"r",cfg.r,"R1",cfg.R1,"R2",cfg.R2,"R3",cfg.R3,"R4",cfg.R4,"R5",cfg.R5);
        evidence.wiring=struct();
        evidence.wiring("s1")=struct("pairs",bench_pairs(LD7.report_wires(1)),"meter","DC");
        evidence.wiring("s5te")=struct("pairs",bench_pairs(LD7.report_wires(2)),"meter","DC");
        evidence.wiring("s5tj")=struct("pairs",bench_pairs(LD7.report_wires(3)),"meter","DC");
        note="";
    elseif lab=="LD8" then
        if isfield(LD8,"demoMode") & LD8.demoMode then error("Grįžkite iš pavyzdžio į savo darbą prieš išsaugodami ataskaitą."); end
        st=LD8.student; cfg=LD8.cfg;
        if isfield(LD8,"assessment") then if LD8.assessment then mode="assessment"; end; end
        if isfield(LD8,"practice_used") then practice=LD8.practice_used; end
        specs=["2" "1" "Ohm";"2" "2" "Ohm";"3" "1" "Ohm";"3" "2" "Ohm"; ...
               "4" "1" "Ohm";"4" "2" "Ohm";"5" "1" "mA";"5" "2" "mA";"5" "3" "mA"; ...
               "6" "1" "choice";"6" "2" "choice";"6" "3" "choice"];
        for k=1:size(specs,1)
            step=bench_safe_number(specs(k,1)); q=bench_safe_number(specs(k,2));
            answers($+1)=bench_answer(msprintf("s%d.q%d",step,q),LD8.answers(step,q),specs(k,3));
        end
        if isfield(LD8,"journal") & LD8.journal<>[] then
            for tag=1:3
                row=find(LD8.journal(:,3)==tag);
                if row<>[] then
                    observations($+1)=bench_observation(msprintf("u%d",tag),LD8.journal(row(1),1),"V");
                    observations($+1)=bench_observation(msprintf("i%d",tag),LD8.journal(row(1),2),"mA");
                end
            end
        end
        params=struct("E",cfg.E,"R1",cfg.R1,"R2",cfg.R2,"R3",cfg.R3);
        evidence.wiring=struct();
        evidence.wiring("s1")=struct("pairs",bench_pairs(LD8.report_wires(1)),"meter","DC");
        evidence.wiring("s3")=struct("pairs",bench_pairs(LD8.report_wires(2)),"meter","DC");
        evidence.wiring("s4")=struct("pairs",bench_pairs(LD8.report_wires(3)),"meter","DC");
        note="";
    elseif lab=="LD9" then
        if isfield(LD9,"demoMode") & LD9.demoMode then error("Grįžkite iš pavyzdžio į savo darbą prieš išsaugodami ataskaitą."); end
        st=LD9.student; cfg=LD9.cfg;
        if isfield(LD9,"assessment") then if LD9.assessment then mode="assessment"; end; end
        if isfield(LD9,"practice_used") then practice=LD9.practice_used; end
        specs=["1" "1" "Hz";"3" "1" "1";"3" "2" "V"; ...
               "5" "1" "V";"5" "2" "Ohm";"5" "3" "1";"5" "4" "mW";"5" "5" "mvar";"5" "6" "mVA"; ...
               "6" "1" "choice";"6" "2" "choice";"6" "3" "choice"];
        for k=1:size(specs,1)
            step=bench_safe_number(specs(k,1)); q=bench_safe_number(specs(k,2));
            answers($+1)=bench_answer(msprintf("s%d.q%d",step,q),LD9.answers(step,q),specs(k,3));
        end
        if isfield(LD9,"journal") & LD9.journal<>[] then
            // 15 stebėjimų: 3 dažnio taškai × (I, UR, UL, UC, U).
            names=["i";"ur";"ul";"uc";"ue"];
            for tag=1:3
                for target=1:4
                    row=find(LD9.journal(:,3)==tag & LD9.journal(:,5)==target);
                    if row<>[] then
                        observations($+1)=bench_observation(names(target+1)+string(tag),LD9.journal(row(1),1),"V");
                        if target==1 then
                            observations($+1)=bench_observation("i"+string(tag),LD9.journal(row(1),2),"mA");
                        end
                    end
                end
            end
        end
        params=struct("E",cfg.E,"R",cfg.R,"L",cfg.L,"C",cfg.C);
        evidence.wiring=struct("s1",struct("pairs",bench_pairs(LD9.report_wires),"meter","AC"));
        note="";
    elseif lab=="LD10" then
        if isfield(LD10,"demoMode") & LD10.demoMode then error("Grįžkite iš pavyzdžio į savo darbą prieš išsaugodami ataskaitą."); end
        st=LD10.student; cfg=LD10.cfg;
        if isfield(LD10,"assessment") then if LD10.assessment then mode="assessment"; end; end
        if isfield(LD10,"practice_used") then practice=LD10.practice_used; end
        specs=["1" "1" "Hz";"3" "1" "1";"3" "2" "mA"; ...
               "5" "1" "mA";"5" "2" "mS";"5" "3" "1";"5" "4" "mW";"5" "5" "mvar";"5" "6" "mVA"; ...
               "6" "1" "choice";"6" "2" "choice";"6" "3" "choice"];
        for k=1:size(specs,1)
            step=bench_safe_number(specs(k,1)); q=bench_safe_number(specs(k,2));
            answers($+1)=bench_answer(msprintf("s%d.q%d",step,q),LD10.answers(step,q),specs(k,3));
        end
        if isfield(LD10,"journal") & LD10.journal<>[] then
            // 15 stebėjimų: 3 taškai × (U, IR, IL, IC, I bendra).
            names=["ir";"il";"ic"];
            for tag=1:3
                // Žurnalas: [U V, I mA, taškas, f, taikinys].
                rowI=find(LD10.journal(:,3)==tag & LD10.journal(:,5)==4);
                if rowI<>[] then observations($+1)=bench_observation("u"+string(tag),LD10.journal(rowI(1),1),"V"); end
                for target=1:3
                    row=find(LD10.journal(:,3)==tag & LD10.journal(:,5)==target);
                    if row<>[] then
                        observations($+1)=bench_observation(names(target)+string(tag),LD10.journal(row(1),2),"mA");
                    end
                end
                if rowI<>[] then
                    observations($+1)=bench_observation("i"+string(tag),LD10.journal(rowI(1),2),"mA");
                end
            end
        end
        params=struct("E",cfg.E,"R",cfg.R,"L",cfg.L,"C",cfg.C);
        evidence.wiring=struct("s1",struct("pairs",bench_pairs(LD10.report_wires),"meter","AC"));
        note="";
    elseif lab=="LD11" then
        if isfield(LD11,"demoMode") & LD11.demoMode then error("Grįžkite iš pavyzdžio į savo darbą prieš išsaugodami ataskaitą."); end
        st=LD11.student; cfg=LD11.cfg;
        if isfield(LD11,"assessment") then if LD11.assessment then mode="assessment"; end; end
        if isfield(LD11,"practice_used") then practice=LD11.practice_used; end
        specs=["1" "1" "1";"2" "1" "mVA";"2" "2" "mvar";"2" "3" "1";"3" "1" "uF"; ...
               "5" "1" "mVA";"5" "2" "mvar";"5" "3" "1";"5" "4" "mVA"; ...
               "6" "1" "choice";"6" "2" "choice";"6" "3" "choice"];
        for k=1:size(specs,1)
            step=bench_safe_number(specs(k,1)); q=bench_safe_number(specs(k,2));
            answers($+1)=bench_answer(msprintf("s%d.q%d",step,q),LD11.answers(step,q),specs(k,3));
        end
        if isfield(LD11,"journal") & LD11.journal<>[] then
            // 6 stebėjimai: U, I, P abiejuose režimuose.
            for tag=1:2
                row=find(LD11.journal(:,3)==tag);
                if row<>[] then
                    observations($+1)=bench_observation("u"+string(tag),LD11.journal(row(1),1),"V");
                    observations($+1)=bench_observation("i"+string(tag),LD11.journal(row(1),2),"mA");
                    observations($+1)=bench_observation("p"+string(tag),LD11.journal(row(1),4),"mW");
                end
            end
        end
        params=struct("E",cfg.E,"f",50,"R",cfg.R,"L",cfg.L,"Ck",cfg.Ck);
        evidence.wiring=struct();
        evidence.wiring("s1")=struct("pairs",bench_pairs(LD11.report_wires(1)),"meter","AC");
        evidence.wiring("s4")=struct("pairs",bench_pairs(LD11.report_wires(2)),"meter","AC");
        note="";
    elseif lab=="LD12" then
        if isfield(LD12,"demoMode") & LD12.demoMode then error("Grįžkite iš pavyzdžio į savo darbą prieš išsaugodami ataskaitą."); end
        st=LD12.student; cfg=LD12.cfg;
        if isfield(LD12,"assessment") then if LD12.assessment then mode="assessment"; end; end
        if isfield(LD12,"practice_used") then practice=LD12.practice_used; end
        specs=["1" "1" "V";"2" "1" "mA";"3" "1" "V";"4" "1" "mA"; ...
               "5" "1" "mA";"5" "2" "mW";"5" "3" "mW"; ...
               "6" "1" "choice";"6" "2" "choice";"6" "3" "choice"];
        for k=1:size(specs,1)
            step=bench_safe_number(specs(k,1)); q=bench_safe_number(specs(k,2));
            answers($+1)=bench_answer(msprintf("s%d.q%d",step,q),LD12.answers(step,q),specs(k,3));
        end
        if isfield(LD12,"journal") & LD12.journal<>[] then
            // Simetrinėje grandinėje studentas realiai matuoja po vieną fazę kiekvienu jungimu.
            // Kitų fazių ir linijinės srovės negeneruojame kaip tariamų matavimų.
            row1=find(LD12.journal(:,3)==1);
            if row1<>[] then observations($+1)=bench_observation("is",LD12.journal(row1(1),2),"mA"); end
            row2=find(LD12.journal(:,3)==2);
            if row2<>[] then observations($+1)=bench_observation("id",LD12.journal(row2(1),2),"mA"); end
        end
        params=struct("Ul",cfg.Ul,"R",cfg.R);
        evidence.wiring=struct();
        evidence.wiring("s1")=struct("pairs",bench_pairs(LD12.report_wires(1)),"meter","AC");
        evidence.wiring("s3")=struct("pairs",bench_pairs(LD12.report_wires(2)),"meter","AC");
        note="";
    else
        if LD2.example_active then error("Grįžkite iš pavyzdžio į savo darbą prieš išsaugodami ataskaitą."); end
        s=LD2.state; st=s.student; cfg=LD2.cfg;
        if isfield(s,"assessment") then if s.assessment then mode="assessment"; end; end
        if isfield(s,"practice_used") then practice=s.practice_used;end
        for step=[3 4 6 7 9 10 11]
            select step
            case 3 then units=["Ohm" "Ohm" "mA" "V" "V" "mW" "deg"];
            case 6 then units=["Ohm" "Ohm" "mA" "V" "V" "mW" "deg"];
            case 4 then units=["V" "mA"];
            case 7 then units=["V" "mA"];
            case 9 then units=["Hz" "Hz" "ms" "V"];
            case 10 then units=["V" "V" "V" "Hz" "Hz" "Hz"];
            case 11 then units=["V" "Hz" "Hz" "Hz" "1"];
            end
            for q=1:size(units,"*"); answers($+1)=bench_answer(msprintf("s%d.q%d",step,q),s.answers_text(step,q),units(q)); end
        end
        fields=["rc_I" "rc_UR" "rc_UC" "rc_UE" "rl_I" "rl_UR" "rl_UL" "rl_UE" "f1_meas" "f2_meas" "f1_u" "f2_u"];
        units=["A" "V" "V" "V" "A" "V" "V" "V" "Hz" "Hz" "V" "V"];
        for k=1:size(fields,"*"); observations($+1)=bench_observation(fields(k),s(fields(k)),units(k)); end
        for field=["E_RC" "F_RC" "R8" "C2" "E_RL" "F_RL" "R9" "L1" "E_RLC" "R13" "L3" "C4"]
            params(field)=cfg(field);
        end
        evidence.wiring=struct("RC",bench_pairs(s.rc_connections),"RL",bench_pairs(s.rl_connections),"RLC",bench_pairs(s.rlc_connections));
        evidence.resonance=list();
        for k=1:size(s.res_f,"*"); evidence.resonance($+1)=struct("f",s.res_f(k),"u",s.res_ur(k)); end
        evidence.peaks=list();
        for k=1:size(s.peak_f,"*"); evidence.peaks($+1)=struct("target",s.peak_target(k),"f",s.peak_f(k),"u",s.peak_u(k)); end
        evidence.sweep=list();
        for k=1:size(s.sweep_f,"*"); evidence.sweep($+1)=struct("f",s.sweep_f(k),"u",s.sweep_ur(k)); end
        evidence.journal=s.measurements;
        note=s.free_note;
    end
    if st.number<1 then error("Pirmiausia įveskite studento duomenis ir eilės numerį."); end
    r=struct("schema_version",1,"lab_id",lab,"lab_revision","1","rubric_version",lab+"-1", ...
        "bank_id",st.bank,"variant",st.number,"submission_id",bench_id(),"mode",mode, ...
        "student",struct("number",st.number,"name",st.name,"group",st.group), ...
        "parameters",params,"answers",answers,"observations",observations,"evidence",evidence,"note",note,"practice_used",practice);
    if lab=="LD6" then r.lab_revision="2"; r.rubric_version="LD6-2"; end
    if lab=="LD1" then
        if isfield(evidence,"automatic_setup") then
            if evidence.automatic_setup then r.lab_revision="2";r.rubric_version="LD1-2";end
        end
        if ld1_measurement_workflow() then r=ld1_measurement_report(r); end
    end
endfunction

function path=bench_export_report(lab,folder)
    if argn(2)<2 then folder=bench_documents(); end
    r=bench_report_data(lab);
    path=fullfile(folder,r.lab_id+"-V"+msprintf("%02d",r.variant)+"-"+r.submission_id+".html");
    bench_core_require(); p=ascii(path); b=ascii(toJSON(r));
    status=call("ld_export_report",p,1,"i",size(p,"*"),2,"i",b,3,"i",size(b,"*"),4,"i","out",[1 1],5,"i");
    if status<>0 then error("Ataskaita neišsaugota. Patikrinkite aplanko teises ir darbo duomenis."); end
endfunction

function path=bench_export_current(lab)
    global LD1 LD2 LD3 LD4 LD5 LD6 LD7 LD8 LD9 LD10 LD11 LD12;
    path="";

    // Pirma atliekame vienintelį autoritetingą veiksmą: surenkame dabartinius
    // studento duomenis ir įrašome HTML. Jei tai nepavyko, grąžiname klaidą.
    try
        if lab=="LD1" then ld1_save_step_inputs();
        elseif lab=="LD3" then ld3_save_answers();
        elseif lab=="LD4" then ld4_save_answers();
        elseif lab=="LD5" then ld5_save_answers();
        elseif lab=="LD6" then ld6_save_answers();
        elseif lab=="LD7" then ld7_save_answers();
        elseif lab=="LD8" then ld8_save_answers();
        elseif lab=="LD9" then ld9_save_answers();
        elseif lab=="LD10" then ld10_save_answers();
        elseif lab=="LD11" then ld11_save_answers();
        elseif lab=="LD12" then ld12_save_answers();
        else ld2_save_answers(); end
        path=bench_export_report(lab);
    catch
        path="";
        if lab=="LD1" then ld1_set_status(strcat(lasterror()," "),"error","");
        elseif lab=="LD3" then ld3_set_status(strcat(lasterror()," "),"error","");
        elseif lab=="LD4" then ld4_set_status(strcat(lasterror()," "),"error","");
        elseif lab=="LD5" then ld5_set_status(strcat(lasterror()," "),"error","");
        elseif lab=="LD6" then ld6_set_status(strcat(lasterror()," "),"error","");
        elseif lab=="LD7" then ld7_set_status(strcat(lasterror()," "),"error","");
        elseif lab=="LD8" then ld8_set_status(strcat(lasterror()," "),"error","");
        elseif lab=="LD9" then ld9_set_status(strcat(lasterror()," "),"error","");
        elseif lab=="LD10" then ld10_set_status(strcat(lasterror()," "),"error","");
        elseif lab=="LD11" then ld11_set_status(strcat(lasterror()," "),"error","");
        elseif lab=="LD12" then ld12_set_status(strcat(lasterror()," "),"error","");
        else ld2_set_status(strcat(lasterror()," "),"error"); end
        return;
    end

    // Nuo šios vietos HTML jau yra išsaugotas. UI patvirtinimo langas yra
    // antrinis patogumo sluoksnis ir jo gedimas negali atšaukti eksporto.
    if lab=="LD1" then
        if LD1.assessment & ~LD1.practice_used then
            ld1_set_status("Ataskaita išsaugota: "+path,"ok","Persiųskite šį HTML failą dėstytojui.");
        else
            ld1_set_status("Mokymosi ataskaita išsaugota: "+path,"ok","Atsiskaitymui pradėkite naują darbą per Pagalba → Režimas.");
        end
    elseif lab=="LD3" then
        if LD3.assessment & ~LD3.practice_used then
            ld3_set_status("Ataskaita išsaugota: "+path,"ok","Persiųskite šį HTML failą dėstytojui.");
        else
            ld3_set_status("Mokymosi ataskaita išsaugota: "+path,"info","Šis bandymas neįtraukiamas į pažymių suvestinę.");
        end
    elseif lab=="LD4" then
        if LD4.assessment & ~LD4.practice_used then
            ld4_set_status("Ataskaita išsaugota: "+path,"ok","Persiųskite šį HTML failą dėstytojui.");
        else
            ld4_set_status("Mokymosi ataskaita išsaugota: "+path,"info","Šis bandymas neįtraukiamas į pažymių suvestinę.");
        end
    elseif lab=="LD5" then
        if LD5.assessment & ~LD5.practice_used then
            ld5_set_status("Ataskaita išsaugota: "+path,"ok","Persiųskite šį HTML failą dėstytojui.");
        else
            ld5_set_status("Mokymosi ataskaita išsaugota: "+path,"info","Šis bandymas neįtraukiamas į pažymių suvestinę.");
        end
    elseif lab=="LD6" then
        if LD6.assessment & ~LD6.practice_used then
            ld6_set_status("Ataskaita išsaugota: "+path,"ok","Persiųskite šį HTML failą dėstytojui.");
        else
            ld6_set_status("Mokymosi ataskaita išsaugota: "+path,"info","Šis bandymas neįtraukiamas į pažymių suvestinę.");
        end
    elseif lab=="LD8" then ld8_set_status("Ataskaita išsaugota: "+path,"ok","Persiųskite šį HTML failą dėstytojui.");
    elseif lab=="LD9" then ld9_set_status("Ataskaita išsaugota: "+path,"ok","Persiųskite šį HTML failą dėstytojui.");
    elseif lab=="LD10" then ld10_set_status("Ataskaita išsaugota: "+path,"ok","Persiųskite šį HTML failą dėstytojui.");
    elseif lab=="LD11" then ld11_set_status("Ataskaita išsaugota: "+path,"ok","Persiųskite šį HTML failą dėstytojui.");
    elseif lab=="LD12" then ld12_set_status("Ataskaita išsaugota: "+path,"ok","Persiųskite šį HTML failą dėstytojui.");
    elseif lab=="LD7" then
        if LD7.assessment & ~LD7.practice_used then
            ld7_set_status("Ataskaita išsaugota: "+path,"ok","Persiųskite šį HTML failą dėstytojui.");
        else
            ld7_set_status("Mokymosi ataskaita išsaugota: "+path,"info","Šis bandymas neįtraukiamas į pažymių suvestinę.");
        end
    else ld2_set_status("Ataskaita išsaugota: "+path+". Persiųskite šį HTML failą dėstytojui.","ok"); end

    learning_report=%f;
    if lab=="LD1" then learning_report=(~LD1.assessment | LD1.practice_used); end
    if lab=="LD3" then learning_report=(~LD3.assessment | LD3.practice_used); end
    if lab=="LD4" then learning_report=(~LD4.assessment | LD4.practice_used); end
    if lab=="LD5" then learning_report=(~LD5.assessment | LD5.practice_used); end
    if lab=="LD6" then learning_report=(~LD6.assessment | LD6.practice_used); end
    if lab=="LD7" then learning_report=(~LD7.assessment | LD7.practice_used); end

    try
        if learning_report then bench_report_saved(path,"Mokymosi ataskaita išsaugota");
        else bench_report_saved(path,"Ataskaita išsaugota"); end
    catch
        mprintf("WARN: ataskaita išsaugota, bet nepavyko atverti patvirtinimo lango: %s\n",strcat(lasterror()," "));
    end
endfunction
