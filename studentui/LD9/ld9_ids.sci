// ============================================================================
// LD9 elementų numerių registras. Bankas LD9-64-A-2026.
// REGISTRY-CODES: T01:T12 B01:B16 E01:E06 A01.01 A03.01 A03.02 A05.01:A05.06 A06.01:A06.03 V02 H01
// ============================================================================

function ids = ld9_terminal_ids()
    ids = ["GEN_P";"GEN_N";"K1";"K2";"A_P";"A_N";"R_A";"R_B";"L_A";"L_B";"C_A";"C_B"];
endfunction

function code = ld9_terminal_code(id)
    tids = ld9_terminal_ids();
    k = find(tids == id);
    if size(k, "*") ~= 1 then code = ""; else code = msprintf("T%02d", k(1)); end
endfunction

function name = ld9_terminal_name(id)
    names = ["Generatoriaus + gnybtas";"Generatoriaus − gnybtas"; ...
             "Jungiklio įėjimas";"Jungiklio išėjimas";"Ampermetro + gnybtas"; ...
             "Ampermetro − gnybtas";"Rezistoriaus R gnybtas a";"Rezistoriaus R gnybtas b"; ...
             "Reaktyviosios rišlės L gnybtas a";"Reaktyviosios rišlės L gnybtas b"; ...
             "Kondensatoriaus C gnybtas a";"Kondensatoriaus C gnybtas b"];
    tids = ld9_terminal_ids();
    k = find(tids == id);
    if size(k, "*") ~= 1 then name = id; else name = names(k(1)); end
endfunction

function [ids, callbacks, labels, hints] = ld9_button_registry()
    ids = ["B01";"B02";"B03";"B04";"B05";"B06";"B07";"B08";"B09"; ...
           "B10";"B11";"B12";"B13";"B14";"B15";"B16"];
    callbacks = ["ld9_toggle_power()";"ld9_toggle_switch()";"ld9_measure()"; ...
                 "ld9_show_wiring_guide()";"ld9_show_stand_map()";"ld9_restore_stage()"; ...
                 "ld9_toggle_solution()";"ld9_export_report()";"ld9_restart()"; ...
                 "ld9_set_freq(1)";"ld9_set_freq(2)";"ld9_set_freq(3)"; ...
                 "ld9_set_target(1)";"ld9_set_target(2)";"ld9_set_target(3)";"ld9_set_target(4)"];
    labels = ["MAITINIMAS";"JUNGIKLIS";"MATUOTI";"KAIP SUJUNGTI";"STENDO ŽEMĖLAPIS"; ...
              "ATKURTI";"PAVYZDYS";"ATASKAITA";"IŠ NAUJO"; ...
              "0,5·f0";"f0";"2·f0"; ...
              "UR · R";"UL · L";"UC · C";"U · GEN"];
    hints = ["Įjungti/išjungti generatorių.";"Atidaryti/uždaryti jungiklį."; ...
             "Užfiksuoti I ir pasirinktą U į žurnalą."; ...
             "Parodyti sujungimo seką."; ...
             "Numerių paskirtis."; ...
             "Atkurti stendą."; ...
             "Teisingas sujungimas."; ...
             "HTML ataskaita."; ...
             "Pradėti iš naujo."; ...
             "Žemiau rezonanso.";"Rezonanso dažnis.";"Aukščiau rezonanso."; ...
             "Voltmetras prie R.";"Voltmetras prie L.";"Voltmetras prie C.";"Voltmetras prie generatoriaus."];
endfunction

function [code, label, hint] = ld9_button_info(cb)
    [ids, callbacks, labels, hints] = ld9_button_registry();
    k = find(callbacks == cb);
    if size(k, "*") ~= 1 then error("Valdiklis ne LD9 registre: " + cb); end
    code = ids(k(1)); label = labels(k(1)); hint = hints(k(1));
endfunction

function code = ld9_stage_code(n)
    code = msprintf("E%02d", n);
endfunction

function code = ld9_answer_code(n, k)
    code = msprintf("A%02d.%02d", n, k);
endfunction

function k = ld9_stage_freq(step)
    // Etapas 2 matuoja ties 0,5·f0; 3 — f0; 4 — 2·f0.
    map = [0.5 1 2]; k = map(step-1);
endfunction

function codes = ld9_all_codes()
    tids = ld9_terminal_ids();
    codes = emptystr(size(tids, "*"), 1);
    for k = 1:size(tids, "*"); codes(k) = msprintf("T%02d", k); end
    [bids, callbacks, labels, hints] = ld9_button_registry();
    codes = [codes; bids];
    for n = 1:6; codes($+1, 1) = msprintf("E%02d", n); end
    codes = [codes; "A01.01";"A03.01";"A03.02"; ...
             "A05.01";"A05.02";"A05.03";"A05.04";"A05.05";"A05.06"; ...
             "A06.01";"A06.02";"A06.03"];
    codes = [codes; "V02";"H01"];
endfunction
