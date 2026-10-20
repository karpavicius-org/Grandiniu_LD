// ============================================================================
// LD2 metodikos langas ir per-etapo turinys su elementų numerių kodais.
// Adaptuota iš numerių registro architektūros: visi kodai laužtiniuose
// skliaustuose ([T07], [B12], [A04.01], [W01]), laidai visur W%02d.
// ============================================================================

// Metodika: naujai parašyti paaiškinimai, ne pažodinė šaltinių kopija.
function lines=ld2_common_theory()
    lines=["Šis stendas modeliuoja tik nusistovėjusią sinusinę būseną. Tai virtualūs matavimai, o ne iš fizinio KL modulio gauti duomenys. Laidai ir ampermetras idealūs, voltmetras grandinės neapkrauna; nevertinamos temperatūros, triukšmo ir komponentų tolerancijos."; ...
        "E, U, I ir prietaisų rodmenys yra efektinės (RMS) vertės. Sinuso amplitudė Um = sqrt(2)·U, periodas T = 1/f. Dažnis f matuojamas Hz, kampinis dažnis omega = 2·pi·f – rad/s."; ...
        "Vienetai: 1 kΩ = 1000 Ω; 1 mH = 0,001 H; 1 µF = 10^(-6) F; 1 nF = 10^(-9) F; 1 A = 1000 mA; 1 W = 1000 mW. Į [F04] rašomi Hz, ne kHz. Atsakymo lauke įrašomas tik skaičius jo etiketėje nurodytu vienetu; leidžiamas taškas arba kablelis."; ...
        "Fazės sutartis: šaltinio įtampos fazė 0°. φZ yra kompleksinės varžos kampas, srovės fazė φI = −φZ. RC srovė pirmauja, RL atsilieka; tai aiškina oscilograma ir fazorių diagramos, o ne pašalinti teoriniai įvedimo laukai."; ...
        "Kontaktai pažymėti [T01]–[T38], mygtukai [B01]–[B45], o 10 aktyvių etapų pasiekiami per Pagalba → Etapai, įvedimo laukai [F01]–[F04], papildomi valdikliai [V01]–[V02]. [H01]–[H04] numeriai priklauso metodikos langui. Tas pats numeris visuomet reiškia tą pačią paskirtį."; ...
        "Dešinėje matomas KĄ DARYTI DABAR? – vienas artimiausias veiksmas, pagal būseną paryškintas gnybtas arba mygtukas. Tai pagalba, ne automatinis atlikimas."; ...
        "Jungtis sukuriama dviem paspaudimais: pirmas [T] numeris, paskui antras [T] numeris. Pažymėtas lizdas pagelsta. Vienam fiziniam lizdui skirtas vienas laidas. Susikertančios linijos be bendro lizdo nesudaro naujo mazgo."; ...
        "Pagrindiniai ir matavimo lizdai yra atskiri fiziniai lizdai tame pačiame elektriniame taške. Pavyzdžiui, R8 [T09] ir [T11] yra sujungti viduje, kaip ir [T10] bei [T12]. Violetinis matavimo lizdas nėra papildomas elementas grandinėje."; ...
        "[B14] arba [B15] atlieka matavimą ir įrašo jį į žurnalą. [B21], [B23], [B24] ir [B25] papildomai atrenka jau atliktą matavimą atitinkamai paieškos lentelei. Pakeitus f, laidus ar maitinimą, gyvas rodmuo panaikinamas; žurnalas išlieka."; ...
        "Mokymosi režimu [B03] atveria atliktą pavyzdį, o antras paspaudimas grąžina jūsų darbą. Pavyzdžio duomenys atskirti. Per Pagalba → Etapai galima sugrįžti į jau pasiektą etapą. Praleistas etapas nėra atliktas."; ...
        "Per Pagalba galima išsaugoti ir atkurti .sod juodraštį. Išsaugoti ataskaitą sukuria vieną HTML failą su studento duomenimis, matavimais ir atsakymais. Ją dėstytojui siųskite užbaigę visus etapus."];
endfunction

