# Galutinis kryžminis auditas — studentas → dėstytojas → CI → paketas

Data: 2026-09-28  
Audituotas `main` prieš šį checkpointą: `fee3018b122fe6d47ebcba035bcb780157062d33`

## 1. Kontrolinė išvada

Kryžminė patikra atlikta ne remiantis vien ankstesniais audito tekstais, bet dar kartą lyginant:

- dabartinius LD1–LD12 Scilab šaltinius;
- `bench_report.sci`, `bench_session.sci`, `bench_common.sci`;
- C++ `grader.cpp`, `batch.cpp`, `mokytojas.cpp`, `model.cpp`;
- realius `tools/test_ld*.sce/.py` testus;
- `test_student_delivery.sce/.py`;
- `AUTOMATINIS.sce`, `HEADLESS.sce`, `GUI_PATIKRA.sce`;
- `native.yml`, `macos.yml`;
- `package_native.py`, `package_student.py`, `check_student_package.py`;
- repo `dist/` istoriją;
- oficialų KVK „Grandinių teorija“ (TF-EA-2025-07) dalyko aprašą Google Drive.

Bendras rezultatas:

> Skaitinis/fizikinis branduolys ir C++ graderis yra stipri sistemos dalis. Didžiausi neuždaryti klausimai yra formalus assessment srautas, pateikimo vientisumas, dėstytojo agregavimas, LD numeracijos atsekamumas, LD12 matavimo rubrika ir release/paketavimo grandinė.

Funkcinis laboratorijų kodas šio audito metu nekeistas.

---

## 2. Patvirtinta, kad auditas nepakeitė produkto kodo

Palyginta:
- bazinis audito pradžios commit: `a3f59a87d8f92ee2d281bb87db93eff0d205c0fe`;
- dabartinė audito šaka prieš šį checkpointą.

Visi pakeisti failai yra tik:

`audits/full-lab-validation-2026-09-28/*`

Nė vienas:
- `studentui/*`;
- `core/*`;
- `.github/workflows/*`;
- `tools/*`;
- `dist/*`

funkcinis failas audito metu nepakeistas.

Tai patvirtina, kad visi rasti defektai yra esamos sistemos būklė, o ne audito įvestos regresijos.

---

## 3. Oficialus 13 LD žemėlapis dar kartą patvirtintas tiesiai iš KVK dokumento

Oficialus dokumentas nurodo:

1. Elektrinių grandinių jungimas  
2. Įtampos ir srovės matavimas  
3. Omo dėsnio veikimas realioje elektros grandinėje  
4. Tiesinių rezistorių tyrimas  
5. Nuosekliai, lygiagrečiai, mišriai jungiamų grandinės elementų tyrimas  
6. Įtampos daliklio tyrimas  
7. Nuoseklaus ir lygiagretaus šaltinių jungimo tyrimas  
8. Įtampos, srovės ir galios suderinamumo tyrimas  
9. Paprastųjų kintamosios srovės grandinių tyrimas  
10. Nuosekliai sujungtos R,L,C vienfazės grandinės tyrimas. Įtampų rezonansas  
11. Lygiagrečiai sujungtos R,L,C vienfazės grandinės tyrimas. Srovių rezonansas  
12. Aktyviosios, reaktyviosios, pilnutinės galios tyrimas  
13. Trikampiu ir žvaigžde jungiamų imtuvų tyrimas.

Repo virtualių ID atitiktis patvirtinta:

- repo LD1 → oficialus LD1;
- oficialus LD2 → atskiras virtualus darbas neįgyvendintas, lieka fizinis;
- repo LD3 → oficialus LD3;
- repo LD4 → oficialus LD4;
- repo LD8 → oficialus LD5;
- repo LD5 → oficialus LD6;
- repo LD6 → oficialus LD7;
- repo LD7 → oficialus LD8;
- repo LD2 → dengia oficialaus LD9 ir dalį LD10 tematikos;
- repo LD9 → oficialus LD10;
- repo LD10 → oficialus LD11;
- repo LD11 → oficialus LD12;
- repo LD12 → oficialus LD13.

Todėl techninis `lab_id=LDx` negali būti tiesiogiai laikomas oficialiu kurso LD numeriu.

---

## 4. Assessment/autosave matrica patvirtinta tiesiai iš dabartinių šaltinių

Pilnai prijungtą produkto kelią turi:

### LD1
- assessment normaliai paleidžiamas;
- autosave normaliai įjungtas;
- režimas pasiekiamas UI;
- juodraščio atkūrimas pasiekiamas;
- klaidingas raw atsakymas gali būti perduotas graderiui.

Tačiau numatytasis `guided=true` jau pirmajame etape pažymi `guided_used`, todėl normalus UI lieka LD1-2 (15 studento atsakymų kriterijų). 22 kriterijų LD1-1 yra legacy/specialiai konstruojama rubrika, ne normaliai pasiekiamas kelias po guided starto.

### LD2
- assessment normaliai paleidžiamas;
- autosave normaliai įjungtas;
- režimas pasiekiamas;
- juodraščio atkūrimas pasiekiamas;
- raw atsakymo teisingumas assessment metu neatskleidžiamas.

Tačiau:
- restartas numeta assessment;
- varianto pakeitimas numeta assessment;
- assessment etapai nefiksuojami `completed/skipped`;
- galima tyliai pereiti per visiškai tuščią etapą.

### LD8
- assessment normaliai paleidžiamas;
- autosave normaliai įjungtas;
- režimas pasiekiamas;
- juodraščio atkūrimas pasiekiamas;
- tuščias atsakymas neleidžiamas;
- neteisingas netuščias raw atsakymas perduodamas dėstytojui.

