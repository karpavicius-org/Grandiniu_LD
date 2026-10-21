// Actual callback workflow and independent circuit checks, all 64 variants.
function ld2_test_assert(condition,message)
    if ~and(condition) then error("LD2-4: "+message);end
endfunction

function [ok,log]=ld2_selftest()
    global LD2;
    previous=LD2;ok=%f;log=emptystr(0,1);
    try
        for variant=1:64
            cfg=ld2_variant_config(variant);
            LD2=struct("root",LD2_ROOT,"cfg",cfg,"state",ld2_initial_state(cfg), ...
                "ui",struct("headless",%t,"suppress_render",%f,"dynamic",[],"answer_edits",[],"answer_step",0), ...
                "example_active",%f,"example_backup",struct());
            LD2.state.student=student_profile(variant,"Testas","TEST","LD2");
            LD2.state.assessment=%t;
            for stage=ld2_visible_steps()
                ld2_test_assert(LD2.state.step==stage,"navigation skipped a stage");
                if stage<>1 then
                    [ready,why]=ld2_workflow_ready();ld2_test_assert(~ready,"stage ready before experiment");
                    ld2_auto_stage();
                    [label,measured]=ld2_auto_stage_status(stage);
                    ld2_test_assert(measured,"automatic experiment failed: "+string(variant)+" / "+string(stage));
                    ld2_test_assert(~LD2.state.auto_recording,"recording flag leaked");
                    count=length(LD2.state.measurements);ld2_auto_stage();
                    ld2_test_assert(length(LD2.state.measurements)==count,"second click duplicated observations");
                end
                if or(stage==[4 7 10]) then
                    ld2_test_assert(LD2.state.comparisons(stage)==0,"automatic student choice");
                    ld2_choose_comparison(1);
                elseif stage==9 then
                    ld2_test_assert(LD2.state.answers_text(9,1)=="","automatic resonance answer");
                    [value,index]=max(LD2.state.res_ur);ld2_choose_resonance(index);
                elseif stage==11 then
                    // Independent bandwidth identity, not the measured subtraction.
                    bw=cfg.R13/(2*%pi*cfg.L3);
                    ld2_test_assert(abs((LD2.state.f2_meas-LD2.state.f1_meas)-bw)<1d-7,"BW units/identity");
                    LD2.state.answers_text(11,1)=ld2_num(bw,6);LD2.state.answers(11,1)=bw;
                end
                [ready,why]=ld2_workflow_ready();ld2_test_assert(ready,why);
                if stage<12 then ld2_student_primary();else LD2.state.completed(12)=1;end
            end
            ld2_test_assert(abs(sqrt(LD2.state.rc_UR^2+LD2.state.rc_UC^2)-cfg.E_RC)<1d-8,"RC vector sum");
            ld2_test_assert(abs(sqrt(LD2.state.rl_UR^2+LD2.state.rl_UL^2)-cfg.E_RL)<1d-8,"RL vector sum");
            ld2_test_assert(abs(LD2.state.res_fr_meas-1/(2*%pi*sqrt(cfg.L3*cfg.C4)))<1d-7,"resonance identity");
            ld2_test_assert(abs(LD2.state.f1_meas*LD2.state.f2_meas-LD2.state.res_fr_meas^2)<1d-5,"half power product");
            ld2_test_assert(size(LD2.state.sweep_f,"*")==11,"sweep length");
            r=bench_report_data("LD2");ld2_test_assert(length(r.answers)==5,"exactly five answers");
            ld2_test_assert(r.rubric_version=="LD2-4","wrong rubric");
            if getenv("LD2_TEST_REPORTS","")<>"" then
                out=getenv("LD2_TEST_REPORTS");
                bench_export_report("LD2",out);
            end
            // Back, change answer, return: readings stay, completion is invalidated.
            saved=LD2.state.rc_UR;ld2_go_step(4,%f);ld2_choose_comparison(2);
            ld2_test_assert(LD2.state.completed(12)==0,"stale final completion");
            ld2_test_assert(LD2.state.rc_UR==saved,"back erased measurements");
            // Restore new state, then migrate old state without converting numbers to choices.
            session=struct("cfg",cfg,"state",LD2.state);
            ld2_restore_session(session);ld2_test_assert(LD2.state.comparisons(4)==2,"choice lost in restore");
            oldstate=struct();
            for field=fieldnames(session.state)'
                if field<>"workflow_revision" then oldstate(field)=session.state(field);end
            end
            session.state=oldstate;
            session.state.answers_text(4,1)="9";
            ld2_restore_session(session);
            ld2_test_assert(LD2.state.comparisons(4)==0 & LD2.state.answers_text(4,1)=="","old numbers treated as choice");
            log($+1,1)="PASS variant "+string(variant);
        end
        for invalid=["1+2" "%pi" "NaN" "1e999" "" "2k"]
            ld2_test_assert(isnan(ld2_safe_number(invalid)),"invalid numeric accepted");
        end
        ld2_test_assert(abs(ld2_safe_number("12,5")-12.5)<1d-12,"decimal comma");
        ok=%t;log($+1,1)="PASS: 64 complete callback workflows, independent physics, repeated clicks, report mapping, back/restore/migration, numeric input.";
    catch
        [msg,code,line,fun]=lasterror();log($+1,1)="FAIL: "+strcat(msg," ")+" | "+fun+":"+string(line);
    end
    LD2=previous;
endfunction
