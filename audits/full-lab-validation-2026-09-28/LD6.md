# LD6 auditas — studento UI → dėstytojo UI

Data: 2026-09-28  
Audituotas `main` prieš šį checkpointą: `39262e201692a8973583e8280dd5a4d817bfd310`

## Būsena

Virtualus LD6 yra **šaltinių jungimo** laboratorinis darbas:
- vienas E1 šaltinis su vidine varža;
- E1+E2 nuosekliai;
- E1/E2 priešpriešiais;
- E1/E2 lygiagrečiai su vidinėmis r1/r2;
- apkrovos ir atskirų šaltinių srovės.

Tai yra naujesnė revizija:
- bankas `LD6-64-B-2026`;
- `lab_revision="2"`;
- rubrika `LD6-2`;
- 25 kriterijai.

Techninė fizika, report revision ir graderis tarpusavyje suderinti. Funkcinis kodas šiame etape nekeistas.

## Patvirtinta kaip veikianti

- Studentas realiai sujungia keturias skirtingas topologijas.
- Kiekvieno režimo laidai saugomi atskirai.
- Pakeitus laidą:
  - anuliuojami susiję matavimai;
  - anuliuojamas susijusių etapų `done`;
  - report wiring įrodymas išvalomas.
- Laidų redagavimas **blokuojamas esant įjungtam maitinimui**.
- Perjungiant topologijos režimą maitinimas ir jungiklis automatiškai išjungiami.
- Tai yra teisinga laboratorinės saugos / darbo sekos semantika.
- Priešpriešiniame režime išlaikomas įtampos ir srovės ženklas.
- Lygiagrečiame režime modeliuojamos atskiros E1 ir E2 šaltinių srovės; neigiama srovė reiškia energijos tekėjimą į mažesnės EV šaltinį.
- Lygiagretus nevienodų EV šaltinių jungimas modeliuojamas su r1=r2=10 Ω, todėl idealūs skirtingų įtampų šaltiniai nėra trumpinami be vidinių varžų.
- C++ graderis nepriklausomai skaičiuoja visų keturių režimų U/I.
- Graderis taip pat tikrina lygiagretaus režimo atskiras šaltinių sroves.
- Ataskaita saugo keturių režimų:
  - U;
  - I;
  - lygiagrečiai I1/I2;
  - laidų įrodymus.
- Kiekviena topologija vertinama atskiru wiring kriterijumi.
- Studentų variantų bankas ir C++ variantų bankas suderinti.
- Studentų report automatiškai žymimas:
  - `lab_revision="2"`;
  - `rubric_version="LD6-2"`;
  - `bank_id="LD6-64-B-2026"`.
- Graderis seną `LD6-1` vis dar palaiko atskirai, todėl istorinių ataskaitų suderinamumas išlaikytas.
- Targeted testai tikrina variantus 1/17/64, keturias realias topologijas, pasirašytą MNA elgseną, report evidence, kablelio įvestį, draft restore, geometriją ir Scilab↔C++ grading atitiktį.
- Ankstesnė nepriklausoma fizikos patikra patvirtino lygiagrečios topologijos apkrovos įtampos fizinį intervalą ir kitus LD6 bazinius santykius.

## CRITICAL — normalus LD6 studento paleidimas nėra atsiskaitymo režimas

`ld6_student_main()` po registracijos sukuria:

`LD6=struct("root",root,"cfg",cfg,"student",st)`

ir kviečia `ld6_start()`.

Nėra:

`LD6.assessment=%t`.

Todėl normalus report generuojamas su:

`mode="learning"`.

Net teisingas 25/25 darbas:
- bus įvertintas;
- gaus feedback;
- bet nepateks į galutinę pažymių suvestinę.

## CRITICAL — realiame LD6 UI nėra režimo pasirinkimo

Bendras `bench_mode("LD6")` techniškai egzistuoja.

Tačiau realus Pagalbos meniu jo nekviečia.

Studentas iš standartinio produkto kelio negali sąmoningai pasirinkti formaliojo assessment režimo.

## CRITICAL/METHODIC — `ld6_student_primary()` assessment būsenos nenaudoja

Pagrindinio mygtuko logika visada:
1. išsaugo atsakymus;
2. kviečia `ld6_check_step()`;
3. tik teisingai patikrintą etapą pažymi `done`;
4. tik tada leidžia tęsti.

Todėl net ranka nustatytas `assessment=true` nepadarytų LD6 tikru atsiskaitymu.

Klaidingas atsakymas turi būti pataisytas prieš judant toliau.

## HIGH — formalus assessment negali naudoti dabartinio `ld6_check_step()`

`ld6_check_step()` tikrina:
- ar yra privalomas matavimas;
- ar laidai teisingi;
- ar kiekvienas skaitinis studento atsakymas yra pakankamai arti etalono.

Klaidos pranešimas šiuo atveju nėra toks tiesioginis kaip LD3/LD4/LD5 — paprastai nerodo tikslaus etaloninio skaičiaus, o pateikia formulės / ženklų užuominą.

Tai yra metodologiškai geriau.

Vis dėlto assessment metu pati teisingumo kontrolė turi likti dėstytojo pusėje. Studentui reikia tik:
- pilnumo;
- matavimo veiksmų;
- saugos / wiring validumo

kontrolės, bet ne galutinio atsakymo teisingumo atskleidimo.

## HIGH/UI — keliuose mA skaičiavimuose formulėse trūksta ×1000

2 etapo instrukcija suformuluota teisingai:

`I = E1/(R+r1) · 1000 mA`.

Tačiau:

### 3–4 etapai

Rodoma:

`I = (E1+E2)/(R+r1+r2)`

ir

