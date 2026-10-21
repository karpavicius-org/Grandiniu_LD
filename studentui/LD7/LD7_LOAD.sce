// Pakrauna LD7 funkcijas neatidarius langų (kaip LD1–LD6_LOAD).
LD7_ROOT = get_absolute_file_path("LD7_LOAD.sce");
ld7_saved_funcprot = funcprot(); funcprot(0);
exec(LD7_ROOT + "../student_style.sci", -1);
exec(LD7_ROOT + "../student_profile.sci", -1);
exec(LD7_ROOT + "../bench_common.sci", -1);
exec(LD7_ROOT + "../bench_report.sci", -1);
exec(LD7_ROOT + "../bench_session.sci", -1);
for ld7_file = ["ld7_ids.sci" "ld7_config.sci" "ld7_utils.sci" "ld7_circuit.sci" "ld7_gui.sci" "ld7_callbacks.sci" "ld7_student.sci" "ld7_guidance.sci"]
    exec(LD7_ROOT + ld7_file, -1);
end
funcprot(ld7_saved_funcprot);
