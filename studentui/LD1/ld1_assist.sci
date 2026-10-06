// Guided operation reuses the original circuit, measurements and answer fields.
function yes=ld1_guided()
    global LD1;
    yes=%f;
    if isfield(LD1,"guided") then yes=LD1.guided; end
endfunction

function ld1_guided_prepare()
    global LD1;
    if ~ld1_guided() | LD1.demoMode | LD1.step==9 then return; end
    LD1.guided_used=%t; LD1.pendingTerminal="";
    n=LD1.step; LD1.powerOn=%f;
    if n<=4 then
        LD1.wires=ld1_series_canonical_wires(); LD1.savedSeriesWires=LD1.wires;
        ld1_apply_meter_mode_quiet("A");
    elseif n<=7 then
        LD1.wires=ld1_parallel_voltage_canonical_wires(); LD1.savedParallelWires=LD1.wires;
        LD1.savedParallelVoltageWires=LD1.wires; LD1.kclPrepared=%f;
        ld1_set_parallel_meter_layout(%f); ld1_apply_meter_mode_quiet("V");
    else
        LD1.wires=ld1_parallel_kcl_canonical_wires(); LD1.savedParallelWires=LD1.wires;
        LD1.kclPrepared=%t; ld1_set_parallel_meter_layout(%t); ld1_apply_meter_mode_quiet("A");
    end
    LD1.VR1=1000;
    if or(n==[4 7]) then LD1.VR1=500; end
    if n==8 then LD1.VR1=0; end
    LD1.ui.vrSlider.value=LD1.VR1; ld1_update_actual_values();
    if or(n==[3 4 6 7 8]) then
        LD1.powerOn=%t;
        if isnan(LD1.stepMeas(n)) then ld1_measure(); end
    end
    ld1_set_instruction("",[]);
    ld1_set_status("Mokymosi stendas paruoštas automatiškai.","info","Įrašykite atsakymą ir spauskite Patikrinti. Tada galėsite tęsti.");
endfunction

function ok=ld1_inputs_present()
    // Check completeness only. Incorrect numerical answers remain the student's.
    global LD1;
    ok=%f;
    if LD1.step<=4 then
        [wok,wmsg,wfix]=ld1_validate_series_topology();
    elseif LD1.step<=7 then
        [wok,wmsg,wfix]=ld1_validate_parallel_voltage_topology();
    else
        [wok,wmsg,wfix]=ld1_validate_parallel_total_current_topology();
    end
    if ~wok then ld1_set_status(wmsg,"error",wfix); return; end
    expectedVR=1000;
    if LD1.step==4 then expectedVR=500; end
    if LD1.step==8 then expectedVR=0; end
    if LD1.step==7 then
        if LD1.VR1==1000 then ld1_set_status("Pakeiskite VR1 prieš matuodami.","warn","Pasirinkite, pvz., 500 Ω, tada spauskite Matuoti."); return; end
    elseif LD1.VR1<>expectedVR then
        ld1_set_status("Šiam etapui nustatykite VR1 = "+string(expectedVR)+" Ω.","warn","Naudokite varžos mygtukus arba slankiklį."); return;
    end
    for k=1:3
        h=LD1.ui.qEdit(k);
        if h.visible=="on" then
            if isnan(ld1_parse_number(h.string)) then
                ld1_set_status("Įrašykite skaičių: "+LD1.ui.qLabel(k).string,"warn","Tinka kablelis arba taškas. Enter spausti nereikia."); return;
            end
        end
    end
    if LD1.ui.typeSeries.visible=="on" then
        if LD1.ui.typeSeries.value+LD1.ui.typeParallel.value+LD1.ui.typeMixed.value<>1 then
            ld1_set_status("Pasirinkite grandinės tipą.","warn",""); return;
        end
    end
    if LD1.ui.yes.visible=="on" then
        if LD1.ui.yes.value+LD1.ui.no.value<>1 then
            ld1_set_status("Pasirinkite Taip arba Ne.","warn",""); return;
        end
    end
    if or(LD1.step==[3 4 6 7 8]) & isnan(LD1.stepMeas(LD1.step)) then
        ld1_set_status("Trūksta matavimo.","error","Įjunkite šaltinį ir spauskite Matuoti pačiame prietaise."); return;
    end
    ok=%t;
endfunction

