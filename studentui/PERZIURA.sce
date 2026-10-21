// Originalaus stendo peržiūra su naujomis matavimo užduotimis.
mode(-1);
rt_preview=get_absolute_file_path("PERZIURA.sce");
exec(rt_preview+"LD1/LD1_LOAD.sce",-1);
exec(rt_preview+"RT_LOAD.sce",-1);
rt_start(rt_preview,"LD1",student_profile(1,"Stendo peržiūra","BANDOMASIS","LD1"),mo_config("LD1",1));
