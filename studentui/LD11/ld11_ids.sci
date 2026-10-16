// ============================================================================
// LD11 elementų numerių registras. Bankas LD11-64-A-2026.
// REGISTRY-CODES: T01:T10 B01:B11 E01:E06 A01.01 A02.01:A02.03 A03.01 A05.01:A05.04 A06.01:A06.03 V02 H01
// ============================================================================

function ids = ld11_terminal_ids()
    ids = ["GEN_P";"GEN_N";"K1";"K2";"A_P";"A_N";"RL_A";"RL_B";"C_A";"C_B"];
endfunction

function code = ld11_terminal_code(id)
    tids = ld11_terminal_ids();
    k = find(tids == id);
    if size(k, "*") ~= 1 then code = ""; else code = msprintf("T%02d", k(1)); end
endfunction

function name = ld11_terminal_name(id)
    names = ["Generatoriaus + gnybtas";"Generatoriaus − gnybtas"; ...
             "Jungiklio įėjimas";"Jungiklio išėjimas";"Ampermetro + gnybtas"; ...
             "Ampermetro − gnybtas";"Ritės (R, L) gnybtas a";"Ritės (R, L) gnybtas b"; ...
             "Kondensatoriaus Ck gnybtas a";"Kondensatoriaus Ck gnybtas b"];
    tids = ld11_terminal_ids();
    k = find(tids == id);
    if size(k, "*") ~= 1 then name = id; else name = names(k(1)); end
endfunction

function [ids, callbacks, labels, hints] = ld11_button_registry()
    ids = ["B01";"B02";"B03";"B04";"B05";"B06";"B07";"B08";"B09";"B10";"B11"];
    callbacks = ["ld11_toggle_power()";"ld11_toggle_switch()";"ld11_measure()"; ...
                 "ld11_show_wiring_guide()";"ld11_show_stand_map()";"ld11_restore_stage()"; ...
                 "ld11_toggle_solution()";"ld11_export_report()";"ld11_restart()"; ...
                 "ld11_set_mode(1)";"ld11_set_mode(2)"];
    labels = ["MAITINIMAS";"JUNGIKLIS";"MATUOTI";"KAIP SUJUNGTI";"STENDO ŽEMĖLAPIS"; ...
              "ATKURTI";"PAVYZDYS";"ATASKAITA";"IŠ NAUJO"; ...
              "BE Ck";"SU Ck"];
    hints = ["Įjungti arba išjungti maitinimą.";"Atidaryti arba uždaryti jungiklį."; ...
        "Automatiškai įrašyti U, I ir P į žurnalą.";"Parodyti laidų jungimo seką."; ...
        "Stendo elementų ir gnybtų paskirtis.";"Išvalyti šio režimo sujungimą."; ...
        "Mokymosi pavyzdys; atsiskaitymui nenaudojamas.";"Išsaugoti užbaigtą ataskaitą."; ...
        "Išsaugoti ankstesnį darbą ir pradėti naują atsiskaitymą."; ...
        "Ritė be kompensavimo kondensatoriaus.";"Ck lygiagrečiai ritei; atskirai išsaugoti šio režimo laidai."];
endfunction

function [code, label, hint] = ld11_button_info(cb)
    [ids, callbacks, labels, hints] = ld11_button_registry();
    k = find(callbacks == cb);
    if size(k, "*") ~= 1 then error("Valdiklis ne LD11 registre: " + cb); end
    code = ids(k(1)); label = labels(k(1)); hint = hints(k(1));
endfunction

function code = ld11_stage_code(n)
    code = msprintf("E%02d", n);
endfunction

function code = ld11_answer_code(n, k)
    code = msprintf("A%02d.%02d", n, k);
endfunction

function codes = ld11_all_codes()
    tids = ld11_terminal_ids();
    codes = emptystr(size(tids, "*"), 1);
    for k = 1:size(tids, "*"); codes(k) = msprintf("T%02d", k); end
    [bids, callbacks, labels, hints] = ld11_button_registry();
    codes = [codes; bids];
    for n = 1:6; codes($+1, 1) = msprintf("E%02d", n); end
    codes = [codes; "A01.01";"A02.01";"A02.02";"A02.03";"A03.01"; ...
             "A05.01";"A05.02";"A05.03";"A05.04"; ...
             "A06.01";"A06.02";"A06.03"];
    codes = [codes; "V02";"H01"];
endfunction
