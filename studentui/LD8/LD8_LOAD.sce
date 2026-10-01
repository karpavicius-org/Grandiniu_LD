// Pakrauna LD8 funkcijas neatidarius langų (kaip LD1–LD12_LOAD).
LD8_ROOT = get_absolute_file_path("LD8_LOAD.sce");
ld8_saved_funcprot = funcprot(); funcprot(0);
exec(LD8_ROOT + "../student_style.sci", -1);
exec(LD8_ROOT + "../student_profile.sci", -1);
exec(LD8_ROOT + "../bench_common.sci", -1);
exec(LD8_ROOT + "../bench_report.sci", -1);
exec(LD8_ROOT + "../bench_session.sci", -1);
for ld8_file = ["ld8_ids.sci" "ld8_config.sci" "ld8_utils.sci" "ld8_circuit.sci" "ld8_gui.sci" "ld8_callbacks.sci" "ld8_student.sci"]
    exec(LD8_ROOT + ld8_file, -1);
end
funcprot(ld8_saved_funcprot);
