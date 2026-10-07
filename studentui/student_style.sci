// Shared native Scilab styling for both student benches.
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
