// Local resume files are separate from submitted reports. Keep the last two
// complete snapshots; a failed save must leave the previous snapshot intact.
function session=bench_snapshot(lab)
    global LD1 LD2 LD3 LD4 LD5 LD6 LD7 LD8 LD9 LD10 LD11 LD12;
    session=struct("format","Grandiniu-LD-session-1","lab",lab,"state",struct());
    if lab=="LD1" then
        session.cfg=LD1.cfg; session.student=LD1.student;
        for field=fieldnames(LD1)'
            if or(field==["ui" "fig" "term" "base" "cfg" "student" "demoSnapshot" "autosave_paths" "autosave_error"]) then continue; end
            session.state(field)=LD1(field);
        end
    elseif lab=="LD3" then
        if LD3.demoMode then error("Grįžkite į savo darbą prieš išsaugodami juodraštį."); end
        ld3_save_answers();
        session.cfg=LD3.cfg; session.student=LD3.student;
        for field=fieldnames(LD3)'
            if or(field==["ui" "fig" "term" "base" "root" "cfg" "student" "autosave_paths" "autosave_error"]) then continue; end
            session.state(field)=LD3(field);
        end
    elseif lab=="LD4" then
        if LD4.demoMode then error("Grįžkite į savo darbą prieš išsaugodami juodraštį."); end
        ld4_save_answers();
        session.cfg=LD4.cfg; session.student=LD4.student;
        for field=fieldnames(LD4)'
            if or(field==["ui" "fig" "term" "base" "root" "cfg" "student" "backup" "autosave_paths" "autosave_error"]) then continue; end
            session.state(field)=LD4(field);
        end
    elseif lab=="LD5" then
        if LD5.demoMode then error("Grįžkite į savo darbą prieš išsaugodami juodraštį."); end
        ld5_save_answers();
        session.cfg=LD5.cfg; session.student=LD5.student;
        for field=fieldnames(LD5)'
            if or(field==["ui" "fig" "term" "base" "root" "cfg" "student" "backup" "autosave_paths" "autosave_error"]) then continue; end
            session.state(field)=LD5(field);
        end
    elseif lab=="LD6" then
        if LD6.demoMode then error("Grįžkite į savo darbą prieš išsaugodami juodraštį."); end
        ld6_save_answers();
        session.cfg=LD6.cfg; session.student=LD6.student;
        for field=fieldnames(LD6)'
            if or(field==["ui" "fig" "term" "base" "root" "cfg" "student" "backup" "autosave_paths" "autosave_error"]) then continue; end
            session.state(field)=LD6(field);
        end
    elseif lab=="LD7" then
        if LD7.demoMode then error("Grįžkite į savo darbą prieš išsaugodami juodraštį."); end
        ld7_save_answers();
        session.cfg=LD7.cfg; session.student=LD7.student;
        for field=fieldnames(LD7)'
            if or(field==["ui" "fig" "term" "base" "root" "cfg" "student" "backup" "autosave_paths" "autosave_error"]) then continue; end
            session.state(field)=LD7(field);
        end
    elseif lab=="LD8" then
        if LD8.demoMode then error("Grįžkite į savo darbą prieš išsaugodami juodraštį."); end
        ld8_save_answers();
        session.cfg=LD8.cfg; session.student=LD8.student;
        for field=fieldnames(LD8)'
            if or(field==["ui" "fig" "term" "base" "root" "cfg" "student" "backup" "autosave_paths" "autosave_error"]) then continue; end
            session.state(field)=LD8(field);
        end
    elseif lab=="LD9" then
        if LD9.demoMode then error("Grįžkite į savo darbą prieš išsaugodami juodraštį."); end
        ld9_save_answers();
        session.cfg=LD9.cfg; session.student=LD9.student;
        for field=fieldnames(LD9)'
            if or(field==["ui" "fig" "term" "base" "root" "cfg" "student" "backup" "autosave_paths" "autosave_error"]) then continue; end
            session.state(field)=LD9(field);
        end
    elseif lab=="LD10" then
        if LD10.demoMode then error("Grįžkite į savo darbą prieš išsaugodami juodraštį."); end
        ld10_save_answers();
        session.cfg=LD10.cfg; session.student=LD10.student;
        for field=fieldnames(LD10)'
            if or(field==["ui" "fig" "term" "base" "root" "cfg" "student" "backup" "autosave_paths" "autosave_error"]) then continue; end
            session.state(field)=LD10(field);
        end
    elseif lab=="LD11" then
        if LD11.demoMode then error("Grįžkite į savo darbą prieš išsaugodami juodraštį."); end
        ld11_save_answers();
        session.cfg=LD11.cfg; session.student=LD11.student;
        for field=fieldnames(LD11)'
            if or(field==["ui" "fig" "term" "base" "root" "cfg" "student" "backup" "autosave_paths" "autosave_error"]) then continue; end
            session.state(field)=LD11(field);
        end
    elseif lab=="LD12" then
        if LD12.demoMode then error("Grįžkite į savo darbą prieš išsaugodami juodraštį."); end
        ld12_save_answers();
        session.cfg=LD12.cfg; session.student=LD12.student;
        for field=fieldnames(LD12)'
            if or(field==["ui" "fig" "term" "base" "root" "cfg" "student" "backup" "autosave_paths" "autosave_error"]) then continue; end
            session.state(field)=LD12(field);
        end
    else
        session.cfg=LD2.cfg;session.student=LD2.state.student;session.state=LD2.state;
    end
