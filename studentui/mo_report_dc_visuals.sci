// Compact report explanations, built only from recorded readings and settings.
function h=mo6dc_text(x,y,label,fontSize,anchor,bold,color)
    if argn(2)<5 then anchor="start";end
    if argn(2)<6 then bold=%f;end
    if argn(2)<7 then color="#526a64";end
    weight="normal";if bold then weight="bold";end
    h=msprintf("<text x=""%.2f"" y=""%.2f"" text-anchor=""%s"" font-size=""%g"" font-weight=""%s"" style=""fill:%s"">",x,y,anchor,fontSize,weight,color)+mo_html(label)+"</text>";
endfunction
function h=mo6dc_line(x1,y1,x2,y2,color,width)
    if argn(2)<5 then color="#90aaa2";end
    if argn(2)<6 then width=2;end
    h=msprintf("<line x1=""%.2f"" y1=""%.2f"" x2=""%.2f"" y2=""%.2f"" stroke=""%s"" stroke-width=""%.2f""/>",x1,y1,x2,y2,color,width);
endfunction
function h=mo6dc_rect(x,y,w,hgt,fill,stroke)
    if argn(2)<6 then stroke="#dce5e2";end
    h=msprintf("<rect x=""%.2f"" y=""%.2f"" width=""%.2f"" height=""%.2f"" rx=""8"" fill=""%s"" stroke=""%s""/>",x,y,w,hgt,fill,stroke);
endfunction
function h=mo6dc_arrow(x1,y1,x2,y2,width,color)
    dx=x2-x1;dy=y2-y1;distance=sqrt(dx*dx+dy*dy);h="";if distance<=0 then return;end
    ux=dx/distance;uy=dy/distance;head=max(9,1.1*width);half=max(5,.55*width);
    bx=x2-head*ux;by=y2-head*uy;
    h=mo6dc_line(x1,y1,bx,by,color,width)+msprintf("<polygon points=""%.2f,%.2f %.2f,%.2f %.2f,%.2f"" fill=""%s""/>",x2,y2,bx-half*uy,by+half*ux,bx+half*uy,by-half*ux,color);
endfunction
function h=mo6dc_begin(lab,title,height)
    h="<section class=""section dc-explanation"" data-lab="""+lab+"""><h2>"+mo_html(title)+"</h2><article class=""chart""><svg viewBox=""0 0 980 "+string(height)+""" role=""img"" aria-label="""+mo_html(title)+"""><title>"+mo_html(title)+"</title>";
endfunction
function h=mo6dc_end(note)
    h="</svg><p class=""chart-note"">"+mo_html(note)+"</p></article></section>";
endfunction
function h=mo6dc_reading(x,y,label,value,unit)
    h=mo6dc_text(x,y,label+" = "+mo_display(value)+" "+unit,20,"middle",%t,"#075e52");
endfunction
function h=mo6dc_resistor(x,y,w,label)
    h=mo6dc_line(x-20,y+14,x,y+14)+mo6dc_rect(x,y,w,28,"#e8f2ec","#7aa595")+mo6dc_line(x+w,y+14,x+w+20,y+14);
    h=h+mo6dc_text(x+w/2,y+19,label,14,"middle",%t,"#285c50");
endfunction
function h=mo6dc_source(x,y,r,label,reverse)
    h=msprintf("<circle cx=""%.2f"" cy=""%.2f"" r=""%.2f"" fill=""#f3f7f5"" stroke=""#7c9b8e"" stroke-width=""2""/>",x,y,r);
    upper="+";lower="−";if reverse then upper="−";lower="+";end
    h=h+mo6dc_text(x,y-3,upper,16,"middle",%t)+mo6dc_text(x,y+14,lower,16,"middle",%t)+mo6dc_text(x-r-12,y+5,label,15,"end",%t);
endfunction
function h=mo6dc_internal(x,y,label)
    h=mo6dc_rect(x-14,y,28,18,"#e8f2ec","#7aa595")+mo6dc_text(x,y+13,label,12,"middle",%t);
