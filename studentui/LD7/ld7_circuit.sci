// ============================================================================
// LD7 grandinės modelis: kanoniniai laidai pagal režimą, etapų ir režimų
// atvaizdis, C++ matavimas (ld_sources, 1 režimas: E per r į apkrovą R),
// laukiami atsakymai ir žurnalo eilutės. Žurnalas: [U V, I mA, žyma, R Ω, P mW];
// žymos 1–5 — padėtys P1–P5, 6 — tuščioji eiga, 7 — trumpasis jungimas.
// ============================================================================

function wires = ld7_canonical_wires(mode)
    wires = emptystr(0, 2);
    if ~ld7_valid_index(mode, 3) then return; end
    select mode
    case 1 then wires = ["E_P" "K1";"K2" "A_P";"A_N" "R_A";"R_B" "E_N";"V_P" "R_A";"V_N" "R_B"];
    case 2 then wires = ["V_P" "E_P";"V_N" "E_N"];
    case 3 then wires = ["E_P" "K1";"K2" "A_P";"A_N" "E_N"];
    end
endfunction

function mode = ld7_stage_mode(step)
    mapping = [1 1 1 1 2 1]; mode = mapping(step);
endfunction

function modes = ld7_stage_modes(step)
    // 5 etapui reikia abiejų specialiųjų sujungimų (TE ir TJ).
    if step == 5 then modes = [2 3]; else modes = ld7_stage_mode(step); end
endfunction

function editable = ld7_wiring_editable()
    global LD7;
    editable = ~LD7.demoMode & or(LD7.step == [1 5]) & or(LD7.wireMode == ld7_stage_modes(LD7.step));
endfunction

function [ok, reason] = ld7_wiring_valid(wires)
    global LD7;
    ok = %f; reason = "Sujunkite grandinę pagal Pagalba → Kaip sujungti.";
    if ~ld7_valid_index(LD7.wireMode, 3) then return; end
    canonical = ld7_canonical_wires(LD7.wireMode);
    if wires == [] then return; end
    if type(wires) <> 10 | size(wires, 2) <> 2 then reason = "Netinkami sujungimo duomenys."; return; end
    if size(wires, 1) > size(canonical, 1) then reason = "Per daug laidų."; return; end
    for index = 1:size(canonical, 1)
        present = %f;
        for row = 1:size(wires, 1)
            if and(wires(row,:) == canonical(index,:)) | and(wires(row,:) == canonical(index,[2 1])) then present = %t; end
        end
        if ~present then
            reason = "Trūksta laido ["+ld7_terminal_code(canonical(index,1))+"]–["+ld7_terminal_code(canonical(index,2))+"].";
            return;
        end
    end
    ok = %t; reason = "";
endfunction

function load = ld7_mode_load(mode)
    // Fizinis atitikmuo: TE — voltmetro varža 1 MΩ, TJ — ampermetro varža 1 µΩ.
    global LD7;
    if mode == 2 then load = 1e6;
    elseif mode == 3 then load = 1e-6;
    else load = LD7.cfg("R" + string(LD7.position));
    end
endfunction

function values = ld7_reference(mode, position)
    global LD7;
    cfg = LD7.cfg;
    if argn(2) < 2 then position = LD7.position; end
    if mode == 2 then load = 1e6;
    elseif mode == 3 then load = 1e-6;
    else load = cfg("R" + string(position));
    end
    current = cfg.E / (load + cfg.r);
    values = [current*load, current*1000];
endfunction

function [voltage, current, ok, message, load] = ld7_measure_values()
    global LD7;
    voltage = %nan; current = %nan; load = %nan; ok = %f; message = "";
    if ~LD7.powerOn then message = "Įjunkite maitinimą [B01]."; return; end
    if LD7.wireMode == 1 & LD7.position == 0 then message = "Pasirinkite reostato padėtį [B13]–[B17]."; return; end
    if or(LD7.wireMode == [1 3]) & ~LD7.switchOn then message = "Uždarykite jungiklį [B02]."; return; end
    [valid, message] = ld7_wiring_valid(LD7.wires);
    if ~valid then return; end
    bench_core_require(); cfg = LD7.cfg;
    load = ld7_mode_load(LD7.wireMode);
    [values, status] = call("ld_sources", 1, 1, "i", [cfg.E cfg.E load cfg.r cfg.r], 2, "d", ...
        "out", [1 4], 3, "d", [1 1], 4, "i");
    if status <> 0 then message = "C++ grandinės modelis negali apskaičiuoti režimo."; return; end
    voltage = values(1); current = values(2); ok = %t;
endfunction

function ld7_init_state()
    global LD7;
    assessment=%t; practice=%f;
    if isfield(LD7,"assessment") then assessment=LD7.assessment; end
    if isfield(LD7,"practice_used") then practice=LD7.practice_used; end
    LD7.step = 1; LD7.done = zeros(1, 6) == 1; LD7.skipped = zeros(1, 6) == 1;
    LD7.powerOn = %f; LD7.switchOn = %f; LD7.wireMode = 1; LD7.position = 0;
    LD7.wires = emptystr(0, 2); LD7.journal = [];
    LD7.wires_by_mode = list(); LD7.report_wires = list();
    for index = 1:3
        LD7.wires_by_mode(index) = emptystr(0, 2); LD7.report_wires(index) = emptystr(0, 2);
    end
    LD7.answers = emptystr(6, 8); LD7.demoMode = %f; LD7.lastMeasurement = %nan; LD7.pending = "";
    LD7.assessment=assessment; LD7.practice_used=practice;
endfunction

function expected = ld7_expected_answers()
    global LD7;
    cfg = LD7.cfg;
    expected = %nan * ones(6, 8);
    first = ld7_reference(1, 1); third = ld7_reference(1, 3); fifth = ld7_reference(1, 5);
    expected(3, 1:2) = [cfg.r, cfg.E];
    expected(4, 1) = first(1) * first(2);
    expected(4, 2) = third(1) * third(2);
    expected(4, 3) = fifth(1) * fifth(2);
    expected(4, 4) = 1000 * cfg.E^2 / (4*cfg.r);
    expected(4, 5) = 50;
    expected(5, 1) = cfg.E * 1e6 / (1e6 + cfg.r);
    expected(5, 2) = cfg.E / cfg.r * 1000;
    expected(6, 1:3) = [1 1 1];
endfunction

function rows = ld7_journal_rows(tag)
    global LD7;
    rows = [];
    if LD7.journal == [] then return; end
    indices = find(LD7.journal(:, 3) == tag);
    if indices <> [] then rows = LD7.journal(indices, [1 2 4 5]); end
endfunction
