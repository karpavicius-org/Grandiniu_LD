function ok = ld1_configure_missing_values()
    global LD1;
    ok=%t;
    if LD1.cfg.R1>0 & LD1.cfg.R2>0 & LD1.cfg.R3>0 then return; end

    title=["LD Nr. 1 – stendo rezistorių parametrai";
           "Įveskite R1, R2 ir R3 NOMINALIAS varžas OMAIS (Ω).";
           "Pavyzdys: jei ant modulio parašyta 1 kΩ, įveskite 1000."];
    labels=["R1 [Ω]";"R2 [Ω]";"R3 [Ω]"];
    defaults=["";"";""];
    if LD1.cfg.R1>0 then defaults(1)=string(LD1.cfg.R1); end
    if LD1.cfg.R2>0 then defaults(2)=string(LD1.cfg.R2); end
    if LD1.cfg.R3>0 then defaults(3)=string(LD1.cfg.R3); end

    while %t
        vals=x_mdialog(title,labels,defaults);
        if isempty(vals) then ok=%f; return; end

        r1=ld1_parse_number(vals(1));
        r2=ld1_parse_number(vals(2));
        r3=ld1_parse_number(vals(3));
        if isnan(r1) | isnan(r2) | isnan(r3) | r1<=0 | r2<=0 | r3<=0 then
            messagebox("Įveskite tris teigiamas skaitines varžų reikšmes OMAIS.","LD1 parametrai","error");
            defaults=vals;
            continue;
        end

        // Dažniausia klaida – vietoje 1000 Ω įvedama 1, turint omenyje 1 kΩ.
        if min([r1 r2 r3])<10 then
            warn=ld1_multiline(["Bent viena įvesta varža yra mažesnė nei 10 Ω.";
                "Patikrinkite vienetus: 1 kΩ = 1000 Ω, o ne 1 Ω.";
                "";
                "Įvesta: R1="+string(r1)+" Ω, R2="+string(r2)+" Ω, R3="+string(r3)+" Ω.";
                "Ar šios reikšmės tikrai teisingos?"]);
            answ=messagebox(warn,"Patikrinkite varžų vienetus","question",["Taip, teisingos" "Taisyti"],"modal");
            if answ<>1 then defaults=vals; continue; end
        end

        LD1.cfg.R1=r1; LD1.cfg.R2=r2; LD1.cfg.R3=r3;
        return;
    end
endfunction

function ld1_init_state()
    global LD1;
    LD1.step=1;
    if ~isfield(LD1,"assessment") then LD1.assessment=%f;end
    if ~isfield(LD1,"guided") then LD1.guided=%f;end
    if ~isfield(LD1,"practice_used") then LD1.practice_used=%f;end
    LD1.panel="series";
    LD1.powerOn=%f;
    LD1.VR1=1000;
    LD1.meterMode="A";
    LD1.realistic=LD1.cfg.realistic_default;
    LD1.reviewMode=%f;
    LD1.demoMode=%f;
    LD1.demoSnapshot=struct();
    LD1.skipped=zeros(1,9)==1;
    LD1.pendingTerminal="";
    LD1.wires=emptystr(0,2);
    LD1.savedSeriesWires=emptystr(0,2);
    LD1.savedParallelWires=emptystr(0,2);
    LD1.savedParallelVoltageWires=emptystr(0,2);
    LD1.savedParallelVoltageVR=1000;
    LD1.kclPrepared=%f;
    LD1.kclTargetA="NODE_A1";
    LD1.lastMeasurement=%nan;
    LD1.lastMeasurementUnit="";
    LD1.lastMeasurementStep=0;
    LD1.parallelBaseVoltage=%nan;
    LD1.done=zeros(1,9)==1;
    LD1.recorded=zeros(1,9)==1; LD1.guided_used=%f;

    // Studentų įrašai ir matavimai saugomi atskirai kiekvienam etapui.
    // Grįžus atgal nieko nereikia spręsti iš naujo.
    LD1.report_wires=list(); LD1.report_meter=emptystr(1,9);
    for k=1:9; LD1.report_wires(k)=emptystr(0,2); end
    LD1.stepQ=emptystr(9,3);
    LD1.stepType=zeros(1,9);
    LD1.stepYesNo=zeros(1,9);
    LD1.stepMeas=%nan*ones(1,9);
    LD1.stepMeasUnit=emptystr(9,1);
    LD1.stepVR=%nan*ones(1,9);

    LD1.actual=struct("R1",0,"R2",0,"R3",0,"VR1",1000);
    LD1.res=struct( ..
        "Rseries1000",%nan,"Iseries1000",%nan,"Mseries1000",%nan,"Errseries1000",%nan, ..
        "Rseries500",%nan,"Iseries500",%nan,"Mseries500",%nan,"Errseries500",%nan, ..
        "Rparallel1000",%nan,"Uparallel1000",%nan, ..
        "UparallelChanged",%nan, ..
        "I1",%nan,"I2",%nan,"It",%nan,"MIt",%nan,"KclErr",%nan);
    ld1_update_actual_values();
endfunction

function ld1_init_terminals()
    global LD1;
    LD1.term=struct();
    LD1.term.ids=["SRC_P";"SRC_N";"R1_1";"R1_2";"R2_1";"R2_2";"R3_1";"R3_2"; ..
                  "VR1_1";"VR1_2";"M_P";"M_N"; ..
                  "NODE_A1";"NODE_A2";"NODE_A3";"NODE_A4"; ..
                  "NODE_B1";"NODE_B2";"NODE_B3";"NODE_B4"];
    LD1.term.xy=%nan*ones(size(LD1.term.ids,"*"),2);
    LD1.term.active=emptystr(0,1);
    LD1.term.handles=list();
    LD1.term.handleIds=emptystr(0,1);
endfunction

function ld1_start()
    global LD1;
    if ~ld1_configure_missing_values() then
        disp("LD1 nepaleista: nenurodytos R1, R2, R3 vertės.");
        return;
    end
    ld1_init_state();
    ld1_init_terminals();
    ld1_create_gui();
    ld1_build_panel("series");
    ld1_set_step(1);
    LD1.fig.resizefcn="ld1_resize("+string(LD1.fig.figure_id)+")";
endfunction

function ld1_switch_panel(kind)
    global LD1;
    if isfield(LD1,"panel") then
        if LD1.panel=="series" then LD1.savedSeriesWires=LD1.wires; else LD1.savedParallelWires=LD1.wires; end
    end
    ld1_build_panel(kind);
    if kind=="series" then LD1.wires=LD1.savedSeriesWires; else LD1.wires=LD1.savedParallelWires; end
    ld1_redraw_panel();
endfunction

function ld1_refresh_meter_idle_display()
    global LD1;
    if ~isfield(LD1,"ui") then return; end
    if ~isfield(LD1.ui,"meterDisplay") then return; end
    if ~isnan(LD1.lastMeasurement) then
        LD1.ui.meterDisplay.string=ld1_num(LD1.lastMeasurement,3)+" "+LD1.lastMeasurementUnit;
        return;
    end
    if ld1_terminal_wire_count("M_P")>0 & ld1_terminal_wire_count("M_N")>0 then
        LD1.ui.meterDisplay.string="PARUOŠTA";
    else
        LD1.ui.meterDisplay.string="NEPRIJUNGTA";
    end
endfunction

function ld1_invalidate_measurement()
    global LD1;
    LD1.lastMeasurement=%nan;
    LD1.lastMeasurementUnit="";
    LD1.lastMeasurementStep=0;
    if isfield(LD1,"stepMeas") & LD1.step>=1 & LD1.step<=9 then
        LD1.stepMeas(LD1.step)=%nan;
        LD1.stepMeasUnit(LD1.step)="";
    end
    ld1_refresh_meter_idle_display();
endfunction

function fix = ld1_current_connection_fix()
    global LD1;
    if LD1.step<=4 then
        fix="Išjunkite maitinimą [B01]. Tiksliai: [T01]→[T03]; [T04]→[T09]; [T10]→[T11]; [T12]→[T02]. Jei etapas >1, spauskite ATKURTI ETAPO STENDĄ [B12].";
    elseif LD1.step<=7 then
        fix="Išjunkite maitinimą [B01]. Naudokite atskirus A/B lizdus: [T01]→[T13], [T02]→[T17]; R3 tarp [T14]-[T18]; R2+VR1 tarp [T15]-[T19]; V tarp [T16]-[T20].";
    elseif LD1.step==8 then
        targetA=ld1_terminal_button_text(LD1.kclTargetA);
        tpart="";
        if exists("ld1_terminal_code")==1 then tpart=" ["+ld1_terminal_code(LD1.kclTargetA)+"]"; end
        fix="8 etape kitų 6 laidų nelieskite. Prijunkite tik: šaltinio + [T01]→+/mA [T11] ir COM [T12]→"+targetA+tpart+". Jei būsena sugadinta – ATKURTI ETAPO STENDĄ [B12].";
    else
        fix="Šiame etape laidų jungti nereikia.";
    end
endfunction
function W = ld1_series_canonical_wires()
    W=["SRC_P" "R1_1";
       "R1_2" "VR1_1";
       "VR1_2" "M_P";
       "M_N" "SRC_N"];
endfunction

function W = ld1_parallel_voltage_canonical_wires()
    W=["SRC_P" "NODE_A1";
       "SRC_N" "NODE_B1";
       "NODE_A2" "R3_1";
       "R3_2" "NODE_B2";
       "NODE_A3" "R2_1";
       "R2_2" "VR1_1";
       "VR1_2" "NODE_B3";
       "M_P" "NODE_A4";
       "M_N" "NODE_B4"];
endfunction

function W = ld1_parallel_kcl_base_wires()
    // 8 etapo pradžia: abi šakos ir grįžtamasis laidas jau palikti,
    // o bendras + laidas atvertas ampermetrui įterpti.
    W=["SRC_N" "NODE_B1";
       "NODE_A2" "R3_1";
       "R3_2" "NODE_B2";
       "NODE_A3" "R2_1";
       "R2_2" "VR1_1";
       "VR1_2" "NODE_B3"];
endfunction

function W = ld1_parallel_kcl_canonical_wires()
    // Pilnai teisinga 8 etapo PAVYZDŽIO schema. Kiekvienas fizinis A lizdas
    // gauna daugiausia vieną laidą: target naudojamas ampermetro COM, o dvi
    // kitos A jungtys – R3 ir R2 šakoms. Taip pavyzdys lieka aiškus net jei
    // ankstesniame etape šaltinio + buvo prijungtas ne prie A1.
    global LD1;
    target=LD1.kclTargetA;
    if target=="" then target="NODE_A1"; end
    anodes=["NODE_A1";"NODE_A2";"NODE_A3";"NODE_A4"];
    freeA=emptystr(0,1);
    for k=1:size(anodes,"*")
        if anodes(k)<>target then freeA($+1,1)=anodes(k); end
    end
    aR3=freeA(1); aR2=freeA(2);
    W=["SRC_N" "NODE_B1";
       aR3 "R3_1";
       "R3_2" "NODE_B2";
       aR2 "R2_1";
       "R2_2" "VR1_1";
       "VR1_2" "NODE_B3";
       "SRC_P" "M_P";
       "M_N" target];
endfunction

function ld1_apply_meter_mode_quiet(mode)
    global LD1;
    LD1.meterMode=mode;
    if mode=="A" then
        LD1.ui.modeA.value=1; LD1.ui.modeV.value=0;
    else
        LD1.ui.modeA.value=0; LD1.ui.modeV.value=1;
    end
endfunction

function ld1_save_step_inputs()
    global LD1;
    if isfield(LD1,"fig") then
        if ~is_handle_valid(LD1.fig) then return; end
    end
    if ~isfield(LD1,"ui") then return; end
    if LD1.step<1 | LD1.step>9 then return; end
    if LD1.demoMode then return; end
    LD1.report_wires(LD1.step)=LD1.wires;
    LD1.report_meter(LD1.step)=LD1.meterMode;
    LD1.stepVR(LD1.step)=LD1.VR1;
    for k=1:3
        LD1.stepQ(LD1.step,k)=string(LD1.ui.qEdit(k).string);
    end
    t=0;
    if LD1.ui.typeSeries.value<>0 then t=1; end
    if LD1.ui.typeParallel.value<>0 then t=2; end
    if LD1.ui.typeMixed.value<>0 then t=3; end
    LD1.stepType(LD1.step)=t;
    yn=0;
    if LD1.ui.yes.value<>0 then yn=1; end
    if LD1.ui.no.value<>0 then yn=2; end
    LD1.stepYesNo(LD1.step)=yn;
    if LD1.step==2 then
        LD1.res.Rseries1000=ld1_parse_number(LD1.stepQ(2,1));LD1.res.Iseries1000=ld1_parse_number(LD1.stepQ(2,2));
    elseif LD1.step==4 then
        LD1.res.Rseries500=ld1_parse_number(LD1.stepQ(4,1));LD1.res.Iseries500=ld1_parse_number(LD1.stepQ(4,2));
    elseif LD1.step==6 then LD1.res.Rparallel1000=ld1_parse_number(LD1.stepQ(6,1));
    elseif LD1.step==8 then
        LD1.res.I1=ld1_parse_number(LD1.stepQ(8,1));LD1.res.I2=ld1_parse_number(LD1.stepQ(8,2));LD1.res.It=ld1_parse_number(LD1.stepQ(8,3));
    end
    if LD1.lastMeasurementStep==LD1.step & ~isnan(LD1.lastMeasurement) then
        LD1.stepMeas(LD1.step)=LD1.lastMeasurement;
        LD1.stepMeasUnit(LD1.step)=LD1.lastMeasurementUnit;
    end
    ld1_sync_recorded_results();
endfunction

function ld1_restore_step_inputs(n)
    global LD1;
    if n<1 | n>9 then return; end
    if isfield(LD1,"stepVR") then
        if ~isnan(LD1.stepVR(n)) then
            LD1.VR1=LD1.stepVR(n); LD1.ui.vrSlider.value=LD1.VR1;
            if is_handle_valid(LD1.ui.vrText) then LD1.ui.vrText.string=string(LD1.VR1)+" Ω"; end
            ld1_update_actual_values();
        end
    end
    if LD1.report_meter(n)<>"" then ld1_apply_meter_mode_quiet(LD1.report_meter(n)); end
    for k=1:3
        LD1.ui.qEdit(k).string=LD1.stepQ(n,k);
    end
    t=LD1.stepType(n);
    LD1.ui.typeSeries.value=bool2s(t==1); LD1.ui.typeParallel.value=bool2s(t==2); LD1.ui.typeMixed.value=bool2s(t==3);
    yn=LD1.stepYesNo(n);
    LD1.ui.yes.value=bool2s(yn==1); LD1.ui.no.value=bool2s(yn==2);
    if ~isnan(LD1.stepMeas(n)) then
        LD1.lastMeasurement=LD1.stepMeas(n);
        LD1.lastMeasurementUnit=LD1.stepMeasUnit(n);
        LD1.lastMeasurementStep=n;
    end
