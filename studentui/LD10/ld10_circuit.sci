// ============================================================================
// LD10 grandinės modelis: viena lygiagretė RLC grandinė, trys dažnio taškai
// (0,5·f0, f0, 2·f0) ir keturi ampermetro taikiniai (R, L, C šaka, pagrindinė).
// Fizika — ld_ac kind 4: [XL XC |Z| I_bendra IR IL IC |IL−IC| P φ].
// Žurnalas: [I mA, U V, taškas 1–3, f Hz, taikinys 1–4].
// ============================================================================

function wires = ld10_canonical_wires()
    // Lygiagretus jungimas: visos trys šakos tarp tų pačių dviejų mazgų.
    wires = ["GEN_P" "K1";"K2" "A_P";"A_N" "R_A";"R_A" "L_A";"L_A" "C_A"; ...
             "R_B" "GEN_N";"R_B" "L_B";"L_B" "C_B"];
endfunction

function editable = ld10_wiring_editable()
    global LD10;
    editable = ~LD10.demoMode & LD10.step == 1;
endfunction

function [ok, reason] = ld10_wiring_valid(wires)
    ok = %f; reason = "Sujunkite grandinę pagal Pagalba → Kaip sujungti.";
    canonical = ld10_canonical_wires();
    if wires == [] then return; end
    if type(wires) <> 10 | size(wires, 2) <> 2 then reason = "Netinkami sujungimo duomenys."; return; end
    if size(wires, 1) > size(canonical, 1) then reason = "Per daug laidų."; return; end
    for index = 1:size(canonical, 1)
        present = %f;
        for row = 1:size(wires, 1)
            if and(wires(row,:) == canonical(index,:)) | and(wires(row,:) == canonical(index,[2 1])) then present = %t; end
        end
        if ~present then
            reason = "Trūksta laido ["+ld10_terminal_code(canonical(index,1))+"]–["+ld10_terminal_code(canonical(index,2))+"].";
            return;
        end
    end
    ok = %t; reason = "";
endfunction

function values = ld10_reference(k)
    // [U_taikiniui, I mA, UR, UL, UC, U] ties dažniu k·f0 (k = 0,5/1/2).
    global LD10;
    cfg = LD10.cfg; target = LD10.target;
    if argn(2) < 1 then k = ld10_stage_freq(LD10.step); end
    v = bench_cpp_ac(4, cfg.E, k/sqrt(cfg.L*cfg.C)/(2*%pi), cfg.R, cfg.L, cfg.C);
    // ld_ac kind 4 (1-based): v(4)=I bendra, v(5)=IR, v(6)=IL, v(7)=IC.
    current = v(4)*1000;
    if target == 1 then current = v(5)*1000; elseif target == 2 then current = v(6)*1000; elseif target == 3 then current = v(7)*1000; end
    values = [current, cfg.E, v(5)*1000, v(6)*1000, v(7)*1000, v(4)*1000];
endfunction

function f = ld10_current_frequency()
    // Naudoja tik esamą dažnio mygtuką: etapams be dažnio (1, 5, 6) kviečiama
    // tik kai freqPoint > 0.
    global LD10;
    kk = [0.5 1 2];
    f = kk(LD10.freqPoint)/sqrt(LD10.cfg.L*LD10.cfg.C)/(2*%pi);
endfunction

function [voltage, current, ok, message] = ld10_measure_values()
    global LD10;
    voltage = %nan; current = %nan; ok = %f; message = "";
    if ~LD10.powerOn then message = "Įjunkite generatorių [B01]."; return; end
    if ~LD10.switchOn then message = "Uždarykite jungiklį [B02]."; return; end
    [valid, message] = ld10_wiring_valid(LD10.wires);
    if ~valid then return; end
    if LD10.freqPoint == 0 then message = "Pasirinkite dažnį [B10]–[B12]."; return; end
    if LD10.target == 0 then message = "Pasirinkite voltmetro taikinį [B13]–[B16]."; return; end
    bench_core_require();
    kk = [0.5 1 2];
    f = kk(LD10.freqPoint)/sqrt(LD10.cfg.L*LD10.cfg.C)/(2*%pi);
    v = bench_cpp_ac(4, LD10.cfg.E, f, LD10.cfg.R, LD10.cfg.L, LD10.cfg.C);
    current = v(4)*1000;
    if LD10.target == 1 then current = v(5)*1000; elseif LD10.target == 2 then current = v(6)*1000; elseif LD10.target == 3 then current = v(7)*1000; end
    voltage = LD10.cfg.E; ok = %t;
endfunction

function ld10_init_state()
    global LD10;
    assessment=%t; practice=%f;
    if isfield(LD10,"assessment") then assessment=LD10.assessment; end
    if isfield(LD10,"practice_used") then practice=LD10.practice_used; end
    LD10.step = 1; LD10.done = zeros(1, 6) == 1; LD10.skipped = zeros(1, 6) == 1;
    LD10.powerOn = %f; LD10.switchOn = %f; LD10.freqPoint = 0; LD10.target = 0;
    LD10.wires = emptystr(0, 2); LD10.journal = [];
    LD10.report_wires = emptystr(0, 2);
    LD10.answers = emptystr(6, 8); LD10.demoMode = %f; LD10.lastMeasurement = %nan; LD10.pending = "";
    LD10.assessment=assessment; LD10.practice_used=practice;
endfunction

function expected = ld10_expected_answers()
    global LD10;
    cfg = LD10.cfg;
    expected = %nan * ones(6, 8);
    f0 = 1/(2*%pi*sqrt(cfg.L*cfg.C));
    expected(1, 1) = f0;
    v0 = bench_cpp_ac(4, cfg.E, f0, cfg.R, cfg.L, cfg.C);
    expected(3, 1:2) = [v0(6)/v0(4), (v0(6)-v0(7))*1000];
    v1 = bench_cpp_ac(4, cfg.E, 0.5*f0, cfg.R, cfg.L, cfg.C);
    i1 = v1(4)*1000; ir1 = v1(5)*1000; il1 = v1(6)*1000; ic1 = v1(7)*1000;
    expected(5, 1:6) = [sqrt(ir1^2+(il1-ic1)^2), i1/cfg.E, ir1/i1, ...
        cfg.E*ir1, cfg.E*(il1-ic1), cfg.E*i1];
    expected(6, 1:3) = [1 1 1];
endfunction

function rows = ld10_journal_rows(tag, target)
    global LD10;
    rows = [];
    if LD10.journal == [] then return; end
    indices = find(LD10.journal(:, 3) == tag & LD10.journal(:, 5) == target);
    if indices <> [] then rows = LD10.journal(indices, :); end
endfunction
