// ============================================================================
// LD4 grandinės modelis: DU rezistoriai (R1/R2 + nuoseklus), I = U / R.
// ============================================================================

function w = ld4_canonical_wires(mode)
    // mode: 1 = R1, 2 = R2, "S" = nuoseklus R1+R2.
    select mode
    case 1 then w = ["E_P" "K1"; "K2" "A_P"; "A_N" "R1A"; "R1B" "E_N"; "V_P" "R1A"; "V_N" "R1B"];
    case 2 then w = ["E_P" "K1"; "K2" "A_P"; "A_N" "R2A"; "R2B" "E_N"; "V_P" "R2A"; "V_N" "R2B"];
    else w = ["E_P" "K1"; "K2" "A_P"; "A_N" "R1A"; "R1B" "R2A"; "R2B" "E_N"; "V_P" "R1A"; "V_N" "R2B"];
    end
endfunction

function m = ld4_wire_mode()
    // Dabartinis režimas pagal etapą: 2 = R1, 3 = R2, 6 = nuoseklus, kiti = kaip ankstesnis.
    global LD4;
    select LD4.step
    case 1 then m = 1;
    case 2 then m = 1;
    case 3 then m = 2;
    case 6 then m = "S";
    else m = LD4.wireMode;
    end
endfunction

function [ok, reason] = ld4_wiring_valid(wires)
    global LD4;
    ok = %f; reason = "";
    m = ld4_wire_mode();
    canon = ld4_canonical_wires(m);
    if wires == [] then
        reason = "Grandinė nesujungta: seką rodys [B04] KAIP SUJUNGTI.";
        return;
    end
    if size(wires, 1) <> size(canon, 1) then
        reason = "Reikia " + string(size(canon,1)) + " laidų.";
        return;
    end
    for k = 1:size(canon, 1)
        rasta = %f;
        for mm = 1:size(wires, 1)
            par = [wires(mm,1) wires(mm,2)];
            if and(par == canon(k,:)) | and(par == canon(k, [2 1])) then rasta = %t; end
        end
        if ~rasta then
            reason = "Trūksta laido " + canon(k,1) + "–" + canon(k,2) + ...
                     " (" + ld4_terminal_code(canon(k,1)) + "–" + ld4_terminal_code(canon(k,2)) + ").";
            return;
        end
    end
    ok = %t;
endfunction

function r = ld4_active_resistance()
    // Aktyvi grandinės varža pagal režimą (REALIOS reikšmės su tolerancija).
    global LD4;
    m = ld4_wire_mode();
    if m == 1 then r = LD4.cfg.R1;
    elseif m == 2 then r = LD4.cfg.R2;
    else r = LD4.cfg.R1 + LD4.cfg.R2;
    end
endfunction

function [u, i, ok, msg] = ld4_measure_values()
    global LD4;
    u = %nan; i = %nan; ok = %f; msg = "";
    if ~LD4.powerOn then msg = "Maitinimas išjungtas: įjunkite [B01]."; return; end
    if ~LD4.switchOn then msg = "Jungiklis atidarytas: uždarykite [B02]."; return; end
    if LD4.voltage <= 0 then msg = "Įtampa 0 V: nustatykite mygtuku [B10]/[B11]/[B12]."; return; end
    [wok, wwhy] = ld4_wiring_valid(LD4.wires);
    if ~wok then msg = wwhy; return; end
    bench_core_require();
    m=ld4_wire_mode();
    if m=="S" then edges=[1 3 LD4.cfg.R1;3 2 LD4.cfg.R2]; reachable=[%t %t %t];
    else edges=[1 2 ld4_active_resistance()]; reachable=[%t %t]; end
    [volts,currents,status]=bench_cpp_dc(edges,reachable,1,2,LD4.voltage);
    if status<>0 then msg="C++ grandinės skaičiavimas nepavyko."; return; end
    u=volts(1)-volts(2); i=currents(1)*1000; ok=%t;
endfunction