function d=ld2_method_data_1_4(step)
    d=struct("goal", "", "theory",emptystr(0,1), "method",emptystr(0,1), "formulas",emptystr(0,1), "check",emptystr(0,1), "mistakes",emptystr(0,1), "questions",emptystr(0,1), "source",emptystr(0,1));
    select step
    case 1 then
        d.goal="Priskirti individualų variantą ir suprasti, kas bus matuojama.";
        d.theory=["Sąrašo numeris n nuo 1 iki 64 vienareikšmiškai nustato visų RC, RL ir RLC bandymų parametrus. Tai nėra atsitiktinis parinkimas: tas pats n kaskart duoda tą patį LD2-Vnn variantą. Matavimai, pavyzdžiai ir ataskaita naudoja tą patį rinkinį.";"Iš pirminio aprašo išlaikytos 9 V RC/RL ir 5 V RLC efektinės įtampos, C2 = 4,7 µF ir L1 = 0,5 H. Individualios rezistorių, RLC L3/C4 ir RC/RL dažnių reikšmės yra naujas metodinis priedas virtualiam darbui, ne spėjimas apie tikro modulio elementus.";"LD2 yra šio programinio stendo vardas pagal ankstesnį 6 puslapių aprašą. Dalyko TF-EA-2025-07 apraše ši RC/RL/RLC tematika siejasi su 9 ir 10 laboratoriniais darbais. Ji nėra I semestro 2 laboratorinis darbas „Įtampos ir srovės matavimas“.";"64 LD2 variantų bankas atskiras nuo pridėtos praktinių darbų medžiagos 60 variantų banko. Šie numeriai nereiškia tų pačių uždavinių."];
        d.method=["1. Pagalba → Studentas ir priskirtos reikšmės ([B01]). [F01] įrašykite savo eilės numerį 1–64; [F02] vardą ir pavardę; [F03] grupę. Patvirtinkite OK.";"2. Patikrinkite patvirtinimą: „Sąrašo Nr. n → LD2-Vnn“. [B39] patikrinkite visas priskirtas reikšmes.";"3. [B43] rodo visą 64 variantų banką. [B42] paaiškina kontaktus; [B45] – valdiklius.";"4. Perskaitykite metodikos lango bendrąją atmintinę. [B38] paaiškina šaltinius ir metodinius pakeitimus.";"5. [B04] patikrinkite etapą. [B05] išsaugokite pirmą .sod failą. Toliau → pereikite į [E02]."];
        d.formulas=["n = sveikas skaičius nuo 1 iki 64.";"a = floor((n−1)/8)+1; b = modulo(n−1,8)+1. Šie indeksai parenka 8×8 variantų lentelę."];
        d.check=["Antraštėje matomas jūsų LD2-Vnn, vardas ir grupė.";"Parametrai keičiasi tik per [B01] keičiant numerį; tada ankstesni bandymai nesujungiami su naujais."];
        d.mistakes=["Įvestas 0 arba 65: [B01] pataisykite į 1–64.";"Įvesta „17a“: [F01] rašykite tik 17.";"Suklydote tik varde: palikite tą patį numerį ir pakeiskite vardą – matavimai lieka."];
        d.questions=["Kuo efektinė įtampa skiriasi nuo amplitudės?";"Kodėl pakeitus varianto numerį negalima palikti seno varianto matavimų?"];
        d.source=["[S1] p. 3–6: RC, RL ir RLC darbų turinys.";"[S2] dalyko aprašas: temos 13–14, darbai 9–10.";"[N] 64 variantai, numeriai ir ataskaitos tvarka sukurti šiam stendui."];
    case 2 then
        d.goal="Sujungti nuoseklią RC grandinę ir teisingai įterpti ampermetrą.";
        d.theory=["Nuoseklioje grandinėje rezistoriumi, kondensatoriumi ir ampermetru teka ta pati srovė. Visi keturi pagrindiniai laidai sudaro vieną uždarą kelią nuo generatoriaus išėjimo atgal iki jo grįžimo lizdo.";"Idealiame ampermetre įtampos kritimo nepaisoma. Jis įterpiamas į srovės kelią, o ne prijungiamas tarp generatoriaus gnybtų. Šis vedamasis stendas netinkamos jungties neįrašo ir nurodo reikalingą porą.";"RC kondensatorius nekeičiamas laidu: kondensatoriaus vidinis ryšys priklauso nuo dažnio, jo gnybtai nėra tas pats mazgas. Matavimo lizdai [T11]/[T12] ir [T15]/[T16] šiame sujungimo etape nereikalingi."];
        d.method=["1. [B09] būsena turi būti IŠJUNGTA. Jei jau įjungta, paspauskite [B09].";"2. [W01]: [T01] → [T05]. Spauskite [T01], po to [T05]. Generatoriaus išėjimas → ampermetro įėjimas.";"3. [W02]: [T06] → [T09]. Spauskite [T06], po to [T09]. Ampermetro COM → R8 kairysis lizdas.";"4. [W03]: [T10] → [T13]. Spauskite [T10], po to [T13]. R8 dešinysis lizdas → C2 kairysis lizdas.";"5. [W04]: [T14] → [T02]. Spauskite [T14], po to [T02]. C2 dešinysis lizdas → generatoriaus grįžimas.";"6. [B04] patikrinkite 4 laidus. Suklydus [B11] atšaukia paskutinį, [B12] išvalo šios dalies laidus.";"7. [B03] galima apžiūrėti atliktą jungimą ir grįžti į savo darbą. Tada [B04], paskui Toliau →."];
        d.formulas=["Srovės kelias: [T01] → [T05] — A~ — [T06] → [T09] — R8 — [T10] → [T13] — C2 — [T14] → [T02].";"ZRC = R8 − j/(2·pi·f·C2); teorinė formulė aptariama RC matavimo etape."];
        d.check=["4 pagrindiniai laidai, nė vieno voltmetro zondo.";"[B04] nerodo trūkstamų jungčių; [E02] po patikros pažymimas atliktu."];
        d.mistakes=["[T09] jau užimtas: kitas laidas jungiamas prie [T10], ne dar kartą [T09].";"Paspaustas komponento pavadinimas: spauskite patį numeruotą lizdą, pvz., [T09].";"Laido nėra: pasirinkti reikia du skirtingus lizdus iš nurodytos poros."];
        d.questions=["Kodėl ampermetras nėra jungiamas lygiagrečiai šaltiniui?";"Kodėl vienodas srovės stipris nereiškia vienodų elementų įtampų?"];
        d.source=["[S1] p. 3, RC darbo 1–2 punktai.";"[S3] matavimo prietaisų nuoseklaus ir lygiagretaus jungimo pagrindai.";"[N] T numeriai ir keturių laidų planas – virtualaus stendo realizacija."];
    case 4 then
        d.goal="Sujungus RC grandinę išmatuoti srovę bei įtampas ir palyginti du matavimais pagrįstus dydžius. Septyni teoriniai skaičiavimai nebereikalingi.";
        d.theory=["Voltmetras jungiamas lygiagrečiai: jo du zondai turi apimti vieną visą elementą arba šaltinį. [T07] yra V~ lizdas, [T08] – COM. Tai atskiras prietaisas nuo grandinėje esančio ampermetro.";"R8 matavimo pora [T11]/[T12] elektriškai sutampa su pagrindiniais [T09]/[T10], C2 pora [T15]/[T16] – su [T13]/[T14], o šaltinio [T03]/[T04] – su [T01]/[T02]. Todėl voltmetro matavimas pagrindinio laido nenutraukia.";"Pakeitus zondus senasis gyvas skaičius išnyksta. [B15] atlieka naują matavimą ir jį išsaugo žurnale. Vien zondų prijungimas nėra matavimas.";"Iš matuotų UR ir UC apskaičiuokite šaltinio RMS įtampą pagal statmenų fazorių sumą. Srovę patikrinkite per rezistorių: I = UR/R8. Idealiame modelyje skirtumai gali kilti tik dėl apvalinimo."];
        d.method=["1. [B09] įjunkite generatorių. [B14] išmatuokite I; rodmuo ir kilmė atsiranda žurnale.";"2. UR8: [T07] → [T11] ir [T08] → [T12]. [B15] išmatuokite įtampą.";"3. [B13] nuimkite abu V zondus. UC2: [T07] → [T15] ir [T08] → [T16]. [B15].";"4. [B13]. Šaltinis E: [T07] → [T03] ir [T08] → [T04]. [B15].";"5. [A04.01] įrašykite sqrt(UR8²+UC2²); [A04.02] įrašykite 1000·UR8/R8.";"6. Meniu „Grafikai“ ([B28], [B29], [B30]): diagramos ir oscilograma. [B41] atsakykite į klausimus. [B04] patikrinkite."];
        d.formulas=["E_sk = sqrt(UR8_mat²+UC2_mat²).";"I_sk,mA = 1000·UR8_mat/R8.";"δE = 100·(E_sk−E_mat)/E_mat.";"u(t)=sqrt(2)·E·sin(2·pi·f·t); i(t)=sqrt(2)·I·sin(2·pi·f·t+φI)."];
        d.check=["Žurnale turi būti RC I, UR, UC ir UE.";"Du skaitiniai atsakymai apskaičiuoti iš realiai užfiksuotų virtualių matavimų."];
        d.mistakes=["NEPRIJUNGTA: patikrinkite abu zondus; vien [T07] → [T11] nepakanka.";"PARUOŠTA: spauskite [B15], o srovei [B14].";"Norite keisti UR į UC: [B13] nuima tik zondus; pagrindinės grandinės neardykite."];
        d.questions=["Ką oscilogramoje reiškia srovės pirmavimas?";"Ar idealus virtualus matavimas leidžia įvertinti tikro voltmetro paklaidą? Kodėl?"];
        d.source=["[S1] p. 3, RC 4–7 punktai.";"[N] matavimų žurnalas, jų kilmė ir oscilograma – papildymas."];
    else error("Netinkamas metodikos etapas.");
    end
