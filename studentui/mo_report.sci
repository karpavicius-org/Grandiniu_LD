// Savarankiškos 12 laboratorinių darbų ataskaitos ir dėstytojo suvestinė.
function s=mo_html(s)
    s=strsubst(string(s),"&","&amp;");s=strsubst(s,"<","&lt;");s=strsubst(s,">","&gt;");
    s=strsubst(s,ascii(34),"&quot;");s=strsubst(s,ascii(39),"&#39;");
endfunction
function h=mo_paragraphs(lines)
    h="";for k=1:size(lines,"*");h=h+"<p>"+mo_html(lines(k))+"</p>";end
endfunction
function s=mo_report_number(v)
    s=msprintf("%.6g",v);if abs(v)<1d-12 then s="0";end
endfunction
function s=mo5_json(value)
    s=toJSON(value);s=strsubst(s,"<","\u003c");s=strsubst(s,">","\u003e");s=strsubst(s,"&","\u0026");
endfunction
function value=mo5_value(records,index,id)
    if type(index)==10 then
        hit=0;for k=1:length(records);if records(k).trial.key==index then hit=k;break;end;end
        if hit==0 then error("Trūksta bandymo "+index);end;index=hit;
    end
    rec=records(index);j=find(rec.reading.ids==id);
    if size(j,"*")<>1 then error("Trūksta rodmens "+id);end
    value=rec.reading.values(j(1));
endfunction
function values=mo5_values(records,indices,id)
    values=[];for k=matrix(indices,1,-1);values($+1)=mo5_value(records,k,id);end
    values=matrix(values,1,-1);
endfunction
function values=mo5_x(records,indices)
    values=[];for k=matrix(indices,1,-1);values($+1)=records(k).trial.x;end
    values=matrix(values,1,-1);
endfunction
function s=mo5_series(name,x,y,labels,role)
    if argn(2)<4 then labels=emptystr(0,1);end
    if argn(2)<5 then role="measurement";end
    s=struct("name",name,"x",matrix(x,1,-1),"y",matrix(y,1,-1),"labels",matrix(labels,-1,1),"role",role);
endfunction
function g=mo5_plot(title,xlabel,ylabel,kind,series,labels)
    if argn(2)<6 then labels=emptystr(0,1);end
    g=struct("title",title,"xlabel",xlabel,"ylabel",ylabel,"kind",kind,"series",series,"labels",matrix(labels,-1,1));
endfunction
function plots=mo5_recipes(lab,cfg,r)
    plots=list();
    select lab
    case "LD1" then
        plots($+1)=mo5_plot("Srovė sumažinus grandinės varžą","VR1, Ω","I, mA","line",list(mo5_series("Nuoseklioji grandinė",mo5_x(r,1:2),mo5_values(r,1:2,"I_series"))));
        plots($+1)=mo5_plot("Lygiagrečių šakų įtampa","VR1, Ω","U, V","line",list(mo5_series("Įtampa tarp A ir B",mo5_x(r,3:4),mo5_values(r,3:4,"U_parallel"))));
        plots($+1)=mo5_plot("Bendroji ir šakų srovės","Matavimo vieta","I, mA","bar",list(mo5_series("Ampermetro rodmuo",1:3,[mo5_value(r,5,"I_main") mo5_value(r,7,"I_R2") mo5_value(r,6,"I_R3")])),["Prieš išsišakojimą";"R2 ir VR1 šaka";"R3 šaka"]);
    case "LD2" then
        plots($+1)=mo5_plot("RC grandinės įtampos","Matavimo vieta","U, V","bar",list(mo5_series("Voltmetro rodmuo",1:3,[mo5_value(r,1,"U_RC_R") mo5_value(r,2,"U_RC_C") mo5_value(r,3,"U_RC_E")])),["Rezistorius";"Kondensatorius";"Generatorius"]);
        plots($+1)=mo5_plot("RL grandinės įtampos","Matavimo vieta","U, V","bar",list(mo5_series("Voltmetro rodmuo",1:3,[mo5_value(r,4,"U_RL_R") mo5_value(r,5,"U_RL_L") mo5_value(r,6,"U_RL_E")])),["Rezistorius";"Ritė";"Generatorius"]);
        plots($+1)=mo5_plot("RLC srovės rezonansas","f, Hz","I, mA","line",list(mo5_series("RLC srovė",mo5_x(r,7:9),mo5_values(r,7:9,"I_RLC"))));
        plots($+1)=mo5_plot("RLC rezistoriaus įtampa","f, Hz","UR, V","line",list(mo5_series("Rezistoriaus įtampa",mo5_x(r,7:9),mo5_values(r,7:9,"U_RLC_R"))));
        plots($+1)=mo5_plot("Įtampos ties rezonansu","Matavimo vieta","U, V","bar",list(mo5_series("Voltmetro rodmuo",1:4,[mo5_value(r,8,"U_RLC_R") mo5_value(r,10,"U_RLC_L") mo5_value(r,11,"U_RLC_C") mo5_value(r,12,"U_RLC_LC")])),["R";"L";"C";"L ir C kartu"]);
    case "LD3" then
        plots($+1)=mo5_plot("To paties rezistoriaus srovė didinant įtampą","U, V","I, mA","line",list(mo5_series("Matavimo taškai",mo5_values(r,1:3,"U"),mo5_values(r,1:3,"I"))));
    case "LD4" then
        plots($+1)=mo5_plot("Dviejų rezistorių voltamperinės charakteristikos","U, V","I, mA","line",list(mo5_series("R1",mo5_values(r,1:3,"U"),mo5_values(r,1:3,"I")),mo5_series("R2",mo5_values(r,4:6,"U"),mo5_values(r,4:6,"I"))));
        plots($+1)=mo5_plot("Jungimų srovės esant "+mo_report_number(cfg.U3)+" V","Jungimas","I, mA","bar",list(mo5_series("Ampermetro rodmuo",1:3,[mo5_value(r,3,"I") mo5_value(r,6,"I") mo5_value(r,7,"I")])),["R1";"R2";"R1 ir R2 nuosekliai"]);
    case "LD5" then
        plots($+1)=mo5_plot("Potenciometro padėtis ir išėjimo įtampa","Potenciometro padėtis, %","Uout, V","line",list(mo5_series("Išėjimo įtampa",mo5_x(r,1:3),mo5_values(r,1:3,"U"))));
        plots($+1)=mo5_plot("Potenciometro padėtis ir srovė","Potenciometro padėtis, %","I, mA","line",list(mo5_series("Grandinės srovė",mo5_x(r,1:3),mo5_values(r,1:3,"I"))));
    case "LD6" then
        labels=["Vienas E1";"Nuosekliai suderintai";"Nuosekliai priešpriešiais";"Lygiagrečiai"];
        plots($+1)=mo5_plot("Šaltinių jungimo poveikis įtampai","Šaltinių jungimas","U, V","bar",list(mo5_series("Apkrovos įtampa",1:4,mo5_values(r,1:4,"U"))),labels);
        plots($+1)=mo5_plot("Šaltinių jungimo poveikis srovei","Šaltinių jungimas","I, mA","bar",list(mo5_series("Apkrovos srovė",1:4,mo5_values(r,1:4,"I"))),labels);
    case "LD7" then
        u=mo5_values(r,1:5,"U");i=mo5_values(r,1:5,"I");
        plots($+1)=mo5_plot("Apkrauto šaltinio charakteristika","I, mA","U, V","line",list(mo5_series("Penkios apkrovos",i,u)));
        plots($+1)=mo5_plot("Apkrovai perduodama galia","R, Ω","P = U · I, mW","line",list(mo5_series("Apkrovos galia",mo5_x(r,1:5),u.*i,[],"derived")));
    case "LD8" then
        labels=["Nuosekliai";"Lygiagrečiai";"Mišriai"];idx=[1 5 9];u=mo5_values(r,idx,"U");i=mo5_values(r,idx,"I");
        plots($+1)=mo5_plot("Trijų jungimų bendrosios srovės","Rezistorių jungimas","I, mA","bar",list(mo5_series("Bendroji srovė",1:3,i)),labels);
        plots($+1)=mo5_plot("Trijų jungimų bendroji varža","Rezistorių jungimas","R = U / I, Ω","bar",list(mo5_series("Bendroji varža",1:3,1000*u./i,[],"derived")),labels);
        plots($+1)=mo5_plot("Įtampa ties kiekvienu rezistoriumi","Rezistorius","U, V","bar",list(mo5_series("Nuosekliai",1:3,[mo5_value(r,2,"U1") mo5_value(r,3,"U2") mo5_value(r,4,"U3")]),mo5_series("Lygiagrečiai",1:3,[mo5_value(r,6,"U1") mo5_value(r,7,"U2") mo5_value(r,8,"U3")]),mo5_series("Mišriai",1:3,[mo5_value(r,10,"U1") mo5_value(r,11,"U2") mo5_value(r,12,"U3")])),["R1";"R2";"R3"]);
        plots($+1)=mo5_plot("Lygiagretaus jungimo srovės","Matavimo vieta","I, mA","bar",list(mo5_series("Ampermetro rodmuo",1:4,[mo5_value(r,5,"I") mo5_value(r,6,"I1") mo5_value(r,7,"I2") mo5_value(r,8,"I3")])),["Bendroji";"R1";"R2";"R3"]);
        plots($+1)=mo5_plot("Mišriojo jungimo srovės","Matavimo vieta","I, mA","bar",list(mo5_series("Ampermetro rodmuo",1:3,[mo5_value(r,9,"I") mo5_value(r,11,"I2") mo5_value(r,12,"I3")])),["Bendroji ir R1";"R2 šaka";"R3 šaka"]);
    case "LD9" then
        idx=[1 5 9];freq=mo5_x(r,idx);
        plots($+1)=mo5_plot("Nuosekliosios grandinės srovės rezonansas","f, Hz","I, mA","line",list(mo5_series("I",freq,mo5_values(r,idx,"I"))));
        plots($+1)=mo5_plot("Rezistoriaus, ritės ir kondensatoriaus įtampos","f, Hz","U, V","line",list(mo5_series("UR",freq,mo5_values(r,idx,"UR")),mo5_series("UL",freq,mo5_values(r,idx+1,"UL")),mo5_series("UC",freq,mo5_values(r,idx+2,"UC")),mo5_series("Generatoriaus U",freq,mo5_values(r,idx+3,"U"))));
    case "LD10" then
        idx=[1 5 9];freq=mo5_x(r,idx);
        plots($+1)=mo5_plot("Šakų srovės ir bendroji srovė","f, Hz","I, mA","line",list(mo5_series("IR",freq,mo5_values(r,idx,"IR")),mo5_series("IL",freq,mo5_values(r,idx+1,"IL")),mo5_series("IC",freq,mo5_values(r,idx+2,"IC")),mo5_series("Bendroji I",freq,mo5_values(r,idx+3,"I"))));
    case "LD11" then
        idx=1:length(r);u=mo5_values(r,idx,"U");i=mo5_values(r,idx,"I");power=mo5_values(r,idx,"P");cap=mo5_x(r,idx);
        plots($+1)=mo5_plot("Talpa ir bendroji srovė","C, µF","I, mA","line",list(mo5_series("Bendroji srovė",cap,i)));
        plots($+1)=mo5_plot("Talpa ir galios faktorius","C, µF","cos φ = P / (U · I)","line",list(mo5_series("Galios faktorius",cap,power./(u.*i),[],"derived")));
    case "LD12" then
        labels=["Žvaigždė";"Trikampis"];uf=mo5_values(r,[1 3],"Uf");ifaz=mo5_values(r,[1 3],"If");ul=mo5_values(r,[2 4],"Ul");il=mo5_values(r,[2 4],"Il");
        plots($+1)=mo5_plot("Fazinės ir linijinės įtampos","Jungimas","U, V","bar",list(mo5_series("Fazinė Uf",1:2,uf),mo5_series("Linijinė Ul",1:2,ul)),labels);
        plots($+1)=mo5_plot("Fazinės ir linijinės srovės","Jungimas","I, mA","bar",list(mo5_series("Fazinė If",1:2,ifaz),mo5_series("Linijinė Il",1:2,il)),labels);
    end
endfunction
function color=mo5_color(k)
    colors=["#087866" "#bd7132" "#546fc2" "#b04f75" "#7a8b37" "#6b6f76"];
    color=colors(modulo(k-1,size(colors,"*"))+1);
