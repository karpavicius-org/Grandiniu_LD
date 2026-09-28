# LD2 auditas — studento UI → dėstytojo UI

Data: 2026-09-28  
Audituotas `main` prieš šį checkpointą: `030c1cbb39b0eba0c8dd0e43f5b433fedfcb6241`

## Būsena

Virtualaus LD2 skaitinis modelis, RC/RL/RLC fizika, matavimų įrodymai ir C++ vertinimas yra stiprūs. Normalus pirmasis paleidimas teisingai inicijuoja atsiskaitymo režimą ir autosave. Funkcinis kodas šiame etape nekeistas.

Tarp ankstesnio LD1 checkpointo ir šio audito `main` atsirado tik audito dokumentai `OFFICIAL_LD_MAPPING.md` ir `STUDENT_TEACHER_MATRIX.md`; funkciniai LD2 failai nepasikeitė.

## Patvirtinta kaip veikianti

- Normalus `ld2_student_main()` po registracijos nustato `LD2.state.assessment=%t`.
- Normalus studento paleidimas įjungia `LD2.autosave_enabled=%t`.
- Atsiskaitymo režimo pagrindinis mygtukas rodo **„Įrašyti ir toliau →“** ir tyčia nekviečia teisingumo tikrinimo.
- Todėl klaidingas studento atsakymas gali būti išsaugotas ir perduotas dėstytojo vertinimui; studentas nėra verčiamas bandyti tol, kol gauna teisingą atsakymą.
- Mokymosi režime veikia atskira logika: `ld2_check_step()` tikrina atsakymus ir pateikia korekcijos informaciją.
- Pavyzdys / sprendimas atsiskaitymo režime blokuojamas.
- Mokymosi režime pavyzdys kuriamas atskiroje būsenoje, o grįžus atkuriami studento laidai, tekstas ir matavimai.
- Rankinis `.sod` išsaugojimas saugo konfigūraciją ir būseną; atkūrimas patikrina variantą, parametrus ir atsakymų struktūrą.
- Atkuriant darbą generatorius išjungiamas ir gyvi rodmenys anuliuojami, todėl senas matavimo ekranas nelaikomas nauju matavimu.
- Automatinis juodraštis realiame studento meniu pasiekiamas per „Atverti automatinį juodraštį“.
- Studentas gali atskirai eksportuoti matavimų žurnalą, atsakymus, dažninę lentelę, parametrus ir išvadų tekstą.
- Dėstytojo HTML ataskaitai perduodami ne tik atsakymai, bet ir:
  - RC, RL, RLC faktiniai laidų rinkiniai;
  - RC/RL srovės ir įtampos matavimai;
  - rezonanso paieškos taškai;
  - UL/UC/ULC ekstremumų paieškos taškai;
  - f1/f2 ir atitinkamos įtampos;
  - 0–10 kHz sweep duomenys;
  - matavimų žurnalas;
  - laisvo teksto išvados.
- C++ graderis nepriklausomai perskaičiuoja etalonus ir tikrina, kad matavimo duomenys atitiktų modelį.
- LD2 rubrika turi 50 taškų ir apima teorinius atsakymus, faktinius matavimus, tris grandinių sujungimus, rezonanso eksperimentą, tris ekstremumų tyrimus, pusės galios taškus ir 11 taškų dažninę charakteristiką.
- Rezonanso paieškai neužtenka vien įrašyti teorinį f0: graderis reikalauja faktinių taškų abipus maksimumo.
- f1/f2 neužtenka įrašyti skaičių: graderis tikrina matuotą įtampą ties URmax/√2 ir modelio atitiktį.
- Nepriklausomame matematiniame audite visų 64 variantų RC/RL/RLC skaičiavimai buvo palyginti su nepriklausomomis kompleksinėmis formulėmis; 3072 patikrintų išvesčių didžiausias absoliutus skirtumas buvo apie `5.7e-14`.

## CRITICAL/HIGH — „Pradėti iš naujo“ tyliai išjungia atsiskaitymo režimą

Normalus LD2 paleidimas nustato:

`LD2.state.assessment=%t`.

Tačiau `ld2_restart()` daro:

