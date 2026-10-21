// Pakrauna LD4 funkcijas neatidarius langų (kaip LD1/LD2_LOAD).
LD4_ROOT=get_absolute_file_path("LD4_LOAD.sce");
ld4_saved_funcprot=funcprot(); funcprot(0);
exec(LD4_ROOT+"../student_style.sci",-1);
exec(LD4_ROOT+"../student_profile.sci",-1);
exec(LD4_ROOT+"../bench_common.sci",-1);
exec(LD4_ROOT+"../bench_report.sci",-1);
exec(LD4_ROOT+"../bench_session.sci",-1);
for ld4_file=["ld4_ids.sci" "ld4_config.sci" "ld4_utils.sci" "ld4_circuit.sci" "ld4_gui.sci" "ld4_callbacks.sci" "ld4_student.sci"]
    exec(LD4_ROOT+ld4_file,-1);
end
exec(LD4_ROOT+"ld4_guidance.sci",-1);
funcprot(ld4_saved_funcprot);
