// Originalaus stendo peržiūra su naujomis matavimo užduotimis.
mode(-1);
rt_preview=get_absolute_file_path("PERZIURA_LD12.sce");
exec(rt_preview+"LD12/LD12_LOAD.sce",-1);
exec(rt_preview+"RT_LOAD.sce",-1);
rt_start(rt_preview,"LD12",student_profile(1,"Stendo peržiūra","BANDOMASIS","LD12"),mo_config("LD12",1));