1. išsaugo tik `teacher_mode` ir studento tapatybę;
2. sukuria naują `ld2_initial_state(LD2.cfg)`;
3. `ld2_initial_state()` nustato `assessment=%f`;
4. `assessment` po restarto neatkuriamas.

Rezultatas:

- studentas pradeda darbą atsiskaitymo režime;
- pasirenka Pagalba → „Pradėti iš naujo“;
- naujas darbas tyliai tampa mokymosi režimu;
- pagrindinio mygtuko semantika pasikeičia į „Patikrinti“;
- išsaugota ataskaita gauna `mode="learning"`;
- dėstytojo suvestinėje toks bandymas neįskaitomas.

Tai realaus studento UI būsenos mašinos defektas, ne teorinė kraštinė situacija.

## CRITICAL/HIGH — keičiant eilės numerį / variantą naujas darbas taip pat tyliai tampa mokymosi režimu

`ld2_student_details()` leidžia pakeisti studento duomenis ir eilės numerį.

Jei numeris pasikeičia, `ld2_apply_profile()`:
- išvalo dinaminę būseną;
- pakeičia variantą;
- sukuria naują `ld2_initial_state(cfg)`;
- įrašo naują studentą.

Tačiau `assessment=%t` neatstatomas.

Todėl studentui pasirinkus kitą variantą ir patvirtinus aiškiai rodomą perspėjimą „Pradėti naują“, naujas darbas nėra toks pats kaip pradinis paleidimas: jis tampa `learning`.

Dėstytojo požiūriu tai gali atrodyti kaip teisėtai atlikta ataskaita, tačiau ji nepatenka į pažymių suvestinę.

## HIGH/UI — atsiskaitymo režimas nefiksuoja etapų kaip atliktų ar praleistų

`ld2_student_primary()` atsiskaitymo režime daro:

- autosave;
- jei ne 12 etapas — tiesiog `ld2_go_step(step+1,%f)`.

Jis:
- nekviečia `ld2_check_step()`;
- nenustato `completed(step)=1`;
- nenustato `skipped(step)=1`.

Tai teisingai išvengia atsakymo teisingumo atskleidimo, tačiau palieka vidinę etapų būseną neapibrėžtą.

`ld2_show_summary_window()` etapą rodo:
- PATIKRINTA, jei `completed=1`;
- PRALEISTA, jei `skipped=1`;
- kitaip NEATLIKTA.

Todėl studentas gali atsiskaitymo režime:
- teisingai sujungti grandinę;
- atlikti visus matavimus;
- įrašyti visus atsakymus;
- pereiti per visus 12 etapų;

ir vis tiek suvestinėje matyti ankstesnius etapus kaip **NEATLIKTA**.

Dėstytojo graderis `completed/skipped` laukų nenaudoja ir gali teisingai skirti balus pagal faktinius įrodymus, todėl susidaro paradoksas:

> studento UI sako „NEATLIKTA“, o dėstytojo vertintuvas gali skirti pilną balą.

## HIGH/UX — atsiskaitymo režime galima vienu paspaudimu tyliai praleisti visiškai tuščią privalomą etapą

Mokymosi režime `ld2_next()` nepatikrintam etapui rodo pasirinkimą:
- likti ir baigti;
- pereiti nebaigus.

Atsiskaitymo režime šis apsauginis kelias apeinamas.

„Įrašyti ir toliau“ leidžia pereiti net jei:
- nėra nė vieno privalomo laido;
- nėra atsakymo;
- nėra privalomų matavimų;
- rezonanso taškai neužfiksuoti.

Tai nėra vertinimo saugumo klaida — graderis už trūkstamus įrodymus duos 0 taškų. Tačiau studento ergonomikai tai rizikinga: atsitiktinis paspaudimas gali nepastebimai palikti nulį už visą etapą.

Industrinio lygio atsiskaitymui reikėtų atskirti:
- **pilnumo kontrolę** (ar studentas kažką įvedė / atliko privalomą veiksmą);
- **teisingumo kontrolę** (kurios atsiskaitymo metu studentui rodyti nereikia).

Dabartinis LD2 atsiskaitymas išjungia abi.

## HIGH — CI pagrindinis LD2 workflow testuoja mokymosi, o ne realų atsiskaitymo kelią

`studentui/tests/workflows.sci::bench_ld2_workflow()` pats konstruoja:

