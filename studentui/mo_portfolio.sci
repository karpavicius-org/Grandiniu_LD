// Scilab 2024 corrupts these valid JSON Unicode escapes. Decode only the
// three HTML-protective ASCII characters before its parser; keep writer safety.
function decoded=mo7_decode_html_json(raw)
    decoded=raw;
    patterns=["\u003c" "\u003C" "\u003e" "\u003E" "\u0026"];
    if isempty(strindex(raw,patterns)) then return;end
    bytes=ascii(raw);n=size(bytes,"*");slashes=find(bytes==92);last=1;consumed=1;out=[];
    for i=slashes
        if i<consumed | i>=n then continue;end
        consumed=i+2;
        if bytes(i+1)==92 then continue;end
        if bytes(i+1)<>117 | i+5>n then continue;end
        token=convstr(ascii(bytes(i+2:i+5)),"l");value=0;
        if token=="003c" then value=60;elseif token=="003e" then value=62;elseif token=="0026" then value=38;end
        if value>0 then
            if i>last then out=[out bytes(last:i-1)];end
            out=[out value];last=i+6;consumed=last;
        end
    end
    if last<=n then out=[out bytes(last:n)];end
    decoded=ascii(out);
endfunction
// One cumulative student file. Existing measurement records remain unchanged.
function yes=mo7_is_portfolio(p)
    yes=%f;
    if typeof(p)<>"st" then return;end
    if ~isfield(p,"report_type") then return;end
    if type(p.report_type)<>10 | size(p.report_type,"*")<>1 then return;end
    yes=p.report_type=="student-laboratory-portfolio-v1";
endfunction
function yes=mo7_student_valid(s)
    yes=%f;
    try
        if typeof(s)<>"st" | size(s,"*")<>1 then return;end
        if type(s.name)<>10 | size(s.name,"*")<>1 | type(s.group)<>10 | size(s.group,"*")<>1 then return;end
        if stripblanks(s.name)=="" | stripblanks(s.group)=="" then return;end
        if type(s.number)<>1 | size(s.number,"*")<>1 then return;end
        n=s.number;if ~isreal(n) | isnan(n) | isinf(n) | n<1 | n>64 | floor(n)<>n then return;end
        yes=%t;
    catch yes=%f;end
endfunction
function yes=mo7_same_student(a,b)
    yes=%f;
    if ~mo7_student_valid(a) | ~mo7_student_valid(b) then return;end
    yes=a.name==b.name & a.group==b.group & a.number==b.number;
endfunction
function labs=mo7_labs()
    labs=["LD1" "LD2" "LD3" "LD4" "LD5" "LD6" "LD7" "LD8" "LD9" "LD10" "LD11" "LD12"];
endfunction
function [ok,why,reports]=mo7_portfolio_reports(p)
    ok=%f;why="";reports=list();
    try
        if ~mo7_is_portfolio(p) then error("Tai nėra bendras studento failas.");end
        if type(p.schema_version)<>1 | size(p.schema_version,"*")<>1 then error("Netinkama bendro failo versija.");end
        if p.schema_version<>7 then error("Nepalaikoma bendro failo versija.");end
        if ~mo7_student_valid(p.student) then error("Netinkami bendro failo studento duomenys.");end
        reports=mo_record_list(p.reports);n=length(reports);
        if n<1 | n>12 then error("Bendrame faile turi būti nuo 1 iki 12 darbų.");end
        seen=emptystr(0,1);labs=mo7_labs();
        for k=1:n
            q=reports(k);
            if typeof(q)<>"st" | size(q,"*")<>1 then error("Netinkamas laboratorinio darbo įrašas.");end
            if type(q.lab_id)<>10 | size(q.lab_id,"*")<>1 then error("Netinkamas laboratorinio darbo numeris.");end
            if ~or(q.lab_id==labs) then error("Neatpažintas laboratorinis darbas bendrame faile.");end
            if or(seen==q.lab_id) then error("Bendrame faile kartojasi tas pats laboratorinis darbas.");end
            if ~mo7_same_student(q.student,p.student) then error("Bendrame faile sumaišyti skirtingų studentų duomenys.");end
            seen($+1,1)=q.lab_id;
        end
        ok=%t;
    catch why=strcat(lasterror()," ");reports=list();end
