# LD5 auditas — studento UI → dėstytojo UI

Data: 2026-09-28  
Audituotas `main` prieš šį checkpointą: `35175fbdd0b5df3e5989fc494bae5e03b690a2d1`

## Būsena

Virtualus LD5 techniškai yra nuoseklus **įtampos daliklio** laboratorinis darbas: R1 + kintama RV dalis, trys potenciometro padėtys, U/I matavimai ir daliklio formulės. Fizikinis modelis ir 16 kriterijų graderis yra nuoseklūs.

Tačiau šis virtualus ID nesutampa su oficialiu dalyko numeravimu: oficialiame apraše **įtampos daliklis yra LD6**, o oficialus LD5 yra elementų nuoseklusis / lygiagretusis / mišrusis jungimas. Funkcinis kodas šiame etape nekeistas.

## Patvirtinta kaip veikianti

- Studentas rankiniu būdu sujungia septynių jungčių įtampos daliklio grandinę.
- Laidų topologija tikrinama pagal kanoninį sujungimą, ne vien jungčių skaičių.
- Laidų redagavimas leidžiamas tik 1 etape; pakeitus laidus:
  - anuliuojama ankstesnė etapų būsena;
  - išvalomas matavimų žurnalas;
  - išjungiamas maitinimas ir jungiklis.
- Tai yra geresnė saugaus virtualaus stendo semantika nei LD4 perjungimo sekoje.
- Potenciometro padėtys P1/P2/P3 keičia aktyvią RV dalį deterministiškai pagal variantą.
- Studentas realiai išmatuoja visas tris padėtis.
- Matavimų žurnalas saugo U, I ir padėties indeksą.
- To paties padėties matavimo negalima įrašyti antrą kartą kaip naujo taško.
- C++ graderis nepriklausomai skaičiuoja:
  - RVd;
  - daliklio įtampą;
  - grandinės srovę;
  - reguliavimo diapazoną;
  - RV dalies procentinį santykį.
- Ataskaitoje perduodami faktiniai trijų padėčių U/I matavimai, studento atsakymai ir 1 etapo laidų įrodymas.
- Parametrai tikrinami prieš 64 variantų banką, įskaitant faktines R1/RV reikšmes ir P1/P2/P3.
- Pavyzdžio būsena izoliuojama nuo studento darbo ir report export demonstraciniame režime blokuojamas.
- Pavyzdžio naudojimas pažymi `practice_used=true`.
- Generic snapshot mechanizmas techniškai teisingai atkuria:
  - raw studento tekstą, įskaitant kablelį;
  - matavimų žurnalą;
  - padėtį;
  - laidus;
  - maitinimą atkūrimo metu priverstinai išjungia.
- Targeted testai patvirtina variantus 1/17/64, realius GUI matavimus, kablelio įvestį be Enter, demo izoliaciją, reset, 36 geometrijos scenarijus ir 108 Scilab↔C++ tolerancijos palyginimus.
- Ankstesnėje nepriklausomoje fizikos patikroje daliklio įtampa ir jos monotoniškumas buvo teisingi visiems variantams.

## CRITICAL — normalus LD5 paleidimas nėra atsiskaitymo režimas

`ld5_student_main()` po registracijos sukuria:

`LD5=struct("root",root,"cfg",cfg,"student",st)`

ir kviečia `ld5_start()`.

Normalus kelias nenustato:

`LD5.assessment=%t`.

Todėl `bench_report_data("LD5")` palieka numatytą:

`mode="learning"`.

Net pilnai ir teisingai atlikta LD5 ataskaita:
- gali gauti 16/16 iš graderio;
- tačiau bus mokymosi bandymas;
- nebus pasirinkta galutinei pažymių suvestinei.

## CRITICAL — studento UI neturi režimo pasirinkimo

Bendra `bench_mode("LD5")` funkcija egzistuoja.

Tačiau realiame LD5 Pagalbos meniu nėra:
- Atsiskaitymas;
- Mokymasis;
- režimo perjungimo.

Todėl studentas negali iš standartinio produkto UI sukurti normalaus assessment bandymo.

## CRITICAL/METHODIC — primary visada reikalauja teisingo atsakymo

`ld5_student_primary()` visada:
1. išsaugo atsakymus;
2. kviečia `ld5_check_step()`;
3. tik teisingai užbaigtą etapą leidžia tęsti.

Klaidingas, bet užpildytas atsakymas negali būti išsaugotas kaip formalus studento bandymas dėstytojui.

Tai learning semantika, ne formalus assessment.

## HIGH — klaidos metu studentui rodomas etaloninis atsakymas

Klaidingo atsakymo atveju 2, 4 ir 5 etapuose rodoma:

`Tikimasi ≈ ...`

Todėl būsimas assessment įjungimas negali būti tik boolean pakeitimas. Reikia atskiros elgsenos, kuri:
- patikrina tik pilnumą;
- neatskleidžia teisingumo;
- išsaugo raw atsakymą;
- leidžia graderiui vertinti vėliau.

## HIGH/UI — 5 etapo srovės formulėje neteisingai pateikti vienetai

Studento instrukcija:

`I2 = E/(R1+RVd), mA`

yra dimensijų požiūriu nepilna.

Kai:
- E yra V;
- R yra Ω;

`V/Ω = A`, ne mA.

Kad gauti mA, turi būti aiškiai:

`I2 = E/(R1+RVd) × 1000, mA`

arba studentui turi būti pasakyta, kad rezultatą amperais reikia paversti į mA.

Svarbu:
- C++ graderis skaičiuoja teisingai su ×1000;
- Scilab expected atsakymas taip pat teisingas;
- klaida yra tik studentui rodomoje formulėje / paaiškinime.

Tai gali sistemingai sukelti 1000× klaidą, ypač studentui, kuris vadovaujasi būtent ekrano formule.