endfunction

function d=ld2_method_data_5_8(step)
    d=struct("goal", "", "theory",emptystr(0,1), "method",emptystr(0,1), "formulas",emptystr(0,1), "check",emptystr(0,1), "mistakes",emptystr(0,1), "questions",emptystr(0,1), "source",emptystr(0,1));
    select step
    case 5 then
        d.goal="Sujungti nuoseklią RL grandinę ir atskirti ją nuo RC.";
        d.theory=["RL grandinėje kondensatorių pakeičia ritė. Rezistorius ir ritė sujungti nuosekliai, todėl jų srovė ta pati. Ritės induktyvioji varža priklauso nuo dažnio: XL = 2·pi·f·L.";"Šiame modelyje L1 yra ideali ritė be apvijos aktyviosios varžos. Visa aktyvioji varža sutelkta R9. Tikro stendo ritės nuostolius reikėtų įvertinti atskirai – jie čia neapsimetami žinomais.";"RC ir RL gnybtų numeriai specialiai skirtingi. Generatorius bei prietaisai išlaiko [T01]–[T08], tačiau R9 ir L1 turi naujus [T17]–[T24]. Tai saugo nuo vienodų „1“ ir „2“ žymų painiojimo."];
        d.method=["1. Patikrinkite [B09]: generatorius IŠJUNGTAS.";"2. [W01]: [T01] → [T05].  [W02]: [T06] → [T17].";"3. [W03]: [T18] → [T21].  [W04]: [T22] → [T02].";"4. [B04] patikrinkite keturių laidų planą. Violetinių [T19]/[T20] ir [T23]/[T24] dar nejunkite.";"5. [B03] leidžia palyginti su atliktu pavyzdžiu. Grįžę [B04] patikrinkite savą jungimą ir Toliau → pereikite."];
        d.formulas=["Srovės kelias: [T01] → [T05] — A~ — [T06] → [T17] — R9 — [T18] → [T21] — L1 — [T22] → [T02].";"ZRL = R9 + j·2·pi·f_RL·L1."];
        d.check=["Keturios numatytos jungtys; srovės kelias vienas."];
        d.mistakes=["Ieškote [T09]: jis priklauso RC R8. RL rezistorius yra R9, jo pagrindiniai lizdai [T17] ir [T18].";"Norite prijungti ritę prie matavimo lizdo: naudokite pagrindinius [T21] ir [T22]."];
        d.questions=["Kaip nuo dažnio priklauso ritės ir kondensatoriaus varžos?";"Kokia tikros ritės savybė čia sąmoningai neįtraukta?"];
        d.source=["[S1] p. 4, RL 1–2 punktai.";"[N] idealių elementų prielaidos ir numeravimo sistema."];
    case 7 then
        d.goal="Sujungus RL grandinę išmatuoti rodmenis ir patikrinti įtampų ryšius. Septyni teoriniai skaičiavimai nebereikalingi.";
        d.theory=["Matavimo principas toks pats kaip [E04]: ampermetras pagrindinėje grandinėje, voltmetras lygiagrečiai pasirinktam elementui. Šioje dalyje R9 matavimo lizdai yra [T19]/[T20], L1 – [T23]/[T24].";"Voltmetras rodo RMS modulį. Sukeitus jo zondus sinusinės įtampos RMS modulis nesikeičia; fazoriaus krypties sutartis diagramoje vis tiek turi būti nurodyta.";"Iš UR9 išvestą srovę lyginkite su A~ rodmeniu. E išveskite iš UR9 ir UL1 fazorių, ne jų paprastos aritmetinės sumos.";"Oscilograma apskaičiuota iš sinusinio modelio ir parodo fazės poslinkį. Ji nevaizduoja realaus skaitmeninio osciloskopo triukšmo ar diskretizavimo paklaidų."];
        d.method=["1. [B09] įjunkite generatorių. [B14] išmatuokite I.";"2. UR9: [T07] → [T19], [T08] → [T20]. [B15].";"3. [B13]. UL1: [T07] → [T23], [T08] → [T24]. [B15].";"4. [B13]. Šaltinio E: [T07] → [T03], [T08] → [T04]. [B15].";"5. [A07.01] įrašykite sqrt(UR9²+UL1²); [A07.02] – 1000·UR9/R9.";"6. Meniu „Grafikai“ ([B28], [B29], [B30]) palyginkite diagramas. [B41] įrašykite pastebėjimus. [B04]."];
        d.formulas=["E_sk = sqrt(UR9_mat²+UL1_mat²).";"I_sk,mA = 1000·UR9_mat/R9.";"i(t) = sqrt(2)·I·sin(2·pi·f·t+φI), φI<0."];
        d.check=["Žurnale RL I, UR, UL ir UE; du užpildyti skaičiavimo laukai."];
        d.mistakes=["Rodoma sena reikšmė žurnale, bet ekrane PARUOŠTA: žurnalas yra istorija; naujam matavimui [B15].";"Norite kondensatoriaus įtampos: RL dalyje C nėra, matuojama L1 per [T23]/[T24]."];
        d.questions=["Kaip iš oscilogramos matyti srovės atsilikimas?";"Kuo skiriasi A~ matavimas ir iš UR9/R9 apskaičiuota srovė?"];
        d.source=["[S1] p. 4, RL 4–6 punktai.";"[N] papildyta atskira oscilograma ir matavimo kilmės žurnalas."];
    case 8 then
        d.goal="Sujungti nuoseklų C4–L3–R13 kontūrą dažnio tyrimui.";
        d.theory=["Nuosekliame RLC kontūre bendra reaktyvioji dalis X = XL−XC. Didinant dažnį XL didėja, XC mažėja; tarp jų yra dažnis, kuriame jos susilygina.";"R13 yra kontūro aktyvioji varža. Todėl jos įtampa UR13 = I·R13 tiesiogiai proporcinga kontūro srovei. Stebėdami UR13 maksimumą vėliau ieškosime srovės rezonanso.";"Šiame modelyje generatoriaus vidinė ir ritės apvijos varžos lygios nuliui. Visa kontūro aktyvioji varža RΣ = R13. Todėl rezonanse UR13 = E_RLC. Tikram prietaisui ši lygybė be papildomų nuostolių įvertinimo nebūtinai galiotų.";"[T37]/[T38] yra papildomi bendros C4+L3 įtampos matavimo lizdai. [T37] viduje sujungtas su [T25], [T38] – su [T30]. Jų nejunkite tarpusavyje laidu, nes taip apeitumėte reaktyviąją porą."];
        d.method=["1. [B09] būsena IŠJUNGTA. Reikia 5 pagrindinių laidų.";"2. [W01]: [T01] → [T05].  [W02]: [T06] → [T25].";"3. [W03]: [T26] → [T29].  [W04]: [T30] → [T33].";"4. [W05]: [T34] → [T02]. Voltmetro dar nejunkite.";"5. [B04] patikrinkite. Visa srovė turi tekėti per A~, C4, L3 ir R13.";"6. [B03] rodo tą patį penkių laidų planą. Grįžę [B04], paskui Toliau →."];
        d.formulas=["Z = R13+j(2·pi·f·L3−1/(2·pi·f·C4)).";"I = E_RLC/|Z|; UR13 = I·R13."];
        d.check=["[T01]–[T05], [T06]–[T25], [T26]–[T29], [T30]–[T33], [T34]–[T02] yra penkios užbaigtos poros."];
        d.mistakes=["Vietoje [T26] pasirinktas [T28]: [T28] matavimo lizdas, pagrindinei grandinei naudokite [T26].";"Vieną laidą prijungėte prie R13 netinkamo krašto: srovės įėjimas [T33], išėjimas [T34]."];
        d.questions=["Kodėl rezonanso paieškai tinka R13 įtampa?";"Kodėl papildomi matavimo lizdai nėra naujos grandinės šakos su apkrova?"];
        d.source=["[S1] p. 5, RLC schema 2-18-1 ir 1–2 punktai.";"[N] penkių laidų planas ir idealios aktyviosios varžos prielaida."];
    else error("Netinkamas metodikos etapas.");
    end
