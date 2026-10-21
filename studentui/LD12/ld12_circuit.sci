// ============================================================================
// LD12 grandinės modelis: trifazis simetrinis šaltinis (Ul pagal variantą,
// fazinės EV ±120°) ir trys vienodi imtuvai R žvaigždėje arba trikampyje.
// Fizika — C++ ld_ac kind 6, simetrinė aktyvioji apkrova; Žurnalas: [U V, I mA, režimas 1–2, fazė 1–3, 0].
// Režimas 1 – žvaigždė (Uf = Ul/√3, If = Il), 2 – trikampis (Uf = Ul).
// ============================================================================

function plan = ld12_instrument_plan(mode, measurement)
    if argn(2) < 2 then measurement = "phase"; end
    wires = emptystr(0, 2);
    if ~ld12_valid_index(mode, 2) then plan = struct("wires", wires); return; end
    if measurement <> "phase" & measurement <> "line" then plan = struct("wires", wires); return; end
    // Phase: A is after R1; V is across R1. Line: A precedes the L1 split;
    // V is across L1/L2. Thus all four measurements have distinct real graphs.
    if measurement == "phase" then
        if mode == 1 then
            wires = ["L1" "R1_A";"L2" "R2_A";"L3" "R3_A";"R1_B" "A_P"; ...
                "A_N" "R2_B";"R2_B" "R3_B";"R3_B" "N"];
        else
            wires = ["L1" "R1_A";"R1_B" "A_P";"A_N" "L2";"L2" "R2_A"; ...
                "R2_B" "L3";"L3" "R3_A";"R3_B" "L1"];
        end
        wires = [wires;"V_P" "R1_A";"V_N" "R1_B"];
    else
        if mode == 1 then
            wires = ["L1" "A_P";"A_N" "R1_A";"L2" "R2_A";"L3" "R3_A"; ...
                "R1_B" "R2_B";"R2_B" "R3_B";"R3_B" "N"];
        else
            wires = ["L1" "A_P";"A_N" "R1_A";"R1_B" "L2";"L2" "R2_A"; ...
                "R2_B" "L3";"L3" "R3_A";"R3_B" "A_N"];
        end
        wires = [wires;"V_P" "L1";"V_N" "L2"];
    end
    plan = struct("wires", wires, "mode", mode, "measurement", measurement);
endfunction

function wires = ld12_canonical_wires(mode, measurement)
    if argn(2) < 2 then measurement = "phase"; end
    plan = ld12_instrument_plan(mode, measurement); wires = plan.wires;
endfunction

function same = ld12_wires_equal(actual, planned)
    same = %f;
    if type(actual) <> 10 | size(actual, 2) <> 2 then return; end
    if size(actual, 1) <> size(planned, 1) then return; end
    used = zeros(size(planned, 1), 1) == 1;
    for row = 1:size(actual, 1)
        match = 0;
        for k = 1:size(planned, 1)
            if ~used(k) then
                if and(actual(row,:) == planned(k,:)) | and(actual(row,:) == planned(k,[2 1])) then match = k; break; end
            end
        end
        if match == 0 then return; end
        used(match) = %t;
    end
    same = and(used);
endfunction

function [ok, mode, measurement] = ld12_detect_measurement(wires)
    ok = %f; mode = 0; measurement = "";
    for candidate = 1:2
        for selected = ["phase" "line"]
            if ld12_wires_equal(wires, ld12_canonical_wires(candidate, selected)) then
                ok = %t; mode = candidate; measurement = selected; return;
            end
        end
    end
endfunction

function mode = ld12_stage_mode(step)
    mapping = [1 1 2 2 2 2]; mode = mapping(step);
endfunction

function editable = ld12_wiring_editable()
    global LD12;
    editable = ~LD12.demoMode & or(LD12.step == [1 3]) & LD12.wireMode == ld12_stage_mode(LD12.step);
endfunction

function [ok, reason] = ld12_wiring_valid(wires)
    [ok, mode, measurement] = ld12_detect_measurement(wires);
    reason = "Prijunkite visus imtuvų, ampermetro ir voltmetro laidus pagal geltonus kontaktus.";
    if ok then reason = ""; end
endfunction

function [u, i, ok, message] = ld12_measure_values()
    // The full submitted graph determines both topology and meter position.
    // Native If/Il values are already mA. No virtual phase selector is used.
    global LD12;
    u = %nan; i = %nan; ok = %f; message = "";
    if ~LD12.powerOn then message = "Įjunkite trifazį šaltinį."; return; end
    if ~LD12.switchOn then message = "Uždarykite jungiklį."; return; end
    [valid, mode, measurement] = ld12_detect_measurement(LD12.wires);
    if ~valid then message = "Prijunkite visus imtuvų, ampermetro ir voltmetro laidus pagal geltonus kontaktus."; return; end
    bench_core_require(); cfg = LD12.cfg;
    v = bench_cpp_ac(6, cfg.Ul, 50, cfg.R, 1, 1);
    if measurement == "line" then
        u = v(8); i = v(2); if mode == 2 then i = v(5); end
    else
        u = v(1); i = v(2); if mode == 2 then u = v(3); i = v(4); end
    end
    ok = %t;
endfunction

function values = ld12_line_current()
    // Linijinė srovė trikampyje iš C++ kind 6 (MNA).
    global LD12;
    v = bench_cpp_ac(6, LD12.cfg.Ul, 50, LD12.cfg.R, 1, 1);
    values = v(5);
endfunction

function ld12_init_state()
    global LD12;
    assessment=%t; practice=%f;
    if isfield(LD12,"assessment") then assessment=LD12.assessment; end
    if isfield(LD12,"practice_used") then practice=LD12.practice_used; end
    LD12.guide_enabled = %f;
    LD12.step = 1; LD12.done = zeros(1, 6) == 1; LD12.skipped = zeros(1, 6) == 1;
    LD12.powerOn = %f; LD12.switchOn = %f; LD12.wireMode = 1; LD12.phase = 0;
    LD12.wires = emptystr(0, 2); LD12.journal = [];
    LD12.wires_by_mode = list(); LD12.report_wires = list();
    for index = 1:2
        LD12.wires_by_mode(index) = emptystr(0, 2); LD12.report_wires(index) = emptystr(0, 2);
    end
    LD12.answers = emptystr(6, 8); LD12.demoMode = %f; LD12.lastMeasurement = %nan; LD12.pending = "";
    LD12.assessment=assessment; LD12.practice_used=practice;
endfunction

function expected = ld12_expected_answers()
    global LD12;
    cfg = LD12.cfg;
    expected = %nan * ones(6, 8);
    v = bench_cpp_ac(6, cfg.Ul, 50, cfg.R, 1, 1);
    expected(1, 1) = v(1);
    expected(2, 1) = v(2);
    expected(3, 1) = v(3);
    expected(4, 1) = v(4);
    expected(5, 1:3) = [v(5), v(7)*1000, v(6)*1000];
    expected(6, 1:3) = [1 1 1];
endfunction

function rows = ld12_journal_rows(tag)
    global LD12;
    rows = [];
    if LD12.journal == [] then return; end
    indices = find(LD12.journal(:, 3) == tag);
    if indices <> [] then rows = LD12.journal(indices, :); end
endfunction