endfunction

function ld1_show_wiring_guide()
    global LD1;
    select LD1.step
    case 1 then
        txt=["1 ETAPAS – NUOSEKLI GRANDINĖ";
             "";
             "Maitinimas [B01] turi būti IŠJUNGTAS.";
             "1. Šaltinio + [T01]  →  R1(1) [T03]";
             "2. R1(2) [T04]       →  VR1(1) [T09]";
             "3. VR1(2) [T10]      →  multimetro +/mA [T11]";
             "4. Multimetro COM [T12] → šaltinio − [T02]";
             "5. Multimetras: A (DC) [B07].";
             "";
             "Turi būti 4 laidai ir viena uždara nuosekli kilpa."];
    case 2 then
        txt=["2 ETAPAS – JUNGIMAS NEKEIČIAMAS";"Naudokite 1 etapo nuoseklią schemą.";"VR1 = 1000 Ω [B04]. Srovę galite pamatuoti: įjunkite šaltinį [B01], pasirinkite A (DC) [B07] ir spauskite MATUOTI [B06]."];
    case 3 then
        txt=["3 ETAPAS – SROVĖS MATAVIMAS";"Jungimas toks pats kaip 1 etape.";"Multimetras A (DC) [B07], nuosekliai. Įjunkite 10 V [B01] ir spauskite MATUOTI [B06]."];
    case 4 then
        txt=["4 ETAPAS – VR1 = 500 Ω";"Jungimas toks pats kaip 1 etape.";"Pakeiskite tik VR1 į 500 Ω [B03] arba [V01], apskaičiuokite ir išmatuokite srovę [B06]."];
    case 5 then
        txt=["5 ETAPAS – LYGIAGRETI GRANDINĖ";
             "";
             "Maitinimas [B01] turi būti IŠJUNGTAS.";
             "1. Šaltinis: + [T01]→A1 [T13], − [T02]→B1 [T17]";
             "2. Šaka 1: A2 [T14]→R3(1) [T07], R3(2) [T08]→B2 [T18]";
             "3. Šaka 2: A3 [T15]→R2(1) [T05], R2(2) [T06]→VR1(1) [T09], VR1(2) [T10]→B3 [T19]";
             "4. Voltmetras: +/V [T11]→A4 [T16], COM [T12]→B4 [T20]";
             "5. Multimetras: V (DC) [B08].";
             "";
             "A1=A2=A3=A4 yra tas pats mazgas A; B1=B2=B3=B4 – mazgas B."];
    case 6 then
        txt=["6 ETAPAS – UAB MATAVIMAS";"Jungimas toks pats kaip 5 etape.";"VR1 = 1000 Ω [B04]. Voltmetras tarp A ir B: + [T11]→A4 [T16], COM [T12]→B4 [T20]."];
    case 7 then
        txt=["7 ETAPAS – VR1 KEITIMAS";"Jungimas toks pats kaip 5 etape.";"Pakeiskite tik VR1 (pvz., 500 Ω [B03]) ir iš naujo išmatuokite UAB [B06]."];
    case 8 then
        targetA=ld1_terminal_button_text(LD1.kclTargetA);
        tpart="";
        if exists("ld1_terminal_code")==1 then tpart=" ["+ld1_terminal_code(LD1.kclTargetA)+"]"; end
        txt=["8 ETAPAS – BENDROS SROVĖS MATAVIMAS";
             "";
             "SROVĖS KELIAS TURI BŪTI: +10 V [T01] → AMPERMETRAS → MAZGAS A → DVI ŠAKOS → MAZGAS B → 0 V [T02].";
             "Programa jau paliko 6 teisingus ir užrakintus laidus.";
             "R3 lieka tarp [T14]-[T18]; R2+VR1 tarp [T15]-[T19]; B [T17] lieka sujungtas su šaltinio − [T02].";
             "";
             "Prijunkite TIK 2 laidus:";
             "1. Šaltinio + [T01] → ampermetro +/mA [T11].";
             "2. Ampermetro COM [T12] → "+targetA+tpart+".";
             "";
             "Po sujungimo turi būti 8 laidai. VR1=0 Ω [B02]. PATIKRINTI SUJUNGIMĄ [B09] → ĮJUNGTI 10 V [B01] → MATUOTI [B06].";
             "Jei vis tiek neaišku – PAVYZDYS / SPRENDIMAS [B17] parodo pilnai veikiančią schemą."];
    else
        txt=["9 ETAPAS – REZULTATAI";"Laidų jungti nebereikia.";"PATIKRINTI IR UŽFIKSUOTI ETAPĄ [B14] eksportuoja CSV; [B17] rodo pilną pavyzdį."];
    end
    ld1_show_text_window("LD1 – kaip tiksliai sujungti",txt);
endfunction

function ld1_show_stand_map()
    // STENDO ŽEMĖLAPIS [B13]: visų numerių žinynas kontaktams, mygtukams,
    // etapams ir atsakymų laukeliams. Langas kuriamas TIK iš mygtuko
    // callbacko, o be registro ar be GUI (headless) saugiai išeiname.
    global LD1;
    if ~isfield(LD1,"ui") then return; end
    if exists("ld1_terminal_ids")<>1 | exists("ld1_button_registry")<>1 then
        ld1_set_status("Elementų numerių registras (ld1_ids.sci) neįkeltas.","warn");
        return;
    end
    lines=emptystr(0,1);
    lines($+1,1)="KONTAKTAI – T NUMERIAI (pažymėti ir ant stendo prie kiekvieno lizdo):";
    tids=ld1_terminal_ids();
    for k=1:size(tids,"*")
        lines($+1,1)="  "+ld1_terminal_name(tids(k));
    end
    lines($+1,1)=" ";
    lines($+1,1)="Mazgas A: T13–T16 yra elektriškai bendri; mazgas B: T17–T20 bendri";
    lines($+1,1)="(lygiagrečios grandinės stende).";
    lines($+1,1)=" ";
    lines($+1,1)="MYGTUKAI – B NUMERIAI:";
    [ids,cbs,labels,hints]=ld1_button_registry();
    for k=1:size(ids,"*")
        lines($+1,1)="  ["+ids(k)+"] "+labels(k)+" – "+hints(k);
    end
    lines($+1,1)=" ";
    lines($+1,1)="ETAPAI – E NUMERIAI: [E01]–[E09] mygtukai viršutinėje juostoje.";
    lines($+1,1)="ATSAKYMŲ LAUKELIAI – A NUMERIAI: [Aetapas.laukelis], pvz. [A03.02] yra";
    lines($+1,1)="3 etapo 2 laukelis. Vietos: 27 laukeliai [A01.01]–[A09.03].";
    lines($+1,1)=" ";
    lines($+1,1)="KITI VALDIKLIAI: [V01] VR1 slankiklis; [V02] peržiūros režimo žymė;";
    lines($+1,1)="[H01] pagalbinių langų mygtukas Uždaryti.";
    lines($+1,1)="Taip/Ne ir Nuosekli/Lygiagreti/Mišri jungikliai palikti be numerių.";
    ld1_show_text_window("[B13] STENDO ŽEMĖLAPIS – visų numerių registras",lines);
endfunction

function ld1_show_text_window(title,rows)
    // Paprastas sąrašo langas su [H01] Uždaryti mygtuku.
    global LD1;
    if ~isfield(LD1,"ui") then return; end
    f=figure("default_axes","off","dockable","off","menubar","none","toolbar","none");
    f.figure_name=title;
    f.axes_size=[940 640];
    f.figure_position=[40 40];
    f.resize="on";
    uicontrol(f,"style","listbox","units","normalized", ..
        "position",[0.025 0.11 0.95 0.86], ..
        "string",rows,"fontname","Arial","fontunits","pixels","fontsize",13, ..
        "backgroundcolor",[1 1 1]);
    uicontrol(f,"style","pushbutton","units","normalized", ..
        "position",[0.68 0.02 0.29 0.06], ..
        "string","[H01] Uždaryti","tag","H01", ..
        "tooltipstring","[H01] Uždaro šį žinyno langą.", ..
        "fontsize",10,"fontweight","bold", ..
        "callback",msprintf("ld1_aux_close(%d)",f.figure_id));
endfunction

function ld1_aux_close(fid)
    f=findobj("figure_id",fid);
    if f<>[] then delete(f); end
endfunction
function ld1_restore_current_stage_board()
    // Atkuriama tik dabartinio etapo saugi pradinė būsena, o ne visas laboratorinis darbas.
    global LD1;
    if LD1.assessment then
        if LD1.step==9 then return; end
        ld1_force_power_off(); LD1.pendingTerminal="";
        if LD1.step<=4 then
            LD1.wires=LD1.report_wires(1); LD1.savedSeriesWires=LD1.wires;
        elseif LD1.step<=7 then
            LD1.wires=LD1.report_wires(5); LD1.savedParallelWires=LD1.wires;
        else
            LD1.wires=LD1.savedParallelVoltageWires;
            ld1_remove_wires_touching(["M_P";"M_N"]); ld1_remove_direct_source_to_A();
            LD1.savedParallelWires=LD1.wires;
        end
        ld1_redraw_panel(); ld1_save_step_inputs(); bench_autosave("LD1");
        ld1_set_status("Atkurtas jūsų išsaugotas sujungimas. Maitinimas išjungtas.","info","VR1 ir multimetro režimą nustatykite pagal etapo paaiškinimą.");
        return;
    end
    if ld1_guided() & ~LD1.demoMode then
        ld1_guided_prepare(); if LD1.step<9 then ld1_redraw_panel(); end; return;
    end
    ld1_force_power_off();
    LD1.pendingTerminal="";

    if LD1.step==1 then
        if LD1.panel<>"series" then ld1_switch_panel("series"); end
        LD1.wires=emptystr(0,2);
        LD1.savedSeriesWires=LD1.wires;
        ld1_apply_meter_mode_quiet("A");
        LD1.VR1=1000;
    elseif LD1.step>=2 & LD1.step<=4 then
        if LD1.panel<>"series" then ld1_switch_panel("series"); end
        LD1.wires=ld1_series_canonical_wires();
        LD1.savedSeriesWires=LD1.wires;
        ld1_apply_meter_mode_quiet("A");
        if LD1.step==4 then LD1.VR1=500; else LD1.VR1=1000; end
    elseif LD1.step==5 then
        if LD1.panel<>"parallel" then ld1_switch_panel("parallel"); end
        LD1.wires=emptystr(0,2);
        LD1.savedParallelWires=LD1.wires;
        LD1.kclPrepared=%f;
        ld1_set_parallel_meter_layout(%f);
        ld1_apply_meter_mode_quiet("V");
        LD1.VR1=1000;
    elseif LD1.step==6 | LD1.step==7 then
        if LD1.panel<>"parallel" then ld1_switch_panel("parallel"); end
        LD1.wires=ld1_parallel_voltage_canonical_wires();
        LD1.savedParallelWires=LD1.wires;
        LD1.savedParallelVoltageWires=LD1.wires;
        LD1.savedParallelVoltageVR=1000;
        LD1.kclPrepared=%f;
        ld1_set_parallel_meter_layout(%f);
        ld1_apply_meter_mode_quiet("V");
        LD1.VR1=1000;
    elseif LD1.step==8 then
        if LD1.panel<>"parallel" then ld1_switch_panel("parallel"); end
        LD1.wires=ld1_parallel_kcl_base_wires();
        LD1.savedParallelWires=LD1.wires;
        LD1.savedParallelVoltageWires=ld1_parallel_voltage_canonical_wires();
        LD1.savedParallelVoltageVR=1000;
        LD1.kclTargetA="NODE_A1";
        LD1.kclPrepared=%t;
        ld1_set_parallel_meter_layout(%t);
        ld1_apply_meter_mode_quiet("A");
        LD1.VR1=0;
    else
        ld1_set_status("Rezultatų etape stendo atkurti nereikia.","info");
        return;
    end

    LD1.ui.vrSlider.value=LD1.VR1;
    LD1.ui.vrText.string=string(LD1.VR1)+" Ω";
    ld1_update_actual_values();
    ld1_invalidate_measurement();
    ld1_redraw_panel();
    ld1_set_status("Dabartinio etapo stendas atkurtas į saugią pradinę būseną.","ok",ld1_current_connection_fix());
endfunction

function ld1_prepare_review_stage(n)
    // Dėstytojo/testavimo režimui: paruošiamos ankstesnių etapų prielaidos,
    // bet pats pasirinktas etapas nelaikomas atliktu ir išsaugoti jo duomenys neištrinami.
    global LD1;
    if n<=4 then
        if LD1.panel<>"series" then ld1_switch_panel("series"); end
        LD1.wires=ld1_series_canonical_wires(); LD1.savedSeriesWires=LD1.wires;
        ld1_apply_meter_mode_quiet("A");
        if n==4 then LD1.VR1=500; else LD1.VR1=1000; end
    elseif n>=5 & n<=7 then
        if LD1.panel<>"parallel" then ld1_switch_panel("parallel"); end
        LD1.wires=ld1_parallel_voltage_canonical_wires(); LD1.savedParallelWires=LD1.wires;
        LD1.savedParallelVoltageWires=LD1.wires; LD1.savedParallelVoltageVR=1000;
        LD1.kclPrepared=%f; ld1_set_parallel_meter_layout(%f); ld1_apply_meter_mode_quiet("V");
        LD1.VR1=1000;
    elseif n==8 then
        if LD1.panel<>"parallel" then ld1_switch_panel("parallel"); end
        LD1.wires=ld1_parallel_kcl_base_wires(); LD1.savedParallelWires=LD1.wires;
        LD1.savedParallelVoltageWires=ld1_parallel_voltage_canonical_wires(); LD1.savedParallelVoltageVR=1000;
        LD1.kclTargetA="NODE_A1"; LD1.kclPrepared=%t; ld1_set_parallel_meter_layout(%t); ld1_apply_meter_mode_quiet("A");
        LD1.VR1=0;
    end
    if n<9 then
        // Saugiai išjungiame, bet nevalome LD1.stepMeas(n).
        LD1.powerOn=%f;
        ld1_button_string(LD1.ui.power,"IŠJUNGTA");
        LD1.ui.power.backgroundcolor=[0.94 0.82 0.82];
        LD1.ui.sourceDisplay.string="0 V DC";
        LD1.lastMeasurement=%nan; LD1.lastMeasurementUnit=""; LD1.lastMeasurementStep=0;
        LD1.ui.vrSlider.value=LD1.VR1; LD1.ui.vrText.string=string(LD1.VR1)+" Ω";
        ld1_update_actual_values(); ld1_redraw_panel();
    end
endfunction