endfunction
function [found,payload]=mo7_find_report(p,lab,student)
    found=%f;payload=[];
    try
        reports=list(p);
        if mo7_is_portfolio(p) then
            [ok,why,reports]=mo7_portfolio_reports(p);if ~ok then return;end
        end
        for k=1:length(reports)
            q=reports(k);
            if q.lab_id==lab & mo7_same_student(q.student,student) then
                [valid,why,stats]=mo_report_verify(q);
                if valid then found=%t;payload=q;return;end
            end
        end
    catch found=%f;payload=[];end
endfunction
function path=mo7_canonical_path(student)
    if ~mo7_student_valid(student) then error("Netinkami studento duomenys.");end
    identity=struct("name",student.name,"group",student.group,"number",student.number);
    key=part(hash(toJSON(identity),"sha256"),1:20);
    name="Studento_LD1-LD12-V"+msprintf("%02d",student.number)+"-"+key+".html";
    path=fullfile(bench_documents(),"Grandiniu_ataskaitos",name);
endfunction
function reports=mo7_put_report(reports,payload,replace)
    for k=1:length(reports)
        if reports(k).lab_id==payload.lab_id then
            if replace then reports(k)=payload;end
            return;
        end
    end
    reports($+1)=payload;
endfunction
function mo7_verify_children(reports)
    for k=1:length(reports)
        [valid,why,stats]=mo_report_verify(reports(k));
        if ~valid then error(reports(k).lab_id+": "+why);end
    end
endfunction
function reports=mo7_existing(path,student)
    reports=list();
    readPath=path;
    if ~isfile(path) then
        if isfile(path+".previous") then readPath=path+".previous";else return;end
    end
    [kind,p,why]=mo_read_report(readPath);
    if kind<>1 | ~mo7_is_portfolio(p) then error("Esamas bendras failas neįskaitomas. Jis nepakeistas: "+path);end
    [ok,why,reports]=mo7_portfolio_reports(p);
    if ~ok then error("Esamas bendras failas nepatikrintas ir nepakeistas: "+why);end
    if ~mo7_same_student(p.student,student) then error("Šis failas priklauso kitam studentui. Jis nepakeistas.");end
    mo7_verify_children(reports);
endfunction
function reports=mo7_import_file(reports,path,student)
    if ~isfile(path) then return;end
    [kind,p,why]=mo_read_report(path);if kind<>1 then return;end
    candidates=list(p);
    if mo7_is_portfolio(p) then
        [ok,why,candidates]=mo7_portfolio_reports(p);if ~ok then return;end
    end
    for j=1:length(candidates)
        q=candidates(j);
        try
            if ~mo7_same_student(q.student,student) then continue;end
            exists=%f;for k=1:length(reports);if reports(k).lab_id==q.lab_id then exists=%t;break;end;end
            if exists then continue;end
            [valid,why,stats]=mo_report_verify(q);
            if valid then reports=mo7_put_report(reports,q,%f);end
        catch
            // An unrelated or malformed legacy report is never imported.
        end
    end
endfunction
function reports=mo7_import_checkpoint(reports,path,student)
    if ~isfile(path) then return;end
    try
        raw=strcat(mgetl(path),ascii(10));if ~mo_json_safe(raw) then return;end
        c=fromJSON(raw);
        if c.workflow<>"measurement-tasks-v5" | c.checkpoint_revision<>2 | c.phase<>"complete" then return;end
        if ~mo7_same_student(c.student,student) | ~or(c.lab==mo7_labs()) then return;end
        if isfield(c,"reportPath") then reports=mo7_import_file(reports,c.reportPath,student);end
        for k=1:length(reports);if reports(k).lab_id==c.lab then return;end;end
        cfg=mo_config(c.lab,student.number);protocol=mo_protocol(c.lab,cfg);
        records=mo_record_list(c.records);
        if c.trialIndex<>length(protocol.trials) | length(records)<>length(protocol.trials) then return;end
        if ~rt_protocol_compatible(c.protocolSignature,protocol) then return;end
        s=struct("student",c.student,"cfg",cfg,"protocol",protocol,"records",records);
        for field=["sessionId" "createdAt" "helpUsed" "wiringErrors" "copyErrors" "events"]
            if isfield(c,field) then s(field)=c(field);end
        end
        q=mo_report_payload(s);[valid,why,stats]=mo_report_verify(q);
        if valid then reports=mo7_put_report(reports,q,%f);end
    catch
        // Completed checkpoints are imported only after the full model check.
    end
