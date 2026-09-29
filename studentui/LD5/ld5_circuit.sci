// ============================================================================
// LD5 grandinės modelis: ĮTAMPOS DALIKLIS E → R1 → RV → E_N; U_iš = E·RVd/(R1+RVd).
// ============================================================================

function w = ld5_canonical_wires()
    w = ["E_P" "K1"; "K2" "A_P"; "A_N" "R1A"; "R1B" "RVA"; "RVB" "E_N"; "V_P" "RVA"; "V_N" "RVB"];
endfunction

function rv = ld5_rv_at(position)
    // Aktyvi potenciometro dalis pagal padėtį (1, 2 arba 3).
    global LD5;
    p = LD5.cfg("P" + string(position));
    rv = LD5.cfg.RV * p / 100;
endfunction

function [u, i, ok, msg] = ld5_measure_values()
    global LD5;
    u = %nan; i = %nan; ok = %f; msg = "";
    if ~LD5.powerOn then msg = "Maitinimas išjungtas: įjunkite [B01]."; return; end
    if ~LD5.switchOn then msg = "Jungiklis atidarytas: uždarykite [B02]."; return; end
    if ~ld5_valid_index(LD5.position,3) then msg = "Padėtis nenustatyta: [B10]/[B11]/[B12]."; return; end
    if ~isfield(LD5, "wires") | LD5.wires == [] then msg = "Grandinė nesujungta: [B04] KAIP SUJUNGTI."; return; end
    [wok, wwhy] = ld5_wiring_valid(LD5.wires);
    if ~wok then msg = wwhy; return; end
    rvd = ld5_rv_at(LD5.position);
    bench_core_require();
    [volts,currents,status]=bench_cpp_dc([1 3 LD5.cfg.R1;3 2 rvd],[%t %t %t],1,2,LD5.cfg.E);
    if status<>0 then msg="C++ grandinės skaičiavimas nepavyko."; return; end
    u = volts(3)-volts(2);
    i = currents(1)*1000;
    ok = %t;
endfunction

function [ok, reason] = ld5_wiring_valid(wires)
    ok = %f; reason = "";
    canon = ld5_canonical_wires();
    if wires == [] then
        reason = "Grandinė nesujungta: seką rodys [B04] KAIP SUJUNGTI."; return;
    end
    if type(wires)<>10 | size(wires,2)<>2 then
        reason="Netinkami sujungimo duomenys."; return;
    end
    if size(wires, 1) > size(canon, 1) then
        reason = "Per daug laidų (riba " + string(size(canon,1)) + ")."; return;
    end
    for k = 1:size(canon, 1)
        rasta = %f;
        for mm = 1:size(wires, 1)
            par = wires(mm,:);
            if and(par == canon(k,:)) | and(par == canon(k, [2 1])) then rasta = %t; end
        end
        if ~rasta then
            reason = "Trūksta laido " + canon(k,1) + "–" + canon(k,2) + ...
                     " (" + ld5_terminal_code(canon(k,1)) + "–" + ld5_terminal_code(canon(k,2)) + ").";
            return;
        end
    end
    ok = %t;
endfunction

function ld5_init_state()
    global LD5;
    assessment=%t; practice=%f;
    if isfield(LD5,"assessment") then assessment=LD5.assessment; end
    if isfield(LD5,"practice_used") then practice=LD5.practice_used; end
    LD5.step = 1;
    LD5.done = [%f %f %f %f %f %f];
    LD5.skipped = [%f %f %f %f %f %f];
    LD5.powerOn = %f;
    LD5.switchOn = %f;
    LD5.position = 0;      // 0 = nenustatyta; 1..3 = padėtys
    LD5.wires = [];
    LD5.report_wires = list();
    for k=1:6; LD5.report_wires(k)=emptystr(0,2); end
    LD5.journal = [];      // [U, I_mA, padėtis]
    LD5.answers = emptystr(6, 8);
    LD5.demoMode = %f;
    LD5.lastMeasurement = %nan;
    LD5.pending = "";
    LD5.assessment=assessment; LD5.practice_used=practice;
endfunction

function ok=ld5_valid_index(n,maximum)
    ok=%f;
    if type(n)<>1 | size(n,"*")<>1 then return; end
    if ~isreal(n) | isnan(n) | isinf(n) then return; end
    ok=n>=1 & n<=maximum & n==floor(n);
endfunction

function expected = ld5_expected_answers()
    global LD5;
    expected = %nan*ones(6, 8);
    cfg = LD5.cfg;
    rv2 = ld5_rv_at(2);
    expected(2,1) = cfg.E * rv2 / (cfg.R1 + rv2);
    expected(4,1) = cfg.E * ld5_rv_at(1) / (cfg.R1 + ld5_rv_at(1));
    expected(4,2) = cfg.E * ld5_rv_at(3) / (cfg.R1 + ld5_rv_at(3));
    u3 = cfg.E * ld5_rv_at(3) / (cfg.R1 + ld5_rv_at(3));
    u1 = cfg.E * ld5_rv_at(1) / (cfg.R1 + ld5_rv_at(1));
    expected(4,3) = u3 - u1;
    expected(4,4) = (u3 - u1) / cfg.E * 100;
    expected(5,1) = cfg.E / (cfg.R1 + rv2) * 1000;
    expected(5,2) = rv2 / (cfg.R1 + rv2) * 100;
    expected(6,1) = 1;
    expected(6,2) = 1;
endfunction

function rows = ld5_journal_rows(tag)
    global LD5;
    rows = [];
    if ~isfield(LD5, "journal") | LD5.journal == [] then return; end
    for m = 1:size(LD5.journal, 1)
        if LD5.journal(m, 3) == tag then rows($+1, :) = LD5.journal(m, 1:2); end
    end
endfunction