function ld1_terminal_click(id)
    global LD1;
    if ld1_guided() | LD1.demoMode then return; end
    if ~ld1_terminal_should_show(id) then return; end
    if LD1.powerOn then ld1_set_status("Prieš keisdami laidus išjunkite maitinimą.","warn",""); return; end
    if LD1.pendingTerminal=="" then
        LD1.pendingTerminal=id;
        ld1_set_status("Pasirinkta: "+ld1_terminal_label(id)+". Dabar pasirinkite antrą gnybtą.","info",ld1_current_connection_fix());
    elseif LD1.pendingTerminal==id then
        LD1.pendingTerminal="";
        ld1_set_status("Gnybto pasirinkimas atšauktas.","info",ld1_current_connection_fix());
    else
        a=LD1.pendingTerminal; b=id;
        existed=ld1_wire_exists(a,b);
        if ~existed then
            if ld1_terminal_wire_count(a)>0 then
                LD1.pendingTerminal="";
                if LD1.step==8 & a=="VR1_2" then
                    tpart="";
                    if exists("ld1_terminal_code")==1 then tpart=" ["+ld1_terminal_code(LD1.kclTargetA)+"]"; end
                    fix="VR1(2) [T10] šiame etape jau teisingai jungiasi į B3 [T19]. Ampermetro COM [T12] junkite į "+ld1_terminal_button_text(LD1.kclTargetA)+tpart+", ne į VR1.";
                else
                    fix=ld1_current_connection_fix();
                end
                ld1_set_status(ld1_terminal_label(a)+" jau turi laidą – ant vieno fizinio lizdo antro laido nedėkite.","warn",fix);
                ld1_redraw_panel();
                return;
            end
            if ld1_terminal_wire_count(b)>0 then
                LD1.pendingTerminal="";
                if LD1.step==8 & b=="VR1_2" then
                    tpart="";
                    if exists("ld1_terminal_code")==1 then tpart=" ["+ld1_terminal_code(LD1.kclTargetA)+"]"; end
                    fix="VR1(2) [T10] šiame etape jau teisingai jungiasi į B3 [T19]. Ampermetro COM [T12] junkite į "+ld1_terminal_button_text(LD1.kclTargetA)+tpart+", ne į VR1.";
                else
                    fix=ld1_current_connection_fix();
                end
                ld1_set_status(ld1_terminal_label(b)+" jau turi laidą – pasirinkite nurodytą laisvą lizdą.","warn",fix);
                ld1_redraw_panel();
                return;
            end
        end
        ld1_add_wire(a,b);
        LD1.pendingTerminal="";
        ld1_invalidate_measurement();
        if existed then
            ld1_set_status("Laidas pašalintas: "+ld1_terminal_label(a)+" ↔ "+ld1_terminal_label(b)+".","info",ld1_current_connection_fix());
        else
            ld1_set_status("Laidas prijungtas: "+ld1_terminal_label(a)+" ↔ "+ld1_terminal_label(b)+".","ok",ld1_current_connection_fix());
        end
        if LD1.panel=="series" then LD1.savedSeriesWires=LD1.wires; else LD1.savedParallelWires=LD1.wires; end
    end
    ld1_redraw_panel();
    ld1_save_step_inputs(); bench_autosave("LD1");
endfunction

function ld1_remove_last_wire()
    global LD1;
    if LD1.powerOn then ld1_set_status("Prieš keisdami laidus išjunkite maitinimą.","warn",""); return; end
    if LD1.step==8 & size(LD1.wires,1)<=6 then
        tpart="";
        if exists("ld1_terminal_code")==1 then tpart=" ["+ld1_terminal_code(LD1.kclTargetA)+"]"; end
        ld1_set_status("8 etapo šeši baziniai laidai yra užrakinti.","info","Atšaukti galima tik jūsų pridėtus ampermetro laidus. Prijunkite: [T01]→[T11] ir [T12]→"+ld1_terminal_button_text(LD1.kclTargetA)+tpart+".");
        return;
    end
    if size(LD1.wires,1)==0 then
        ld1_set_status("Nėra laidų, kuriuos būtų galima atšaukti.","info",ld1_current_connection_fix());
        return;
    end
    a=LD1.wires($,1); b=LD1.wires($,2);
    if size(LD1.wires,1)==1 then LD1.wires=emptystr(0,2); else LD1.wires=LD1.wires(1:$-1,:); end
    LD1.pendingTerminal="";
    ld1_invalidate_measurement();
    if LD1.panel=="series" then LD1.savedSeriesWires=LD1.wires; else LD1.savedParallelWires=LD1.wires; end
    ld1_redraw_panel();
    ld1_set_status("Atšauktas paskutinis laidas: "+ld1_terminal_label(a)+" ↔ "+ld1_terminal_label(b)+".","info");
    ld1_save_step_inputs(); bench_autosave("LD1");
endfunction

function ld1_clear_wires()
    global LD1;
    if LD1.powerOn then ld1_set_status("Prieš keisdami laidus išjunkite maitinimą.","warn",""); return; end
    if LD1.step<>1 & LD1.step<>5 then
        ld1_set_status("Šiame etape visa schema nuo atsitiktinio išvalymo užrakinta.","info","Jei reikia teisingos pradinės būsenos, spauskite ATKURTI ETAPO STENDĄ [B12].");
        return;
    end
    LD1.wires=emptystr(0,2);
    LD1.pendingTerminal="";
    ld1_invalidate_measurement();
    if LD1.panel=="series" then LD1.savedSeriesWires=LD1.wires; else LD1.savedParallelWires=LD1.wires; end
    ld1_redraw_panel();
    ld1_set_status("Visi stendo laidai pašalinti.","info");
    ld1_save_step_inputs(); bench_autosave("LD1");
endfunction

function ld1_force_power_off()
    global LD1;
    LD1.powerOn=%f;
    ld1_button_string(LD1.ui.power,"IŠJUNGTA");
    LD1.ui.power.backgroundcolor=[0.94 0.82 0.82];
    LD1.ui.sourceDisplay.string="0 V DC";
    ld1_invalidate_measurement();
endfunction

function tf = ld1_id_in_list(id, ids)
    tf=~isempty(find(ids==id));
endfunction

function ld1_remove_wires_touching(ids)
    global LD1;
    if size(LD1.wires,1)==0 then return; end
    keep=[];
    for k=1:size(LD1.wires,1)
        a=LD1.wires(k,1); b=LD1.wires(k,2);
        if ~ld1_id_in_list(a,ids) & ~ld1_id_in_list(b,ids) then
            keep($+1)=k;
        end
    end
    if isempty(keep) then LD1.wires=emptystr(0,2); else LD1.wires=LD1.wires(keep,:); end
endfunction

function ld1_remove_direct_source_to_A()
    // 5–7 etapuose šaltinio + gnybtas tiesiogiai sujungtas su vienu mazgo A lizdu.
    // 8 etape šį laidą būtina ATVIRTI, nes į jo vietą įterpiamas ampermetras.
    global LD1;
    anodes=["NODE_A1";"NODE_A2";"NODE_A3";"NODE_A4"];
    LD1.kclTargetA="";
    if size(LD1.wires,1)>0 then
        keep=[];
        for k=1:size(LD1.wires,1)
            a=LD1.wires(k,1); b=LD1.wires(k,2);
            direct=(a=="SRC_P" & ld1_id_in_list(b,anodes)) | (b=="SRC_P" & ld1_id_in_list(a,anodes));
            if direct then
                if a=="SRC_P" then LD1.kclTargetA=b; else LD1.kclTargetA=a; end
            else
                keep($+1)=k;
            end
        end
        if isempty(keep) then LD1.wires=emptystr(0,2); else LD1.wires=LD1.wires(keep,:); end
    end
    // Jei studentas anksčiau pasirinko kitokią, bet elektriškai lygiavertę topologiją,
    // parenkame pirmą laisvą A lizdą ir aiškiai jį nurodome.
    if LD1.kclTargetA=="" then
        for k=1:size(anodes,"*")
            if ld1_terminal_wire_count(anodes(k))==0 then LD1.kclTargetA=anodes(k); break; end
        end
    end
    if LD1.kclTargetA=="" then LD1.kclTargetA="NODE_A1"; end
endfunction

function ld1_prepare_kcl_stage()
    // Saugus perėjimas iš voltmetro matavimo į 2-7-3 pav. ampermetro matavimą.
    // Šakos paliekamos, voltmetro laidai nuimami, o tiesioginis +→A laidas atveriamas.
    global LD1;
    LD1.savedParallelVoltageWires=LD1.wires;
    LD1.savedParallelVoltageVR=LD1.VR1;

    ld1_force_power_off();
    ld1_remove_wires_touching(["M_P";"M_N"]);
    ld1_remove_direct_source_to_A();

    if ld1_guided() | LD1.demoMode then
        LD1.VR1=0; LD1.ui.vrSlider.value=0; LD1.ui.vrText.string="0 Ω";
        ld1_update_actual_values(); ld1_apply_meter_mode_quiet("A");
    end
    ld1_set_parallel_meter_layout(%t);
    LD1.pendingTerminal="";
    LD1.kclPrepared=%t;
    LD1.savedParallelWires=LD1.wires;
    ld1_redraw_panel();
endfunction

function ld1_restore_voltage_stage_wiring()
    // Grįžus iš 8 etapo į 7, atkuriama prieš ampermetro įterpimą buvusi schema.
    // Čia sąmoningai nevalome LD1.stepMeas(8), kad jau atliktas 8 etapo matavimas išliktų atmintyje.
    global LD1;
    if size(LD1.savedParallelVoltageWires,1)>0 then LD1.wires=LD1.savedParallelVoltageWires; end
    LD1.VR1=LD1.savedParallelVoltageVR;
    LD1.ui.vrSlider.value=LD1.VR1;
    LD1.ui.vrText.string=string(LD1.VR1)+" Ω";
    ld1_update_actual_values();
    LD1.meterMode="V";
    LD1.ui.modeA.value=0; LD1.ui.modeV.value=1;
    ld1_set_parallel_meter_layout(%f);
    LD1.powerOn=%f;
    ld1_button_string(LD1.ui.power,"IŠJUNGTA");
    LD1.ui.power.backgroundcolor=[0.94 0.82 0.82];
    LD1.ui.sourceDisplay.string="0 V DC";
    LD1.lastMeasurement=%nan; LD1.lastMeasurementUnit=""; LD1.lastMeasurementStep=0;
    LD1.pendingTerminal="";
    LD1.savedParallelWires=LD1.wires;
    LD1.kclPrepared=%f;
    ld1_redraw_panel();
endfunction

function ld1_toggle_power()
    global LD1;
    LD1.powerOn=~LD1.powerOn;
    ld1_invalidate_measurement();
    if LD1.powerOn then
        ld1_button_string(LD1.ui.power,"ĮJUNGTA");
        LD1.ui.power.backgroundcolor=[0.72 0.92 0.74];
        LD1.ui.sourceDisplay.string=string(LD1.cfg.E)+" V DC";
        ld1_set_status("Maitinimo šaltinis [B01] įjungtas: E = "+string(LD1.cfg.E)+" V. Naujam rodmeniui paspauskite MATUOTI [B06].","ok");
    else
        ld1_button_string(LD1.ui.power,"IŠJUNGTA");
        LD1.ui.power.backgroundcolor=[0.94 0.82 0.82];
        LD1.ui.sourceDisplay.string="0 V DC";
        ld1_set_status("Maitinimo šaltinis išjungtas. Ankstesnis matavimo rodmuo panaikintas.","info");
    end
    ld1_redraw_panel();
    ld1_save_step_inputs(); bench_autosave("LD1");
endfunction

function ld1_vr_changed()
    global LD1;
    v=LD1.ui.vrSlider.value;
    v=round(v/LD1.cfg.VR1_step)*LD1.cfg.VR1_step;
    v=max(LD1.cfg.VR1_min,min(LD1.cfg.VR1_max,v));
    LD1.VR1=v;
    LD1.ui.vrSlider.value=v;
    LD1.ui.vrText.string=string(v)+" Ω";
    ld1_update_actual_values();
    ld1_invalidate_measurement();
    ld1_redraw_panel();
    ld1_set_status("VR1 nustatyta į "+string(v)+" Ω. Ankstesnis multimetro rodmuo panaikintas.","info");
    ld1_save_step_inputs(); bench_autosave("LD1");
endfunction

function ld1_set_vr(v)
    global LD1;
    LD1.ui.vrSlider.value=v;
    ld1_vr_changed();
endfunction

function ld1_meter_mode(mode)
    global LD1;
    LD1.meterMode=mode;
    if mode=="A" then
        LD1.ui.modeA.value=1; LD1.ui.modeV.value=0;
    else
        LD1.ui.modeA.value=0; LD1.ui.modeV.value=1;
    end
    ld1_invalidate_measurement();
    ld1_redraw_panel();
    ld1_set_status("Multimetro režimas: "+mode+". Rodmuo bus rodomas tik prijungus abu gnybtus ir paspaudus MATUOTI.","info");
    ld1_save_step_inputs(); bench_autosave("LD1");
endfunction

function ld1_measure()
    global LD1;
    // Prieš matavimą tikriname konkretaus etapo topologiją ir pateikiame pataisymo veiksmą.
    if LD1.step==2 | LD1.step==3 | LD1.step==4 then
        [wok,wmsg,wfix]=ld1_validate_series_topology();
        if ~wok then ld1_invalidate_measurement(); LD1.ui.meterDisplay.string="KLAIDA"; ld1_set_status(wmsg,"error",wfix); return; end
    elseif LD1.step==6 | LD1.step==7 then
        [wok,wmsg,wfix]=ld1_validate_parallel_voltage_topology();
        if ~wok then ld1_invalidate_measurement(); LD1.ui.meterDisplay.string="KLAIDA"; ld1_set_status(wmsg,"error",wfix); return; end
    elseif LD1.step==8 then
        [wok,wmsg,wfix]=ld1_validate_parallel_total_current_topology();
        if ~wok then ld1_invalidate_measurement(); LD1.ui.meterDisplay.string="KLAIDA"; ld1_set_status(wmsg,"error",wfix); return; end
    end

    if ld1_terminal_wire_count("M_P")==0 | ld1_terminal_wire_count("M_N")==0 then
        ld1_invalidate_measurement();
        LD1.ui.meterDisplay.string="NEPRIJUNGTA";
        ld1_redraw_panel();
        ld1_set_status("Multimetras nematuoja, nes neprijungti abu jo gnybtai.","error",ld1_current_connection_fix());
        return;
    end
    [v,u,ok,msg]=ld1_meter_read();
    if ~ok then
        ld1_invalidate_measurement();
        LD1.ui.meterDisplay.string="KLAIDA";
        ld1_redraw_panel();
        ld1_set_status(msg,"error",ld1_current_connection_fix());
        return;
    end
    LD1.lastMeasurement=v;
    LD1.lastMeasurementUnit=u;
    LD1.lastMeasurementStep=LD1.step;
    LD1.stepMeas(LD1.step)=v;
    LD1.stepMeasUnit(LD1.step)=u;
    LD1.ui.meterDisplay.string=ld1_num(v,3)+" "+u;
    ld1_redraw_panel();
    ld1_set_status(msg+" Rodmuo: "+ld1_num(v,3)+" "+u+".","ok","Rodmuo užfiksuotas šiame etape. Galite tęsti skaičiavimus arba paspausti PATIKRINTI IR UŽFIKSUOTI ETAPĄ.");
    ld1_save_step_inputs(); bench_autosave("LD1");
