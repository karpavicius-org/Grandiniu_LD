// Viename aplanke ir jo poaplankiuose pateiktų darbų suvestinė.
function files=mo_teacher_files(folder,depth)
    if argn(2)<2 then depth=0;end
    files=emptystr(0,1);if depth>12 then return;end
    names=findfiles(folder,"*");
    for k=1:size(names,"*")
        name=names(k);if or(name==["." ".."]) then continue;end
        path=fullfile(folder,name);
        if isdir(path) then
            if ~isempty(strindex(name,"Matavimu_suvestine-")) | ~isempty(strindex(name,"Vertinimai-")) then continue;end
            child=mo_teacher_files(path,depth+1);files=[files;child];
        elseif convstr(fileext(path),"l")==".html" then files($+1,1)=path;
        end
    end
endfunction
function [newCount,oldCount]=mo_teacher_count(folder)
    newCount=0;oldCount=0;files=mo_teacher_files(folder);
    for k=1:size(files,"*")
        [kind,p,why]=mo_read_report(files(k));
        if kind==0 then oldCount=oldCount+1;else newCount=newCount+1;end
    end
endfunction
function line=mo_teacher_csv(fields)
    for j=1:size(fields,"*")
        v=string(fields(j));
        if v<>"" then if or(part(v,1)==["=" "+" "-" "@"]) then v=ascii(39)+v;end;end
        fields(j)=ascii(34)+strsubst(v,ascii(34),ascii(34)+ascii(34))+ascii(34);
    end
    line=strcat(fields,";");
