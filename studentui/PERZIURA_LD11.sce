// Originalaus stendo peržiūra su naujomis matavimo užduotimis.
mode(-1);
rt_preview=get_absolute_file_path("PERZIURA_LD11.sce");
exec(rt_preview+"LD11/LD11_LOAD.sce",-1);
exec(rt_preview+"RT_LOAD.sce",-1);
rt_start(rt_preview,"LD11",student_profile(1,"Stendo peržiūra","BANDOMASIS","LD11"),mo_config("LD11",1));