endfunction

function tf = ld1_graph_connected(adj)
    n=size(adj,1);
    if n==0 then tf=%f; return; end
    seen=zeros(1,n)==1;
    q=1; seen(1)=%t; qh=1;
    while qh<=size(q,"*")
        a=q(qh); qh=qh+1;
        nb=find(adj(a,:)>0);
        for kk=1:size(nb,"*")
            b=nb(kk);
            if ~seen(b) then seen(b)=%t; q($+1)=b; end
        end
    end
    tf=and(seen);
endfunction

function [ok,msg,fix] = ld1_validate_series_topology()
    global LD1;
    ok=%f; msg=""; fix="Išjunkite maitinimą [B01] ir junkite tiksliai: [T01]→[T03], [T04]→[T09], [T10]→[T11], [T12]→[T02].";
    if LD1.meterMode<>"A" then msg="Srovės matavimui pasirinktas neteisingas multimetro režimas."; fix="Pasirinkite A (DC) [B07]. Tada palikite ampermetrą nuoseklioje kilpoje."; return; end
    if size(LD1.wires,1)<>4 then
        msg="Nuosekliai grandinei turi būti tiksliai 4 laidai; dabar yra "+string(size(LD1.wires,1))+".";
        fix="Išjunkite maitinimą [B01]. Naudokite 4 jungtis: [T01]→[T03]; [T04]→[T09]; [T10]→[T11]; [T12]→[T02]. Patogiausia: IŠVALYTI LAIDUS [B11] ir KAIP SUJUNGTI [B05]."; return;
    end
    [parent,roots]=ld1_wire_roots();
    ids=["SRC_P";"SRC_N";"R1_1";"R1_2";"VR1_1";"VR1_2";"M_P";"M_N"];
    rr=zeros(1,size(ids,"*"));
    for k=1:size(ids,"*") rr(k)=roots(ld1_term_index(ids(k))); end
    u=unique(rr);
    if size(u,"*")<>4 then
        msg="Nuosekli grandinė nesudaro keturių teisingų elektrinių mazgų."; return;
    end
    ep=[roots(ld1_term_index("SRC_P")) roots(ld1_term_index("SRC_N")); ..
        roots(ld1_term_index("R1_1")) roots(ld1_term_index("R1_2")); ..
        roots(ld1_term_index("VR1_1")) roots(ld1_term_index("VR1_2")); ..
        roots(ld1_term_index("M_P")) roots(ld1_term_index("M_N"))];
    deg=zeros(1,4); adj=zeros(4,4);
    for k=1:4
        if ep(k,1)==ep(k,2) then msg="Vienas elementas užtrumpintas laidu."; fix="IŠVALYTI LAIDUS [B11] ir sujunkite pagal KAIP SUJUNGTI [B05]. Nė vieno elemento gnybtų nejunkite tiesiogiai tarpusavyje."; return; end
        a=find(u==ep(k,1)); b=find(u==ep(k,2)); a=a(1); b=b(1);
        deg(a)=deg(a)+1; deg(b)=deg(b)+1; adj(a,b)=1; adj(b,a)=1;
    end
    if ~and(deg==2) | ~ld1_graph_connected(adj) then
        msg="R1, VR1, ampermetras ir šaltinis nesudaro vienos uždaros nuoseklios kilpos."; return;
    end
    ok=%t; msg="Nuosekli grandinė sujungta teisingai."; fix="";
endfunction
function tf = ld1_two_series_between(pair1,pair2,p,n)
    tf=%f;
    // Tikriname visas pasyvių elementų orientacijas ir abi šakos kryptis.
    for a1=1:2
        a2=3-a1;
        for b1=1:2
            b2=3-b1;
            if pair1(a1)==p & pair1(a2)==pair2(b1) & pair2(b2)==n then tf=%t; return; end
            if pair1(a1)==n & pair1(a2)==pair2(b1) & pair2(b2)==p then tf=%t; return; end
        end
    end
endfunction

function tf = ld1_parallel_resistor_core(roots,p,n)
    r3=ld1_endpoint_root_set("R3_1","R3_2",roots);
    r2=ld1_endpoint_root_set("R2_1","R2_2",roots);
    vr=ld1_endpoint_root_set("VR1_1","VR1_2",roots);
    tf=ld1_unordered_pair_equal(r3,[p n]) & ld1_two_series_between(r2,vr,p,n);
endfunction

function [ok,msg,fix] = ld1_validate_parallel_voltage_topology()
    global LD1;
    ok=%f; msg="";
    fix="Išjunkite maitinimą [B01]. [T01]→[T13], [T02]→[T17]; [T14]→[T07], [T08]→[T18]; [T15]→[T05], [T06]→[T09], [T10]→[T19]; [T11]→[T16], [T12]→[T20].";
    if LD1.meterMode<>"V" then msg="UAB matavimui pasirinktas neteisingas multimetro režimas."; fix="Pasirinkite V (DC) [B08]. Voltmetro + [T11] turi būti A mazge, COM [T12] – B mazge."; return; end
    if size(LD1.wires,1)<>9 then
        msg="5–7 etapų lygiagrečiai schemai turi būti 9 laidai; dabar yra "+string(size(LD1.wires,1))+".";
        fix="Spauskite KAIP SUJUNGTI [B05] ir patikrinkite 9 jungtis. Jei tai ne 5 etapas, greičiausia išeitis – ATKURTI ETAPO STENDĄ [B12]."; return;
    end
    [parent,roots]=ld1_wire_roots();
    p=roots(ld1_term_index("SRC_P")); n=roots(ld1_term_index("SRC_N"));
    if p==n then msg="Maitinimo šaltinis užtrumpintas."; fix="Išjunkite maitinimą [B01], pašalinkite laidą tarp A ir B / šaltinio + ir −, tada spauskite KAIP SUJUNGTI [B05]."; return; end
    if ~ld1_parallel_resistor_core(roots,p,n) then
        msg="Lygiagrečios šakos sujungtos neteisingai."; return;
    end
    mp=ld1_endpoint_root_set("M_P","M_N",roots);
    if ~ld1_unordered_pair_equal(mp,[p n]) then
        msg="Voltmetras neprijungtas tarp tų pačių A ir B mazgų."; fix="Voltmetro +/V [T11] junkite į A4 [T16], COM [T12] – į B4 [T20]. Kitų šakų nekeiskite."; return;
    end
    ok=%t; msg="Lygiagreti grandinė ir voltmetras sujungti teisingai."; fix="";
endfunction
function [ok,msg,fix] = ld1_validate_parallel_total_current_topology()
    // 2-7-3 pav. logika: ampermetras bendrame teigiamame laide prieš mazgą A.
    global LD1;
    ok=%f; msg="";
    targetA=ld1_terminal_button_text(LD1.kclTargetA);
    tpart="";
    if exists("ld1_terminal_code")==1 then tpart=" ["+ld1_terminal_code(LD1.kclTargetA)+"]"; end
    fix="Kitų 6 laidų nelieskite. Prijunkite TIK: šaltinio + [T01]→+/mA [T11] ir COM [T12]→"+targetA+tpart+". Jei abejojate – ATKURTI ETAPO STENDĄ [B12].";
    if LD1.meterMode<>"A" then msg="Bendrai srovei matuoti pasirinktas neteisingas multimetro režimas."; fix="Pasirinkite A (DC) [B07], tada junkite šaltinio + [T01]→+/mA [T11] ir COM [T12]→"+targetA+tpart+"."; return; end
    if size(LD1.wires,1)<6 then
        msg="Trūksta vieno ar kelių bazinių 8 etapo laidų."; fix="Spauskite ATKURTI ETAPO STENDĄ [B12]. Programa grąžins 6 bazinius laidus; tada pridėsite tik 2 ampermetro laidus."; return;
    elseif size(LD1.wires,1)>8 then
        msg="8 etape yra per daug laidų."; fix="Spauskite ATKURTI ETAPO STENDĄ [B12] ir pridėkite tik dvi jungtis: [T01]→[T11] bei [T12]→"+targetA+tpart+"."; return;
    end
    mpCount=ld1_terminal_wire_count("M_P"); mnCount=ld1_terminal_wire_count("M_N");
    if mpCount==0 & mnCount==0 then
        msg="Ampermetras dar visai neprijungtas.";
        fix="Atlikite dvi jungtis iš eilės: 1) [T01]→[T11]; 2) [T12]→"+targetA+tpart+". Tada PATIKRINTI SUJUNGIMĄ [B09]."; return;
    elseif mpCount==0 then
        msg="Trūksta ampermetro +/mA pusės jungties.";
        fix="Prijunkite šaltinio + [T01] prie ampermetro +/mA [T11] (oranžiniai kontaktai). COM jungties nekeiskite."; return;
    elseif mnCount==0 then
        msg="Trūksta ampermetro COM pusės jungties.";
        fix="Prijunkite ampermetro COM [T12] prie "+targetA+tpart+" (violetiniai kontaktai). +/mA jungties nekeiskite."; return;
    end
    if size(LD1.wires,1)<>8 then
        msg="Prijungti abu ampermetro gnybtai, bet bendras laidų skaičius nėra 8.";
        fix="Spauskite ATKURTI ETAPO STENDĄ [B12]. Tada pridėkite tik: [T01]→[T11] ir [T12]→"+targetA+tpart+"."; return;
    end

    [parent,roots]=ld1_wire_roots();
    sp=roots(ld1_term_index("SRC_P")); sn=roots(ld1_term_index("SRC_N"));
    a=roots(ld1_term_index("NODE_A1")); b=roots(ld1_term_index("NODE_B1"));
    mp=roots(ld1_term_index("M_P")); mn=roots(ld1_term_index("M_N"));

    if sp==sn then msg="Maitinimo šaltinis užtrumpintas."; fix="Išjunkite maitinimą [B01] ir spauskite ATKURTI ETAPO STENDĄ [B12]. Tada prijunkite tik dvi pažymėtas poras."; return; end
    if sp==a then
        msg="Šaltinio + vis dar turi tiesioginį kelią į mazgą A, todėl srovė apeina ampermetrą."; fix="Pašalinkite tiesioginį +→A laidą. Turi likti tik [T01]→[T11]→[T12]→"+targetA+tpart+"."; return;
    end
    if b<>sn then
        msg="Mazgas B nebėra sujungtas su šaltinio − (0 V)."; fix="Atkurkite B grįžtamąjį laidą: [T17]→[T02]. Paprasčiausia – ATKURTI ETAPO STENDĄ [B12]."; return;
    end
    if ~(mp==sp & mn==a) then
        msg="Ampermetro +/mA ir COM prijungti ne ta tvarka arba ne į bendrą + laidą."; fix="Oranžiniai: [T01]↔[T11]. Violetiniai: [T12]↔"+targetA+tpart+". Ampermetras turi būti prieš srovės išsišakojimą."; return;
    end
    if mp==mn then msg="Ampermetras užtrumpintas laidu."; fix="Pašalinkite laidą tarp [T11] ir [T12]. Jungti reikia per grandinę: [T01]→[T11], [T12]→"+targetA+tpart+"."; return; end
    if ~ld1_parallel_resistor_core(roots,a,b) then
        msg="Viena iš dviejų lygiagrečių šakų sugadinta."; fix="R3 turi likti tarp [T14]-[T18], o R2+VR1 tarp [T15]-[T19]. Spauskite ATKURTI ETAPO STENDĄ [B12], tada junkite tik ampermetro 2 laidus."; return;
    end

    ok=%t; msg="Teisingai: visa bendra srovė teka per ampermetrą ir tik tada mazge A pasidalija į I1 ir I2."; fix="";
endfunction
function ld1_check_wiring()
    global LD1;
    if LD1.panel=="series" then
        [ok,msg,fix]=ld1_validate_series_topology();
    elseif LD1.meterMode=="V" then
        [ok,msg,fix]=ld1_validate_parallel_voltage_topology();
    else
        [ok,msg,fix]=ld1_validate_parallel_total_current_topology();
    end
    if ok then ld1_set_status(msg,"ok",""); else ld1_set_status(msg,"error",fix); end
endfunction


function ld1_set_power_quiet(on)
    global LD1;
    LD1.powerOn=on;
    if ~is_handle_valid(LD1.ui.power) then return; end
    if on then
        ld1_button_string(LD1.ui.power,"ĮJUNGTA");
        LD1.ui.power.backgroundcolor=[0.72 0.92 0.74];
        LD1.ui.sourceDisplay.string=string(LD1.cfg.E)+" V DC";
    else
        ld1_button_string(LD1.ui.power,"IŠJUNGTA");
        LD1.ui.power.backgroundcolor=[0.94 0.82 0.82];
        LD1.ui.sourceDisplay.string="0 V DC";
    end
endfunction

function [v,u,ok] = ld1_solution_measure(stepNo)
    // Pavyzdys naudoja tą patį grandinės sprendiklį ir tą patį virtualų
    // multimetrą kaip studento MATUOTI mygtukas – ne įrašytą „paruoštą“ skaičių.
    global LD1;
    [v,u,ok,msg]=ld1_meter_read();
    if ok then
        LD1.lastMeasurement=v;
        LD1.lastMeasurementUnit=u;
        LD1.lastMeasurementStep=stepNo;
    else
        LD1.lastMeasurement=%nan;
        LD1.lastMeasurementUnit="";
        LD1.lastMeasurementStep=0;
    end
endfunction

function ld1_set_solution_lock(on)
    // Pavyzdžio režimas yra tik peržiūrai. Studentas pirmiausia pamato
    // pilnai veikiantį variantą, tada grįžta į savo nepakeistą darbą.
    global LD1;
    tf=~on;
    ld1_enable(LD1.ui.power,tf);
    ld1_enable(LD1.ui.vrSlider,tf);
    ld1_enable(LD1.ui.vr0,tf);
    ld1_enable(LD1.ui.vr500,tf);
    ld1_enable(LD1.ui.vr1000,tf);
    ld1_enable(LD1.ui.modeA,tf);
    ld1_enable(LD1.ui.modeV,tf);
    ld1_enable(LD1.ui.measure,tf);
    ld1_enable(LD1.ui.checkWiring,tf);
    ld1_enable(LD1.ui.undoWire,tf);
    ld1_enable(LD1.ui.clearWires,tf);
    ld1_enable(LD1.ui.wiringGuide,tf);
    ld1_enable(LD1.ui.restoreStage,tf);
    ld1_enable(LD1.ui.checkStep,tf);
    ld1_enable(LD1.ui.prev,tf & LD1.step>1);
    ld1_enable(LD1.ui.next,tf);
    ld1_enable(LD1.ui.review,tf);
    for k=1:3
        ld1_enable(LD1.ui.qEdit(k),tf);
    end
    ld1_enable(LD1.ui.typeSeries,tf);
    ld1_enable(LD1.ui.typeParallel,tf);
    ld1_enable(LD1.ui.typeMixed,tf);
    ld1_enable(LD1.ui.yes,tf);
    ld1_enable(LD1.ui.no,tf);
    for k=1:9
        ld1_enable(LD1.ui.stepButtons(k),tf);
    end
    if ~on then
        ld1_update_step_navigation();
        if LD1.step==1 | LD1.step==5 then
            ld1_set_wiring_edit_mode("full");
        elseif LD1.step==8 then
            ld1_set_wiring_edit_mode("meter");
        else
            ld1_set_wiring_edit_mode("locked");
        end
    end
