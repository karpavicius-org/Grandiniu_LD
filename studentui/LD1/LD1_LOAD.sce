// Load functions without opening windows or modifying a live laboratory.
LD1_ROOT=get_absolute_file_path("LD1_LOAD.sce");
ld1_saved_funcprot=funcprot(); funcprot(0);
exec(LD1_ROOT+"../student_style.sci",-1);
exec(LD1_ROOT+"../student_profile.sci",-1);
exec(LD1_ROOT+"../bench_common.sci",-1);
exec(LD1_ROOT+"../bench_report.sci",-1);
exec(LD1_ROOT+"../bench_session.sci",-1);
for ld1_file=["ld1_ids.sci" "ld1_config.sci" "ld1_utils.sci" "ld1_circuit.sci" "ld1_gui.sci" "ld1_callbacks.sci" "ld1_student.sci"]
    exec(LD1_ROOT+ld1_file,-1);
end
exec(LD1_ROOT+"ld1_assist.sci",-1);
exec(LD1_ROOT+"ld1_measurement.sci",-1);
funcprot(ld1_saved_funcprot);
