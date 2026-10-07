function [edges, names] = ld1_component_edges()
    global LD1;
    edges = zeros(0,3);
    names = emptystr(0,1);

    if LD1.panel == "series" then
        edges($+1,:) = [ld1_term_index("R1_1") ld1_term_index("R1_2") LD1.actual.R1];
        names($+1,1) = "R1";
        edges($+1,:) = [ld1_term_index("VR1_1") ld1_term_index("VR1_2") LD1.actual.VR1];
        names($+1,1) = "VR1";
    else
        edges($+1,:) = [ld1_term_index("R2_1") ld1_term_index("R2_2") LD1.actual.R2];
        names($+1,1) = "R2";
        edges($+1,:) = [ld1_term_index("R3_1") ld1_term_index("R3_2") LD1.actual.R3];
        names($+1,1) = "R3";
        edges($+1,:) = [ld1_term_index("VR1_1") ld1_term_index("VR1_2") LD1.actual.VR1];
        names($+1,1) = "VR1";
    end

    if LD1.meterMode == "A" then
        if LD1.realistic then
            Rm = LD1.cfg.meter_R_A;
        else
            // Idealiame mokomajame režime ampermetro įtaka grandinei turi būti praktiškai nulinė.
            Rm = 1e-9;
        end
    else
        if LD1.realistic then
            Rm = LD1.cfg.meter_R_V;
        else
            // Idealiame mokomajame režime voltmetras grandinės neturi apkrauti.
            // Tai taip pat panaikina painų 9.999 V vietoje 10.000 V efektą.
            Rm = 1e12;
        end
    end
    edges($+1,:) = [ld1_term_index("M_P") ld1_term_index("M_N") Rm];
    names($+1,1) = "METER";
endfunction

function ni = ld1_node_of_root(uRoots, r)
    z = find(uRoots == r);
    if isempty(z) then ni = 0; else ni = z(1); end
endfunction

function out = ld1_solve_network()
    global LD1;
    out = struct("ok",%f,"short",%f,"message","", ..
                 "V",[],"roots",[],"edgeNames",[],"edgeCurrents",[]);

    if ~LD1.powerOn then
        out.message = "Maitinimo šaltinis išjungtas.";
        return;
    end

    [parent, roots] = ld1_wire_roots();
    out.roots = roots;

    iSP = ld1_term_index("SRC_P");
    iSN = ld1_term_index("SRC_N");
    rSP = roots(iSP);
    rSN = roots(iSN);
    if rSP == rSN then
        out.short = %t;
        out.message = "Trumpasis jungimas: +10 V ir 0 V gnybtai sujungti laidu.";
        return;
    end

    [edgesT, edgeNames] = ld1_component_edges();
    out.edgeNames = edgeNames;

    uRoots = unique(roots);
    nNodes = size(uRoots,"*");
    srcP = ld1_node_of_root(uRoots, rSP);
    srcN = ld1_node_of_root(uRoots, rSN);

    edges = zeros(size(edgesT,1),3);
    for k=1:size(edgesT,1)
        edges(k,1) = ld1_node_of_root(uRoots, roots(edgesT(k,1)));
        edges(k,2) = ld1_node_of_root(uRoots, roots(edgesT(k,2)));
        edges(k,3) = max(edgesT(k,3), 1e-9);
    end

    // Pasiekiamų mazgų paieška nuo šaltinio gnybtų.
    adj = zeros(nNodes,nNodes);
    for k=1:size(edges,1)
        a = edges(k,1); b = edges(k,2);
        if a <> b then
            adj(a,b)=1; adj(b,a)=1;
        end
    end
    reachable = zeros(1,nNodes)==1;
    queue = [srcP srcN];
    reachable(srcP)=%t; reachable(srcN)=%t;
    qh = 1;
    while qh <= size(queue,"*")
        a = queue(qh); qh = qh + 1;
        nb = find(adj(a,:)>0);
        for jj = 1:size(nb,"*")
            j = nb(jj);
            if ~reachable(j) then
                reachable(j)=%t;
                queue($+1)=j;
            end
        end
    end

    fixed = zeros(1,nNodes)==1;
    fixed(srcP)=%t; fixed(srcN)=%t;
    Vnode = %nan*ones(1,nNodes);
    Vnode(srcP)=LD1.cfg.E;
    Vnode(srcN)=0;

    global BENCH_CORE_READY;
    nativeCurrent=[];
    unknown = find(reachable & ~fixed);
    if BENCH_CORE_READY==%t then
        [Vnode,nativeCurrent,nativeStatus]=bench_cpp_dc(edges,reachable,srcP,srcN,LD1.cfg.E);
        if nativeStatus<>0 then
            out.message="C++ modelis: grandinė neapibrėžta arba sujungta netinkamai.";return;
        end
        unknown=[];
    end
    if ~isempty(unknown) then
        nu = size(unknown,"*");
        A = zeros(nu,nu);
        bvec = zeros(nu,1);
        for rr=1:nu
            n = unknown(rr);
            for k=1:size(edges,1)
                n1=edges(k,1); n2=edges(k,2); R=edges(k,3); G=1/R;
                if n1==n | n2==n then
                    if n1==n then other=n2; else other=n1; end
                    if other==n then continue; end
                    A(rr,rr)=A(rr,rr)+G;
                    if fixed(other) then
                        bvec(rr)=bvec(rr)+G*Vnode(other);
                    elseif reachable(other) then
                        cc=find(unknown==other);
                        if ~isempty(cc) then A(rr,cc(1))=A(rr,cc(1))-G; end
                    end
                end
            end
        end
        try
            sol=A\bvec;
            for rr=1:nu
                Vnode(unknown(rr))=sol(rr);
            end
        catch
            out.message="Grandinė turi neapibrėžtą (plūduriuojantį) mazgą arba netinkamą sujungimą.";
            return;
        end
    end

    Vterm=%nan*ones(1,size(LD1.term.ids,"*"));
    for i=1:size(LD1.term.ids,"*")
        ni=ld1_node_of_root(uRoots, roots(i));
        if reachable(ni) then Vterm(i)=Vnode(ni); end
    end
    out.V=Vterm;

    edgeI=%nan*ones(size(edges,1),1);
    for k=1:size(edges,1)
        i1=edgesT(k,1); i2=edgesT(k,2); R=max(edgesT(k,3),1e-9);
        if ~isnan(Vterm(i1)) & ~isnan(Vterm(i2)) then
            edgeI(k)=(Vterm(i1)-Vterm(i2))/R;
        end
    end
    if BENCH_CORE_READY==%t then edgeI=nativeCurrent; end
    out.edgeCurrents=edgeI;

    sourceCurrent = 0;
    anySourceEdge=%f;
    for k=1:size(edges,1)
        n1=edges(k,1); n2=edges(k,2);
        if n1==srcP & n2<>srcP then
            sourceCurrent=sourceCurrent + edgeI(k); anySourceEdge=%t;
        elseif n2==srcP & n1<>srcP then
            sourceCurrent=sourceCurrent - edgeI(k); anySourceEdge=%t;
        end
    end
    // Apsauga nuo akivaizdaus ampermetro prijungimo tiesiai prie šaltinio.
    // Riba priklauso nuo stende įvestų rezistorių, todėl maža teisėta R reikšmė
    // savaime nelaikoma trumpuoju jungimu.
    rmin=min([LD1.cfg.R1 LD1.cfg.R2 LD1.cfg.R3]);
    expectedScale=LD1.cfg.E/max(rmin,1e-6);
    shortLimit=max(1,10*expectedScale);
    if anySourceEdge & abs(sourceCurrent)>shortLimit then
        out.short=%t;
        out.message="Srovė neįprastai didelė. Patikrinkite, ar ampermetras neprijungtas lygiagrečiai šaltiniui.";
        return;
    end

    out.ok=%t;
    out.message="Grandinės modelis išspręstas.";