function ld1_toggle_guided()
    global LD1;
    if LD1.demoMode then return; end
    if ~ld1_guided() then
        if ~ld1_enter_learning() then return; end
        LD1.practice_used=%t;
    end
    ld1_save_step_inputs(); LD1.guided=~ld1_guided();
    ld1_guided_prepare(); ld1_set_instruction("",[]);
    if LD1.step<9 then ld1_redraw_panel(); end
    if ~LD1.guided then ld1_set_status("Rankinis valdymas įjungtas. Duomenys išliko.","info","Automatinį paruošimą galite grąžinti per Pagalbą."); end
    ld1_save_step_inputs(); bench_autosave("LD1");
endfunction

function ld1_resize(id)
    global LD1;
    if typeof(LD1)<>"st" then return; end
    if ~isfield(LD1,"fig") then return; end
    if ~is_handle_valid(LD1.fig) then return; end
    if LD1.fig.figure_id<>id then return; end
    ld1_reflow(LD1.fig,LD1.fig.axes_size);
    if LD1.step<9 then ld1_redraw_panel(); end
endfunction

function ld1_reflow(parent,sz)
    // Reapply the native widget bounds, not just model-side normalized values.
    for h=matrix(parent.children,1,-1)
        if h.type<>"uicontrol" then continue; end
        r=h.position;
        if h.units=="normalized" then
            h.units="pixels"; h.position=r.*[sz sz]; h.units="normalized"; h.position=r;
            child_size=r(3:4).*sz;
        else child_size=r(3:4); end
        ld1_reflow(h,child_size);
    end
endfunction

function ld1_sync_recorded_results()
    global LD1;
    // Assessment does not call the answer checker, but its measurements are real.
    LD1.res.Mseries1000=LD1.stepMeas(3); LD1.res.Mseries500=LD1.stepMeas(4);
    LD1.res.Uparallel1000=LD1.stepMeas(6); LD1.res.UparallelChanged=LD1.stepMeas(7);
    LD1.res.MIt=LD1.stepMeas(8); LD1.parallelBaseVoltage=LD1.stepMeas(6);
    LD1.res.Errseries1000=ld1_recorded_error(LD1.res.Mseries1000,LD1.res.Iseries1000);
    LD1.res.Errseries500=ld1_recorded_error(LD1.res.Mseries500,LD1.res.Iseries500);
    LD1.res.KclErr=ld1_recorded_error(LD1.res.MIt,LD1.res.I1+LD1.res.I2);
endfunction

function value=ld1_recorded_error(measured,calculated)
    value=%nan;
    if isnan(measured) | isnan(calculated) | calculated==0 then return; end
    value=100*abs(measured-calculated)/abs(calculated);
endfunction

function ld1_ui_font(parent)
    for h=matrix(parent.children,1,-1)
        if h.type=="uicontrol" then
            h.fontname="SansSerif"; h.fontsize=max(15,h.fontsize); ld1_ui_font(h);
        end
    end
endfunction

function ld1_results_cards(t)
    // Native Scilab table font and row-header sizing vary between platforms.
    // Keep its data for compatibility; display read-only, explicitly sized rows.
    global LD1;
    LD1.ui.resultsTable.visible="off";
    if isfield(LD1.ui,"resultCards") then
        for h=LD1.ui.resultCards
            if is_handle_valid(h) then delete(h); end
        end
    end
    LD1.ui.resultCards=list();
    for k=2:size(t,1)
        bg=[0.95 0.97 0.97];
        fr=student_frame(LD1.ui.circuitFrame,[0.025 0.64-(k-2)*0.15 0.95 0.13],bg);
        ld1_track_board_handle(fr); LD1.ui.resultCards($+1)=fr;
        student_text(fr,[0.02 0.68 0.65 0.26],t(k,1),14,%t,bg);
        student_text(fr,[0.70 0.68 0.28 0.26],t(k,5),12,%f,bg);
        student_text(fr,[0.02 0.07 0.33 0.57],student_wrap(t(k,2),30),12,%f,bg);
        left="Skaičiuota: "; right="Išmatuota: ";
        if k==5 then left="Prieš: "; right="Po pakeitimo: "; end
        student_text(fr,[0.38 0.07 0.29 0.57],student_wrap(left+t(k,3),26),12,%f,bg);
        student_text(fr,[0.70 0.07 0.28 0.57],student_wrap(right+t(k,4),26),12,%f,bg);
        ld1_ui_font(fr);
    end
endfunction
