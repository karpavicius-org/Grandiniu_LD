// Pakrauna LD6 funkcijas neatidarius langų (kaip LD1/LD2_LOAD).
LD6_ROOT=get_absolute_file_path("LD6_LOAD.sce");
ld6_saved_funcprot=funcprot(); funcprot(0);
exec(LD6_ROOT+"../student_style.sci",-1);
exec(LD6_ROOT+"../student_profile.sci",-1);
exec(LD6_ROOT+"../bench_common.sci",-1);
exec(LD6_ROOT+"../bench_report.sci",-1);
exec(LD6_ROOT+"../bench_session.sci",-1);
for ld6_file=["ld6_ids.sci" "ld6_config.sci" "ld6_utils.sci" "ld6_circuit.sci" "ld6_gui.sci" "ld6_callbacks.sci" "ld6_student.sci" "ld6_guidance.sci"]
    exec(LD6_ROOT+ld6_file,-1);
end
funcprot(ld6_saved_funcprot);