endfunction

function ld1_snapshot_solution_state()
    global LD1;
    ld1_save_step_inputs();
    S=struct();
    S.panel=LD1.panel;
    S.wires=LD1.wires;
    S.savedSeriesWires=LD1.savedSeriesWires;
    S.savedParallelWires=LD1.savedParallelWires;
    S.savedParallelVoltageWires=LD1.savedParallelVoltageWires;
    S.savedParallelVoltageVR=LD1.savedParallelVoltageVR;
    S.kclPrepared=LD1.kclPrepared;
    S.kclTargetA=LD1.kclTargetA;
    S.VR1=LD1.VR1;
    S.meterMode=LD1.meterMode;
    S.powerOn=LD1.powerOn;
    S.pendingTerminal=LD1.pendingTerminal;
    S.lastMeasurement=LD1.lastMeasurement;
    S.lastMeasurementUnit=LD1.lastMeasurementUnit;
    S.lastMeasurementStep=LD1.lastMeasurementStep;
    S.q=emptystr(1,3);
    for k=1:3
        S.q(k)=string(LD1.ui.qEdit(k).string);
    end
    S.typeSeries=LD1.ui.typeSeries.value;
    S.typeParallel=LD1.ui.typeParallel.value;
    S.typeMixed=LD1.ui.typeMixed.value;
    S.yes=LD1.ui.yes.value;
    S.no=LD1.ui.no.value;
    S.instructionTitle=string(LD1.ui.instructionTitle.string);
    S.instructionLines=emptystr(1,5);
    for k=1:5
        S.instructionLines(k)=string(LD1.ui.instructionLine(k).string);
    end
    S.resultsString=LD1.ui.resultsTable.string;
    S.checkStepString=string(LD1.ui.checkStep.string);
    LD1.demoSnapshot=S;
endfunction

function ld1_restore_solution_state()
    global LD1;
    S=LD1.demoSnapshot;
    LD1.demoMode=%f;
    if LD1.panel<>S.panel then
        ld1_build_panel(S.panel);
    end
    LD1.savedSeriesWires=S.savedSeriesWires;
    LD1.savedParallelWires=S.savedParallelWires;
    LD1.savedParallelVoltageWires=S.savedParallelVoltageWires;
    LD1.savedParallelVoltageVR=S.savedParallelVoltageVR;
    LD1.kclPrepared=S.kclPrepared;
    LD1.kclTargetA=S.kclTargetA;
    LD1.wires=S.wires;
    LD1.VR1=S.VR1;
    LD1.ui.vrSlider.value=S.VR1;
    if is_handle_valid(LD1.ui.vrText) then LD1.ui.vrText.string=string(S.VR1)+" Ω"; end
    ld1_apply_meter_mode_quiet(S.meterMode);
    ld1_set_power_quiet(S.powerOn);
    LD1.pendingTerminal=S.pendingTerminal;
    LD1.lastMeasurement=S.lastMeasurement;
    LD1.lastMeasurementUnit=S.lastMeasurementUnit;
    LD1.lastMeasurementStep=S.lastMeasurementStep;
    for k=1:3
        LD1.ui.qEdit(k).string=S.q(k);
    end
    LD1.ui.typeSeries.value=S.typeSeries;
    LD1.ui.typeParallel.value=S.typeParallel;
    LD1.ui.typeMixed.value=S.typeMixed;
    LD1.ui.yes.value=S.yes;
    LD1.ui.no.value=S.no;
    LD1.ui.instructionTitle.string=S.instructionTitle;
    for k=1:5
        LD1.ui.instructionLine(k).string=S.instructionLines(k);
        if S.instructionLines(k)=="" then
            ld1_show(LD1.ui.instructionLine(k),%f);
        else
            ld1_show(LD1.ui.instructionLine(k),%t);
        end
    end
    LD1.ui.resultsTable.string=S.resultsString;
    if LD1.step==9 then ld1_results_cards(S.resultsString); end
    LD1.ui.checkStep.string=S.checkStepString;
    ld1_button_string(LD1.ui.solution,"Pagalba → Pavyzdys");
    ld1_update_actual_values();
    if LD1.step==9 then
        // Suvestinėje multimetro valdiklio nėra.
    elseif ~isnan(LD1.lastMeasurement) then
        LD1.ui.meterDisplay.string=ld1_num(LD1.lastMeasurement,3)+" "+LD1.lastMeasurementUnit;
    else
        ld1_refresh_meter_idle_display();
    end
    ld1_set_solution_lock(%f);
    if LD1.step<9 then ld1_redraw_panel(); end
    ld1_set_status("Grąžintas jūsų darbas – pavyzdys nieko nepakeitė.","ok","Dabar galite atkartoti matytą jungimą ir skaičiavimus savo stende.");
endfunction

function ld1_apply_solution_state()
    global LD1;
    n=LD1.step;
    LD1.pendingTerminal="";
    LD1.lastMeasurement=%nan;
    LD1.lastMeasurementUnit="";
    LD1.lastMeasurementStep=0;
    LD1.ui.typeSeries.value=0; LD1.ui.typeParallel.value=0; LD1.ui.typeMixed.value=0;
    LD1.ui.yes.value=0; LD1.ui.no.value=0;

    if n<=4 then
        if LD1.panel<>"series" then ld1_build_panel("series"); end
        LD1.wires=ld1_series_canonical_wires();
        LD1.savedSeriesWires=LD1.wires;
        ld1_apply_meter_mode_quiet("A");
        if n==4 then LD1.VR1=500; else LD1.VR1=1000; end
        LD1.ui.vrSlider.value=LD1.VR1; LD1.ui.vrText.string=string(LD1.VR1)+" Ω";
        [R,I]=ld1_series_theory(LD1.VR1);
        if n==1 then
            ld1_set_power_quiet(%f);
            LD1.ui.typeSeries.value=1;
            ld1_set_instruction("PAVYZDYS – 1 ETAPAS",[
                "Pilnai sujungta nuosekli grandinė. Maitinimas išjungtas.";
                "+→R1(1); R1(2)→VR1(1); VR1(2)→+/mA; COM→−.";
                "Multimetras A (DC), nes srovė matuojama nuosekliai.";
                "Grandinės tipas: NUOSEKLI.";
                "Spauskite GRĮŽTI Į SAVO DARBĄ ir atkartokite jungimą."]);
        elseif n==2 then
            ld1_set_power_quiet(%f);
            LD1.ui.qEdit(1).string=ld1_num(R,3); LD1.ui.qEdit(2).string=ld1_num(I,3);
            ld1_set_instruction("PAVYZDYS – 2 ETAPAS",[
                "VR1 = 1000 Ω.";
                "Rbendr = R1 + 1000 = "+ld1_num(R,3)+" Ω.";
                "I [mA] = 1000·10/Rbendr = "+ld1_num(I,3)+" mA.";
                "Šiame etape matavimo dar nereikia.";
                "Spauskite GRĮŽTI Į SAVO DARBĄ ir perskaičiuokite patys."]);
        else
            ld1_set_power_quiet(%t);
            [mval,munit,mok]=ld1_solution_measure(n);
            if mok then mtxt=ld1_num(mval,3)+" "+munit; else mtxt="VIDINĖ MATAVIMO KLAIDA"; end
            LD1.ui.yes.value=1;
            if n==4 then
                LD1.ui.qEdit(1).string=ld1_num(R,3); LD1.ui.qEdit(2).string=ld1_num(I,3);
            end
            ld1_set_instruction("PAVYZDYS – "+string(n)+" ETAPAS",[
                "Ampermetras įjungtas nuosekliai, maitinimas 10 V.";
                "Teorinė srovė = "+ld1_num(I,3)+" mA.";
                "Virtualus ampermetras realiai apskaičiavo: "+mtxt+".";
                "Todėl atsakymas į palyginimą: TAIP.";
                "Spauskite GRĮŽTI Į SAVO DARBĄ ir atkartokite veiksmus."]);
        end
    elseif n>=5 & n<=7 then
        if LD1.panel<>"parallel" then ld1_build_panel("parallel"); end
        LD1.wires=ld1_parallel_voltage_canonical_wires();
        LD1.savedParallelWires=LD1.wires;
        LD1.savedParallelVoltageWires=LD1.wires;
        LD1.kclPrepared=%f;
        ld1_set_parallel_meter_layout(%f);
        ld1_apply_meter_mode_quiet("V");
        if n==7 then LD1.VR1=500; else LD1.VR1=1000; end
        LD1.ui.vrSlider.value=LD1.VR1; LD1.ui.vrText.string=string(LD1.VR1)+" Ω";
        Rb=ld1_parallel_theory(LD1.VR1);
        if n==5 then
            ld1_set_power_quiet(%f);
            LD1.ui.typeParallel.value=1;
            ld1_set_instruction("PAVYZDYS – 5 ETAPAS",[
                "Pilnai sujungta lygiagreti grandinė; maitinimas išjungtas.";
                "+→A1, −→B1; R3 tarp A2-B2.";
                "R2 ir VR1 nuosekliai tarp A3-B3.";
                "Voltmetras: +/V→A4, COM→B4; režimas V (DC).";
                "Spauskite GRĮŽTI Į SAVO DARBĄ ir atkartokite jungimą."]);
        elseif n==6 then
            ld1_set_power_quiet(%t);
            [mval,munit,mok]=ld1_solution_measure(6);
            if mok then mtxt=ld1_num(mval,3)+" "+munit; else mtxt="VIDINĖ MATAVIMO KLAIDA"; end
            LD1.ui.qEdit(1).string=ld1_num(Rb,3); LD1.ui.yes.value=1;
            ld1_set_instruction("PAVYZDYS – 6 ETAPAS",[
                "Rš2 = R2 + 1000 Ω.";
                "Rbendr = (R3·Rš2)/(R3+Rš2) = "+ld1_num(Rb,3)+" Ω.";
                "Virtualus voltmetras tarp A-B realiai apskaičiavo: "+mtxt+".";
                "Todėl UAB ≈ 10 V → TAIP.";
                "Spauskite GRĮŽTI Į SAVO DARBĄ ir atkartokite veiksmus."]);
        else
            ld1_set_power_quiet(%t);
            [mval,munit,mok]=ld1_solution_measure(7);
            if mok then mtxt=ld1_num(mval,3)+" "+munit; else mtxt="VIDINĖ MATAVIMO KLAIDA"; end
            LD1.ui.no.value=1;
            ld1_set_instruction("PAVYZDYS – 7 ETAPAS",[
                "VR1 pakeistas į 500 Ω; kitų laidų nekeista.";
                "Voltmetras vis dar tarp A-B ir realiai apskaičiavo: "+mtxt+".";
                "Idealiame 10 V šaltinyje UAB lieka apie 10 V.";
                "Todėl klausimas „ar UAB pakito?“ → NE.";
                "Spauskite GRĮŽTI Į SAVO DARBĄ ir atkartokite veiksmus."]);
        end
    elseif n==8 then
        if LD1.panel<>"parallel" then ld1_build_panel("parallel"); end
        LD1.kclTargetA=LD1.demoSnapshot.kclTargetA;
        if LD1.kclTargetA=="" then LD1.kclTargetA="NODE_A1"; end
        LD1.kclPrepared=%t;
        LD1.wires=ld1_parallel_kcl_canonical_wires();
        LD1.savedParallelWires=LD1.wires;
        ld1_set_parallel_meter_layout(%t);
        ld1_apply_meter_mode_quiet("A");
        LD1.VR1=0; LD1.ui.vrSlider.value=0; LD1.ui.vrText.string="0 Ω";
        ld1_set_power_quiet(%t);
        [I1,I2,It]=ld1_parallel_currents(0);
        targetA=ld1_terminal_button_text(LD1.kclTargetA);
        LD1.ui.qEdit(1).string=ld1_num(I1,3);
        LD1.ui.qEdit(2).string=ld1_num(I2,3);
        LD1.ui.qEdit(3).string=ld1_num(It,3);
        LD1.ui.yes.value=1;
        [mval,munit,mok]=ld1_solution_measure(8);
        if mok then mtxt=ld1_num(mval,3)+" "+munit; else mtxt="VIDINĖ MATAVIMO KLAIDA"; end
        ld1_set_instruction("PAVYZDYS – 8 ETAPAS",[
            "Ampermetras yra BENDRAME laide PRIEŠ mazgą A.";
            "Tiksliai: šaltinio +→+/mA; COM→"+targetA+"; šaltinio −→B1.";
            "R3 yra A-B šaka; R2+VR1 yra kita A-B šaka; VR1=0 Ω.";
            "I1=1000·10/R3="+ld1_num(I1,3)+" mA; I2=1000·10/R2="+ld1_num(I2,3)+" mA; suma="+ld1_num(It,3)+" mA.";
            "Virtualus ampermetras realiai apskaičiavo: "+mtxt+"."]);
    else
        ld1_update_results_table(%t);
        ld1_set_instruction("PAVYZDYS – 9 ETAPAS",[
            "Rodoma pilnai atlikto IDEALAUS darbo suvestinė.";
            "Kiekvienoje eilutėje formulė paaiškina, iš kur gautas skaičius.";
            "Tai nėra jūsų rezultatai – jūsų duomenys liko išsaugoti.";
            "NEATLIKTA jūsų suvestinėje reiškia praleistą etapą.";
            "Spauskite GRĮŽTI Į SAVO DARBĄ, kad grįžtų jūsų suvestinė."]);
    end

    ld1_update_actual_values();
    if n<9 then
        LD1.ui.meterDisplay.string="—";
        if ~isnan(LD1.lastMeasurement) then
            LD1.ui.meterDisplay.string=ld1_num(LD1.lastMeasurement,3)+" "+LD1.lastMeasurementUnit;
        else
            ld1_refresh_meter_idle_display();
        end
        ld1_redraw_panel();
    end
endfunction