endfunction

function d=ld2_method_data_9_12(step)
    d=struct("goal", "", "theory",emptystr(0,1), "method",emptystr(0,1), "formulas",emptystr(0,1), "check",emptystr(0,1), "mistakes",emptystr(0,1), "questions",emptystr(0,1), "source",emptystr(0,1));
    select step
    case 9 then
        d.goal="Eksperimentiškai virtualiame modelyje rasti rezonansą pagal UR13 maksimumą.";
        d.theory=["Rezonanso sąlyga XL=XC duoda f0 = 1/(2·pi·sqrt(L3·C4)). Ši teorinė reikšmė yra paieškos orientyras, tačiau matuotas fr gaunamas iš jūsų užfiksuotų taškų.";"Ties f0 reaktyviosios dalys kompensuojasi, |Z| mažiausias ir lygus R13. Srovė bei UR13 didžiausi. Srovės ir šaltinio įtampos fazės sutampa.";"Vieno didelio rodmens nepakanka maksimumui pagrįsti: reikia bent vieno taško mažesniu ir vieno didesniu dažniu, kurių UR13 mažesni. Programa reikalauja bent 3 skirtingų dažnių ir maksimumo tarp kraštinių taškų.";"[F04] leidžia įvesti trupmeninį dažnį; [B18] ir [B20] mygtukai keičia dažnio žingsnį. Po kiekvieno keitimo būtinas naujas [B15] matavimas. [B21] negali naudoti pasenusio rodmens.";"Periodas T_ms = 1000/fr. Tai tas pats ryšys kaip f = 1/T, tik laikas pateiktas milisekundėmis. [B30] modelio oscilogramoje galima patikrinti, kokį periodą atitinka nustatytas dažnis."];
        d.method=["1. [B13] nuimkite likusius V zondus. [T07] → [T35], [T08] → [T36] – voltmetras apima R13.";"2. [B09] įjunkite generatorių. Apskaičiuokite teorinį f0 pagal savo L3 ir C4.";"3. [F04] įrašykite pasirinktą dažnį Hz; [B16] jį taiko. [B15] išmatuokite UR13; [B21] įrašykite tašką.";"4. Keiskite dažnį ir kartokite [B16] → [B15] → [B21]. Artėdami prie maksimumo mažinkite žingsnį; turėkite taškų iš abiejų pusių.";"5. Meniu „Grafikai“: [B31] rodo būtent jūsų paieškos taškus, [B30] – nustatyto dažnio periodą.";"6. [A09.01] teorinis f0; [A09.02] geriausio užfiksuoto taško fr; [A09.03] 1000/fr; [A09.04] to taško UR13.";"7. [B41] aprašykite paiešką. [B04] tikrina ir taškus, ir skaičius."];
        d.formulas=["f0 = 1/(2·pi·sqrt(L3·C4)).";"XL = 2·pi·f·L3; XC = 1/(2·pi·f·C4).";"|Z| = sqrt(R13²+(XL−XC)²).";"I = E_RLC/|Z|; UR13=I·R13."; "T_ms = 1000/fr_mat."];
        d.check=["Bent 3 skirtingi užfiksuoti taškai; maksimumas ne intervalo krašte.";"UR13,max turi būti bent 97 % E_RLC. Tai mokomasis paieškos kriterijus, ne matavimo prietaiso tikslumo specifikacija.";"Ataskaitoje teorinis f0 ir rastas fr rodomi atskirai."];
        d.mistakes=["[B21] sako rodmuo paseno: dažnį jau pakeitėte; dar kartą [B15], tada [B21].";"Visi taškai vienoje maksimumo pusėje: išmatuokite ir užfiksuokite tašką kitoje pusėje.";"Į [F04] įrašyta 5 vietoje 5 kHz: [F04] reikia 5000."];
        d.questions=["Kaip pagrindžiate, kad rastas taškas yra maksimumas?";"Kodėl teorinis ir jūsų rastas fr gali šiek tiek skirtis?"];
        d.source=["[S1] p. 5, RLC 3–4 punktai.";"[N] paieškos taškų aprėminimas, kilmė ir f0/fr atskyrimas."];
    case 10 then
        d.goal="Atskirai rasti UL ir UC maksimumus bei bendros ULC įtampos minimumą.";
        d.theory=["UL = I·XL, UC = I·XC. Keičiant dažnį keičiasi ne tik srovė, bet ir atitinkamas XL arba XC. Todėl atskiri įtampų maksimumai nebūtinai sutampa su srovės maksimumo dažniu.";"Šiam idealiam, bet slopinamam RLC modeliui Q = sqrt(L3/C4)/R13. Kai Q>1/sqrt(2), fC = f0·sqrt(1−1/(2Q²)), o fL = f0/sqrt(1−1/(2Q²)). Taigi fC < f0 < fL. Visi 64 variantai parinkti šiai sąlygai.";"Ties tikslia srovės rezonanso būsena UL ir UC moduliai lygūs, jų fazės priešingos, todėl ULC = |UL−UC| = 0. Bendros reaktyviosios poros įtampos negalima rasti kaip UL+UC.";"Į atsakymus rašomi jūsų užfiksuoti ekstremumai ir jų dažniai. Jeigu f nėra tiksliai f0, tikras virtualaus prietaiso ULC rodmuo gali būti nedidelis, bet nenulinis. Programa jo nepakeičia teoriniu nuliu.";"Maksimumų stiprumas priklauso nuo Q; jų įtampos gali viršyti šaltinio įtampą. Tai neprieštarauja Kirchhofo dėsniui, nes sumuojami fazoriai, o ne visi teigiami moduliai."];
        d.method=["1. UL: [B13], tada [T07] → [T31] ir [T08] → [T32]. [B09] turi būti ĮJUNGTA.";"2. Keiskite [F04] / [B16]; kiekviename dažnyje [B15] → [B23]. UL reikia bent 3 taškų, iš abiejų rasto maksimumo pusių.";"3. UC: [B13], [T07] → [T27] ir [T08] → [T28]. Pakartokite dažnio keitimą → [B15] → [B23]; raskite atskirą maksimumą.";"4. ULC: [B13], [T07] → [T37] ir [T08] → [T38]. Taip pat įrašykite bent 3 taškus, dabar ieškokite minimumo.";"5. [B33] rodo kiekvieno taikinio geriausią rodmenį su jo dažniu.";"6. [A10.01]–[A10.06] įrašykite ULmax, UCmax, ULCmin, fL, fC, fULC. Įtampas ir dažnius imkite iš atitinkamų užfiksuotų taškų.";"7. [B41] palyginkite fL, fC ir [E09] fr. [B04] patikrinkite."];
        d.formulas=["UL = E_RLC·XL/|Z|; UC = E_RLC·XC/|Z|; ULC = |UL−UC|.";"Q = sqrt(L3/C4)/R13.";"fL = f0/sqrt(1−1/(2Q²)); fC = f0·sqrt(1−1/(2Q²)).";"Ties f0: UL = UC = Q·E_RLC; ULC = 0 (teorinis idealus taškas)."];
        d.check=["Kiekvienam taikiniui bent 3 skirtingi dažniai, geriausias taškas tarp mažesnio ir didesnio f.";"ULCmin ne didesnis kaip 10 % E_RLC; mažesni žingsniai leidžia dar priartėti prie nulio.";"Atsakymų vertinimo atskaita – užfiksuotų taškų vertės."];
        d.mistakes=["Sumaišyti fL ir fC: UL ieškoma per [T31]/[T32], UC – per [T27]/[T28].";"Norite matuoti ULC per [T31]/[T28]: taip apimami ne tie kraštai; naudokite [T37]/[T38].";"Išmatuota 0,02 V, bet rašote 0: laukelyje nurašykite matuotą minimumą, o teorinį nulį aptarkite pastaboje."];
        d.questions=["Kodėl UL ir UC atskirų maksimumų dažniai skiriasi?";"Kaip gali būti UL > E_RLC, bet bendras fazorių balansas vis tiek galioti?"];
        d.source=["[S1] p. 5–6, RLC 5–7 punktai.";"[N] tikslios idealaus slopinamo kontūro maksimumų formulės ir jų aiškus atskyrimas."];
    case 11 then
        d.goal="Rasti pusės aktyviosios galios dažnius f1 ir f2, BW ir Q.";
        d.theory=["Rezistoriaus galia P = I²R13. Pusė maksimumo galios atitinka I = Imax/sqrt(2), todėl ir UR13 = UR13,max/sqrt(2). Įtampos lygis yra maždaug 0,7071 maksimumo, ne pusė įtampos.";"Originalo 8–11 punktai pusės galios ribas siūlo sieti su ritės įtampa. Šiame stende tai aiškiai pakeista: aktyviosios galios ribos nustatomos per R13 įtampą. Ritės įtampa papildomai priklauso nuo dažnio, todėl jos 0,707·UL,max kriterijus nėra tas pats.";"f1 yra žemiau srovės rezonanso, f2 – aukščiau. Juostos plotis BW = f2−f1; matavimu paremtas kokybės koeficientas Qmat = fr_mat/BW.";"Kai [E09] atliktas, slenkstis nustatomas iš ten užfiksuoto UR13 maksimumo. Laisvai peršokus į pusės galios etapo, orientyras yra nominali E_RLC ir teorinis f0; tai aiškiai pažymima ir ataskaitoje. [E09] vis tiek lieka neatliktas.";"Analitinės ribos pateiktos savikontrolei. Jos nepakeičia reikalavimo [B24] ir [B25] išsaugoti galiojantį virtualų matavimą abiejose rezonanso pusėse."];
        d.method=["1. [B13]; [T07] → [T35], [T08] → [T36]. [B09] įjunkite generatorių.";"2. Lentelėje nusirašykite UR13 slenkstį. Pasirinkite dažnį žemiau fr per [F04] ir [B16].";"3. [B15] matuokite ir keiskite f, kol UR13 priartės prie slenksčio. [B24] užfiksuokite f1.";"4. Dažnį perkelkite aukščiau fr. Kartokite keitimą ir [B15]. [B25] užfiksuokite f2.";"5. [A11.01] slenkstis; [A11.02] f1; [A11.03] f2; [A11.04] f2−f1; [A11.05] fr/BW.";"6. [B41] parašykite, kuo paremti slenkstis ir Q. [B04] tikrinkite."];
        d.formulas=["U_slenkstis = UR13,max/sqrt(2).";"f1 = (sqrt(R13²+4L3/C4)−R13)/(4·pi·L3).";"f2 = (sqrt(R13²+4L3/C4)+R13)/(4·pi·L3).";"BW_teor = R13/(2·pi·L3); Q_teor = f0/BW_teor."; "BW_mat = f2_mat−f1_mat; Q_mat = fr_mat/BW_mat."];
        d.check=["Yra abu matavimo mygtukais užfiksuoti taškai ir f1 < fr < f2.";"[B24]/[B25] leidžia iki 3 % slenksčio rodmens skirtumą; tai mokomasis paieškos kriterijus.";"Tik įrašytų teorinių f1/f2 į laukus nepakanka."];
        d.mistakes=["[B24] atmeta dažnį: tikrinkite, ar jis tikrai žemiau fr. [B25] naudojamas virš fr.";"Pakeitę dažnį nespaudėte [B15]: fiksuojamas tik naujas matavimas.";"Naudojate 0,5·URmax: pusės galios įtampos kriterijus 1/sqrt(2)."];
        d.questions=["Kodėl pusės galios įtampa nėra pusė maksimalios įtampos?";"Kaip didesnis R13 keistų rezonanso kreivės plotį?"];
        d.source=["[S1] p. 6, RLC 8–11 punktai.";"[N] metodinis pakeitimas – pusės aktyviosios galios kriterijus pagal UR13; BW ir Q papildyti."];
    case 12 then
        d.goal="Sudaryti dažninę lentelę, apibendrinti rezultatus ir išsaugoti detalų darbą.";
        d.theory=["Dažninė charakteristika parodo, kaip UR13 priklauso nuo generatoriaus dažnio. Originalaus aprašo lentelėje naudojami 0, 1, 2, ..., 10 kHz taškai; toks žingsnis gali nepagauti siauro maksimumo, todėl iš [E09] turimi papildomi paieškos taškai yra svarbūs.";"[B26] vykdo virtualių 1–10 kHz matavimų seką su tuo pačiu modeliu ir tikrintuvu. 0 Hz nėra sinusinis AC signalas: jo eilutė pažymėta kaip teorinė ribinė vertė UR13 → 0. Ji nepateikiama kaip voltmetro matavimas.";"Ataskaita atskiria priskirtus parametrus, studento tekstą, teorinę atskaitą, virtualius matavimus, užfiksuotus ekstremumus, klaidų žurnalą ir atliktus/praleistus etapus. Pavyzdžio duomenys neperrašomi kaip studento matavimai.";"[B07] generuoja savarankišką HTML dokumentą su lentelėmis ir diagramomis, CSV duomenimis ir .sod tęsimo failu. HTML galima atverti naršyklėje be interneto; naršyklės spausdinimo lange galima pasirinkti PDF. Tai nėra automatinis PDF spausdintuvo valdymas iš Scilab.";"Ataskaita nėra galutinis pažymys. Skaitinė savikontrolė ir atlikimo būsenos padeda dėstytojui, tačiau kokybinius paaiškinimus ir išvadas vertina dėstytojas."];
        d.method=["1. [B13]; [T07] → [T35], [T08] → [T36]. [B09] įjunkite generatorių.";"2. [B26] atlikite 0–10 kHz skenavimą. Patikrinkite visas 11 eilučių ir kilmės stulpelį.";"3. Meniu „Grafikai“ ([B31]) – lentelės grafikas. [B33] – visą matavimų žurnalą, [B34] – atsakymų suvestinę.";"4. [B41] aprašykite šio etapo kreivę. [B08] įrašykite bendras darbo išvadas: RC/RL fazės, fazorių sumos, fr, įtampų maksimumai, BW ir Q.";"5. [B04] patikrinkite galutinio etapo. Kai visi etapai patikrinti ir užpildyti studento duomenys bei išvados, programa pasiūlo išsaugoti galutinę ataskaitą.";"6. [B07] bet kada sugeneruoja ataskaitą: neužbaigto darbo dokumentas aiškiai pažymimas JUODRAŠTIS. Pasirinkite aplanką.";"7. Atverkite nurodytą ATASKAITA.html, patikrinkite variantą, savo tekstą ir matavimus. Pateikite dėstytojui visą sugeneruotą aplanką arba HTML su priedais."];
        d.formulas=["UR13(f) = E_RLC·R13 / sqrt(R13²+(2·pi·f·L3−1/(2·pi·f·C4))²), kai f>0.";"Riba f→0+: UR13→0.";"Δ = studento rezultatas − atskaitos rezultatas; δ = 100·Δ/atskaita, tik kai atskaita nelygi nuliui."];
        d.check=["11 skenavimo eilučių; 0 Hz eilutė aiškiai teorinė.";"Ataskaitoje yra sąrašo numeris, LD2-Vnn, priskirti parametrai, 10 aktyvių etapų būsenos ir išvados.";"Neatliktas rodmuo rašomas NEATLIKTA, ne 0 ir ne teorinis skaičius."];
        d.mistakes=["[B26] neleidžia skenuoti: [B09] įjungta ir V zondai [T07]–[T35] / [T08]–[T36] turi būti prijungti.";"Ataskaita JUODRAŠTIS: patikrinkite nepabaigtų etapų sąrašą, [F02]/[F03] ir [B08] išvadas.";"Neturite rašymo teisių: [B07] pasirinkite savo Dokumentų aplanką, ne Program Files."];
        d.questions=["Kodėl 1 kHz žingsnio lentelė gali nepataikyti į rezonansą?";"Kuri jūsų ataskaitos dalis gauta matuojant, o kuri – skaičiuojant?";"Kokie modelio ribotumai trukdo šiuos skaičius laikyti realaus modulio matavimais?"];
        d.source=["[S1] p. 6, RLC 12–13 punktai ir išvados.";"[N] ataskaita, žurnalas, individualūs variantai, savikontrolė ir duomenų kilmė."];
    else error("Netinkamas metodikos etapas.");
    end
