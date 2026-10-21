// Pakrauna LD11 funkcijas neatidarius langų (kaip LD1–LD8_LOAD).
LD11_ROOT = get_absolute_file_path("LD11_LOAD.sce");
ld11_saved_funcprot = funcprot(); funcprot(0);
exec(LD11_ROOT + "../student_style.sci", -1);
exec(LD11_ROOT + "../student_profile.sci", -1);
exec(LD11_ROOT + "../bench_common.sci", -1);
exec(LD11_ROOT + "../bench_report.sci", -1);
exec(LD11_ROOT + "../bench_session.sci", -1);
for ld11_file = ["ld11_ids.sci" "ld11_config.sci" "ld11_utils.sci" "ld11_circuit.sci" "ld11_gui.sci" "ld11_callbacks.sci" "ld11_student.sci" "ld11_guidance.sci"]
    exec(LD11_ROOT + ld11_file, -1);
end
funcprot(ld11_saved_funcprot);