function ld1_toggle_solution()
    global LD1;
    if LD1.assessment & ~LD1.demoMode then
        if ~ld1_enter_learning() then return; end
    end
    if LD1.demoMode then
        ld1_restore_solution_state();
        return;
    end
    LD1.practice_used=%t; bench_autosave("LD1");
    ld1_snapshot_solution_state();
    LD1.demoMode=%t;
    ld1_button_string(LD1.ui.solution,"GRĮŽTI Į SAVO DARBĄ");
    ld1_apply_solution_state();
    ld1_set_solution_lock(%t);
    ld1_set_status("RODOMAS TEISINGAS PAVYZDYS – jūsų darbas nepakeistas.","warn","Peržiūrėkite laidus, režimą, VR1, formules ir rodmenį. Tada spauskite GRĮŽTI Į SAVO DARBĄ ir atkartokite.");
endfunction

function ld1_show_help()
    global LD1;
    txt=["LD1 – TEORIJA IR STENDO ATMINTINĖ";
         "";
         "STENDO VALDYMAS";
         "• Laidui prijungti: spauskite vieną rodomą lizdą, tada kitą.";"• Kontaktų numerius (T01–T20) rodo gnybtų žymės ir STENDO ŽEMĖLAPIS [B13].";
         "• 1 ir 5 etapuose jungiate visą schemą; 2–4 ir 6–7 etapuose patikrinti laidai užrakinami.";
         "• 8 etape aktyvūs tik 4 lizdai: šaltinio +, +/mA, COM ir nurodytas A lizdas.";
         "• PATIKRINTI SUJUNGIMĄ [B09] parodo: kas blogai + kaip tiksliai pataisyti.";
         "• KAIP SUJUNGTI [B05] parodo visą dabartinio etapo jungimo sąrašą.";
         "• PAVYZDYS / SPRENDIMAS [B17] laikinai parodo pilnai teisingą, veikiantį dabartinio etapo variantą.";
         "• Grįžus iš PAVYZDŽIO jūsų laidai, atsakymai ir matavimai lieka tokie, kokie buvo.";
         "• ATKURTI ETAPO STENDĄ [B12] atkuria tik šio etapo saugią pradinę būseną.";
         "• Atsiskaityme TOLIAU leidžia tęsti tik sujungus grandinę ir įrašius etapo duomenis.";
         "• Paaiškinimas ir teorija prieinami atsiskaityme. Sprendimo pavyzdys perjungia į mokymąsi.";
         "";
         "MATAVIMO TAISYKLĖS";
         "• Ampermetras jungiamas NUOSEKLIAI su matuojama srove.";
         "• Voltmetras jungiamas LYGIAGREČIAI tarp A ir B.";
         "• Skaitinis rodmuo atsiranda tik paspaudus MATUOTI [B06].";
         "";
         "REIKALINGOS FORMULĖS";
         "• Omo dėsnis: I = U/R.";
         "• Nuosekliai: Rbendr = R1 + R2 + ...; visur teka ta pati I.";
         "• Lygiagrečiai: U1 = U2 = UAB.";
         "• 2-oji šaka: Rš2 = R2 + VR1.";
         "• Rbendr = (R3·Rš2)/(R3+Rš2).";
         "• Kirchhoffas mazge: Ibendr = I1 + I2.";
         "• Srovė miliamperais: I [mA] = 1000·U [V]/R [Ω].";
         "• 8 etape VR1=0 Ω: I1 [mA]=1000·E/R3, I2 [mA]=1000·E/R2.";
         "";
         "PASTABOS APIE VIRTUALIĄ LABORATORORIJĄ";
         "• Atsakymų skaitinė tolerancija yra programos mokomoji taisyklė, ne originalaus aprašo tekstas.";
         "• 8 etape voltmetras vizualiai nuimamas, kad stendas būtų aiškesnis; 13–14 punktams jo rodmens nereikia.";
         "• Varžos įvedamos omais: 1 kΩ = 1000 Ω."];
    ld1_show_text_window("LD1 – teorija ir valdymas",txt);
endfunction

function ld1_restart()
    global LD1;
    answ=messagebox("Ar tikrai pradėti laboratorinį darbą iš naujo?","LD1","question",["Taip" "Ne"],"modal");
    if answ==1 then
        ld1_save_step_inputs(); bench_autosave("LD1");
        if isfield(LD1,"autosave_error") then
            if LD1.autosave_error<>"" then return; end
        end
        try
            delete(LD1.fig);
        catch
        end
        LD1.assessment=%t; LD1.guided=%f; LD1.practice_used=%f;
        LD1.autosave_paths=emptystr(0,1);
        ld1_init_state();
        ld1_init_terminals();
        ld1_create_gui();
        ld1_build_panel("series");
        ld1_set_step(1);
        LD1.fig.resizefcn="ld1_resize("+string(LD1.fig.figure_id)+")";
        ld1_save_step_inputs(); bench_autosave("LD1");
    end
endfunction

function ld1_prev_step()
    global LD1;
    if LD1.step<=1 then return; end
    if LD1.reviewMode then
        ld1_jump_step(LD1.step-1);
    else
        ld1_set_step(LD1.step-1);
    end
endfunction

function ld1_next_step()
    global LD1;
    if LD1.step>=9 then return; end
    if LD1.reviewMode then
        ld1_jump_step(LD1.step+1);
        return;
    end
    if LD1.done(LD1.step) then
        ld1_set_step(LD1.step+1);
        return;
    end

    answ=messagebox([
        "Dabartinis etapas dar neužbaigtas.";
        "Galite pereiti toliau ir grįžti vėliau.";
        "Praleistas etapas bus pažymėtas GELTONAI, o 9 etape jo rezultatai bus NEATLIKTA.";
        "Kitas stendas bus paruoštas saugiai, todėl nereikės visko pradėti nuo pradžių."], ..
        "LD1 – pereiti nebaigus?","question",["LIKTI IR BAIGTI" "PEREITI NEBAIGUS"],"modal");
    if answ<>2 then return; end

    old=LD1.step;
    ld1_save_step_inputs();
    LD1.skipped(old)=%t;
    nxt=old+1;
    ld1_set_step(nxt);
    if nxt<9 then ld1_prepare_review_stage(nxt); end
    ld1_update_step_navigation();
    ld1_set_status("Etapas "+string(old)+" praleistas – galite grįžti vėliau.","warn","Geltonas etapo numeris reiškia NEBAIGTA. Kitas stendas paruoštas teisingai, kad galėtumėte tęsti testavimą.");
endfunction

function ld1_set_wiring_edit_mode(mode)
    // full   – studentas šiame etape pats jungia visą schemą (1 ir 5).
    // locked – ankstesniame etape patikrinta schema užrakinta nuo atsitiktinio sugadinimo.
    // meter  – 8 etape leidžiama keisti tik du ampermetro laidus; visų laidų valymas išjungtas.
    global LD1;
    select mode
    case "full" then
        ld1_enable(LD1.ui.undoWire,%t);
        ld1_enable(LD1.ui.clearWires,%t);
    case "meter" then
        ld1_enable(LD1.ui.undoWire,%t);
        ld1_enable(LD1.ui.clearWires,%f);
    else
        ld1_enable(LD1.ui.undoWire,%f);
        ld1_enable(LD1.ui.clearWires,%f);
    end
endfunction

function ld1_prepare_step_common()
    global LD1;
    ld1_hide_all_answers();
    LD1.ui.resultsTable.visible="off";
    LD1.ui.resultsTable.position=[0.04 0.10 0.92 0.78];
    ld1_button_string(LD1.ui.checkStep,"PATIKRINTI IR UŽFIKSUOTI ETAPĄ");
    ld1_button_string(LD1.ui.solution,"Pagalba → Pavyzdys");
    LD1.ui.instructionFrame.visible="on";
    LD1.ui.instructionFrame.position=[0.035 0.735 0.93 0.245];
    LD1.ui.standFrame.visible="on";
    LD1.ui.answerFrame.visible="on";
    if LD1.step<9 then ld1_redraw_panel(); end
    ld1_enable(LD1.ui.prev, LD1.step>1);
    LD1.ui.progress.string="Etapas "+string(LD1.step)+" / 9";
    ld1_update_step_navigation();
endfunction

function ld1_update_step_navigation()
    global LD1;
    if ~isfield(LD1.ui,"stepButtons") then return; end
    for k=1:9
        h=LD1.ui.stepButtons(k);
        if k==LD1.step then
            h.backgroundcolor=[0.20 0.48 0.78];
            ld1_enable(h,%t);
        elseif LD1.done(k) then
            h.backgroundcolor=[0.72 0.92 0.74];
            ld1_enable(h,%t);
        elseif LD1.skipped(k) then
            h.backgroundcolor=[1.00 0.86 0.56];
            ld1_enable(h,%t);
        elseif LD1.reviewMode then
            h.backgroundcolor=[0.93 0.93 0.93];
            ld1_enable(h,%t);
        else
            h.backgroundcolor=[0.93 0.93 0.93];
            ld1_enable(h,%f);
        end
    end
    if LD1.step<9 then
        ld1_enable(LD1.ui.next,%t);
    else
        ld1_enable(LD1.ui.next,%f);
    end
    if exists("ld1_student_sync")==1 then ld1_student_sync(); end
endfunction

function ld1_review_toggle()
    global LD1;
    LD1.reviewMode=(LD1.ui.review.value<>0);
    ld1_update_step_navigation();
    if LD1.reviewMode then
        ld1_set_status("PERŽIŪROS REŽIMAS įjungtas.","warn","Galite spausti bet kurį etapo numerį 1–9 arba TOLIAU. Neatlikti etapai nebus pažymėti kaip užbaigti; stendas bus paruoštas to etapo pradžiai.");
    else
        ld1_set_status("Grįžta įprastas studento režimas.","info","TOLIAU bus leidžiama tik užfiksavus dabartinį etapą.");
    end
endfunction

function ld1_jump_step(n)
    global LD1;
    if n<1 | n>9 | n==LD1.step then return; end
    if ~LD1.reviewMode then
        if LD1.done(n) then
            ld1_set_step(n);
        elseif LD1.skipped(n) then
            ld1_set_step(n);
            if n<9 then ld1_prepare_review_stage(n); end
            ld1_set_status("Grįžote į anksčiau praleistą "+string(n)+" etapą.","warn","Etapo atsakymai išsaugoti; stendas paruoštas saugioje pradinėje būsenoje.");
        else
            ld1_set_status("Šis etapas dar neatliktas.","warn","Galite naudoti TOLIAU → PEREITI NEBAIGUS arba viršuje įjungti PERŽIŪROS REŽIMĄ.");
        end
        return;
    end
    ld1_set_step(n);
    if n<9 then ld1_prepare_review_stage(n); end
    ld1_update_step_navigation();
    ld1_set_status("Atidarytas "+string(n)+" etapas peržiūros režimu.","info","Stendas paruoštas taip, kad šį etapą galėtumėte tikrinti nepradėję laboratorinio nuo 1 etapo.");
endfunction