endfunction

function d=ld2_method_data(step)
    if step==3 then step=4; end
    if step==6 then step=7; end
    if step>=1 & step<=4 then d=ld2_method_data_1_4(step);
    elseif step>=5 & step<=8 then d=ld2_method_data_5_8(step);
    elseif step>=9 & step<=12 then d=ld2_method_data_9_12(step);
    else error("Etapas turi būti nuo 1 iki 12."); end
endfunction

function lines=ld2_method_lines(step)
    global LD2;
    d=ld2_method_data(step);
    lines=[ld2_step_title(step);"VARIANTAS: "+LD2.state.student.variant_id; ...
        student_parameter_lines("LD2",LD2.cfg);" ";"TIKSLAS";d.goal;" "; ...
        "TEORIJA IR FIZIKINĖ PRASMĖ";d.theory;" ";"DARBO EIGA – KONKRETŪS NUMERIAI";d.method; ...
        " ";"FORMULĖS IR VIENETAI";d.formulas;" ";"KADA ETAPAS ATLIKTAS";d.check; ...
        " ";"DAŽNOS KLAIDOS IR TAISYMAS";d.mistakes;" "; ...
        "KLAUSIMAI SAVO PAAIŠKINIMUI [B41]";d.questions; ...
        " ";"TURINIO KILMĖ";d.source;" ";"BENDROJI ATMINTINĖ";ld2_common_theory()];
