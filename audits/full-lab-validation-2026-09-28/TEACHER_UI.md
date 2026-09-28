# Dėstytojo UI ir pilnos studentas → dėstytojas grandinės auditas

Data: 2026-09-28
Audituotas main prieš šį checkpointą: 0d6e86860ef063e7f4de391b591d5ef7516edf0d

## Apimtis

Audituota visa grandinė:
studento registracija → laboratorijos būsena → HTML ataskaita → importas → C++ graderis → bandymų agregavimas → Scilab dėstytojo UI → C++ mokytojas --ui → CSV/HTML/atsiliepimai.

Funkcinis kodas šiame etape nekeistas.

## Bendras vertinimas

Stipriausia sistemos dalis yra skaitinis C++ branduolys ir report importo/graderio validacija:
- fiksuotos schemos ir rubrikų versijos;
- variantų banko parametrų kontrolė;
- student.number == variant kontrolė;
- griežti vienetai;
- nežinomų answer/observation ID atmetimas;
- duplicate JSON key atmetimas;
- 2 MiB failo riba;
- gylio ir masyvų ribos;
- formulės / kodas nevykdomi;
- sugadinti failai gauna review/NEVERTINTA, ne automatinį nulį;
- CSV formulės pradžia = + - @ neutralizuojama.

Didžiausios rizikos yra ne fizikos skaičiavimuose, o:
1. formalios assessment eigos nevienodume tarp LD;
2. nepasirašyto studento failo vientisume;
3. studentams platinamame dėstytojo vertintuve;
4. dviejų skirtingų dėstytojo agregavimo modelių semantikoje;
5. oficialaus kurso numeracijos ir virtualių ID neatitikime;
6. mokytojas --ui Drive/UI defektuose.

---

## CRITICAL — tik 3 iš 12 virtualių LD normaliai pradeda assessment režimu

Normalus studento paleidimas assessment režimą inicijuoja:
- LD1;
- LD2;
- LD8.

LD3–LD7 ir LD9–LD12 normaliai paleidžiami be assessment=true, todėl bench_report_data juos eksportuoja kaip mode="learning".

Be to jų realus student_primary visada tikrina teisingumą vietoje ir neleidžia perduoti klaidingo raw atsakymo dėstytojui.

Praktinė pasekmė:
- paprastai paleidus STENDAS.sce, 9 iš 12 virtualių laboratorijų formalios ataskaitos nepatenka į galutinę pažymių suvestinę;
- žalias CI to neparodo, nes dalies darbų workflow prieš exportą ranka nustato assessment=true.

LD2 papildomai gali tyliai pamesti assessment per restartą arba varianto pakeitimą.

---

## CRITICAL — studento HTML nėra autentiškas / pasirašytas pateikimas

HTML ataskaitoje yra inertinis JSON su:
- studento tapatybe;
- variantu;
- raw atsakymais;
- matavimais;
- wiring evidence;
- submission_id.

Schema ir fizika tikrinamos labai gerai, tačiau nėra:
- HMAC;
- skaitmeninio parašo;
- dėstytojo/LMS sugeneruoto vienkartinio pateikimo rakto;
- patikimos serverio pusės pateikimo būsenos.

Todėl studentas gali po eksporto redaguoti JSON ir pakeisti raw atsakymą ar kitą leidžiamą lauką.

Jei dėstytojui pateikiama tik pakeista kopija:
- ldcheck neturi originalo, su kuriuo galėtų aptikti submission_id konfliktą;
- failas bus vertinamas kaip normalus, jei jo struktūra ir kiti laukai galioja.

Submission konflikto logika padeda tik tada, kai tame pačiame batch yra ir originali, ir pakeista to paties ID kopija.

Vietinis/offline HTML todėl nėra patikimas formalios autorystės ar nepakeisto pateikimo įrodymas.

---

## CRITICAL — studento pakete platinamas pats etalonų vertintuvas

tools/package_student.py į studento ZIP įtraukia:
- ldcore;
- ldcheck;
- mokytojas.

Studentui platinamas STENDAS.sce taip pat turi meniu punktą:
„Dėstytojui · automatinis ataskaitų vertinimas“.