function ld1_set_step(n)
    global LD1;
    if n<1 | n>9 then return; end

    // Prieš paliekant etapą išsaugomi visi studento įrašai ir matavimas.
    if isfield(LD1,"ui") then ld1_save_step_inputs(); end

    oldStep=LD1.step;
    if oldStep==8 & n<=7 then
        ld1_restore_voltage_stage_wiring();
    end
    LD1.step=n;
    LD1.lastMeasurement=%nan; LD1.lastMeasurementUnit=""; LD1.lastMeasurementStep=0;
    // 9 etape lenta išvaloma, todėl grįžtant rodmens valdiklis gali būti dar
    // nesukurtas – jį atkurs artėjantis ld1_redraw_panel.
    if is_handle_valid(LD1.ui.meterDisplay) then LD1.ui.meterDisplay.string="—"; end

    if n<=4 & LD1.panel<>"series" then ld1_switch_panel("series"); end
    if n>=5 & n<=8 & LD1.panel<>"parallel" then ld1_switch_panel("parallel"); end
    ld1_prepare_step_common();
    if n==1 | n==5 then
        ld1_set_wiring_edit_mode("full");
    elseif n==8 then
        ld1_set_wiring_edit_mode("meter");
    else
        ld1_set_wiring_edit_mode("locked");
    end

    select n
    case 1 then
        LD1.powerOn=%f; ld1_button_string(LD1.ui.power,"IŠJUNGTA"); LD1.ui.power.backgroundcolor=[0.94 0.82 0.82]; LD1.ui.sourceDisplay.string="0 V DC";
        ld1_apply_meter_mode_quiet("A");
        LD1.VR1=1000; LD1.ui.vrSlider.value=1000; LD1.ui.vrText.string="1000 Ω"; ld1_update_actual_values();
        ld1_set_instruction("1. SUJUNKITE NUOSEKLIĄ GRANDINĘ", [
            "1) Šaltinio + [T01] → R1 [T03].";
            "2) R1 [T04] → VR1 [T09].";
            "3) VR1 [T10] → +/mA [T11]; COM [T12] → šaltinio − [T02].";
            "4) Multimetras A (DC) [B07], maitinimas [B01] IŠJUNGTAS. Turi būti 4 laidai.";
            "5) Jei neaišku – KAIP SUJUNGTI [B05]. Tada pasirinkite NUOSEKLI."]);
        ld1_show(LD1.ui.typeSeries,%t); ld1_show(LD1.ui.typeParallel,%t); ld1_show(LD1.ui.typeMixed,%t);
        ld1_set_status("Sujunkite vieną uždarą nuoseklią kilpą.","info","Tikslus laidų sąrašas pasiekiamas mygtuku KAIP SUJUNGTI [B05].");
    case 2 then
        LD1.VR1=1000; LD1.ui.vrSlider.value=1000; LD1.ui.vrText.string="1000 Ω"; ld1_update_actual_values();
        ld1_set_instruction("2. TEORINIS SKAIČIAVIMAS", [
            "Jungimo nekeiskite. VR1 = 1000 Ω [B04].";
            "Apskaičiuokite Rbendr = R1 + VR1 ir įrašykite į [A02.01].";
            "Apskaičiuokite I [mA] = 1000·E / Rbendr ir įrašykite į [A02.02].";
            "Srovę galite pamatuoti pasitikrinimui: įjunkite šaltinį [B01] ir spauskite MATUOTI [B06]."]);
        ld1_show_numeric_field(1,"Rbendr, Ω"); ld1_show_numeric_field(2,"I skaič., mA");
        ld1_set_status("Apskaičiuokite teorines reikšmes.","info","Jei grįžote iš vėlesnio etapo, ankstesni įrašai bus atkurti automatiškai.");
    case 3 then
        LD1.VR1=1000; LD1.ui.vrSlider.value=1000; LD1.ui.vrText.string="1000 Ω"; ld1_update_actual_values();
        ld1_apply_meter_mode_quiet("A");
        ld1_set_instruction("3. IŠMATUOKITE SROVĘ", [
            "Jungimas toks pats kaip 1 etape; VR1 = 1 kΩ [B04].";
            "1) Įjunkite 10 V maitinimą [B01].";
            "2) Multimetras A (DC) [B07]; spauskite MATUOTI [B06].";
            "3) Palyginkite rodmenį su 2 etapo skaičiavimu.";
            "4) Pažymėkite Taip arba Ne."]);
        ld1_show_yes_no("Ar I išmatuota ≈ I apskaičiuota?");
        ld1_set_status("Paruošta srovės matavimui.","info","Jei sujungimas sugadintas – spauskite ATKURTI ETAPO STENDĄ [B12], tada įjunkite maitinimą [B01] ir MATUOTI [B06].");
    case 4 then
        ld1_set_instruction("4. VR1 = 500 Ω", [
            "Jungimo nekeiskite. VR1 = 500 Ω [B03].";
            "1) Apskaičiuokite Rbendr = R1 + VR1 → [A04.01].";
            "2) Apskaičiuokite I [mA] = 1000·E / Rbendr → [A04.02].";
            "3) Įjunkite maitinimą [B01], MATUOTI [B06] ir palyginkite reikšmes.";
            "4) Pažymėkite Taip/Ne. Mažesnė Rbendr turi duoti didesnę I."]);
        ld1_show_numeric_field(1,"Rbendr, Ω"); ld1_show_numeric_field(2,"I skaič., mA");
        ld1_show_yes_no("Ar I išmatuota ≈ I apskaičiuota?");
        ld1_set_status("Pakartokite nuoseklios grandinės bandymą su VR1 = 500 Ω.","info","Jungimo keisti nereikia – keičiasi tik VR1 [B03] ir srovė.");
    case 5 then
        LD1.kclPrepared=%f;
        ld1_set_parallel_meter_layout(%f);
        LD1.powerOn=%f; ld1_button_string(LD1.ui.power,"IŠJUNGTA"); LD1.ui.power.backgroundcolor=[0.94 0.82 0.82]; LD1.ui.sourceDisplay.string="0 V DC";
        LD1.VR1=1000; LD1.ui.vrSlider.value=1000; LD1.ui.vrText.string="1000 Ω"; ld1_update_actual_values();
        ld1_set_instruction("5. SUJUNKITE LYGIAGREČIĄ GRANDINĘ", [
            "1) Šaltinis: + [T01]→A1 [T13], − [T02]→B1 [T17].";
            "2) Šaka 1: A2 [T14]→R3 [T07]; R3 [T08]→B2 [T18].";
            "3) Šaka 2: A3 [T15]→R2 [T05]; R2 [T06]→VR1 [T09]; VR1 [T10]→B3 [T19].";
            "4) Voltmetras: +/V [T11]→A4 [T16]; COM [T12]→B4 [T20]; režimas V (DC) [B08].";
            "5) Mazgai: T13–T16 ir T17–T20 bendri. Iš viso 9 laidai."]);
        ld1_show(LD1.ui.typeSeries,%t); ld1_show(LD1.ui.typeParallel,%t); ld1_show(LD1.ui.typeMixed,%t);
        ld1_set_status("Sujunkite dvi lygiagrečias šakas tarp A ir B bei voltmetrą tarp A-B.","info","Jei kontaktai painūs – spauskite KAIP SUJUNGTI [B05]: ten nurodytas kiekvienas konkretus lizdas.");
    case 6 then
        ld1_apply_meter_mode_quiet("V");
        LD1.VR1=1000; LD1.ui.vrSlider.value=1000; LD1.ui.vrText.string="1000 Ω"; ld1_update_actual_values();
        ld1_set_instruction("6. APSKAIČIUOKITE IR IŠMATUOKITE", [
            "Jungimas toks pats kaip 5 etape; VR1 = 1 kΩ [B04].";
            "1) Bendrą lygiagrečios grandinės varžą apskaičiuokite → [A06.01].";
            "2) Įjunkite 10 V maitinimą [B01].";
            "3) Voltmetru išmatuokite UAB: MATUOTI [B06] (režimas V [B08]).";
            "4) Pažymėkite, ar UAB ≈ 10 V (Taip/Ne)."]);
        ld1_show_numeric_field(1,"Rbendr, Ω"); ld1_show_yes_no("Ar UAB ≈ 10 V?");
        ld1_set_status("Paruošta UAB skaičiavimui ir matavimui.","info","Voltmetro +/V [T11] turi būti A4 [T16], COM [T12] – B4 [T20]. Jei ne – ATKURTI ETAPO STENDĄ [B12].");
    case 7 then
        ld1_apply_meter_mode_quiet("V");
        ld1_set_instruction("7. PAKEISKITE VR1 IR STEBĖKITE UAB", [
            "Jungimo nekeiskite – voltmetras lieka tarp [T16] ir [T20].";
            "1) Pakeiskite VR1 nuo 1 kΩ, pvz., į 500 Ω [B03] arba slankikliu [V01].";
            "2) Dar kartą paspauskite MATUOTI [B06].";
            "3) Palyginkite naują UAB su 6 etapo reikšme.";
            "4) Pažymėkite, ar UAB pakito."]);
        ld1_show_yes_no("Ar pakeitus VR1, UAB pakito?");
        ld1_set_status("Pakeiskite tik VR1 ir atlikite naują UAB matavimą.","info","Jei sujungimas pasikeitė netyčia – ATKURTI ETAPO STENDĄ [B12] ir kartokite tik VR1 pakeitimą.");
    case 8 then
        if ~LD1.kclPrepared then ld1_prepare_kcl_stage(); end
        targetA=ld1_terminal_button_text(LD1.kclTargetA);
        tpart="";
        if exists("ld1_terminal_code")==1 then tpart=" ["+ld1_terminal_code(LD1.kclTargetA)+"]"; end
        ld1_set_instruction("8. BENDRA SROVĖ IR KIRCHHOFO DĖSNIS", [
            "Ampermetras [B07] – BENDRAME laide prieš srovės išsišakojimą mazge A.";
            "1) Šaltinio + [T01] → +/mA [T11].";
            "2) COM [T12] → "+targetA+tpart+"; kitų 6 užrakintų laidų nelieskite.";
            "3) VR1=0 Ω [B02]; PATIKRINTI SUJUNGIMĄ [B09]; 10 V [B01]; MATUOTI [B06].";
            "4) I1=1000·10/R3 → [A08.01]; I2=1000·10/R2 → [A08.02]; I=I1+I2 → [A08.03] (mA)."]);
        ld1_show_numeric_field(1,"I1 (R3), mA"); ld1_show_numeric_field(2,"I2 (R2), mA"); ld1_show_numeric_field(3,"I1 + I2, mA");
        ld1_show_yes_no("Ar ampermetro I ≈ I1 + I2?");
        ld1_set_status("8 etape turite pridėti tik 2 ampermetro laidus.","info","Jei neaišku – PAVYZDYS / SPRENDIMAS [B17] parodo pilnai sujungtą ir veikiantį 8 etapą; grįžus jūsų darbas lieka nepakeistas.");
    case 9 then
        LD1.ui.progress.string="9 / 9 – rezultatų suvestinė";
        LD1.ui.standFrame.visible="off";
        LD1.ui.answerFrame.visible="off";
        LD1.ui.instructionFrame.position=[0.035 0.43 0.93 0.55];
        ld1_set_instruction("9. PROGRAMOS SUVESTINĖ – IŠ KUR ATSIRADO SKAIČIAI?", [
            "Tai PAPILDOMA virtualios laboratorijos suvestinė; originaliame apraše atskiro 9 matavimo etapo nėra.";
            "1–2 eilutės: 2–4 etapų [E02]–[E04] nuoseklios grandinės skaičiavimai ir ampermetro rodmenys.";
            "3 eilutė: 6 etapo [E06] lygiagrečios grandinės Rbendr ir UAB voltmetro rodmuo.";
            "4 eilutė: 7 etapo [E07] UAB matavimas pakeitus VR1.";
            "5 eilutė: 8 etapo [E08] I1=1000·E/R3, I2=1000·E/R2, jų suma ir bendros srovės ampermetro rodmuo (mA).";
            "NEATLIKTA = etapas praleistas. PAVYZDYS / SPRENDIMAS [B17] = pilnas idealus variantas su formulėmis."]);
        ld1_clear_board_controls();
        ld1_board_text([0.03 0.875 0.94 0.055],"9. JŪSŲ REZULTATAI",15,%t,"left",[1 1 1],[0.10 0.23 0.38]);
        ld1_board_text([0.03 0.815 0.94 0.050],"Lentelė tik SURINKA ankstesnių etapų duomenis – ji nekuria naujų skaičių.",10,%f,"left",[1 1 1],[0.18 0.22 0.28]);
        LD1.ui.resultsTable.position=[0.025 0.12 0.95 0.67];
        LD1.ui.resultsTable.visible="on";
        ld1_update_results_table(%f);
        ld1_button_string(LD1.ui.checkStep,"EKSPORTUOTI MANO REZULTATUS CSV");
        LD1.done(9)=%t;
        ld1_set_status("9 etapas – tik aiški ankstesnių rezultatų suvestinė.","ok","Jei norite pamatyti, kaip turi atrodyti pilnai atliktas darbas, spauskite PAVYZDYS / SPRENDIMAS [B17].");
    end

    // Atkuriame to etapo anksčiau įvestus atsakymus ir matavimą.
    ld1_restore_step_inputs(n);
    ld1_guided_prepare();

    if n<9 then
        ld1_refresh_meter_idle_display();
        ld1_redraw_panel();
    end
    ld1_update_step_navigation();
endfunction
function yes = ld1_yes_selected()
    global LD1;
    yes=(LD1.ui.yes.value<>0);
endfunction

function selected = ld1_any_yesno_selected()
    global LD1;
    selected=(LD1.ui.yes.value<>0 | LD1.ui.no.value<>0);
endfunction

function ld1_mark_done(msg)
    global LD1;
    LD1.done(LD1.step)=%t;
    LD1.skipped(LD1.step)=%f;
    ld1_save_step_inputs();
    ld1_update_step_navigation();
    ld1_set_status(msg,"ok","Etapas išsaugotas. Galite spausti TOLIAU arba vėliau grįžti – įvesti duomenys liks.");
endfunction