endfunction
function reports=mo7_migrate(reports,s)
    if length(reports)>=12 then return;end
    folder=fullfile(bench_documents(),"Grandiniu_ataskaitos");
    value=5381;codes=ascii(s.student.group+"|"+s.student.name);
    for code=codes;value=modulo(value*33+code,4294967291);end
    for lab=mo7_labs()
        present=%f;for k=1:length(reports);if reports(k).lab_id==lab then present=%t;break;end;end
        if present then continue;end
        cp=fullfile(folder,"Darbo_busena_v5",lab+"-V"+string(s.student.number)+"-"+msprintf("%.0f",value)+".json");
        reports=mo7_import_checkpoint(reports,cp,s.student);
        if length(reports)>=12 then return;end
    end
    if isfield(s,"reportPath") then if s.reportPath<>"" then reports=mo7_import_file(reports,s.reportPath,s.student);end;end
    folders=folder;
    if isfield(s,"reportFolder") then if s.reportFolder<>"" & s.reportFolder<>folder then folders($+1)=s.reportFolder;end;end
    for dir=matrix(folders,1,-1)
        if ~isdir(dir) then continue;end
        names=findfiles(dir,"LD*-V"+msprintf("%02d",s.student.number)+"-ataskaita-*.html");
        // Newest name first; canonical entries and checkpoint references win.
        if size(names,"*")>1 then names=gsort(names,"g","d");end
        for name=matrix(names,1,-1)
            lab=part(name,1:strindex(name,"-V")(1)-1);present=%f;
            for k=1:length(reports);if reports(k).lab_id==lab then present=%t;break;end;end
            if ~present then reports=mo7_import_file(reports,fullfile(dir,name),s.student);end
            if length(reports)>=12 then return;end
        end
    end
endfunction
function reports=mo7_sort_reports(reports)
    sorted=list();
    for lab=mo7_labs()
        for k=1:length(reports)
            if reports(k).lab_id==lab then sorted($+1)=reports(k);break;end
        end
    end
    reports=sorted;
endfunction
function p=mo7_envelope(student,reports)
    identity=struct("name",student.name,"group",student.group,"number",student.number);
    p=struct("schema_version",7,"report_type","student-laboratory-portfolio-v1","presentation_revision",7,"student",identity,"reports",mo7_sort_reports(reports),"exported_at",bench_id());
    [ok,why,r]=mo7_portfolio_reports(p);if ~ok then error(why);end
