// Shared native Scilab styling for both student benches.
// Opt-in guidance. Looking at help never changes an experiment. The explicit
// action button runs the existing bench callbacks, with a separate student
// click required for a displayed answer and for advancing to another stage.

function found=student_guide_find(parent,tag)
    found=[];
    if tag=="" | ~is_handle_valid(parent) then return; end
    if parent.type=="uicontrol" then
        if parent.tag==tag then found=parent;return;end
    end
    for child=matrix(parent.children,1,-1)
        if child.type<>"uicontrol" then continue;end
        found=student_guide_find(child,tag);
        if found<>[] then return;end
    end
endfunction

function student_guide_unfocus(lab)
    global STUDENT_GUIDE_FOCUS;
    if typeof(STUDENT_GUIDE_FOCUS)<>"st" then STUDENT_GUIDE_FOCUS=struct();return;end
    if ~isfield(STUDENT_GUIDE_FOCUS,lab) then return;end
    old=STUDENT_GUIDE_FOCUS(lab);
    if old.handle==[] then return;end
    if is_handle_valid(old.handle) then
        // A redraw may already have applied a new selected-mode colour. Keep
        // it; restore the saved colour only while our own yellow is present.
        if and(abs(old.handle.backgroundcolor-[1 .86 .20])<1d-10) then
            old.handle.backgroundcolor=old.background;
            old.handle.foregroundcolor=old.foreground;
        end
    end
    STUDENT_GUIDE_FOCUS(lab)=struct("handle",[]);
endfunction

function h=student_guide_focus(lab,fig,tag,enabled)
    h=[];
    if getscilabmode()=="NWNI" then return;end
    student_guide_unfocus(lab);
    if ~enabled | tag=="" then return;end
    h=student_guide_find(fig,tag);
    if h==[] then return;end
    if h.visible<>"on" | h.enable<>"on" then h=[];return;end
    global STUDENT_GUIDE_FOCUS;
    STUDENT_GUIDE_FOCUS(lab)=struct("handle",h,"background",h.backgroundcolor,"foreground",h.foregroundcolor);
    h.backgroundcolor=[1 .86 .20];h.foregroundcolor=[.12 .12 .08];
endfunction

function student_guide_action_refresh(lab,fig,tag,value,enabled)
    if getscilabmode()=="NWNI" then return;end
    global STUDENT_GUIDE_ACTIONS STUDENT_GUIDE_BUSY;
    if typeof(STUDENT_GUIDE_ACTIONS)<>"st" then STUDENT_GUIDE_ACTIONS=struct();end
    if typeof(STUDENT_GUIDE_BUSY)<>"st" then STUDENT_GUIDE_BUSY=struct();end
    STUDENT_GUIDE_ACTIONS(lab)=struct("fig",fig,"enabled",enabled);
    h=findobj("tag",lab+"-guide-action");
    if h==[] then return;end
    h.enable="off";
    busy=%f;if isfield(STUDENT_GUIDE_BUSY,lab) then busy=STUDENT_GUIDE_BUSY(lab);end
    if busy then h.string="Atliekamas jūsų pasirinktas bandymas…";return;end
    if ~enabled then return;end
    target=student_guide_find(fig,tag);
    if target==[] then h.string="Atlikite aukščiau paaiškintą veiksmą stende";return;end
    if target.visible<>"on" | target.enable<>"on" then
        h.string="Atlikite aukščiau paaiškintą veiksmą stende";return;
    end
    if tag==lab+"_PRIMARY" | tag==lab+"_BACK" then
        h.string="Tęskite geltonu mygtuku stende";return;
    end
    if target.style=="edit" then
        if value=="" then h.string="Savo atsakymą įrašykite geltoname lauke";return;end
        h.string="Įrašyti parodytą reikšmę: "+value;
    elseif target.style=="popupmenu" then
        if ~or(value==["1" "2"]) then h.string="Pasirinkite išvadą geltoname sąraše";return;end
        h.string="Pasirinkti parodytą išvadą";
    else h.string="Paruošti ir atlikti šio etapo bandymą";end
    h.enable="on";
