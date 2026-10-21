RT_ROOT=get_absolute_file_path("RT_LOAD.sce");
rt_saved_funcprot=funcprot();funcprot(0);
for rt_file=["mo_public.sci" "mo_common.sci" "mo_ld1_2.sci" "mo_ld3_6.sci" "mo_ld7_12.sci" "mo_report.sci" "mo_teacher.sci" "rt_session.sci" "rt_student.sci" "rt_preview.sci"]
 exec(RT_ROOT+rt_file,-1);
end
for rt_n=1:12
 exec(RT_ROOT+"rt_ld"+string(rt_n)+"_bridge.sci",-1);
end
exec(RT_ROOT+"rt_overrides.sci",-1);
funcprot(rt_saved_funcprot);
