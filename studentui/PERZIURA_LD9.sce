// Originalaus stendo peržiūra su naujomis matavimo užduotimis.
mode(-1);
rt_preview=get_absolute_file_path("PERZIURA_LD9.sce");
exec(rt_preview+"LD9/LD9_LOAD.sce",-1);
exec(rt_preview+"RT_LOAD.sce",-1);
rt_start(rt_preview,"LD9",student_profile(1,"Stendo peržiūra","BANDOMASIS","LD9"),mo_config("LD9",1));
