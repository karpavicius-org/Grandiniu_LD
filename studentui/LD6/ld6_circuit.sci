function wires=ld6_canonical_wires(mode)
    wires=emptystr(0,2);
    if ~ld6_valid_index(mode,4) then return; end
    wires=["E1_P" "K1";"K2" "A_P";"A_N" "R_A";"V_P" "R_A";"V_N" "R_B"];
    select mode
    case 1 then wires=[wires;"R_B" "E1_N"];
    case 2 then wires=[wires;"R_B" "E2_N";"E2_P" "E1_N"];
    case 3 then wires=[wires;"R_B" "E2_P";"E2_N" "E1_N"];
    case 4 then wires=[wires;"R_B" "E1_N";"E1_P" "E2_P";"E1_N" "E2_N"];
    end
endfunction

function mode=ld6_stage_mode(step)
    mapping=[1 1 2 3 4 4]; mode=mapping(step);
endfunction

function editable=ld6_wiring_editable()
    global LD6;
    editable=~LD6.demoMode & or(LD6.step==[1 3 4 5]) & LD6.wireMode==ld6_stage_mode(LD6.step);
endfunction

function [ok,reason]=ld6_wiring_valid(wires)
    global LD6;
    ok=%f; reason="Sujunkite grandinę pagal Pagalba → Kaip sujungti.";
    if ~ld6_valid_index(LD6.wireMode,4) then return; end
    canonical=ld6_canonical_wires(LD6.wireMode);
    if wires==[] then return; end
    if type(wires)<>10 | size(wires,2)<>2 then reason="Netinkami sujungimo duomenys."; return; end
    if size(wires,1)>size(canonical,1) then reason="Per daug laidų."; return; end
    for index=1:size(canonical,1)
        present=%f;
        for row=1:size(wires,1)
            if and(wires(row,:)==canonical(index,:)) | and(wires(row,:)==canonical(index,[2 1])) then present=%t; end
        end
        if ~present then
            reason="Trūksta jungties: "+ld6_terminal_name(canonical(index,1))+" → "+ld6_terminal_name(canonical(index,2))+".";
            return;
        end
    end
    ok=%t; reason="";
endfunction

function values=ld6_reference(mode)
    global LD6;
    cfg=LD6.cfg;
    select mode
    case 1 then current=cfg.E1/(cfg.R+cfg.r1);
    case 2 then current=(cfg.E1+cfg.E2)/(cfg.R+cfg.r1+cfg.r2);
    case 3 then current=(cfg.E1-cfg.E2)/(cfg.R+cfg.r1+cfg.r2);
    case 4 then current=(cfg.E1/cfg.r1+cfg.E2/cfg.r2)/(1/cfg.R+1/cfg.r1+1/cfg.r2)/cfg.R;
    end
    voltage=current*cfg.R; first=current; second=0;
    if mode==2 then second=current; end
    if mode==3 then second=-current; end
    if mode==4 then first=(cfg.E1-voltage)/cfg.r1; second=(cfg.E2-voltage)/cfg.r2; end
    values=[voltage current*1000 first*1000 second*1000];
endfunction

function [voltage,current,ok,message,branches]=ld6_measure_values()
    global LD6;
    voltage=%nan; current=%nan; branches=[%nan %nan]; ok=%f; message="";
    if ~LD6.powerOn then message="Pirmiausia įjunkite maitinimą."; return; end
    if ~LD6.switchOn then message="Uždarykite jungiklį."; return; end
    [valid,message]=ld6_wiring_valid(LD6.wires);
    if ~valid then return; end
    bench_core_require(); cfg=LD6.cfg;
    [values,status]=call("ld_sources",LD6.wireMode,1,"i",[cfg.E1 cfg.E2 cfg.R cfg.r1 cfg.r2],2,"d", ...
        "out",[1 4],3,"d",[1 1],4,"i");
    if status<>0 then message="C++ šaltinių modelis negali apskaičiuoti grandinės."; return; end
    voltage=values(1); current=values(2); branches=values(3:4); ok=%t;
endfunction

function ld6_init_state()
    global LD6;
    assessment=%t; practice=%f;
    if isfield(LD6,"assessment") then assessment=LD6.assessment; end
    if isfield(LD6,"practice_used") then practice=LD6.practice_used; end
    LD6.step=1; LD6.done=zeros(1,6)==1; LD6.skipped=zeros(1,6)==1;
    LD6.powerOn=%f; LD6.switchOn=%f; LD6.wireMode=1;
    LD6.wires=emptystr(0,2); LD6.journal=[];
    LD6.wires_by_mode=list(); LD6.report_wires=list();
    for index=1:4
        LD6.wires_by_mode(index)=emptystr(0,2); LD6.report_wires(index)=emptystr(0,2);
    end
    LD6.answers=emptystr(6,8); LD6.demoMode=%f; LD6.lastMeasurement=%nan; LD6.pending="";
    LD6.assessment=assessment; LD6.practice_used=practice;
endfunction

function expected=ld6_expected_answers()
    expected=%nan*ones(6,8);
    first=ld6_reference(1); series=ld6_reference(2); opposing=ld6_reference(3); parallel=ld6_reference(4);
    expected(2,1)=first(2);
    expected(4,1:4)=[series(1:2) opposing(1:2)];
    expected(5,1:4)=parallel;
    expected(6,1:2)=[1 2];
endfunction

function rows=ld6_journal_rows(tag)
    global LD6;
    rows=[];
    if LD6.journal==[] then return; end
    indices=find(LD6.journal(:,3)==tag);
    if indices<>[] then rows=LD6.journal(indices,[1 2 4 5]); end
endfunction