Tai geriausias dabartinis assessment architektūros etalonas.

### LD3–LD7 ir LD9–LD12
Patvirtinta:
- normalus startas neinicijuoja assessment;
- realus UI neturi režimo pasirinkimo;
- normalus startas neįjungia autosave;
- UI neturi automatinio juodraščio atkūrimo;
- `student_primary()` assessment būsenos nenaudoja;
- studentas turi vietoje pataisyti atsakymą iki teisingo.

Todėl vien `assessment=true` pridėjimas šių darbų nepataisytų.

---

## 5. Pavyzdžio/practice kontrolė

Patvirtinta:

- LD1 ir LD2 assessment metu pavyzdys blokuojamas / mokymosi režimas pažymimas.
- LD4–LD12 pavyzdžio callbackai nustato `practice_used=true`.
- LD3 pavyzdys rodo teisingą būseną/atsakymus, bet `practice_used=true` nenustato.

Dabartiniu LD3 tai dar nesukuria įskaitinio apėjimo, nes visas normalus LD3 ir taip learning. Tačiau assessment taisymas ir LD3 practice žyma turi būti projektuojami kartu.

`practice_used` restarto semantika nėra vienoda: LD8 `ld8_init_state()` aiškiai nustato `practice_used=%f`, todėl „Iš naujo“ ją nunulina; LD4–LD7 ir LD9–LD12 `init_state()` šio lauko neperrašo, todėl jau egzistuojantis `practice_used=true` Scilab struktūroje po restarto išlieka. Būsimoje vieningoje assessment būsenoje šią politiką reikia suvienodinti sąmoningai.

---

## 6. Skaitinis saugumas patvirtintas

Aktyviame runtime studento skaitinė įvestis nevykdoma kaip kodas.

Repo paieška `evstr` parodė:
- aktyviuose studento atsakymų parseriuose `evstr` nebenaudojamas;
- vienintelis aktyvus `evstr` likęs `HEADLESS.sce` testui, kuris parsina source-controlled `REGISTRY-CODES` intervalo numerius.

Studento skaičių parseriai riboja simbolius ir naudoja `strtod`.

C++ importas papildomai:
- nevykdo HTML/Scilab;
- riboja failą iki 2 MiB;
- tikrina tipą;
- atmeta symlink;
- tikrina schemą, ID, vienetus ir variantą.

Ankstesnis įtarimas, kad `mokytojas` vietinis kelias galėtų įvertinti symlink, kryžmiškai atmestas:
- `scan_local()` pats symlink netikrina;
- tačiau galutinis bendras `read_report()` turi `!is_symlink(path)` ir tokį failą atmeta.

---

## 7. Fizikos/modelio sluoksnis

Nepatvirtinta jokių naujų esminių fizikinių regresijų.

Ankstesnė nepriklausoma patikra lieka galiojanti, nes funkciniai šaltiniai audito metu nekeisti:

- LD2 RC/RL/RLC visų 64 variantų kompleksinės formulės sutapo su C++ modeliu iki ~5.7e-14 abs. paklaidos;
- LD1 baziniai serijos/lygiagretūs/KCL santykiai tvarkingi;
- LD3 Omo dėsnis tvarkingas;
- LD4 realios R reikšmės ±5 %;
- LD5 daliklis monotoniškas ir matematiškai nuoseklus;
- LD6 šaltinių kombinacijos fiziškai nuoseklios;
- LD7 maksimalios galios režimas R=r;
- LD8 serijos/lygiagretaus/mišraus jungimo dėsniai tvarkingi;
- LD9 rezonanso AC modelis nuoseklus;
- LD10 lygiagretus rezonansas nuoseklus;
- LD11 kompensacija išlaiko P ir mažina I/S;
- LD12 idealios simetrinės trifazės formulės nuoseklios.

---

## 8. LD12 kritinis rubrikos/evidence neatitikimas patvirtintas

Realiame studento UI studentas atlieka tik:
- vieną žvaigždės fazės matavimą;
- vieną trikampio fazės matavimą.

`bench_report_data("LD12")` iš jų sukuria:
- tris žvaigždės fazių observations, kopijuodamas vieną matavimą;
- tris trikampio fazių observations, kopijuodamas vieną matavimą;
- `ild` tiesiai iš `ld12_line_current()`, t. y. tiesiai iš modelio.

C++ graderis šiuos 7 laukus vertina kaip 7 matavimo kriterijus.

Taigi 19 taškų rubrikos 7 „matavimo“ balai neatitinka 7 nepriklausomų studento matavimo veiksmų.

Tai patvirtintas metodinis/grading evidence defektas.

---

## 9. 769 automatinės ataskaitos — ką šis skaičius realiai reiškia

`test_automatic_reports.py` realiai patikrina:
- 64 variantus kiekvienam LD1–LD12;
- papildomą klaidingą/trūkstamą LD2 ataskaitą;
- iš viso 769 reportus;
- jų C++ graderio taškų skaičiavimą.

Tačiau testas **neassertina**, kad visi tie reportai:
- `mode=assessment`;
- `selected_for_summary=true`.

Todėl:

> „769 graded reports“ reiškia, kad graderis geba juos techniškai įvertinti taškais. Tai nereiškia „769 formaliai įskaitinių assessment pateikimų“.

Tai ypač svarbu LD3–LD7 ir LD9–LD12.

---

## 10. Student delivery testo aprėpties korekcija

Rastas konkretus CI metaduomenų neatitikimas.

`tools/test_student_delivery.sce` turi:

`for lab=1:8`

ir verdict tekstas teisingai sako:
„eight fixed windows“.

Tačiau `tools/test_student_delivery.py` acceptance.json rašo:

`labs=list(range(1,13))`.