function ld1_check_step()
    global LD1;
    n=LD1.step;
    if n==9 then ld1_export_results(); return; end

    select n
    case 1 then
        [ok,msg,fix]=ld1_validate_series_topology();
        if ~ok then ld1_set_status(msg,"error",fix); return; end
        if LD1.ui.typeSeries.value==0 then
            ld1_set_status("Grandinės tipas pasirinktas neteisingai.","error","Pažymėkite NUOSEKLI: R1, VR1, ampermetru ir šaltiniu yra tik vienas srovės kelias."); return;
        end
        ld1_mark_done("Teisingai: grandinė nuosekli, ampermetras įjungtas nuosekliai.");

    case 2 then
        if abs(LD1.VR1-1000)>1 then ld1_set_status("VR1 nėra 1000 Ω.","error","Paspauskite mygtuką 1 kΩ [B04] arba slankikliu [V01] nustatykite 1000 Ω."); return; end
        [R,I]=ld1_series_theory(1000);
        uR=ld1_parse_number(LD1.ui.qEdit(1).string); uI=ld1_parse_number(LD1.ui.qEdit(2).string);
        if isnan(uR) then ld1_set_status("Rbendr laukas tuščias arba įrašas nėra skaičius.","error","Įrašykite tik skaičių omais. Formulė: Rbendr = R1 + 1000 Ω."); return; end
        if ~ld1_close_enough(uR,R) then ld1_set_status("Rbendr reikšmė neteisinga.","error","Naudokite Rbendr = R1 + VR1. Abi varžos turi būti omais; VR1 = 1000 Ω."); return; end
        if isnan(uI) then ld1_set_status("Srovės laukas tuščias arba įrašas nėra skaičius.","error","Skaičiuokite I = 10 V / Rbendr. Gautus amperus padauginkite iš 1000 ir įrašykite mA."); return; end
        if ~ld1_close_enough(uI,I) then ld1_set_status("Apskaičiuota srovė neteisinga.","error","Naudokite I = E/Rbendr, E=10 V. Nepamirškite A → mA: ×1000."); return; end
        LD1.res.Rseries1000=uR; LD1.res.Iseries1000=uI;
        ld1_mark_done("Teoriniai skaičiavimai ties VR1 = 1 kΩ teisingi.");

    case 3 then
        [ok,msg,fix]=ld1_validate_series_topology(); if ~ok then ld1_set_status(msg,"error",fix); return; end
        if ~LD1.powerOn then ld1_set_status("Maitinimo šaltinis išjungtas.","error","Paspauskite maitinimo mygtuką [B01], kad būtų 10 V DC, tada MATUOTI [B06]."); return; end
        if LD1.lastMeasurementStep<>3 | isnan(LD1.lastMeasurement) then ld1_set_status("Šiame etape dar nėra srovės matavimo.","error","Paspauskite MATUOTI [B06]. Jei gaunate KLAIDA – pirmiausia PATIKRINTI SUJUNGIMĄ [B09]."); return; end
        if ~ld1_any_yesno_selected() then ld1_set_status("Nepasirinktas atsakymas Taip/Ne.","error","Pažymėkite Taip, jei išmatuota ir apskaičiuota srovė skiriasi ne daugiau kaip 5 %; kitu atveju Ne."); return; end
        theo=LD1.res.Iseries1000; meas=LD1.lastMeasurement;
        if isnan(theo) then [rr,theo]=ld1_series_theory(1000); end
        err=abs(meas-theo)/max(theo,1e-9); expectedYes=(err<=0.05);
        if ld1_yes_selected()<>expectedYes then ld1_set_status("Taip/Ne pasirinkimas neatitinka skaitinio palyginimo.","error","Apskaičiuokite santykinį skirtumą. ≤5 % → Taip; >5 % → Ne."); return; end
        LD1.res.Mseries1000=meas; LD1.res.Errseries1000=err*100;
        ld1_mark_done("Matavimas užfiksuotas. Skirtumas = "+ld1_num(err*100,2)+" %.");

    case 4 then
        [ok,msg,fix]=ld1_validate_series_topology(); if ~ok then ld1_set_status(msg,"error",fix); return; end
        if abs(LD1.VR1-500)>1 then ld1_set_status("VR1 nėra 500 Ω.","error","Paspauskite 500 Ω mygtuką [B03]."); return; end
        [R,I]=ld1_series_theory(500);
        uR=ld1_parse_number(LD1.ui.qEdit(1).string); uI=ld1_parse_number(LD1.ui.qEdit(2).string);
        if isnan(uR) | ~ld1_close_enough(uR,R) then ld1_set_status("Rbendr ties VR1=500 Ω neteisinga.","error","Naudokite Rbendr = R1 + 500 Ω."); return; end
        if isnan(uI) | ~ld1_close_enough(uI,I) then ld1_set_status("I ties VR1=500 Ω neteisinga.","error","Naudokite I [mA] = 1000·10 V / Rbendr."); return; end
        if ~LD1.powerOn then ld1_set_status("Maitinimo šaltinis išjungtas.","error","Įjunkite 10 V DC [B01] ir paspauskite MATUOTI [B06]."); return; end
        if LD1.lastMeasurementStep<>4 | isnan(LD1.lastMeasurement) then ld1_set_status("Trūksta srovės matavimo.","error","Paspauskite MATUOTI [B06], tada palyginkite su apskaičiuota I."); return; end
        if ~ld1_any_yesno_selected() then ld1_set_status("Nepasirinktas Taip/Ne.","error","Pažymėkite, ar išmatuota ir apskaičiuota srovė sutampa 5 % ribose."); return; end
        meas=LD1.lastMeasurement; err=abs(meas-uI)/max(uI,1e-9); expectedYes=(err<=0.05);
        if ld1_yes_selected()<>expectedYes then ld1_set_status("Taip/Ne pasirinkimas neatitinka rezultato.","error","≤5 % skirtumas → Taip; >5 % → Ne."); return; end
        LD1.res.Rseries500=uR; LD1.res.Iseries500=uI; LD1.res.Mseries500=meas; LD1.res.Errseries500=err*100;
        ld1_mark_done("VR1 = 500 Ω bandymas baigtas. Sumažinus Rbendr, srovė padidėjo.");

    case 5 then
        [ok,msg,fix]=ld1_validate_parallel_voltage_topology();
        if ~ok then ld1_set_status(msg,"error",fix); return; end
        if LD1.ui.typeParallel.value==0 then ld1_set_status("Grandinės tipas pasirinktas neteisingai.","error","Pažymėkite LYGIAGRETI: R3 ir R2+VR1 yra dvi šakos tarp tų pačių A ir B mazgų."); return; end
        ld1_mark_done("Teisingai: dvi šakos yra lygiagrečios, voltmetras prijungtas tarp A ir B.");

    case 6 then
        [ok,msg,fix]=ld1_validate_parallel_voltage_topology(); if ~ok then ld1_set_status(msg,"error",fix); return; end
        if abs(LD1.VR1-1000)>1 then ld1_set_status("VR1 nėra 1000 Ω.","error","Paspauskite 1 kΩ mygtuką [B04]."); return; end
        R=ld1_parallel_theory(1000); uR=ld1_parse_number(LD1.ui.qEdit(1).string);
        if isnan(uR) | ~ld1_close_enough(uR,R) then ld1_set_status("Bendra lygiagrečios grandinės varža neteisinga.","error","Pirma Rš2=R2+VR1. Tada Rbendr=(R3·Rš2)/(R3+Rš2). VR1=1000 Ω."); return; end
        if ~LD1.powerOn then ld1_set_status("Maitinimo šaltinis išjungtas.","error","Įjunkite 10 V DC ir spauskite MATUOTI."); return; end
        if LD1.lastMeasurementStep<>6 | isnan(LD1.lastMeasurement) then ld1_set_status("Trūksta UAB matavimo.","error","Multimetras V (DC) [B08], +/V [T11]→A4 [T16], COM [T12]→B4 [T20]; tada MATUOTI [B06]."); return; end
        if ~ld1_any_yesno_selected() then ld1_set_status("Nepasirinktas Taip/Ne.","error","Palyginkite UAB su 10 V ir pažymėkite atsakymą."); return; end
        expectedYes=(abs(LD1.lastMeasurement-LD1.cfg.E)/LD1.cfg.E<=0.05);
        if ld1_yes_selected()<>expectedYes then ld1_set_status("Taip/Ne pasirinkimas neatitinka UAB palyginimo.","error","Jei UAB nuo 10 V skiriasi ≤5 %, rinkitės Taip; kitu atveju Ne."); return; end
        LD1.res.Rparallel1000=uR; LD1.res.Uparallel1000=LD1.lastMeasurement; LD1.parallelBaseVoltage=LD1.lastMeasurement;
        ld1_mark_done("UAB matavimas užfiksuotas: "+ld1_num(LD1.lastMeasurement,3)+" V.");

    case 7 then
        [ok,msg,fix]=ld1_validate_parallel_voltage_topology(); if ~ok then ld1_set_status(msg,"error",fix); return; end
        if LD1.VR1==1000 then ld1_set_status("VR1 dar nepakeistas.","error","Paspauskite, pvz., 500 Ω [B03]. Kitų laidų nekeiskite."); return; end
        if LD1.lastMeasurementStep<>7 | isnan(LD1.lastMeasurement) then ld1_set_status("Po VR1 pakeitimo neatliktas naujas UAB matavimas.","error","Paspauskite MATUOTI [B06] dar kartą."); return; end
        if ~ld1_any_yesno_selected() then ld1_set_status("Nepasirinktas Taip/Ne.","error","Pažymėkite, ar UAB pasikeitė daugiau kaip 5 %."); return; end
        base=LD1.parallelBaseVoltage;
        if isnan(base) & ~isnan(LD1.res.Uparallel1000) then base=LD1.res.Uparallel1000; end
        if isnan(base) then base=LD1.cfg.E; end
        delta=abs(LD1.lastMeasurement-base);
        changed=(delta/max(LD1.cfg.E,1e-9)>0.05);
        if ld1_yes_selected()<>changed then ld1_set_status("Taip/Ne pasirinkimas neatitinka grandinės elgsenos.","error","Idealiame 10 V šaltinyje A-B įtampa iš esmės nekinta keičiant vienos šakos varžą, todėl tikėtinas atsakymas – Ne."); return; end
        LD1.res.UparallelChanged=LD1.lastMeasurement;
        ld1_mark_done("Teisingai: keičiant vienos lygiagrečios šakos varžą, UAB idealiame modelyje iš esmės nekinta.");

    case 8 then
        [ok,msg,fix]=ld1_validate_parallel_total_current_topology(); if ~ok then ld1_set_status(msg,"error",fix); return; end
        if abs(LD1.VR1)>1 then ld1_set_status("VR1 nėra 0 Ω.","error","Paspauskite 0 Ω [B02]. Kitų 8 etapo laidų nekeiskite."); return; end
        [I1,I2,It]=ld1_parallel_currents(0);
        u1=ld1_parse_number(LD1.ui.qEdit(1).string); u2=ld1_parse_number(LD1.ui.qEdit(2).string); ut=ld1_parse_number(LD1.ui.qEdit(3).string);
        if isnan(u1) | ~ld1_close_enough(u1,I1) then ld1_set_status("I1 reikšmė neteisinga.","error","I1 yra R3 šakos srovė: I1 = E/R3. E=10 V; rezultatą įrašykite mA."); return; end
        if isnan(u2) | ~ld1_close_enough(u2,I2) then ld1_set_status("I2 reikšmė neteisinga.","error","Kai VR1=0 Ω, antroji šaka turi R2. Skaičiuokite I2 = E/R2 ir įrašykite mA."); return; end
        if isnan(ut) | ~ld1_close_enough(ut,It) then ld1_set_status("Bendra I reikšmė neteisinga.","error","Taikykite Kirchhofo srovės dėsnį: I = I1 + I2."); return; end
        if ~LD1.powerOn then ld1_set_status("Maitinimo šaltinis išjungtas.","error","Pirmiausia PATIKRINTI SUJUNGIMĄ [B09]. Jei jis teisingas, įjunkite 10 V [B01] ir MATUOTI [B06]."); return; end
        if LD1.lastMeasurementStep<>8 | isnan(LD1.lastMeasurement) then ld1_set_status("Trūksta bendros srovės matavimo.","error","Kai sujungimas patikrintas [B09] ir maitinimas įjungtas [B01], paspauskite MATUOTI [B06]."); return; end
        if ~ld1_any_yesno_selected() then ld1_set_status("Nepasirinktas Taip/Ne.","error","Palyginkite išmatuotą bendrą srovę su I1+I2 ir pažymėkite atsakymą."); return; end
        meas=LD1.lastMeasurement; err=abs(meas-It)/max(It,1e-9); expectedYes=(err<=0.05);
        if ld1_yes_selected()<>expectedYes then ld1_set_status("Taip/Ne pasirinkimas neatitinka skaitinio palyginimo.","error","Jei |Imat−(I1+I2)|/(I1+I2) ≤5 %, rinkitės Taip; kitu atveju Ne."); return; end
        LD1.res.I1=u1; LD1.res.I2=u2; LD1.res.It=ut; LD1.res.MIt=meas; LD1.res.KclErr=err*100;
        ld1_mark_done("Kirchhofo srovės dėsnis patikrintas: I ≈ I1 + I2. Skirtumas = "+ld1_num(err*100,2)+" %.");
    end
endfunction

function s = ld1_result_value(v,d,unit)
    if isnan(v) then
        s="NEATLIKTA";
    else
        s=ld1_num(v,d);
        if unit<>"" then s=s+" "+unit; end
    end
endfunction

function ld1_update_results_table(showExample)
    // 9 etapas nieko „neapskaičiuoja iš oro“: normaliai jis tik surenka
    // ankstesniuose etapuose išsaugotus duomenis. showExample=%t naudojamas
    // tik Pagalba → Pavyzdys režime ir rodo idealų pilną variantą.
    global LD1;
    if argn(2)<1 then showExample=%f; end
    r=LD1.res;

    if showExample then
        [Rs1,Is1]=ld1_series_theory(1000);
        [Rs5,Is5]=ld1_series_theory(500);
        Rp=ld1_parallel_theory(1000);
        [I1,I2,It]=ld1_parallel_currents(0);
        t=["Bandymas" "Formulė / kilmė" "Skaičiuota" "Multimetro rodmuo" "Vertinimas"; ..
           "Nuosekli, VR1=1 kΩ" "I [mA]=1000·E/(R1+1000)" ld1_num(Is1,3)+" mA" ld1_num(Is1,3)+" mA" "idealus pavyzdys"; ..
           "Nuosekli, VR1=500 Ω" "I [mA]=1000·E/(R1+500)" ld1_num(Is5,3)+" mA" ld1_num(Is5,3)+" mA" "idealus pavyzdys"; ..
           "Lygiagreti, VR1=1 kΩ" "Rb=R3||(R2+1000)" ld1_num(Rp,2)+" Ω" ld1_num(LD1.cfg.E,3)+" V" "UAB=E"; ..
           "Pakeista VR1" "7 et.: UAB prieš ir po" ld1_num(LD1.cfg.E,3)+" V" ld1_num(LD1.cfg.E,3)+" V" "UAB nepakito"; ..
           "Kirchhofo dėsnis" "I1=1000·E/R3; I2=1000·E/R2 (mA)" ld1_num(I1,3)+"+"+ld1_num(I2,3)+"="+ld1_num(It,3)+" mA" ld1_num(It,3)+" mA" "I=I1+I2"];
    else
        sIs1=ld1_result_value(r.Iseries1000,3,"mA");
        sMs1=ld1_result_value(r.Mseries1000,3,"mA");
        sEr1=ld1_result_value(r.Errseries1000,2,"%");
        sIs5=ld1_result_value(r.Iseries500,3,"mA");
        sMs5=ld1_result_value(r.Mseries500,3,"mA");
        sEr5=ld1_result_value(r.Errseries500,2,"%");
        sRp=ld1_result_value(r.Rparallel1000,2,"Ω");
        sUp=ld1_result_value(r.Uparallel1000,3,"V");
        sIt=ld1_result_value(r.It,3,"mA");
        sMIt=ld1_result_value(r.MIt,3,"mA");
        sKe=ld1_result_value(r.KclErr,2,"%");
        if isnan(r.I1) | isnan(r.I2) | isnan(r.It) then
            sKcalc="NEATLIKTA";
        else
            sKcalc=ld1_num(r.I1,3)+" + "+ld1_num(r.I2,3)+" = "+ld1_num(r.It,3)+" mA";
        end
        t=["Bandymas" "Formulė / kilmė" "Skaičiuota" "Multimetro rodmuo" "Vertinimas"; ..
           "Nuosekli, VR1=1 kΩ" "2–3 et.: I=1000·E/(R1+1000) (mA)" sIs1 sMs1 sEr1; ..
           "Nuosekli, VR1=500 Ω" "4 et.: I=1000·E/(R1+500) (mA)" sIs5 sMs5 sEr5; ..
           "Lygiagreti, VR1=1 kΩ" "6 et.: Rb=R3||(R2+1000)" sRp sUp "UAB matavimas"; ..
           "Pakeista VR1" "7 et.: UAB prieš ir po" sUp ld1_result_value(r.UparallelChanged,3,"V") "UAB palyginimas"; ..
           "Kirchhofo dėsnis" "8 et.: I1=1000·E/R3; I2=1000·E/R2 (mA)" sKcalc sMIt sKe];
    end
    LD1.ui.resultsTable.string=t;
    ld1_results_cards(t);
endfunction

function ld1_export_results()
    global LD1;
    r=LD1.res;
    lines=["LD Nr.1;Nuolatinės srovės grandinės tyrimas";
           "E_V;"+string(LD1.cfg.E);
           "R1_Ohm;"+string(LD1.cfg.R1);
           "R2_Ohm;"+string(LD1.cfg.R2);
           "R3_Ohm;"+string(LD1.cfg.R3);
           "Bandymas;Formule_ar_kilme;Skaiciuota;Ismatuota;Skirtumas_proc";
           "Nuosekli_VR1_1000;I_mA=1000*E/(R1+1000);"+ld1_result_value(r.Iseries1000,6,"mA")+";"+ld1_result_value(r.Mseries1000,6,"mA")+";"+ld1_result_value(r.Errseries1000,4,"");
           "Nuosekli_VR1_500;I_mA=1000*E/(R1+500);"+ld1_result_value(r.Iseries500,6,"mA")+";"+ld1_result_value(r.Mseries500,6,"mA")+";"+ld1_result_value(r.Errseries500,4,"");
           "Lygiagreti_UAB;Rb=R3||(R2+1000);"+ld1_result_value(r.Rparallel1000,6,"Ohm")+";"+ld1_result_value(r.Uparallel1000,6,"V")+";";
           "Pakeista_VR1_UAB;UAB_pries_ir_po;"+ld1_result_value(r.Uparallel1000,6,"V")+";"+ld1_result_value(r.UparallelChanged,6,"V")+";";
           "Kirchhofas_It;I1_mA=1000*E/R3, I2_mA=1000*E/R2;"+ld1_result_value(r.It,6,"mA")+";"+ld1_result_value(r.MIt,6,"mA")+";"+ld1_result_value(r.KclErr,4,"")];
    out=LD1.base+"LD1_rezultatai.csv";
    if isfield(LD1,"student") then
        lines=[student_csv_lines(LD1.student);"";lines];
        if LD1.student.number>0 then out=LD1.base+LD1.student.variant_id+"_rezultatai.csv"; end
    end
    mputl(lines,out);
    ld1_set_status("Rezultatai eksportuoti: "+out,"ok","NEATLIKTA CSV faile reiškia, kad atitinkamas etapas buvo praleistas arba neužfiksuotas.");
endfunction
