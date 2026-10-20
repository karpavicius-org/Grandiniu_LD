mode(-1);
root=get_absolute_file_path("AUTOMATINIS.sce")+"../";
try
    exec(root+"LD1/LD1_LOAD.sce",-1); exec(root+"LD2/LD2_LOAD.sce",-1); exec(root+"LD3/LD3_LOAD.sce",-1); exec(root+"LD4/LD4_LOAD.sce",-1); exec(root+"LD5/LD5_LOAD.sce",-1); exec(root+"LD6/LD6_LOAD.sce",-1); exec(root+"LD7/LD7_LOAD.sce",-1); exec(root+"LD8/LD8_LOAD.sce",-1); exec(root+"LD9/LD9_LOAD.sce",-1); exec(root+"LD10/LD10_LOAD.sce",-1); exec(root+"LD11/LD11_LOAD.sce",-1); exec(root+"LD12/LD12_LOAD.sce",-1);
    exec(root+"tests/workflows.sci",-1); exec(root+"bench_teacher.sci",-1);
    bench_core_require();
    global LD1 LD2 LD3 LD4 LD5 LD6 LD7 LD8 LD9 LD10 LD11 LD12;
    for bad=["1+2" "exec(""x"")" "%nan" "NaN" "Inf" "1e999" "1 2" "1.2.3" "" "0x10" "(2)"]
        assert_checktrue(isnan(ld1_parse_number(bad)));assert_checktrue(isnan(ld2_safe_number(bad)));
    end
    for valid=["1,25" "1.25" " 1.25 " "125d-2"]
        assert_checkequal(ld1_parse_number(valid),1.25);assert_checkequal(ld2_safe_number(valid),1.25);
    end
    folder=bench_documents();
    for n=1:64
        cfg=ld1_variant_config(n);
        LD1=struct("cfg",cfg,"student",student_profile(n,"Patikra Žąsė "+string(n),"TEST-DC","LD1"));
        ld1_init_state(); ld1_init_terminals();
        LD1.stepQ(2,1)=msprintf("%.12g",cfg.R1+1000); LD1.stepQ(2,2)=msprintf("%.12g",10000/(cfg.R1+1000));
        LD1.stepQ(4,1)=msprintf("%.12g",cfg.R1+500); LD1.stepQ(4,2)=msprintf("%.12g",10000/(cfg.R1+500));
        LD1.stepQ(6,1)=msprintf("%.12g",cfg.R3*(cfg.R2+1000)/(cfg.R3+cfg.R2+1000));
        LD1.stepQ(8,1)=msprintf("%.12g",10000/cfg.R3); LD1.stepQ(8,2)=msprintf("%.12g",10000/cfg.R2);
        LD1.stepQ(8,3)=msprintf("%.12g",10000/cfg.R2+10000/cfg.R3);
        LD1.stepType(1)=1; LD1.stepType(5)=2; LD1.stepYesNo([3 4 6 8])=1; LD1.stepYesNo(7)=2;
        LD1.powerOn=%t; LD1.wires=ld1_series_canonical_wires();LD1.meterMode="A";
        LD1.report_wires(1)=LD1.wires; LD1.report_meter(1)="A";
        for step=[3 4]
            LD1.VR1=1000; if step==4 then LD1.VR1=500; end
            ld1_update_actual_values(); [v,u,ok,msg]=ld1_meter_read();assert_checktrue(ok);LD1.stepMeas(step)=v;
        end
        LD1.panel="parallel"; LD1.wires=ld1_parallel_voltage_canonical_wires(); LD1.meterMode="V";
        LD1.report_wires(5)=LD1.wires; LD1.report_meter(5)="V";
        for step=[6 7]
            LD1.VR1=1000;if step==7 then LD1.VR1=500;end
            ld1_update_actual_values();[v,u,ok,msg]=ld1_meter_read();assert_checktrue(ok);LD1.stepMeas(step)=v;
        end
        LD1.VR1=0; LD1.meterMode="A"; LD1.wires=ld1_parallel_kcl_canonical_wires();ld1_update_actual_values();
        [v,u,ok,msg]=ld1_meter_read();assert_checktrue(ok);LD1.stepMeas(8)=v;
        bench_export_report("LD1",folder);
        bench_ld2_workflow(n,root,%f);
        LD2.state.student.name="Patikra Žąsė "+string(n);LD2.state.student.group="TEST-AC";
        bench_export_report("LD2",folder);
        bench_ld3_workflow(n,root,%f);
        LD3.student.name="Patikra Žąsė "+string(n);LD3.student.group="TEST-DC";
        bench_ld4_workflow(n,root,%f);
        LD4.student.name="Patikra Žąsė "+string(n);LD4.student.group="TEST-DC";
        bench_export_report("LD4",folder);
        bench_ld5_workflow(n,root,%f);
        LD5.student.name="Patikra Žąsė "+string(n);LD5.student.group="TEST-DC";
        bench_export_report("LD5",folder);
        bench_ld6_workflow(n,root,%f);
        LD6.student.name="Patikra Žąsė "+string(n);LD6.student.group="TEST-DC";
        bench_export_report("LD6",folder);
        bench_ld7_workflow(n,root,%f);
        LD7.student.name="Patikra Žąsė "+string(n);LD7.student.group="TEST-DC";
        bench_export_report("LD7",folder);
        bench_ld8_workflow(n,root,%f);
        LD8.student.name="Patikra Žąsė "+string(n);LD8.student.group="TEST-DC";
        bench_export_report("LD8",folder);
        bench_ld9_workflow(n,root,%f);
        LD9.student.name="Patikra Žąsė "+string(n);LD9.student.group="TEST-AC";
        bench_export_report("LD9",folder);
        bench_ld10_workflow(n,root,%f);
        LD10.student.name="Patikra Žąsė "+string(n);LD10.student.group="TEST-AC";
        bench_export_report("LD10",folder);
        bench_ld11_workflow(n,root,%f);
        LD11.student.name="Patikra Žąsė "+string(n);LD11.student.group="TEST-AC";
        bench_export_report("LD11",folder);
        bench_ld12_workflow(n,root,%f);
        LD12.student.name="Patikra Žąsė "+string(n);LD12.student.group="TEST-3PH";
        bench_export_report("LD12",folder);
        bench_export_report("LD3",folder);
        // Independent Scilab formula vs actual C++ MNA backend.
        for f=[0 40 1000 5000 10000]
            cfg=LD2.cfg; ref=ld2_reference_rlc_values(5,f,cfg.R13,cfg.L3,cfg.C4);v=bench_cpp_ac(3,5,f,cfg.R13,cfg.L3,cfg.C4);
            assert_checkalmostequal(v([4 5 6 7 8 9]),[ref.I ref.UR ref.UL ref.UC ref.ULC ref.P],1e-9,1e-9);
        end
        mprintf("AUTOMATIC V%02d: LD1 + LD2 + LD3 + LD4 HTML exported\n",n);
    end
    // Native atomic storage preserves raw text and binary local snapshots.
    LD1.stepQ(2,1)="1330,012345";
    draft=bench_save_snapshot("LD1");saved=bench_read_snapshot(draft,"LD1");
    assert_checkequal(saved.state.stepQ,LD1.stepQ);
    LD2.state.answers_text(4,1)="123,456";
    draft=bench_save_snapshot("LD2");saved=bench_read_snapshot(draft,"LD2");
    before=LD2.state.answers_text;LD2.state.answers_text(4,1)="erased";
    bench_restore_snapshot(saved);assert_checkequal(LD2.state.answers_text,before);
    assert_checkfalse(LD2.state.power);
    // A second write to the same submission path fails and preserves bytes.
    sentinel=fullfile(TMPDIR,"ld-write-"+bench_id()+".txt");bench_write_new(sentinel,"original");
    rejected=%f;try bench_write_new(sentinel,"changed");catch rejected=%t;end
    assert_checktrue(rejected);assert_checkequal(mgetl(sentinel),"original");mdelete(sentinel);
    // Snapshot files live outside the submitted report inventory.
    rmdir(fullfile(folder,"Juodrasciai"),"s");
    // Raw erroneous text, blanks and HTML delimiters survive export unchanged.
    LD2.state.answers_text(4,1)="999999";LD2.state.answers_text(4,2)="";
    LD2.state.student.name="Žąsė </script><script>alert(1)</script>";
    path=bench_export_report("LD2",folder);
    body=strcat(mgetl(path),ascii(10));
    assert_checkfalse(~isempty(strindex(body,"<script>alert(1)</script>")));
    assert_checktrue(~isempty(strindex(body,"999999")));
    output=fullfile(folder,"CFFI-vertinimas");
    [p,status]=bench_batch_call(1,folder,output);assert_checktrue(status>=0);
    while status==0
        [p,status]=bench_batch_call(2,folder,output);assert_checktrue(status>=0);
    end
    [p,status]=bench_batch_call(4,folder,output);assert_checkequal(status,1);
    assert_checkequal(p(1),769);assert_checkequal(p(3),769);assert_checkequal(p(4),0);
    mprintf("AUTOMATIC_PASS: 768 full reports + one incorrect LD2-2 submission, C++ CFFI folder grading, UTF-8 HTML\n");
    exit(0);
catch
    mprintf("AUTOMATIC_FAIL: %s\n",strcat(lasterror()," | "));exit(1);
end