endfunction

function path=bench_save_snapshot(lab)
    session=bench_snapshot(lab);
    folder=fullfile(bench_documents(),"Juodrasciai"); if ~isdir(folder) then mkdir(folder); end
    path=fullfile(folder,lab+"-V"+msprintf("%02d",session.student.number)+"-"+bench_id()+".sod");
    temp=fullfile(TMPDIR,"ld-session-"+bench_id()+".sod");
    save(temp,"session");
    info=fileinfo(temp); n=info(1);
    if n>16*1024*1024 then error("Darbo juodraštis viršija 16 MB ribą."); end
    fd=mopen(temp,"rb"); b=mget(n,"uc",fd);mclose(fd);mdelete(temp);
    bench_core_require();p=ascii(path);
    status=call("ld_write_new",p,1,"i",size(p,"*"),2,"i",b,3,"i",size(b,"*"),4,"i","out",[1 1],5,"i");
    if status<>0 then error("Juodraštis neišsaugotas. Ankstesnis įrašas liko nepakeistas."); end
endfunction

function paths=bench_autosave_trim(paths)
    if size(paths,"*")<=2 then return; end
    old=paths(1);
    try
        if isfile(old) then mdelete(old); end
    catch
        // Retention is best-effort. The newly written snapshot remains valid.
    end
    paths(1)=[];
endfunction

