// Presentation vocabulary only. Numeric values, terminal IDs and wires stay intact.
// Call this for application captions, never for student identities or typed data.
function out=mo_public_text(value)
    out=value;if type(value)<>10 then return;end
    forms=["virtualus" "virtualaus" "virtualiam" "virtualų" "virtualiu" "virtualiame" ...
        "virtuali" "virtualios" "virtualiai" "virtualią" "virtualia" "virtualioje" ...
        "virtualūs" "virtualių" "virtualiems" "virtualius" "virtualiais" "virtualiuose" ...
        "virtualioms" "virtualias" "virtualiomis" "virtualiose"];
    ends=[" " "." "," ":" ";" "!" "?" ")" "]"];
    for index=1:size(value,"*")
        original=value(index);
        if isempty(strindex(convstr(original,"l"),"virtual")) then continue;end
        text=" "+original+" ";capitalize=%f;
        for word=forms
            variants=[word convstr(part(word,1),"u")+part(word,2:length(word)) convstr(word,"u")];
            for form=variants
                if length(original)>=length(form)+1 then
                    if part(original,1:length(form)+1)==form+" " & part(form,1)==convstr(part(form,1),"u") then capitalize=%t;end
                end
                for ending=ends
                    replacement=ending;if ending==" " then replacement=" ";end
                    text=strsubst(text," "+form+ending," "+replacement);
                end
            end
        end
        text=stripblanks(text);
        while ~isempty(strindex(text,"  "));text=strsubst(text,"  "," ");end
        for ending=["." "," ":" ";" "!" "?" ")" "]"];text=strsubst(text," "+ending,ending);end
        if capitalize & text<>"" then text=convstr(part(text,1),"u")+part(text,2:length(text));end
        out(index)=text;
    end
endfunction
function trial=mo_public_trial(trial)
    for key=["title" "condition" "why" "purpose"]
        if isfield(trial,key) then trial(key)=mo_public_text(trial(key));end
    end
    if isfield(trial,"topology") then
        if trial.topology=="ld7_virtualus_tj" then trial.topology="ld7_tj";end
    end
endfunction
function protocol=mo_public_protocol(protocol)
    for key=["title" "aim" "background"]
        if isfield(protocol,key) then protocol(key)=mo_public_text(protocol(key));end
    end
    for k=1:length(protocol.trials);protocol.trials(k)=mo_public_trial(protocol.trials(k));end
    if isfield(protocol,"components") then
        for k=1:length(protocol.components)
            component=protocol.components(k);
            if isfield(component,"name") then component.name=mo_public_text(component.name);end
            if isfield(component,"labels") then component.labels=mo_public_text(component.labels);end
            protocol.components(k)=component;
        end
    end
endfunction
function ok=rt_protocol_compatible(raw,protocol)
    ok=%f;
    try
        if type(raw)<>10 | size(raw,"*")<>1 then return;end
        if raw==rt_protocol_key(protocol) then ok=%t;return;end
        // The shared syntax gate deliberately accepts top-level objects only.
        // Older signatures contain a trial array, so validate it inside an object.
        body="{"+ascii(34)+"trials"+ascii(34)+":"+raw+"}";
        if ~mo_json_safe(body) then return;end
        decoded=fromJSON(body);old=mo_record_list(decoded.trials);
        if length(old)<>length(protocol.trials) then return;end
        for k=1:length(old)
            // Only the enumerated vocabulary conversion is accepted. All
            // remaining conditions, modes, targets, values and wires must match.
            if ~mo5_same(mo_public_trial(old(k)),protocol.trials(k)) then return;end
        end
        ok=%t;
    catch ok=%f;end
endfunction
