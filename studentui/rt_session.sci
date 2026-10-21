function snapshot=mo_snapshot()
    global MO;
    snapshot=struct("workflow","measurement-tasks-v5","checkpoint_revision",2,"protocolSignature",rt_protocol_key(MO.protocol),"lab",MO.lab,"student",MO.student, ...
        "trialIndex",MO.trialIndex,"readingIndex",MO.readingIndex,"phase",MO.phase, ...
        "wires",MO.wires,"pending",MO.pending,"helpEnabled",MO.helpEnabled,"helpUsed",MO.helpUsed,"records",MO.records, ...
        "displayed",MO.displayed,"copied",MO.copied, ...
        "wiringErrors",MO.wiringErrors,"copyErrors",MO.copyErrors,"reportPath",MO.reportPath, ...
        "reportFolder",MO.reportFolder,"sessionId",MO.sessionId,"createdAt",MO.createdAt,"events",MO.events);
endfunction

function mo_checkpoint()
    global MO;
    try
        path=rt_checkpoint_path();
        // The previous checkpoint survives a failed write.
        tmp=path+".new"; mputl(toJSON(mo_snapshot()),tmp);
        [ok,msg]=movefile(tmp,path); if ~ok then error(msg); end
        MO.resumePath=path;
    catch
        // Never discard the current measurements because a checkpoint failed.
        MO.message="Darbas vyksta šiame lange. Automatinės darbo kopijos išsaugoti nepavyko: "+strcat(lasterror()," ");
    end
endfunction