Pakete yra ir:
- DESTYTOJUI.sce;
- bench_teacher.sci;
- vidiniai testai / preview įrankiai.

ldcheck vertinimo HTML rodo:
- studento atsakymą;
- etaloną;
- komentarą.

Todėl studentas gali:
1. eksportuoti savo ataskaitą;
2. paleisti dėstytojo vertintuvą lokaliai;
3. pamatyti tikslius etalonus;
4. taisyti atsakymus / reportą;
5. kartoti vertinimą iki norimo rezultato.

Net pašalinus binarą vien paslėpti etalonų nepakanka aukšto vientisumo atsiskaitymui, nes dalis sprendimo logikos yra studento Scilab šaltiniuose ir viešame repo.

Tai reikia spręsti ne „slėpimo“, o patikimo assessment modelio lygiu.

---

## CRITICAL — mokytojas Google Drive importas ištrina failus prieš juos vertindamas

mokytojas_run() Drive kelyje:

1. sukuria laikiną katalogą;
2. parsisiunčia HTML failus į jį;
3. išsaugo jų fs::path į files;
4. kviečia fs::remove_all(tmp);
5. tik po to kviečia process(files,...).

Taigi parsisiųsti failai pašalinami prieš hash_file/read_report.

process() tokio failo nebegali perskaityti ir eina į:
„nepavyko perskaityti“.

Dar blogiau:
- toks hash_file nepavykimas tik padidina failed;
- process() pabaigoje vis tiek grąžina 0.

mokytojas --ui workeris rc==0 interpretuoja kaip:
„Įvertinimas baigtas. Žurnalas ir atsiliepimai paruošti.“

Todėl Drive režimas su realiai gautais failais gali atrodyti sėkmingai baigtas, nors parsisiųsti darbai faktiškai nebuvo įvertinti.

Esami testai tikrina Drive atvejį BE API rakto. Realaus sėkmingo Drive parsisiuntimo→vertinimo testo nėra.

---

## HIGH — Drive kelias ir vietinis kelias elgiasi skirtingai

Vietinis mokytojas importas:
- rekursyvus;
- ieško HTML/HTM;
- ignoruoja kitus failus;
- iki 10000 ataskaitų.

Drive importas:
- skaito tik tiesioginius vieno aplanko vaikus;
- subfolderių nerekur­suoja;
- Google-native objektus praleidžia;
- naudoja API key, ne vartotojo OAuth.

Todėl tokia pati katalogų struktūra lokaliai ir Drive gali duoti skirtingą ataskaitų rinkinį.

API-key modelis taip pat nėra tinkamas numatytasis privačių studentų ataskaitų saugojimo modelis.

---

## HIGH — du dėstytojo keliai nevienodai traktuoja tą patį submission_id

Scilab DESTYTOJUI.sce / ldcheck:
- reportus grupuoja pagal submission_id;
- tiksli kopija → duplicate;
- tas pats ID su kitokiu JSON → conflict;
- abiem konflikto kopijoms automatinis balas panaikinamas.

mokytojas:
- submission_id agregavimo lygyje nenaudoja;
- deduplikuoja pagal viso failo SHA-256;
- pakeistas failas su tuo pačiu submission_id turi kitą hash ir gali būti vertinamas kaip naujas bandymas.

Todėl du oficialiai pateikiami dėstytojo keliai nėra lygiaverčiai.

---

## HIGH — studento tapatybė abiejuose dėstytojo keliuose grupuojama skirtingai

ldcheck geriausio bandymo raktas:
- visas student objektas;
- lab_id.

Student objekte yra ir student.number.

mokytojas ZURNALAS:
- vardas;
- grupė;
- lab_id.

Todėl tas pats vardas+grupė su skirtingu varianto numeriu:
- ldcheck gali tapti dviem atskiromis tapatybėmis;
- mokytojas sujungia į vieną studento/LD langelį.

Tai empiriškai patvirtinta kontroliuojamu bandymu.

---

## HIGH — nėra oficialaus studentų sąrašo / varianto autoriteto

