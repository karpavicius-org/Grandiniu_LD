// Purpose-specific report illustrations; all quantities come from the saved experiment.
function h=mo6_late_svg(title,w,height)
    h="<svg viewBox=""0 0 "+string(w)+" "+string(height)+""" role=""img"" aria-label="""+mo_html(title)+"""><title>"+mo_html(title)+"</title>";
endfunction
function h=mo6_late_text(x,y,text,sizePx,color,anchor)
    if argn(2)<6 then anchor="start";end
    h=msprintf("<text x=""%.2f"" y=""%.2f"" font-size=""%g"" style=""fill:%s"" text-anchor=""%s"">",x,y,sizePx,color,anchor)+mo_html(text)+"</text>";
endfunction
function h=mo6_late_arrow(id,x1,y1,x2,y2,color,tip)
    h="<defs><marker id="""+id+""" markerWidth=""7"" markerHeight=""7"" refX=""6"" refY=""3"" orient=""auto""><path d=""M0,0 L0,6 L6,3 z"" fill="""+color+"""/></marker></defs>";
    if abs(x2-x1)+abs(y2-y1)<1d-7 then return;end
    h=h+msprintf("<line x1=""%.2f"" y1=""%.2f"" x2=""%.2f"" y2=""%.2f"" stroke=""%s"" stroke-width=""3"" marker-end=""url(#%s)"" tabindex=""0"" data-tip=""",x1,y1,x2,y2,color,id)+mo_html(tip)+"""><title>"+mo_html(tip)+"</title></line>";
endfunction
function h=mo6_late_readings(names,values,unit)
    h="<div style=""display:flex;flex-wrap:wrap;gap:8px 20px;margin:12px 22px""><span>";
    for j=1:size(values,"*")
        if j>1 then h=h+"</span><span>";end
        h=h+"<strong>"+mo_html(names(j))+"</strong> "+mo_html(mo_display(values(j))+" "+unit);
    end
    h=h+"</span></div>";
endfunction
function h=mo6_late_ld7(cfg,r)
    u=mo5_values(r,1:5,"U");i=mo5_values(r,1:5,"I");p=u.*i;[best,k]=max(p);load=r(k).trial.x;
    h="<section class=""section"" data-purpose=""LD7""><h2>Kuri apkrova gavo daugiausia galios?</h2><article class=""chart"">";
    h=h+mo6_late_svg("Šaltinis ir daugiausia galios gavusi apkrova",980,205);
    h=h+"<path d=""M80 75 H215 M365 75 H530 M690 75 H805 V150 H80 V75"" fill=""none"" stroke=""#8fa99e"" stroke-width=""2""/><circle cx=""80"" cy=""110"" r=""28"" fill=""#edf5f1"" stroke=""#77998b""/><rect x=""215"" y=""52"" width=""150"" height=""46"" rx=""5"" fill=""#f3f5f2"" stroke=""#a1b3a8""/><rect x=""530"" y=""45"" width=""160"" height=""60"" rx=""6"" fill=""#ddf1e7"" stroke=""#087866"" stroke-width=""2""/>";
    h=h+mo6_late_text(80,116,"E",18,"#234139","middle")+mo6_late_text(290,79,"r = "+mo_report_number(cfg.r)+" Ω",16,"#234139","middle")+mo6_late_text(610,70,"Apkrova R",14,"#087866","middle")+mo6_late_text(610,92,mo_report_number(load)+" Ω",18,"#087866","middle");
    h=h+mo6_late_arrow("ld7-best-current",390,75,490,75,"#087866","I = "+mo_display(i(k))+" mA");
    h=h+mo6_late_text(440,57,"I = "+mo_display(i(k))+" mA",14,"#087866","middle")+mo6_late_text(800,75,"Didžiausia galia",15,"#234139")+mo6_late_text(800,106,mo_display(best)+" mW",23,"#087866");
    h=h+mo6_late_text(80,180,mo_report_number(cfg.E)+" V",15,"#234139","middle")+mo6_late_text(610,180,"U = "+mo_display(u(k))+" V",15,"#234139","middle")+"</svg><p class=""chart-note"">Iš penkių pamatuotų apkrovų didžiausią galią gavo "+string(k)+" bandymo apkrova. Palyginkite jos varžą su šaltinio vidine varža r.</p></article></section>";
endfunction
function h=mo6_late_rbox(x,y,label)
    h=msprintf("<rect x=""%.1f"" y=""%.1f"" width=""72"" height=""28"" rx=""3"" fill=""#eff6f2"" stroke=""#8ca89a""/>",x-36,y-14)+mo6_late_text(x,y+5,label,15,"#234139","middle");
endfunction
function h=mo6_late_ld8(cfg,r)
    names=["Nuosekliai";"Lygiagrečiai";"Mišriai"];
    h="<section class=""section"" data-purpose=""LD8""><h2>Kaip pasidalijo įtampa ir srovė?</h2><div style=""display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:16px"">";
    for mode=1:3
        b=4*(mode-1);u=[mo5_value(r,b+2,"U1") mo5_value(r,b+3,"U2") mo5_value(r,b+4,"U3")];main=mo5_value(r,b+1,"I");
        currents=[main main main];
        if mode==2 then currents=[mo5_value(r,b+2,"I1") mo5_value(r,b+3,"I2") mo5_value(r,b+4,"I3")];end
        if mode==3 then currents=[main mo5_value(r,b+3,"I2") mo5_value(r,b+4,"I3")];end
        h=h+"<article class=""chart""><div class=""chart-head""><h3>"+names(mode)+"</h3></div>"+mo6_late_svg(names(mode)+" sujungti rezistoriai",330,220);
        if mode==1 then
            h=h+"<path d=""M25 30 H270 V190 H25 Z"" fill=""none"" stroke=""#8ca89a"" stroke-width=""2""/>";
            for j=1:3;h=h+mo6_late_rbox(270,55+50*(j-1),"R"+string(j));end
            h=h+mo6_late_arrow("ld8-s",80,30,160,30,"#087866","Visuose rezistoriuose ta pati srovė");
        elseif mode==2 then
            h=h+"<path d=""M25 30 H270 V190 H25 Z M110 30 V190 M190 30 V190"" fill=""none"" stroke=""#8ca89a"" stroke-width=""2""/>";
            for j=1:3;h=h+mo6_late_rbox(110+80*(j-1),105,"R"+string(j));end
        else
            h=h+"<path d=""M25 30 H155 V90 H270 V190 H25 Z M155 90 V190"" fill=""none"" stroke=""#8ca89a"" stroke-width=""2""/>";
            h=h+mo6_late_rbox(155,55,"R1")+mo6_late_rbox(155,140,"R2")+mo6_late_rbox(270,140,"R3");
        end
        h=h+"<circle cx=""25"" cy=""110"" r=""22"" fill=""white"" stroke=""#8ca89a"" stroke-width=""2""/>"+mo6_late_text(25,116,"E",17,"#234139","middle")+"</svg>";
        h=h+"<table><thead><tr><th>Elementas</th><th>U, V</th><th>I, mA</th></tr></thead><tbody>";
        for j=1:3;h=h+"<tr><td>R"+string(j)+"</td><td>"+mo_display(u(j))+"</td><td>"+mo_display(currents(j))+"</td></tr>";end
        h=h+"</tbody></table><p class=""chart-note"">";
        select mode
        case 1 then h=h+"Tas pats srovės kelias; įtampa pasidalija tarp rezistorių.";
        case 2 then h=h+"Visoms šakoms ta pati įtampa; bendroji srovė pasidalija.";
        case 3 then h=h+"Per R1 teka bendroji srovė, vėliau ji pasidalija į R2 ir R3.";
        end
        h=h+"</p></article>";
    end
    h=h+"</div></section>";
endfunction
function h=mo6_late_compensation(lab,r)
    isVoltage=(lab=="LD9");first=[];second=[];active=[];total=[];frequency=[];
    for k=1:3
        b=4*(k-1);frequency(k)=r(b+1).trial.x;
        if isVoltage then first(k)=mo5_value(r,b+2,"UL");second(k)=mo5_value(r,b+3,"UC");active(k)=mo5_value(r,b+1,"UR");total(k)=mo5_value(r,b+4,"U");
        else first(k)=mo5_value(r,b+3,"IC");second(k)=mo5_value(r,b+2,"IL");active(k)=mo5_value(r,b+1,"IR");total(k)=mo5_value(r,b+4,"I");end
    end
    scale=110/max([matrix(first,1,-1) matrix(second,1,-1) matrix(active,1,-1) matrix(total,1,-1) 1d-12]);unit="mA";a="IC";b="IL";realName="IR";totalName="I";title="Kodėl bendroji srovė gali būti maža?";
    colorA="#546fc2";colorB="#bd7132";
    if isVoltage then unit="V";a="UL";b="UC";realName="UR";totalName="U";title="Kaip ritės ir kondensatoriaus įtampos atsveria viena kitą?";colorA="#bd7132";colorB="#546fc2";end
    h="<section class=""section"" data-purpose="""+lab+"""><h2>"+title+"</h2><div style=""display:grid;grid-template-columns:repeat(auto-fit,minmax(250px,1fr));gap:16px"">";
    stages=["Žemiau rezonanso";"Ties rezonansu";"Aukščiau rezonanso"];
    for k=1:3
        x=95;y=150;prefix=lab+"-balance-"+string(k);
        h=h+"<article class=""chart""><div class=""chart-head""><h3>"+stages(k)+"</h3><p class=""small"">"+mo_report_number(frequency(k))+" Hz</p></div>"+mo6_late_svg("Priešingos "+a+" ir "+b+" kryptys",300,285);
        h=h+"<path d=""M35 150 H270 M95 20 V275"" stroke=""#d4dfd8"" fill=""none""/>";
        h=h+mo6_late_arrow(prefix+"-a",x,y,x,y-scale*first(k),colorA,a+" = "+mo_display(first(k))+" "+unit);
        h=h+mo6_late_arrow(prefix+"-b",x,y,x,y+scale*second(k),colorB,b+" = "+mo_display(second(k))+" "+unit);
        h=h+mo6_late_arrow(prefix+"-r",x,y,x+scale*active(k),y,"#087866",realName+" = "+mo_display(active(k))+" "+unit);
        h=h+mo6_late_arrow(prefix+"-sum",x,y,x+scale*active(k),y-scale*(first(k)-second(k)),"#b04f75",totalName+" = "+mo_display(total(k))+" "+unit);
        h=h+mo6_late_text(20,18,a+" ↑",13,colorA)+mo6_late_text(20,276,b+" ↓",13,colorB)+mo6_late_text(184,276,totalName+" – bendroji",12,"#b04f75")+mo6_late_text(220,143,realName+" →",13,"#087866")+"</svg>";
        h=h+mo6_late_readings([a;b],[first(k);second(k)],unit)+mo6_late_readings([realName;totalName],[active(k);total(k)],unit)+"</article>";
    end
    note="Ties rezonansu priešingų krypčių ritės ir kondensatoriaus srovės atsveria viena kitą; šaltinio srovė lieka artima IR.";
    if isVoltage then note="Ties rezonansu UL ir UC atsveria viena kitą; šaltinio įtampa lieka artima UR. Bendrąją įtampą vaizduoja įstrižas vektorius.";end
    h=h+"</div><p class=""chart-note"">"+note+" Visuose trijuose vaizduose mastelis vienodas.</p></section>";
endfunction
function [P,Q,S]=mo6_wave_power(w)
    angle=(w.phase_deg(2)-w.phase_deg(1))*%pi/180;S=1000*w.rms(1)*w.rms(2);P=S*cos(angle);Q=-S*sin(angle);
endfunction
function h=mo6_triangle(id,w,referenceWave)
    [P,Q,S]=mo6_wave_power(w);[P0,Q0,S0]=mo6_wave_power(referenceWave);
    factor=min(560/max(abs(P0),1d-12),135/max(abs(S0),1d-12));x0=150;y0=180;x=150+factor*P;y=180-factor*Q;xb=150+factor*P0;yb=180-factor*Q0;
    h="<article class=""chart""><div class=""chart-head""><h3>Galios trikampis: palyginimas su pradžia</h3><p class=""small"">P = "+mo_display(P)+" mW · Q = "+mo_display(Q)+" mvar · S = "+mo_display(S)+" mVA · cos φ = "+mo_display(P/max(S,1d-12))+"</p></div>"+mo6_late_svg("Galios trikampis vienodu masteliu su pradiniu kontūru",980,370);
    h=h+msprintf("<path d=""M150 180 H%.3f V%.3f Z"" stroke=""#b8c6bf"" fill=""#f6f8f6"" stroke-width=""2"" stroke-dasharray=""6 4""/>",xb,yb);
    h=h+mo6_late_arrow(id+"-p",x0,y0,x,y0,"#087866","P = "+mo_report_number(P)+" mW")+mo6_late_arrow(id+"-q",x,y0,x,y,"#bd7132","Q = "+mo_report_number(Q)+" mvar")+mo6_late_arrow(id+"-s",x0,y0,x,y,"#546fc2","S = "+mo_report_number(S)+" mVA");
    h=h+mo6_late_text((x0+x)/2,202,"P",14,"#087866","middle")+mo6_late_text(x+11,(y0+y)/2+4,"Q",14,"#bd7132")+mo6_late_text((x0+x)/2-25,(y0+y)/2-10,"S",14,"#546fc2")+mo6_late_text(470,105,"Pradžia: be kondensatoriaus",17,"#657c70")+mo6_late_text(470,143,"Pradinė srovė: "+mo_display(referenceWave.rms(2)*1000)+" mA",18,"#657c70")+mo6_late_text(470,183,"Šio bandymo srovė: "+mo_display(w.rms(2)*1000)+" mA",20,"#087866")+mo6_late_text(470,223,"Aktyvioji galia P: "+mo_display(P)+" mW",18,"#234139");
    h=h+mo6_late_text(150,343,"Blankus kontūras – pradžia; spalvotos rodyklės – pasirinktas bandymas.",15,"#657c70")+"</svg><p class=""chart-note"">Mastelis visoms talpoms vienodas. Q kryptis parodo, ar poveikis induktyvus, ar talpinis; arti kompensacijos vertikalioji trikampio kraštinė sutrumpėja.</p></article>";
endfunction
function h=mo6_three_phase(w)
    indices=[];for label=["U1" "U2" "U3"];j=find(w.labels==label);if isempty(j) then h="";return;end;indices($+1)=j(1);end
    peak=sqrt(2)*max(w.rms(indices));if peak<=0 then h="";return;end
    h="<article class=""chart""><div class=""chart-head""><h3>Trys šaltinio fazės: 120° poslinkis</h3></div>"+mo6_late_svg("Trys fazinės įtampos su 120 laipsnių poslinkiu",980,340);
    for q=[-1 0 1];yy=160-100*q;h=h+msprintf("<line x1=""85"" y1=""%g"" x2=""945"" y2=""%g"" stroke=""#dbe5df""/>",yy,yy)+mo6_late_text(74,yy+4,mo_display(q*peak),12,"#657c70","end");end
    for k=1:3
        j=indices(k);points="";
        for n=0:240;x=85+860*n/240;y=160-100*sqrt(2)*w.rms(j)/peak*cos(4*%pi*n/240+w.phase_deg(j)*%pi/180);points=points+msprintf("%.2f,%.2f ",x,y);end
        tip=w.labels(j)+" = "+mo_display(w.rms(j))+" V, fazė "+mo_report_number(w.phase_deg(j))+"°";
        h=h+"<polyline data-role=""model"" data-tip="""+mo_html(tip)+""" tabindex=""0"" points="""+points+""" fill=""none"" stroke="""+mo5_color(k)+""" stroke-width=""2.7""><title>"+mo_html(tip)+"</title></polyline>";
        h=h+mo6_late_text(150+280*(k-1),25,tip,13,mo5_color(k),"middle");
    end
    for q=0:4;xx=85+860*q/4;h=h+mo6_late_text(xx,292,mo_report_number(2000/w.frequency*q/4),13,"#657c70","middle");end
    h=h+mo6_late_text(30,165,"V",14,"#657c70")+mo6_late_text(515,328,"t, ms",14,"#657c70","middle")+"</svg><p class=""chart-note"">Visos trys fazės turi tą patį dažnį ir efektinę įtampą. Šaltinio fazės abiem jungimams tos pačios; keičiasi imtuvų sujungimas.</p></article>";
endfunction
function h=mo6_late_resistor(cx,cy,angle)
    h=msprintf("<g transform=""translate(%.3f %.3f) rotate(%.3f)""><rect x=""-22"" y=""-9"" width=""44"" height=""18"" fill=""#eff6f2"" stroke=""#087866"" stroke-width=""2""/></g>",cx,cy,angle);
endfunction
function h=mo6_connection_12(mode)
    title="Žvaigždė";if mode==2 then title="Trikampis";end
    h=mo6_late_svg(title+" sujungti imtuvai",300,200);
    if mode==1 then
        h=h+"<path d=""M150 35 L150 110 L50 170 M150 110 L250 170"" fill=""none"" stroke=""#087866"" stroke-width=""3""/>"+mo6_late_text(164,114,"N",14,"#657c70");
        h=h+mo6_late_resistor(150,72.5,90)+mo6_late_resistor(100,140,150)+mo6_late_resistor(200,140,30)+"<circle cx=""150"" cy=""110"" r=""4"" fill=""#087866""/>"+mo6_late_text(165,77,"R1",13,"#234139")+mo6_late_text(80,129,"R2",13,"#234139")+mo6_late_text(210,129,"R3",13,"#234139");
    else
        h=h+"<path d=""M150 35 L50 170 H250 Z"" fill=""none"" stroke=""#087866"" stroke-width=""3""/>"+mo6_late_resistor(100,102.5,126.528855)+mo6_late_resistor(150,170,0)+mo6_late_resistor(200,102.5,53.471145)+mo6_late_text(65,96,"R1",13,"#234139")+mo6_late_text(150,157,"R2",13,"#234139","middle")+mo6_late_text(218,96,"R3",13,"#234139");
    end
    h=h+mo6_late_text(150,23,"L1",14,"#234139","middle")+mo6_late_text(30,190,"L2",14,"#234139")+mo6_late_text(250,190,"L3",14,"#234139")+"</svg>";
endfunction
function h=mo6_late_ld12(cfg,r)
    h="<section class=""section"" data-purpose=""LD12""><h2>Trys fazės ir du imtuvų jungimai</h2>"+mo6_three_phase(r(1).reading.wave)+"<div style=""display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:16px"">";
    names=["Žvaigždė";"Trikampis"];
    for mode=1:2
        b=2*(mode-1);uf=mo5_value(r,b+1,"Uf");ifaz=mo5_value(r,b+1,"If");ul=mo5_value(r,b+2,"Ul");il=mo5_value(r,b+2,"Il");
        h=h+"<article class=""chart""><div class=""chart-head""><h3>"+names(mode)+"</h3></div>"+mo6_connection_12(mode)+mo6_late_readings(["Uf";"Ul"],[uf;ul],"V")+mo6_late_readings(["If";"Il"],[ifaz;il],"mA")+"<p class=""chart-note"">";
        if mode==1 then h=h+"Linijinė įtampa didesnė už fazinę; linijos ir imtuvo srovė vienodos.";
        else h=h+"Imtuvui tenka linijinė įtampa; linijos srovė didesnė už vieno imtuvo srovę.";end
        h=h+"</p></article>";
    end
    h=h+"</div></section>";
endfunction
function h=mo6_late_visual(lab,cfg,records)
    h="";
    select lab
    case "LD7" then h=mo6_late_ld7(cfg,records);
    case "LD8" then h=mo6_late_ld8(cfg,records);
    case "LD9" then h=mo6_late_compensation(lab,records);
    case "LD10" then h=mo6_late_compensation(lab,records);
    case "LD12" then h=mo6_late_ld12(cfg,records);
    end
endfunction
function h=mo6_wave_note(w)
    difference=modulo(w.phase_deg(2)-w.phase_deg(1)+180,360)-180;
    delta=abs(difference)/(360*w.frequency)*1000;
    if abs(difference)<.01 then sentence="Įtampos ir srovės viršūnės sutampa: jos kinta vienoje fazėje.";
    elseif difference>0 then sentence="Srovės viršūnė pasiekiama anksčiau: srovė pirmauja prieš įtampą.";
    else sentence="Srovės viršūnė pasiekiama vėliau: srovė atsilieka nuo įtampos.";end
    h="<p class=""chart-note"">"+sentence+" Viršūnių laiko skirtumas Δt = "+mo_report_number(delta)+" ms.</p>";
endfunction
function h=mo6_peak_markers(w)
    a=modulo(w.phase_deg(1)+180,360)-180;b=modulo(w.phase_deg(2)+180,360)-180;
    xu=517-850*a/720;xi=517-850*b/720;
    h=msprintf("<circle cx=""%.3f"" cy=""40"" r=""5"" fill=""#087866"" stroke=""white"" stroke-width=""2""/><circle cx=""%.3f"" cy=""225"" r=""5"" fill=""#bd7132"" stroke=""white"" stroke-width=""2""/><path d=""M%.3f 45 V366 M%.3f 230 V366"" fill=""none"" stroke=""#a1b6aa"" stroke-dasharray=""4 4""/>",xu,xi,xu,xi);
    if abs(xu-xi)>1 then h=h+msprintf("<path d=""M%.3f 359 V369 M%.3f 364 H%.3f M%.3f 359 V369"" stroke=""#657c70"" fill=""none""/>",xu,xu,xi,xi);end
    h=h+mo6_late_text((xu+xi)/2,351,"Δt",13,"#657c70","middle");
endfunction