endfunction
function h=mo6_dc_visual(lab,cfg,records)
    h="";
    select lab
    case "LD1" then
        im=mo5_value(records,5,"I_main");i2=mo5_value(records,7,"I_R2");i3=mo5_value(records,6,"I_R3");scale=max([abs(im) abs(i2) abs(i3) 1d-12]);
        h=mo6dc_begin(lab,"Kaip srovė pasidalijo mazge?",360);
        h=h+mo6dc_text(40,60,"Prieš išsišakojimą",18,"start",%t);
        h=h+mo6dc_arrow(55,180,300,180,max(2,24*abs(im)/scale),"#087866");
        h=h+msprintf("<circle cx=""300"" cy=""180"" r=""8"" fill=""#087866""/>");
        h=h+mo6dc_line(300,180,300,95,"#546fc2",max(2,24*abs(i2)/scale))+mo6dc_arrow(300,95,850,95,max(2,24*abs(i2)/scale),"#546fc2");
        h=h+mo6dc_line(300,180,300,265,"#bd7132",max(2,24*abs(i3)/scale))+mo6dc_arrow(300,265,850,265,max(2,24*abs(i3)/scale),"#bd7132");
        h=h+mo6dc_text(575,55,"R2 ir VR1 šaka",18,"middle",%t,"#546fc2")+mo6dc_reading(575,137,"I",i2,"mA");
        h=h+mo6dc_text(575,225,"R3 šaka",18,"middle",%t,"#bd7132")+mo6dc_reading(575,309,"I",i3,"mA");
        h=h+mo6dc_reading(170,223,"I",im,"mA");
        h=h+mo6dc_end("Abi atskirai išmatuotos šakų srovės kartu sudaro bendrąją srovę. Rodyklių storis padeda palyginti jų dydžius.");
    case "LD2" then
        // The existing U/I signal panel carries this explanation; do not duplicate it.
        return;
    case "LD3" then
        h=mo6dc_begin(lab,"Tas pats rezistorius – trys bandymai",310);currents=mo5_values(records,1:3,"I");maxI=max([abs(currents) 1d-12]);
        for k=1:3
            x=24+(k-1)*316;u=mo5_value(records,k,"U");i=currents(k);
            h=h+"<g data-trial="""+string(k)+""">"+mo6dc_rect(x,20,300,270,"#f7faf8");
            h=h+mo6dc_text(x+150,53,string(k)+" bandymas",17,"middle",%t)+mo6dc_reading(x+150,91,"U",u,"V");
            h=h+mo6dc_resistor(x+85,126,130,"R = "+mo_report_number(cfg.R)+" Ω");
            h=h+mo6dc_arrow(x+35,205,x+35+225*abs(i)/maxI,205,10,"#087866");
            h=h+mo6dc_reading(x+150,256,"I",i,"mA")+"</g>";
        end
        h=h+mo6dc_end("Rezistorius ir laidai tie patys. Didinant įtampą, srovė didėja tokiu pačiu santykiu; tai matyti ir I(U) grafike.");
    case "LD4" then
        indices=[3 6 7];labels=["R1 atskirai";"R2 atskirai";"R1 ir R2 nuosekliai"];currents=mo5_values(records,indices,"I");maxI=max([abs(currents) 1d-12]);
        h=mo6dc_begin(lab,"Vienoda įtampa, skirtingi rezistorių jungimai",300);
        for k=1:3
            x=24+(k-1)*316;u=mo5_value(records,indices(k),"U");i=currents(k);
            h=h+mo6dc_rect(x,20,300,260,"#f7faf8")+mo6dc_text(x+150,54,labels(k),17,"middle",%t)+mo6dc_reading(x+150,90,"U",u,"V");
            if k<3 then h=h+mo6dc_resistor(x+85,120,130,"R"+string(k));
            else h=h+mo6dc_resistor(x+42,120,90,"R1")+mo6dc_resistor(x+168,120,90,"R2");end
            h=h+mo6dc_arrow(x+35,197,x+35+225*abs(i)/maxI,197,10,"#087866")+mo6dc_reading(x+150,248,"I",i,"mA");
        end
        h=h+mo6dc_end("Lyginami trys atlikti bandymai esant tai pačiai įtampai. Didesnės bendros varžos grandine teka mažesnė srovė.");
    case "LD5" then
        h=mo6dc_begin(lab,"Potenciometro padėtis ir išėjimo įtampa",365);
        for k=1:3
            x=24+(k-1)*316;position=records(k).trial.x;u=mo5_value(records,k,"U");i=mo5_value(records,k,"I");endX=x+36+228*position/100;
            h=h+mo6dc_rect(x,20,300,325,"#f7faf8")+mo6dc_text(x+150,54,mo_report_number(position)+" % aktyviosios dalies",17,"middle",%t);
            h=h+mo6dc_rect(x+36,85,228,24,"#e4ebe7","#bbcec3");
            if position>0 then h=h+mo6dc_rect(x+36,85,228*position/100,24,"#87b4a4","#87b4a4");end
            h=h+msprintf("<polygon points=""%.2f,114 %.2f,128 %.2f,128"" fill=""#075e52""/>",endX,endX-7,endX+7);
            h=h+mo6dc_text(x+36,153,"Varžos dalis",14)+mo6dc_text(x+150,192,"Išėjimo įtampa",16,"middle",%t);
            h=h+mo6dc_rect(x+36,211,228,18,"#edf1ee","#d5e1da");
            width=228*max(0,min(1,u/cfg.E));if width>0 then h=h+mo6dc_rect(x+36,211,width,18,"#087866","#087866");end
            h=h+mo6dc_text(x+36,253,"0 V",13)+mo6dc_text(x+264,253,mo_report_number(cfg.E)+" V",13,"end");
            h=h+mo6dc_reading(x+150,285,"U",u,"V")+mo6dc_text(x+150,319,"I = "+mo_display(i)+" mA",17,"middle",%f);
        end
        h=h+mo6dc_end("Viršuje parodyta naudojama varžos dalis, apačioje – voltmetro rodmuo šaltinio įtampos skalėje. Padėties procentas ir įtampos procentas yra skirtingi dydžiai.");
    case "LD6" then
        h=mo6dc_begin(lab,"Keturi šaltinių jungimai – ta pati apkrova",540);
        labels=["Vienas šaltinis E1";"Nuosekliai suderintai";"Nuosekliai priešpriešiais";"Lygiagrečiai"];
        for k=1:4
            col=modulo(k-1,2);row=floor((k-1)/2);x=24+col*478;y=18+row*264;u=mo5_value(records,k,"U");i=mo5_value(records,k,"I");
            h=h+mo6dc_rect(x,y,454,246,"#f7faf8")+mo6dc_text(x+227,y+31,labels(k),18,"middle",%t);
            left=x+112;right=x+352;top=y+59;bottom=y+167;cy=y+113;
            h=h+mo6dc_line(left,top,right,top)+mo6dc_line(left,bottom,right,bottom)+mo6dc_line(right,top,right,y+95)+mo6dc_line(right,y+131,right,bottom);
            h=h+mo6dc_rect(right-19,y+95,38,36,"#e8f2ec","#7aa595")+mo6dc_text(right,y+119,"R",16,"middle",%t);
            h=h+mo6dc_text(right+31,y+91,"+",16,"middle",%t)+mo6dc_text(right+31,y+145,"−",16,"middle",%t);
            if k==1 then
                h=h+mo6dc_line(left,top,left,cy-25)+mo6dc_line(left,cy+25,left,bottom)+mo6dc_source(left,cy,25,"E1",%f)+mo6dc_internal(left,y+143,"r1");
            elseif k==2 | k==3 then
                h=h+mo6dc_line(left,top,left,y+74)+mo6dc_line(left,y+112,left,y+120)+mo6dc_line(left,y+158,left,bottom);
                h=h+mo6dc_source(left,y+93,19,"E1",%f)+mo6dc_source(left,y+139,19,"E2",k==3);
                h=h+mo6dc_rect(x+146,top-9,44,18,"#e8f2ec","#7aa595")+mo6dc_text(x+168,top+4,"r1",12,"middle",%t)+mo6dc_rect(x+200,top-9,44,18,"#e8f2ec","#7aa595")+mo6dc_text(x+222,top+4,"r2",12,"middle",%t);
            else
                second=x+216;
                h=h+mo6dc_line(left,top,left,cy-25)+mo6dc_line(left,cy+25,left,bottom)+mo6dc_source(left,cy,25,"E1",%f)+mo6dc_internal(left,y+143,"r1");
                h=h+mo6dc_line(second,top,second,cy-25)+mo6dc_line(second,cy+25,second,bottom)+mo6dc_source(second,cy,25,"E2",%f)+mo6dc_internal(second,y+143,"r2");
            end
            if i>=0 then h=h+mo6dc_arrow(x+250,top,x+308,top,5,"#087866");
            else h=h+mo6dc_arrow(x+308,top,x+250,top,5,"#087866");end
            h=h+mo6dc_reading(x+125,y+210,"U",u,"V")+mo6dc_reading(x+337,y+210,"I",i,"mA");
        end
        h=h+mo6dc_end("Schemos parodo šaltinių jungimo principą, įskaitant vidines varžas r1 ir r2. U ir I matuoti apkrovoje; minusas reiškia priešingą pasirinktai atskaitai kryptį.");
    end
endfunction
