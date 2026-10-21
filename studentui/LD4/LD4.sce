mode(-1);
rt_entry=get_absolute_file_path("LD4.sce");
exec(rt_entry+"LD4_LOAD.sce",-1);
exec(rt_entry+"../RT_LOAD.sce",-1);
rt_launch(rt_entry+"../","LD4");