`LD2.state=ld2_initial_state(cfg)`

ir nenustato `LD2.state.assessment=%t`.

Toliau jis vykdo `bench_ld2_primary()`, todėl realiai eina mokymosi logika:
- tikrina etapą;
- reikalauja teisingumo;
- nustato `completed=1`;
- dar kartą spaudžia mygtuką, kad pereitų toliau.

Dėl to testas sėkmingai patvirtina:
- visas fizines operacijas;
- teisingumo tikrinimą;
- `completed` būseną;
- ataskaitą;
- save/restore;

bet nepatvirtina normalios studento starto semantikos, kur `assessment=true`.

Būtent todėl:
- restarto / varianto pakeitimo `assessment` praradimas;
- atsiskaitymo `completed/skipped` problema;
- visiškai tuščio etapo tylus praleidimas

galėjo likti nepastebėti žaliame CI.

## HIGH/TRACEABILITY — virtualus „LD2“ nėra oficialus dalyko LD2

Oficialiame dalyko apraše:

**2 laboratorinis darbas — „Įtampos ir srovės matavimas“.**

Virtualus programos LD2 yra:
- RC grandinė;
- RL grandinė;
- nuosekli RLC;
- rezonansas;
- UL/UC ekstremumai;
- -3 dB ribos;
- dažninė charakteristika.

Pats `ld2_method.sci` tai teisingai ir aiškiai pripažįsta:

- RC/RL/RLC tematika siejasi su oficialiais 9 ir 10 laboratoriniais darbais;
- ji **nėra** I semestro oficialus LD2 „Įtampos ir srovės matavimas“.

Tai gerai dokumentuota studento metodikos viduje, tačiau sistemos išorėje vis tiek naudojamas ID `LD2`.

Svarbiausia pasekmė dėstytojui:

- `mokytojas --ui` kuria `ZURNALAS.csv` su stulpeliais `LD1 ... LD13`;
- virtualaus RC/RL/RLC darbo pažymys patenka į stulpelį **LD2**;
- oficialiame studijų dalyke tas stulpelis semantiškai reikštų visai kitą laboratorinį darbą.

Kol nėra aiškaus oficialus↔virtualus ID žemėlapio žurnalo lygyje, `ZURNALAS.csv` negalima laikyti tiesiogine oficialių 13 laboratorinių darbų pažymių matrica.

## MEDIUM — virtualus LD2 dalinai dubliuoja vėlesnį virtualų LD9

Virtualus LD2 jau turi nuoseklios RLC grandinės:
- rezonanso dažnį;
- UR maksimumo paiešką;
- UL/UC ekstremumus;
- f1/f2;
- BW ir Q;
- dažninę charakteristiką.

Virtualus LD9 taip pat yra nuoseklios RLC grandinės ir įtampų rezonanso laboratorija.

Tai nebūtinai klaida, nes metodinis gylis gali skirtis, tačiau galutiniame oficialiame žemėlapyje reikia aiškiai nurodyti:
- kuriuos studijų rezultatus vertina virtualus LD2;
- kuriuos papildomai / atskirai vertina LD9;
- ar studentas turi atlikti abu.

## MEDIUM — režimo pakeitimas į mokymąsi pažymi bandymą kaip practice, bet UI nepaaiškina negrįžtamumo dabartiniame bandyme

`bench_mode("LD2")` pasirinkus mokymąsi nustato `practice_used=%t`.

Vėliau grįžus į atsiskaitymą šis laukas neanuliuojamas, todėl ataskaita į pažymių suvestinę nepatenka.

Tai teisinga apsaugos logika, tačiau režimo pasirinkimo dialogas aiškiai nepasako, kad:
- vien tik sugrįžti į „Atsiskaitymas“ nepakanka;
- esamas bandymas jau pažymėtas kaip naudota mokymosi pagalba.

## MEDIUM — laisvo teksto išvados perduodamos dėstytojui, bet automatiškai nevertinamos

LD2 leidžia studentui įrašyti išvadas apie:
- RC/RL fazes;
- įtampų vektorius;
- RLC rezonansą;
- ribinius dažnius.

Tekstas patenka į report `note` ir matomas dėstytojui, tačiau 50 taškų skaitinė rubrika už jo turinį balų neskiria.