Studentas pats įveda:
- vardą;
- grupę;
- eilės numerį 1–64.

Graderis tikrina vidinį nuoseklumą:
student.number == variant ir parametrai atitinka to varianto banką.

Tačiau sistema neturi autoritetingos lentelės:
vardas + grupė → priskirtas numeris.

Todėl ataskaita nepatvirtina, kad konkretus studentas pasirinko jam skirtą variantą.

---

## HIGH — ZURNALAS.csv numeracija nėra oficialaus kurso numeracija

mokytojas hardcodina stulpelius:
LD1 ... LD13.

Tačiau report lab_id yra virtualaus produkto numeris.

Oficialus kursas turi kitą žemėlapį. Pavyzdžiai:
- repo LD5 → oficialus LD6;
- repo LD6 → oficialus LD7;
- repo LD7 → oficialus LD8;
- repo LD8 → oficialus LD5;
- repo LD9 → oficialus LD10;
- repo LD10 → oficialus LD11;
- repo LD11 → oficialus LD12;
- repo LD12 → oficialus LD13;
- oficialus LD2 lieka fizinis.

Todėl dabartinis ZURNALAS.csv negali būti tiesiogiai naudojamas kaip oficiali 13 laboratorinių pažymių matrica.

Pilnas žemėlapis: OFFICIAL_LD_MAPPING.md.

---

## HIGH — mokytojas --ui turi studento ataskaita → naršyklė XSS paviršių

ZURNALAS.csv studento vardas ir grupė gali turėti HTML tekstą.

Naršyklės UI lentelė statoma taip:
innerHTML = ... '<td>' + cell + '</td>' ...

HTML escaping nevykdomas.

Kontroliuojamu bandymu vardas <b>AUDITAS</b> iš galiojančios ataskaitos išliko ZURNALAS atsakyme ir pateko į innerHTML.

Tai yra lokali studento failo → dėstytojo naršyklės HTML/XSS injekcijos spraga.

Scilab/ldcheck vertinimai.html naudoja html_escape ir šios konkrečios spragos neturi.

---

## HIGH / METHODIC — abu keliai automatiškai parenka geriausią bandymą

ldcheck:
- iš galiojančių assessment bandymų pasirenka didžiausią grade_10.

mokytojas:
- ZURNALAS langelyje taip pat palieka didžiausią grade_10.

Nėra automatinės politikos:
- pirmas bandymas;
- paskutinis bandymas;
- maksimalus N bandymų;
- terminas;
- dėstytojo patvirtintas bandymas.

Todėl dabartinė įdiegta politika faktiškai yra:
„neribotas pateikimų skaičius, galutinis — geriausias“.

Jei tai nėra sąmoningas kurso sprendimas, prieš oficialų naudojimą reikia pasirinkti kitą politiką.

---

## HIGH — pateikimo laikas nėra patikimas akademinis terminas

submission_id laiko dalis generuojama studento kompiuteryje.

IVERTINIMAI.csv Data yra dėstytojo vertinimo momentas, ne patikimas pateikimo laikas.

HTML yra redaguojamas.

Todėl dabartinė sistema negali pati patikimai įrodyti:
- kad pateikta iki deadline;
- kada realiai pateikta;
- kelintas tai leidžiamas bandymas.

Jei terminai svarbūs, pateikimo laikas turi ateiti iš dėstytojo/LMS valdomo kanalo.

---

## HIGH — LD12 rubrikoje dalis „matavimo“ balų nėra realūs studento matavimai

Tai detalizuota LD12.md, bet svarbu ir dėstytojo suvestinei.

Studentas atlieka:
- 1 žvaigždės fazės matavimą;
- 1 trikampio fazės matavimą.

Report sukuria:
- 3 žvaigždės fazių observations kopijuodamas tą pačią reikšmę;
- 3 trikampio fazių observations kopijuodamas tą pačią reikšmę;
- linijinę trikampio srovę tiesiai iš C++ modelio.

Graderis šiuos 7 laukus traktuoja kaip 7 matavimo kriterijus.