endfunction

function student_guide_action(lab)
    global LD3 LD4 LD5 LD6 LD7 LD8 LD9 LD10 LD11 LD12;
    global STUDENT_GUIDE_ACTIONS STUDENT_GUIDE_BUSY;
    if ~or(lab==["LD3" "LD4" "LD5" "LD6" "LD7" "LD8" "LD9" "LD10" "LD11" "LD12"]) then return;end
    if typeof(STUDENT_GUIDE_ACTIONS)<>"st" then return;end
    if ~isfield(STUDENT_GUIDE_ACTIONS,lab) then return;end
    entry=STUDENT_GUIDE_ACTIONS(lab);
    if ~entry.enabled | ~is_handle_valid(entry.fig) then return;end
    if isfield(STUDENT_GUIDE_BUSY,lab) then if STUDENT_GUIDE_BUSY(lab) then return;end;end
    name=convstr(lab,"l");
    execstr("stage="+lab+".step;");
    STUDENT_GUIDE_BUSY(lab)=%t;
    failure="";
    try
        // Stop before a stage transition or an answer. There is no hidden
        // progression and no synthetic measurement appended to a journal.
        for count=1:160
            execstr("currentStage="+lab+".step;");
            if currentStage<>stage then break;end
            execstr("[lines,tag,value]="+name+"_guide_next();");
            if tag=="" | tag==lab+"_PRIMARY" | tag==lab+"_BACK" then break;end
            target=student_guide_find(entry.fig,tag);
            if target==[] then break;end
            if target.enable<>"on" | target.visible<>"on" then break;end
            cb=target.callback;
            if cb=="" then break;end
            if target.style=="edit" then
                // Only an explicit click starting on this displayed answer
                // may copy it. A physical batch never fills the next answer.
                if count==1 & value<>"" then target.string=value;execstr(cb);end
                break;
            end
            if target.style=="popupmenu" then
                if count==1 & or(value==["1" "2"]) then
                    choice=2;if value=="2" then choice=3;end
                    target.value=choice;execstr(cb);
                end
                break;
            end
            if target.style<>"pushbutton" then break;end
            execstr("beforeWires="+lab+".wires; beforePending="+lab+".pending; beforeJournal="+lab+".journal;");
            execstr(cb);
            execstr("[nextLines,nextTag,nextValue]="+name+"_guide_next();");
            if nextTag==tag then
                // The next wire may start at the very contact just clicked.
                // An unchanged tag is not an unchanged experiment.
                execstr("progress=~isequal(beforeWires,"+lab+".wires) | beforePending<>"+lab+".pending | ~isequal(beforeJournal,"+lab+".journal);");
                if ~progress then break;end
            end
        end
    catch
        failure=lasterror();
    end
    STUDENT_GUIDE_BUSY(lab)=%f;
    execstr(name+"_guide_refresh();");
    if failure<>"" then
        content=findobj("tag",lab+"-guide-content");
        if content<>[] then content.string=["Veiksmas sustojo. Duomenys išliko; tęskite pagal geltoną žymėjimą.";failure;content.string];end
    end
endfunction

function student_guide_hide(lab)
    if getscilabmode()=="NWNI" then return; end
    if or(lab==["LD3" "LD4" "LD5" "LD6" "LD7" "LD8" "LD9" "LD10" "LD11" "LD12"]) then
        student_guide_unfocus(lab);
        global STUDENT_GUIDE_ACTIONS;
        if typeof(STUDENT_GUIDE_ACTIONS)=="st" then
            if isfield(STUDENT_GUIDE_ACTIONS,lab) then STUDENT_GUIDE_ACTIONS(lab).enabled=%f;end
        end
    end
    windows=findobj("tag",lab+"-guide-window");
    if windows<>[] then delete(windows); end
endfunction

function out=student_guide_wrap(lines,width)
    out=emptystr(0,1);
    for line=matrix(lines,1,-1)
        words=tokens(line," "); current="";
        for k=1:size(words,"*")
            if length(current)+length(words(k))+1>width & current<>"" then
                out($+1,1)=current;current="";
            end
            if current<>"" then current=current+" ";end
            current=current+words(k);
        end
        out($+1,1)=current;
    end