Todėl acceptance JSON klaidingai deklaruoja LD1–LD12 aprėptį.

Teisinga interpretacija:

- bendras delivery/fixed-window launch testas realiai paleidžia LD1–LD8;
- LD9–LD12 turi atskirus `test_ld9.py`–`test_ld12.py` GUI/geometrijos/graderio testus;
- mažų ekranų 1024×768 ir 900×600 scrollable mechanizmas testuojamas kaip bendras studento window mechanizmas, ne atskirai kiekvienam LD9–LD12.

---

## 11. Targeted testų skaičių korekcija

Scilab verdict tekstai kai kur pasenę. Faktinis Python `len(expected)` / case konstrukcija duoda:

- LD8: 146 — verdict tekstas 146, sutampa;
- LD9: 146 — Scilab verdict tekstas vis dar rašo 144;
- LD10: 146 — Scilab verdict tekstas vis dar rašo 144;
- LD11: 146 — Scilab verdict tekstas vis dar rašo 148;
- LD12: 122 — Scilab verdict tekstas vis dar rašo 140.

Tai nekeičia testų rezultatų, tačiau rankiniu būdu įrašyti PASS statistikos tekstai negali būti laikomi autoritetingais test case skaitikliais.

Audito LD10/LD11/LD12 dokumentuose šie skaičiai pataisyti.

---

## 12. Dėstytojo pusės du keliai tikrai nėra semantiškai ekvivalentiški

### DESTYTOJUI.sce / ldcheck

Patvirtinta:
- vienodas submission_id + identiškas report → duplicate;
- vienodas submission_id + skirtingas report → conflict;
- conflict panaikina automatinį balą;
- geriausias valid assessment parenkamas pagal visą student objektą + lab_id;
- HTML studento tekstas escapinamas;
- atšauktas batch turi complete/cancelled būseną JSON.

### mokytojas / mokytojas --ui

Patvirtinta:
- dedup pagal viso failo SHA-256;
- vienodas submission_id su pakeistu turiniu konflikto nesukelia;
- studentas grupuojamas vardas + grupė + lab_id;
- `ZURNALAS.csv` lentelė naršyklėje kuriama per neescapintą `innerHTML`;
- geriausias balas paliekamas žurnale;
- nėra rankinės pataisos istorijos.

Todėl prieš gamybinį naudojimą reikia vienos kanoninės agregavimo semantikos.

---

## 13. mokytojas Google Drive kelio kritinis defektas patvirtintas

Dabartinis `mokytojas_run()`:

1. sukuria temp katalogą;
2. parsisiunčia Drive HTML į temp;
3. išsaugo jų kelią `Source.path`;
4. ištrina visą temp katalogą;
5. tik tada kviečia `process(files,...)`.

`Source` nesaugo failo baitų — tik kelią ir display vardą.

Todėl po `remove_all(tmp)`:
- `hash_file()` failo neberanda;
- ataskaita neįvertinama.

`process()` hash failure atveju didina failed, bet pabaigoje vis tiek gali grąžinti 0, todėl UI gali parodyti sėkmingo užbaigimo būseną.

Esami testai tikrina Drive BE API rakto klaidos kelią, ne sėkmingą realų download→grade kelią.

Tai patvirtintas kritinis defektas.

---

## 14. Ataskaitos vientisumas: formalus assessment nėra kriptografiškai patikimas

HTML ataskaita nėra pasirašyta.

Studento valdomame JSON yra:
- `mode`;
- `practice_used`;
- `submission_id`;
- vardas/grupė/numeris;
- raw atsakymai;
- measurements/evidence.

Graderis puikiai apsaugo nuo:
- neegzistuojančio varianto;
- pakeistų variantų parametrų;
- neleistinų ID/vienetų;
- netinkamos schemos.

Tačiau jei studentas pakeičia leidžiamą raw atsakymą, mode, practice ar naują submission_id ir dėstytojas gauna tik pakeistą kopiją, sistema neturi serverio pusės originalo ar parašo, su kuriuo galėtų įrodyti pakeitimą.

Tai ne C++ parserio trūkumas — tai pateikimo architektūros ribojimas.

---

## 15. Studentams platinami etalonai patvirtinti

`package_native.py` ir `package_student.py` į studento paketą įtraukia:
- `ldcore`;
- `ldcheck`;
- `mokytojas`.

`STENDAS.sce` studento meniu rodo:
„Dėstytojui · automatinis ataskaitų vertinimas“.

Studento pakete taip pat yra Scilab šaltinių su `*_expected_answers`.

Todėl studentas lokaliai gali prieiti prie vertinimo etalonų.

Tai reiškia, kad vietinis offline studento paketas negali būti laikomas „slaptų atsakymų“ pagrindu. Formalų vientisumą reikia spręsti pateikimo/assessment architektūra, ne obfuskavimu.

---

## 16. Release/paketavimo grandinės kryžminė išvada

### Trackinti dist paketai pasenę

Visi:
- `Grandiniu_LD-studentui.zip`;
- `Grandiniu_LD-macOS-arm64.zip`;
- `Grandiniu_LD-macOS-x86_64.zip`

paskutinį kartą atnaujinti 2026-09-23.

LD8–LD12 į repo įtraukti 2026-09-24–25.

Todėl README tiesioginės dist nuorodos rodo į release, kuris chronologiškai yra senesnis už LD8–LD12.

### PATIKRA.json pasenęs

Jame:
- 97 source SHA;
- yra LD1–LD7;
- nėra nė vieno LD8–LD12 runtime failo.

### VARIANTAI.csv

LD9–LD12 `VARIANTAI.csv`:
- dabartiniame Git tree nėra;
- juos generuoja tik `HEADLESS.sce`;
- dabartiniai Actions workflow `HEADLESS.sce` nevykdo.

