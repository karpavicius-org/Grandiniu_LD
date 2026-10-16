// All64 complete simulator workflows; independent phasor checks, no GUI injection claim.
mode(-1);funcprot(0);global LD12;
root=get_absolute_file_path("test_ld12_headless.sce")+"../studentui/";
try
    exec(root+"LD12/LD12_LOAD.sce",-1);exec(root+"tests/workflows.sci",-1);
    for number=1:64
        bench_ld12_workflow(number,root,%f);
        assert_checktrue(and(LD12.done));assert_checkequal(size(LD12.journal,1),2);
        report=bench_report_data("LD12");assert_checkequal(report.variant,number);
        assert_checkequal(report.rubric_version,"LD12-1");assert_checkequal(length(report.observations),2);
        cfg=LD12.cfg;
        phases=cfg.Ul/sqrt(3)*exp(%i*[0 -2*%pi/3 2*%pi/3]);
        branchD=(phases-phases([2 3 1]))/cfg.R;
        lineD=branchD-branchD([3 1 2]);
        powerY=sum(real(phases.*conj(phases/cfg.R)));
        powerD=sum(real((phases-phases([2 3 1])).*conj(branchD)));
        for mode=1:2
            LD12.wireMode=mode;LD12.wires=ld12_canonical_wires(mode);LD12.powerOn=%t;LD12.switchOn=%t;
            for branch=1:3
                LD12.phase=branch;[u,i,ok,message]=ld12_measure_values();assert_checktrue(ok);
                if mode==1 then wantU=abs(phases(branch));wantI=wantU/cfg.R*1000;
                else wantU=abs(phases(branch)-phases(modulo(branch,3)+1));wantI=abs(branchD(branch))*1000;end
                assert_checkalmostequal(u,wantU,1e-10,1e-8);assert_checkalmostequal(i,wantI,1e-10,1e-8);
            end
        end
        assert_checkalmostequal(ld12_line_current(),abs(lineD(1))*1000,1e-10,1e-8);
        assert_checkalmostequal(powerD,3*powerY,1e-10,1e-8);
    end
    mprintf("LD12_ALL64_PASS: 64 complete workflows,384 stages,128 recorded measurements; all3 branches in both modes checked with independent phasors; LD12-1 reports preserved\n");exit(0);
catch
    mprintf("LD12_ALL64_FAIL: %s\n",strcat(lasterror()," | "));exit(1);
end