Todėl pažymio semantika čia pervertina faktinių studento eksperimentinių veiksmų skaičių.

---

## MEDIUM/HIGH — mokymosi atsiliepimas rodo skaitinį „Įvertinimas“

mokytojas process():
- learning/practice bandymui IVERTINIMAI.csv balo lauką pakeičia į MOKYMASIS;
- ZURNALAS jo neįtraukia.

Tačiau write_feedback() gauna originalų grader verdict v, kuriame grade_10 yra skaičius, ir pirmiau parašo:

„Įvertinimas: 8.7 (balai ...)“

tik po to:
„MOKYMASIS: šis rezultatas neįtraukiamas į pažymių žurnalą.“

Tai gali klaidinti studentą / dėstytoją: istorijos CSV sako MOKYMASIS, o atsiliepimo failas vis tiek pateikia formalų skaitinį „Įvertinimas“.

Jei skaitinis formative score norimas, jis turi būti taip ir pavadintas.

---

## MEDIUM — mokytojas --ui sustabdymas pabaigoje atrodo kaip sėkmingas užbaigimas

/stop nustato cancel=true.

process() nutraukia ciklą, bet grąžina 0.

Workeris rc==0 tada nustato būseną:
done / „Įvertinimas baigtas. Žurnalas ir atsiliepimai paruošti.“

Taigi dalinai sustabdytas batch nėra aiškiai atskiriamas nuo pilnai užbaigto.

Scilab batch šiame taške geresnis: vertinimai.json turi cancelled ir complete laukus.

---

## MEDIUM — Scilab dėstytojo pakartotinis vertinimas surenka ankstesnius rezultatų aplankus

DESTYTOJUI.sce kuria:
studentų_aplankas/Vertinimai-<id>.

Batch inventorizacija yra rekursinė ir renka visus failus prieš kurdama NAUJĄ rezultatų aplanką.

Todėl:
- dabartinio run naujas output nepatenka į savo input;
- bet ankstesni Vertinimai-* jau egzistuoja ir patenka į kitą run inventorizaciją.

Jų vertinimai.html neturi studento ld-data bloko → review.
JSON/CSV → unsupported_file review.

Kiekvienas ankstesnis run gali pridėti triukšmo į kitą vertinimą.

---

## MEDIUM — Scilab sustabdytas batch rodomas kaip „Vertinimas baigtas“

bench_teacher() atšaukus naudoja batch command=3 ir sukuria dalinius failus.

Tačiau po to vis tiek kviečia:
bench_report_saved(..., "Vertinimas baigtas").

Detalus vertinimai.json/HTML žino, kad cancelled, bet pirmasis UI signalas dėstytojui nėra pakankamai aiškus.

---

## MEDIUM — mokytojas --ui rezultatų vietos tekstas netikslus

UI sako:
„Rezultatai rašomi šalia programos“.

Kodas rašo:
- IVERTINIMAI.csv;
- ZURNALAS.csv;
- atsiliepimai/

į proceso current working directory.

Tai gali būti programos katalogas, bet nebūtinai.

Dėstytojas neturi aiškaus output folder pasirinkimo UI.

---

## MEDIUM — mokytojas --ui žada uždarymo mygtuką, kurio puslapyje nėra

Puslapio tekstas sako:
„Lango uždarymas: mygtukas čia arba Ctrl+C terminale.“

Matomi mygtukai yra:
- Įvertinti;
- Sustabdyti.

UI /quit endpoint egzistuoja ir testuojamas, bet puslapyje nėra mygtuko, kuris jį kviestų.

Uždarius tik naršyklės kortelę serverio procesas savaime negauna /quit.

---

## MEDIUM — mokytojas naršyklės CSV parseris nėra pilnas CSV parseris

ZURNALAS.csv HTML lentelė formuojama:
- tekstą skaidant pagal naujas eilutes;
- laukus skaidant pagal '";"'.

Tai veikia tipiniams vardams/grupėms, bet nėra RFC CSV parseris:
- embedded newline gali sulaužyti eilutę;
- dvigubos kabutės nėra normaliai unescape'inamos.