### package_native

Pakuoja visus workspace esančius failus.
Todėl sugeneruotų CSV buvimas priklauso nuo ankstesnio side-effect.

### package_student

Naudoja `git ls-files`, todėl netrackintų LD9–LD12 CSV neįtrauks net jei jie workspace sugeneruoti.

### check_student_package

Reikalauja LD9–LD12 CSV ir reikalauja runtime == pasenusio PATIKRA manifesto.
Todėl dabartiniame švariame main šis checker negali būti sėkmingas.

### Actions

Dabartiniai workflow:
- nekuria bendro `Grandiniu_LD-studentui.zip`;
- nepaleidžia `check_student_package.py`.

Todėl žalias CI nėra įrodymas, kad README nurodytas bendras ZIP yra dabartinis.

---

## 17. CI dokumentacinių commitų dubliavimas

Audito pradžioje kiekvienas docs commit paleido:
- Windows/Linux acceptance;
- macOS acceptance,

nes workflow yra `on: push`.

Funkcinis kodas tuo metu nesikeitė, todėl keli run'ai buvo dubliuoti.

Nuo `CI_AND_PACKAGE.md` checkpointo audito docs commitai daromi su `[skip ci]`.

Patikrinta:
- naujam `2159f2ec...` nebuvo paleisti Windows/Linux ir macOS acceptance;
- liko tik atskiras platforminis „Push on main“ check.

Tai atitinka 0 € papildomų resursų ir nedubliuoto CI politiką.

---

## 18. Viešos dokumentacijos neatitikimai

Patvirtinta, kad dalis aktyvios dokumentacijos yra pasenusi:

### core/README.md
Sako:
- „LD1–LD12 ... visi dalyko darbai“;
- bendrą „Atsiskaitymo režime Įrašyti ir toliau“ semantiką.

Realybė:
- oficialus LD2 lieka fizinis;
- repo LD2 nėra oficialus LD2;
- pilnas assessment raw-answer kelias yra tik LD1/LD2/LD8.

### root README.md
Bendrai teigia:
„atsiskaitymo režime Įrašyti ir toliau išsaugo tikrus atsakymus“,
nenurodydamas, kad daugumos LD realus primary vis dar yra learning/TIKRINTI.

Taip pat:
- Actions nuorodos vis dar rodo seną `Karpavicius82/Grandiniu_LD` savininką;
- „Naujausia keturių platformų patikra“ nurodo 2026-09-23 LD1–LD7 etapą;
- skiltis „Plėtra iki 13 LD“ jau neatspindi dabartinės LD1–LD12 būklės.

Šių failų audito metu netaisome; tik fiksuojame.

---

## 19. Paleidimo kelias

Šakniniai:
- `PALEISTI.bat`;
- `PALEISTI.sh`;
- `PALEISTI.command`;
- `STENDAS.sce`

tik deleguoja į `studentui/`, todėl dviejų skirtingų studento runtime logikų nėra.

Tačiau:
- root `STENDAS.sce` komentaras vis dar sako „Shared student launch for LD1 and LD2“;
- dokumentacija reikalauja Scilab 2026.1.0;
- Linux/macOS launcher priima bet kurį randamą `scilab`;
- Windows launcher ieško ir `scilab-*` be realaus versijos patikrinimo;
- Windows iš anksto tikrina `ldcore.dll`, Linux/macOS leidžia klaidai iškilti vėliau per `bench_core_require()`.

Tai nėra branduolio klaida, bet gamybiniam palaikymui versijos/diagnostikos politika nevienoda.

---

## 20. UI ir metodikos defektai, kurių kryžminė patikra nepaneigė

Lieka patvirtinti:

- LD5 mA formulės paaiškinimo spraga;
- LD6 keli mA formulės paaiškinimai be ×1000;
- LD7 Pmax/Ik vienetų formuluotės;
- LD8 šakų srovių mA formulės formuluotė;
- LD12 If mA formulių ×1000 trūkumas;
- LD9–LD12 literalūs `<br>` komponentų kortelėse;
- LD10 starto „nuosekli RLC“ copy/paste;
- LD10 „voltmetro taikinys“, nors naudojamas ampermetras;
- LD11 starto „nuosekli RLC“;
- LD11 „mikromadais“ vietoje mikrofaradais;
- LD12 starto „nuosekli RLC“;
- LD12 literalus `R = %g Ω`;
- LD12 klaidingas fazės mygtukų intervalas B13–B15 vietoje B12–B14;
- LD12 voltmetro tooltipas vadina jį vatmetru;
- LD9–LD12 README nurodomi CSV, kurių Git tree nėra.

---

## 21. Kas kryžmiškai paneigta / patikslinta

Kad galutinė analizė nebūtų vien tik problemų sąrašas:

### Paneigta
- Studentų atsakymų vykdymas per `evstr` — aktyviame UI to nebėra.
- Symlink failo automatinis įvertinimas `mokytojas` — galutinis `read_report()` symlink atmeta.
- Funkcinio kodo pakeitimas audito metu — neįvyko.

### Patikslinta
- „Student delivery LD1–LD12“ → realiai bendras delivery loop LD1–LD8; LD9–LD12 turi atskirus targeted testus.
- LD1 „22 manual“ → 22 kriterijų kelias nėra normaliai pasiekiamas po numatyto guided starto.
- LD9–LD12 PASS tekstuose kai kurie case skaičiai pasenę; faktiniai skaičiai nurodyti šiame protokole.
- „769 reportai“ → 769 techniškai įvertinami reportai, ne 769 assessment-eligible pateikimai.

---

