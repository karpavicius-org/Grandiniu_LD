// ============================================================================
// LD8 elementų numerių registras. Bankas LD8-64-A-2026.
// REGISTRY-CODES: T01:T14 B01:B12 E01:E06 A02.01 A03.01 A04.01 A05.01:A05.03 A06.01:A06.03 V02 H01
// ============================================================================

function ids = ld8_terminal_ids()
    ids = ["E_P";"E_N";"K1";"K2";"A_P";"A_N";"R1_A";"R1_B";"R2_A";"R2_B";"R3_A";"R3_B";"V_P";"V_N"];
endfunction

function code = ld8_terminal_code(id)
    tids = ld8_terminal_ids();
    k = find(tids == id);
    if size(k, "*") ~= 1 then code = ""; else code = msprintf("T%02d", k(1)); end
endfunction

function name = ld8_terminal_name(id)
    names = ["Šaltinio E + gnybtas";"Šaltinio E − gnybtas"; ...
             "Jungiklio įėjimas";"Jungiklio išėjimas";"Ampermetro + gnybtas"; ...
             "Ampermetro − gnybtas";"Rezistoriaus R1 gnybtas a";"Rezistoriaus R1 gnybtas b"; ...
             "Rezistoriaus R2 gnybtas a";"Rezistoriaus R2 gnybtas b"; ...
             "Rezistoriaus R3 gnybtas a";"Rezistoriaus R3 gnybtas b"; ...
             "Voltmetro + zondas";"Voltmetro − zondas"];
    tids = ld8_terminal_ids();
    k = find(tids == id);
    if size(k, "*") ~= 1 then name = id; else name = names(k(1)); end
endfunction

function [ids, callbacks, labels, hints] = ld8_button_registry()
    ids = ["B01";"B02";"B03";"B04";"B05";"B06";"B07";"B08";"B09";"B10";"B11";"B12"];
    callbacks = ["ld8_toggle_power()";"ld8_toggle_switch()";"ld8_measure()"; ...
                 "ld8_show_wiring_guide()";"ld8_show_stand_map()";"ld8_restore_stage()"; ...
                 "ld8_toggle_solution()";"bench_export_current(""LD8"")";"ld8_restart()"; ...
                 "ld8_set_mode(1)";"ld8_set_mode(2)";"ld8_set_mode(3)"];
    labels = ["MAITINIMAS";"JUNGIKLIS";"MATUOTI";"KAIP SUJUNGTI";"STENDO ŽEMĖLAPIS"; ...
              "ATKURTI";"PAVYZDYS";"ATASKAITA";"IŠ NAUJO"; ...
              "NUOSEKLIAI";"LYGIAGREČIAI";"MIŠRIAI"];
    hints = ["Įjungti/išjungti šaltinį.";"Atidaryti/uždaryti jungiklį."; ...
             "Užfiksuoti U ir I į žurnalą."; ...
             "Parodyti sujungimo seką."; ...
             "Numerių paskirtis."; ...
             "Atkurti stendą."; ...
             "Teisingas sujungimas."; ...
             "HTML ataskaita."; ...
             "Pradėti iš naujo."; ...
             "R1, R2 ir R3 viena pakopa."; ...
             "R1, R2 ir R3 tarp tų pačių mazgų."; ...
             "R1 nuosekliai su lygiagrečiais R2 ir R3."];
endfunction

function [code, label, hint] = ld8_button_info(cb)
    [ids, callbacks, labels, hints] = ld8_button_registry();
    k = find(callbacks == cb);
    if size(k, "*") ~= 1 then error("Valdiklis ne LD8 registre: " + cb); end
    code = ids(k(1)); label = labels(k(1)); hint = hints(k(1));
endfunction

function code = ld8_stage_code(n)
    code = msprintf("E%02d", n);
endfunction

function code = ld8_answer_code(n, k)
    code = msprintf("A%02d.%02d", n, k);
endfunction

function codes = ld8_all_codes()
    tids = ld8_terminal_ids();
    codes = emptystr(size(tids, "*"), 1);
    for k = 1:size(tids, "*"); codes(k) = msprintf("T%02d", k); end
    [bids, callbacks, labels, hints] = ld8_button_registry();
    codes = [codes; bids];
    for n = 1:6; codes($+1, 1) = msprintf("E%02d", n); end
    codes = [codes; "A02.01";"A03.01";"A04.01"; ...
             "A05.01";"A05.02";"A05.03";"A06.01";"A06.02";"A06.03"];
    codes = [codes; "V02";"H01"];
endfunction
