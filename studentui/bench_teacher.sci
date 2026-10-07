function bench_teacher_cancel()
    global BENCH_TEACHER_CANCEL;
    BENCH_TEACHER_CANCEL=%t;
endfunction

function [p,status]=bench_batch_call(command,source,destination)
    bench_core_require();
    a=ascii(source); b=ascii(destination);
    [p,status]=call("ld_batch",command,1,"i",a,2,"i",size(a,"*"),3,"i",b,4,"i",size(b,"*"),5,"i", ...
        "out",[1 4],6,"d",[1 1],7,"i");
endfunction

function bench_teacher()
    global BENCH_TEACHER_CANCEL;
    BENCH_TEACHER_CANCEL=%f;
    try bench_core_require(); catch messagebox(lasterror(),"Vertinimas","error"); return; end
    folder=uigetdir(bench_documents(),"Pasirinkite aplanką su studentų ataskaitomis");
    if isempty(folder) then return; end
    if stripblanks(folder)=="" then return; end
    destination=fullfile(folder,"Vertinimai-"+bench_id());
    f=figure("figure_name","Automatinis laboratorinių vertinimas","axes_size",[620 220],"menubar_visible","off","toolbar_visible","off","infobar_visible","off");
    h=uicontrol(f,"style","text","units","normalized","position",[.05 .45 .9 .4],"string","Skaitomas aplankas…","fontsize",16);
    cancel=uicontrol(f,"style","pushbutton","units","normalized","position",[.3 .12 .4 .22],"string","Sustabdyti","callback","bench_teacher_cancel()");
    try
        [p,status]=bench_batch_call(1,folder,destination);
        if status<0 then error("Nepavyko atverti aplanko arba sukurti rezultatų aplanko."); end
        while status==0
            if ~is_handle_valid(f) then BENCH_TEACHER_CANCEL=%t; end
            if BENCH_TEACHER_CANCEL then break; end
            [p,status]=bench_batch_call(2,folder,destination);
            if status<0 then error("Vertinimas sustabdytas dėl skaitymo ar rašymo klaidos. Jau išsaugoti rezultatai yra rezultatų aplanke."); end
            if is_handle_valid(h) then h.string=msprintf("Nuskaityta %d / %d. Įvertinta: %d. Patikslinti: %d.",p(1),p(2),p(3),p(4)); end
            sleep(1);
        end
        command=4; if BENCH_TEACHER_CANCEL then command=3; end
        [p,status]=bench_batch_call(command,folder,destination);
        if status<0 then error("Nepavyko užbaigti rezultatų įrašymo."); end
        if is_handle_valid(f) then delete(f); end
        title="Vertinimas baigtas";
        if BENCH_TEACHER_CANCEL then title="Vertinimas sustabdytas"; end
        bench_report_saved(fullfile(destination,"vertinimai.html"),title);
    catch
        if is_handle_valid(f) then delete(f); end
        messagebox(lasterror(),"Vertinimo klaida","error");
    end
endfunction
