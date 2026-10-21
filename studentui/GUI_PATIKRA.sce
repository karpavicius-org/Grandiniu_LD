mode(-1);funcprot(0);
root=get_absolute_file_path("GUI_PATIKRA.sce");
try
 exec(root+"RT_MODELS_LOAD.sce",-1);exec(root+"RT_LOAD.sce",-1);bench_core_require();
 global MO;
 for n=1:12
  lab="LD"+string(n);cfg=mo_config(lab,1);st=student_profile(1,"Langu patikra "+bench_id(),"PATIKRA",lab);
  rt_start(root,lab,st,cfg);assert_checkequal(MO.phase,"wiring");assert_checkfalse(MO.helpEnabled);
  rt_help();assert_checktrue(MO.helpEnabled);assert_checktrue(rt_target_ready(MO.focusHandle));
  t=MO.protocol.trials(1);
  for k=1:size(t.wires,1);rt_port(t.wires(k,1));rt_port(t.wires(k,2));end
  assert_checktrue(mo_wires_equal(MO.wires,t.wires));rt_measure();assert_checkequal(MO.phase,"copy");
  for k=1:size(MO.current.values,"*");MO.ui.copyEdits(k).string=MO.displayed(k);end
  rt_primary();assert_checkequal(MO.phase,"between");
  rt_help_close();rt_close();
  mprintf("PASS %s: langas, kontaktai, pagalba ir matavimas\n",lab);
 end
 mprintf("PASS: 12 stendu GUI callback patikra\n");exit(0);
catch
 [e,c,l,f]=lasterror();mprintf("FAIL %s:%d %s\n",f,l,strcat(e," "));exit(1);
end
