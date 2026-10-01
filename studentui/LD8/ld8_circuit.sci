// ============================================================================
// LD8 grandinės modelis: kanoniniai laidai pagal režimą (nuosekliai,
// lygiagrečiai, mišriai), C++ MNA matavimas per bench_cpp_dc, laukiami
// atsakymai ir žurnalas. Žurnalas: [U V, I mA, žyma, Re Ω, P mW];
// žymos 1 – nuoseklioji, 2 – lygiagretė, 3 – mišrioji grandinė.
// ============================================================================

function wires = ld8_canonical_wires(mode)
    wires = emptystr(0, 2);
    if ~ld8_valid_index(mode, 3) then return; end
    base = ["E_P" "K1";"K2" "A_P";"A_N" "R1_A";"V_P" "E_P";"V_N" "E_N"];
    select mode
    case 1 then wires = [base;"R1_B" "R2_A";"R2_B" "R3_A";"R3_B" "E_N"];
    case 2 then wires = [base;"R1_A" "R2_A";"R2_A" "R3_A";"R1_B" "E_N";"R1_B" "R2_B";"R2_B" "R3_B"];
    case 3 then wires = [base;"R1_B" "R2_A";"R2_A" "R3_A";"R2_B" "R3_B";"R3_B" "E_N"];
    end
endfunction

function mode = ld8_stage_mode(step)
    mapping = [1 1 2 3 2 1]; mode = mapping(step);
endfunction

function editable = ld8_wiring_editable()
    global LD8;
    editable = ~LD8.demoMode & or(LD8.step == [1 3 4]) & LD8.wireMode == ld8_stage_mode(LD8.step);
endfunction

function [ok, reason] = ld8_wiring_valid(wires)
    global LD8;
    ok = %f; reason = "Sujunkite grandinę pagal Pagalba → Kaip sujungti.";
    if ~ld8_valid_index(LD8.wireMode, 3) then return; end
    canonical = ld8_canonical_wires(LD8.wireMode);
    if wires == [] then return; end
    if type(wires) <> 10 | size(wires, 2) <> 2 then reason = "Netinkami sujungimo duomenys."; return; end
    if size(wires, 1) > size(canonical, 1) then reason = "Per daug laidų."; return; end
    for index = 1:size(canonical, 1)
        present = %f;
        for row = 1:size(wires, 1)
            if and(wires(row,:) == canonical(index,:)) | and(wires(row,:) == canonical(index,[2 1])) then present = %t; end
        end
        if ~present then
            reason = "Trūksta laido ["+ld8_terminal_code(canonical(index,1))+"]–["+ld8_terminal_code(canonical(index,2))+"].";
            return;
        end
    end
    ok = %t; reason = "";
endfunction

function values = ld8_reference(mode)
    // Analitinės reikšmės (idealus šaltinis): U = E, I = E/Rt.
    global LD8;
    cfg = LD8.cfg;
    select mode
    case 1 then rt = cfg.R1 + cfg.R2 + cfg.R3;
    case 2 then rt = 1/(1/cfg.R1 + 1/cfg.R2 + 1/cfg.R3);
    case 3 then rt = cfg.R1 + cfg.R2*cfg.R3/(cfg.R2 + cfg.R3);
    end
    values = [cfg.E, cfg.E/rt*1000, rt];
endfunction

function [voltage, current, ok, message] = ld8_measure_values()
    global LD8;
    voltage = %nan; current = %nan; ok = %f; message = "";
    if ~LD8.powerOn then message = "Įjunkite maitinimą [B01]."; return; end
    if ~LD8.switchOn then message = "Uždarykite jungiklį [B02]."; return; end
    [valid, message] = ld8_wiring_valid(LD8.wires);
    if ~valid then return; end
    bench_core_require(); cfg = LD8.cfg; mode = LD8.wireMode;
    // Tikras trijų varžų tinklas per bendrą MNA branduolį.
    select mode
    case 1 then edges = [1 3 cfg.R1;3 4 cfg.R2;4 2 cfg.R3]; reachable = [%t %t %t %t];
    case 2 then edges = [1 2 cfg.R1;1 2 cfg.R2;1 2 cfg.R3]; reachable = [%t %t];
    else edges = [1 3 cfg.R1;3 2 cfg.R2;3 2 cfg.R3]; reachable = [%t %t %t];
    end
    [volts, currents, status] = bench_cpp_dc(edges, reachable, 1, 2, cfg.E);
    if status <> 0 then message = "C++ grandinės skaičiavimas nepavyko."; return; end
    voltage = volts(1) - volts(2);
    if mode == 2 then current = sum(currents)*1000; else current = currents(1)*1000; end
    ok = %t;
endfunction

function ld8_init_state()
    global LD8;
    assessment=%t; practice=%f;
    if isfield(LD8,"assessment") then assessment=LD8.assessment; end
    if isfield(LD8,"practice_used") then practice=LD8.practice_used; end
    LD8.assessment=assessment; LD8.practice_used=practice;
    LD8.step = 1; LD8.done = zeros(1, 6) == 1; LD8.skipped = zeros(1, 6) == 1;
    LD8.powerOn = %f; LD8.switchOn = %f; LD8.wireMode = 1;
    LD8.wires = emptystr(0, 2); LD8.journal = [];
    LD8.wires_by_mode = list(); LD8.report_wires = list();
    for index = 1:3
        LD8.wires_by_mode(index) = emptystr(0, 2); LD8.report_wires(index) = emptystr(0, 2);
    end
    LD8.answers = emptystr(6, 8); LD8.demoMode = %f; LD8.lastMeasurement = %nan; LD8.pending = "";
endfunction

function expected = ld8_expected_answers()
    global LD8;
    cfg = LD8.cfg;
    expected = %nan * ones(6, 8);
    series = cfg.R1 + cfg.R2 + cfg.R3;
    parallel = 1/(1/cfg.R1 + 1/cfg.R2 + 1/cfg.R3);
    mixed = cfg.R1 + cfg.R2*cfg.R3/(cfg.R2 + cfg.R3);
    expected(2, 1:2) = [series, series];
    expected(3, 1:2) = [parallel, parallel];
    expected(4, 1:2) = [mixed, mixed];
    expected(5, 1:3) = [cfg.E/cfg.R1*1000, cfg.E/cfg.R2*1000, cfg.E/cfg.R3*1000];
    expected(6, 1:3) = [1 1 1];
endfunction

function rows = ld8_journal_rows(tag)
    global LD8;
    rows = [];
    if LD8.journal == [] then return; end
    indices = find(LD8.journal(:, 3) == tag);
    if indices <> [] then rows = LD8.journal(indices, :); end
endfunction