## 22. Galutinė prioritetų eilė prieš įgyvendinimą

### P0 — būtina išspręsti prieš formalų naudojimą

1. Vieninga assessment/learning būsenos mašina LD1–LD12.
2. LD3–LD7/LD9–LD12 raw-answer assessment semantika.
3. Pateikimo vientisumo/autorystės modelis.
4. Studentų ir dėstytojo etalonų/paketų atskyrimo politika.
5. LD12 realių matavimų ir rubrikos sutartis.
6. `mokytojas` Drive temp katalogo klaida.
7. Viena kanoninė submission conflict / student identity semantika.
8. Oficialus kurso LD numeris atskirai nuo virtualaus techninio ID.
9. Dabartinių studento release paketų perstatymas ir deterministinė release grandinė.

### P1 — aukštas prioritetas

10. Autosave/restore visiems darbams.
11. Practice/pavyzdžio/restart politika.
12. `mokytojas --ui` XSS.
13. Bandymų skaičiaus ir termino politika.
14. Rankinio dėstytojo override + audit trail.
15. Aktyvių README/core README teiginių suvienodinimas su realybe.

### P2 — UX / dokumentacija / priežiūra

16. Vienetų tekstai.
17. Copy/paste tekstai.
18. literalūs `<br>`.
19. LD12 B12–B14 / tooltip / %g klaidos.
20. Scilab versijos diagnostika launcheriuose.
21. CI PASS tekstų ir acceptance metadata skaitiklių sutvarkymas.
22. CI dependency install / artefaktų retention / dubliavimo optimizavimas.

---

## 23. Galutinė būsena

Po kryžminio audito nėra pagrindo teigti, kad skaitinis branduolys yra „sugedęs“. Priešingai — didžioji dalis fizikos, variantų bankų ir C++ graderio validacijos yra gera.

Tačiau taip pat nėra pagrindo dabartinės sistemos dar vadinti užbaigta formalaus pažymio platforma.

Tiksliausias dabartinės būklės apibūdinimas:

> **techniškai stipri virtualių laboratorijų ir automatinio formuojamojo vertinimo sistema, kurios formaliojo assessment, pateikimo vientisumo, dėstytojo žurnalo ir release sluoksniai dar turi aiškiai apibrėžtų neuždarytų P0/P1 darbų.**

Šis dokumentas užbaigia analizės/kryžminio audito etapą. Jame nesiūloma ir nevykdoma funkcinio kodo implementacija.


---

## 24. Learning ataskaitos siuntimo UX

Kryžmiškai patikrintas paskutinis studento veiksmas po eksporto.

`bench_export_current(lab)` nepriklausomai nuo darbo režimo rodo:

- „Ataskaita išsaugota“;
- „Persiųskite šį HTML failą dėstytojui.“

Bendras `bench_report_saved()` langas taip pat sako:

„Persiųskite dėstytojui vieną HTML failą.“

Tačiau LD3–LD7 ir LD9–LD12 normaliame produkto kelyje reportas yra `mode="learning"` ir nebus `selected_for_summary`.

Todėl sistema pati ragina studentą pateikti failą, kurį dėstytojo agregavimo logika laiko neįskaitiniu.

Pats eksportuotas HTML režimą rodo teisingai („Mokymasis“), todėl duomenų sluoksnis nėra klaidingas; klaida yra paskutinio studento UI pranešimo / workflow semantikoje.

Tai laikytina aukšto prioriteto assessment UX problema ir turi būti taisoma kartu su vieninga LD3–LD7/LD9–LD12 assessment būsenos mašina.

## 25. CI bazinės būsenos patikslinimas

Keturių platformų funkcinis įrodymas tiesiogiai patvirtintas baziniam funkciniam SHA:

`a3f59a87d8f92ee2d281bb87db93eff0d205c0fe`

- Windows/Linux acceptance run `36162442906`: PASS;
- macOS Intel/Apple Silicon run `36162442730`: PASS.

Nuo šio SHA iki dabartinio audito `main` funkciniai `studentui/`, `core/`, `tools/`, `.github/workflows/` ir `dist/` failai audito metu nekeisti; pridėti/keisti tik audito dokumentai.

Todėl tikslus teiginys yra ne „dabartiniam main paleistas keturių platformų CI“, o:

> funkcionalus runtime yra bitų prasme tas pats kaip keturių platformų PASS baseline; dabartiniam audito HEAD pilnas acceptance sąmoningai nebekartojamas.


---

## 26. Practice žymos restarto korekcija

Pakartotinai patikrinta Scilab struktūros semantika ir konkretūs `init_state()/restart()` keliai.

Teisinga dabartinė būsena:

- LD8: `ld8_init_state()` aiškiai nustato `practice_used=%f`; todėl `ld8_restart()` practice žymą nunulina.
- LD4–LD7 ir LD9–LD12: jų `init_state()` `practice_used` lauko išvis neperrašo. Kadangi restartas nekeičia viso global struct nauju objektu, jau egzistuojantis `practice_used=true` lieka struktūroje.
- LD3: pavyzdžio callback pats `practice_used` nenustato, todėl pagrindinė LD3 problema išlieka kita — pavyzdžio naudojimas nepažymimas.

Taigi ankstesnis bendras teiginys, kad LD9–LD12 restartas nunulina practice, buvo neteisingas ir šiame protokole pataisytas.


---

## 27. LD2 ir LD8 practice žymos apėjimas

Kryžmiškai patikrinti trys realiai assessment paleidžiami darbai.

### LD1

- Pavyzdys assessment metu blokuojamas.
- Perėjus į Mokymąsi `practice_used=true`.
- `ld1_restart()` šio lauko neperrašo.
- Grįžus į assessment practice žyma išlieka.

