// Native Scilab regression suite. Runs the SAME model and callbacks as the GUI.
// It never touches an existing figure: a separate headless state is used.
function [ok,log]=ld2_selftest()
    global LD2;
    previous=LD2;
    ok=%t; log=["LD2 v1.1 – natyvi Scilab savikontrolė";"Vykdymo aplinka: "+getversion()];
    try
        ld2_test_new_state();
        [valid,why]=ld2_validate_config(LD2.cfg);
        [ok,log]=ld2_test_true(ok,log,"Numatytieji parametrai",valid);
        rc=ld2_rc_values(9,60,1000,4.7e-6);
        rl=ld2_rl_values(9,50,1000,0.5);
        rr=ld2_resonance_values(100,0.1,10e-9);
        rz=ld2_rlc_values(5,rr.F0,100,0.1,10e-9);
        r1=ld2_rlc_values(5,rr.F1,100,0.1,10e-9);
        r2=ld2_rlc_values(5,rr.F2,100,0.1,10e-9);
        [ok,log]=ld2_test_append(ok,log,"RC įtampų vektorių suma",sqrt(rc.UR^2+rc.UX^2),9,1d-9);
        [ok,log]=ld2_test_append(ok,log,"RL įtampų vektorių suma",sqrt(rl.UR^2+rl.UX^2),9,1d-9);
        [ok,log]=ld2_test_true(ok,log,"RC ir RL srovės fazės ženklai",rc.PHI_I>0 & rl.PHI_I<0);
        [ok,log]=ld2_test_append(ok,log,"Rezonansas: XL=XC",rz.XL,rz.XC,1d-7);
        [ok,log]=ld2_test_append(ok,log,"Rezonansas: UR=E",rz.UR,5,1d-9);
        [ok,log]=ld2_test_append(ok,log,"Rezonansas: ULC=0",rz.ULC,0,1d-9);
        [ok,log]=ld2_test_append(ok,log,"f1 pusė galios",r1.UR,5/sqrt(2),1d-9);
        [ok,log]=ld2_test_append(ok,log,"f2 pusė galios",r2.UR,5/sqrt(2),1d-9);
        [ok,log]=ld2_test_append(ok,log,"BW=R/(2*pi*L)",rr.BW,100/(2*%pi*0.1),1d-8);
        [ok,log]=ld2_test_true(ok,log,"UR_RLC vardas nebevirsta URC",ld2_target_code("UR_RLC")=="UR");
        [ok,log]=ld2_test_append(ok,log,"Dešimtainis kablelis",ld2_safe_number(" 12,5 "),12.5,1d-12);
        for invalid=["1+2" "sqrt(9)" "1/2" "%pi" "1e999" "NaN" "2k" "" "1 2"]
            label=invalid; if label=="" then label="<tuščia>"; end
            [ok,log]=ld2_test_true(ok,log,"Neleidžiama įvestis: "+label,isnan(ld2_safe_number(invalid)));
        end
        [ok,log]=ld2_test_append(ok,log,"Mokslinė įvestis",ld2_safe_number("4.7e-6"),4.7e-6,1d-14);

        // Elementų numerių registro (ld2_ids.sci) vientisumas.
        codes=ld2_all_codes();
        [ok,log]=ld2_test_true(ok,log,"Registro kodų sąrašas > 100 ir be pasikartojimų", ...
            size(codes,1)>100 & size(unique(codes),1)==size(codes,1));
        [ok,log]=ld2_test_true(ok,log,"Kontaktų kodai: VM_H=T07, LC_M2=T38", ...
            ld2_terminal_code("VM_H")=="T07" & ld2_terminal_code("LC_M2")=="T38" & ...
            part(ld2_terminal_name("VM_H"),1:4)=="T07 ");
        [ok,log]=ld2_test_true(ok,log,"Mygtukų registro atitikmenys: B15, B11, B41", ...
            ld2_button_info("ld2_measure_voltage()")=="B15" & ...
            ld2_button_info("ld2_undo_wire()")=="B11" & ...
            ld2_button_info("ld2_edit_step_note()")=="B41");
        [rids,rcbs]=ld2_button_registry();
        defined=size(rcbs,"*")==45;
        for k=1:size(rcbs,"*")
            fname=rcbs(k);
            pp=strindex(fname,"(");
            if size(pp,"*")>0 then fname=part(fname,1:pp(1)-1); end
            w=whereis(fname);
            if w==[] | w=="" then defined=%f; end
        end
        [ok,log]=ld2_test_true(ok,log,"Visi 45 registro mygtukų veiksmai apibrėžti",defined);
        meth_ok=%t;
        for st=ld2_visible_steps()
            d=ld2_method_data(st);
            if size(d.method,"*")<3 | size(strindex(d.method(1),"["),"*")==0 then meth_ok=%f; end
        end
        [ok,log]=ld2_test_true(ok,log,"10 aktyvių etapų metodika su kodais",meth_ok);
        ilines=ld2_instruction_lines(2);
        [ok,log]=ld2_test_true(ok,log,"Instrukcijos deleguojamos į metodiką su kodais", ...
            size(ilines,"*")>=5 & size(strindex(ilines(4),"[T01]"),"*")>0 & ...
            size(strindex(ilines(3),"[B09]"),"*")>0);

        // All sample stages use the actual measurement, recording and evaluation code.
        for step=ld2_visible_steps()
            ld2_test_new_state();
            LD2.example_active=%t;
            ld2_prepare_example(step);
            [ok,log]=ld2_test_true(ok,log,"Pavyzdys "+string(step)+": be veikimo klaidos",LD2.state.last_error=="");
            [ok,log]=ld2_test_true(ok,log,"Pavyzdys neįskaito studento etapo "+string(step),and(LD2.state.completed==0));
            LD2.example_active=%f;
            ld2_check_step();
            [ok,log]=ld2_test_true(ok,log,"Pavyzdžio duomenys praeina tikrintuvą "+string(step),LD2.state.completed(step)==1);
        end

        // A full student workflow, in one persistent state, through clicks and measurements.
        ld2_test_new_state();
        LD2.state.teacher_mode=%f;
        [ok,log]=ld2_test_true(ok,log,"Studento matomų etapų skaičius yra 10", ...
            size(ld2_visible_steps(),"*")==10 & ld2_visible_next(2)==4 & ld2_visible_next(5)==7);
        [ok,log]=ld2_test_true(ok,log,"Grįžimo kelias aplenkia 3 ir 6", ...
            ld2_visible_previous(4)==2 & ld2_visible_previous(7)==5);
        // Exercise the real advance/back callbacks, not only arithmetic mappings.
        ld2_test_new_state(); LD2.state.step=2; LD2.state.completed(2)=1;
        ld2_next();
        [ok,log]=ld2_test_true(ok,log,"RC: po laidų jungimo tiesiai į matavimus", ...
            LD2.state.step==4 & LD2.state.completed(3)==1);
        LD2.state.step=5; LD2.state.completed(5)=1;
        ld2_next();
        [ok,log]=ld2_test_true(ok,log,"RL: po laidų jungimo tiesiai į matavimus", ...
            LD2.state.step==7 & LD2.state.completed(6)==1);
        ld2_prev();
        [ok,log]=ld2_test_true(ok,log,"RL: Atgal grąžina į jungimo ekraną",LD2.state.step==5);
        ld2_test_new_state(); LD2.state.step=3;
        ld2_go_step(3,%f);
        [ok,log]=ld2_test_true(ok,log,"Atkuriamas senas 3 etapas nenuklysta į tuščią langą",LD2.state.step==4);
        ld2_test_new_state(); LD2.state.step=6;
        ld2_go_step(6,%f);
        [ok,log]=ld2_test_true(ok,log,"Atkuriamas senas 6 etapas nenuklysta į tuščią langą",LD2.state.step==7);
        [labels,n3]=ld2_answer_spec(3);
        [labels,n6]=ld2_answer_spec(6);
        [ok,log]=ld2_test_true(ok,log,"Nebėra teorinių įvesties laukų",n3==0 & n6==0);
        for step=ld2_visible_steps()
            ld2_go_step(step,%f);
            phase=ld2_phase_for_step(step);
            if step==2 | step==5 | step==8 then
                req=ld2_required_main(phase);
                for k=1:size(req,1)
                    ld2_terminal_click(req(k,1)); ld2_terminal_click(req(k,2));
                end
            elseif step==4 | step==7 then
                if ~LD2.state.power then ld2_power_toggle(); end
                ld2_measure_current();
                if step==4 then targets=["UR" "UC" "UE"]; else targets=["UR" "UL" "UE"]; end
                for target=targets
                    ld2_test_connect_probe(phase,target); ld2_measure_voltage();
                end
                if step==4 then ld2_test_answers(step,[9 rc.I*1000]);
                else ld2_test_answers(step,[9 rl.I*1000]); end
            elseif step==9 then
                ld2_test_connect_probe("RLC","UR");
                if ~LD2.state.power then ld2_power_toggle(); end
                // Deliberately use the formerly failing, rounded resonance frequency.
                for f=[5000 5030 5060]
                    ld2_set_frequency(f); ld2_measure_voltage(); ld2_record_resonance_point();
                end
                ld2_test_answers(step,[rr.F0 5030 1000/5030 max(LD2.state.res_ur)]);
            elseif step==10 then
                peaks=ld2_peak_reference(LD2.cfg);
                targets=["UL" "UC" "ULC"]; centers=[peaks.FL peaks.FC 5030];
                for j=1:3
                    ld2_test_connect_probe("RLC",targets(j));
                    for f=[centers(j)-peaks.BW/2 centers(j) centers(j)+peaks.BW/2]
                        ld2_set_frequency(f); ld2_measure_voltage(); ld2_record_peak_point();
                    end
                end
                [fl,ul,yes]=ld2_peak_best("UL"); [fc,uc,yes]=ld2_peak_best("UC"); [fz,uz,yes]=ld2_peak_best("ULC");
                ld2_test_answers(step,[ul uc uz fl fc fz]);
                [ok,log]=ld2_test_true(ok,log,"5030 Hz tikras ULC rodmuo nėra pakeistas nuliu",uz>0.18 & uz<0.19);
            elseif step==11 then
                ld2_test_connect_probe("RLC","UR");
                ld2_set_frequency(rr.F1); ld2_measure_voltage(); ld2_record_f1();
                ld2_set_frequency(rr.F2); ld2_measure_voltage(); ld2_record_f2();
                ld2_test_answers(step,[ld2_half_power_threshold() rr.F1 rr.F2 rr.BW 5030/rr.BW]);
            elseif step==12 then
                ld2_test_connect_probe("RLC","UR"); ld2_run_sweep();
            end
            ld2_check_step();
            [ok,log]=ld2_test_true(ok,log,"Nuosekli studento sesija: etapas "+string(step),LD2.state.completed(step)==1);
        end
        [ok,log]=ld2_test_true(ok,log,"10 aktyvių etapų ir 2 nematomi suderinamumo etapai",and(LD2.state.completed==1) & ...
            and(LD2.state.answers_text(3,:)=="") & and(LD2.state.answers_text(6,:)==""));
        [ok,log]=ld2_test_true(ok,log,"Lentelėje 11 taškų ir atskira 0 Hz kilmė", ...
            size(LD2.state.sweep_f,"*")==11 & LD2.state.sweep_source(1)=="TEORINĖ 0 Hz RIBA");
        count=length(LD2.state.measurements);
        [ok,log]=ld2_test_true(ok,log,"Matavimų žurnalas išliko tarp etapų",count>=30);

        // Typed answers cannot substitute missing physical actions in the virtual bench.
        ld2_test_new_state(); ld2_go_step(11,%t);
        ld2_test_answers(11,[5/sqrt(2) rr.F1 rr.F2 rr.BW rr.Q]);
        ld2_check_step();
        [ok,log]=ld2_test_true(ok,log,"11 etapas neįskaitomas vien su teoriniais skaičiais",LD2.state.completed(11)==0);
        LD2.state.step=12; LD2.state.power=%f; ld2_run_sweep();
        [ok,log]=ld2_test_true(ok,log,"Skenavimas išjungus generatorių neįvyksta",size(LD2.state.sweep_f,"*")==0);

        // Wrong wires and meter placement are rejected before they become a circuit.
        ld2_test_new_state(); LD2.state.step=8;
        [valid,msg,fix]=ld2_can_add_pair(8,"GEN_H","GEN_L");
        [ok,log]=ld2_test_true(ok,log,"Trumpasis jungimas atmetamas su taisymo nurodymu",~valid & fix<>"");
        LD2.state.rlc_connections=ld2_required_main("RLC"); LD2.state.step=9;
        [valid,msg,fix]=ld2_can_add_pair(9,"AM_H","R13_M1");
        [ok,log]=ld2_test_true(ok,log,"Ampermetro lygiagretus prijungimas atmetamas",~valid);
        ld2_test_connect_probe("RLC","UR"); LD2.state.power=%t;
        ld2_measure_voltage();
        [valid,msg,fix]=ld2_validate_voltage_probes("RLC","UR_RLC");
        [ok,log]=ld2_test_true(ok,log,"RLC R13 zondai tikrinami teisingai",valid);
        [valid,msg]=ld2_live_voltage_ok("UR");
        [ok,log]=ld2_test_true(ok,log,"Tinkamas naujas rodmuo",valid);
        ld2_set_frequency(LD2.state.freq+1);
        ld2_record_resonance_point();
        [ok,log]=ld2_test_true(ok,log,"Pasenęs rodmuo neįrašomas pakeitus dažnį",size(LD2.state.res_f,"*")==0);
        ld2_measure_voltage(); ld2_power_toggle(); ld2_record_resonance_point();
        [ok,log]=ld2_test_true(ok,log,"Išjungimas panaikina gyvo rodmens tinkamumą",size(LD2.state.res_f,"*")==0);
        ld2_power_toggle(); ld2_measure_voltage(); ld2_remove_voltage_probes();
        [ok,log]=ld2_test_true(ok,log,"Atjungus zondus nėra skaitinio rodmens",~LD2.state.last_voltage.valid & isnan(LD2.state.volt_live));

        // A pending student measurement answer stays with its original step.
        ld2_test_new_state(); LD2.state.step=4;
        LD2.ui.answer_step=4;
        LD2.ui.answer_edits=[struct("string","12,34") struct("string","1e")];
        LD2.state.step=5; ld2_save_answers();
        [ok,log]=ld2_test_true(ok,log,"Neužbaigtas tekstas išsaugomas ankstesniame etape", ...
            LD2.state.answers_text(4,1)=="12,34" & LD2.state.answers_text(4,2)=="1e" & LD2.state.answers_text(5,1)=="");
        LD2.ui.answer_edits=[]; LD2.ui.answer_step=0;
        LD2.state.step=10; LD2.state.answers_text(10,1)="mano tekstas";
        before=LD2.state;
        ld2_show_solution();
        [ok,log]=ld2_test_true(ok,log,"Pavyzdys atidaromas tikrame stendo būsenoje",LD2.example_active);
        ld2_show_solution();
        [ok,log]=ld2_test_true(ok,log,"Grįžimas atkuria studento tekstą ir istoriją", ...
            ~LD2.example_active & LD2.state.answers_text(10,1)==before.answers_text(10,1) & ...
            length(LD2.state.measurements)==length(before.measurements));
    catch
        ok=%f;
        log($+1,1)="FAIL | Vykdymo išimtis: "+strcat(lasterror()," | ");
    end
    LD2=previous;
    if ok then log($+1,1)="BENDRAS REZULTATAS: PASS";
    else log($+1,1)="BENDRAS REZULTATAS: FAIL"; end
