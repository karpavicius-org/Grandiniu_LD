mode(-1);funcprot(0);
root=get_absolute_file_path("HEADLESS.sce")+"../";
try
 exec(root+"RT_MODELS_LOAD.sce",-1);bench_core_require();
 trials=0;readings=0;rejected=0;counts=[7 12 3 7 3 4 7 12 12 12 4 4];
 for n=1:12
  lab="LD"+string(n);
  for variant=1:64
   cfg=mo_config(lab,variant);p=mo_protocol(lab,cfg);assert_checkequal(length(p.trials),counts(n));
   for k=1:length(p.trials)
    t=p.trials(k);r=mo_measure(lab,cfg,t,t.wires);
    rr=mo_measure(lab,cfg,t,t.wires($:-1:1,[2 1]));assert_checkalmostequal(r.values,rr.values);
    assert_checkequal(size(r.values,"*"),size(r.ids,"*"));
    for j=1:size(r.values,"*")
     assert_checktrue(mo_copy_matches(mo_display(r.values(j)),mo_display(r.values(j))));
     assert_checkfalse(mo_copy_matches(string(r.values(j)+10),mo_display(r.values(j))));
    end
    incomplete=t.wires;incomplete($,:)=[];failed=%f;
    try bad=mo_measure(lab,cfg,t,incomplete);catch failed=%t;end
    assert_checktrue(failed);rejected=rejected+1;
    trials=trials+1;readings=readings+size(r.values,"*");
   end
  end
  mprintf("PASS %s: 64 variantai, tikri sujungimai ir prietaisu rodmenys\n",lab);
 end
 for text=["1+2" "%nan" "Inf" "1e999" "abc" ""]
  assert_checktrue(isnan(bench_safe_number(text)));
 end
 result=struct("status","PASS","labs",12,"variants_per_lab",64,"trials",trials,"readings",readings,"incomplete_graph_rejections",rejected);
 if ~isdir(root+"tests/results") then mkdir(root+"tests/results");end
 mputl(toJSON(result),root+"tests/results/modelis.json");
 mprintf("PASS: LD1-LD12, 64 variantai, %d bandymu, %d rodmenu\n",trials,readings);exit(0);
catch
 [e,c,l,f]=lasterror();mprintf("FAIL %s:%d %s\n",f,l,strcat(e," "));exit(1);
end