function bench_autosave(lab)
    global LD1 LD2 LD3 LD4 LD5 LD6 LD7 LD8 LD9 LD10 LD11 LD12 BENCH_AUTOSAVE_SUSPENDED;
    if BENCH_AUTOSAVE_SUSPENDED==%t then return; end
    if lab=="LD1" then
        if ~isfield(LD1,"autosave_enabled") then return; end
        if ~LD1.autosave_enabled | LD1.demoMode then return; end
    elseif lab=="LD3" then
        if ~isfield(LD3,"autosave_enabled") then return; end
        if ~LD3.autosave_enabled | LD3.demoMode then return; end
    elseif lab=="LD4" then
        if ~isfield(LD4,"autosave_enabled") then return; end
        if ~LD4.autosave_enabled | LD4.demoMode then return; end
    elseif lab=="LD5" then
        if ~isfield(LD5,"autosave_enabled") then return; end
        if ~LD5.autosave_enabled | LD5.demoMode then return; end
    elseif lab=="LD6" then
        if ~isfield(LD6,"autosave_enabled") then return; end
        if ~LD6.autosave_enabled | LD6.demoMode then return; end
    elseif lab=="LD7" then
        if ~isfield(LD7,"autosave_enabled") then return; end
        if ~LD7.autosave_enabled | LD7.demoMode then return; end
    elseif lab=="LD8" then
        if ~isfield(LD8,"autosave_enabled") then return; end
        if ~LD8.autosave_enabled | LD8.demoMode then return; end
    elseif lab=="LD9" then
        if ~isfield(LD9,"autosave_enabled") then return; end
        if ~LD9.autosave_enabled | LD9.demoMode then return; end
    elseif lab=="LD10" then
        if ~isfield(LD10,"autosave_enabled") then return; end
        if ~LD10.autosave_enabled | LD10.demoMode then return; end
    elseif lab=="LD11" then
        if ~isfield(LD11,"autosave_enabled") then return; end
        if ~LD11.autosave_enabled | LD11.demoMode then return; end
    elseif lab=="LD12" then
        if ~isfield(LD12,"autosave_enabled") then return; end
        if ~LD12.autosave_enabled | LD12.demoMode then return; end
    else
        if ~isfield(LD2,"autosave_enabled") then return; end
        if ~LD2.autosave_enabled | LD2.example_active then return; end
    end
    try
        path=bench_save_snapshot(lab);
        // Retention is scoped to files created in this running session; never
        // delete another student's files or old recoverable work automatically.
        if lab=="LD1" then
            if ~isfield(LD1,"autosave_paths") then LD1.autosave_paths=emptystr(0,1); end
            LD1.autosave_paths($+1)=path;
            LD1.autosave_paths=bench_autosave_trim(LD1.autosave_paths);
            LD1.autosave_error="";
        elseif lab=="LD3" then
            if ~isfield(LD3,"autosave_paths") then LD3.autosave_paths=emptystr(0,1); end
            LD3.autosave_paths($+1)=path;
            LD3.autosave_paths=bench_autosave_trim(LD3.autosave_paths);
            LD3.autosave_error="";
        elseif lab=="LD4" then
            if ~isfield(LD4,"autosave_paths") then LD4.autosave_paths=emptystr(0,1); end
            LD4.autosave_paths($+1)=path;
            LD4.autosave_paths=bench_autosave_trim(LD4.autosave_paths);
            LD4.autosave_error="";
        elseif lab=="LD5" then
            if ~isfield(LD5,"autosave_paths") then LD5.autosave_paths=emptystr(0,1); end
            LD5.autosave_paths($+1)=path;
            LD5.autosave_paths=bench_autosave_trim(LD5.autosave_paths);
            LD5.autosave_error="";
        elseif lab=="LD6" then
            if ~isfield(LD6,"autosave_paths") then LD6.autosave_paths=emptystr(0,1); end
            LD6.autosave_paths($+1)=path;
            LD6.autosave_paths=bench_autosave_trim(LD6.autosave_paths);
            LD6.autosave_error="";
        elseif lab=="LD7" then
            if ~isfield(LD7,"autosave_paths") then LD7.autosave_paths=emptystr(0,1); end
            LD7.autosave_paths($+1)=path;
            LD7.autosave_paths=bench_autosave_trim(LD7.autosave_paths);
            LD7.autosave_error="";
        elseif lab=="LD8" then
            if ~isfield(LD8,"autosave_paths") then LD8.autosave_paths=emptystr(0,1); end
            LD8.autosave_paths($+1)=path;
            LD8.autosave_paths=bench_autosave_trim(LD8.autosave_paths);
            LD8.autosave_error="";
        elseif lab=="LD9" then
            if ~isfield(LD9,"autosave_paths") then LD9.autosave_paths=emptystr(0,1); end
            LD9.autosave_paths($+1)=path;
            LD9.autosave_paths=bench_autosave_trim(LD9.autosave_paths);
            LD9.autosave_error="";
        elseif lab=="LD10" then
            if ~isfield(LD10,"autosave_paths") then LD10.autosave_paths=emptystr(0,1); end
            LD10.autosave_paths($+1)=path;
            LD10.autosave_paths=bench_autosave_trim(LD10.autosave_paths);
            LD10.autosave_error="";
        elseif lab=="LD11" then
            if ~isfield(LD11,"autosave_paths") then LD11.autosave_paths=emptystr(0,1); end
            LD11.autosave_paths($+1)=path;
            LD11.autosave_paths=bench_autosave_trim(LD11.autosave_paths);
            LD11.autosave_error="";
        elseif lab=="LD12" then
            if ~isfield(LD12,"autosave_paths") then LD12.autosave_paths=emptystr(0,1); end
            LD12.autosave_paths($+1)=path;
            LD12.autosave_paths=bench_autosave_trim(LD12.autosave_paths);
            LD12.autosave_error="";
        else
            if ~isfield(LD2,"autosave_paths") then LD2.autosave_paths=emptystr(0,1); end
            LD2.autosave_paths($+1)=path;
            LD2.autosave_paths=bench_autosave_trim(LD2.autosave_paths);
            LD2.autosave_error="";
        end
    catch
        problem=strcat(lasterror()," ");
        if lab=="LD1" then LD1.autosave_error=problem;
            ld1_set_status("Nepavyko išsaugoti juodraščio.","error",problem);
        elseif lab=="LD3" then LD3.autosave_error=problem;
            ld3_set_status("Nepavyko išsaugoti juodraščio.","error",problem);
        elseif lab=="LD4" then LD4.autosave_error=problem;
            ld4_set_status("Nepavyko išsaugoti juodraščio.","error",problem);
        elseif lab=="LD5" then LD5.autosave_error=problem;
            ld5_set_status("Nepavyko išsaugoti juodraščio.","error",problem);
        elseif lab=="LD6" then LD6.autosave_error=problem;
            ld6_set_status("Nepavyko išsaugoti juodraščio.","error",problem);
        elseif lab=="LD7" then LD7.autosave_error=problem;
            ld7_set_status("Nepavyko išsaugoti juodraščio.","error",problem);
        elseif lab=="LD8" then LD8.autosave_error=problem;
            ld8_set_status("Nepavyko išsaugoti juodraščio.","error",problem);
        elseif lab=="LD9" then LD9.autosave_error=problem;
            ld9_set_status("Nepavyko išsaugoti juodraščio.","error",problem);
        elseif lab=="LD10" then LD10.autosave_error=problem;
            ld10_set_status("Nepavyko išsaugoti juodraščio.","error",problem);
        elseif lab=="LD11" then LD11.autosave_error=problem;
            ld11_set_status("Nepavyko išsaugoti juodraščio.","error",problem);
        elseif lab=="LD12" then LD12.autosave_error=problem;
            ld12_set_status("Nepavyko išsaugoti juodraščio.","error",problem);
        else LD2.autosave_error=problem;ld2_set_status("Nepavyko išsaugoti juodraščio: "+problem,"error");end
    end