`I = (E1−E2)/(R+r1+r2)`

o studento atsakymo laukai ir graderis srovę interpretuoja **mA**.

Pagal vienetus V/Ω duoda A. Jei atsakymas laukiamas mA, turi būti aiškus ×1000.

### 5 etapas

Rodoma:

- `I=U/R`;
- `I1=(E1−U)/r1`;
- `I2=(E2−U)/r2`;

ir tuoj pat sakoma „Sroves rašykite mA“.

Tačiau studentui neparodoma konversija ×1000.

C++ graderio etalonai teisingai skaičiuoja mA su ×1000.

Taigi problema yra instrukcijoje, ne fizikoje.

## HIGH — realiame produkto kelyje autosave neįjungtas

Generic `bench_session.sci` LD6 snapshot/autosave palaiko.

Targeted testas net ranka nustato:

`LD6.autosave_enabled=%t`

ir patvirtina autosave mechanizmą.

Tačiau normalus studento paleidimas:
- nenustato `autosave_enabled`;
- Pagalbos meniu neturi „Tęsti išsaugotą darbą“;
- realus studento srautas bendro autosave neaktyvuoja.

CI čia įrodo biblioteką, bet ne studentui prieinamą funkciją.

## HIGH — CI workflow vėl testuoja learning semantiką

`bench_ld6_workflow()` sukuria:

`LD6=struct(...)`

be `assessment=true`.

Toliau kiekviename etape:
- sujungia;
- matuoja;
- įveda etaloninius atsakymus;
- kviečia `ld6_student_primary()`;
- reikalauja `LD6.done(step)==true`.

Eksportas atliekamas tame pačiame learning režime.

Todėl žalias CI patvirtina:
- fizikinį workflow;
- wiring;
- MNA;
- GUI;
- grading suderinamumą;

bet ne formalų assessment kelią.

## HIGH/TRACEABILITY — virtualus LD6 atitinka oficialų LD7, ne oficialų LD6

Oficialiame kurso apraše:
- LD6 — įtampos daliklis;
- LD7 — elektros šaltinių jungimas.

Virtualioje sistemoje:
- LD5 — įtampos daliklis;
- **LD6 — šaltinių jungimas**.

Todėl `ZURNALAS.csv` stulpelis **LD6** semantiškai atitinka oficialų LD7, o ne oficialų LD6.

Šis vienos pozicijos poslinkis jau sistemingas nuo virtualaus LD5.

## MEDIUM — lygiagretaus šaltinių jungimo metodika turi būti aiškiai paaiškinta studentui

Modelis fiziškai prasmingas todėl, kad:
- abu šaltiniai turi r1=r2=10 Ω;
- E1 ir E2 gali būti nevienodi;
- gali atsirasti srovė į mažesnės EV šaltinį.

Tai vertinga mokomoji situacija.

Tačiau studentui svarbu aiškiai pabrėžti, kad:
- nevienodų idealizuotų šaltinių tiesiogiai lygiagrečiai jungti negalima;
- šiame modelyje saugų rezultatą lemia įtrauktos vidinės varžos;
- neigiamas I2 nėra skaičiavimo klaida.

Dalis šio paaiškinimo jau yra Pagalboje, bet galutinėje metodikoje tai turi būti akcentuota, nes priešingu atveju laboratorinis stendas gali suformuoti pernelyg supaprastintą taisyklę „skirtingus šaltinius galima jungti lygiagrečiai“.

## MEDIUM — pavyzdžio apsauga paruošta

`ld6_toggle_solution()`:
- izoliuoja studento būseną;
- nustato `practice_used=true`;
- report demonstraciniame režime neleidžiamas.

Tai gera bazė būsimam assessment dizainui.

## MEDIUM — restartas išlaiko cfg/student, tačiau būsimas režimas turi būti aiškiai suprojektuotas

`ld6_restart()` kviečia `ld6_init_state()`.

`ld6_init_state()` nekeičia cfg/student ir šiuo metu nevaldo assessment/practice/autosave laukų.

Todėl, skirtingai nuo LD2, čia nėra dabartinio aiškaus „assessment numetimo“ defekto — assessment apskritai nėra normaliai įjungtas.

Tačiau diegiant formalų režimą reikia sąmoningai apibrėžti:
- ką restartas turi išlaikyti;
- kada `practice_used` turi likti negrįžtamas;
- ar autosave istorija turi būti pradėta iš naujo.

## MEDIUM — bendros dėstytojo UI problemos taikomos ir LD6

LD6 taip pat paveikia:
- nevienoda `submission_id` konfliktų logika tarp `ldcheck` ir `mokytojas --ui`;
- nevienodas studento grupavimas;
- `mokytojas --ui` neescapintas studento vardas/grupė naršyklės `innerHTML`;
- studento deklaruojamas numeris nėra tikrinamas prieš oficialų grupės sąrašą.

## LD6 audito išvada

LD6 yra techniškai stiprus laboratorinis modelis.

Ypač geri elementai:
- keturios realios topologijos;
- laidų būsenų invalidacija;
- maitinimo išjungimo kontrolė prieš rewiring;
- vidinių šaltinių varžų modelis;
- pasirašytos srovės;
- atskiros lygiagrečių šaltinių srovės;
- nuosekli `LD6-2` versijų schema.

Pagrindinės problemos:
1. nėra realaus assessment produkto kelio;
2. primary reikalauja teisingumo vietoje;
3. nėra realaus autosave/restore UI;
4. kelių srovės formulių mA konversija pateikta nepilnai;
5. virtualus LD6 numeris atitinka oficialų LD7;
6. CI testuoja learning, ne assessment semantiką.

Šiame etape niekas netaisyta.