## HIGH — CI pilnas workflow testuoja learning, ne produkto assessment kelią

`bench_ld5_workflow()` sukuria objektą be `assessment=true`.

Toliau:
- kiekviename etape kviečia `ld5_student_primary()`;
- tikisi, kad teisingumo tikrinimas pažymės `done=true`;
- klaidingą laidų būseną turi atmesti;
- baigęs eksportuoja ataskaitą nepakeitęs režimo.

Targeted testai net tikrina, kad neteisingas raw `1+2` būtų atmestas ir teisingas skaičius priimtas.

Tai stiprus learning režimo testas, bet ne formalus atsiskaitymo testas.

## HIGH — generic autosave mechanizmas testuojamas, bet nėra realiai įjungtas studento produkte

`tools/test_ld5.sce` ranka nustato:

`LD5.autosave_enabled=%t`

ir tada patvirtina, kad bendras autosave veikia.

Tačiau normalus `ld5_student_main()`:
- nenustato `autosave_enabled`;
- Pagalbos meniu neturi „Tęsti išsaugotą darbą“;
- studento įvedimo callback nėra realus produkto autosave workflow.

Todėl CI įrodo bibliotekos mechanizmą, bet ne jo prieinamumą studentui.

## HIGH/TRACEABILITY — virtualus LD5 yra oficialus LD6, ne oficialus LD5

Oficialiame dalyko apraše:
- LD5 — elementų nuoseklusis, lygiagretusis ir mišrusis jungimas;
- LD6 — įtampos daliklis.

Virtualiame stende:
- **LD5 — įtampos daliklis**;
- virtualus LD8 apima nuoseklų / lygiagretų / mišrų rezistorių jungimą.

Todėl `mokytojas --ui` žurnalo stulpelis **LD5** šiuo metu nėra oficialaus LD5 pažymys.

Jei šis CSV būtų tiesiogiai naudojamas oficialiam pažymių žurnalui, studento įtampos daliklio rezultatas būtų įrašytas į neteisingą laboratorinio darbo numerį.

Galutiniame produkte būtinas aiškus:
- virtualus ID;
- oficialus dalyko ID;
- pavadinimas;
- studijų rezultatas

žemėlapis, o ne vien `LD1..LD13` numeriai.

## MEDIUM — oficialaus LD5 tema virtualiai atsiranda kitame darbe

Virtualus LD8 yra:
- nuoseklus;
- lygiagretus;
- mišrus rezistorių jungimas.

Tai semantiškai daug artimiau oficialiam LD5 nei virtualus LD5.

Todėl galutinis studentų meniu ir dėstytojo žurnalas negali būti interpretuojami kaip tiesioginis oficialių darbų numeravimas, kol mapping nėra įdiegtas produkto lygiu.

## MEDIUM — pavyzdžio apsauga paruošta gana gerai

`ld5_toggle_solution()`:
- izoliuoja studento būseną;
- pažymi `practice_used=true`;
- report demonstraciniame režime neleidžiamas.

Tai reiškia, kad būsimas assessment srautas gali saugiai remtis jau esamu practice žymeniu.

Vis dėlto vartotojui turėtų būti aiškiai pasakyta, kad atvėrus pavyzdį esamas bandymas nebebus galutinis atsiskaitymas.

## MEDIUM — studentui matomos faktinės ir nominalios rezistorių reikšmės skirtinguose UI sluoksniuose

Registracijos / parametrų santrauka labiau akcentuoja nominalias R1/RV reikšmes ±5 %.

Stendo komponentų kortelės rodo faktines konkretaus varianto reikšmes.

2 etapo formulė taip pat naudoja faktines `cfg.R1` ir `cfg.RV`.

Tai matematiškai nuoseklu, bet pedagogiškai reikėtų išlaikyti labai aiškią terminiją:
- nominali reikšmė;
- faktinė modeliuojama reikšmė;
- aktyvi potenciometro dalis RVd.

Kad studentas jų nesumaišytų.

## MEDIUM — laisvos išvados nevertinamos

6 etapas turi tik du choice klausimus:
- ar įtampa reguliuojama sklandžiai;
- ar daliklio dėsnis galioja.

Atskiras argumentuotas studento paaiškinimas automatiškai nevertinamas.

Jei metodikoje pakanka dėsningumo patvirtinimo, tai tinkama. Jei reikalaujama analizuoti matavimo ir teorijos skirtumus, reikės papildomos rubrikos ar dėstytojo peržiūros.

## MEDIUM — bendri dėstytojo UI radiniai taikomi ir LD5

LD5 paveikia bendros problemos:
- skirtinga `submission_id` konfliktų semantika tarp `ldcheck` ir `mokytojas --ui`;
- skirtingas studento grupavimo raktas;
- `mokytojas --ui` neescapintas `innerHTML` studento vardui/grupei;
- studento tapatybė ir variantas nėra patvirtinami pagal oficialų dėstytojo sąrašą.

## LD5 audito išvada

LD5 fizikinis modelis ir graderis yra stabilūs, o virtuali grandinė ergonomiškai suprojektuota gana tvarkingai.

Pagrindinės problemos:

1. nėra realaus assessment paleidimo;
2. studentas negali pateikti klaidingo atsakymo dėstytojui — sistema reikalauja pataisyti;
3. assessment režimui netinka etalonų atskleidimas klaidos metu;
4. autosave mechanizmas egzistuoja, bet nėra produkto sraute;
5. 5 etapo srovės formulėje trūksta ×1000 mA konversijos;
6. virtualus LD5 numeris neatitinka oficialaus LD5 — jis semantiškai yra oficialus LD6;
7. CI patvirtina learning kelią, ne formalų assessment.

Šiame etape niekas netaisyta.
