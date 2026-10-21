// Bendri tik matavimų darbo eigos duomenys. Studentų tekstas nevykdomas.
function s=mo_num(x)
    s=msprintf("%.8g",x);
endfunction
function s=mo_display(x)
    s=msprintf("%.2f",x);
    if abs(x)<.005 then s="0.00"; end
endfunction
function ok=mo_wires_equal(a,b)
    ok=%f;
    if size(a,1)<>size(b,1) then return; end
    if size(a,"*")==0 & size(b,"*")==0 then ok=%t; return; end
    if size(a,2)<>2 | size(b,2)<>2 then return; end
    used=zeros(size(b,1),1);
    for i=1:size(a,1)
        hit=0;
        for j=1:size(b,1)
            if used(j)==0 then
                if and(a(i,:)==b(j,:)) | and(a(i,:)==b(j,[2 1])) then hit=j; break; end
            end
        end
        if hit==0 then return; end
        used(hit)=1;
    end
    ok=%t;
endfunction
function cfg=mo_config(lab,n)
    execstr("cfg=ld"+part(lab,3:length(lab))+"_variant_config(n);");
endfunction

// A partial wiring state may contain only unique undirected required cables.
function ok=mo_wires_subset(a,b)
    ok=%f;
    if isempty(a) then ok=%t;return;end
    if type(a)<>10 | size(a,2)<>2 | size(b,2)<>2 then return;end
    for k=1:size(a,1)
        if a(k,1)==a(k,2) then return;end
        hit=%f;
        for j=1:size(b,1)
            if and(a(k,:)==b(j,:)) | and(a(k,:)==b(j,[2 1])) then hit=%t;break;end
        end
        if ~hit then return;end
        for j=1:k-1
            if and(a(k,:)==a(j,:)) | and(a(k,:)==a(j,[2 1])) then return;end
        end
    end
    ok=%t;
endfunction
function p=mo_protocol(lab,cfg)
    execstr("p=mo_protocol_"+part(lab,3:length(lab))+"(cfg);");
    p=mo_public_protocol(p);
endfunction
function r=mo_measure(lab,cfg,t,wires)
    // Verification/export must not replace a live bench's GUI-bearing state.
    execstr("global "+lab+";modelSnapshot="+lab+";");
    try
        execstr("r=mo_measure_"+part(lab,3:length(lab))+"(cfg,t,wires);");
        r.names=mo_public_text(r.names);
        n=size(r.values,"*");
        if n==0 | size(r.ids,"*")<>n | size(r.units,"*")<>n | size(r.names,"*")<>n then error("Netinkamas matavimo prietaiso aprašas."); end
        if ~isreal(r.values) | or(isnan(r.values)) | or(isinf(r.values)) then error("Prietaisas nepateikė baigtinio rodmens."); end
    catch
        modelFailure=strcat(lasterror()," ");execstr(lab+"=modelSnapshot;");error(modelFailure);
    end
    execstr(lab+"=modelSnapshot;");
endfunction
function lines=mo_analysis(lab,cfg,records)
    execstr("lines=mo_analysis_"+part(lab,3:length(lab))+"(cfg,records);");
endfunction
function ok=mo_copy_matches(raw,shown)
    a=bench_safe_number(raw); b=bench_safe_number(shown); ok=%f;
    if isnan(a) | isnan(b) then return; end
    ok=abs(a-b)<=max(1d-12,abs(b)*1d-10);
endfunction

function records=mo_record_list(value)
    records=list();
    if typeof(value)=="list" then records=value; return; end
    if isempty(value) then return; end
    if typeof(value)<>"st" then error("Netinkami išsaugoti matavimų įrašai."); end
    for k=1:size(value,"*"); records($+1)=value(k); end
endfunction

// Syntax gate: some Scilab releases abort natively on malformed fromJSON input.
// This checks JSON grammar before passing local checkpoints/reports to it.
function i=mo_json_space(s,i)
    while i<=length(s)
        if ~or(s(i)==[9 10 13 32]) then return; end
        i=i+1;
    end
