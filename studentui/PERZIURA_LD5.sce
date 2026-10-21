// Originalaus stendo peržiūra su naujomis matavimo užduotimis.
mode(-1);
rt_preview=get_absolute_file_path("PERZIURA_LD5.sce");
exec(rt_preview+"LD5/LD5_LOAD.sce",-1);
exec(rt_preview+"RT_LOAD.sce",-1);
rt_start(rt_preview,"LD5",student_profile(1,"Stendo peržiūra","BANDOMASIS","LD5"),mo_config("LD5",1));