endfunction

function wh=ld2_aux_size(desired)
    wh=desired;
    try
        sc=get(0,"screensize_px");
        if size(sc,"*")==4 then wh=[min([desired(1) sc(3)-45]) min([desired(2) sc(4)-110])]; end
    catch
    end
endfunction

function ld2_open_method(step)
    // The methodology follows exactly the same 10 stages as the student UI.
    global LD2;
    if step==3 then step=4; end
    if step==6 then step=7; end
    if isfield(LD2.ui,"headless") then
        if LD2.ui.headless then return; end
    end
    f=figure("default_axes","off","dockable","off","menubar","none","toolbar","none");
    f.figure_name="LD2 metodika – "+ld2_step_title(step);
    f.axes_size=ld2_aux_size([1040 780]); f.figure_position=[15 15];
    f.infobar_visible="off";
    rows=ld2_wrap_lines(ld2_method_lines(step),110);
    uicontrol(f,"style","text","units","normalized","position",[0.025 0.93 0.95 0.045], ...
        "string",ld2_step_title(step)+"  |  "+LD2.state.student.variant_id, ...
        "fontname","DejaVu Sans","fontunits","pixels","fontsize",16,"fontweight","bold", ...
        "horizontalalignment","left","backgroundcolor",[1 1 1]);
    uicontrol(f,"style","listbox","units","normalized","position",[0.025 0.11 0.95 0.80], ...
        "string",rows,"fontname","DejaVu Sans","fontunits","pixels","fontsize",13, ...
        "backgroundcolor",[1 1 1]);
    uicontrol(f,"style","pushbutton","units","normalized","position",[0.025 0.025 0.22 0.055], ...
        "string","[H01] Ankstesnis etapas","fontname","DejaVu Sans","fontunits","pixels","fontsize",12, ...
        "callback",msprintf("ld2_open_method(%d)",ld2_visible_previous(step)));
    uicontrol(f,"style","pushbutton","units","normalized","position",[0.265 0.025 0.22 0.055], ...
        "string","[H02] Kitas etapas","fontname","DejaVu Sans","fontunits","pixels","fontsize",12, ...
        "callback",msprintf("ld2_open_method(%d)",ld2_visible_next(step)));
    uicontrol(f,"style","pushbutton","units","normalized","position",[0.505 0.025 0.23 0.055], ...
        "string","[H03] Kontaktų žinynas","fontname","DejaVu Sans","fontunits","pixels","fontsize",12, ...
        "callback","ld2_show_contact_map()");
    uicontrol(f,"style","pushbutton","units","normalized","position",[0.755 0.025 0.22 0.055], ...
        "string","[H04] Uždaryti","fontname","DejaVu Sans","fontunits","pixels","fontsize",12, ...
        "callback",msprintf("ld2_close_aux(%d)",f.figure_id));
