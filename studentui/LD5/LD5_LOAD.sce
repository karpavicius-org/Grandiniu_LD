// Pakrauna LD5 funkcijas neatidarius langų (kaip LD1/LD2_LOAD).
LD5_ROOT=get_absolute_file_path("LD5_LOAD.sce");
ld5_saved_funcprot=funcprot(); funcprot(0);
exec(LD5_ROOT+"../student_style.sci",-1);
exec(LD5_ROOT+"../student_profile.sci",-1);
exec(LD5_ROOT+"../bench_common.sci",-1);
exec(LD5_ROOT+"../bench_report.sci",-1);
exec(LD5_ROOT+"../bench_session.sci",-1);
for ld5_file=["ld5_ids.sci" "ld5_config.sci" "ld5_utils.sci" "ld5_circuit.sci" "ld5_gui.sci" "ld5_callbacks.sci" "ld5_student.sci"]
    exec(LD5_ROOT+ld5_file,-1);
end
exec(LD5_ROOT+"ld5_guidance.sci",-1);
funcprot(ld5_saved_funcprot);