function ld4_init_state()
    global LD4;
    assessment=%t; practice=%f;
    if isfield(LD4,"assessment") then assessment=LD4.assessment; end
    if isfield(LD4,"practice_used") then practice=LD4.practice_used; end
    LD4.step = 1;
    LD4.done = [%f %f %f %f %f %f %f];
    LD4.skipped = [%f %f %f %f %f %f %f];
    LD4.powerOn = %f;
    LD4.switchOn = %f;
    LD4.voltage = 0;
    LD4.wires = [];
    LD4.journal = [];      // eilutės [U, I_mA, rezistoriaus žymė: 1/2/3(serija)]
    LD4.answers = emptystr(7, 8);
    LD4.demoMode = %f;
    LD4.lastMeasurement = %nan;
    LD4.pending = "";
    LD4.wireMode = 1;
    LD4.report_wires=list();
    for k=1:7; LD4.report_wires(k)=emptystr(0,2); end
    LD4.assessment=assessment; LD4.practice_used=practice;
endfunction

function expected = ld4_expected_answers()
    // Teisingi atsakymai iš varianto ir studento žurnalo (etapams 2, 4, 5, 6).
    global LD4;
    expected = emptystr(7, 8);
    cfg = LD4.cfg;
    expected(2,1) = msprintf("%.10g", cfg.U1 / cfg.R1nom * 1000);        // A02.01 teorinė I1 (R1)
    r1 = ld4_journal_rows(1); r2 = ld4_journal_rows(2); rs = ld4_journal_rows(3);
    if size(r1, 1) >= 3 then
        rr = mean(r1(:,1) ./ (r1(:,2) / 1000));
        expected(4,1) = msprintf("%.10g", rr);                        // A04.01 R1m
    end
    if size(r2, 1) >= 3 then
        rr2 = mean(r2(:,1) ./ (r2(:,2) / 1000));
        expected(4,2) = msprintf("%.10g", rr2);                       // A04.02 R2m
    end
    if size(r1, 1) >= 3 then
        expected(4,3) = msprintf("%.10g", (mean(r1(:,1) ./ (r1(:,2)/1000)) / cfg.R1nom - 1) * 100); // A04.03 δ1 %
    end
    if size(r2, 1) >= 3 then
        expected(4,4) = msprintf("%.10g", (mean(r2(:,1) ./ (r2(:,2)/1000)) / cfg.R2nom - 1) * 100); // A04.04 δ2 %
    end
    if size(r1, 1) >= 3 then
        expected(5,1) = msprintf("%.10g", (r1(3,1) - r1(1,1)) / ((r1(3,2) - r1(1,2)) / 1000)); // A05.01 R1 iš nuolydžio
    end
    if size(r2, 1) >= 3 then
        expected(5,2) = msprintf("%.10g", (r2(3,1) - r2(1,1)) / ((r2(3,2) - r2(1,2)) / 1000)); // A05.02 R2
        expected(5,3) = msprintf("%.10g", 1000 / ((r2(3,1) - r2(1,1)) / ((r2(3,2) - r2(1,2)) / 1000))); // A05.03 G2, mS
    end
    if size(rs, 1) >= 1 then
        expected(6,1) = msprintf("%.10g", rs(1,1) / (rs(1,2) / 1000));  // A06.01 Rs iš matavimo
    end
    expected(7,1) = "1";   // A07.01 tiesinė
    expected(7,2) = "1";   // A07.02 talpina ±5 % ribose
endfunction

function rows = ld4_journal_rows(tag)
    // Žurnalo eilutės pagal rezistoriaus žymę (1, 2 arba 3 = serija).
    global LD4;
    rows = [];
    if ~isfield(LD4, "journal") | LD4.journal == [] then return; end
    for m = 1:size(LD4.journal, 1)
        if LD4.journal(m, 3) == tag then rows($+1, :) = LD4.journal(m, 1:2); end
    end
    if size(rows,1)>1 then
        [unused,order]=gsort(rows(:,1),"g","i"); rows=rows(order,:);
    end
endfunction
