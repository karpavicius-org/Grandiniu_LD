# LD8 auditas — studento UI → dėstytojo UI

Data: 2026-09-28  
Audituotas `main` prieš šį checkpointą: `e1ee02694723e1933224ba5baa185ce2546ef21c`

## Būsena

LD8 yra pirmasis iš naujesnių virtualių darbų, kuriame reali studento produkto eiga jau turi pilną atskyrimą tarp:
- atsiskaitymo;
- mokymosi;
- privalomų veiksmų / pilnumo kontrolės;
- teisingumo vertinimo dėstytojo pusėje;
- autosave / restore.

Todėl LD8 yra tinkamiausias esamas vidinis etalonas, pagal kurį vėliau galima projektuoti LD3–LD7 ir LD9–LD12 assessment srautą.

Virtualus LD8 tiria nuoseklų, lygiagretų ir mišrų trijų rezistorių jungimą. Pagal oficialaus dalyko metodiką ši tema semantiškai atitinka **oficialų LD5**, ne oficialų LD8.

Funkcinis kodas šiame etape nekeistas.

## Patvirtinta kaip veikianti

- `ld8_init_state()` normaliai nustato:
  - `assessment=%t`;
  - `practice_used=%f`.
- Realus studento paleidimas įjungia `autosave_enabled`.
- Pagalboje realiai pasiekiamas:
  - „Tęsti išsaugotą darbą“;
  - „Išsaugoti ataskaitą“;
  - „Mokymosi / atsiskaitymo režimas“;
  - wiring guide;
  - pavyzdys;
  - stendo atkūrimas;
  - restartas.
- Atsiskaitymo režime pagrindinis mygtukas rodo:
  - **„ĮRAŠYTI IR TOLIAU →“**.
- `ld8_student_primary()` assessment metu kviečia:
  - `ld8_check_step(~LD8.assessment)`,
  todėl `check_answers=%f`.
- Assessment metu studento atsakymas:
  - turi būti netuščias;
  - **neprivalo būti teisingas**;
  - neparodomas etalonas;
  - raw tekstas išsaugomas nepakeistas.
- Testas tiesiogiai patvirtina, kad assessment metu `1+2` gali būti išsaugotas kaip klaidingas raw atsakymas ir studentas pereina toliau.
- Tuščias privalomas laukas assessment metu neleidžia tęsti.
- Wiring ir realus matavimas assessment metu vis tiek privalomi; sistema neleidžia vien įrašyti skaičių be praktinio veiksmo.
- Learning režime tas pats `ld8_check_step()` jau tikrina teisingumą vietoje.
- Tai yra tinkamas architektūrinis atskyrimas:
  - produkto pilnumas / eksperimentas tikrinamas studento pusėje;
  - žinių teisingumas — dėstytojo graderio pusėje.
- Autosave vykdomas:
  - pakeitus atsakymą;
  - pakeitus laidus;
  - atlikus matavimą;
  - pereinant etapus;
  - atkuriant etapą;
  - restartuojant;
  - uždarant langą.
- Uždarant langą paskutinis edit tekstas išsaugomas net nepaspaudus Enter.
- Jei autosave nepavyksta, langas nėra tyliai uždaromas.
- Juodraščio atkūrimas:
  - atkuria etapą;
  - atsakymus;
  - laidus;
  - matavimus;
  - assessment būseną;
  - išjungia maitinimą.
- Senesnis snapshot be `assessment` saugiai atkuriamas kaip nepatikimas mokymosi/practice bandymas.
- Laidų keitimas blokuojamas, kai maitinimas įjungtas.
- Keičiant topologiją maitinimas ir jungiklis išjungiami.
- Pakeitus laidus anuliuojamas susijęs matavimo / wiring įrodymas.
- Pavyzdys izoliuojamas nuo studento būsenos ir report demonstraciniame režime neeksportuojamas.
- Pavyzdžio naudojimas nustato `practice_used=true`.
- Perėjus į mokymosi režimą `practice_used=true`; grįžus į assessment paprastu režimo perjungimu jis išlieka true.
- C++ graderis turi 21 kriterijų:
  - 12 studento atsakymų;
  - 6 realių matavimų;
  - 3 wiring įrodymus.
- Modelis vertina:
  - nuoseklią Rt ir eksperimentinę Re;
  - lygiagrečią Rt ir Re;
  - mišrią Rt ir Re;
  - tris lygiagrečių šakų sroves;
  - tris išvadas;
  - 3×U/I matavimus;
  - 3 topologijas.
- Targeted GUI testas tikrina realų assessment ir learning režimus, close/autosave/help restore, wrong-raw išlaikymą, 3 topologijas, MNA ir 146 grading palyginimus.
- `tools/test_ld8.py` tiesiogiai patvirtina, kad realios GUI ataskaitos:
  - yra `mode=assessment`;
  - gauna 21/21;
  - yra `selected_for_summary=true`.
- Practice ataskaita gauna grįžtamąjį ryšį, bet neįtraukiama į suvestinę.

