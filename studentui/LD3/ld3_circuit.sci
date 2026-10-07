// ============================================================================
// LD3 grandinės modelis: sujungimai, matavimas. Fizika: I = U / R (mA).
// ============================================================================

function w = ld3_canonical_wires()
    // 6 laidai: šaltinis → jungiklis → ampermetras → R1 → šaltinis; V lygiagrečiai R1.
    w = ["E_P" "K1"; "K2" "A_P"; "A_N" "R1A"; "R1B" "E_N"; "V_P" "R1A"; "V_N" "R1B"];
endfunction

function [ok, reason] = ld3_wiring_valid(wires)
    ok = %f; reason = "";
    canon = ld3_canonical_wires();
    if ~isfield(LD3, "wires") | LD3.wires == [] then
        reason = "Grandinė dar nesujungta. Jei reikia, atverkite Pagalba → Kaip sujungti.";
        return;
    end
    if size(LD3.wires, 1) > 6 then
        reason = "Per daug laidų (leisčiau 6): nuimkite perteklinius.";
        return;
    end
    for k = 1:size(canon, 1)
        rasta = %f;
        for m = 1:size(LD3.wires, 1)
            par = [LD3.wires(m,1) LD3.wires(m,2)];
            if and(par == canon(k,:)) | and(par == canon(k, [2 1])) then rasta = %t; end
        end
        if ~rasta then
            reason = "Trūksta jungties: " + ld3_terminal_name(canon(k,1)) + " → " + ld3_terminal_name(canon(k,2)) + ".";
            return;
        end
    end
    ok = %t;
endfunction

function [u, i, ok, msg] = ld3_measure_values()
    // Grąžina matuojamas reikšmes, kai grandinė fiziškai parengta.
    global LD3;
    u = %nan; i = %nan; ok = %f; msg = "";
    if ~LD3.powerOn then
        msg = "Maitinimas išjungtas. Pirmiausia įjunkite maitinimą.";
        return;
    end
    if ~LD3.switchOn then
        msg = "Jungiklis atidarytas. Uždarykite jungiklį.";
        return;
    end
    if LD3.voltage <= 0 then
        msg = "Įtampa nenustatyta. Pasirinkite U1, U2 arba U3.";
        return;
    end
    [wok, wwhy] = ld3_wiring_valid(LD3.wires);
    if ~wok then
        msg = wwhy;
        return;
    end
    u = LD3.voltage;
    i = LD3.voltage / LD3.cfg.R * 1000;
    ok = %t;
endfunction

function ld3_init_state()
    global LD3;
    assessment=%t; practice=%f;
    if isfield(LD3,"assessment") then assessment=LD3.assessment; end
    if isfield(LD3,"practice_used") then practice=LD3.practice_used; end
    LD3.step = 1;
    LD3.done = [%f %f %f %f %f %f];
    LD3.skipped = [%f %f %f %f %f %f];
    LD3.powerOn = %f;
    LD3.switchOn = %f;
    LD3.voltage = 0;
    LD3.wires = [];
    LD3.journal = [];
    LD3.answers = emptystr(6, 8);
    LD3.demoMode = %f;
    LD3.lastMeasurement = %nan;
    LD3.pending = "";
    LD3.assessment=assessment; LD3.practice_used=practice;
endfunction

function expected = ld3_expected_answers()
    // Teisingi atsakymai pagal variantą ir žurnalą (etapams 2, 4, 5).
    global LD3;
    expected = emptystr(6, 8);
    cfg = LD3.cfg;
    expected(2,1) = msprintf("%.10g", cfg.U1 / cfg.R * 1000);   // A02.01 teorinė I1, mA
    if size(LD3.journal, 1) >= 3 then
        for k = 1:3
            expected(3 + k, k > 3) = ""; // (nenaudojama – kviečiama žemiau)
        end
        u1 = LD3.journal(1,1); i1 = LD3.journal(1,2);
        u2 = LD3.journal(2,1); i2 = LD3.journal(2,2);
        u3 = LD3.journal(3,1); i3 = LD3.journal(3,2);
        expected(4,1) = msprintf("%.10g", u1 / (i1 / 1000));    // R1
        expected(4,2) = msprintf("%.10g", u2 / (i2 / 1000));    // R2
        expected(4,3) = msprintf("%.10g", u3 / (i3 / 1000));    // R3
        expected(4,4) = msprintf("%.10g", (u1/(i1/1000) + u2/(i2/1000) + u3/(i3/1000)) / 3); // Rvid
        expected(5,1) = msprintf("%.10g", (u3 - u1) / ((i3 - i1) / 1000)); // iš nuolydžio
    end
    expected(6,1) = "1";  // tiesinė
    expected(6,2) = "1";  // R pastovi
endfunction