endfunction

function ld2_edit_step_note()
    // [B41] Etapo paaiškinimas. Pastabos kaupiamos laisvame darbo tekste.
    global LD2;
    if LD2.example_active then
        ld2_show_error("Tai pavyzdžio būsena.",["[B03] grįžkite į MANO DARBAS; tada [B41] įrašykite savo paaiškinimą."]); return;
    end
    k=LD2.state.step; d=ld2_method_data(k);
    note=x_dialog([msprintf("[B41] %s – jūsų paaiškinimas ataskaitai",ld2_step_title(k));d.questions; ...
        "Aprašykite formulę, savo veiksmus ir rezultatų prasmę. OK išsaugo, Cancel nekeičia."], ...
        "");
    if size(note,"*")==0 then return; end
    text=strcat(matrix(note,-1,1)," ");
    if length(text)==0 then return; end
    LD2.state.free_note=LD2.state.free_note+msprintf("[E%02d] ",k)+text+ascii(10);
    ld2_event("B41","Atnaujintas etapo paaiškinimas.");
    ld2_set_status(msprintf("[E%02d]",k)+" paaiškinimas įrašytas. [B05] išsaugo darbą, [B07] – ataskaitą.","ok");
endfunction

function ld2_show_contact_map()
    // [B42] Kontaktų žinynas: visi [T01]–[T38] ir vidinės jungtys.
    if isfield(LD2,"ui") then
        if isfield(LD2.ui,"headless") then
            if LD2.ui.headless then return; end
        end
    end
    global LD2;
    ids=ld2_terminal_ids(); lines=emptystr(0,1);
    for k=1:size(ids,"*"); lines($+1,1)=ld2_terminal_name(ids(k)); end
    lines=[lines;" ";"VIDINĖS JUNGTYS (ne papildomi jūsų laidai):"; ...
        "[T01] ≡ [T03]; [T02] ≡ [T04] (generatorius)."; ...
        "[T09] ≡ [T11]; [T10] ≡ [T12] (R8). [T13] ≡ [T15]; [T14] ≡ [T16] (C2)."; ...
        "[T17] ≡ [T19]; [T18] ≡ [T20] (R9). [T21] ≡ [T23]; [T22] ≡ [T24] (L1)."; ...
        "[T25] ≡ [T27] ≡ [T37]; [T26] ≡ [T28] (C4)."; ...
        "[T29] ≡ [T31]; [T30] ≡ [T32] ≡ [T38] (L3). [T33] ≡ [T35]; [T34] ≡ [T36] (R13)."; ...
        "Bendras mazgas tarp C4 ir L3 atsiranda tik sujungus pagrindinį laidą [T26]–[T29]."; ...
        "[T07] = voltmetro V~; [T08] = jo COM. [T05] = ampermetro A~; [T06] = jo COM."];
    ld2_text_window("[B42] Pastovių kontaktų žinynas",lines);