## CRITICAL / VISOS SISTEMOS VIENTISUMAS — studento pakete yra pilnas dėstytojo vertintuvas ir etalonai

LD8 yra pirmas darbas, kuriame tikras formalus assessment realiai veikia, todėl ši bendra sistemos problema tampa ypač svarbi.

Studentams platinamame pakete šiuo metu yra:
- `ldcheck`;
- `mokytojas`;
- `ldcore` su pilna graderio logika.

Be to:
- `STENDAS.sce` bendrame paleidimo meniu turi dėstytojo automatinio vertinimo punktą;
- realiu iš CI studento paketo paimtu `ldcheck` jau patvirtinta, kad klaidingai studento ataskaitai `vertinimai.html` parodo studento atsakymą ir tikslų teisingą etaloną.

Dar svarbiau:
- `core/src/report.cpp::report_html()`, naudojamas studento HTML ataskaitai sukurti, pats kviečia `grade(r)`, kad gautų rubrikos etiketes;
- taigi pilnas graderis nėra tik atskirame `ldcheck` EXE — jis architektūriškai yra ir studento naudojamame `ldcore`.

Tai reiškia, kad studentas su formaliu LD8 assessment:
1. gali išsaugoti savo ataskaitą;
2. lokaliai paleisti pateiktą dėstytojo vertintuvą;
3. pamatyti tikslų balą ir klaidingų atsakymų etalonus;
4. grįžti į stendą ir pataisyti atsakymus prieš galutinį pateikimą.

Todėl vien LD8 UI assessment semantikos nepakanka, kad darbas būtų patikimas formalus atsiskaitymas.

Vėliau reikės architektūriškai atskirti:
- studentui būtiną skaitinį modelį;
- studento report rendererį;
- dėstytojo slaptą / neprieinamą grading etalonų sluoksnį.

Vien `ldcheck.exe` pašalinimas iš paketo šios problemos neišspręstų, kol studento `ldcore` pats turi pilną `grade()`.

## HIGH / POLICY — „Pradėti iš naujo“ nuvalo `practice_used`

Paprastas režimo perjungimas veikia konservatyviai:
- studentas pasirenka Mokymasis;
- `practice_used=true`;
- studentas grįžta į Atsiskaitymas;
- `practice_used` lieka true;
- bandymas nebegali patekti į galutinę suvestinę.

Pavyzdžio naudojimas taip pat nustato `practice_used=true`.

Tačiau „Pradėti iš naujo“ vykdo:

`ld8_restart() → ld8_init_state()`

o `ld8_init_state()` nustato:

- `assessment=%t`;
- `practice_used=%f`.

Vadinasi studentas gali:
1. atverti Pavyzdį arba Mokymosi režimą;
2. pamatyti sprendimo / savikontrolės informaciją;
3. pasirinkti „Pradėti iš naujo“;
4. gauti naują švarią assessment būseną tam pačiam studentui ir variantui.

Tai gali būti **sąmoningas produkto sprendimas**, jei restartas interpretuojamas kaip naujas formalus bandymas po pasiruošimo.

Tačiau dabartinis UI ir dokumentacija šios politikos aiškiai neapibrėžia.

Ji taip pat skiriasi nuo paprasto režimo perjungimo semantikos, kur practice žymuo yra negrįžtamas.

Todėl prieš įgyvendinimo fazę reikia nuspręsti vieną aiškią taisyklę:
- ar studentui leidžiama mokytis ir tada pradėti visiškai naują assessment bandymą;
- ar practice žymuo turi likti susietas su studentu / variantu iki atskiro dėstytojo leidimo;
- ar naujas formalus bandymas turi gauti atskirą aiškiai identifikuotą attempt/session ID.

Dabartiniai testai `practice → restart → assessment` scenarijaus netikrina.

## HIGH/UI — 5 etapo šakų srovių formulėse trūksta ×1000

Studentui rodoma:

- `I1 = U/R1`;
- `I2 = U/R2`;
- `I3 = U/R3`;

ir nurodyta, kad atsakymas yra **mA**.

Tačiau V/Ω duoda A.

Kad gauti mA, turi būti:

`I = U/R × 1000`.

C++ graderis tai skaičiuoja teisingai.

Tai studento instrukcijos, ne modelio klaida.

## MEDIUM/UI — eksperimentinės varžos formulės vienetų paaiškinimas nevienodas tarp etapų

2 etape aiškiai parašyta:

`Re = U/I (I — amperais)`.

3 ir 4 etapuose rodoma tik:

`Re = U/I`.

Tačiau matavimų žurnalas studentui srovę rodo mA.

Matematiškai sistema veikia, bet pedagogiškai tą patį A↔mA priminimą verta pateikti vienodai visuose trijuose etapuose.

## HIGH/TRACEABILITY — virtualus LD8 semantiškai yra oficialus LD5

Oficialiame dalyko apraše LD5 yra:
- elementų nuoseklusis jungimas;
- lygiagretusis jungimas;
- mišrusis jungimas.