endfunction

function ld2_test_new_state()
    global LD2;
    cfg=ld2_default_config();
    // Fixed regression fixture, independent of user-edited launch defaults.
    cfg.E_RC=9; cfg.F_RC=60; cfg.R8=1000; cfg.C2=4.7e-6;
    cfg.E_RL=9; cfg.F_RL=50; cfg.R9=1000; cfg.L1=0.5;
    cfg.E_RLC=5; cfg.R13=100; cfg.L3=0.1; cfg.C4=10e-9;
    cfg.F_MIN=0; cfg.F_MAX=10000; cfg.F_INIT=5000;
    cfg.ANSWER_TOL_REL=0.015; cfg.ANSWER_TOL_ABS=0.005;
    LD2=struct("cfg",cfg,"state",ld2_initial_state(cfg),"root",TMPDIR, ...
        "example_active",%f,"example_backup",struct("dummy",0), ...
        "ui",struct("headless",%t,"suppress_render",%f,"dynamic",[],"answer_edits",[],"answer_step",0));
endfunction

function ld2_test_answers(step,ref)
    global LD2;
    for j=1:size(ref,"*")
        LD2.state.answers(step,j)=ref(j);
        LD2.state.answers_text(step,j)=msprintf("%.12g",ref(j));
    end
endfunction

function ld2_test_connect_probe(phase,target)
    ld2_remove_voltage_probes();
    pair=ld2_probe_pair(phase,target);
    ld2_terminal_click("VM_H"); ld2_terminal_click(pair(1));
    ld2_terminal_click("VM_L"); ld2_terminal_click(pair(2));
endfunction

function [ok,log]=ld2_test_true(ok,log,name,condition)
    if and(condition) then log($+1,1)="PASS | "+name;
    else ok=%f; log($+1,1)="FAIL | "+name; end
endfunction

function [ok,log]=ld2_test_append(ok,log,name,actual,expected,tol)
    valid=~isnan(actual) & ~isinf(actual) & abs(actual-expected)<=tol;
    [ok,log]=ld2_test_true(ok,log,name,valid);
endfunction
