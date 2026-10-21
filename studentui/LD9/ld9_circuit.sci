// ============================================================================
// LD9 grandinės modelis: viena nuosekli RLC grandinė, trys dažnio taškai
// (0,5·f0, f0, 2·f0) ir keturi voltmetro taikiniai (R, L, C, generatorius).
// Fizika — per bendrą ld_ac (kompleksinė MNA): [XL XC |Z| I UR UL UC ULC P φ].
// Žurnalas: [U V, I mA, taškas 1–3, f Hz, taikinys 1–4].
// ============================================================================

function wires=ld9_canonical_wires(target)
    if argn(2)<1 then target=1;end
    plan=ld9_instrument_plan(target);wires=plan.wires;
endfunction

function plan=ld9_instrument_plan(target)
    wires=emptystr(0,2);
    if ~ld9_valid_index(target,4) then plan=struct("wires",wires);return;end
    base=["GEN_P" "K1";"K2" "A_P";"A_N" "R_A";"R_B" "L_A";"L_B" "C_A";"C_B" "GEN_N"];
    ends=["R_A" "R_B";"L_A" "L_B";"C_A" "C_B";"GEN_P" "GEN_N"];
    wires=[base;"V_P" ends(target,1);"V_N" ends(target,2)];
    plan=struct("wires",wires,"target",target);
endfunction

function [ok,target]=ld9_detect_measurement(wires)
    ok=%f;target=0;
    for t=1:4
        if ld9_wires_equal(wires,ld9_canonical_wires(t)) then ok=%t;target=t;return;end
    end
endfunction
function same=ld9_wires_equal(actual,planned)
    same=%f;
    if type(actual)<>10 | size(actual,2)<>2 then return;end
    if size(actual,1)<>size(planned,1) then return;end
    used=zeros(size(planned,1),1)==1;
    for row=1:size(actual,1)
        match=0;
        for k=1:size(planned,1)
            if ~used(k) then
                if and(actual(row,:)==planned(k,:)) | and(actual(row,:)==planned(k,[2 1])) then match=k;break;end
            end
        end
        if match==0 then return;end
        used(match)=%t;
    end
    same=and(used);
endfunction

function editable = ld9_wiring_editable()
    global LD9;
    editable = ~LD9.demoMode & LD9.step == 1;
endfunction

function [ok,reason]=ld9_wiring_valid(wires)
    [ok,target]=ld9_detect_measurement(wires);
    reason="Prijunkite visus grandinės ir matavimo prietaisų laidus pagal geltonus kontaktus.";
    if ok then reason="";end
endfunction

function values = ld9_reference(k)
    // [U_taikiniui, I mA, UR, UL, UC, U] ties dažniu k·f0 (k = 0,5/1/2).
    global LD9;
    cfg = LD9.cfg; target = LD9.target;
    if argn(2) < 1 then k = ld9_stage_freq(LD9.step); end
    v = bench_cpp_ac(3, cfg.E, k/sqrt(cfg.L*cfg.C)/(2*%pi), cfg.R, cfg.L, cfg.C);
    u = cfg.E;
    if target == 1 then u = v(5); elseif target == 2 then u = v(6); elseif target == 3 then u = v(7); end
    values = [u, v(4)*1000, v(5), v(6), v(7), cfg.E];
endfunction

function f = ld9_current_frequency()
    // Naudoja tik esamą dažnio mygtuką: etapams be dažnio (1, 5, 6) kviečiama
    // tik kai freqPoint > 0.
    global LD9;
    kk = [0.5 1 2];
    f = kk(LD9.freqPoint)/sqrt(LD9.cfg.L*LD9.cfg.C)/(2*%pi);
endfunction

function [voltage, current, ok, message] = ld9_measure_values()
    global LD9;
    voltage = %nan; current = %nan; ok = %f; message = "";
    if ~LD9.powerOn then message = "Įjunkite maitinimą."; return; end
    if ~LD9.switchOn then message = "Uždarykite jungiklį."; return; end
    [valid, message] = ld9_wiring_valid(LD9.wires);
    if ~valid then return; end
    if LD9.freqPoint == 0 then message = "Pasirinkite šio etapo dažnį: 0,5·f0, f0 arba 2·f0."; return; end
    [valid,target]=ld9_detect_measurement(LD9.wires);
    if ~valid then message="Matavimo prietaisas neprijungtas.";return;end
    bench_core_require();
    kk = [0.5 1 2];
    f = kk(LD9.freqPoint)/sqrt(LD9.cfg.L*LD9.cfg.C)/(2*%pi);
    v = bench_cpp_ac(3, LD9.cfg.E, f, LD9.cfg.R, LD9.cfg.L, LD9.cfg.C);
    voltage = LD9.cfg.E;
    if target == 1 then voltage = v(5); elseif target == 2 then voltage = v(6); elseif target == 3 then voltage = v(7); end
    current = v(4)*1000; ok = %t;
endfunction

function ld9_init_state()
    global LD9;
    assessment=%t; practice=%f;
    if isfield(LD9,"assessment") then assessment=LD9.assessment; end
    if isfield(LD9,"practice_used") then practice=LD9.practice_used; end
    LD9.guide_enabled = %f;
    LD9.step = 1; LD9.done = zeros(1, 6) == 1; LD9.skipped = zeros(1, 6) == 1;
    LD9.powerOn = %f; LD9.switchOn = %f; LD9.freqPoint = 0; LD9.target = 0;
    LD9.wires = emptystr(0, 2); LD9.journal = [];
    LD9.report_wires = emptystr(0, 2);
    LD9.answers = emptystr(6, 8); LD9.demoMode = %f; LD9.lastMeasurement = %nan; LD9.pending = "";
    LD9.assessment=assessment; LD9.practice_used=practice;
endfunction

function expected = ld9_expected_answers()
    global LD9;
    cfg = LD9.cfg;
    expected = %nan * ones(6, 8);
    f0 = 1/(2*%pi*sqrt(cfg.L*cfg.C));
    expected(1, 1) = f0;
    v0 = bench_cpp_ac(3, cfg.E, f0, cfg.R, cfg.L, cfg.C);
    expected(3, 1:2) = [v0(6)/cfg.E, v0(6)-v0(7)];
    v1 = bench_cpp_ac(3, cfg.E, 0.5*f0, cfg.R, cfg.L, cfg.C);
    i1 = v1(4)*1000;
    expected(5, 1:6) = [sqrt(v1(5)^2+(v1(6)-v1(7))^2), cfg.E/v1(4), v1(5)/cfg.E, ...
        v1(5)*i1, (v1(6)-v1(7))*i1, cfg.E*i1];
    expected(6, 1:3) = [1 1 1];
endfunction

function rows = ld9_journal_rows(tag, target)
    global LD9;
    rows = [];
    if LD9.journal == [] then return; end
    indices = find(LD9.journal(:, 3) == tag & LD9.journal(:, 5) == target);
    if indices <> [] then rows = LD9.journal(indices, :); end
endfunction
