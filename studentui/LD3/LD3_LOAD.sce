// Pakrauna LD3 funkcijas neatidarius langų (kaip LD1/LD2_LOAD).
LD3_ROOT=get_absolute_file_path("LD3_LOAD.sce");
ld3_saved_funcprot=funcprot(); funcprot(0);
exec(LD3_ROOT+"../student_style.sci",-1);
exec(LD3_ROOT+"../student_profile.sci",-1);
exec(LD3_ROOT+"../bench_common.sci",-1);
exec(LD3_ROOT+"../bench_report.sci",-1);
exec(LD3_ROOT+"../bench_session.sci",-1);
for ld3_file=["ld3_ids.sci" "ld3_config.sci" "ld3_utils.sci" "ld3_circuit.sci" "ld3_gui.sci" "ld3_callbacks.sci" "ld3_student.sci"]
    exec(LD3_ROOT+ld3_file,-1);
end
exec(LD3_ROOT+"ld3_guidance.sci",-1);
funcprot(ld3_saved_funcprot);
