// Originalaus stendo peržiūra su naujomis matavimo užduotimis.
mode(-1);
rt_preview=get_absolute_file_path("PERZIURA_LD8.sce");
exec(rt_preview+"LD8/LD8_LOAD.sce",-1);
exec(rt_preview+"RT_LOAD.sce",-1);
rt_start(rt_preview,"LD8",student_profile(1,"Stendo peržiūra","BANDOMASIS","LD8"),mo_config("LD8",1));
