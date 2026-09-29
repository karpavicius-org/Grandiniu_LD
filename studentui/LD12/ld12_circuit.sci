// ============================================================================
// LD12 grandinės modelis: trifazis simetrinis šaltinis (Ul pagal variantą,
// fazinės EV ±120°) ir trys vienodi imtuvai R žvaigždėje arba trikampyje.
// Fizika — tiesioginis ld_mna (kompleksinė MNA): trys EV šaltiniai su re/im
// dalimis. Žurnalas: [U V, I mA, režimas 1–2, fazė 1–3, 0].
// Režimas 1 – žvaigždė (Uf = Ul/√3, If = Il), 2 – trikampis (Uf = Ul).
// ============================================================================

function wires = ld12_canonical_wires(mode)
    wires = emptystr(0, 2);
    if ~ld12_valid_index(mode, 2) then return; end
    select mode
    case 1 then wires = ["L1" "R1_A";"L2" "R2_A";"L3" "R3_A";"R1_B" "R2_B";"R2_B" "R3_B";"R3_B" "N"];
    case 2 then wires = ["L1" "R1_A";"R1_B" "L2";"L2" "R2_A";"R2_B" "L3";"L3" "R3_A";"R3_B" "L1"];
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
    global LD12;
    ok = %f; reason = "Sujunkite imtuvus pagal Pagalba → Kaip sujungti.";
    if ~ld12_valid_index(LD12.wireMode, 2) then return; end
    canonical = ld12_canonical_wires(LD12.wireMode);
    if wires == [] then return; end
    if type(wires) <> 10 | size(wires, 2) <> 2 then reason = "Netinkami sujungimo duomenys."; return; end
    if size(wires, 1) > size(canonical, 1) then reason = "Per daug laidų."; return; end
    for index = 1:size(canonical, 1)
        present = %f;
        for row = 1:size(wires, 1)
            if and(wires(row,:) == canonical(index,:)) | and(wires(row,:) == canonical(index,[2 1])) then present = %t; end
        end
        if ~present then
            reason = "Trūksta laido ["+ld12_terminal_code(canonical(index,1))+"]–["+ld12_terminal_code(canonical(index,2))+"].";
            return;
        end
    end
    ok = %t; reason = "";
endfunction

function [u, i, ok, message] = ld12_measure_values()
    // U ir I pasirinktoje fazėje (LD12.phase 1–3) su esamu režimu.
    global LD12;
    u = %nan; i = %nan; ok = %f; message = "";
    if ~LD12.powerOn then message = "Įjunkite trifazį šaltinį [B01]."; return; end
    if ~LD12.switchOn then message = "Uždarykite jungiklį [B02]."; return; end
    [valid, message] = ld12_wiring_valid(LD12.wires);
    if ~valid then return; end
    if LD12.phase == 0 then message = "Pasirinkite matuojamą fazę [B12]–[B14]."; return; end
    // Fizika — ld_ac kind 6 (trifazė MNA branduolyje):
    // v = [Uf_Y, If_Y, Uf_D, If_D, Il_D, P_Y, P_D, Ul].
    bench_core_require(); cfg = LD12.cfg;
    v = bench_cpp_ac(6, cfg.Ul, 50, cfg.R, 1, 1);
    if LD12.wireMode == 2 then u = v(3); i = v(4);
    else u = v(1); i = v(2); end
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
