// Originalaus stendo peržiūra su naujomis matavimo užduotimis.
mode(-1);
rt_preview=get_absolute_file_path("PERZIURA_LD6.sce");
exec(rt_preview+"LD6/LD6_LOAD.sce",-1);
exec(rt_preview+"RT_LOAD.sce",-1);
rt_start(rt_preview,"LD6",student_profile(1,"Stendo peržiūra","BANDOMASIS","LD6"),mo_config("LD6",1));