endfunction
function h=mo5_axis_label(label,x,y)
    label=string(label);cut=0;
    if length(label)>24 then
        spaces=strindex(label," ");spaces=spaces(spaces<=24);if ~isempty(spaces) then cut=spaces($);else cut=24;end
    end
    h=msprintf("<text x=""%.2f"" y=""%.2f"" text-anchor=""middle"" font-size=""12"">",x,y);
    if cut>0 then h=h+"<tspan>"+mo_html(part(label,1:cut))+"</tspan>"+msprintf("<tspan x=""%.2f"" dy=""15"">",x)+mo_html(part(label,cut+1:length(label)))+"</tspan>";
    else h=h+mo_html(label);end
    h=h+"</text>";
endfunction
function h=mo5_chart(id,g)
    allx=[];ally=[];
    for k=1:length(g.series)
        s=g.series(k);if size(s.x,"*")<>size(s.y,"*") | size(s.y,"*")==0 then error("Neatitinka grafiko duomenys: "+g.title);end
        if or(isnan(s.y)) | or(isinf(s.y)) then error("Grafike negalimi netinkami rodmenys.");end
        allx=[allx matrix(s.x,1,-1)];ally=[ally matrix(s.y,1,-1)];
    end
    xmin=min(allx);xmax=max(allx);ymin=min([0 ally]);ymax=max([0 ally]);
    if xmin==xmax then xmin=xmin-.5;xmax=xmax+.5;end
    if ymin==ymax then ymax=ymin+1;end
    span=ymax-ymin;if ymin<0 then ymin=ymin-.12*span;end;if ymax>0 then ymax=ymax+.15*span;end
    left=92;top=50;pw=850;ph=280;bottom=top+ph;zero=bottom-ph*(0-ymin)/(ymax-ymin);
    h="<article class=""chart"" id="""+id+"""><div class=""chart-head""><h3>"+mo_html(g.title)+"</h3><div class=""legend no-print"">";
    for k=1:length(g.series)
        h=h+"<button type=""button"" data-toggle="""+id+"-s"+string(k)+""" aria-pressed=""true"" style=""--series-color:"+mo5_color(k)+""">"+mo_html(g.series(k).name)+"</button>";
    end
    h=h+"</div><p class=""print-legend"">";
    for k=1:length(g.series);h=h+"<span style=""color:"+mo5_color(k)+""">■ "+mo_html(g.series(k).name)+"</span> &nbsp; ";end
    h=h+"</p></div><svg viewBox=""0 0 980 430"" role=""img"" aria-label="""+mo_html(g.title)+"""><title>"+mo_html(g.title)+"</title>";
    for q=0:4
        yy=bottom-ph*q/4;value=ymin+(ymax-ymin)*q/4;
        h=h+msprintf("<line x1=""92"" y1=""%.2f"" x2=""942"" y2=""%.2f"" stroke=""#e0e9e4""/><text x=""82"" y=""%.2f"" text-anchor=""end"" font-size=""12"">",yy,yy,yy+4)+mo_html(mo_report_number(value))+"</text>";
    end
    h=h+msprintf("<line x1=""92"" y1=""50"" x2=""92"" y2=""330"" stroke=""#a5b9ad""/><line x1=""92"" y1=""%.2f"" x2=""942"" y2=""%.2f"" stroke=""#91a99c""/>",zero,zero);
    if g.kind=="line" then
        ticks=unique(allx);if size(ticks,"*")>7 then ticks=linspace(xmin,xmax,5);end
        for x=matrix(ticks,1,-1)
            xx=left+pw*(x-xmin)/(xmax-xmin);h=h+mo5_axis_label(mo_report_number(x),xx,353);
        end
    else
        n=size(g.labels,"*");for j=1:n;h=h+mo5_axis_label(g.labels(j),left+pw*(j-.5)/n,353);end
    end
    for k=1:length(g.series)
        s=g.series(k);col=mo5_color(k);h=h+"<g id="""+id+"-s"+string(k)+""" data-role="""+s.role+""">";
        if g.kind=="line" then
            [xx,order]=gsort(s.x,"g","i");yy=s.y(order);px=left+pw*(xx-xmin)/(xmax-xmin);py=bottom-ph*(yy-ymin)/(ymax-ymin);points="";
            for j=1:size(xx,"*");points=points+msprintf("%.2f,%.2f ",px(j),py(j));end
            h=h+"<polyline points="""+points+""" fill=""none"" stroke="""+col+""" stroke-width=""2.5""/>";
            for j=1:size(xx,"*")
                tip=s.name+": "+mo_report_number(xx(j))+"; "+mo_report_number(yy(j))+" "+g.ylabel;
                h=h+msprintf("<circle cx=""%.2f"" cy=""%.2f"" r=""5"" fill=""%s"" stroke=""white"" stroke-width=""1.5"" tabindex=""0"" data-tip=""",px(j),py(j),col)+mo_html(tip)+"""><title>"+mo_html(tip)+"</title></circle>";
            end
        else
            n=size(g.labels,"*");ns=length(g.series);bw=.7*pw/n/ns;
            for j=1:size(s.y,"*")
                x=left+pw*(j-.5)/n+(k-(ns+1)/2)*bw;y=bottom-ph*(s.y(j)-ymin)/(ymax-ymin);tip=s.name+" · "+g.labels(j)+": "+mo_report_number(s.y(j))+" "+g.ylabel;
                h=h+msprintf("<rect x=""%.2f"" y=""%.2f"" width=""%.2f"" height=""%.2f"" rx=""3"" fill=""%s"" tabindex=""0"" data-tip=""",x-bw*.44,min(y,zero),bw*.88,max(.8,abs(zero-y)),col)+mo_html(tip)+"""><title>"+mo_html(tip)+"</title></rect>";
                labely=y-9;if s.y(j)<0 then labely=y+17;end
                h=h+msprintf("<text x=""%.2f"" y=""%.2f"" text-anchor=""middle"" font-size=""11"">",x,labely)+mo_html(mo_report_number(s.y(j)))+"</text>";
            end
        end
        h=h+"</g>";
    end
    h=h+"<text x=""92"" y=""28"" font-size=""12"">"+mo_html(g.ylabel)+"</text><text x=""517"" y=""411"" text-anchor=""middle"" font-size=""13"">"+mo_html(g.xlabel)+"</text></svg></article>";
endfunction
function h=mo_report_charts(p,records,cfg)
    if argn(2)<3 then error("Grafikams reikia žinomo varianto parametrų.");end
    recipes=mo5_recipes(p.lab,cfg,records);h="";
    for k=1:length(recipes);h=h+mo5_chart(p.lab+"-g"+string(k),recipes(k));end
endfunction
function states=mo5_wave_states(lab,cfg,records)
    states=list();seen=emptystr(0,1);
    if lab=="LD2" then
        for k=[1 4 7 8 9]
            t=records(k).trial;f=t.frequency;
            select t.phase
            case "RC" then
                m=ld2_rc_values(cfg.E_RC,f,cfg.R8,cfg.C2);w=struct("frequency",f,"labels",["U";"I";"UR";"UC"],"units",["V";"A";"V";"V"],"rms",[cfg.E_RC;m.I;m.UR;m.UX],"phase_deg",[0;m.PHI_I;m.PHI_I;m.PHI_I-90]);
            case "RL" then
                m=ld2_rl_values(cfg.E_RL,f,cfg.R9,cfg.L1);w=struct("frequency",f,"labels",["U";"I";"UR";"UL"],"units",["V";"A";"V";"V"],"rms",[cfg.E_RL;m.I;m.UR;m.UX],"phase_deg",[0;m.PHI_I;m.PHI_I;m.PHI_I+90]);
            case "RLC" then
                m=ld2_rlc_values(cfg.E_RLC,f,cfg.R13,cfg.L3,cfg.C4);w=struct("frequency",f,"labels",["U";"I";"UR";"UL";"UC"],"units",["V";"A";"V";"V";"V"],"rms",[cfg.E_RLC;m.I;m.UR;m.UL;m.UC],"phase_deg",[0;-m.PHI;-m.PHI;-m.PHI+90;-m.PHI-90]);
            end
            states($+1)=struct("label",t.phase+" · "+mo_report_number(f)+" Hz","wave",w);
        end
        return;
    end
    for k=1:length(records)
        rec=records(k);if ~isfield(rec.reading,"wave") then continue;end
        token=string(k);label=rec.trial.title;
        if or(lab==["LD9" "LD10"]) then token=mo_num(rec.reading.wave.frequency);label="f = "+mo_report_number(rec.reading.wave.frequency)+" Hz";end
        if lab=="LD12" then token=string(rec.trial.mode);if rec.trial.mode==1 then label="Žvaigždė";else label="Trikampis";end;end
        if or(seen==token) then continue;end;seen($+1,1)=token;
        states($+1)=struct("label",label,"wave",rec.reading.wave);
    end
endfunction
function h=mo5_wave_svg(id,w)
    f=w.frequency;if f<=0 then h="";return;end
    h="<article class=""chart""><div class=""chart-head""><h3>Įtampos ir srovės modelio signalai</h3><p class=""small"">f = "+mo_report_number(f)+" Hz · U = "+mo_report_number(w.rms(1))+" V · I = "+mo_report_number(w.rms(2)*1000)+" mA</p></div><svg viewBox=""0 0 980 440"" role=""img""><title>Įtampa ir srovė per du periodus</title><desc>Įtampos ir srovės amplitudės atskirose ašyse, bendras laikas milisekundėmis.</desc>";
    for ch=1:2
        zero=105+(ch-1)*185;peak=sqrt(2)*w.rms(ch);unit="V";scale=1;if ch==2 then unit="mA";scale=1000;end
        h=h+msprintf("<line x1=""92"" y1=""%.2f"" x2=""942"" y2=""%.2f"" stroke=""#b3c4bb""/>",zero,zero);
        for q=[-1 1]
            yy=zero-q*65;h=h+msprintf("<line x1=""92"" y1=""%.2f"" x2=""942"" y2=""%.2f"" stroke=""#e3eae6""/><text x=""82"" y=""%.2f"" text-anchor=""end"" font-size=""11"">",yy,yy,yy+4)+mo_html(mo_report_number(q*peak*scale))+"</text>";
        end
        h=h+msprintf("<text x=""92"" y=""%.2f"" font-size=""12"">",zero-82)+mo_html(w.labels(ch)+", "+unit)+"</text>";points="";
        for j=0:200
            x=92+850*j/200;y=zero-65*cos(4*%pi*j/200+w.phase_deg(ch)*%pi/180);
            if peak==0 then y=zero;end
            points=points+msprintf("%.2f,%.2f ",x,y);
        end
        h=h+"<polyline data-role=""model"" points="""+points+""" fill=""none"" stroke="""+mo5_color(ch)+""" stroke-width=""2.5""/>";
    end
    for q=0:4;xx=92+850*q/4;h=h+mo5_axis_label(mo_report_number(2000/f*q/4),xx,395);end
    h=h+mo6_peak_markers(w);angle=w.phase_deg(2)-w.phase_deg(1);h=h+"<text x=""517"" y=""427"" text-anchor=""middle"" font-size=""13"">t, ms</text></svg><p class=""chart-note"">Srovės fazė įtampos atžvilgiu: "+mo_report_number(angle)+"°.</p>"+mo6_wave_note(w)+"</article>";
endfunction
function h=mo5_phasor_svg(id,w,unit)
    indices=find(w.units==unit);if size(indices,"*")<2 then h="";return;end
    scaleUnit=1;labelUnit=unit;title="Įtampų fazoriai";if unit=="A" then scaleUnit=1000;labelUnit="mA";title="Srovių fazoriai";end
    values=w.rms(indices)*scaleUnit;maxval=max(abs(values));if maxval<=0 then maxval=1;end
    h="<article class=""chart""><div class=""chart-head""><h3>"+title+"</h3><div class=""legend no-print"">";
    for j=1:size(indices,"*");k=indices(j);h=h+"<button data-toggle="""+id+"-p"+string(j)+""" type=""button"" aria-pressed=""true"" style=""--series-color:"+mo5_color(j)+""">"+mo_html(w.labels(k))+"</button>";end
    h=h+"</div></div><svg viewBox=""0 0 980 440"" role=""img""><title>"+title+"</title><desc>Vektoriai vienodo mastelio kompleksinėje plokštumoje.</desc><line x1=""220"" y1=""215"" x2=""760"" y2=""215"" stroke=""#bacbc1""/><line x1=""490"" y1=""35"" x2=""490"" y2=""395"" stroke=""#bacbc1""/><text x=""769"" y=""219"" font-size=""12"">Re</text><text x=""499"" y=""32"" font-size=""12"">Im</text>";
    for j=1:size(indices,"*")
        k=indices(j);angle=w.phase_deg(k)*%pi/180;xx=490+155*values(j)/maxval*cos(angle);yy=215-155*values(j)/maxval*sin(angle);col=mo5_color(j);marker=id+"-arrow"+string(j);tip=w.labels(k)+": "+mo_report_number(values(j))+" "+labelUnit+" ∠ "+mo_report_number(w.phase_deg(k))+"°";
        h=h+"<defs><marker id="""+marker+""" markerWidth=""7"" markerHeight=""7"" refX=""6"" refY=""3"" orient=""auto""><path d=""M0,0 L0,6 L6,3 z"" fill="""+col+"""/></marker></defs><g id="""+id+"-p"+string(j)+""" data-role=""model"">";
        if abs(values(j))>1d-12 then h=h+msprintf("<line x1=""490"" y1=""215"" x2=""%.2f"" y2=""%.2f"" stroke=""%s"" stroke-width=""2.5"" marker-end=""url(#%s)"" tabindex=""0"" data-tip=""",xx,yy,col,marker)+mo_html(tip)+"""><title>"+mo_html(tip)+"</title></line>";end
        h=h+msprintf("<text x=""%.2f"" y=""%.2f"" font-size=""12"" style=""fill:%s"">",xx+8,yy-8-11*modulo(j,2),col)+mo_html(w.labels(k))+"</text></g>";
    end
    h=h+"</svg><p class=""chart-note"">";
    for j=1:size(indices,"*");k=indices(j);h=h+mo_html(w.labels(k)+" = "+mo_report_number(values(j))+" "+labelUnit+" ∠ "+mo_report_number(w.phase_deg(k))+"°")+" &nbsp; ";end
    h=h+"</p></article>";
endfunction
function h=mo5_triangle(id,w)
    u=w.rms(1);i=w.rms(2);angle=(w.phase_deg(2)-w.phase_deg(1))*%pi/180;S=1000*u*i;P=S*cos(angle);Q=-S*sin(angle);
    factor=min(700/max(abs(P),1d-12),160/max(abs(Q),1d-12));x=130+factor*P;y=215-factor*Q;
    h="<article class=""chart""><div class=""chart-head""><h3>Galios trikampis</h3><p class=""small"">P = "+mo_report_number(P)+" mW · Q = "+mo_report_number(Q)+" mvar · S = "+mo_report_number(S)+" mVA · cos φ = "+mo_report_number(P/max(S,1d-12))+"</p></div><svg viewBox=""0 0 980 440"" role=""img""><title>Galios trikampis P Q S</title><desc>Aktyvioji, reaktyvioji ir pilnutinė galia pavaizduotos vienodu masteliu.</desc>";
    h=h+msprintf("<line x1=""130"" y1=""215"" x2=""%.2f"" y2=""215"" stroke=""#087866"" stroke-width=""3""/><line x1=""%.2f"" y1=""215"" x2=""%.2f"" y2=""%.2f"" stroke=""#bd7132"" stroke-width=""3""/><line x1=""130"" y1=""215"" x2=""%.2f"" y2=""%.2f"" stroke=""#546fc2"" stroke-width=""3""/>",x,x,x,y,x,y);
    h=h+msprintf("<text x=""%.2f"" y=""237"" font-size=""13"">P</text><text x=""%.2f"" y=""%.2f"" font-size=""13"">Q</text><text x=""%.2f"" y=""%.2f"" font-size=""13"">S</text>",(130+x)/2,x+11,(215+y)/2,(130+x)/2-10,(215+y)/2-12);
    phi=atan(Q,max(P,1d-12));points="";for j=0:20;points=points+msprintf("%.2f,%.2f ",130+40*cos(phi*j/20),215-40*sin(phi*j/20));end
    h=h+"<polyline points="""+points+""" fill=""none"" stroke=""#8a9e91""/>"+msprintf("<text x=""183"" y=""%.2f"" font-size=""12"">",207-20*sign(phi))+"φ = "+mo_report_number(phi*180/%pi)+"°</text></svg></article>";
endfunction
function h=mo5_ac_visuals(lab,cfg,records)
    h="";states=mo5_wave_states(lab,cfg,records);if length(states)==0 then return;end
    h="<section class=""section ac-visuals""><h2>Fazoriai ir signalai</h2><div class=""controls wave-tabs no-print""><label>Bandymas <select data-wave-select>";
    for k=1:length(states);h=h+"<option value="""+lab+"-wave"+string(k)+""">"+mo_html(states(k).label)+"</option>";end
    h=h+"</select></label></div>";
    referenceWave=states(1).wave;
    for k=1:length(states)
        state=states(k);id=lab+"-wave"+string(k);w=state.wave;h=h+"<div class=""wave-panel"" id="""+id+"""><h3>"+mo_html(state.label)+"</h3>";
        unit="V";if or(lab==["LD10" "LD11"]) then unit="A";end
        h=h+mo5_phasor_svg(id,w,unit)+mo5_wave_svg(id,w);
        if lab=="LD11" then h=h+mo6_triangle(id,w,referenceWave);end
        h=h+"</div>";
    end
    h=h+"</section>";
endfunction
function text=mo5_goal(lab)
    goals=["Ištirti srovę nuoseklioje ir šakotoje grandinėje bei palyginti bendrąją ir šakų sroves."; ...
    "Palyginti RC ir RL grandinių įtampas, ištirti nuosekliosios RLC grandinės rezonansą."; ...
    "Nustatyti to paties rezistoriaus srovės priklausomybę nuo įtampos."; ...
    "Palyginti dviejų rezistorių charakteristikas ir jų nuoseklų jungimą."; ...
    "Ištirti potenciometro padėties poveikį išėjimo įtampai ir grandinės srovei."; ...
    "Palyginti vieną šaltinį, suderintą ir priešpriešinį nuoseklų bei lygiagretų šaltinių jungimą."; ...
    "Ištirti apkrauto šaltinio įtampą, srovę ir apkrovai perduodamą galią."; ...
    "Palyginti trijų rezistorių jungimų bendruosius ir atskirų elementų rodmenis."; ...
    "Ištirti nuosekliosios RLC grandinės srovę ir elementų įtampas keičiant dažnį."; ...
    "Ištirti lygiagrečiosios RLC grandinės šakų bei bendrąją sroves keičiant dažnį."; ...
    "Ištirti, kaip kompensuojančio kondensatoriaus talpa keičia srovę, reaktyviąją galią ir galios faktorių."; ...
    "Palyginti simetrinės trifazės apkrovos fazines ir linijines įtampas bei sroves žvaigždės ir trikampio jungimuose."];
    n=strtod(part(lab,3:length(lab)));text=goals(n);
endfunction
function lines=mo5_clean_analysis(lines)
    out=emptystr(0,1);
    for k=1:size(lines,"*")
        s=mo_public_text(lines(k));
        if ~isempty(strindex(s,"AUTOMATINĖ ANALIZĖ")) | ~isempty(strindex(s,"Visos čia nurodytos srovės")) | ~isempty(strindex(s,"Ataskaitos įtampos ir srovės yra")) then continue;end
        pairs=["Programa apskaičiavo: " "";"Programa apskaičiavo " "Apskaičiuota ";"Programos apskaičiuotas " "";"programos apskaičiuotos " "";"programos apskaičiuota " "";"Programa iš prietaisų rodmenų apskaičiavo vidutines varžas: " "Vidutinės varžos: ";"Iš nuoseklaus jungimo rodmenų programa apskaičiavo " "Nuoseklaus jungimo varža: ";"Tai programos apskaičiuoti dydžiai, ne papildomi perrašomi rodmenys." "";"Šis pokytis yra apskaičiuotas dydis, ne atskiras prietaiso rodmuo." "";"Visas šis palyginimas parengtas programoje; studentas skaičiuojamų dydžių neįvedė." "";"Programa keitė tik " "Keista tik ";"Lygiagretaus jungimo programos apskaičiuota " "Lygiagretaus jungimo "];
        extra=["Programos apskaičiuota " "";"Programos apskaičiuotos " "";"Programa apskaičiavo, kad " "";"Studentui šio skirtumo skaičiuoti nereikėjo." "";"automatiškai nustatyta " "nustatyta ";"Tai apskaičiuoti dydžiai, ne papildomi prietaisų rodmenys." "";"Tai apskaičiuoti šaltinių dydžiai, ne papildomi prietaisų rodmenys; apkrovos rodmenis taip pat veikia vidinės varžos." "Apkrovos rodmenis taip pat veikia vidinės varžos."];
        pairs=[pairs;extra];for j=1:size(pairs,1);s=strsubst(s,pairs(j,1),pairs(j,2));end
        s=stripblanks(s);if s<>"" then s=convstr(part(s,1),"u")+part(s,2:length(s));out($+1,1)=s;end
    end
    lines=out;
endfunction
function [lead,cards]=mo5_result(lab,cfg,r)
    cards=emptystr(0,3);lead="";
    select lab
    case "LD1" then
        a=mo5_value(r,1,"I_series");b=mo5_value(r,2,"I_series");main=mo5_value(r,5,"I_main");sumI=mo5_value(r,6,"I_R3")+mo5_value(r,7,"I_R2");
        lead="Sumažinus varžą srovė padidėjo. Šakotoje grandinėje bendroji srovė sutapo su abiejų šakų srovių suma.";
        cards=["VR1 = 1000 Ω" mo_report_number(a)+" mA" "Nuoseklioji grandinė";"VR1 = 500 Ω" mo_report_number(b)+" mA" "Nuoseklioji grandinė";"Bendroji srovė" mo_report_number(main)+" mA" "Šakų suma: "+mo_report_number(sumI)+" mA"];
    case "LD2" then
        current=mo5_value(r,8,"I_RLC");freq=r(8).trial.x;ul=mo5_value(r,10,"U_RLC_L");uc=mo5_value(r,11,"U_RLC_C");
        lead="RLC grandinės srovė didžiausia ties rezonansu. Atskiros ritės ir kondensatoriaus įtampos didelės, tačiau bendroji jų įtampa maža.";
        cards=["Rezonanso dažnis" mo_report_number(freq)+" Hz" "Iš trijų dažnio taškų";"Srovė ties rezonansu" mo_report_number(current)+" mA" "Ampermetro rodmuo";"Ritė ir kondensatorius" mo_report_number(ul)+" / "+mo_report_number(uc)+" V" "UL / UC ties rezonansu"];
    case "LD3" then
        u=mo5_values(r,1:3,"U");i=mo5_values(r,1:3,"I");res=mean(1000*u./i);
        lead="Padidinus įtampą "+mo_report_number(u(3)/u(1))+" karto, to paties rezistoriaus srovė taip pat padidėjo "+mo_report_number(i(3)/i(1))+" karto.";
        cards=["Pirmas bandymas" mo_report_number(i(1))+" mA" "U = "+mo_report_number(u(1))+" V";"Trečias bandymas" mo_report_number(i(3))+" mA" "U = "+mo_report_number(u(3))+" V";"R = U / I" mo_report_number(res)+" Ω" "Trijų bandymų vidurkis"];
    case "LD4" then
        r1=mean(1000*mo5_values(r,1:3,"U")./mo5_values(r,1:3,"I"));r2=mean(1000*mo5_values(r,4:6,"U")./mo5_values(r,4:6,"I"));rs=1000*mo5_value(r,7,"U")/mo5_value(r,7,"I");
        lead="Abiejų rezistorių srovė didėjo proporcingai įtampai. Nuoseklaus jungimo varža sutapo su atskirų varžų suma.";
        cards=["Rezistorius R1" mo_report_number(r1)+" Ω" "R = U / I, trijų taškų vidurkis";"Rezistorius R2" mo_report_number(r2)+" Ω" "R = U / I, trijų taškų vidurkis";"Nuoseklus jungimas" mo_report_number(rs)+" Ω" "R1 + R2 = "+mo_report_number(r1+r2)+" Ω"];
    case "LD5" then
        a=mo5_value(r,1,"U");b=mo5_value(r,3,"U");lead="Keičiant potenciometro padėtį pasikeitė išėjimo įtampa; šaltinis ir grandinės sujungimas išliko tie patys.";
        cards=["Pirma padėtis" mo_report_number(a)+" V" "Išėjimo įtampa";"Trečia padėtis" mo_report_number(b)+" V" "Išėjimo įtampa";"Įtampos pokytis" mo_report_number(b-a)+" V" "U3 − U1"];
    case "LD6" then
        lead="Šaltinių jungimo būdas pakeitė apkrovos įtampą ir srovę. Suderinto ir priešpriešinio jungimo poveikiai skirtingi.";
        cards=["Suderintas jungimas" mo_report_number(mo5_value(r,2,"U"))+" V" "Apkrovos įtampa";"Priešpriešinis jungimas" mo_report_number(mo5_value(r,3,"U"))+" V" "Apkrovos įtampa";"Lygiagretus jungimas" mo_report_number(mo5_value(r,4,"U"))+" V" "Apkrovos įtampa"];
    case "LD7" then
        p=mo5_values(r,1:5,"U").*mo5_values(r,1:5,"I");[peak,k]=max(p);lead="Didžiausia apkrovai perduodama galia gauta ties apkrova, artima šaltinio vidinei varžai.";
        cards=["Didžiausia galia" mo_report_number(peak)+" mW" "R = "+mo_report_number(r(k).trial.x)+" Ω";"Tuščioji eiga" mo_report_number(mo5_value(r,6,"U0"))+" V" "Voltmetro rodmuo";"Trumpasis jungimas" mo_report_number(mo5_value(r,7,"Ik"))+" mA" "Srovę riboja šaltinio vidinė varža"];
    case "LD8" then
        idx=[1 5 9];i=mo5_values(r,idx,"I");lead="Nuosekliame jungime srovė mažiausia, lygiagrečiame – didžiausia. Elementų rodmenys parodo, kaip pasidalija įtampa ir srovė.";
        cards=["Nuosekliai" mo_report_number(i(1))+" mA" "Bendroji srovė";"Lygiagrečiai" mo_report_number(i(2))+" mA" "Bendroji srovė";"Mišriai" mo_report_number(i(3))+" mA" "Bendroji srovė"];
    case "LD9" then
        lead="Nuosekliosios RLC grandinės srovė didžiausia ties rezonansu, kai ritės ir kondensatoriaus įtampų poveikiai kompensuojasi.";
        cards=["Rezonansas" mo_report_number(r(5).trial.x)+" Hz" "Vidurinis dažnio taškas";"Rezonanso srovė" mo_report_number(mo5_value(r,5,"I"))+" mA" "Ampermetro rodmuo";"UL / UC ties rezonansu" mo_report_number(mo5_value(r,6,"UL"))+" / "+mo_report_number(mo5_value(r,7,"UC"))+" V" "Elementų įtampos"];
    case "LD10" then
        lead="Lygiagrečioje RLC grandinėje ties rezonansu ritės ir kondensatoriaus šakų srovės kompensuojasi, todėl bendroji srovė mažiausia.";
        cards=["Rezonansas" mo_report_number(r(5).trial.x)+" Hz" "Vidurinis dažnio taškas";"Bendroji srovė" mo_report_number(mo5_value(r,8,"I"))+" mA" "Ties rezonansu";"IL / IC ties rezonansu" mo_report_number(mo5_value(r,6,"IL"))+" / "+mo_report_number(mo5_value(r,7,"IC"))+" mA" "Šakų srovės"];
    case "LD11" then
        i=mo5_values(r,1:length(r),"I");u=mo5_values(r,1:length(r),"U");p=mo5_values(r,1:length(r),"P");cosines=p./(u.*i);[best,k]=max(cosines);lead="Tinkama kondensatoriaus talpa sumažino bendrąją srovę ir pagerino galios faktorių. Per didelė talpa sukėlė perteklinį kompensavimą.";
        cards=["Be kondensatoriaus" mo_report_number(i(1))+" mA" "Pradinė srovė";"Geriausias cos φ" mo_report_number(best) "C = "+mo_report_number(r(k).trial.x)+" µF";"Mažiausia srovė" mo_report_number(min(i))+" mA" "Iš keturių talpos taškų"];
    case "LD12" then
        lead="Trikampio jungime kiekvienam imtuvui tenka didesnė įtampa. Esant tai pačiai linijinei įtampai, linijinė srovė didesnė nei žvaigždės jungime.";
        cards=["Žvaigždės Il" mo_report_number(mo5_value(r,2,"Il"))+" mA" "Linijinė srovė";"Trikampio Il" mo_report_number(mo5_value(r,4,"Il"))+" mA" "Linijinė srovė";"Linijinių srovių santykis" mo_report_number(mo5_value(r,4,"Il")/mo5_value(r,2,"Il"))+" karto" "IlΔ / IlY"];
    end
endfunction
function same=mo5_same(a,b)
    same=%f;
    if typeof(a)=="st" & typeof(b)=="st" then
        names=fieldnames(b);if size(fieldnames(a),"*")<>size(names,"*") then return;end
        for k=1:size(names,"*");key=names(k);if ~isfield(a,key) then return;end;if ~mo5_same(a(key),b(key)) then return;end;end
        same=%t;return;
    end
    if size(a,"*")<>size(b,"*") then return;end
    if type(b)==1 then
        if type(a)<>1 then return;end
        aa=matrix(a,-1,1);bb=matrix(b,-1,1);if or(isnan(aa)) | or(isinf(aa)) then return;end
        same=and(abs(aa-bb)<=1d-9*max(1,max(abs(bb))));return;
    end
    if type(a)<>type(b) then return;end
    same=and(matrix(a,-1,1)==matrix(b,-1,1));
endfunction
function r=mo5_known_reading(lab,cfg,t,wires)
    execstr("global "+lab+"; savedState="+lab+";");
    try r=mo_measure(lab,cfg,t,wires);
    catch err=lasterror();execstr(lab+"=savedState;");error(strcat(err," "));end
    execstr(lab+"=savedState;");
endfunction
function payload=mo_report_payload(s)
    payload=struct("schema_version",5,"report_type","physical-measurement-report-v5", ...
        "protocol_revision","physical-instruments-v5.1","lab_id",s.protocol.lab,"lab_title",s.protocol.title, ...
        "student",s.student,"configuration",s.cfg,"expected_trials",length(s.protocol.trials),"records",s.records, ...
        "display_format","fixed-2","analysis_author","program","student_actions","connect_wires_and_copy_instrument_reading");
    payload.submission_id=bench_id();payload.created_at=payload.submission_id;
    if isfield(s,"sessionId") then payload.submission_id=s.sessionId;end
    if isfield(s,"createdAt") then payload.created_at=s.createdAt;end
    payload.exported_at=bench_id();payload.presentation_revision=6;
    if isfield(s,"helpUsed") then payload.help_used=s.helpUsed;else payload.help_used=%f;end
    if isfield(s,"wiringErrors") then payload.wiring_corrections=s.wiringErrors;end
    if isfield(s,"copyErrors") then payload.copy_corrections=s.copyErrors;end
    if isfield(s,"events") then payload.events=s.events;else payload.events=list();end
endfunction
function [ok,why,stats]=mo_report_verify(p)
    ok=%f;why="";stats=struct("trials",0,"readings",0,"copies",0,"wiring",0,"category","invalid","model_verified",%f);
    try
        if ~or(p.lab_id==["LD1" "LD2" "LD3" "LD4" "LD5" "LD6" "LD7" "LD8" "LD9" "LD10" "LD11" "LD12"]) then error("Neatpažintas laboratorinis darbas.");end
        if p.student.name=="" | p.student.group=="" | p.student.number<1 | p.student.number>64 | floor(p.student.number)<>p.student.number then error("Netinkami studento duomenys.");end
        cfg=mo_config(p.lab_id,p.student.number);if ~mo5_same(p.configuration,cfg) then error("Parametrai neatitinka nurodyto varianto.");end
        records=mo_record_list(p.records);legacy=(p.schema_version==3);
        if ~legacy then
            if p.schema_version<>5 | p.report_type<>"physical-measurement-report-v5" | p.protocol_revision<>"physical-instruments-v5.1" then error("Nepalaikoma ataskaitos versija.");end
            protocol=mo_protocol(p.lab_id,cfg);
            if length(records)<>length(protocol.trials) | p.expected_trials<>length(protocol.trials) then error("Neatlikti visi šios darbo versijos bandymai.");end
        else
            if p.report_type<>"measurement-only-v3" then error("Neatpažintas ankstesnis formatas.");end
            if length(records)<1 | length(records)<>p.expected_trials then error("Nepilna ankstesnio darbo ataskaita.");end
        end
        format="significant-4";if isfield(p,"display_format") then format=p.display_format;end
        if ~or(format==["fixed-2" "significant-4"]) then error("Neatpažintas ekrano tikslumas.");end
        if ~legacy & format<>"fixed-2" then error("Šios versijos ekrano tikslumas netinkamas.");end
        for k=1:length(records)
            rec=records(k);r=rec.reading;n=size(r.values,"*");
            if n<1 | size(r.ids,"*")<>n | size(r.units,"*")<>n | size(r.names,"*")<>n | size(rec.copied,"*")<>n | size(rec.displayed,"*")<>n then error("Nepilnas matavimo įrašas.");end
            expected=r;
            if ~legacy then
                t=protocol.trials(k);
                if ~mo5_same(mo_public_trial(rec.trial),t) then error("Bandymo sąlygos ir aprašas neatitinka žinomo protokolo.");end
                if ~mo_wires_equal(rec.wires,t.wires) | ~mo_wires_equal(rec.trial.wires,t.wires) then error("Sujungimai neatitinka žinomos bandymo schemos.");end
                expected=mo5_known_reading(p.lab_id,cfg,t,rec.wires);
                if ~and(matrix(r.ids,-1,1)==matrix(expected.ids,-1,1)) | ~and(matrix(r.units,-1,1)==matrix(expected.units,-1,1)) | ~and(matrix(mo_public_text(r.names),-1,1)==matrix(expected.names,-1,1)) then error("Matavimo dydžiai neatitinka bandymo.");end
                if ~mo5_same(r.values,expected.values) then error("Prietaiso rodmuo neatitinka nurodyto varianto ir grandinės.");end
                if isfield(expected,"wave") then
                    if ~isfield(r,"wave") then error("Trūksta signalų modelio duomenų.");end
                    if ~mo5_same(r.wave,expected.wave) then error("Signalų duomenys neatitinka to paties matavimo modelio.");end
                end
            elseif ~mo_wires_equal(rec.wires,rec.trial.wires) then error("Nenuoseklus ankstesnis sujungimo įrašas.");end
            for j=1:n
                v=expected.values(j);if ~isreal(v) | isnan(v) | isinf(v) then error("Netinkamas skaitinis rodmuo.");end
                shown=msprintf("%.2f",v);if format=="significant-4" then shown=msprintf("%.4g",v);end
                if ~mo_copy_matches(rec.displayed(j),shown) then error("Ekrano rodmuo neatitinka modelio ir apvalinimo.");end
                if ~mo_copy_matches(rec.copied(j),shown) then error("Perrašytas skaičius neatitinka prietaiso rodmens.");end
                stats.readings=stats.readings+1;stats.copies=stats.copies+1;
            end
            stats.trials=stats.trials+1;stats.wiring=stats.wiring+1;
        end
        if legacy then
            stats.category="legacy";why="Ankstesnė darbo eiga. Išsaugota "+string(stats.trials)+" bandymų; naujos versijos apimtis netaikoma.";return;
        end
        if isfield(p,"events") then
            events=mo_record_list(p.events);last=0;copyEvents=0;wireEvents=0;helpEvents=0;
            for j=1:length(events)
                e=events(j);if e.sequence<=last | floor(e.sequence)<>e.sequence then error("Nenuosekli veiksmų istorija.");end
                if type(e.action)<>10 | type(e.detail)<>10 | length(e.detail)>4096 then error("Netinkamas veiksmų istorijos įrašas.");end
                if e.action=="reading_correction" then copyEvents=copyEvents+1;end
                if e.action=="wire_rejected" then wireEvents=wireEvents+1;end
                if e.action=="help_opened" then helpEvents=helpEvents+1;end
                last=e.sequence;
            end
            for key=["copy_corrections" "wiring_corrections"]
                if isfield(p,key) then
                    v=p(key);if type(v)<>1 | size(v,"*")<>1 then error("Netinkamas taisymų skaičius.");end
                    if isnan(v) | isinf(v) | v<0 | floor(v)<>v then error("Netinkamas taisymų skaičius.");end
                    nEvents=copyEvents;if key=="wiring_corrections" then nEvents=wireEvents;end
                    if length(events)>0 & v<>nEvents then error("Taisymų skaičius neatitinka užfiksuotų veiksmų.");end
                end
            end
            if helpEvents>0 then if ~p.help_used then error("Pagalbos žyma neatitinka veiksmų istorijos.");end;end
        end
        ok=%t;stats.category="valid";stats.model_verified=%t;why="Patikrinti visi bandymai, jų sujungimai, modelio rodmenys ir perrašyti skaičiai.";
    catch why=strcat(lasterror()," ");end
endfunction
function h=mo5_measurement_table(records)
    h="<div class=""scroll""><table><thead><tr><th>Bandymas</th><th>Dydis</th><th>Rodmuo</th></tr></thead><tbody>";
    for k=1:length(records)
        rec=records(k);r=rec.reading;
        for j=1:size(r.values,"*")
            h=h+"<tr><td>"+string(k)+". "+mo_html(mo_public_text(rec.trial.title))+"<div class=""condition"">"+mo_html(mo_public_text(rec.trial.condition))+"</div></td><td>"+mo_html(mo_public_text(r.names(j)))+"</td><td class=""number"">"+mo_html(rec.displayed(j)+" "+r.units(j))+"</td></tr>";
        end
    end
    h=h+"</tbody></table></div>";
endfunction
function h=mo5_compare(records)
    h="<details class=""no-print""><summary>Palyginti du bandymus</summary><div class=""controls"" style=""margin-top:12px""><label>Pirmas <select data-compare-a>";
    for k=1:length(records);h=h+"<option value="""+string(k-1)+""">"+mo_html(records(k).trial.title)+"</option>";end
    h=h+"</select></label><label>Antras <select data-compare-b>";
    for k=1:length(records)
        selected="";if k==min(2,length(records)) then selected=" selected";end
        h=h+"<option value="""+string(k-1)+""""+selected+">"+mo_html(records(k).trial.title)+"</option>";
    end
    h=h+"</select></label></div><div class=""comparison-output"" data-compare-output></div></details>";
endfunction
function html=mo5_student_html(s,payload)
    p=s.protocol;r=s.records;cfg=s.cfg;[lead,cards]=mo5_result(p.lab,cfg,r);analysis=mo_analysis(p.lab,cfg,r);analysis=mo5_clean_analysis(analysis);
    html="<!doctype html><html lang=""lt""><head><meta charset=""utf-8""><meta name=""viewport"" content=""width=device-width,initial-scale=1""><title>"+mo_html(p.lab+" · "+p.title)+"</title><style>"+mo_report_style()+".print-legend{display:none}@media print{.print-legend{display:block;font-size:11px}}"+"</style></head><body><main><header><div class=""eyebrow"">Laboratorinio darbo ataskaita · "+p.lab+"</div><h1>"+mo_html(p.title)+"</h1><div class=""meta""><span>"+mo_html(s.student.name)+"</span><span>"+mo_html(s.student.group)+"</span><span>Sąrašo nr. "+string(s.student.number)+"</span><span>"+string(length(r))+" bandymų</span></div><div class=""toolbar""><a href=""#matavimai"" class=""button no-print"">Matavimų lentelė</a><button type=""button"" class=""no-print"" data-print>Spausdinti / PDF</button></div></header><div class=""content""><p class=""lead"">"+mo_html(lead)+"</p><div class=""stats"">";
    for k=1:size(cards,1);html=html+"<div class=""stat""><small>"+mo_html(cards(k,1))+"</small><strong>"+mo_html(cards(k,2))+"</strong><span>"+mo_html(cards(k,3))+"</span></div>";end
    html=html+"</div><section class=""section""><h2>Darbo tikslas</h2><p>"+mo_html(mo5_goal(p.lab))+"</p></section>"+mo6_dc_visual(p.lab,cfg,r)+mo6_late_visual(p.lab,cfg,r)+"<section class=""section""><h2>Rezultatų grafikai</h2>"+mo_report_charts(p,r,cfg)+"</section>"+mo5_ac_visuals(p.lab,cfg,r);
    html=html+"<section class=""section"" id=""matavimai""><h2>Matavimų lentelė</h2>"+mo5_measurement_table(r)+mo5_compare(r)+"</section><section class=""section""><h2>Rezultatų paaiškinimas ir išvados</h2><ol class=""conclusions"">";
    for k=1:size(analysis,"*");html=html+"<li>"+mo_html(analysis(k))+"</li>";end
    html=html+"</ol></section><details><summary>Sujungimų įrašai</summary>";
    for k=1:length(r)
        html=html+"<p><strong>"+string(k)+". "+mo_html(r(k).trial.title)+"</strong><br>";
        for j=1:size(r(k).wires,1);html=html+mo_html(r(k).wires(j,1)+" ↔ "+r(k).wires(j,2))+"; ";end
        html=html+"</p>";
    end
    html=html+"</details></div><footer>"+mo_html(p.lab+" · "+s.student.group+" · "+s.student.name)+" · Rodmenys lentelėje pateikti prietaisų ekrano tikslumu.<br>Ataskaitos ID: "+mo_html(payload.submission_id)+"</footer><script id=""mo-data"" type=""application/json"">"+mo5_json(payload)+"</script></main><script>"+mo5_student_script()+"</script></body></html>";
endfunction
function path=mo_export_report(s)
    if isfield(s,"reportPath") then
        if s.reportPath<>"" then if isfile(s.reportPath) then path=s.reportPath;return;end;end
    end
    payload=mo_report_payload(s);[ok,why,stats]=mo_report_verify(payload);if ~ok then error("Ataskaita neparengta: "+why);end
    html=mo5_student_html(s,payload);folder=fullfile(bench_documents(),"Grandiniu_ataskaitos");
    if isfield(s,"reportFolder") then if s.reportFolder<>"" then folder=s.reportFolder;end;end
    if ~isdir(folder) then [ok,msg]=mkdir(folder);if ~ok then error("Nepavyko sukurti ataskaitų aplanko: "+msg);end;end
    path=fullfile(folder,s.protocol.lab+"-V"+msprintf("%02d",s.student.number)+"-ataskaita-"+bench_id()+".html");
    bench_write_new(path,html);
    [kind,saved,why]=mo_read_report(path);if kind<>1 then error("Nepavyko perskaityti išsaugotos ataskaitos: "+path);end
    [ok,why,stats]=mo_report_verify(saved);if ~ok then error("Nepavyko patikrinti išsaugotos ataskaitos: "+why);end
endfunction
function [kind,p,why]=mo_read_report(path)
    kind=0;p=[];why="";
    try
        contents=strcat(mgetl(path),ascii(10));marker="<script id=""mo-data"" type=""application/json"">";start=strindex(contents,marker);if isempty(start) then return;end
        kind=2;if size(start,"*")<>1 then error("Ataskaitoje keli duomenų blokai.");end
        tail=part(contents,start(1)+length(marker):length(contents));finish=strindex(tail,"</script>");if isempty(finish) then error("Neužbaigtas duomenų blokas.");end
        raw=part(tail,1:finish(1)-1);if ~mo_json_safe(raw) then error("Sugadinti JSON duomenys.");end
        p=fromJSON(raw);kind=1;
    catch kind=2;why=strcat(lasterror()," ");end
endfunction

function s=mo_report_style()
    s=ascii([ ...
        58 114 111 111 116 123 102 111 110 116 45 102 97 109 105 108 121 58 73 110 116 101 114 44 65 114 105 97 108 44 115 97 110 115 45 115 101 114 105 102 59 99 111 108 111 114 58 35 49 55 51 51 51 56 59 98 97 99 107 103 114 111 117 110 100 58 35 101 100 102 50 102 49 59 102 111 110 116 45 115 ...
        121 110 116 104 101 115 105 115 58 110 111 110 101 59 45 45 103 114 101 101 110 58 35 48 55 53 101 53 50 59 45 45 108 105 110 101 58 35 100 99 101 53 101 50 59 45 45 109 117 116 101 100 58 35 54 49 55 54 55 48 125 42 123 98 111 120 45 115 105 122 105 110 103 58 98 111 114 100 101 114 ...
        45 98 111 120 125 98 111 100 121 123 109 97 114 103 105 110 58 48 59 102 111 110 116 45 115 105 122 101 58 49 53 112 120 59 108 105 110 101 45 104 101 105 103 104 116 58 49 46 53 53 125 109 97 105 110 123 109 97 120 45 119 105 100 116 104 58 49 49 56 48 112 120 59 109 97 114 103 105 110 58 ...
        51 50 112 120 32 97 117 116 111 59 98 97 99 107 103 114 111 117 110 100 58 35 102 102 102 59 98 111 114 100 101 114 58 49 112 120 32 115 111 108 105 100 32 118 97 114 40 45 45 108 105 110 101 41 59 98 111 114 100 101 114 45 114 97 100 105 117 115 58 49 56 112 120 59 111 118 101 114 102 108 ...
        111 119 58 104 105 100 100 101 110 59 98 111 120 45 115 104 97 100 111 119 58 48 32 49 50 112 120 32 52 53 112 120 32 35 49 56 51 102 51 53 49 48 125 104 101 97 100 101 114 123 112 97 100 100 105 110 103 58 51 56 112 120 32 52 54 112 120 59 98 111 114 100 101 114 45 98 111 116 116 111 ...
        109 58 49 112 120 32 115 111 108 105 100 32 118 97 114 40 45 45 108 105 110 101 41 125 46 101 121 101 98 114 111 119 123 116 101 120 116 45 116 114 97 110 115 102 111 114 109 58 117 112 112 101 114 99 97 115 101 59 108 101 116 116 101 114 45 115 112 97 99 105 110 103 58 46 49 53 101 109 59 102 ...
        111 110 116 45 115 105 122 101 58 49 49 112 120 59 102 111 110 116 45 119 101 105 103 104 116 58 56 48 48 59 99 111 108 111 114 58 118 97 114 40 45 45 103 114 101 101 110 41 125 104 49 123 102 111 110 116 45 115 105 122 101 58 51 50 112 120 59 108 105 110 101 45 104 101 105 103 104 116 58 49 ...
        46 50 59 108 101 116 116 101 114 45 115 112 97 99 105 110 103 58 45 46 48 51 53 101 109 59 109 97 114 103 105 110 58 49 51 112 120 32 48 125 104 50 123 102 111 110 116 45 115 105 122 101 58 50 51 112 120 59 108 101 116 116 101 114 45 115 112 97 99 105 110 103 58 45 46 48 50 53 101 109 ...
        59 109 97 114 103 105 110 58 48 32 48 32 49 56 112 120 125 104 51 123 102 111 110 116 45 115 105 122 101 58 49 54 112 120 59 109 97 114 103 105 110 58 48 32 48 32 49 50 112 120 125 112 123 109 97 114 103 105 110 58 57 112 120 32 48 59 109 97 120 45 119 105 100 116 104 58 57 48 99 104 ...
        125 46 109 101 116 97 123 100 105 115 112 108 97 121 58 102 108 101 120 59 102 108 101 120 45 119 114 97 112 58 119 114 97 112 59 103 97 112 58 56 112 120 32 50 50 112 120 59 99 111 108 111 114 58 118 97 114 40 45 45 109 117 116 101 100 41 59 102 111 110 116 45 115 105 122 101 58 49 51 112 ...
        120 125 46 99 111 110 116 101 110 116 123 112 97 100 100 105 110 103 58 48 32 52 54 112 120 32 51 54 112 120 125 46 115 101 99 116 105 111 110 123 112 97 100 100 105 110 103 45 116 111 112 58 51 50 112 120 125 46 108 101 97 100 123 98 97 99 107 103 114 111 117 110 100 58 35 101 56 102 50 101 ...
        99 59 98 111 114 100 101 114 45 108 101 102 116 58 52 112 120 32 115 111 108 105 100 32 118 97 114 40 45 45 103 114 101 101 110 41 59 112 97 100 100 105 110 103 58 50 50 112 120 32 50 54 112 120 59 109 97 114 103 105 110 58 50 56 112 120 32 48 32 49 50 112 120 59 98 111 114 100 101 114 ...
        45 114 97 100 105 117 115 58 48 32 49 48 112 120 32 49 48 112 120 32 48 59 102 111 110 116 45 115 105 122 101 58 49 56 112 120 59 102 111 110 116 45 119 101 105 103 104 116 58 54 48 48 59 108 105 110 101 45 104 101 105 103 104 116 58 49 46 54 125 46 115 116 97 116 115 123 100 105 115 112 ...
        108 97 121 58 103 114 105 100 59 103 114 105 100 45 116 101 109 112 108 97 116 101 45 99 111 108 117 109 110 115 58 114 101 112 101 97 116 40 97 117 116 111 45 102 105 116 44 109 105 110 109 97 120 40 49 56 48 112 120 44 49 102 114 41 41 59 103 97 112 58 49 50 112 120 59 109 97 114 103 105 ...
        110 58 49 56 112 120 32 48 125 46 115 116 97 116 123 98 111 114 100 101 114 58 49 112 120 32 115 111 108 105 100 32 118 97 114 40 45 45 108 105 110 101 41 59 98 111 114 100 101 114 45 114 97 100 105 117 115 58 49 48 112 120 59 112 97 100 100 105 110 103 58 49 54 112 120 125 46 115 116 97 ...
        116 32 115 109 97 108 108 123 100 105 115 112 108 97 121 58 98 108 111 99 107 59 99 111 108 111 114 58 118 97 114 40 45 45 109 117 116 101 100 41 59 102 111 110 116 45 115 105 122 101 58 49 49 112 120 59 116 101 120 116 45 116 114 97 110 115 102 111 114 109 58 117 112 112 101 114 99 97 115 101 ...
        59 108 101 116 116 101 114 45 115 112 97 99 105 110 103 58 46 48 53 101 109 125 46 115 116 97 116 32 115 116 114 111 110 103 123 100 105 115 112 108 97 121 58 98 108 111 99 107 59 102 111 110 116 45 115 105 122 101 58 50 51 112 120 59 108 101 116 116 101 114 45 115 112 97 99 105 110 103 58 45 ...
        46 48 51 101 109 59 109 97 114 103 105 110 45 116 111 112 58 53 112 120 125 46 115 116 97 116 32 115 112 97 110 123 102 111 110 116 45 115 105 122 101 58 49 50 112 120 59 99 111 108 111 114 58 118 97 114 40 45 45 109 117 116 101 100 41 125 46 99 104 97 114 116 123 98 111 114 100 101 114 58 ...
        49 112 120 32 115 111 108 105 100 32 118 97 114 40 45 45 108 105 110 101 41 59 98 111 114 100 101 114 45 114 97 100 105 117 115 58 49 50 112 120 59 109 97 114 103 105 110 58 49 54 112 120 32 48 59 111 118 101 114 102 108 111 119 58 104 105 100 100 101 110 59 98 114 101 97 107 45 105 110 115 ...
        105 100 101 58 97 118 111 105 100 125 46 99 104 97 114 116 45 104 101 97 100 123 112 97 100 100 105 110 103 58 49 57 112 120 32 50 50 112 120 32 48 125 46 99 104 97 114 116 32 115 118 103 123 100 105 115 112 108 97 121 58 98 108 111 99 107 59 119 105 100 116 104 58 49 48 48 37 59 104 101 ...
        105 103 104 116 58 97 117 116 111 59 98 97 99 107 103 114 111 117 110 100 58 119 104 105 116 101 59 102 111 110 116 45 102 97 109 105 108 121 58 65 114 105 97 108 44 115 97 110 115 45 115 101 114 105 102 125 46 99 104 97 114 116 32 115 118 103 32 116 101 120 116 123 102 105 108 108 58 35 53 50 ...
        54 97 54 52 125 46 108 101 103 101 110 100 123 100 105 115 112 108 97 121 58 102 108 101 120 59 103 97 112 58 55 112 120 59 102 108 101 120 45 119 114 97 112 58 119 114 97 112 59 109 97 114 103 105 110 58 49 48 112 120 32 48 32 49 112 120 125 98 117 116 116 111 110 44 115 101 108 101 99 116 ...
        44 105 110 112 117 116 123 102 111 110 116 58 105 110 104 101 114 105 116 125 98 117 116 116 111 110 44 46 98 117 116 116 111 110 123 99 117 114 115 111 114 58 112 111 105 110 116 101 114 59 98 111 114 100 101 114 58 49 112 120 32 115 111 108 105 100 32 35 99 102 100 100 100 55 59 98 97 99 107 103 ...
        114 111 117 110 100 58 35 102 102 102 59 99 111 108 111 114 58 35 49 98 53 49 52 53 59 98 111 114 100 101 114 45 114 97 100 105 117 115 58 55 112 120 59 112 97 100 100 105 110 103 58 56 112 120 32 49 51 112 120 59 102 111 110 116 45 115 105 122 101 58 49 50 112 120 59 102 111 110 116 45 ...
        119 101 105 103 104 116 58 54 53 48 125 98 117 116 116 111 110 58 104 111 118 101 114 123 98 97 99 107 103 114 111 117 110 100 58 35 102 48 102 54 102 50 125 98 117 116 116 111 110 58 102 111 99 117 115 45 118 105 115 105 98 108 101 44 115 101 108 101 99 116 58 102 111 99 117 115 45 118 105 115 ...
        105 98 108 101 123 111 117 116 108 105 110 101 58 51 112 120 32 115 111 108 105 100 32 35 100 98 97 57 50 50 59 111 117 116 108 105 110 101 45 111 102 102 115 101 116 58 50 112 120 125 46 108 101 103 101 110 100 32 98 117 116 116 111 110 58 98 101 102 111 114 101 123 99 111 110 116 101 110 116 58 ...
        39 39 59 100 105 115 112 108 97 121 58 105 110 108 105 110 101 45 98 108 111 99 107 59 98 97 99 107 103 114 111 117 110 100 58 118 97 114 40 45 45 115 101 114 105 101 115 45 99 111 108 111 114 41 59 119 105 100 116 104 58 49 51 112 120 59 104 101 105 103 104 116 58 51 112 120 59 109 97 114 ...
        103 105 110 58 48 32 55 112 120 32 51 112 120 32 48 125 46 108 101 103 101 110 100 32 98 117 116 116 111 110 91 97 114 105 97 45 112 114 101 115 115 101 100 61 102 97 108 115 101 93 123 111 112 97 99 105 116 121 58 46 52 125 46 111 102 102 123 100 105 115 112 108 97 121 58 110 111 110 101 33 ...
        105 109 112 111 114 116 97 110 116 125 46 99 104 97 114 116 45 110 111 116 101 44 46 115 109 97 108 108 123 102 111 110 116 45 115 105 122 101 58 49 50 112 120 59 99 111 108 111 114 58 118 97 114 40 45 45 109 117 116 101 100 41 125 46 99 104 97 114 116 45 110 111 116 101 123 112 97 100 100 105 ...
        110 103 58 48 32 50 50 112 120 32 49 54 112 120 125 46 99 111 110 116 114 111 108 115 123 100 105 115 112 108 97 121 58 102 108 101 120 59 103 97 112 58 49 48 112 120 59 102 108 101 120 45 119 114 97 112 58 119 114 97 112 59 97 108 105 103 110 45 105 116 101 109 115 58 99 101 110 116 101 114 ...
        125 46 99 111 110 116 114 111 108 115 32 115 101 108 101 99 116 44 46 102 105 108 116 101 114 115 32 105 110 112 117 116 44 46 102 105 108 116 101 114 115 32 115 101 108 101 99 116 123 112 97 100 100 105 110 103 58 56 112 120 32 49 48 112 120 59 98 111 114 100 101 114 58 49 112 120 32 115 111 108 ...
        105 100 32 35 99 102 100 100 100 55 59 98 111 114 100 101 114 45 114 97 100 105 117 115 58 54 112 120 59 98 97 99 107 103 114 111 117 110 100 58 35 102 102 102 59 99 111 108 111 114 58 35 49 55 51 51 51 56 59 109 97 120 45 119 105 100 116 104 58 51 54 48 112 120 125 46 116 111 111 108 ...
        98 97 114 123 100 105 115 112 108 97 121 58 102 108 101 120 59 106 117 115 116 105 102 121 45 99 111 110 116 101 110 116 58 115 112 97 99 101 45 98 101 116 119 101 101 110 59 103 97 112 58 49 50 112 120 59 97 108 105 103 110 45 105 116 101 109 115 58 99 101 110 116 101 114 59 109 97 114 103 105 ...
        110 45 116 111 112 58 49 56 112 120 125 46 115 99 114 111 108 108 123 111 118 101 114 102 108 111 119 45 120 58 97 117 116 111 59 98 111 114 100 101 114 58 49 112 120 32 115 111 108 105 100 32 118 97 114 40 45 45 108 105 110 101 41 59 98 111 114 100 101 114 45 114 97 100 105 117 115 58 57 112 ...
        120 125 116 97 98 108 101 123 119 105 100 116 104 58 49 48 48 37 59 98 111 114 100 101 114 45 99 111 108 108 97 112 115 101 58 99 111 108 108 97 112 115 101 59 102 111 110 116 45 115 105 122 101 58 49 51 112 120 125 116 104 44 116 100 123 112 97 100 100 105 110 103 58 49 49 112 120 32 49 51 ...
        112 120 59 116 101 120 116 45 97 108 105 103 110 58 108 101 102 116 59 98 111 114 100 101 114 45 98 111 116 116 111 109 58 49 112 120 32 115 111 108 105 100 32 118 97 114 40 45 45 108 105 110 101 41 59 118 101 114 116 105 99 97 108 45 97 108 105 103 110 58 116 111 112 125 116 104 123 98 97 99 ...
        107 103 114 111 117 110 100 58 35 102 48 102 53 102 50 59 99 111 108 111 114 58 35 52 50 53 101 53 51 59 102 111 110 116 45 115 105 122 101 58 49 49 112 120 59 116 101 120 116 45 116 114 97 110 115 102 111 114 109 58 117 112 112 101 114 99 97 115 101 59 108 101 116 116 101 114 45 115 112 97 ...
        99 105 110 103 58 46 48 52 101 109 125 116 98 111 100 121 32 116 114 58 108 97 115 116 45 99 104 105 108 100 32 116 100 123 98 111 114 100 101 114 45 98 111 116 116 111 109 58 48 125 116 98 111 100 121 32 116 114 58 104 111 118 101 114 123 98 97 99 107 103 114 111 117 110 100 58 35 102 53 102 ...
        56 102 54 125 46 99 111 110 100 105 116 105 111 110 123 102 111 110 116 45 115 105 122 101 58 49 49 112 120 59 99 111 108 111 114 58 118 97 114 40 45 45 109 117 116 101 100 41 125 46 110 117 109 98 101 114 123 102 111 110 116 45 118 97 114 105 97 110 116 45 110 117 109 101 114 105 99 58 116 97 ...
        98 117 108 97 114 45 110 117 109 115 59 119 104 105 116 101 45 115 112 97 99 101 58 110 111 119 114 97 112 59 102 111 110 116 45 119 101 105 103 104 116 58 54 53 48 125 46 99 111 110 99 108 117 115 105 111 110 115 123 112 97 100 100 105 110 103 45 108 101 102 116 58 50 50 112 120 125 46 99 111 ...
        110 99 108 117 115 105 111 110 115 32 108 105 123 112 97 100 100 105 110 103 58 53 112 120 32 48 125 46 109 101 116 104 111 100 123 100 105 115 112 108 97 121 58 103 114 105 100 59 103 114 105 100 45 116 101 109 112 108 97 116 101 45 99 111 108 117 109 110 115 58 114 101 112 101 97 116 40 97 117 116 ...
        111 45 102 105 116 44 109 105 110 109 97 120 40 50 52 48 112 120 44 49 102 114 41 41 59 103 97 112 58 49 50 112 120 125 46 109 101 116 104 111 100 32 100 105 118 123 112 97 100 100 105 110 103 58 49 53 112 120 32 49 55 112 120 59 98 97 99 107 103 114 111 117 110 100 58 35 102 53 102 55 ...
        102 53 59 98 111 114 100 101 114 45 114 97 100 105 117 115 58 57 112 120 125 46 109 101 116 104 111 100 32 115 116 114 111 110 103 123 102 111 110 116 45 115 105 122 101 58 49 50 112 120 125 46 109 101 116 104 111 100 32 112 123 102 111 110 116 45 115 105 122 101 58 49 50 112 120 59 99 111 108 111 ...
        114 58 118 97 114 40 45 45 109 117 116 101 100 41 125 100 101 116 97 105 108 115 123 109 97 114 103 105 110 58 49 54 112 120 32 48 59 112 97 100 100 105 110 103 58 49 51 112 120 32 49 55 112 120 59 98 111 114 100 101 114 58 49 112 120 32 115 111 108 105 100 32 118 97 114 40 45 45 108 105 ...
        110 101 41 59 98 111 114 100 101 114 45 114 97 100 105 117 115 58 56 112 120 125 115 117 109 109 97 114 121 123 99 117 114 115 111 114 58 112 111 105 110 116 101 114 59 102 111 110 116 45 115 105 122 101 58 49 51 112 120 59 102 111 110 116 45 119 101 105 103 104 116 58 54 53 48 59 99 111 108 111 ...
        114 58 118 97 114 40 45 45 103 114 101 101 110 41 125 102 111 111 116 101 114 123 112 97 100 100 105 110 103 58 50 48 112 120 32 52 54 112 120 59 98 111 114 100 101 114 45 116 111 112 58 49 112 120 32 115 111 108 105 100 32 118 97 114 40 45 45 108 105 110 101 41 59 99 111 108 111 114 58 118 ...
        97 114 40 45 45 109 117 116 101 100 41 59 102 111 110 116 45 115 105 122 101 58 49 49 112 120 125 46 112 108 111 116 45 99 111 110 116 114 111 108 115 123 112 97 100 100 105 110 103 58 49 54 112 120 32 48 32 48 125 46 99 111 109 112 97 114 105 115 111 110 45 111 117 116 112 117 116 123 109 97 ...
        114 103 105 110 58 49 50 112 120 32 48 59 112 97 100 100 105 110 103 58 49 50 112 120 59 98 97 99 107 103 114 111 117 110 100 58 35 102 48 102 53 102 50 59 98 111 114 100 101 114 45 114 97 100 105 117 115 58 55 112 120 125 46 116 111 111 108 116 105 112 123 112 111 115 105 116 105 111 110 58 ...
        102 105 120 101 100 59 122 45 105 110 100 101 120 58 49 48 48 48 59 112 111 105 110 116 101 114 45 101 118 101 110 116 115 58 110 111 110 101 59 112 97 100 100 105 110 103 58 56 112 120 32 49 49 112 120 59 98 97 99 107 103 114 111 117 110 100 58 35 49 53 51 98 51 50 59 99 111 108 111 114 ...
        58 119 104 105 116 101 59 98 111 114 100 101 114 45 114 97 100 105 117 115 58 54 112 120 59 102 111 110 116 45 115 105 122 101 58 49 50 112 120 59 109 97 120 45 119 105 100 116 104 58 51 48 48 112 120 59 98 111 120 45 115 104 97 100 111 119 58 48 32 51 112 120 32 49 50 112 120 32 35 48 ...
        48 48 51 125 46 119 97 118 101 45 116 97 98 115 123 109 97 114 103 105 110 45 98 111 116 116 111 109 58 49 52 112 120 125 46 119 97 118 101 45 112 97 110 101 108 123 112 97 100 100 105 110 103 45 116 111 112 58 51 112 120 125 46 102 105 108 116 101 114 115 123 100 105 115 112 108 97 121 58 102 ...
        108 101 120 59 103 97 112 58 49 48 112 120 59 102 108 101 120 45 119 114 97 112 58 119 114 97 112 59 97 108 105 103 110 45 105 116 101 109 115 58 99 101 110 116 101 114 59 109 97 114 103 105 110 58 49 56 112 120 32 48 125 46 109 97 116 114 105 120 32 116 104 58 102 105 114 115 116 45 99 104 ...
        105 108 100 44 46 109 97 116 114 105 120 32 116 100 58 102 105 114 115 116 45 99 104 105 108 100 123 112 111 115 105 116 105 111 110 58 115 116 105 99 107 121 59 108 101 102 116 58 48 59 98 97 99 107 103 114 111 117 110 100 58 35 102 102 102 59 122 45 105 110 100 101 120 58 49 59 109 105 110 45 ...
        119 105 100 116 104 58 49 54 48 112 120 125 46 109 97 116 114 105 120 32 116 104 58 102 105 114 115 116 45 99 104 105 108 100 123 98 97 99 107 103 114 111 117 110 100 58 35 102 48 102 53 102 50 125 46 109 97 116 114 105 120 32 116 100 123 116 101 120 116 45 97 108 105 103 110 58 99 101 110 116 ...
        101 114 59 112 97 100 100 105 110 103 58 57 112 120 32 54 112 120 125 46 109 97 116 114 105 120 32 116 100 58 102 105 114 115 116 45 99 104 105 108 100 123 116 101 120 116 45 97 108 105 103 110 58 108 101 102 116 125 46 109 97 116 114 105 120 32 98 117 116 116 111 110 123 102 111 110 116 45 115 105 ...
        122 101 58 49 49 112 120 59 109 105 110 45 119 105 100 116 104 58 53 50 112 120 59 112 97 100 100 105 110 103 58 54 112 120 125 46 112 97 115 115 123 98 97 99 107 103 114 111 117 110 100 58 35 101 48 102 50 101 55 59 99 111 108 111 114 58 35 49 50 53 99 51 101 125 46 102 97 105 108 123 ...
        98 97 99 107 103 114 111 117 110 100 58 35 102 102 102 48 100 56 59 99 111 108 111 114 58 35 56 56 53 57 49 97 125 46 101 109 112 116 121 123 99 111 108 111 114 58 35 97 50 97 102 97 56 59 102 111 110 116 45 115 105 122 101 58 49 50 112 120 125 46 98 97 100 103 101 123 112 97 100 100 ...
        105 110 103 58 51 112 120 32 55 112 120 59 98 111 114 100 101 114 45 114 97 100 105 117 115 58 49 48 112 120 59 102 111 110 116 45 115 105 122 101 58 49 49 112 120 59 102 111 110 116 45 119 101 105 103 104 116 58 55 48 48 125 46 109 111 100 97 108 45 98 97 99 107 100 114 111 112 123 112 111 ...
        115 105 116 105 111 110 58 102 105 120 101 100 59 105 110 115 101 116 58 48 59 98 97 99 107 103 114 111 117 110 100 58 35 48 97 50 52 49 57 97 56 59 122 45 105 110 100 101 120 58 57 48 48 59 100 105 115 112 108 97 121 58 102 108 101 120 59 97 108 105 103 110 45 105 116 101 109 115 58 102 ...
        108 101 120 45 115 116 97 114 116 59 106 117 115 116 105 102 121 45 99 111 110 116 101 110 116 58 99 101 110 116 101 114 59 112 97 100 100 105 110 103 58 50 56 112 120 59 111 118 101 114 102 108 111 119 58 97 117 116 111 125 46 109 111 100 97 108 123 98 97 99 107 103 114 111 117 110 100 58 35 102 ...
        102 102 59 98 111 114 100 101 114 45 114 97 100 105 117 115 58 49 52 112 120 59 109 97 120 45 119 105 100 116 104 58 49 48 54 48 112 120 59 119 105 100 116 104 58 49 48 48 37 59 112 97 100 100 105 110 103 58 50 54 112 120 125 46 109 111 100 97 108 45 104 101 97 100 123 100 105 115 112 108 ...
        97 121 58 102 108 101 120 59 106 117 115 116 105 102 121 45 99 111 110 116 101 110 116 58 115 112 97 99 101 45 98 101 116 119 101 101 110 59 103 97 112 58 50 48 112 120 125 46 104 105 115 116 111 114 121 123 100 105 115 112 108 97 121 58 103 114 105 100 59 103 97 112 58 49 48 112 120 59 109 97 ...
        114 103 105 110 58 49 53 112 120 32 48 125 46 104 105 115 116 111 114 121 32 97 114 116 105 99 108 101 123 112 97 100 100 105 110 103 58 49 53 112 120 59 98 111 114 100 101 114 58 49 112 120 32 115 111 108 105 100 32 118 97 114 40 45 45 108 105 110 101 41 59 98 111 114 100 101 114 45 114 97 ...
        100 105 117 115 58 57 112 120 125 46 104 105 115 116 111 114 121 32 97 114 116 105 99 108 101 32 112 123 102 111 110 116 45 115 105 122 101 58 49 50 112 120 59 99 111 108 111 114 58 118 97 114 40 45 45 109 117 116 101 100 41 125 46 101 118 101 110 116 45 116 97 98 108 101 123 102 111 110 116 45 ...
        115 105 122 101 58 49 49 112 120 125 46 110 111 45 112 114 105 110 116 123 100 105 115 112 108 97 121 58 98 108 111 99 107 125 64 109 101 100 105 97 40 109 97 120 45 119 105 100 116 104 58 55 48 48 112 120 41 123 109 97 105 110 123 109 97 114 103 105 110 58 48 59 98 111 114 100 101 114 45 114 ...
        97 100 105 117 115 58 48 59 98 111 114 100 101 114 58 48 125 104 101 97 100 101 114 44 46 99 111 110 116 101 110 116 123 112 97 100 100 105 110 103 58 50 52 112 120 32 50 48 112 120 125 102 111 111 116 101 114 123 112 97 100 100 105 110 103 58 49 56 112 120 32 50 48 112 120 125 104 49 123 102 ...
        111 110 116 45 115 105 122 101 58 50 55 112 120 125 46 108 101 97 100 123 102 111 110 116 45 115 105 122 101 58 49 54 112 120 59 112 97 100 100 105 110 103 58 49 56 112 120 125 46 109 111 100 97 108 45 98 97 99 107 100 114 111 112 123 112 97 100 100 105 110 103 58 56 112 120 125 46 109 111 100 ...
        97 108 123 112 97 100 100 105 110 103 58 49 55 112 120 125 46 116 111 111 108 98 97 114 123 97 108 105 103 110 45 105 116 101 109 115 58 102 108 101 120 45 115 116 97 114 116 125 46 99 104 97 114 116 45 104 101 97 100 123 112 97 100 100 105 110 103 58 49 52 112 120 32 49 52 112 120 32 48 125 ...
        46 108 101 103 101 110 100 32 98 117 116 116 111 110 123 112 97 100 100 105 110 103 58 54 112 120 32 56 112 120 125 125 64 109 101 100 105 97 32 112 114 105 110 116 123 98 111 100 121 123 98 97 99 107 103 114 111 117 110 100 58 119 104 105 116 101 125 109 97 105 110 123 109 97 120 45 119 105 100 116 ...
        104 58 110 111 110 101 59 109 97 114 103 105 110 58 48 59 98 111 114 100 101 114 58 48 59 98 111 120 45 115 104 97 100 111 119 58 110 111 110 101 125 104 101 97 100 101 114 44 46 99 111 110 116 101 110 116 123 112 97 100 100 105 110 103 45 108 101 102 116 58 48 59 112 97 100 100 105 110 103 45 ...
        114 105 103 104 116 58 48 125 104 101 97 100 101 114 123 112 97 100 100 105 110 103 45 116 111 112 58 48 125 46 110 111 45 112 114 105 110 116 44 46 99 111 110 116 114 111 108 115 44 46 108 101 103 101 110 100 44 46 102 105 108 116 101 114 115 44 46 116 111 111 108 98 97 114 32 98 117 116 116 111 ...
        110 44 46 116 111 111 108 116 105 112 123 100 105 115 112 108 97 121 58 110 111 110 101 33 105 109 112 111 114 116 97 110 116 125 46 111 102 102 123 100 105 115 112 108 97 121 58 98 108 111 99 107 33 105 109 112 111 114 116 97 110 116 125 46 99 104 97 114 116 123 98 114 101 97 107 45 105 110 115 105 ...
        100 101 58 97 118 111 105 100 125 104 50 44 104 51 123 98 114 101 97 107 45 97 102 116 101 114 58 97 118 111 105 100 125 102 111 111 116 101 114 123 112 97 100 100 105 110 103 45 108 101 102 116 58 48 59 112 97 100 100 105 110 103 45 114 105 103 104 116 58 48 125 46 109 111 100 97 108 45 98 97 ...
        99 107 100 114 111 112 123 112 111 115 105 116 105 111 110 58 115 116 97 116 105 99 59 112 97 100 100 105 110 103 58 48 59 98 97 99 107 103 114 111 117 110 100 58 119 104 105 116 101 125 46 109 111 100 97 108 123 109 97 120 45 119 105 100 116 104 58 110 111 110 101 59 112 97 100 100 105 110 103 58 ...
        48 125 46 109 97 116 114 105 120 32 116 104 58 102 105 114 115 116 45 99 104 105 108 100 44 46 109 97 116 114 105 120 32 116 100 58 102 105 114 115 116 45 99 104 105 108 100 123 112 111 115 105 116 105 111 110 58 115 116 97 116 105 99 125 46 115 99 114 111 108 108 123 111 118 101 114 102 108 111 119 ...
        58 118 105 115 105 98 108 101 125 116 97 98 108 101 123 102 111 110 116 45 115 105 122 101 58 49 48 112 120 125 125 10 ...
    ]);
endfunction

function s=mo5_student_script()
    s=ascii([ ...
        40 40 41 61 62 123 39 117 115 101 32 115 116 114 105 99 116 39 59 99 111 110 115 116 32 36 61 40 115 44 112 61 100 111 99 117 109 101 110 116 41 61 62 112 46 113 117 101 114 121 83 101 108 101 99 116 111 114 40 115 41 44 36 36 61 40 115 44 112 61 100 111 99 117 109 101 110 116 41 61 ...
        62 65 114 114 97 121 46 102 114 111 109 40 112 46 113 117 101 114 121 83 101 108 101 99 116 111 114 65 108 108 40 115 41 41 59 100 111 99 117 109 101 110 116 46 100 111 99 117 109 101 110 116 69 108 101 109 101 110 116 46 99 108 97 115 115 76 105 115 116 46 97 100 100 40 39 106 115 39 41 59 ...
        108 101 116 32 116 105 112 61 100 111 99 117 109 101 110 116 46 99 114 101 97 116 101 69 108 101 109 101 110 116 40 39 100 105 118 39 41 59 116 105 112 46 99 108 97 115 115 78 97 109 101 61 39 116 111 111 108 116 105 112 32 111 102 102 39 59 116 105 112 46 115 101 116 65 116 116 114 105 98 117 ...
        116 101 40 39 114 111 108 101 39 44 39 116 111 111 108 116 105 112 39 41 59 100 111 99 117 109 101 110 116 46 98 111 100 121 46 97 112 112 101 110 100 67 104 105 108 100 40 116 105 112 41 59 102 117 110 99 116 105 111 110 32 115 104 111 119 84 105 112 40 101 41 123 99 111 110 115 116 32 116 61 ...
        101 46 116 97 114 103 101 116 46 99 108 111 115 101 115 116 40 39 91 100 97 116 97 45 116 105 112 93 39 41 59 105 102 40 33 116 41 114 101 116 117 114 110 59 116 105 112 46 116 101 120 116 67 111 110 116 101 110 116 61 116 46 100 97 116 97 115 101 116 46 116 105 112 59 116 105 112 46 99 108 ...
        97 115 115 76 105 115 116 46 114 101 109 111 118 101 40 39 111 102 102 39 41 59 99 111 110 115 116 32 114 61 116 46 103 101 116 66 111 117 110 100 105 110 103 67 108 105 101 110 116 82 101 99 116 40 41 59 99 111 110 115 116 32 120 61 101 46 99 108 105 101 110 116 88 124 124 114 46 108 101 102 ...
        116 43 114 46 119 105 100 116 104 47 50 44 121 61 101 46 99 108 105 101 110 116 89 124 124 114 46 116 111 112 59 116 105 112 46 115 116 121 108 101 46 108 101 102 116 61 77 97 116 104 46 109 105 110 40 105 110 110 101 114 87 105 100 116 104 45 51 49 48 44 77 97 116 104 46 109 97 120 40 56 ...
        44 120 43 49 50 41 41 43 39 112 120 39 59 116 105 112 46 115 116 121 108 101 46 116 111 112 61 77 97 116 104 46 109 97 120 40 56 44 121 45 52 54 41 43 39 112 120 39 125 100 111 99 117 109 101 110 116 46 97 100 100 69 118 101 110 116 76 105 115 116 101 110 101 114 40 39 112 111 105 110 ...
        116 101 114 111 118 101 114 39 44 115 104 111 119 84 105 112 41 59 100 111 99 117 109 101 110 116 46 97 100 100 69 118 101 110 116 76 105 115 116 101 110 101 114 40 39 112 111 105 110 116 101 114 109 111 118 101 39 44 101 61 62 123 105 102 40 101 46 116 97 114 103 101 116 46 99 108 111 115 101 115 ...
        116 40 39 91 100 97 116 97 45 116 105 112 93 39 41 41 115 104 111 119 84 105 112 40 101 41 125 41 59 100 111 99 117 109 101 110 116 46 97 100 100 69 118 101 110 116 76 105 115 116 101 110 101 114 40 39 102 111 99 117 115 105 110 39 44 115 104 111 119 84 105 112 41 59 100 111 99 117 109 101 ...
        110 116 46 97 100 100 69 118 101 110 116 76 105 115 116 101 110 101 114 40 39 112 111 105 110 116 101 114 111 117 116 39 44 40 41 61 62 116 105 112 46 99 108 97 115 115 76 105 115 116 46 97 100 100 40 39 111 102 102 39 41 41 59 100 111 99 117 109 101 110 116 46 97 100 100 69 118 101 110 116 ...
        76 105 115 116 101 110 101 114 40 39 102 111 99 117 115 111 117 116 39 44 40 41 61 62 116 105 112 46 99 108 97 115 115 76 105 115 116 46 97 100 100 40 39 111 102 102 39 41 41 59 100 111 99 117 109 101 110 116 46 97 100 100 69 118 101 110 116 76 105 115 116 101 110 101 114 40 39 99 108 105 ...
        99 107 39 44 101 61 62 123 99 111 110 115 116 32 98 61 101 46 116 97 114 103 101 116 46 99 108 111 115 101 115 116 40 39 91 100 97 116 97 45 116 111 103 103 108 101 93 39 41 59 105 102 40 98 41 123 99 111 110 115 116 32 116 97 114 103 101 116 61 100 111 99 117 109 101 110 116 46 103 101 ...
        116 69 108 101 109 101 110 116 66 121 73 100 40 98 46 100 97 116 97 115 101 116 46 116 111 103 103 108 101 41 59 105 102 40 33 116 97 114 103 101 116 41 114 101 116 117 114 110 59 99 111 110 115 116 32 111 110 61 98 46 103 101 116 65 116 116 114 105 98 117 116 101 40 39 97 114 105 97 45 112 ...
        114 101 115 115 101 100 39 41 33 61 61 39 102 97 108 115 101 39 59 98 46 115 101 116 65 116 116 114 105 98 117 116 101 40 39 97 114 105 97 45 112 114 101 115 115 101 100 39 44 83 116 114 105 110 103 40 33 111 110 41 41 59 116 97 114 103 101 116 46 99 108 97 115 115 76 105 115 116 46 116 ...
        111 103 103 108 101 40 39 111 102 102 39 44 111 110 41 125 105 102 40 101 46 116 97 114 103 101 116 46 99 108 111 115 101 115 116 40 39 91 100 97 116 97 45 112 114 105 110 116 93 39 41 41 119 105 110 100 111 119 46 112 114 105 110 116 40 41 125 41 59 36 36 40 39 91 100 97 116 97 45 119 ...
        97 118 101 45 115 101 108 101 99 116 93 39 41 46 102 111 114 69 97 99 104 40 115 61 62 123 99 111 110 115 116 32 117 112 100 97 116 101 61 40 41 61 62 123 36 36 40 39 46 119 97 118 101 45 112 97 110 101 108 39 44 115 46 99 108 111 115 101 115 116 40 39 46 97 99 45 118 105 115 117 ...
        97 108 115 39 41 41 46 102 111 114 69 97 99 104 40 112 61 62 112 46 99 108 97 115 115 76 105 115 116 46 116 111 103 103 108 101 40 39 111 102 102 39 44 112 46 105 100 33 61 61 115 46 118 97 108 117 101 41 41 125 59 115 46 97 100 100 69 118 101 110 116 76 105 115 116 101 110 101 114 40 ...
        39 99 104 97 110 103 101 39 44 117 112 100 97 116 101 41 59 117 112 100 97 116 101 40 41 125 41 59 99 111 110 115 116 32 100 97 116 97 61 36 40 39 35 109 111 45 100 97 116 97 39 41 59 105 102 40 33 100 97 116 97 41 114 101 116 117 114 110 59 108 101 116 32 112 59 116 114 121 123 112 ...
        61 74 83 79 78 46 112 97 114 115 101 40 100 97 116 97 46 116 101 120 116 67 111 110 116 101 110 116 41 125 99 97 116 99 104 123 114 101 116 117 114 110 125 99 111 110 115 116 32 102 108 97 116 61 120 61 62 65 114 114 97 121 46 105 115 65 114 114 97 121 40 120 41 63 120 46 102 108 97 116 ...
        40 73 110 102 105 110 105 116 121 41 58 91 120 93 59 99 111 110 115 116 32 114 101 99 111 114 100 115 61 65 114 114 97 121 46 105 115 65 114 114 97 121 40 112 46 114 101 99 111 114 100 115 41 63 112 46 114 101 99 111 114 100 115 58 91 112 46 114 101 99 111 114 100 115 93 59 99 111 110 115 ...
        116 32 114 101 97 100 61 114 61 62 123 99 111 110 115 116 32 113 61 114 46 114 101 97 100 105 110 103 44 105 100 115 61 102 108 97 116 40 113 46 105 100 115 41 44 118 97 108 117 101 115 61 102 108 97 116 40 113 46 118 97 108 117 101 115 41 44 117 110 105 116 115 61 102 108 97 116 40 113 46 ...
        117 110 105 116 115 41 44 110 97 109 101 115 61 102 108 97 116 40 113 46 110 97 109 101 115 41 59 114 101 116 117 114 110 32 105 100 115 46 109 97 112 40 40 105 100 44 105 41 61 62 40 123 105 100 44 118 97 108 117 101 58 78 117 109 98 101 114 40 118 97 108 117 101 115 91 105 93 41 44 117 ...
        110 105 116 58 117 110 105 116 115 91 105 93 44 110 97 109 101 58 110 97 109 101 115 91 105 93 125 41 41 125 59 99 111 110 115 116 32 97 61 36 40 39 91 100 97 116 97 45 99 111 109 112 97 114 101 45 97 93 39 41 44 98 61 36 40 39 91 100 97 116 97 45 99 111 109 112 97 114 101 45 ...
        98 93 39 41 44 111 117 116 61 36 40 39 91 100 97 116 97 45 99 111 109 112 97 114 101 45 111 117 116 112 117 116 93 39 41 59 105 102 40 97 38 38 98 38 38 111 117 116 41 123 99 111 110 115 116 32 117 112 100 97 116 101 61 40 41 61 62 123 99 111 110 115 116 32 114 97 61 114 101 97 ...
        100 40 114 101 99 111 114 100 115 91 78 117 109 98 101 114 40 97 46 118 97 108 117 101 41 93 41 44 114 98 61 114 101 97 100 40 114 101 99 111 114 100 115 91 78 117 109 98 101 114 40 98 46 118 97 108 117 101 41 93 41 44 112 97 114 116 115 61 91 93 59 102 111 114 40 99 111 110 115 116 ...
        32 120 32 111 102 32 114 97 41 123 99 111 110 115 116 32 121 61 114 98 46 102 105 110 100 40 121 61 62 121 46 105 100 61 61 61 120 46 105 100 38 38 121 46 117 110 105 116 61 61 61 120 46 117 110 105 116 41 59 105 102 40 121 41 123 99 111 110 115 116 32 100 61 121 46 118 97 108 117 101 ...
        45 120 46 118 97 108 117 101 59 112 97 114 116 115 46 112 117 115 104 40 120 46 110 97 109 101 43 39 58 32 39 43 120 46 118 97 108 117 101 46 116 111 80 114 101 99 105 115 105 111 110 40 53 41 43 39 32 226 134 146 32 39 43 121 46 118 97 108 117 101 46 116 111 80 114 101 99 105 115 105 ...
        111 110 40 53 41 43 39 32 39 43 120 46 117 110 105 116 43 39 59 32 112 111 107 121 116 105 115 32 39 43 40 100 62 61 48 63 39 43 39 58 39 39 41 43 100 46 116 111 80 114 101 99 105 115 105 111 110 40 52 41 43 39 32 39 43 120 46 117 110 105 116 41 125 125 111 117 116 46 116 101 ...
        120 116 67 111 110 116 101 110 116 61 112 97 114 116 115 46 108 101 110 103 116 104 63 112 97 114 116 115 46 106 111 105 110 40 39 32 194 183 32 39 41 58 39 197 160 105 117 111 115 101 32 98 97 110 100 121 109 117 111 115 101 32 109 97 116 117 111 116 105 32 115 107 105 114 116 105 110 103 105 32 ...
        100 121 100 197 190 105 97 105 46 32 80 97 115 105 114 105 110 107 105 116 101 32 100 117 32 116 111 115 32 112 97 196 141 105 111 115 32 115 101 107 111 115 32 98 97 110 100 121 109 117 115 46 39 125 59 97 46 97 100 100 69 118 101 110 116 76 105 115 116 101 110 101 114 40 39 99 104 97 110 103 ...
        101 39 44 117 112 100 97 116 101 41 59 98 46 97 100 100 69 118 101 110 116 76 105 115 116 101 110 101 114 40 39 99 104 97 110 103 101 39 44 117 112 100 97 116 101 41 59 117 112 100 97 116 101 40 41 125 125 41 40 41 59 10 ...
    ]);
endfunction


MO_REPORT_ROOT=get_absolute_file_path("mo_report.sci");
exec(MO_REPORT_ROOT+"mo_report_dc_visuals.sci",-1);
exec(MO_REPORT_ROOT+"mo_report_late_visuals.sci",-1);