Graderis studento teksto newline sintaksiškai nedraudžia.

Tai nėra pagrindinė rizika, bet sąsaja turėtų rodyti CSV duomenis patikimai.

---

## MEDIUM — studento registracijos ir graderio ilgio kontraktai nevienodi

Studento registracija tikrina, kad vardas/grupė nebūtų tušti.

C++ text() turi 256 UTF-8 baitų ribą.

Todėl labai ilgas vardas gali būti priimtas registruojant, bet ataskaitos eksporte / graderio etape atmestas.

Tai turi būti validuojama įvedimo momentu.

---

## MEDIUM — nėra integruotos žmogaus pataisos / patvirtinimo istorijos

Yra atvejai, kuriems automatika sąmoningai negali būti galutinis arbitras:
- review;
- conflict;
- laisvo teksto išvada;
- ginčytinas matavimas;
- dėstytojo metodinė išimtis.

Nei DESTYTOJUI.sce, nei mokytojas --ui neturi:
- rankinio pažymio pakeitimo;
- priežasties;
- kas pakeitė;
- kada pakeitė;
- ankstesnės vertės;
- patvirtinimo istorijos.

Tai jau nurodyta core/README kaip atviras priėmimo klausimas ir turi būti uždaryta prieš formaliai naudojant kaip pažymių sistemą.

---

## Stipriosios Scilab / ldcheck dėstytojo pusės

- Viena C++ graderio logika visoms platformoms.
- Deterministinis replay.
- Griežta report schema.
- submission conflict kontrolė.
- duplicate kontrolė.
- visi bandymai išlieka matomi.
- learning/practice aiškiai neparenkami suvestinei.
- HTML visus studento tekstus escapina.
- CSV formulės neutralizuojamos.
- partial/cancel būklė įrašoma į vertinimai.json.
- studento failai nemodifikuojami.

Iš dviejų dabartinių dėstytojo kelių šis yra geresnis vientisumo etalonas.

---

## Stipriosios mokytojas pusės

- Persistent IVERTINIMAI.csv istorija.
- Exact-file SHA-256 dedup.
- Patogi studentų × LD matrica.
- Atskiras atsiliepimo failas kiekvienam vertintam bandymui.
- Vietinis importas filtruoja tik HTML ir riboja failų dydį.
- UI serveris bindinamas tik 127.0.0.1.
- Worker thread uždaromas/joininamas per /quit, testuose nepaliekant fono proceso.
- Browser UI gali rodyti realaus batch progresą.

Šias savybes verta išsaugoti, bet semantiką reikia suvienodinti su batch/ldcheck.

---

## Galutinė audito išvada prieš įgyvendinimo etapą

Šiuo metu sistema yra stipri kaip:
- virtualių laboratorijų mokymosi aplinka;
- fizikos/skaičiavimų engine;
- automatinių formuojamųjų atsiliepimų generatorius;
- laboratorinių reportų techninis validatorius.

Ji dar nėra pilnai uždaryta kaip aukšto vientisumo formaliojo vertinimo sistema.

Svarbiausi sprendimai, kuriuos reikės nagrinėti TIK po analizės:
1. vieninga assessment/learning būsenos mašina visiems LD;
2. patikimas pateikimo / autorystės modelis;
3. studento ir dėstytojo paketų / funkcijų atskyrimas;
4. vienas kanoninis dėstytojo agregavimo modelis;
5. oficialaus LD numerio atsekamumas žurnale;
6. bandymų ir terminų politika;
7. LD12 measurement rubric semantika;
8. Drive importo modelis;
9. rankinių dėstytojo pataisų audit trail;
10. UI/saugumo defektų uždarymas.

Šiame dokumente tik užfiksuoti radiniai. Funkcinis kodas nekeistas.


## MEDIUM / PLATFORM RISK — Windows Unicode aplanko kelias `mokytojas` dar nepatikrintas

`mokytojas.exe` Windows entrypoint naudoja `wmain`, todėl komandinės eilutės argumentą gauna kaip UTF-16. Tačiau kodas tada pats konvertuoja jį į UTF-8 `std::string` ir perduoda `mokytojas_run()`.

