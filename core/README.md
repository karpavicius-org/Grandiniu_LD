# Bendras C++ branduolys ir automatinis vertinimas

Versija 0.3.0. Įgyvendintas **LD1–LD12** ataskaitų vertinimas — visi dalyko darbai. (dok2 „Įtampos ir srovės matavimas" lieka realiojo stendo tema.) [Ankstesnis 2026-09-13 patikros protokolas](../audits/closure-2026-09-13/README.md). Tai vidiniams priėmimo bandymams skirtas leidimas, ne išorinė aprobacija.

Studentas atveria `STENDAS.sce`, įveda vardą, grupę ir eilės numerį. Atsiskaitymo režime mygtukas **Įrašyti ir toliau** išsaugo ir klaidingus atsakymus. Pabaigoje **Išsaugoti ataskaitą** sukuria vieną HTML failą naudotojo aplanke `Grandiniu_LD_darbai`. Tą failą studentas persiunčia dėstytojui. Ataskaitą galima sukurti ir nebaigus darbo, per Pagalbą. Mokymosi režimas, pavyzdžiai ir juodraščio atvėrimas yra Pagalboje.

Dėstytojas atveria **DESTYTOJUI.sce** arba pasirenka dėstytojo punktą paleidimo lange. Pasirenka studentų darbų aplanką; C++ programa perskaito jo failus ir poaplankius. Naujas `Vertinimai-...` aplankas turi:

* `vertinimai.html`: kiekvienas darbas, balai, studento atsakymai, etalonai, klaidų komentarai;
* `suvestine.csv`: lentelė skaičiuoklei, viena eilutė kiekvienam failui;
* `vertinimai.json`: išsamūs pakartojami rezultatai, versijos ir neapdorotų failų sąrašas.

Originalūs failai nekeičiami. Po kiekvienų 25 failų įrašomas tarpinis rezultatas. Sustabdžius išsaugomi jau įvertinti darbai ir likusių failų sąrašas. Pakartotinis paleidimas sukuria naują rezultatų aplanką ir perskaičiuoja paketą iš pradžių. Tai sąmoningai paprasta atkūrimo eiga, ne slaptas ankstesnio vertinimo pakeitimas.

## Pradinė skaitinė rubrika

LD6 revizija 2, bankas `LD6-64-B-2026`, rubrika `LD6-2`: 25 vienodo svorio kriterijai – 11 atsakymų, 10 matavimo reikšmių ir keturių režimų laidų įrodymai. MNA skaičiuoja E1, nuoseklų, priešpriešinį ir lygiagretų jungimą su r1 = r2 = 10 Ω. Apkrovos įtampos ir srovės ženklas išlaikomas, šaltinio srovė teigiama atiduodant energiją. LD6 atsakymų tolerancijos: 1 % įtampai ir E1 srovei, 2 % kitoms srovėms, papildomai 1e-9 atsakymo vienetais; pasirinkimai tikslūs. Ankstesnis LD6 bankas A ir revizija 1 toliau vertinami pagal seną 14 kriterijų rubriką.

LD7, bankas `LD7-64-A-2026`, rubrika `LD7-1`: 27 vienodo svorio kriterijai – 12 atsakymų, 12 matavimo reikšmių (penkios padėtys U ir I, tuščiosios eigos U0, trumpojo jungimo Ik) ir trijų sujungimų laidų įrodymai. MNA skaičiuoja tą pačią išorinę charakteristiką U = E − r·I per visą padėčių diapazoną; tuščioji eiga modeliuojama 1 MΩ, trumpasis jungimas – 1 µΩ apkrova. LD7 atsakymų tolerancijos: 3 % vidinei varžai r (du taškai), 1 % įtampai ir E patikrai, 2 % galiai bei srovei, pasirinkimai tikslūs.

LD8, bankas `LD8-64-A-2026`, rubrika `LD8-1`: 21 vienodo svorio kriterijus – 12 atsakymų (teorinės ir eksperimentinėms varžoms trims grandinėms, šakų srovės, išvados), 6 matavimo reikšmės (U ir I kiekvienai grandinei) ir 3 sujungimų laidų įrodymai. Matavimai skaičiuojami tikru trijų varžų MNA tinklu per `bench_cpp_dc`: nuoseklioji, lygiagretė ir mišrioji topologija. Tolerancijos: 1 % teorinėms varžoms, 2 % eksperimentinėms ir srovėms, U matuojama 0,005 V; pasirinkimai tikslūs.

LD9, bankas `LD9-64-A-2026`, rubrika `LD9-1`: 28 vienodo svorio kriterijai – 12 atsakymų (teorinis f0, kokybė Q, UL−UC, įtampų trikampis, Z, cos φ, P/Q/S, išvados), 15 matavimo reikšmių (3 dažnio taškai × I, UR, UL, UC, U) ir 1 sujungimo įrodymas. Fizika — tas pats `ld::ac` nuoseklio RLC modelys ties 0,5·f0, f0 ir 2·f0. Nauji ataskaitos vienetai `mvar` ir `mVA` reaktyviajai bei pilnutinei galiai. Tolerancijos: 1 % f0 ir Q, UL−UC iki 0,02 V, 2 % trikampių dydžiams; pasirinkimai tikslūs.

LD10, bankas `LD10-64-A-2026`, rubrika `LD10-1`: 28 vienodo svorio kriterijai – 12 atsakymų (teorinis f0, srovių kokybė Q, IL−IC, srovių trikampis, laidis Y, cos φ, P/Q/S, išvados), 15 matavimo reikšmių (3 taškai × U, IR, IL, IC, I bendroji) ir 1 sujungimo įrodymas. Fizika — naujas `ld::ac` kind 4 (lygiagretis RLC per MNA): ties f0 bendroji srovė minimali ir lygi U/R. Naujas ataskaitos vienetas `mS` pilnutiniam laidžiui. Tolerancijos: 1 % f0 ir Q, IL−IC iki 0,02 mA, 2 % trikampių dydžiams; pasirinkimai tikslūs.

LD11, bankas `LD11-64-A-2026`, rubrika `LD11-1`: 20 vienodo svorio kriterijų – 12 atsakymų (cos φ0, S/Q/cos φ be Ck, teorinis Ck, S2/Q2/cos φ2/ΔS su Ck, išvados), 6 matavimo reikšmės (U, I, P abiejuose režimuose) ir 2 sujungimo įrodymai. Fizika — `ld::ac` kind 5 (R, L nuosekliai su lygiagrečiu C; C = 0 – be kondensatoriaus) analitiškai: G = R/Z², B = ωC − XL/Z²; po pilnos kompensacijos I = E·G ir cos φ = 1. Naujas ataskaitos vienetas `uF` kondensatoriui. Tolerancijos: 1 % cos φ0, 3 % Ck, 2 % galioms; pasirinkimai tikslūs.

LD12, bankas `LD12-64-A-2026`, rubrika `LD12-1`: 14 vienodo svorio kriterijų – 10 atsakymų (Uf žvaigždėje ir trikampyje, fazinės srovės, Il = √3·If, P = √3·Ul·Il ir 3·Uf·If, išvados), 2 realiai studento užfiksuotos fazinės srovės (po vieną simetrinei žvaigždei ir trikampiui) ir 2 sujungimo įrodymai. Kitų simetrinių fazių reikšmės ir trikampio linijinė srovė nebegeneruojamos kaip tariami matavimai; linijinė srovė vertinama kaip studento skaičiavimo atsakymas. Fizika — `ld::ac` kind 6: simetrinė trifazė MNA su šaltiniais Ul/√3 ∠0°/−120°/+120°; trikampio galia lygi tris kartus žvaigždės (tos pačios varžos). Tolerancijos: 1 % įtampoms, 2 % srovėms ir galioms; pasirinkimai tikslūs.

`LD1-2` (automatinis stendo paruošimas): 15 studento atsakymų kriterijų. Penki matavimai ir du sujungimai išlieka diagnostikoje, tačiau turi 0 balų svorį.

`LD1-1`: 22 vienodo svorio kriterijai — 8 skaičiavimai, 2 grandinių tipai, 5 matavimai, 5 palyginimai, 2 sujungimai. `LD2-1`: 50 kriterijų — 33 skaitiniai atsakymai, 8 baziniai matavimai, 3 sujungimai, rezonanso paieška, 3 ekstremumų tyrimai, pusės galios tyrimas ir dažninė lentelė. LD3-1 turi 15 kriterijų (Omo dėsnio darbas). Instrukcijos / įvadinis etapas taškų neduoda.

Balas: `round(100 * points / max_points) / 10`, nuo 0 iki 10. Nepateiktas arba klaidingas atsakymas gauna 0 tik už konkretų kriterijų. Palyginimo / duomenų apdorojimo užduotis vertinama pagal studento užfiksuotus matavimus; atskiras matavimo kriterijus tikrina jų atitikimą grandinei. Rezonanso paieškai būtini tinkami matavimo taškai abipus ekstremumo. Laisvos išvados išsaugomos ir parodomos, bet jų turinys automatiškai semantiškai nevertinamas ir balų neturi. Rubrikos svorius bei šią laisvo teksto politiką turi peržiūrėti dalyko vertintojas prieš oficialų naudojimą.

LD1 skaičiavimams naudojama 1 % santykinė tolerancija ir 1e-9 absoliuti atsakymo vienetais. LD2 paprastiems atsakymams — 1,5 % ir 0,005 atsakymo vienetais, kaip esamame stende; rezonanso etapų tolerancijos atskiros ir išsaugomos kiekvieno kriterijaus rezultate. Modelio skaitinis tikslumas tikrinamas atskirai nuo vertinimo tolerancijų. SI naudojamas branduolyje; ataskaitos laukų vienetai fiksuoti (`A`, `mA`, `V`, `mW`, `Ohm`, `Hz`, `ms`, `deg`, `1`, `choice`).

Visi bandymai išlieka. `mode=learning` ir `practice_used=true` gauna grįžtamąjį ryšį, tačiau neįtraukiami į atsiskaitymų suvestinę ar MOKYTOJAS pažymių žurnalą. Suvestinei `selected_for_summary=true` gauna didžiausią pažymį iš 10 gavęs tos pačios deklaruotos studento tapatybės ir darbo atsiskaitymas; lygių balų atveju — pirmas failas leksikografine tvarka. Tiksli to paties ID kopija pažymima `duplicate`. Skirtingi duomenys tuo pačiu ID sustabdo abiejų automatinį pažymį (`conflict`). Nežinoma versija / sugadintas failas gauna `review` ir paaiškinimą, be pažymio. Vietinė ataskaita nepatvirtina studento autorystės.

## Bendras šablonas kitiems darbams

Vienas ataskaitos apvalkalas ir vienas paketinis vertintuvas naudojami visiems darbams. Naujo LD modulis prideda tik: pastovų banką, užduočių laukus ir vienetus, eksperimentų duomenis, C++ vertinimo taisykles, nepriklausomus etalonus. Mokinio lango, saugojimo, HTML, aplanko importo, suvestinių ir klaidingų failų apdorojimo nereikia rašyti iš naujo. Neįgyvendintas LD aiškiai atmetamas; vien pakeisti jo numerį nepakanka.

Schema `1`: `lab_id`, `lab_revision`, `rubric_version`, `bank_id`, `variant`, `submission_id`, `student`, `mode`, `parameters`, `answers[]`, `observations[]`, `evidence`, `note`. Kiekvienas atsakymas turi stabilų `id`, **nepakeistą `raw` tekstą** ir `unit`; matavimas turi `value` arba `null`. Vienintelio inertiško duomenų bloko pradžia: `<script type="application/json" id="ld-data">`. Įterptame JSON `<` koduojamas `\u003c`; matomas tekstas HTML koduojamas. Kodo ar formulių importas nevykdomas. Importo ribos: 2 MiB failui, 32 gyliai, 256 atsakymų / matavimų laukai, 2048 taškai lentelei, 10 000 failų paketui. Simbolinės nuorodos neskaitomos.

Skaičiavimai: C++17 / Eigen, kompleksinis modifikuotų mazgų metodas, nepriklausomi įtampos ir srovės šaltiniai, R/L/C; nusistovėjusi DC ir sinusoidinė AC, RMS, `exp(+jwt)`. Eilutės ir stulpeliai masteliuojami; neapibrėžta ar blogai sąlygota grandinė grąžina klaidą. ABI: tik skaičiai ir kviečiančiosios pusės masyvai, be išimčių / STL per Scilab ribą. Vietiniai juodraščiai atskiri nuo persiunčiamų ataskaitų.

## Surinkimas ir patikra kūrėjui

Studentui ir dėstytojui reikia Scilab 2026.1.0 ir OS atitinkančio paketo su `bin/ldcore.dll`, `bin/ldcore.so` arba `bin/ldcore.dylib`. Kompiliatoriaus, Python, serverio ar mokamos API jų kompiuteriuose nereikia. CMake naudoja tik užfiksuotas priklausomybes su SHA256; jų šaltinių ir licencijų pranešimai pateikti `third_party`.

```sh
python tools/fetch_core_deps.py /tmp/ld-deps
cmake -S core -B build -DLD_DEPS=/tmp/ld-deps -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release --parallel 2
ctest --test-dir build -C Release --output-on-failure
cmake --install build --config Release --prefix studentui
python tools/test_automatic_reports.py --scilab /path/to/scilab --runtime studentui
```

Komandinė dėstytojo versija: `ldcheck STUDENTU_APLANKAS NAUJAS_REZULTATU_APLANKAS`. Windows naudoja Unicode `wmain`, Scilab siunčia UTF-8 baitus tiesiai į C++ ir nekviečia komandinio interpretatoriaus. GitHub Actions surenka ir tikrina Windows Server 2022 / MSVC bei Ubuntu 22.04. CI neatstoja Windows 10/11 GUI / DPI patikros su tikrais naudotojais.

Atviri viso projekto priėmimo klausimai: 6 likusios metodikos ir jų testai, trifazio darbo pilna studento eiga, Windows 10/11 naudotojo sąsajos / DPI patikra, dėstytojo rankinių pažymio pataisų istorija, projekto licencijos pasirinkimas ir dalykinė / išorinė aprobacija. Jie nepristatomi kaip jau atlikti.
