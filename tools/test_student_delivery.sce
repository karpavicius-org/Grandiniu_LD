mode(-1);funcprot(0);
root=getenv("DELIVERY_ROOT")+"/";out=getenv("DELIVERY_OUT")+"/";
global LD1 LD2 LD3 LD4 LD5 LD6 LD7 LD8 LD9 LD10 LD11 LD12 BENCH_REPORT_WINDOW BENCH_LAST_REPORT DELIVERY_OPEN;
function values=x_mdialog(varargin)
    values=["17";"Patikra Žąsė";"TEST"];
endfunction
function n=messagebox(varargin)
    if varargin(2)<>"Jūsų priskirtos reikšmės" then error("Netikėtas dialogas: "+strcat(string(varargin(1))," "));end
    n=1;
endfunction
try
    screen=get(0,"screensize_px");expected=min([1280 720],max([320 240],screen(3:4)-[40 120]));
    for lab=1:12
        exec(root+"LD"+string(lab)+"/LD"+string(lab)+".sce",-1);
        select lab
        case 1 then f=LD1.fig;
        case 2 then f=LD2.ui.figure;
        case 3 then f=LD3.fig;
        case 4 then f=LD4.fig;
        case 5 then f=LD5.fig;
        case 6 then f=LD6.fig;
        case 7 then f=LD7.fig;
        case 8 then f=LD8.fig;
        case 9 then f=LD9.fig;
        case 10 then f=LD10.fig;
        case 11 then f=LD11.fig;
        case 12 then f=LD12.fig;
        end
        assert_checkequal(f.axes_size,expected);assert_checkequal(f.resize,"off");
        delete(f);
        mprintf("LD%d: vienodas pastovus langas PASS\n",lab);
    end
    for screen=[1024 768;900 600]'
        f=figure("dockable","off","resize","off","default_axes","off","menubar","none","toolbar","none","visible","off","axes_size",[1280 720]);
        f.infobar_visible="off";
        b=student_button(f,[.70 .10 .275 .08],"Toliau","");
        student_finish_window(f,screen');
        assert_checkequal(f.axes_size,screen'-[40 120]);
        assert_checkequal(student_size(b.parent),[1280 720]);
        assert_checkequal(b.parent.parent.scrollable,"on");assert_checkequal(b.position,[.70 .10 .275 .08]);
        delete(f);
    end
    exec(root+"tests/workflows.sci",-1);
    mprintf("DELIVERY: LD2 workflow start\n"); bench_ld2_workflow(17,root,%t); mprintf("DELIVERY: LD2 workflow PASS\n");
    mprintf("DELIVERY: LD3 workflow start\n"); bench_ld3_workflow(17,root,%t); mprintf("DELIVERY: LD3 workflow PASS\n");
    // Capture the two OS-opening callbacks without opening desktop apps in CI.
    function bench_open_local(path)
        global DELIVERY_OPEN;DELIVERY_OPEN=path;
    endfunction
    bench_report_saved(fullfile(bench_documents(),"patikra.html"),"Ataskaita išsaugota");
    buttons=0;
    for h=matrix(BENCH_REPORT_WINDOW.children,1,-1)
        if h.style<>"pushbutton" then continue;end
        buttons=buttons+1;
        if h.string=="Atverti ataskaitą" then execstr(h.callback);assert_checkequal(DELIVERY_OPEN,BENCH_LAST_REPORT);end
        if h.string=="Atverti ataskaitų aplanką" then execstr(h.callback);assert_checkequal(DELIVERY_OPEN,fileparts(BENCH_LAST_REPORT));end
    end
    assert_checkequal(buttons,3);delete(BENCH_REPORT_WINDOW);
    mputl("PASS: twelve fixed windows; small-screen scrolling; LD2/LD3 full GUI; report and folder buttons",out+"verdict.log");exit(0);
catch
    [messages,errno,errline,errfunc]=lasterror(%f);
    problem=strcat(messages," | ");
    detail="FAIL: "+problem+" [error="+string(errno)+", function="+errfunc+", line="+string(errline)+"]";
    mputl(detail,out+"verdict.log");disp(detail);exit(1);
end