`mokytojas_run()` vietiniam katalogui naudoja:

`fs::path(arg)`

o ne `fs::path(wchar_t*)` arba aiškų UTF-8 konvertavimą į native Windows path.

Palyginimui, `ldcheck` Windows kelyje iš `wmain` tiesiogiai daro:

`fs::path(argv[1])`

ir taip išlaiko native wide path semantiką.

Dabartiniai `test_mokytojas.py` ir `test_mokytojas_ui.py` tikrina lietuviškus studentų vardus, tačiau testinis darbų katalogas vadinasi paprastai `pateikimai` / `darbai`; lietuviškas ar kitas non-ASCII **aplanko kelias** Windows pusėje nėra atskirai testuojamas.

Todėl šio punkto statusas yra:
- ne patvirtintas gedimas;
- bet reali C++17/Windows path-kontraktų rizika;
- prieš gamybinį Windows naudojimą būtinas konkretus regression testas su katalogu, pvz. `C:\...\Studentų darbai Žąsė\`.

Naršyklės `mokytojas --ui` kelias turi tą pačią riziką: URL forma perduodamas UTF-8 tekstas dekoduojamas į `std::string` ir vėliau eina per tą patį `mokytojas_run()`.


## HIGH / AUDIT TRAIL — stale pažymys po graderio/rubrikos pakeitimo

`mokytojas` persistent istorijos deduplikacija remiasi tik studento HTML failo SHA-256.

`IVERTINIMAI.csv` antraštėje saugoma:
- Nr;
- Data;
- Studentas;
- Grupė;
- LD;
- Variantas;
- Įvertinimas;
- Balai;
- Iš;
- Klaidos;
- Failas;
- SHA256.

Nesaugoma:
- `core_version`;
- `lab_revision`;
- `rubric_version`;
- repo commit / grader build identifikatorius.

Paleidimo pradžioje visi seni SHA įkeliami į `known`, o tas pats failas vėliau praleidžiamas:

`if (known.count(hash)) ... continue;`

Todėl jei:
1. dėstytojas įvertino ataskaitą;
2. graderio formulė/rubrika vėliau pataisyta;
3. tas pats originalus studento HTML vertinamas dar kartą tame pačiame darbo kataloge,

`mokytojas` jo neperskaičiuos — paliks istorinį ankstesnio graderio rezultatą.

Pats `grade()` verdict turi `core_version`, `lab_revision`, `rubric_version`, bet `mokytojas` jų į persistent CSV neišsaugo.

Palyginimui, `ldcheck` naujame output kataloge kiekvieną kartą iš naujo skaito ir vertina reportą dabartiniu graderiu.

Tai svarbu oficialiam žurnalui: rezultato kilmė turi būti atsekama ne tik iki studento failo SHA, bet ir iki konkrečios vertinimo logikos versijos.


## HIGH / DATA SCOPE — persistent žurnalas neturi semestro / kurso atskyrimo

`IVERTINIMAI.csv` ir iš jo statomas `ZURNALAS.csv` neturi laukų:
- course_id;
- studijų dalyko leidimas;
- akademiniai metai;
- semestras;
- grupės kohortos identifikatorius.

`rebuild_zurnalas()` raktas yra tik:

`{studento vardas, grupė} + lab_id`.

Be to `IVERTINIMAI.csv` yra append-only istorija proceso darbo kataloge.

Todėl jei tas pats katalogas naudojamas:
- kitą semestrą;
- kitais akademiniais metais;
- kitai kohortai su tuo pačiu grupės kodu;
- kitam to paties studento kurso kartojimui,

senas bandymas lieka istorijoje ir gali būti pasirinktas kaip „geriausias“ naujame `ZURNALAS.csv`.

Dabartinė architektūra saugi tik esant išorinei darbo tvarkai „vienas atskiras rezultatų katalogas vienam konkrečiam kursui / semestrui / kohortai“. UI šios sutarties neužtikrina ir aiškiai nereikalauja.

Tai reikia spręsti kartu su `course_id`, terminų, bandymų ir vertinimo versijos politika.