function mo_restore()
    global MO;
    path=rt_checkpoint_path();
    if ~isfile(path) then return; end
    try
        rawCheckpoint=strcat(mgetl(path),ascii(10));
        // Ignore incompatible provisional checkpoints before parsing.
        // The syntax gate below also rejects damaged/truncated JSON safely.
        if isempty(strindex(rawCheckpoint,ascii(34)+"checkpoint_revision"+ascii(34))) then return; end
        if ~mo_json_safe(rawCheckpoint) then return; end
        s=fromJSON(rawCheckpoint);
        s.records=mo_record_list(s.records);
        if s.checkpoint_revision<>2 then return;end
        if ~rt_protocol_compatible(s.protocolSignature,MO.protocol) then return;end
        if s.workflow<>"measurement-tasks-v5" | s.lab<>MO.lab then return; end
        if s.student.name<>MO.student.name | s.student.group<>MO.student.group | s.student.number<>MO.student.number then return; end
        if ~or(s.phase==["wiring" "copy" "between" "complete"]) then return; end

        if s.trialIndex<1 | s.trialIndex>length(MO.protocol.trials) | floor(s.trialIndex)<>s.trialIndex then return; end
        count=length(MO.protocol.trials);
        if s.phase=="between" & s.trialIndex>=count then return;end
        if s.phase=="complete" & s.trialIndex<>count then return;end
        t=MO.protocol.trials(s.trialIndex);
        if s.phase=="wiring" then
            if ~mo_wires_subset(s.wires,t.wires) then return;end
        elseif ~mo_wires_equal(s.wires,t.wires) then return;end
        // Only resume a checkpoint whose already recorded physical measurements still agree.
        for k=1:length(s.records)
            rec=s.records(k); t=MO.protocol.trials(k);
            if ~mo_wires_equal(rec.wires,t.wires) then return; end
            expected=mo_measure(MO.lab,MO.cfg,t,rec.wires);
            if size(expected.values,"*")<>size(rec.reading.values,"*") | size(expected.values,"*")<>size(rec.copied,"*") then return;end
            if ~and(expected.units==rec.reading.units) then return;end
            if ~and(expected.ids==rec.reading.ids) | or(abs(expected.values-rec.reading.values)>max(1d-10,max(abs(expected.values))*1d-10)) then return; end
            for j=1:size(expected.values,"*")
                if ~mo_copy_matches(rec.copied(j),mo_display(expected.values(j))) then return; end
                rec.displayed(j)=mo_display(expected.values(j));
            end
            rec.trial=t;rec.reading=expected;s.records(k)=rec;
        end
        expectedCount=s.trialIndex-1; if s.phase=="between" | s.phase=="complete" then expectedCount=s.trialIndex; end
        if length(s.records)<>expectedCount then return; end
        fields=["sessionId" "createdAt" "reportFolder" "trialIndex" "readingIndex" "phase" "wires" "helpEnabled" "helpUsed" "records" "displayed" "copied" "wiringErrors" "copyErrors"];
        for key=fields; MO(key)=s(key); end
        MO.pending="";MO.events=mo_record_list(s.events);
        if MO.phase=="copy" then
            t=MO.protocol.trials(MO.trialIndex); r=mo_measure(MO.lab,MO.cfg,t,MO.wires);
            if MO.readingIndex<1 | MO.readingIndex>size(r.values,"*") | floor(MO.readingIndex)<>MO.readingIndex then error("Rodmens numeris."); end
            if size(MO.copied,"*")<>size(r.values,"*") then error("Neatitinka išsaugotų rodmenų skaičius."); end
            for j=1:MO.readingIndex-1
                if ~mo_copy_matches(MO.copied(j),mo_display(r.values(j))) then error("Ankstesnis perrašytas rodmuo nesutampa."); end
            end
            MO.current=r;
            for j=1:size(r.values,"*"); MO.displayed(j)=mo_display(r.values(j)); end
        elseif or(MO.phase==["between" "complete"]) then
            // These phases have at least one validated record. The final
            // expected reading above is the actual model result for that
            // record, so the original board and summary can render again.
            MO.current=expected;
            MO.displayed=emptystr(size(expected.values,"*"),1);
            for j=1:size(expected.values,"*"); MO.displayed(j)=mo_display(expected.values(j)); end
        end
        MO.reportPath="";
        if MO.phase=="complete" & s.reportPath<>"" then
            if isfile(s.reportPath) then
                [kind,payload,why]=mo_read_report(s.reportPath);
                if kind==1 then
                    [valid,report]=mo7_find_report(payload,MO.lab,MO.student);
                    if valid then MO.reportPath=s.reportPath;end
                end
            end
        end
        if MO.phase=="complete" & MO.reportPath=="" then
            studentPath=mo7_canonical_path(MO.student);
            if isfile(studentPath) then
                [kind,payload,why]=mo_read_report(studentPath);
                if kind==1 then
                    [valid,report]=mo7_find_report(payload,MO.lab,MO.student);
                    if valid then MO.reportPath=studentPath;end
                end
            end
        end
        MO.message="Ankstesni matavimai atkurti. Tęskite nuo pažymėto veiksmo.";
    catch
        // Invalid/incompatible checkpoint is not a reason to block a new laboratory.
        MO.phase="wiring"; MO.trialIndex=1; MO.readingIndex=1; MO.wires=emptystr(0,2); MO.records=list();
        MO.current=struct(); MO.displayed=emptystr(0,1); MO.copied=emptystr(0,1);
        MO.message="Pradėkite naują matavimų eigą.";
    end
endfunction


function key=rt_protocol_key(p)
    key=toJSON(p.trials);
endfunction
function path=rt_checkpoint_path()
    global MO;
    folder=fullfile(bench_documents(),"Grandiniu_ataskaitos","Darbo_busena_v5");
    if ~isdir(folder) then [ok,msg]=mkdir(folder);if ~ok then error(msg);end;end
    value=5381;codes=ascii(MO.student.group+"|"+MO.student.name);
    for code=codes;value=modulo(value*33+code,4294967291);end
    path=fullfile(folder,MO.lab+"-V"+string(MO.student.number)+"-"+msprintf("%.0f",value)+".json");
endfunction