endfunction
function [ok,i]=mo_json_string(s,i)
    ok=%f; n=length(s);
    if i>n then return; end
    if s(i)<>34 then return; end
    i=i+1;
    while i<=n
        ch=s(i);
        if ch==34 then i=i+1; ok=%t; return; end
        if ch<32 then return; end
        if ch==92 then
            i=i+1; if i>n then return; end
            ch=s(i);
            if ch==117 then
                if i+4>n then return; end
                for j=i+1:i+4
                    if ~or(s(j)==[48:57 65:70 97:102]) then return; end
                end
                code=hex2dec(ascii(s(i+1:i+4)));
                if code>=55296 & code<=56319 then
                    if i+10>n then return; end
                    if s(i+5)<>92 | s(i+6)<>117 then return; end
                    for j=i+7:i+10
                        if ~or(s(j)==[48:57 65:70 97:102]) then return; end
                    end
                    low=hex2dec(ascii(s(i+7:i+10)));
                    if low<56320 | low>57343 then return; end
                    i=i+6;
                elseif code>=56320 & code<=57343 then return;
                end
                i=i+4;
            elseif ~or(ch==[34 92 47 98 102 110 114 116]) then return;
            end
        end
        i=i+1;
    end
endfunction
function [ok,i]=mo_json_value(s,i,depth)
    ok=%f; i=mo_json_space(s,i); n=length(s);
    if i>n | depth>48 then return; end
    ch=s(i);
    if ch==34 then [ok,i]=mo_json_string(s,i); return; end
    if ch==123 | ch==91 then
        close=125; if ch==91 then close=93; end
        object=(ch==123); i=mo_json_space(s,i+1);
        if i<=n then if s(i)==close then i=i+1; ok=%t; return; end; end
        while i<=n
            if object then
                [valid,i]=mo_json_string(s,i); if ~valid then return; end
                i=mo_json_space(s,i); if i>n then return; end
                if s(i)<>58 then return; end
                i=i+1;
            end
            [valid,i]=mo_json_value(s,i,depth+1); if ~valid then return; end
            i=mo_json_space(s,i); if i>n then return; end
            ch=s(i);
            if ch==close then i=i+1; ok=%t; return; end
            if ch<>44 then return; end
            i=mo_json_space(s,i+1);
        end
        return;
    end
    for word=["true" "false" "null"]
        w=length(word);
        if i+w-1<=n then
            if and(s(i:i+w-1)==ascii(word)) then i=i+w; ok=%t; return; end
        end
    end
    start=i;
    while i<=n
        if ~or(s(i)==[48:57 46 101 69 43 45]) then break; end
        i=i+1;
    end
    if i==start then return; end
    token=ascii(s(start:i-1));
    if isempty(regexp(token,"/^-?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?$/")) then return; end
    if isnan(bench_safe_number(token)) then return; end
    ok=%t;
endfunction
function ok=mo_json_safe(s)
    ok=%f;
    if type(s)<>10 then return; end
    if size(s,"*")<>1 then return; end
    if length(s)==0 | length(s)>2000000 then return; end
    try
        // Index UTF-8 bytes once; repeated part(string, i) rescans long documents.
        s=ascii(s);
        // JSON strings must contain valid UTF-8, including when a file is damaged.
        high=find(s>=128);j=1;
        while j<=size(high,"*")
            pos=high(j);lead=s(pos);count=0;
            if lead>=194 & lead<=223 then count=1;
            elseif lead>=224 & lead<=239 then count=2;
            elseif lead>=240 & lead<=244 then count=3;
            else return;end
            if pos+count>length(s) then return;end
            tail=s(pos+1:pos+count);
            if or(tail<128) | or(tail>191) then return;end
            if lead==224 & tail(1)<160 then return;end
            if lead==237 & tail(1)>159 then return;end
            if lead==240 & tail(1)<144 then return;end
            if lead==244 & tail(1)>143 then return;end
            j=j+count+1;
        end
        start=mo_json_space(s,1); if start>length(s) then return; end
        if s(start)<>123 then return; end
        [valid,i]=mo_json_value(s,start,0);
        if valid then ok=mo_json_space(s,i)>length(s); end
    catch
        ok=%f;
    end
endfunction