endfunction

function student_guide_update(lab,title,lines,enabled)
    if getscilabmode()=="NWNI" then return; end
    if ~or(lab==["LD1" "LD2" "LD3" "LD4" "LD5" "LD6" "LD7" "LD8" "LD9" "LD10" "LD11" "LD12"]) then return; end
    if ~enabled then student_guide_hide(lab); return; end
    windows=findobj("tag",lab+"-guide-window");
    if windows==[] then
        s=get(0,"screensize_px");
        sz=min([720 720],max([360 280],s(3:4)-[60 120]));
        side=s(3)-1320;
        if side>=400 then sz(1)=min(720,side);end
        text=student_guide_wrap(lines,max(30,floor(sz(1)*.92/8.5)));
        f=figure("default_axes","off","dockable","off","menubar","none", ...
            "toolbar","none","axes_size",sz,"figure_name",lab+" · Pagalba žingsnis po žingsnio", ...
            "tag",lab+"-guide-window","resize","on");
        f.infobar_visible="off";
        if side>=400 then f.figure_position=[1300 10];end
        f.closerequestfcn=convstr(lab,"l")+"_guide_close()";
        uicontrol(f,"style","text","units","normalized","position",[.04 .86 .92 .11], ...
            "tag",lab+"-guide-title","string",title,"fontname","SansSerif", ...
            "fontunits","pixels","fontsize",19,"fontweight","bold", ...
            "horizontalalignment","left","backgroundcolor",[.96 .98 .97]);
        interactive=or(lab==["LD3" "LD4" "LD5" "LD6" "LD7" "LD8" "LD9" "LD10" "LD11" "LD12"]);
        contentPosition=[.04 .13 .92 .71];
        if interactive then contentPosition=[.04 .22 .92 .62];end
        uicontrol(f,"style","listbox","units","normalized","position",contentPosition, ...
            "tag",lab+"-guide-content","string",text, ...
            "max",2,"min",0,"enable","on","fontname","SansSerif", ...
            "fontunits","pixels","fontsize",16,"horizontalalignment","left", ...
            "backgroundcolor",[1 1 1]);
        if interactive then
            uicontrol(f,"style","pushbutton","units","normalized","position",[.04 .13 .92 .07], ...
                "string","Atlikti parodytą veiksmą","tag",lab+"-guide-action", ...
                "callback","student_guide_action("""+lab+""")","fontunits","pixels","fontsize",15, ...
                "backgroundcolor",[1 .86 .20],"foregroundcolor",[.12 .12 .08]);
        end
        uicontrol(f,"style","pushbutton","units","normalized","position",[.50 .03 .46 .07], ...
            "string","Baigti vedimą","tag",lab+"-guide-close", ...
            "callback",convstr(lab,"l")+"_guide_close()","fontunits","pixels","fontsize",15);
        uicontrol(f,"style","text","units","normalized","position",[.04 .025 .44 .08], ...
            "string","Veiksmus atlikite stendo lange. Pagalba atsinaujina po veiksmo.", ...
            "fontunits","pixels","fontsize",12,"horizontalalignment","left");
    else
        sz=windows(1).axes_size;
        text=student_guide_wrap(lines,max(30,floor(sz(1)*.92/8.5)));
        h=findobj("tag",lab+"-guide-title"); h.string=title;
        h=findobj("tag",lab+"-guide-content");
        if ~isequal(h.string,text) then h.string=text; end
    end
endfunction

function student_finish_window(f,screen,design)
    // One fixed canvas in every lab. A smaller screen scrolls the canvas;
    // stage transitions never move controls or shrink contact targets.
    if argn(2)<2 then s=get(0,"screensize_px"); screen=s(3:4); end
    f.resize="off";
    if argn(2)<3 then design=[1280 720]; end
    available=max([320 240],screen-[40 120]);
    viewport=min(design,available); f.figure_position=[10 10];
    if or(viewport<design) then
        roots=f.children;
        f.axes_size=viewport;
        scroll=uicontrol(f,"style","frame","scrollable",%t,"units","normalized","position",[0 0 1 1],"tag","student-scroll");
        canvas=uicontrol(scroll,"style","frame","units","pixels","position",[0 0 design],"tag","student-canvas");
        for h=matrix(roots,1,-1)
            if h.type=="uicontrol" then r=h.position;h.parent=canvas;h.position=r;end
        end
        student_reflow(canvas,design);
    else
        f.axes_size=design; student_reflow(f,design);
    end
endfunction

function student_reflow(parent,sz)
    for h=matrix(parent.children,1,-1)
        if h.type<>"uicontrol" then continue; end
        r=h.position;
        if h.units=="normalized" then
            h.units="pixels";h.position=r.*[sz sz];h.units="normalized";h.position=r;
            child_size=r(3:4).*sz;
        else child_size=r(3:4); end
        student_reflow(h,child_size);
    end
endfunction

function h=student_text(p,pos,txt,fs,bold,bg)
    if argn(2)<6 then bg=[1 1 1]; end
    if size(strindex(txt,ascii(10)),"*")>0 then txt="<html>"+strsubst(txt,ascii(10),"<br>")+"</html>"; end
    h=uicontrol(p,"style","text","units","normalized","position",pos, ...
        "string",strsubst(txt,ascii(10),"<br>"),"fontname","DejaVu Sans","fontunits","pixels","fontsize",fs, ...
        "horizontalalignment","left","verticalalignment","middle", ...
        "backgroundcolor",bg,"foregroundcolor",[0.13 0.19 0.23]);
    if bold then h.fontweight="bold"; end
endfunction

// Logical client pixels, including normalized nested frames. This is also the
// coordinate system exported by the internal geometry audit.
function sz=student_size(h)
    if h.type=="Figure" then sz=h.axes_size; return; end
    p=h.position;
    if h.units=="normalized" then sz=p(3:4).*student_size(h.parent);
    else sz=p(3:4); end
endfunction

function h=student_terminal(p,xy,label,code,cb,tip,bg)
    sz=p.user_data.pixel_size; wh=[36 40]./sz;
    h=uicontrol(p,"style","pushbutton","units","normalized", ...
        "position",[xy-wh/2 wh],"string","<html><center>"+label+"<br>"+code+"</center></html>", ...
        "fontname","DejaVu Sans","fontunits","pixels","fontsize",12, ...
        "margins",[0 0 0 0],"backgroundcolor",bg,"foregroundcolor",[1 1 1], ...
        "tag",code,"tooltipstring",tip,"callback",cb);
endfunction

function hh=student_wire(p,a,b,col,tag)
    if argn(2)<5 then tag="wire"; end
    hh=[];
    if norm(a-b)<1e-9 then return; end
    if tag=="wire" & typeof(p.user_data)=="st" then
        if isfield(p.user_data,"collect") then
            if p.user_data.collect then
                data=p.user_data; data.segments($+1,:)=[a b col]; p.user_data=data; return;
            end
        end
    end
    sz=[];
    if typeof(p.user_data)=="st" then
        if isfield(p.user_data,"pixel_size") then sz=p.user_data.pixel_size; end
    end
    if sz==[] then sz=student_size(p); end
    t=[3 3]./sz;
    horizontal=abs(a(2)-b(2))<1e-8;
    if ~horizontal & abs(a(1)-b(1))>1e-8 then error("Laido atkarpa turi būti horizontali arba vertikali."); end
    axis=1; other=2; if ~horizontal then axis=2; other=1; end
    spans=[min(a(axis),b(axis)) max(a(axis),b(axis))];
    // Clip every segment against the actual contact rectangles. This also
    // handles a bend inside a terminal and keeps bus lines off contact labels,
    // independently of Swing stacking order on Windows or Linux.
    if typeof(p.user_data)=="st" then
        if isfield(p.user_data,"ports") then
            ports=p.user_data.ports;
            for k=1:size(ports,1)
                half=(ports(k,3:4)/2+[1 1])./sz; center=ports(k,1:2);
                if abs(a(other)-center(other))>half(other) then continue; end
                lo=center(axis)-half(axis); hi=center(axis)+half(axis); next=[];
                for j=1:size(spans,1)
                    l=spans(j,1); r=spans(j,2);
                    if r<=lo | l>=hi then next($+1,:)=[l r];
                    else
                        if l<lo then next($+1,:)=[l lo]; end
                        if r>hi then next($+1,:)=[hi r]; end
                    end
                end
                spans=next;
            end
        end
    end
    for j=1:size(spans,1)
        lo=spans(j,1); hi=spans(j,2);
        if horizontal then pos=[lo a(2)-t(2)/2 hi-lo t(2)];
        else pos=[a(1)-t(1)/2 lo t(1) hi-lo]; end
        if hi-lo<1e-8 then continue; end
        hh($+1)=uicontrol(p,"style","text","units","normalized","position",pos, ...
            "string","","backgroundcolor",col,"tag",tag);
    end
    hh=matrix(hh,1,-1);
endfunction

function student_begin_wires(p)
    data=p.user_data; data.pixel_size=student_size(p); data.collect=%t; data.segments=[]; p.user_data=data;
endfunction

function hh=student_end_wires(p)
    data=p.user_data; data.collect=%f; p.user_data=data; seg=data.segments;
    sz=student_size(p); gap=5/sz(2); hh=[];
    // Calculate all intersections before painting, so the result does not
    // depend on connection order. A 10 px gap means no electrical junction.
    for k=1:size(seg,1)
        a=seg(k,1:2); b=seg(k,3:4); col=seg(k,5:7);
        if abs(a(2)-b(2))<1e-8 then
            hh=[hh student_wire(p,a,b,col)]; continue;
        end
        lo=min(a(2),b(2)); hi=max(a(2),b(2)); cuts=[];
        for j=1:size(seg,1)
            h1=seg(j,1:2); h2=seg(j,3:4);
            if abs(h1(2)-h2(2))>1e-8 then continue; end
            if a(1)>min(h1(1),h2(1))+1e-8 & a(1)<max(h1(1),h2(1))-1e-8 & h1(2)>lo+1e-8 & h1(2)<hi-1e-8 then
                cuts($+1)=h1(2);
            end
        end
        cuts=gsort(cuts,"g","i"); cur=lo;
        for yy=matrix(cuts,1,-1)
            if yy-gap>cur then hh=[hh student_wire(p,[a(1) cur],[a(1) yy-gap],col)]; end
            cur=max(cur,yy+gap);
        end
        if cur<hi then hh=[hh student_wire(p,[a(1) cur],[a(1) hi],col)]; end
    end
endfunction

function h=student_button(p,pos,txt,cb,primary)
    if argn(2)<5 then primary=%f; end
    bg=[0.94 0.96 0.96]; fg=[0.12 0.25 0.28];
    if primary then bg=[0.08 0.39 0.37]; fg=[1 1 1]; end
    h=uicontrol(p,"style","pushbutton","units","normalized","position",pos, ...
        "string",txt,"callback",cb,"fontname","DejaVu Sans","fontunits","pixels", ...
        "fontsize",14,"fontweight","bold","margins",[0 0 0 0],"backgroundcolor",bg,"foregroundcolor",fg);
endfunction

function h=student_frame(p,pos,bg)
    if argn(2)<3 then bg=[1 1 1]; end
    h=uicontrol(p,"style","frame","units","normalized","position",pos, ...
        "backgroundcolor",bg,"relief","flat");
endfunction

function txt=student_wrap(lines,width)
    out=emptystr(0,1);
    for line=matrix(lines,1,-1)
        words=tokens(line," "); current="";
        for k=1:size(words,"*")
            if length(current)+length(words(k))+1>width & current<>"" then
                out($+1,1)=current; current="";
            end
            if current<>"" then current=current+" "; end
            current=current+words(k);
        end
        out($+1,1)=current;
    end
    txt="<html>"+strcat(out,"<br>")+"</html>";
endfunction