Būtent tai atlieka virtualus **LD8**.

Tuo tarpu oficialus LD8 yra įtampos, srovės ir galios suderinamumo darbas, kurį virtualioje sistemoje atlieka LD7.

Todėl `ZURNALAS.csv` stulpelis **LD8** nėra oficialaus LD8 pažymys.

LD8 yra aiškus pavyzdys, kodėl produkto lygiu būtina atskirti:
- vidinį virtualų ID;
- oficialų laboratorinio darbo numerį.

## MEDIUM — Pavyzdys prieinamas ir assessment metu be aiškaus perspėjimo apie bandymo statusą

Techniškai apsauga veikia:
- pavyzdys nustato `practice_used=true`;
- toks report nebus pasirinktas galutinei suvestinei.

Tačiau studentui prieš atveriant Pavyzdį nėra aiškios žinutės, kad:
- šis konkretus bandymas nuo šio momento tampa practice;
- paprastas grįžimas į assessment jo neatkurs.

Tai nėra grading spraga, bet UX gali sukelti netikėtą neįskaitytą bandymą.

Šis perspėjimas ypač svarbus, jei restart policy vėliau bus atskirta kaip „naujas bandymas“.

## MEDIUM — studento report yra redaguojamas failas ir pats savaime neįrodo autorystės / nekintamumo

LD8 HTML ataskaitoje yra JSON duomenų blokas.

Graderis griežtai tikrina:
- banką;
- parametrus;
- variantą;
- struktūrą;
- matavimo įrodymus.

Tačiau failas nėra kriptografiškai pasirašytas patikimu dėstytojo raktu.

Todėl:
- lokalus HTML failas nėra neklastojamas pateikimo kvitas;
- studento vardas / grupė / submission metadata savaime nepatvirtina autorystės.

Tai bendra sistemos, ne vien LD8 problema.

## MEDIUM — du dėstytojo keliai vis dar nėra semantiškai identiški

LD8 assessment failui galioja bendri radiniai:

- batch/`ldcheck` vienodą `submission_id` su pakeistu turiniu žymi konfliktu;
- `mokytojas --ui` deduplikuoja tik pagal failo SHA-256;
- batch ir `mokytojas` studento bandymus grupuoja ne tuo pačiu raktu;
- `mokytojas --ui` studento vardą / grupę naršyklės lentelėje pateikia per neescapintą `innerHTML`.

Kadangi LD8 jau yra realus formalus assessment, šie skirtumai čia nėra teoriniai — jie tiesiogiai gali pakeisti galutinį žurnalą.

## LD8 audito išvada

LD8 studento srauto architektūra yra geriausia dabartinėje sistemoje ir turėtų būti pagrindinis precedentas kitų LD pertvarkymui.

Ypač verta išsaugoti:
1. `assessment=true` realiame starte;
2. aiškų režimo pasirinkimą UI;
3. assessment metu tik pilnumo, wiring ir matavimų kontrolę;
4. neteisingo raw atsakymo išlaikymą;
5. learning metu vietinį teisingumo tikrinimą;
6. realų autosave/restore;
7. saugų rewiring tik išjungus maitinimą;
8. CI testą, kuris tikrina būtent realų assessment kelią.

Tačiau prieš kopijuojant LD8 modelį į kitus darbus reikia išspręsti dvi aukštesnio lygio politikos problemas:

- studento distribucijoje yra pilnas graderis ir etalonai;
- neapibrėžta, ar „Pradėti iš naujo“ po practice turi būti laikoma nauju švariu formaliojo atsiskaitymo bandymu.

Papildomai lieka vienetų instrukcijų ir oficialaus numeravimo neatitikimai.

Šiame etape niekas netaisyta.


## HIGH / ASSESSMENT INTEGRITY — practice žymos apėjimas yra realus dabartiniame assessment

LD8 yra aktyvus assessment darbas, todėl čia restarto semantika jau turi tiesioginę įtaką įskaitomumui.

Patvirtinta seka:

1. LD8 startuoja su `assessment=%t`, `practice_used=%f`.
2. Pavyzdys UI yra pasiekiamas ir assessment režime.
3. `ld8_toggle_solution()` parodo kanoninį sujungimą / matavimą ir nustato `practice_used=%t`.
4. Jei report būtų išsaugotas dabar, jis teisingai nebūtų parinktas suvestinei.
5. Tačiau `ld8_restart()` kviečia `ld8_init_state()`, kuris tiesiogiai nustato:
   - `assessment=%t`;
   - `practice_used=%f`.
6. Studentas lieka tame pačiame variante ir gali pateikti naują reportą kaip formalų assessment.

Vadinasi dabartinė practice apsauga gali būti apeita vien „Pavyzdys → Iš naujo“ seka, nekeičiant failų ranka.

Jei restartas sąmoningai laikomas nauju bandymu, formaliam assessment vis tiek reikia sprendimo, ar po to paties varianto sprendimo peržiūros tas naujas bandymas gali būti įskaitinis. Dabartinis kodas jį įskaito.