LD1 ši konkreti restart apėjimo seka neveikia.

### LD2

- Pavyzdys assessment metu blokuojamas.
- Perėjus į Mokymąsi nustatomas `state.practice_used=true`.
- Pavyzdį galima peržiūrėti.
- `ld2_restart()` visą state pakeičia nauju `ld2_initial_state()`, kuriame `practice_used` nėra.
- Vėl pasirinkus assessment, reportas turi assessment režimą ir practice laikomas false.

Tai realus to paties varianto mokymosi/pavyzdžio atsekamumo apėjimas.

### LD8

- Pavyzdys pasiekiamas tiesiai assessment metu.
- Pavyzdys nustato `practice_used=true`.
- `ld8_restart()` kviečia init, kuris nustato `assessment=true` ir `practice_used=false`.
- Tas pats variantas vėl tampa formaliai įskaitomas.

Tai taip pat realus apėjimas.

Išvada: iš trijų šiandien veikiančių assessment darbų du (LD2 ir LD8) leidžia UI veiksmais nuvalyti practice žymą nekeičiant ataskaitos failo ranka.


---

## 28. Practice žyma yra rollbackable per juodraštį

Papildomai kryžmiškai patikrintas bendras snapshot mechanizmas.

### LD2

- Snapshot saugo visą `LD2.state`.
- Ankstyvas assessment snapshot turi `assessment=true` ir neturi `practice_used=true`.
- Po mokymosi/pavyzdžio `practice_used=true`.
- `bench_restore_snapshot()` LD2 atveju visą state pakeičia senu `session.state`.

Todėl senas juodraštis gali vienu veiksmu grąžinti assessment būseną be practice žymos.

### LD8

- Snapshot saugo `assessment=true` ir `practice_used=false`.
- Po pavyzdžio practice tampa true.
- Restore perrašo snapshot laukus ir grąžina false.

Todėl senas juodraštis taip pat nuvalo practice žymą.

### LD1

LD1 restore elgiasi kitaip: jis perrašo tik snapshot esančius laukus ir nepašalina papildomai atsiradusio `practice_used=true`. Ankstyvame LD1 snapshot šio lauko nėra, todėl ši konkreti rollback seka practice žymos nenuvalo.

### Architektūrinė išvada

`practice_used` yra vietinės studento būsenos dalis. LD2/LD8 atveju ją galima grąžinti į ankstesnę reikšmę per normalų juodraščio atkūrimą.

Todėl formaliojo assessment vientisumui practice / pagalbos naudojimo faktas negali būti saugomas vien rollbackable studento snapshot būsenoje. Tai sutampa su platesne audito išvada, kad vietinis offline failas negali pats įrodyti sąžiningos assessment istorijos.


---

## 29. Windows `mokytojas` Unicode path rizika nėra padengta testu

Kryžmiškai palyginti du C++ dėstytojo entrypointai.

### ldcheck

Windows naudoja `wmain` ir tiesiai perduoda:

`fs::path(argv[1])`

Todėl komandinės eilutės katalogo kelias išlieka native UTF-16.

### mokytojas

Windows taip pat naudoja `wmain`, tačiau:
1. `wchar_t*` argumentą paverčia į UTF-8 `std::string`;
2. `mokytojas_run()` naudoja `fs::path(arg)`.

Naršyklės UI taip pat generuoja UTF-8 `std::string arg` ir naudoja tą patį kodą.

Dabartinis `mokytojas` testas turi lietuviškus studentų vardus, bet ne Unicode katalogo pavadinimą. Repo loguose esantis `utf8_paths=true` yra `ldcheck/test_grading` testo rezultatas ir neįrodo šio `mokytojas` kelio.

Todėl tai žymima kaip **neuždaryta Windows platformos rizika**, o ne kaip empiriškai patvirtintas defektas. Reikalingas atskiras Windows testas su non-ASCII lokaliu darbų aplanko keliu ir tas pats testas per `mokytojas --ui`.


---

## 30. `mokytojas` SHA dedup neversijuoja graderio

Kryžmiškai patikrinta persistent `IVERTINIMAI.csv` sutartis.

Dabartinis `mokytojas` laiko failą „jau įvertintu“, jei jo SHA-256 jau yra istorijoje. Tačiau istorijoje nėra:
- graderio/core versijos;
- rubric version;
- lab revision;
- build/commit SHA.

Taigi studento failo SHA identifikuoja tik **įvestį**, bet ne vertinimo funkciją.

Jei graderis vėliau pataisomas, identiškas studento HTML tame pačiame `IVERTINIMAI.csv` kataloge automatiškai neperskaičiuojamas. Senas pažymys lieka žurnalo šaltiniu.

Tai taip pat reiškia, kad dabartinio `ZURNALAS.csv` negalima visiškai rekonstruoti kaip „studento failas + konkreti graderio versija“, nes antroji dedamoji istorijoje neišsaugota.

`ldcheck` šios konkrečios problemos neturi: naujas batch output iš naujo vertina failus dabartiniu graderiu ir `vertinimai.json` verdictuose turi versijų laukus.

Prieš gamybinį naudojimą persistent mokytojo istorijoje turi būti aiškus vertinimo versijos identifikatorius ir apibrėžta regrade/migration politika.


---

## 31. Persistent žurnalas neturi kurso/semestro ribos

`mokytojas` istorija yra ilgalaikė, tačiau jos loginis scope neįrašytas į duomenis.

CSV eilutėje nėra:
- course_id;
- akademinių metų;
- semestro;
- kohortos ID.

`ZURNALAS.csv` visą `IVERTINIMAI.csv` istoriją grupuoja pagal:

`vardas + grupė + lab_id`.

