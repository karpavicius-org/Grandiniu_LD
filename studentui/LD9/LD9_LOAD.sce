// Pakrauna LD9 funkcijas neatidarius langų (kaip LD1–LD8_LOAD).
LD9_ROOT = get_absolute_file_path("LD9_LOAD.sce");
ld9_saved_funcprot = funcprot(); funcprot(0);
exec(LD9_ROOT + "../student_style.sci", -1);
exec(LD9_ROOT + "../student_profile.sci", -1);
exec(LD9_ROOT + "../bench_common.sci", -1);
exec(LD9_ROOT + "../bench_report.sci", -1);
exec(LD9_ROOT + "../bench_session.sci", -1);
for ld9_file = ["ld9_ids.sci" "ld9_config.sci" "ld9_utils.sci" "ld9_circuit.sci" "ld9_gui.sci" "ld9_callbacks.sci" "ld9_student.sci" "ld9_guidance.sci"]
    exec(LD9_ROOT + ld9_file, -1);
end
funcprot(ld9_saved_funcprot);