endfunction

function session=bench_read_snapshot(path,lab)
    session=[]; info=fileinfo(path);
    if isempty(info) then error("Juodraščio failas nerastas."); end
    if info(1)>16*1024*1024 then error("Juodraščio failas per didelis.");end
    load(path,"session");
    if typeof(session)<>"st" then error("Netinkamas juodraštis.");end
    if session.format<>"Grandiniu-LD-session-1" | session.lab<>lab then error("Kito darbo arba versijos juodraštis.");end
    st=session.student; student_profile(st.number,st.name,st.group,lab);
    if lab=="LD1" then expected=ld1_variant_config(st.number);
    elseif lab=="LD3" then expected=ld3_variant_config(st.number);
    elseif lab=="LD4" then expected=ld4_variant_config(st.number);
    elseif lab=="LD5" then expected=ld5_variant_config(st.number);
    elseif lab=="LD6" then expected=ld6_variant_config(st.number);
elseif lab=="LD7" then expected=ld7_variant_config(st.number);
elseif lab=="LD8" then expected=ld8_variant_config(st.number);
elseif lab=="LD9" then expected=ld9_variant_config(st.number);
elseif lab=="LD10" then expected=ld10_variant_config(st.number);
elseif lab=="LD11" then expected=ld11_variant_config(st.number);
elseif lab=="LD12" then expected=ld12_variant_config(st.number);
    else expected=ld2_variant_config(st.number);end
    if ~isequal(session.cfg,expected) then error("Juodraščio variantas ir parametrai nesutampa.");end
    if lab=="LD1" then
        if or(size(session.state.stepQ)<>[9 3]) | session.state.step<1 | session.state.step>9 then error("Sugadinti LD1 atsakymai.");end
    elseif lab=="LD3" then
        if or(size(session.state.answers)<>[6 8]) | session.state.step<1 | session.state.step>6 then error("Sugadinti LD3 atsakymai.");end
    elseif lab=="LD4" then
        if or(size(session.state.answers)<>[7 8]) | session.state.step<1 | session.state.step>7 then error("Sugadinti LD4 atsakymai.");end
    elseif lab=="LD5" then
        if or(size(session.state.answers)<>[6 8]) | ~ld5_valid_index(session.state.step,6) then error("Sugadinti LD5 atsakymai.");end
    elseif lab=="LD6" then
        if or(size(session.state.answers)<>[6 8]) | ~ld6_valid_index(session.state.step,6) then error("Sugadinti LD6 atsakymai.");end
    elseif lab=="LD7" then
        if or(size(session.state.answers)<>[6 8]) | ~ld7_valid_index(session.state.step,6) then error("Sugadinti LD7 atsakymai.");end
    elseif lab=="LD8" then
        if or(size(session.state.answers)<>[6 8]) | ~ld8_valid_index(session.state.step,6) then error("Sugadinti LD8 atsakymai.");end
    elseif lab=="LD9" then
        if or(size(session.state.answers)<>[6 8]) | ~ld9_valid_index(session.state.step,6) then error("Sugadinti LD9 atsakymai.");end
    elseif lab=="LD10" then
        if or(size(session.state.answers)<>[6 8]) | ~ld10_valid_index(session.state.step,6) then error("Sugadinti LD10 atsakymai.");end
    elseif lab=="LD11" then
        if or(size(session.state.answers)<>[6 8]) | ~ld11_valid_index(session.state.step,6) then error("Sugadinti LD11 atsakymai.");end
    elseif lab=="LD12" then
        if or(size(session.state.answers)<>[6 8]) | ~ld12_valid_index(session.state.step,6) then error("Sugadinti LD12 atsakymai.");end
    else
        if or(size(session.state.answers_text)<>[12 8]) | session.state.step<1 | session.state.step>12 then error("Sugadinti LD2 atsakymai.");end
    end
