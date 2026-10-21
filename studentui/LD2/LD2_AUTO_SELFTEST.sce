mode(-1);funcprot(0);
try
    exec(get_absolute_file_path("LD2_AUTO_SELFTEST.sce")+"LD2_LOAD.sce",-1);
    bench_core_require();
    [ok,log]=ld2_selftest();disp(log);
    if ~ok then exit(1);end
    exit(0);
catch
    disp(lasterror());exit(1);
end