endfunction
function html=mo7_portfolio_html(p)
    [ok,why,reports]=mo7_portfolio_reports(p);if ~ok then error(why);end
    html="<!doctype html><html lang=""lt""><head><meta charset=""utf-8""><meta name=""viewport"" content=""width=device-width,initial-scale=1""><title>Grandiniu laboratoriniai darbai</title><style>"+mo_report_style()+"main.portfolio{max-width:1180px}.portfolio .content{padding-top:24px}.lab-nav{display:grid;grid-template-columns:repeat(auto-fit,minmax(125px,1fr));gap:8px}.lab-nav a,.lab-nav span{padding:11px;border:1px solid #dce5e2;border-radius:9px;text-align:center;text-decoration:none;color:#173338}.lab-nav a{background:#e8f2ec}.lab-nav small{display:block;font-size:11px}.lab-nav a[aria-current=true]{outline:2px solid #087866}.lab-nav span{color:#617670;background:#f5f7f5}.report-frame{display:block;width:100%;min-height:800px;border:0;background:white}.portfolio-panel{margin-top:20px}.portfolio-panel[hidden]{display:none}.panel-label{padding:14px 0;font-size:18px;font-weight:bold}.portfolio>header{padding-bottom:28px}@media(max-width:600px){main.portfolio{margin:0;border-radius:0}.portfolio>header,.portfolio>.content{padding:20px}.report-frame{min-height:650px}}@media print{.lab-nav,.portfolio>header,.panel-label{display:none}.portfolio{border:0;box-shadow:none;margin:0}.portfolio>.content{padding:0}.portfolio-panel{margin:0}}"+"</style></head><body><main class=""portfolio""><header><div class=""eyebrow"">Vienas studento failas · LD1–LD12</div><h1>Grandiniu laboratoriniai darbai</h1><div class=""meta""><span>"+mo_html(p.student.name)+"</span><span>"+mo_html(p.student.group)+"</span><span>Sąrašo nr. "+string(p.student.number)+"</span></div><p class=""lead"">Atlikta "+string(length(reports))+" iš 12 darbų. Šis failas pasipildo užbaigus kitą darbą.</p><p>Dėstytojui perduokite šį vieną HTML failą. Pasirinkite darbą, kad matytumėte jo matavimus, grafikus ir išvadas.</p><div class=""toolbar no-print""><button type=""button"" data-print-selected>Spausdinti / PDF</button></div></header><div class=""content""><nav class=""lab-nav no-print"" aria-label=""Laboratoriniai darbai"">";
    first="";
    for lab=mo7_labs()
        found=0;for k=1:length(reports);if reports(k).lab_id==lab then found=k;break;end;end
        if found>0 then
            if first=="" then first=lab;end
            html=html+"<a href=""#"+lab+""" data-lab="""+lab+"""><strong>"+lab+"</strong><small>Atlikta</small></a>";
        else html=html+"<span><strong>"+lab+"</strong><small>Dar neatlikta</small></span>";end
    end
    html=html+"</nav>";
    for k=1:length(reports)
        q=reports(k);cfg=mo_config(q.lab_id,p.student.number);protocol=mo_protocol(q.lab_id,cfg);
        s=struct("student",q.student,"cfg",cfg,"protocol",protocol,"records",mo_record_list(q.records));
        child=mo5_student_html(s,q);hidden="";if q.lab_id<>first then hidden=" hidden";end
        html=html+"<section class=""portfolio-panel"" id="""+q.lab_id+""" data-panel="""+q.lab_id+""""+hidden+"><div class=""panel-label"">"+mo_html(q.lab_id+" · "+protocol.title)+"</div><iframe class=""report-frame"" title="""+mo_html(q.lab_id+" ataskaita")+""" srcdoc="""+mo_html(child)+"""></iframe></section>";
    end
    html=html+"</div><script id=""mo-data"" type=""application/json"">"+mo5_json(p)+"</script></main><script>"+mo7_portfolio_script()+"</script></body></html>";
endfunction
function script=mo7_portfolio_script()
    script=strcat([ ...
    "(()=>{const panels=[...document.querySelectorAll(''[data-panel]'')],links=[...document.querySelectorAll(''[data-lab]'')];"; ...
    "function fit(f){try{const d=f.contentDocument;if(!d)return;const m=d.querySelector(''main'')||d.body;if(!m)return;const c=f.contentWindow.getComputedStyle(m),h=Math.max(650,Math.ceil(m.getBoundingClientRect().height+(parseFloat(c.marginTop)||0)+(parseFloat(c.marginBottom)||0)));if(Math.abs(f.getBoundingClientRect().height-h)>1)f.style.height=h+''px''}catch(e){}}"; ...
    "function show(){let id=location.hash.slice(1);if(!panels.some(p=>p.dataset.panel===id))id=panels[0]?.dataset.panel;panels.forEach(p=>{p.hidden=p.dataset.panel!==id;if(!p.hidden){const f=p.querySelector(''iframe'');requestAnimationFrame(()=>fit(f))}});links.forEach(a=>a.setAttribute(''aria-current'',String(a.dataset.lab===id)))}"; ...
    "for(const p of panels){const f=p.querySelector(''iframe'');f.addEventListener(''load'',()=>{fit(f);try{const d=f.contentDocument;new ResizeObserver(()=>{if(!p.hidden)fit(f)}).observe(d.body);d.addEventListener(''change'',()=>requestAnimationFrame(()=>fit(f)))}catch(e){}})}"; ...
    "addEventListener(''hashchange'',show);addEventListener(''resize'',()=>{for(const p of panels)if(!p.hidden)fit(p.querySelector(''iframe''))});"; ...
    "document.querySelector(''[data-print-selected]'').addEventListener(''click'',()=>{const p=panels.find(p=>!p.hidden);if(p){const w=p.querySelector(''iframe'').contentWindow;w.focus();w.print()}});show()})();" ...
    ],ascii(10));
endfunction
function [known,alive]=mo7_pid_state(pid,osname)
    known=%f;alive=%t;
    if argn(2)<2 then osname=getos();end
    if type(pid)<>1 | size(pid,"*")<>1 | ~isreal(pid) | isnan(pid) | isinf(pid) | pid<1 | floor(pid)<>pid then return;end
    number=msprintf("%.0f",pid);
    if osname=="Windows" then
        q=ascii(34);command="tasklist /FI "+q+"PID eq "+number+q+" /FO CSV /NH";
        try [lines,status]=unix_g(command);catch return;end
        if status<>0 then return;end
        alive=%f;known=%t;
        for line=matrix(lines,1,-1)
            markers=strindex(line,q+","+q);
            if isempty(markers) then continue;end
            tail=part(line,markers(1)+3:length(line));finish=strindex(tail,q);
            if isempty(finish) then known=%f;alive=%t;return;end
            value=bench_safe_number(part(tail,1:finish(1)-1));
            if isnan(value) then known=%f;alive=%t;return;end
            if value==pid then alive=%t;return;end
        end
    else
        try [lines,status]=unix_g("LC_ALL=C kill -0 "+number+" 2>&1");catch return;end
        if status==0 then known=%t;alive=%t;
        elseif ~isempty(strindex(strcat(lines," "),"No such process")) then known=%t;alive=%f;
        end
    end
endfunction
function lock=mo7_lock(path)
    lock=path+".lock.tmp";
    if isfile(lock) then
        stale=%f;
        try
            raw=strcat(mgetl(lock),ascii(10));if ~mo_json_safe(raw) then error("lock");end
            owner=fromJSON(raw);[known,alive]=mo7_pid_state(owner.pid);stale=known & ~alive;
        catch stale=%f;end
        if stale then
            if raw==strcat(mgetl(lock),ascii(10)) then deletefile(lock);end
        end
    end
    if isfile(lock) then error("Bendras failas dabar įrašomas kitame lange. Po kelių sekundžių bandykite dar kartą.");end
    try bench_write_new(lock,toJSON(struct("pid",getpid(),"created",floor(getdate("s")))));
    catch error("Bendro failo įrašymo pradėti nepavyko. Patikrinkite aplanko teises arba bandykite dar kartą.");end
endfunction
function mo7_unlock(lock)
    // Release the exact lock acquired by this export; do not rely on a prior stat.
    removed=deletefile(lock);
    if ~removed then if isfile(lock) then error("Nepavyko užbaigti bendro failo įrašymo. Bandykite dar kartą.");end;end
endfunction
function same=mo7_same_data(a,b)
    same=%f;
    if typeof(a)=="list" | typeof(b)=="list" then
        try
            aa=mo_record_list(a);bb=mo_record_list(b);if length(aa)<>length(bb) then return;end
            for k=1:length(aa);if ~mo7_same_data(aa(k),bb(k)) then return;end;end
            same=%t;
        catch same=%f;end
        return;
    end
    if typeof(a)=="st" & typeof(b)=="st" then
        if size(a,"*")<>size(b,"*") then return;end
        names=fieldnames(b);if size(fieldnames(a),"*")<>size(names,"*") then return;end
        for k=1:size(a,"*")
            for key=matrix(names,1,-1)
                if ~isfield(a,key) then return;end
                if ~mo7_same_data(a(k)(key),b(k)(key)) then return;end
            end
        end
        same=%t;return;
    end
    same=mo5_same(a,b);
endfunction
function mo7_write_portfolio(path,p)
    html=mo7_portfolio_html(p);
    if size(ascii(html),"*")>15*1024*1024 then error("Bendras failas per didelis. Ankstesnis failas išsaugotas.");end
    tmp=path+".writing-"+bench_id()+".tmp";backup=path+".previous";
    try
        bench_write_new(tmp,html);
        [kind,saved,why]=mo_read_report(tmp);
        if kind<>1 then error("Nepavyko perskaityti parengto bendro failo: "+why);end
        [valid,why,reports]=mo7_portfolio_reports(saved);if ~valid then error(why);end
        if ~mo7_same_data(saved,p) then error("Parengto failo duomenys nesutampa.");end
        mo7_verify_children(reports);
        if isfile(path) then
            if isfile(backup) then deletefile(backup);end
            [ok,msg]=copyfile(path,backup);if ~ok then error("Nepavyko išsaugoti ankstesnio failo kopijos: "+msg);end
        end
        [ok,msg]=movefile(tmp,path);if ~ok then error("Bendro failo pakeisti nepavyko: "+msg);end
    catch
        failure=strcat(lasterror()," ");if isfile(tmp) then deletefile(tmp);end
        // A failed replacement must not strand the previous completed works.
        if ~isfile(path) & isfile(backup) then
            try
                previous=mo7_existing(backup,p.student);
                if length(previous)>0 then [restored,restoreMessage]=copyfile(backup,path);end
            catch
                // The verified backup remains available for the next retry.
            end
        end
        error(failure);
    end
endfunction
function path=mo7_export_to(s,path,canonical)
    if isdir(path) then error("Ataskaitos vietoje yra aplankas. Pasirinkite kitą vietą.");end
    folder=fileparts(path);if ~isdir(folder) then [ok,msg]=mkdir(folder);if ~ok then error(msg);end;end
    lock=mo7_lock(path);
    try
        reports=mo7_existing(path,s.student);
        if canonical<>path then
            source=mo7_existing(canonical,s.student);
            for k=1:length(source);reports=mo7_put_report(reports,source(k),%t);end
        end
        reports=mo7_migrate(reports,s);payload=mo_report_payload(s);
        [valid,why,stats]=mo_report_verify(payload);if ~valid then error("Ataskaita neparengta: "+why);end
        reports=mo7_put_report(reports,payload,%t);mo7_verify_children(reports);
        p=mo7_envelope(s.student,reports);mo7_write_portfolio(path,p);mo7_unlock(lock);
    catch failure=strcat(lasterror()," ");mo7_unlock(lock);error(failure);end
endfunction
function path=mo7_export(s)
    path=mo7_canonical_path(s.student);
    try path=mo7_export_to(s,path,path);
    catch
        failure=strcat(lasterror()," ");fallback="";
        if isfield(s,"reportFolder") then
            if s.reportFolder<>"" & s.reportFolder<>fileparts(path) then
                [dir,name,ext]=fileparts(path);fallback=fullfile(s.reportFolder,name+ext);
            end
        end
        // A damaged existing canonical file is never bypassed or overwritten.
        if fallback<>"" then
            mo7_existing(path,s.student);path=mo7_export_to(s,fallback,path);
        else error(failure);end
    end
endfunction
function dest=mo7_export_copy(s,folder)
    if type(folder)<>10 | size(folder,"*")<>1 | stripblanks(folder)=="" then error("Pasirinkite ataskaitos aplanką.");end
    canonical=mo7_canonical_path(s.student);[dir,name,ext]=fileparts(canonical);dest=fullfile(folder,name+ext);
    dest=mo7_export_to(s,dest,canonical);
endfunction