endfunction
function path=mo_teacher_summary(folder)
    files=mo_teacher_files(folder);entries=list();students=emptystr(0,3);keys=emptystr(0,1);
    for k=1:size(files,"*")
        [kind,p,why]=mo_read_report(files(k));if kind==0 then continue;end
        e=struct("file",files(k),"name","Neatpažintas studentas","group","","lab","","variant","", ...
          "category","invalid","status","Reikia patikslinti","trials",0,"readings",0,"help","", ...
          "corrections","","submission","","created","","why",why,"studentIndex",0,"events",list(),"eventCount",0,"measurements","");
        if kind==1 then
            [valid,why,stats]=mo_report_verify(p);e.why=why;e.category=stats.category;e.trials=stats.trials;e.readings=stats.readings;
            if valid then e.status="Atlikta";elseif stats.category=="legacy" then e.status="Ankstesnė versija";end
            if isfield(p,"student") then
                if typeof(p.student)=="st" then
                    e.name=mo_teacher_text(p.student,"name",e.name);e.group=mo_teacher_text(p.student,"group","");
                    if isfield(p.student,"number") then
                        value=p.student.number;if type(value)==1 & size(value,"*")==1 then if ~isnan(value) & ~isinf(value) then e.variant=string(value);end;end
                    end
                end
            end
            e.lab=mo_teacher_text(p,"lab_id","");e.submission=mo_teacher_text(p,"submission_id","");e.created=mo_teacher_text(p,"created_at","");
            if isfield(p,"exported_at") then e.created=mo_teacher_text(p,"exported_at",e.created);end
            if isfield(p,"events") then
                try allEvents=mo_record_list(p.events);e.eventCount=length(allEvents);e.events=mo_teacher_important_events(allEvents);catch e.events=list();end
            end
            if valid | stats.category=="legacy" then
                try e.measurements=mo5_measurement_table(mo_record_list(p.records));catch e.measurements="";end
            end
            if isfield(p,"help_used") then
                if type(p.help_used)==4 & size(p.help_used,"*")==1 then if p.help_used then e.help="Naudota";else e.help="Nenaudota";end;end
            end
            if isfield(p,"copy_corrections") then
                value=p.copy_corrections;if type(value)==1 & size(value,"*")==1 then if ~isnan(value) & ~isinf(value) & value>=0 & floor(value)==value then e.corrections=string(value);end;end
            end
        end
        identityNumber=bench_safe_number(e.variant);
        hasIdentity=e.name<>"Neatpažintas studentas" & e.group<>"" & ~isnan(identityNumber);
        if hasIdentity then hasIdentity=identityNumber>=1 & identityNumber<=64 & floor(identityNumber)==identityNumber;end
        if hasIdentity then
            key=convstr(stripblanks(e.group)+ascii(9)+stripblanks(e.variant)+ascii(9)+stripblanks(e.name),"l");
            hit=find(keys==key);
            if isempty(hit) then keys($+1,1)=key;students($+1,:)=[e.name e.group e.variant];hit=size(keys,"*");end
            e.studentIndex=hit(1);
        end
        entries($+1)=e;
    end
    ns=size(students,1);status=zeros(ns,12);history=emptystr(ns,12);counts=zeros(ns,1);
    rows="";csv=[mo_teacher_csv(["Studentas" "Grupė" "Sąrašo nr." "Atlikta iš 12" "LD1" "LD2" "LD3" "LD4" "LD5" "LD6" "LD7" "LD8" "LD9" "LD10" "LD11" "LD12"])];
    hc=[mo_teacher_csv(["Failas" "Studentas" "Grupė" "Sąrašo nr." "LD" "Būsena" "Bandymai" "Rodmenys" "Pagalba" "Rodmens taisymai" "Darbo ID" "Paaiškinimas"])];
    for k=1:length(entries)
        e=entries(k);id="bandymas-"+string(k);idx=find(e.lab==["LD1" "LD2" "LD3" "LD4" "LD5" "LD6" "LD7" "LD8" "LD9" "LD10" "LD11" "LD12"]);
        if ~isempty(idx) & e.studentIndex>0 then
            score=1;if e.category=="legacy" then score=2;elseif e.category=="valid" then score=3;end
            status(e.studentIndex,idx)=max(status(e.studentIndex,idx),score);
            history(e.studentIndex,idx)=history(e.studentIndex,idx)+"<a href=""#"+id+""">"+mo_html(e.status)+" · Nr. "+mo_html(e.variant)+"</a><br>";
        end
        hc($+1,1)=mo_teacher_csv([e.file e.name e.group e.variant e.lab e.status string(e.trials) string(e.readings) e.help e.corrections e.submission e.why]);
        reportLink=mo_teacher_href(folder,e.file);
        extra="<p><a href="""+mo_html(reportLink)+""">Atverti HTML ataskaitą</a></p>";
        extra=extra+"<details><summary>Matavimų lentelė</summary>"+e.measurements+"</details><details data-events="""+string(k-1)+"""><summary>Svarbiausių veiksmų istorija ("+string(length(e.events))+" iš "+string(e.eventCount)+")</summary><div data-history-body></div></details>";
        rows=rows+"<tr data-group="""+mo_html(e.group)+""" data-search="""+mo_html(convstr(e.name+" "+e.group,"l"))+""" id="""+id+"""><td>"+mo_html(e.name)+"<div class=""condition"">"+mo_html(e.group)+" · Nr. "+mo_html(e.variant)+"</div></td><td>"+mo_html(e.lab)+"</td><td>"+mo_html(e.status)+"</td><td>"+string(e.trials)+" / "+string(e.readings)+"</td><td>"+mo_html(e.help)+"<div class=""condition"">Rodmens taisymai: "+mo_html(e.corrections)+"</div></td><td><details><summary>Įrašo informacija</summary><p>"+mo_html(e.why)+"</p><p class=""condition"">"+mo_html(e.file)+"<br>Darbo ID: "+mo_html(e.submission)+"<br>Pateikta: "+mo_html(e.created)+"</p>"+extra+"</details></td></tr>";
    end
    matrixRows="";labels=["Nepateikta" "Reikia patikslinti" "Ankstesnė versija" "Atlikta"];
    for k=1:ns
        counts(k)=sum(status(k,:)==3);matrixRows=matrixRows+"<tr data-group="""+mo_html(students(k,2))+""" data-search="""+mo_html(convstr(students(k,1)+" "+students(k,2),"l"))+"""><th>"+mo_html(students(k,1))+"<div class=""condition"">"+mo_html(students(k,2))+" · Nr. "+mo_html(students(k,3))+"</div></th><td class=""number""><strong>"+string(counts(k))+" / 12</strong></td>";
        fields=[students(k,:) string(counts(k))];
        for j=1:12
            label=labels(status(k,j)+1);fields($+1)=label;color="#f5f7f5";
            if status(k,j)==3 then color="#d9f0e6";elseif status(k,j)==2 then color="#e7ecf8";elseif status(k,j)==1 then color="#fff0ce";end
            matrixRows=matrixRows+"<td style=""background:"+color+"""><details><summary>"+mo_html(label)+"</summary>"+history(k,j)+"</details></td>";
        end
        matrixRows=matrixRows+"</tr>";csv($+1,1)=mo_teacher_csv(fields);
    end
    destination=fullfile(folder,"Matavimu_suvestine-"+bench_id());[ok,msg]=mkdir(destination);if ~ok then error(msg);end
    head="<th>Studentas</th><th>Atlikta</th>";for j=1:12;head=head+"<th>LD"+string(j)+"</th>";end
    options="<option value="""">Visos grupės</option>";
    groups=emptystr(0,1);if ns>0 then groups=unique(students(:,2));end;for k=1:size(groups,"*");options=options+"<option>"+mo_html(groups(k))+"</option>";end
    eventData=list();for k=1:length(entries);eventData($+1)=struct("events",entries(k).events);end
    h="<!doctype html><html lang=""lt""><head><meta charset=""utf-8""><meta name=""viewport"" content=""width=device-width,initial-scale=1""><title>LD1–LD12 darbų suvestinė</title><style>"+mo_report_style()+"main{max-width:1700px}.matrix{min-width:1450px}.matrix td{min-width:90px}.matrix details{margin:0;padding:0;border:0}.matrix summary{font-size:11px}.matrix th:first-child{min-width:170px}</style></head><body><main><header><div class=""eyebrow"">Dėstytojo suvestinė</div><h1>LD1–LD12 darbų atlikimas</h1><p>Studentų: "+string(ns)+" · Pateiktų įrašų: "+string(length(entries))+" · Atliktų darbų: "+string(sum(counts))+"</p><p>Atlikta – pateikti visi dabartinės versijos bandymai, sujungimai ir prietaisų rodmenys sutampa su varianto modeliu. Ankstesnės versijos darbai rodomi atskirai. Pagalbos naudojimas ir taisymai pateikiami kaip darbo eigos informacija.</p><div class=""controls no-print""><label>Grupė <select id=""group"">"+options+"</select></label><label>Studentas <input id=""search"" placeholder=""Ieškoti pagal vardą""></label><button onclick=""window.print()"">Spausdinti / PDF</button><a href=""matavimu_suvestine.csv"">CSV suvestinė</a><a href=""pateikimu_istorija.csv"">Pateikimų CSV</a></div></header><div class=""content""><h2>Studentai ir 12 laboratorinių darbų</h2><p>Paspaudus langelio būseną rodomi visi to darbo pateikimai. Nepateikta reiškia, kad pasirinktuose failuose šio darbo nėra.</p><div class=""scroll""><table class=""matrix""><thead><tr>"+head+"</tr></thead><tbody>"+matrixRows+"</tbody></table></div><h2>Pateikimų istorija ir patikra</h2><div class=""scroll""><table><thead><tr><th>Studentas</th><th>LD</th><th>Būsena</th><th>Bandymai / rodmenys</th><th>Darbo eiga</th><th>Duomenys</th></tr></thead><tbody>"+rows+"</tbody></table></div></div></main><script id=""teacher-data"" type=""application/json"">"+mo5_json(eventData)+"</script><script>"+mo_teacher_script()+"</script></body></html>";
    path=fullfile(destination,"matavimu_suvestine.html");bench_write_new(path,h);
    bench_write_new(fullfile(destination,"matavimu_suvestine.csv"),ascii([239 187 191])+strcat(csv,ascii(10)));
    bench_write_new(fullfile(destination,"pateikimu_istorija.csv"),ascii([239 187 191])+strcat(hc,ascii(10)));
endfunction

function href=mo_teacher_href(folder,path)
    root=strsubst(pathconvert(folder,%f,%t),"\","/");source=strsubst(pathconvert(path,%f,%t),"\","/");
    if part(root,length(root))=="/" then root=part(root,1:length(root)-1);end
    prefix=root+"/";if part(source,1:length(prefix))<>prefix then error("Ataskaitos kelias neatitinka pasirinkto aplanko.");end
    relative="../"+part(source,length(prefix)+1:length(source));bytes=ascii(relative);href="";
    safe="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~/";
    for k=1:size(bytes,"*")
        code=bytes(k);
        allowed=(code>=65 & code<=90) | (code>=97 & code<=122) | (code>=48 & code<=57) | or(code==[45 46 95 126 47]);
        if allowed then href=href+ascii(code);
        else href=href+"%"+convstr(dec2hex(code,2),"u");end
    end
endfunction

function s=mo_teacher_script()
    s=ascii([ ...
        40 40 41 61 62 123 39 117 115 101 32 115 116 114 105 99 116 39 59 99 111 110 115 116 32 103 61 100 111 99 117 109 101 110 116 46 103 101 116 69 108 101 109 101 110 116 66 121 73 100 40 39 103 114 111 117 112 39 41 44 115 61 100 111 99 117 109 101 110 116 46 103 101 116 69 108 101 109 101 110 ...
        116 66 121 73 100 40 39 115 101 97 114 99 104 39 41 44 102 108 97 116 61 120 61 62 65 114 114 97 121 46 105 115 65 114 114 97 121 40 120 41 63 120 46 102 108 97 116 40 73 110 102 105 110 105 116 121 41 58 91 120 93 59 102 117 110 99 116 105 111 110 32 117 112 100 97 116 101 40 41 123 ...
        99 111 110 115 116 32 113 61 115 46 118 97 108 117 101 46 116 111 76 111 99 97 108 101 76 111 119 101 114 67 97 115 101 40 39 108 116 39 41 59 100 111 99 117 109 101 110 116 46 113 117 101 114 121 83 101 108 101 99 116 111 114 65 108 108 40 39 116 114 91 100 97 116 97 45 103 114 111 117 112 ...
        93 39 41 46 102 111 114 69 97 99 104 40 114 61 62 114 46 104 105 100 100 101 110 61 33 33 40 40 103 46 118 97 108 117 101 38 38 114 46 100 97 116 97 115 101 116 46 103 114 111 117 112 33 61 61 103 46 118 97 108 117 101 41 124 124 40 113 38 38 33 114 46 100 97 116 97 115 101 116 46 ...
        115 101 97 114 99 104 46 105 110 99 108 117 100 101 115 40 113 41 41 41 41 125 103 46 97 100 100 69 118 101 110 116 76 105 115 116 101 110 101 114 40 39 99 104 97 110 103 101 39 44 117 112 100 97 116 101 41 59 115 46 97 100 100 69 118 101 110 116 76 105 115 116 101 110 101 114 40 39 105 110 ...
        112 117 116 39 44 117 112 100 97 116 101 41 59 108 101 116 32 101 110 116 114 105 101 115 61 91 93 59 116 114 121 123 101 110 116 114 105 101 115 61 74 83 79 78 46 112 97 114 115 101 40 100 111 99 117 109 101 110 116 46 103 101 116 69 108 101 109 101 110 116 66 121 73 100 40 39 116 101 97 99 ...
        104 101 114 45 100 97 116 97 39 41 46 116 101 120 116 67 111 110 116 101 110 116 41 59 105 102 40 33 65 114 114 97 121 46 105 115 65 114 114 97 121 40 101 110 116 114 105 101 115 41 41 101 110 116 114 105 101 115 61 91 101 110 116 114 105 101 115 93 125 99 97 116 99 104 123 125 99 111 110 115 ...
        116 32 110 97 109 101 115 61 123 99 111 110 116 97 99 116 95 115 101 108 101 99 116 101 100 58 39 80 97 115 105 114 105 110 107 116 97 115 32 107 111 110 116 97 107 116 97 115 39 44 115 101 108 101 99 116 105 111 110 95 99 97 110 99 101 108 108 101 100 58 39 80 97 115 105 114 105 110 107 105 ...
        109 97 115 32 97 116 197 161 97 117 107 116 97 115 39 44 119 105 114 101 95 99 111 110 110 101 99 116 101 100 58 39 75 97 98 101 108 105 115 32 112 114 105 106 117 110 103 116 97 115 39 44 119 105 114 101 95 114 101 109 111 118 101 100 58 39 75 97 98 101 108 105 115 32 97 116 106 117 110 103 ...
        116 97 115 39 44 119 105 114 101 95 114 101 106 101 99 116 101 100 58 39 78 101 116 105 110 107 97 109 97 32 106 117 110 103 116 105 115 32 97 116 109 101 115 116 97 39 44 117 110 100 111 58 39 65 116 197 161 97 117 107 116 97 115 32 118 101 105 107 115 109 97 115 39 44 109 101 97 115 117 114 ...
        101 109 101 110 116 95 99 111 109 112 108 101 116 101 100 58 39 65 116 108 105 107 116 97 115 32 109 97 116 97 118 105 109 97 115 39 44 114 101 97 100 105 110 103 95 99 111 114 114 101 99 116 105 111 110 58 39 84 97 105 115 121 116 97 115 32 114 111 100 109 117 111 39 44 114 101 97 100 105 110 ...
        103 115 95 99 111 110 102 105 114 109 101 100 58 39 82 111 100 109 101 110 121 115 32 112 97 116 118 105 114 116 105 110 116 105 39 44 116 114 105 97 108 95 115 116 97 114 116 101 100 58 39 80 114 97 100 196 151 116 97 115 32 98 97 110 100 121 109 97 115 39 44 104 101 108 112 95 111 112 101 110 ...
        101 100 58 39 65 116 118 101 114 116 97 32 112 97 103 97 108 98 97 39 44 114 101 112 111 114 116 95 115 97 118 101 100 58 39 65 116 97 115 107 97 105 116 97 32 105 197 161 115 97 117 103 111 116 97 39 125 59 102 117 110 99 116 105 111 110 32 115 116 97 109 112 40 118 97 108 117 101 41 123 ...
        105 102 40 65 114 114 97 121 46 105 115 65 114 114 97 121 40 118 97 108 117 101 41 41 123 99 111 110 115 116 32 100 61 102 108 97 116 40 118 97 108 117 101 41 59 105 102 40 100 46 108 101 110 103 116 104 62 61 57 41 114 101 116 117 114 110 32 96 36 123 100 91 48 93 125 45 36 123 83 116 ...
        114 105 110 103 40 100 91 49 93 41 46 112 97 100 83 116 97 114 116 40 50 44 39 48 39 41 125 45 36 123 83 116 114 105 110 103 40 100 91 53 93 41 46 112 97 100 83 116 97 114 116 40 50 44 39 48 39 41 125 32 36 123 83 116 114 105 110 103 40 100 91 54 93 41 46 112 97 100 83 116 ...
        97 114 116 40 50 44 39 48 39 41 125 58 36 123 83 116 114 105 110 103 40 100 91 55 93 41 46 112 97 100 83 116 97 114 116 40 50 44 39 48 39 41 125 58 36 123 83 116 114 105 110 103 40 100 91 56 93 41 46 112 97 100 83 116 97 114 116 40 50 44 39 48 39 41 125 96 125 114 101 116 ...
        117 114 110 32 83 116 114 105 110 103 40 118 97 108 117 101 63 63 39 39 41 125 100 111 99 117 109 101 110 116 46 97 100 100 69 118 101 110 116 76 105 115 116 101 110 101 114 40 39 116 111 103 103 108 101 39 44 101 118 61 62 123 99 111 110 115 116 32 100 61 101 118 46 116 97 114 103 101 116 59 ...
        105 102 40 33 100 46 109 97 116 99 104 101 115 63 46 40 39 100 101 116 97 105 108 115 91 100 97 116 97 45 101 118 101 110 116 115 93 39 41 124 124 33 100 46 111 112 101 110 124 124 100 46 100 97 116 97 115 101 116 46 114 101 97 100 121 41 114 101 116 117 114 110 59 100 46 100 97 116 97 115 ...
        101 116 46 114 101 97 100 121 61 39 49 39 59 99 111 110 115 116 32 101 61 101 110 116 114 105 101 115 91 78 117 109 98 101 114 40 100 46 100 97 116 97 115 101 116 46 101 118 101 110 116 115 41 93 44 98 111 120 61 100 46 113 117 101 114 121 83 101 108 101 99 116 111 114 40 39 91 100 97 116 ...
        97 45 104 105 115 116 111 114 121 45 98 111 100 121 93 39 41 59 108 101 116 32 101 118 101 110 116 115 61 101 63 46 101 118 101 110 116 115 124 124 91 93 59 105 102 40 33 65 114 114 97 121 46 105 115 65 114 114 97 121 40 101 118 101 110 116 115 41 41 101 118 101 110 116 115 61 91 101 118 101 ...
        110 116 115 93 59 105 102 40 33 101 118 101 110 116 115 46 108 101 110 103 116 104 41 123 98 111 120 46 116 101 120 116 67 111 110 116 101 110 116 61 39 197 160 105 97 109 32 112 97 116 101 105 107 105 109 117 105 32 100 101 116 97 108 105 32 118 101 105 107 115 109 197 179 32 105 115 116 111 114 105 ...
        106 97 32 110 101 105 197 161 115 97 117 103 111 116 97 46 39 59 114 101 116 117 114 110 125 99 111 110 115 116 32 116 97 98 108 101 61 100 111 99 117 109 101 110 116 46 99 114 101 97 116 101 69 108 101 109 101 110 116 40 39 116 97 98 108 101 39 41 59 116 97 98 108 101 46 99 108 97 115 115 ...
        78 97 109 101 61 39 101 118 101 110 116 45 116 97 98 108 101 39 59 99 111 110 115 116 32 104 101 97 100 61 100 111 99 117 109 101 110 116 46 99 114 101 97 116 101 69 108 101 109 101 110 116 40 39 116 104 101 97 100 39 41 44 104 114 61 100 111 99 117 109 101 110 116 46 99 114 101 97 116 101 ...
        69 108 101 109 101 110 116 40 39 116 114 39 41 59 102 111 114 40 99 111 110 115 116 32 118 32 111 102 32 91 39 78 114 46 39 44 39 76 97 105 107 97 115 39 44 39 66 97 110 100 121 109 97 115 39 44 39 86 101 105 107 115 109 97 115 39 44 39 73 110 102 111 114 109 97 99 105 106 97 39 ...
        93 41 123 99 111 110 115 116 32 99 61 100 111 99 117 109 101 110 116 46 99 114 101 97 116 101 69 108 101 109 101 110 116 40 39 116 104 39 41 59 99 46 116 101 120 116 67 111 110 116 101 110 116 61 118 59 104 114 46 97 112 112 101 110 100 67 104 105 108 100 40 99 41 125 104 101 97 100 46 97 ...
        112 112 101 110 100 67 104 105 108 100 40 104 114 41 59 116 97 98 108 101 46 97 112 112 101 110 100 67 104 105 108 100 40 104 101 97 100 41 59 99 111 110 115 116 32 98 111 100 121 61 100 111 99 117 109 101 110 116 46 99 114 101 97 116 101 69 108 101 109 101 110 116 40 39 116 98 111 100 121 39 ...
        41 59 102 111 114 40 99 111 110 115 116 32 120 32 111 102 32 101 118 101 110 116 115 41 123 99 111 110 115 116 32 116 114 61 100 111 99 117 109 101 110 116 46 99 114 101 97 116 101 69 108 101 109 101 110 116 40 39 116 114 39 41 59 102 111 114 40 99 111 110 115 116 32 118 32 111 102 32 91 120 ...
        46 115 101 113 117 101 110 99 101 44 115 116 97 109 112 40 120 46 116 105 109 101 41 44 120 46 116 114 105 97 108 44 110 97 109 101 115 91 120 46 97 99 116 105 111 110 93 124 124 120 46 97 99 116 105 111 110 44 120 46 100 101 116 97 105 108 93 41 123 99 111 110 115 116 32 99 61 100 111 99 ...
        117 109 101 110 116 46 99 114 101 97 116 101 69 108 101 109 101 110 116 40 39 116 100 39 41 59 99 46 116 101 120 116 67 111 110 116 101 110 116 61 83 116 114 105 110 103 40 118 63 63 39 39 41 59 116 114 46 97 112 112 101 110 100 67 104 105 108 100 40 99 41 125 98 111 100 121 46 97 112 112 ...
        101 110 100 67 104 105 108 100 40 116 114 41 125 116 97 98 108 101 46 97 112 112 101 110 100 67 104 105 108 100 40 98 111 100 121 41 59 98 111 120 46 97 112 112 101 110 100 67 104 105 108 100 40 116 97 98 108 101 41 125 44 116 114 117 101 41 125 41 40 41 59 10 ...
    ]);
endfunction

function text=mo_teacher_text(value,key,fallback)
    text=fallback;if typeof(value)<>"st" then return;end
    if ~isfield(value,key) then return;end
    item=value(key);if type(item)<>10 | size(item,"*")<>1 then return;end
    if length(item)>512 then return;end;text=item;
endfunction

function selected=mo_teacher_important_events(events)
    selected=list();actions=["help_opened" "wire_rejected" "reading_correction" "measurement_completed" "readings_confirmed" "trial_started" "report_saved"];
    for k=1:length(events)
        e=events(k);if typeof(e)<>"st" then continue;end
        if ~isfield(e,"action") then continue;end
        if type(e.action)<>10 | size(e.action,"*")<>1 then continue;end
        if or(e.action==actions) then selected($+1)=e;end
    end
endfunction
