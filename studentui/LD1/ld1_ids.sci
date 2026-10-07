// ================================================================

// REGISTRY-CODES: T01:T20 B01:B19 E01:E09 A01.01:A01.03 A02.01:A02.03 A03.01:A03.03 A04.01:A04.03 A05.01:A05.03 A06.01:A06.03 A07.01:A07.03 A08.01:A08.03 A09.01:A09.03 V01 V02 H01
// LD1 elementų numerių registras (studentų runtime medis).
// Tikslas: vieninga numeracija visoje virtualioje laboratorijoje,
// kad instrukcijos galėtų rodyti konkrečius elementus:
// „[B05] KAIP SUJUNGTI: [T01] → [T03]; rodmenį į [A02.02]“.
//
// Šeimos (tie patys kodai instrukcijose rašomi laužtiniuose skliaustuose):
//   T01–T20      – stendo gnybtai (kontaktai);
//   B01–B19      – valdymo mygtukai;
//   E01–E09      – etapų numeriai (viršutinė navigacijos juosta);
//   A01.01–A09.03– atsakymų laukeliai (A{etapas}.{laukelis});
//   V01, V02     – slankiklis ir žymės langelis (ne mygtukai);
//   H01          – pagalbinių langų „Uždaryti“ mygtukas.
// Pastaba: laidų (W) kodų LD1 nenaudoja – jungtys aprašomos poromis
// [Txx] → [Txx]; Taip/Ne ir Nuosekli/Lygiagreti/Mišri radijos mygtukai
// palikti be numerių (jų registras nesudaromas).
// Registre kodai laikomi PLIKAIS string literalais ("T03", "B05", ...).
// ================================================================

function ids = ld1_terminal_ids()
    // Tvarka STABILI: atitinka ld1_init_terminals() sąrašą
    // (ld1_callbacks.sci). Keisti tik kartu su ld1_init_terminals().
    // T01=SRC_P  T02=SRC_N  T03=R1_1   T04=R1_2   T05=R2_1   T06=R2_2
    // T07=R3_1   T08=R3_2   T09=VR1_1  T10=VR1_2  T11=M_P    T12=M_N
    // T13=NODE_A1 T14=NODE_A2 T15=NODE_A3 T16=NODE_A4
    // T17=NODE_B1 T18=NODE_B2 T19=NODE_B3 T20=NODE_B4
    ids=["SRC_P";"SRC_N";"R1_1";"R1_2";"R2_1";"R2_2";"R3_1";"R3_2"; ..
         "VR1_1";"VR1_2";"M_P";"M_N"; ..
         "NODE_A1";"NODE_A2";"NODE_A3";"NODE_A4"; ..
         "NODE_B1";"NODE_B2";"NODE_B3";"NODE_B4"];
endfunction

function code = ld1_terminal_code(id)
    // Gnybto viešas numeris, pvz. "T01".
    ids=ld1_terminal_ids(); k=find(ids==id);
    if size(k,"*")<>1 then error("Nežinomas kontaktas: "+id); end
    code=msprintf("T%02d",k);
endfunction

function name = ld1_terminal_name(id)
    // "T01 – Maitinimo šaltinis +10 V" – naudojama gnybtų tooltip'uose
    // ir stendo žemėlapyje. Sąrašas turi sutapti su ld1_terminal_label()
    // (ld1_gui.sci); keičiant vieną – atnaujinti ir kitą.
    ids=ld1_terminal_ids(); k=find(ids==id);
    if size(k,"*")<>1 then error("Nežinomas kontaktas: "+id); end
    names=["Maitinimo šaltinis +10 V";
           "Maitinimo šaltinis 0 V";
           "R1 kairysis gnybtas";
           "R1 dešinysis gnybtas";
           "R2 viršutinis gnybtas";
           "R2 apatinis gnybtas";
           "R3 viršutinis gnybtas";
           "R3 apatinis gnybtas";
           "VR1 viršutinis gnybtas";
           "VR1 apatinis gnybtas";
           "Multimetro + / mA gnybtas";
           "Multimetro COM gnybtas";
           "Mazgas A – kontaktas A1 (bendras su A2–A4)";
           "Mazgas A – kontaktas A2 (bendras su A1, A3, A4)";
           "Mazgas A – kontaktas A3 (bendras su A1, A2, A4)";
           "Mazgas A – kontaktas A4 (bendras su A1–A3)";
           "Mazgas B – kontaktas B1 (bendras su B2–B4)";
           "Mazgas B – kontaktas B2 (bendras su B1, B3, B4)";
           "Mazgas B – kontaktas B3 (bendras su B1, B2, B4)";
           "Mazgas B – kontaktas B4 (bendras su B1–B3)"];
    name=ld1_terminal_code(id)+" – "+names(k);
endfunction

