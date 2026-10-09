// ============================================================================
// LD6 elementų numerių registras. Bankas LD6-64-B-2026.
// REGISTRY-CODES: T01:T12 B01:B13 E01:E06 A02.01 A04.01:A04.02 A05.01:A05.02 A06.01 A06.02 V02 H01
// ============================================================================

function ids = ld6_terminal_ids()
    ids = ["E1_P";"E1_N";"E2_P";"E2_N";"K1";"K2";"A_P";"A_N";"R_A";"R_B";"V_P";"V_N"];
endfunction

function code = ld6_terminal_code(id)
    tids = ld6_terminal_ids();
    k = find(tids == id);
    if size(k, "*") ~= 1 then code = ""; else code = msprintf("T%02d", k(1)); end
endfunction

function name = ld6_terminal_name(id)
    names = ["Šaltinio E1 + gnybtas";"Šaltinio E1 − gnybtas"; ...
             "Šaltinio E2 + gnybtas";"Šaltinio E2 − gnybtas"; ...
             "Jungiklio įėjimas";"Jungiklio išėjimas";"Ampermetro + gnybtas"; ...
             "Ampermetro − gnybtas";"Krovinio R gnybtas a";"Krovinio R gnybtas b"; ...
             "Voltmetro + zondas";"Voltmetro − zondas"];
    tids = ld6_terminal_ids();
    k = find(tids == id);
    if size(k, "*") ~= 1 then name = id; else name = names(k(1)); end
endfunction

function [ids, callbacks, labels, hints] = ld6_button_registry()
    ids = ["B01";"B02";"B03";"B04";"B05";"B06";"B07";"B08";"B09";"B10";"B11";"B12";"B13"];
    callbacks = ["ld6_toggle_power()";"ld6_toggle_switch()";"ld6_measure()"; ...
                 "ld6_show_wiring_guide()";"ld6_show_stand_map()";"ld6_restore_stage()"; ...
                 "ld6_toggle_solution()";"ld6_export_report()";"ld6_restart()"; ...
                 "ld6_set_mode(1)";"ld6_set_mode(2)";"ld6_set_mode(3)";"ld6_set_mode(4)"];
    labels = ["MAITINIMAS";"JUNGIKLIS";"MATUOTI";"KAIP SUJUNGTI";"STENDO ŽEMĖLAPIS"; ...
              "ATKURTI";"PAVYZDYS";"ATASKAITA";"IŠ NAUJO"; ...
              "E1 VIENAS";"NUOSEKLIAI";"PRIEŠPRIEŠIAIS";"LYGIAGREČIAI"];
    hints = ["Įjungti/išjungti abu šaltinius.";"Atidaryti/uždaryti jungiklį."; ...
             "Užfiksuoti U ir I į žurnalą."; ...
             "Parodyti sujungimo seką."; ...
             "Numerių paskirtis."; ...
             "Atkurti stendą."; ...
             "Teisingas sujungimas."; ...
             "HTML ataskaita."; ...
             "Pradėti iš naujo."; ...
             "Tik E1 grandinėje."; ...
             "E1 ir E2 nuosekliai sutampintieji."; ...
             "E1 ir E2 nuosekliai priešpriešiais.";"E1 ir E2 lygiagrečiai: + su +, − su −."];
endfunction

function [code, label, hint] = ld6_button_info(cb)
    [ids, callbacks, labels, hints] = ld6_button_registry();
    k = find(callbacks == cb);
    if size(k, "*") ~= 1 then error("Valdiklis ne LD6 registre: " + cb); end
    code = ids(k(1)); label = labels(k(1)); hint = hints(k(1));
endfunction

function code = ld6_stage_code(n)
    code = msprintf("E%02d", n);
endfunction

function code = ld6_answer_code(n, k)
    code = msprintf("A%02d.%02d", n, k);
endfunction

function codes = ld6_all_codes()
    tids = ld6_terminal_ids();
    codes = emptystr(size(tids, "*"), 1);
    for k = 1:size(tids, "*"); codes(k) = msprintf("T%02d", k); end
    [bids, callbacks, labels, hints] = ld6_button_registry();
    codes = [codes; bids];
    for n = 1:6; codes($+1, 1) = msprintf("E%02d", n); end
    codes = [codes; "A02.01";"A04.01";"A04.02";"A05.01";"A05.02";"A06.01";"A06.02"];
    codes = [codes; "V02";"H01"];
endfunction