endfunction

function bench_restore_snapshot(session)
    global LD1 LD2 LD3 LD4 LD5 LD6 LD7 LD8 LD9 LD10 LD11 LD12 BENCH_AUTOSAVE_SUSPENDED;
    BENCH_AUTOSAVE_SUSPENDED=%t;
    try
        if session.lab=="LD1" then
            step=session.state.step;
            LD1.cfg=session.cfg;LD1.student=session.student;
            if ~isfield(session.state,"stepVR") then session.state.stepVR=%nan*ones(1,9); end
            if ~isfield(session.state,"guided") then session.state.guided=%f; end
            if ~isfield(session.state,"practice_used") then session.state.practice_used=%f; end
            if ~isfield(session.state,"assessment") then session.state.assessment=%f; end
            if isfield(session.state,"guided_used") then
                if session.state.guided_used then session.state.assessment=%f; session.state.practice_used=%t; end
            end
            // Rendering a stage can change transient controls; reapply saved
            // values afterwards, with power off and the original raw answers.
            LD1.step=0;
            for field=fieldnames(session.state)'
                if field=="step" then continue;end
                LD1(field)=session.state(field);
            end
            ld1_build_panel(session.state.panel);ld1_set_step(step);
            for field=fieldnames(session.state)';LD1(field)=session.state(field);end
            LD1.powerOn=%f;LD1.demoMode=%f;LD1.pendingTerminal="";
            ld1_restore_step_inputs(step);
            if step<9 then
                ld1_apply_meter_mode_quiet(LD1.meterMode);ld1_set_power_quiet(%f);
                LD1.ui.vrSlider.value=LD1.VR1;LD1.ui.vrText.string=string(LD1.VR1)+" Ω";
                ld1_update_actual_values();ld1_redraw_panel();
            else
                // Stage 9 has results only; its instrument widgets were deleted.
                ld1_update_results_table(%f);
            end
            LD1.ui.studentIdentity.string=student_caption(LD1.student);
            ld1_student_sync();
        elseif session.lab=="LD3" then
            LD3.cfg=session.cfg;LD3.student=session.student;
            for field=fieldnames(session.state)';LD3(field)=session.state(field);end
            if ~isfield(session.state,"assessment") then LD3.assessment=%f;LD3.practice_used=%t;end
            LD3.powerOn=%f;LD3.switchOn=%f;LD3.demoMode=%f;LD3.pending="";
            LD3.autosave_enabled=~LD3.ui.headless;
            ld3_render_stage();ld3_student_sync();
            ld3_set_status("Juodraštis atkurtas: "+student_caption(LD3.student),"ok","Maitinimas išjungtas.");
        elseif session.lab=="LD4" then
            LD4.cfg=session.cfg;LD4.student=session.student;
            for field=fieldnames(session.state)';LD4(field)=session.state(field);end
            if ~isfield(session.state,"assessment") then LD4.assessment=%f;LD4.practice_used=%t;end
            LD4.powerOn=%f;LD4.switchOn=%f;LD4.demoMode=%f;LD4.pending="";
            LD4.lastMeasurement=%nan; LD4.autosave_enabled=~LD4.ui.headless;
            ld4_render_stage();ld4_student_sync();
            ld4_set_status("Juodraštis atkurtas: "+student_caption(LD4.student),"ok","Maitinimas išjungtas.");
        elseif session.lab=="LD5" then
            LD5.cfg=session.cfg;LD5.student=session.student;
            for field=fieldnames(session.state)';LD5(field)=session.state(field);end
            if ~isfield(session.state,"report_wires") then
                LD5.report_wires=list();
                for k=1:6;LD5.report_wires(k)=emptystr(0,2);end
                LD5.done(:)=%f;
            end
            if ~isfield(session.state,"assessment") then LD5.assessment=%f;LD5.practice_used=%t;end
            LD5.powerOn=%f;LD5.switchOn=%f;LD5.demoMode=%f;LD5.pending="";
            LD5.lastMeasurement=%nan;LD5.autosave_enabled=~LD5.ui.headless;
            ld5_render_stage();ld5_student_sync();
            ld5_set_status("Juodraštis atkurtas: "+student_caption(LD5.student),"ok","Maitinimas išjungtas.");
        elseif session.lab=="LD6" then
            LD6.cfg=session.cfg;LD6.student=session.student;
            for field=fieldnames(session.state)';LD6(field)=session.state(field);end
            if ~isfield(session.state,"report_wires") then
                LD6.report_wires=list();
                for k=1:4;LD6.report_wires(k)=emptystr(0,2);end
                LD6.done(:)=%f;
            end
            if ~isfield(session.state,"assessment") then LD6.assessment=%f;LD6.practice_used=%t;end
            LD6.powerOn=%f;LD6.switchOn=%f;LD6.demoMode=%f;LD6.pending="";
            LD6.lastMeasurement=%nan;LD6.autosave_enabled=~LD6.ui.headless;
            ld6_render_stage();ld6_student_sync();
            ld6_set_status("Juodraštis atkurtas: "+student_caption(LD6.student),"ok","Maitinimas išjungtas.");
        elseif session.lab=="LD7" then
            LD7.cfg=session.cfg;LD7.student=session.student;
            for field=fieldnames(session.state)';LD7(field)=session.state(field);end
            if ~isfield(session.state,"report_wires") then
                LD7.report_wires=list();
                for k=1:3;LD7.report_wires(k)=emptystr(0,2);end
                LD7.done(:)=%f;
            end
            if ~isfield(session.state,"assessment") then LD7.assessment=%f;LD7.practice_used=%t;end
            LD7.powerOn=%f;LD7.switchOn=%f;LD7.demoMode=%f;LD7.pending="";
            LD7.lastMeasurement=%nan;LD7.autosave_enabled=~LD7.ui.headless;
            ld7_render_stage();ld7_student_sync();
            ld7_set_status("Juodraštis atkurtas: "+student_caption(LD7.student),"ok","Maitinimas išjungtas.");
        elseif session.lab=="LD8" then
            LD8.cfg=session.cfg;LD8.student=session.student;
            // Apply the store before rendering, so stale edits cannot overwrite it.
            for field=fieldnames(session.state)';LD8(field)=session.state(field);end
            if ~isfield(session.state,"report_wires") then
                LD8.report_wires=list();
                for k=1:3;LD8.report_wires(k)=emptystr(0,2);end
                LD8.done(:)=%f;
            end
            LD8.powerOn=%f;LD8.switchOn=%f;LD8.demoMode=%f;LD8.pending="";
            LD8.lastMeasurement=%nan;
            if ~isfield(session.state,"assessment") then LD8.assessment=%f;LD8.practice_used=%t;end
            LD8.autosave_enabled=~LD8.ui.headless;
            ld8_render_stage();
            ld8_set_status("Juodraštis atkurtas: "+student_caption(LD8.student),"ok","Maitinimas išjungtas.");
        elseif session.lab=="LD9" then
            LD9.cfg=session.cfg;LD9.student=session.student;
            for field=fieldnames(session.state)';LD9(field)=session.state(field);end
            if ~isfield(session.state,"report_wires") then
                LD9.report_wires=emptystr(0,2);
                LD9.done(:)=%f;
            end
            if ~isfield(session.state,"assessment") then LD9.assessment=%f;LD9.practice_used=%t;end
            LD9.powerOn=%f;LD9.switchOn=%f;LD9.demoMode=%f;LD9.pending="";
            LD9.lastMeasurement=%nan;LD9.autosave_enabled=~LD9.ui.headless;
            ld9_render_stage();ld9_student_sync();
            ld9_set_status("Juodraštis atkurtas: "+student_caption(LD9.student),"ok","Maitinimas išjungtas.");
        elseif session.lab=="LD10" then
            LD10.cfg=session.cfg;LD10.student=session.student;
            for field=fieldnames(session.state)';LD10(field)=session.state(field);end
            if ~isfield(session.state,"report_wires") then
                LD10.report_wires=emptystr(0,2);
                LD10.done(:)=%f;
            end
            if ~isfield(session.state,"assessment") then LD10.assessment=%f;LD10.practice_used=%t;end
            LD10.powerOn=%f;LD10.switchOn=%f;LD10.demoMode=%f;LD10.pending="";
            LD10.lastMeasurement=%nan;LD10.autosave_enabled=~LD10.ui.headless;
            ld10_render_stage();ld10_student_sync();
            ld10_set_status("Juodraštis atkurtas: "+student_caption(LD10.student),"ok","Maitinimas išjungtas.");
        elseif session.lab=="LD11" then
            LD11.cfg=session.cfg;LD11.student=session.student;
            for field=fieldnames(session.state)';LD11(field)=session.state(field);end
            if ~isfield(session.state,"report_wires") then
                LD11.report_wires=list();
                for k=1:2;LD11.report_wires(k)=emptystr(0,2);end
                LD11.done(:)=%f;
            end
            if ~isfield(session.state,"assessment") then LD11.assessment=%f;LD11.practice_used=%t;end
            LD11.powerOn=%f;LD11.switchOn=%f;LD11.demoMode=%f;LD11.pending="";
            LD11.lastMeasurement=%nan;LD11.autosave_enabled=~LD11.ui.headless;
            ld11_render_stage();ld11_student_sync();
            ld11_set_status("Juodraštis atkurtas: "+student_caption(LD11.student),"ok","Maitinimas išjungtas.");
        elseif session.lab=="LD12" then
            LD12.cfg=session.cfg;LD12.student=session.student;
            for field=fieldnames(session.state)';LD12(field)=session.state(field);end
            if ~isfield(session.state,"report_wires") then
                LD12.report_wires=list();
                for k=1:2;LD12.report_wires(k)=emptystr(0,2);end
                LD12.done(:)=%f;
            end
            if ~isfield(session.state,"assessment") then LD12.assessment=%f;LD12.practice_used=%t;end
            LD12.powerOn=%f;LD12.switchOn=%f;LD12.demoMode=%f;LD12.pending="";
            LD12.lastMeasurement=%nan;LD12.autosave_enabled=~LD12.ui.headless;
            ld12_render_stage();ld12_student_sync();
            ld12_set_status("Juodraštis atkurtas: "+student_caption(LD12.student),"ok","Maitinimas išjungtas.");
        else
            LD2.cfg=session.cfg;LD2.state=session.state;LD2.state.power=%f;
            if ~isfield(LD2.state,"assessment") then LD2.state.assessment=%f;end
            if ~isfield(LD2.state,"practice_used") then LD2.state.practice_used=%t;end
            LD2.example_active=%f;LD2.ui.answer_step=0;LD2.ui.answer_edits=[];
            LD2.autosave_enabled=~LD2.ui.headless;
            ld2_reset_live_readings(ld2_phase_for_step(LD2.state.step));ld2_render_step();
        end
    catch
        BENCH_AUTOSAVE_SUSPENDED=%f;error(lasterror());
    end
    BENCH_AUTOSAVE_SUSPENDED=%f;
endfunction

function bench_open_snapshot(lab)
    path=uigetfile("*.sod",fullfile(bench_documents(),"Juodrasciai"),"Atverti vietinį darbo juodraštį");
    if isempty(path) then return;end
    if stripblanks(path)=="" then return;end
    try session=bench_read_snapshot(path,lab);bench_restore_snapshot(session);
    catch messagebox(lasterror(),"Juodraštis neatvertas","error");end
endfunction