endfunction

function ld2_show_button_map()
    // [B45] Valdiklių žinynas: visi [B01]–[B45], [E], [F], [A], [V], [H], [D].
    if isfield(LD2,"ui") then
        if isfield(LD2.ui,"headless") then
            if LD2.ui.headless then return; end
        end
    end
    [ids,cbs,labels,hints]=ld2_button_registry(); lines=emptystr(0,1);
    for k=1:size(ids,"*"); lines($+1,1)="["+ids(k)+"] "+labels(k)+" – "+hints(k); end
    lines=[lines;"10 etapų – pasirinkimas per Pagalba → Tęsti arba atkurti darbą → Etapai.";"[F01] – sąrašo numeris; [F02] – vardas, pavardė; [F03] – grupė; [F04] – dažnis Hz."; ...
        "[A04.01], [A07.01] ir kt. – aktyvaus matavimo etapo atsakymo laukai su vienetais."; ...
        "[V01] – dažnio slankiklis; [V02] – laisva etapų navigacija (dėstytojo režimas)."; ...
        "[H01]/[H02] – metodikos ankstesnis/kitas etapas; [H03] – kontaktai; [H04] – uždaryti pagalbos langą."; ...
        "[D01], [D02] – patvirtinimo dialogų parinktys: pirmoji saugi (atšaukti / palikti), antroji patvirtina veiksmą."; ...
        "[W01]–[W05] – pagrindinių laidų numeriai sujungimo etapuose."];
    ld2_text_window("[B45] Valdiklių žinynas",lines);
endfunction

function ld2_show_variant_bank()
    // [B43] Visi 64 variantai.
    if isfield(LD2,"ui") then
        if isfield(LD2.ui,"headless") then
            if LD2.ui.headless then return; end
        end
    end
    lines=["64 iš anksto nustatyti virtualūs variantai. Bankas LD2-64-A-2026."; ...
        "Nr | R8 Ω; fRC Hz | R9 Ω; fRL Hz | R13 Ω; L3 mH; C4 nF"; ...
        "Visiems: E_RC=E_RL=9 V RMS; C2=4,7 µF; L1=0,5 H; E_RLC=5 V RMS."];
    for n=1:64
        c=ld2_variant_config(n);
        lines($+1,1)=msprintf("%02d | %.0f; %.0f | %.0f; %.0f | %.0f; %.0f; %.0f", ...
            n,c.R8,c.F_RC,c.R9,c.F_RL,c.R13,c.L3*1e3,c.C4*1e9);
    end
    ld2_text_window("[B43] LD2 64 variantai",lines);
endfunction
