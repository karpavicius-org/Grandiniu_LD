// Execute in the caller's scope: Scilab functions loaded inside a helper
// function would disappear when that helper returns.
rt_model_root=get_absolute_file_path("RT_MODELS_LOAD.sce");
rt_model_protection=funcprot();funcprot(0);
for rt_model_n=1:12
    rt_model_lab="LD"+string(rt_model_n);
    exec(fullfile(rt_model_root,rt_model_lab,rt_model_lab+"_LOAD.sce"),-1);
end
for rt_model_file=["mo_public.sci" "mo_common.sci" "mo_ld1_2.sci" "mo_ld3_6.sci" "mo_ld7_12.sci"]
    exec(fullfile(rt_model_root,rt_model_file),-1);
end
if exists("rt_render")>0 then exec(fullfile(rt_model_root,"rt_overrides.sci"),-1);end
funcprot(rt_model_protection);