Todėl to paties darbo katalogo pakartotinis naudojimas kitame semestre gali sujungti istoriškai skirtingus bandymus ir palikti ankstesnį aukščiausią balą.

Tai nėra `ldcheck` batch problema, nes jo output yra naujas atskiras katalogas kiekvienam vertinimui. Tai būdinga būtent persistent `mokytojas` istorijos modeliui.

Minimalus dabartinės sistemos naudojimo apribojimas būtų „atskiras darbo katalogas kiekvienai kurso kohortai / semestrui“, tačiau gamybiniame modelyje šis scope turi būti duomenų dalis, o ne vien dėstytojo disciplina.


---

## 32. Persistent CSV parseris neapdoroja embedded newline

Kryžmiškai patikrinta studento tapatybės validacija ir `mokytojas` istorijos parseris.

Graderis priima studento vardą/grupę su vidiniu `\n`, nes `text()` draudžia tik:
- ne-string;
- per ilgą tekstą;
- NUL.

`mokytojas::csv()` tokį lauką teisingai cituoja.

Tačiau `read_csv_rows()` pirmiausia skelia visą failą pagal newline ir tik tada interpretuoja kabutes. Tai nesuderinama su CSV laukais, kuriuose newline teisėtai yra quoted teksto dalis.

Todėl studento kontroliuojamas vardas/grupė gali padaryti persistent `IVERTINIMAI.csv` nepatikimai perskaitomą kitame paleidime ir pažeisti SHA dedup / žurnalo rekonstrukciją.

Šios problemos nėra `ldcheck` vienkartiniame `suvestine.csv` generavime tokiu pačiu mastu, nes jis savo CSV vėliau nenaudoja kaip persistent duomenų bazės.

Reikia arba:
- drausti CR/LF tapatybės laukuose įvesties ir graderio lygiu; arba
- naudoti pilną CSV parserį, kuris palaiko multiline quoted fields.


---

## 33. `mokytojas` persistent žurnalas nėra crash/concurrency-safe

Kryžmiškai palygintas `ldcheck` ir `mokytojas` failų rašymas.

### ldcheck

`batch.cpp` turi `atomic_write()`:
- rašo į naują temp failą;
- flush/fsync;
- atominiu rename/link būdu commitina;
- output katalogas kuriamas atskirai.

### mokytojas

Persistent istorija rašoma tiesioginiais `ofstream` į:
- appendinamą `IVERTINIMAI.csv`;
- truncinamą `ZURNALAS.csv`;
- truncinamus feedback TXT.

Nėra:
- atomic replace;
- disk flush garantijos;
- cross-process lock.

Vienos `mokytojas --ui` instancijos workerio būsena sinchronizuota mutex/atomic kintamaisiais, bet tai neapsaugo nuo dviejų atskirų proceso instancijų tame pačiame darbo kataloge.

Tai reiškia, kad persistent istorija yra silpnesnė už batch rezultatų saugojimo sluoksnį ir nėra pilnai atspari:
- power/process crash;
- vienu metu paleistam dvigubam vertinimui.

Oficialiam pažymių žurnalui tai laikytina aukšto prioriteto durability problema.


---

## 34. CI dependency verification yra nevienoda

Kryžmiškai patikrinta build tiekimo grandinė.

Teigiamas sluoksnis:
- Eigen ir nlohmann/json atsisiuntimai turi repo hardcodintus SHA-256;
- nesaugūs archive entry atmetami.

Neuždarytas sluoksnis:
- Linux/Windows Scilab 2026.1.0 download neturi checksum verification;
- macOS Scilab DMG gaunamas iš atskiro UTC mirror ir taip pat neturi checksum/signature verification.

Taigi build'as yra versijos-pinned, bet ne visiškai bytes-pinned.

## 35. Galutiniai native paketai neturi platformos leidėjo parašo

Nerasta Windows Authenticode ar macOS Developer ID/notarization release žingsnių.

macOS nepasirašymas README jau nurodytas. Windows atveju tai taip pat aktualu platinamiems EXE/DLL.

Tai nėra P0 laboratorijų logikos defektas; tai P2/P1 release trust ir diegimo patirties klausimas.


---

## 36. Shared-workstation studento tapatybė nėra izoliuota

Bendras studento profilis sąmoningai išsaugomas globaliame `BENCH_STUDENT`.

Kiekvienas naujas `student_enroll()`:
1. sukuria tuščią profilį;
2. jei `BENCH_STUDENT` egzistuoja, naudoja jį kaip įvesties defaults.

Visi LD po sėkmingos registracijos kviečia `student_remember(st)`.

Repo nerasta:
- logout;
- „baigti studento sesiją“;
- `BENCH_STUDENT` clear tarp studentų.

Tai patogu vienam studentui atliekant kelis LD, bet bendroje auditorijos Scilab sesijoje:
- kitas studentas pamato ankstesnio vardą/grupę/numerį;
- galima netyčia patvirtinti ankstesnio studento tapatybę.

## 37. Vietiniai reportai/juodraščiai bendroje OS paskyroje nėra atskirti per studentą

`bench_documents()` numatytasis katalogas yra vienas:

`<HOME>/Grandiniu_LD_darbai`.

Juodraščiai saugomi jo `Juodrasciai/` poaplankyje.

Failuose yra studento tapatybė ir darbo eiga. Jei keli studentai naudojasi ta pačia OS paskyra:
- jų darbai kaupiasi tame pačiame kataloge;
- vienas studentas gali atverti kito ankstesnį `.sod` ar HTML;
- autosave retention ištrina tik šio running session sukurtų snapshotų perteklių, bet ne ankstesnių studentų failus.

