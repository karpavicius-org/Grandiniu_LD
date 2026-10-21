// Pakrauna LD12 funkcijas neatidarius langų (kaip LD1–LD8_LOAD).
LD12_ROOT = get_absolute_file_path("LD12_LOAD.sce");
ld12_saved_funcprot = funcprot(); funcprot(0);
exec(LD12_ROOT + "../student_style.sci", -1);
exec(LD12_ROOT + "../student_profile.sci", -1);
exec(LD12_ROOT + "../bench_common.sci", -1);
exec(LD12_ROOT + "../bench_report.sci", -1);
exec(LD12_ROOT + "../bench_session.sci", -1);
for ld12_file = ["ld12_ids.sci" "ld12_config.sci" "ld12_utils.sci" "ld12_circuit.sci" "ld12_gui.sci" "ld12_callbacks.sci" "ld12_student.sci" "ld12_guidance.sci"]
    exec(LD12_ROOT + ld12_file, -1);
end
funcprot(ld12_saved_funcprot);