Jeigu išvadų formulavimas yra oficialus vertinamas studijų rezultatas, tai reikės atskiro dėstytojo vertinimo arba aiškiai aprašytos rubrikos. Jei išvados tik refleksinės — dabartinis sprendimas tinkamas.

## MEDIUM — bendros dėstytojo UI problemos taikomos ir LD2

LD2 taip pat paveikia jau bendrame audite nustatyti dalykai:

1. `ldcheck` vienodą `submission_id` su skirtingais duomenimis žymi konfliktu, o `mokytojas --ui` deduplikuoja tik pagal failo SHA-256.
2. Batch suvestinės studento tapatybė apima studento numerį, o `mokytojas` žurnalas grupuoja vardą+grupę.
3. `mokytojas --ui` vardą ir grupę pateikia naršyklėje per neescapintą `innerHTML`, todėl LD2 ataskaita taip pat gali pernešti lokalų HTML/XSS payload.
4. Studentas pats deklaruoja vardą, grupę ir 1–64 numerį; sistema neturi oficialaus dėstytojo sąrašo, kuris patvirtintų, kad vardui priklauso būtent tas variantas.

## LOW/MEDIUM — senesnio rankinio LD2 sesijos formato saugi, bet ne visai skaidri režimo migracija

`ld2_read_session()` senesnei sesijai, kur nėra `assessment`, priskiria:

`assessment=%f`.

Tai saugus pasirinkimas — senas nežinomas darbas automatiškai nepaverčiamas atsiskaitymu.

Tačiau studentui atkūrus seną `.sod` failą nėra aiškaus atskiro perspėjimo, kad atkurtas darbas yra mokymosi režime ir nebus įtrauktas į galutinę suvestinę, kol nebus sąmoningai pradėtas tinkamas atsiskaitymo bandymas.

## LD2 audito išvada

LD2 yra vienas techniškai stipriausių darbų sistemoje:
- modelis patikrintas nepriklausomai;
- faktiniai eksperimentiniai veiksmai perduodami į graderį;
- atsiskaitymas teisingai neatskleidžia atsakymo teisingumo;
- autosave, rankinis save/restore ir pavyzdžio izoliacija veikia.

Didžiausios problemos yra **būsenos ir identifikacijos sluoksnyje**, ne fizikoje:

1. restartas ir varianto pakeitimas pameta atsiskaitymo režimą;
2. atsiskaitymo režimas nepalaiko prasmingos etapų `completed/skipped` būsenos;
3. atsiskaityme nėra net pilnumo apsaugos nuo atsitiktinio tuščio etapo praleidimo;
4. CI pagrindinis workflow šio realaus atsiskaitymo kelio netestuoja;
5. ID `LD2` konfliktuoja su oficialaus dalyko LD2 numeriu ir tiesiogiai persiduoda į dėstytojo žurnalą.

Šiame etape niekas netaisyta. Įgyvendinimo variantai bus nagrinėjami tik užbaigus visų LD studento→dėstytojo auditą.


## HIGH / ASSESSMENT INTEGRITY — practice žymos apėjimas per restartą

Patvirtinta kryžmiškai pagal realų produkto kelią:

1. LD2 normaliai pradeda `assessment=true`.
2. Assessment metu `ld2_show_solution()` Pavyzdį blokuoja.
3. Studentas per `bench_mode("LD2")` pereina į Mokymąsi; tada `LD2.state.practice_used=%t`.
4. Mokymosi režime Pavyzdys tampa pasiekiamas ir gali parodyti to paties varianto sprendimą.
5. `ld2_restart()` pakeičia visą `LD2.state` nauju `ld2_initial_state(cfg)`.
6. Naujas `ld2_initial_state()` turi `assessment=%f`, bet `practice_used` lauko apskritai nekuria.
7. Studentui vėl pasirinkus Atsiskaitymą, `assessment=%t`, o `practice_used` lieka neegzistuojantis; report export jį interpretuoja kaip `false`.

Taigi pavyzdį tame pačiame variante jau matęs studentas po restarto gali sukurti formaliai įskaitinį assessment reportą.

Tai stipresnis defektas nei vien assessment numetimas: restarte prarandamas ir mokymosi/pavyzdžio atsekamumas.
