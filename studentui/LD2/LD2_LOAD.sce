// Load functions without running tests or opening windows.
LD2_ROOT=get_absolute_file_path("LD2_LOAD.sce");
ld2_saved_funcprot=funcprot(); funcprot(0);
exec(LD2_ROOT+"../student_style.sci",-1);
exec(LD2_ROOT+"../student_profile.sci",-1);
exec(LD2_ROOT+"../bench_common.sci",-1);
exec(LD2_ROOT+"../bench_report.sci",-1);
exec(LD2_ROOT+"../bench_session.sci",-1);
for ld2_file=["ld2_config.sci" "ld2_variants.sci" "ld2_model.sci" "ld2_ids.sci" "ld2_method.sci" ...
    "ld2_utils.sci" "ld2_wiring.sci" ...
    "ld2_observations.sci" "ld2_guide.sci" "ld2_storage.sci" "ld2_plots.sci" "ld2_gui.sci" ...
    "ld2_callbacks.sci" "ld2_selftest.sci" "ld2_student.sci"]
    exec(LD2_ROOT+ld2_file,-1);
end
funcprot(ld2_saved_funcprot);
