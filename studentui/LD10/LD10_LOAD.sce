// Pakrauna LD10 funkcijas neatidarius langų (kaip LD1–LD8_LOAD).
LD10_ROOT = get_absolute_file_path("LD10_LOAD.sce");
ld10_saved_funcprot = funcprot(); funcprot(0);
exec(LD10_ROOT + "../student_style.sci", -1);
exec(LD10_ROOT + "../student_profile.sci", -1);
exec(LD10_ROOT + "../bench_common.sci", -1);
exec(LD10_ROOT + "../bench_report.sci", -1);
exec(LD10_ROOT + "../bench_session.sci", -1);
for ld10_file = ["ld10_ids.sci" "ld10_config.sci" "ld10_utils.sci" "ld10_circuit.sci" "ld10_gui.sci" "ld10_callbacks.sci" "ld10_student.sci" "ld10_guidance.sci"]
    exec(LD10_ROOT + ld10_file, -1);
end
funcprot(ld10_saved_funcprot);