function [ids,callbacks,labels,hints] = ld1_button_registry()
    // Visų LD1 mygtukų registras. Tvarka STABILI: B05 – KAIP SUJUNGTI.
    // callback reikšmės turi sutapti su mygtukų kuriais ld1_gui.sci.
    ids=["B01";"B02";"B03";"B04";"B05";"B06";"B07";"B08";"B09";"B10"; ..
         "B11";"B12";"B13";"B14";"B15";"B16";"B17";"B18";"B19"];
    callbacks=["ld1_toggle_power()"; ..
               "ld1_set_vr(0)"; ..
               "ld1_set_vr(500)"; ..
               "ld1_set_vr(1000)"; ..
               "ld1_show_wiring_guide()"; ..
               "ld1_measure()"; ..
               "ld1_meter_mode(""A"")"; ..
               "ld1_meter_mode(""V"")"; ..
               "ld1_check_wiring()"; ..
               "ld1_remove_last_wire()"; ..
               "ld1_clear_wires()"; ..
               "ld1_restore_current_stage_board()"; ..
               "ld1_show_stand_map()"; ..
               "ld1_check_step()"; ..
               "ld1_prev_step()"; ..
               "ld1_next_step()"; ..
               "ld1_toggle_solution()"; ..
               "ld1_show_help()"; ..
               "ld1_restart()"];
    labels=["Maitinimas ĮJUNGTA / IŠJUNGTAS";
            "VR1 = 0 Ω";
            "VR1 = 500 Ω";
            "VR1 = 1 kΩ";
            "KAIP SUJUNGTI";
            "MATUOTI";
            "Multimetras A (DC)";
            "Multimetras V (DC)";
            "PATIKRINTI SUJUNGIMĄ";
            "ATŠAUKTI LAIDĄ";
            "IŠVALYTI LAIDUS";
            "ATKURTI ETAPO STENDĄ";
            "STENDO ŽEMĖLAPIS";
            "PATIKRINTI IR UŽFIKSUOTI ETAPĄ";
            "← ATGAL";
            "TOLIAU →";
            "PAVYZDYS / SPRENDIMAS";
            "TEORIJA";
            "PRADĖTI IŠ NAUJO"];
    hints=["Įjungia arba išjungia 10 V maitinimo šaltinį. Jungiant laidus šaltinis turi būti IŠJUNGTAS.";
           "Nustato valdomąjį rezistorių VR1 į 0 Ω; reikalinga 8 etape.";
           "Nustato VR1 į 500 Ω; reikalinga 4 ir 7 etapuose.";
           "Nustato VR1 į 1000 Ω; pradinė 2, 3, 5 ir 6 etapų reikšmė.";
           "Parodo dabartinio etapo tikslią jungimo seką su kontaktų T numeriais.";
           "Patikrina jungimą, įjungia grandinę ir įrašo multimetro rodmenį.";
           "Ampermetro režimas: multimetras jungiamas NUOSEKLIAI su srove.";
           "Voltmetro režimas: multimetras jungiamas LYGIAGREČIAI su įtampa.";
           "Patikrina laidų topologiją ir būsenos juostoje parašo, kaip taisyti.";
           "Pašalina paskutinį jūsų pridėtą laidą; užrakintų laidų nepaliečia.";
           "Pašalina visus laidus; veikia tik 1 ir 5 etapuose.";
           "Grąžina dabartinio etapo stendą į saugią pradinę būseną.";
           "Atveria visų T, B, E, A ir V numerių žinyną.";
           "Išsaugo etapo duomenis ir tęsia darbą; suvestinėje išsaugo ataskaitą.";
           "Grįžta vienu etapu atgal neištrinant įrašų.";
           "Pereina prie kito etapo; nebaigtą etapą galima sąmoningai praleisti.";
           "Parodo pilnai teisingą dabartinio etapo variantą; grįžus jūsų darbas lieka.";
           "Atveria teorijos formules ir stendo valdymo taisykles.";
           "Po patvirtinimo išvalo viską ir pradeda darbą nuo 1 etapo."];
endfunction

function [code,label,hint] = ld1_button_info(cb)
    [ids,cbs,labels,hints]=ld1_button_registry(); k=find(cbs==cb);
    if size(k,"*")<>1 then error("Valdiklis neįtrauktas į numerių registrą: "+cb); end
    code=ids(k); label=labels(k); hint=hints(k);
endfunction

function code = ld1_stage_code(n)
    // Etapo viešas numeris, pvz. "E03".
    code=msprintf("E%02d",n);
endfunction

function code = ld1_answer_code(n,k)
    // Atsakymo laukelio kodas, pvz. "A02.01" (2 etapas, 1 laukelis).
    code=msprintf("A%02d.%02d",n,k);
endfunction

function codes = ld1_all_codes()
    // VISI galiojantys LD1 kodai viename stulpelyje (mašininei patikrai).
    tids=ld1_terminal_ids();
    codes=emptystr(size(tids,"*"),1);
    for k=1:size(tids,"*")
        codes(k)=ld1_terminal_code(tids(k));
    end
    [bids,cbs,labels,hints]=ld1_button_registry();
    codes=[codes;bids];
    for n=1:9
        codes($+1,1)=ld1_stage_code(n);
    end
    for n=1:9
        for m=1:3
            codes($+1,1)=ld1_answer_code(n,m);
        end
    end
    codes=[codes;"V01";"V02";"H01"];
endfunction
