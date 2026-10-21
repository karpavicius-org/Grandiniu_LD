// ============================================================================
// LD12 elementų numerių registras. Bankas LD12-64-A-2026.
// REGISTRY-CODES: T01:T14 B01:B14 E01:E06 A01.01 A02.01 A03.01 A04.01 A05.01:A05.03 A06.01:A06.03 V02 H01
// ============================================================================

function ids = ld12_terminal_ids()
    ids = ["L1";"L2";"L3";"N";"R1_A";"R1_B";"R2_A";"R2_B";"R3_A";"R3_B";"A_P";"A_N";"V_P";"V_N"];
endfunction

function code = ld12_terminal_code(id)
    tids = ld12_terminal_ids();
    k = find(tids == id);
    if size(k, "*") ~= 1 then code = ""; else code = msprintf("T%02d", k(1)); end
endfunction

function name = ld12_terminal_name(id)
    names = ["Linija L1";"Linija L2";"Linija L3";"Neutralis N"; ...
             "Imtuvo R1 gnybtas a";"Imtuvo R1 gnybtas b"; ...
             "Imtuvo R2 gnybtas a";"Imtuvo R2 gnybtas b"; ...
             "Imtuvo R3 gnybtas a";"Imtuvo R3 gnybtas b"; ...
             "Ampermetro + gnybtas";"Ampermetro − gnybtas";"Voltmetro + gnybtas";"Voltmetro − gnybtas"];
    tids = ld12_terminal_ids();
    k = find(tids == id);
    if size(k, "*") ~= 1 then name = id; else name = names(k(1)); end
endfunction

function [ids, callbacks, labels, hints] = ld12_button_registry()
    ids = ["B01";"B02";"B03";"B04";"B05";"B06";"B07";"B08";"B09";"B10";"B11";"B12";"B13";"B14"];
    callbacks = ["ld12_toggle_power()";"ld12_toggle_switch()";"ld12_measure()"; ...
                 "ld12_show_wiring_guide()";"ld12_show_stand_map()";"ld12_restore_stage()"; ...
                 "ld12_toggle_solution()";"ld12_export_report()";"ld12_restart()"; ...
                 "ld12_set_mode(1)";"ld12_set_mode(2)"; ...
                 "ld12_set_phase(1)";"ld12_set_phase(2)";"ld12_set_phase(3)"];
    labels = ["MAITINIMAS";"JUNGIKLIS";"MATUOTI";"KAIP SUJUNGTI";"STENDO ŽEMĖLAPIS"; ...
              "ATKURTI";"PAVYZDYS";"ATASKAITA";"IŠ NAUJO"; ...
              "ŽVAIGŽDĖ";"TRIKAMPIS";"MATUOTI R1";"MATUOTI R2";"MATUOTI R3"];
    hints=["Įjungti arba išjungti trifazį šaltinį.";"Atidaryti arba uždaryti bendrą trifazį jungiklį."; ...
        "Automatiškai įrašyti pasirinkto imtuvo Uf ir If į žurnalą.";"Parodyti šešių laidų seką."; ...
        "Stendo elementų ir gnybtų paskirtis.";"Išvalyti šio jungimo laidus ir matavimą."; ...
        "Mokymosi pavyzdys; atsiskaitymui nenaudojamas.";"Išsaugoti užbaigtą ataskaitą."; ...
        "Išsaugoti ankstesnį darbą ir pradėti naują atsiskaitymą."; ...
        "Žvaigždė: imtuvai tarp linijų ir bendro neutralio N.";"Trikampis: imtuvai tarp linijų, N nenaudojamas."; ...
        "Imtuvo R1 įtampa Uf ir srovė If.";"Imtuvo R2 įtampa Uf ir srovė If.";"Imtuvo R3 įtampa Uf ir srovė If."];
endfunction

function [code, label, hint] = ld12_button_info(cb)
    [ids, callbacks, labels, hints] = ld12_button_registry();
    k = find(callbacks == cb);
    if size(k, "*") ~= 1 then error("Valdiklis ne LD12 registre: " + cb); end
    code = ids(k(1)); label = labels(k(1)); hint = hints(k(1));
endfunction

function code = ld12_stage_code(n)
    code = msprintf("E%02d", n);
endfunction

function code = ld12_answer_code(n, k)
    code = msprintf("A%02d.%02d", n, k);
endfunction

function codes = ld12_all_codes()
    tids = ld12_terminal_ids();
    codes = emptystr(size(tids, "*"), 1);
    for k = 1:size(tids, "*"); codes(k) = msprintf("T%02d", k); end
    [bids, callbacks, labels, hints] = ld12_button_registry();
    codes = [codes; bids];
    for n = 1:6; codes($+1, 1) = msprintf("E%02d", n); end
    codes = [codes; "A01.01";"A02.01";"A03.01";"A04.01"; ...
             "A05.01";"A05.02";"A05.03"; ...
             "A06.01";"A06.02";"A06.03"];
    codes = [codes; "V02";"H01"];
endfunction