endfunction

function [value, unit, ok, msg, sol] = ld1_meter_read()
    global LD1;
    value=%nan; unit=""; ok=%f; msg=""; sol=struct("ok",%f);

    if ld1_terminal_wire_count("M_P")==0 | ld1_terminal_wire_count("M_N")==0 then
        msg="Multimetras neprijungtas: prijunkite abu jo gnybtus.";
        return;
    end

    sol=ld1_solve_network();
    if ~sol.ok then
        msg=sol.message;
        return;
    end

    if LD1.meterMode=="A" then
        unit="mA";
        k=find(sol.edgeNames=="METER");
        if isempty(k) | isnan(sol.edgeCurrents(k(1))) then
            msg="Ampermetras nėra elektriškai prijungtas prie maitinamos grandinės.";
            return;
        end
        value=abs(sol.edgeCurrents(k(1)))*1000;
    else
        unit="V";
        ip=ld1_term_index("M_P");
        in=ld1_term_index("M_N");
        if isnan(sol.V(ip)) | isnan(sol.V(in)) then
            msg="Voltmetro zondai nėra prijungti prie apibrėžtų grandinės mazgų.";
            return;
        end
        value=abs(sol.V(ip)-sol.V(in));
    end

    if LD1.realistic & ~isnan(value) then value=value*(1+ld1_random_relative(LD1.cfg.meter_noise)); end
    ok=%t;
    msg="Matavimas atliktas.";
endfunction

function [Rtot, I] = ld1_series_theory(VR)
    global LD1;
    Rtot=LD1.cfg.R1+VR;
    I=LD1.cfg.E/Rtot*1000;
endfunction

function Rtot = ld1_parallel_theory(VR)
    global LD1;
    branch2=LD1.cfg.R2+VR;
    Rtot=(LD1.cfg.R3*branch2)/(LD1.cfg.R3+branch2);
endfunction

function [I1,I2,It] = ld1_parallel_currents(VR)
    global LD1;
    I1=LD1.cfg.E/LD1.cfg.R3*1000;
    I2=LD1.cfg.E/(LD1.cfg.R2+VR)*1000;
    It=I1+I2;
endfunction

function ld1_update_actual_values()
    global LD1;
    if ~isfield(LD1,"actual") then LD1.actual=struct(); end
    if LD1.realistic then
        if ~isfield(LD1.actual,"R1") | LD1.actual.R1<=0 then
            LD1.actual.R1=LD1.cfg.R1*(1+ld1_random_relative(LD1.cfg.resistor_tolerance));
            LD1.actual.R2=LD1.cfg.R2*(1+ld1_random_relative(LD1.cfg.resistor_tolerance));
            LD1.actual.R3=LD1.cfg.R3*(1+ld1_random_relative(LD1.cfg.resistor_tolerance));
        end
    else
        LD1.actual.R1=LD1.cfg.R1;
        LD1.actual.R2=LD1.cfg.R2;
        LD1.actual.R3=LD1.cfg.R3;
    end
    LD1.actual.VR1=max(LD1.VR1, 1e-6);
endfunction