Tai nėra problema individualiame nešiojamame kompiuteryje, tačiau yra reali privatumo ir assessment tapatybės rizika shared-lab deployment scenarijuje.

Prieš diegiant auditorijos kompiuteriuose reikia vienos iš aiškių sutarčių:
- atskiros OS paskyros;
- per-student/per-session izoliuotas darbo katalogas;
- aiškus „Baigti sesiją ir išvalyti tapatybę“ veiksmas;
- valdomas failų retention.


---

## 38. `mokytojas` mastelio ribos elgiasi tyliai

Vietinis skeneris sustoja pasiekęs 10 000 HTML failų, tačiau apie truncation nepraneša.

`ldcheck` tuo pačiu mastelio atveju meta aiškią `batch_file_limit` klaidą.

Todėl `mokytojas` gali pateikti sėkmingą rezultatą ne visam pasirinktam katalogui, jei įvestis netikėtai labai didelė.

## 39. Local HTTP sluoksniui trūksta send-all semantikos

`http_send()` vieną kartą kviečia `send()` headeriui ir vieną kartą body, nepatikrindamas return value.

Tai nėra garantuotai teisinga TCP rašymo semantika didesniems atsakymams. Dabartiniam mažam žurnalui tikėtina veikia, bet mastelio testas šios sąlygos nepadengia.

## 40. Localhost UI neturi CSRF/Origin hardening

Teigiama:
- bind tik `127.0.0.1`;
- random ephemeral port.

Neuždaryta:
- Origin/Host netikrinami;
- nėra CSRF/session token;
- state-changing endpointai naudojami per GET.

Tai vidutinio prioriteto lokalaus web UI hardening, o ne laboratorijų fizikos ar graderio blokatorius.


---

## 41. `mokytojas --ui` dalinė vertinimo nesėkmė rodoma kaip sėkmė

Kryžmiškai palygintas `failed` skaitiklis ir HTTP status state.

`process()` nevertinamus failus registruoja `NEVERTINTA` ir didina `failed`, bet vis tiek grąžina 0.

UI workeris `rc==0` interpretuoja kaip bendrą:
„Įvertinimas baigtas. Žurnalas ir atsiliepimai paruošti.“

Browser `/status` nepateikia `graded/failed/duplicate` skaitiklių.

Esamas UI testas klaidos keliui tikrina tik neegzistuojantį katalogą, kuriame `mokytojas_run()` grąžina nonzero. Galiojantis katalogas su blogais studento failais šiuo testu nepadengtas.

Tai yra reali dėstytojo sprendimo kokybės problema: techninis batch gali turėti review/nevertintų failų, o aukščiausio lygio UI vis tiek atrodo visiškai sėkmingas.


---

## 42. `core_version=0.3.0` nėra tikslus build identifikatorius

`ldcheck` verdictuose teisingai išsaugomi:
- lab_revision;
- rubric_version;
- core_version.

Tačiau `core_version` dabartiniame kode yra hardcodinta `"0.3.0"`, o Git/build identifikatorius verdictuose nepateikiamas.

Todėl ankstesnė išvada „ldcheck turi versijų laukus“ yra teisinga tik semantiškai; tiksliai konkretaus binaro/source commit iš vieno verdict failo atkurti negalima.

Šį trūkumą reikia uždaryti kartu su deterministiniu release manifestu.


---

## 43. LD9–LD12 variantų unikalumas papildomai patvirtintas

HEADLESS testas LD9–LD12 tikrina kiekvieno varianto fizines ribas, bet tiesioginio `unique(...)=64` assert šiems naujesniems bankams neturi.

Todėl variantų generatoriai papildomai perskaičiuoti nepriklausomai pagal dabartines formules:

- LD9: 64/64 unikalios `(E,R,L,C,LmH,CnF)` konfigūracijos;
- LD10: 64/64 unikalios `(E,R,L,C,LmH,CnF)` konfigūracijos;
- LD11: 64/64 unikalios `(E,R,L,Ck,LmH)` konfigūracijos;
- LD12: 64/64 unikalios `(Ul,R)` konfigūracijos.

Dubliuotų pilnų variantų nerasta.

Tai uždaro vieną ankstesnę patikros spragą: visi virtualūs LD1–LD12 dabar turi pagrindą teiginiui, kad jų 1–64 priskyrimai yra 64 skirtingi variantai.


---

## 44. Realūs Windows/Linux CI paketai patvirtino LD9–LD12 CSV trūkumą

Kryžminė paketavimo išvada patikrinta tiesiogiai, nebe vien skaitant scenarijus.

Naudotas funkcionaliai patvirtinto SHA `a3f59a87...` Actions run `36162442906`.

### Linux artefaktas 10876895622

Vidiniame `Grandiniu_LD-Linux.zip`:
- LD1–LD8 `VARIANTAI.csv`: yra;
- LD9–LD12 `VARIANTAI.csv`: nėra;
- pačių LD9–LD12 runtime `.sce/.sci` failų yra.

### Windows artefaktas 10877075562

Vidiniame `Grandiniu_LD-Windows.zip`:
- LD1–LD8 `VARIANTAI.csv`: yra;
- LD9–LD12 `VARIANTAI.csv`: nėra.

Abu vidiniai paketai turi po 169 įrašus ir rodo tą patį paketavimo rezultatą.

Todėl teiginys „LD9–LD12 CSV gali trūkti, nes HEADLESS nevykdomas“ dabar pakeistas į stipresnį:

> sėkminguose realiuose Windows ir Linux baseline CI paketuose LD9–LD12 variantų CSV iš tiesų nėra.

Tai tiesiogiai prieštarauja `studentui/README.md` nuorodoms į tuos failus ir dabartiniam `check_student_package.py` kontraktui.
