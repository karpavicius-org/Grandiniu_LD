# LD3 auditas — studento UI → dėstytojo UI

Data: 2026-09-28  
Audituotas `main` prieš šį checkpointą: `ac3820d115e52656f577883caf76b72b4fa1d8c5`

## Būsena

LD3 fizikinė logika, Omo dėsnio skaičiavimai, matavimų registravimas ir C++ rubrika yra nuoseklūs. Oficialus dalyko LD3 pavadinimas „Omo dėsnio veikimas realioje elektros grandinėje“ atitinka virtualaus LD3 turinį.

Tačiau normalus studento darbo srautas šiuo metu yra mokymosi, o ne realus atsiskaitymo srautas. Funkcinis kodas šiame etape nekeistas.

## Patvirtinta kaip veikianti

- Studentas pats sujungia 6 kanonines jungtis:
  - šaltinis → jungiklis → ampermetras → R1 → grįžimas;
  - voltmetras lygiagrečiai R1.
- Gnybtų logika riboja netinkamus / perpildytus sujungimus.
- Grandinės sujungimą tikrina atskira topologinė validacija, ne vien laidų skaičius.
- Studentas turi realiai įjungti maitinimą ir jungiklį prieš matavimą.
- Matavimo žurnale fiksuojami trys skirtingi U/I taškai.
- Tas pats įtampos taškas negali būti įrašytas antrą kartą kaip naujas matavimas.
- 4 etape studentas apskaičiuoja R iš kiekvieno faktinio U/I taško ir vidurkį.
- 5 etape R gaunama iš I(U) charakteristikos nuolydžio.
- Instrukcijose aiškiai nurodyta mA → A konversija:
  - `R = U/I`, kai I mA — dalyti iš 1000;
  - nuolydžio formulėje `(I3−I1)/1000`.
- C++ graderis 4 etapo etaloną skaičiuoja iš **studento faktinių išmatuotų U/I reikšmių**, todėl matavimo paklaida nėra mechaniškai baudžiama antrą kartą ir skaičiavimo užduotis vertinama pagal paties studento duomenis.
- Atskirai vertinami patys U/I matavimai prieš modelį.
- 15 kriterijų rubrika logiškai susideda iš:
  - 1 teorinės srovės;
  - 6 matavimų;
  - 4 varžos skaičiavimų;
  - 1 nuolydžio;
  - 2 išvadų;
  - 1 laidų sujungimo.
- Graderis patikrina ataskaitos parametrus prieš 64 variantų banką.
- Variantų fizika ankstesniame nepriklausomame audite nerodė bazinių Omo dėsnio neatitikimų.
- CI realiame GUI variante tikrina, kad paspaudus „TIKRINTI“ edit lauko tekstas būtų nuskaitytas net nepaspaudus Enter.
- CI taip pat patvirtina, kad laikinai klaidingas raw atsakymas („0“) nėra pametamas prieš klaidos parodymą.

## CRITICAL — normalus studento paleidimas nėra atsiskaitymo režimas

`ld3_student_main()` po registracijos sukuria:

`LD3=struct("root",root,"cfg",cfg,"student",st)`

ir kviečia `ld3_start()`.

Nei `ld3_student_main()`, nei `ld3_init_state()` nenustato:

`LD3.assessment=%t`.

`bench_report_data("LD3")` pradinis režimas yra:

`mode="learning"`.

Jis tampa `assessment` tik jei objekte egzistuoja `LD3.assessment` ir jis yra true.

Todėl visiškai teisingai atliktas normalus LD3:
- su teisingais laidais;
- trimis matavimais;
- visais teisingais skaičiavimais;
- teisingomis išvadomis;

eksportuojamas kaip **mokymosi bandymas**.

Dėstytojo batch ir `mokytojas` tokį failą įvertina bei pateikia grįžtamąjį ryšį, tačiau jo **neįtraukia į galutinę pažymių suvestinę**.

Tai yra kritinis studento→dėstytojo grandinės defektas.

## CRITICAL — studento UI neturi būdo pasirinkti atsiskaitymo režimą

Bendra funkcija `bench_mode("LD3")` egzistuoja ir techniškai gali nustatyti:

`LD3.assessment=true`.

Tačiau realaus LD3 Pagalbos meniu yra tik:
- Kaip sujungti;
- Žemėlapis;
- Pavyzdys;
- Ataskaita;
- Atkurti stendą;
- Iš naujo.

Jame nėra „Atsiskaitymo / mokymosi režimas“.

Todėl šis bendras mechanizmas studentui normalioje sąsajoje nepasiekiamas.

Praktiškai iš standartinio `STENDAS.sce → LD3` kelio studentas negali sukurti į galutinę suvestinę tinkamo `mode="assessment"` failo.

## CRITICAL/METHODIC — LD3 atsiskaitymo semantika apskritai neįgyvendinta studento pagrindiniame mygtuke

`ld3_student_primary()` neskaito `LD3.assessment`.

Jo logika visada:
1. išsaugo atsakymą;
2. jei etapas dar nebaigtas — kviečia `ld3_check_step()`;
3. tik jei `done(step)=true` — pereina toliau.

Todėl net ranka ar būsimu UI įjungus `assessment=true`, studentas vis tiek negalėtų pateikti klaidingo atsakymo dėstytojui.

Sistema verstų:
- taisyti atsakymą;
- tikrinti dar kartą;
- kartoti, kol atsakymas tampa teisingas.

Tai prieštarauja pačios sistemos deklaruotai atsiskaitymo architektūrai, kur:
- studento raw atsakymas turi būti išsaugomas;
- teisingumą turi nustatyti dėstytojo programa.

LD3 šiuo metu yra **mokymo stendas su automatine savikontrole**, o ne pilnavertis virtualus atsiskaitymo stendas.

## HIGH — studentui parodoma tiksli / beveik tiksli teisinga reikšmė po klaidos

Kadangi visas srautas naudoja `ld3_check_step()`, klaidingo atsakymo atveju UI rodo, pvz.:

- 2 etapas: `Tikimasi ≈ %.2f mA`;
- 4 etapas: `Tikimasi ≈ <reikšmė>`;
- 5 etapas: `Tikimasi ≈ <R> Ω`.

Mokymosi režime tai naudinga ir logiška.

Tačiau tai reiškia, kad vien tik pridėti `assessment=true` prie starto būtų nepakankama ir metodologiškai klaidinga:
- dabartinis primary vis tiek tikrintų;
- studentui būtų atskleidžiamas etalonas;
- po pakartojimo būtų galima pateikti tik jau pataisytą atsakymą.

Vėlesnis įgyvendinimas turės atskirti learning ir assessment elgsenas, ne tik nustatyti vieną boolean lauką.

## HIGH — CI pilnas LD3 GUI workflow testuoja būtent mokymosi kelią

`studentui/tests/workflows.sci::bench_ld3_workflow()` sukuria LD3 objektą ir kviečia `ld3_start()`.

Jis nenustato `LD3.assessment=%t`.

Toliau kiekviename etape:
- įveda teisingą atsakymą;
- kviečia pagrindinį mygtuką;
- tikisi, kad `LD3.done(step)==true`.

2 etape GUI testas specialiai:
- įveda „0“;
- spaudžia primary;
- tikisi, kad etapas **nepraeis**;
- atstato teisingą skaičių;
- dar kartą spaudžia primary.

Tai labai gerai testuoja mokymosi savikontrolę, tačiau visiškai netestuoja norimos atsiskaitymo semantikos „išsaugoti klaidingą raw ir tęsti“.

Baigęs workflow testas eksportuoja ataskaitą nepakeitęs režimo į assessment.

Taigi žalias GUI CI čia yra ne klaidingas — jis tiesiog patvirtina **kitą produktinį režimą**, nei reikalingas atsiskaitymui.

## HIGH — realiame LD3 nėra autosave

`ld3_student_main()` ir `ld3_start()` nenustato:

`LD3.autosave_enabled=%t`.

LD3 atsakymų keitimo callback taip pat nekviečia `bench_autosave("LD3")`.

Bendras `bench_session.sci` techniškai moka:
- sukurti LD3 snapshot;
- atkurti LD3 snapshot.

Tačiau realiame LD3 studento UI nėra:
- automatinio juodraščio įjungimo;
- „Tęsti išsaugotą darbą“ / „Atverti automatinį juodraštį“ veiksmo.

Todėl sistema turi veikiantį bendrą mechanizmą, kuris nėra prijungtas prie produkto studento kelio.

Sesijos nutrūkimo, Scilab užsidarymo ar kompiuterio gedimo atveju LD3 studentas neturi tokios apsaugos kaip LD1/LD2/LD8.

## HIGH — pavyzdys visada prieinamas ir pats nefiksuoja practice_used

LD3 Pagalbos meniu turi tiesioginį **[B07] Pavyzdys**.

`ld3_toggle_solution()`:
- išsaugo studento būseną backup;
- parodo kanoninį sujungimą;
- įrašo teisingus atsakymus;
- sugeneruoja pilnus matavimų pavyzdžius;
- leidžia grįžti į studento darbą.

Tai geras mokymosi režimo funkcionalumas.

Tačiau pati funkcija:
- netikrina `LD3.assessment`;
- nenustato `LD3.practice_used=%t`.

Šiuo metu tai neleidžia „apgauti“ pažymio tik todėl, kad visas normalus LD3 ir taip yra `learning`.

Tačiau vėlesniame taisyme negalima apsiriboti starto `assessment=true`:
- pavyzdys turėtų būti blokuojamas assessment režime arba
- jo naudojimas privalo pažymėti bandymą kaip practice.

Kitaip pataisius vien režimą atsirastų nauja vertinimo vientisumo spraga.

## MEDIUM/HIGH — „Pradėti iš naujo“ taip pat neturi režimo semantikos

`ld3_restart()`:
- išsaugo cfg ir studentą;
- kviečia `ld3_init_state()`;
- grąžina cfg/student.

Kadangi `ld3_init_state()` neturi assessment/practice/autosave laukų, restartas negeba išlaikyti ar sąmoningai nustatyti darbo režimo.

Dabartiniame produkte tai paslepiama tuo, kad pradinis LD3 vis tiek yra learning.

Kai bus diegiama normali assessment eiga, restartas turės būti įtrauktas į būsenos projektavimą, kitaip LD2 tipo režimo praradimo defektas persikels ir čia.

## MEDIUM — studentui „ataskaita“ prieinama dar nebaigus darbo, bet jo būsena nepaaiškina, kad tai tik mokymosi ataskaita

Pagalbos meniu leidžia bet kada vykdyti:

`bench_export_current("LD3")`.

Tai savaime yra naudinga:
- galima perduoti nebaigtą darbą;
- graderis trūkstamiems kriterijams skirs 0 / missing evidence.

Tačiau dabartinis UI studentui neparodo:
- „Mokymosi režimas“;
- „Ši ataskaita nebus įtraukta į pažymių suvestinę“.

Todėl studentas gali pagrįstai manyti, kad „Ataskaita dėstytojui“ yra formalus atsiskaitymas, nors techniniu požiūriu ji nėra tinkama suvestinei.

## MEDIUM — išvadų dalis yra tik du fiksuoti pasirinkimai

Oficialus LD3 siejamas su Omo dėsnio veikimo analizavimu.

Virtualaus LD3 6 etape studentas atsako tik:
- ar I(U) priklausomybė tiesinė;
- ar R pastovi.

Abu atsakymai yra fiksuoti choice kriterijai.

Atskiras laisvo teksto išvadų laukas LD3 ataskaitoje nenaudojamas (`note=""`).

Tai gali būti pakankama, jei oficialiame darbe reikia tik patvirtinti dėsningumą. Jei studentas turi argumentuoti / interpretuoti rezultatą, dabartinė automatinė rubrika to gebėjimo nevertina.

## MEDIUM — bendri dėstytojo UI radiniai taikomi ir LD3

LD3 ataskaitoms taip pat galioja bendrame audite nustatyta:

- `ldcheck` ir `mokytojas --ui` skirtinga submission konfliktų semantika;
- studento grupavimo skirtumas tarp pilno student objekto ir vardas+grupė;
- `mokytojas --ui` neescapintas `innerHTML` studento vardui/grupei;
- studentas pats įveda vardą, grupę ir variantą, todėl ataskaita savaime nepatvirtina tapatybės.

## Stiprioji LD3 vertinimo architektūros vieta

Svarbi teigiama savybė: graderis skiria:
- **matavimo kokybę**;
- **skaičiavimo pagal paties studento matavimą kokybę**.

Pavyzdžiui, jei studento išmatuota srovė šiek tiek skiriasi nuo idealaus modelio, 4 etapo R etalonas skaičiuojamas iš to studento U/I, o ne iš idealios srovės.

Taip išvengiama dvigubo baudimo:
1. už matavimo nuokrypį;
2. už teisingą skaičiavimą iš to nuokrypio turinčių duomenų.

Tai tinkama laboratorinio darbo vertinimo logika.

## LD3 audito išvada

LD3 fizikos ir graderio dalis yra gera, o oficialus numeris / tema čia sutampa.

Pagrindinė problema yra produkto režimas:

> šiuo metu LD3 yra pilnai veikiantis **mokymosi stendas**, tačiau ne pilnai veikiantis **atsiskaitymo stendas**.

Kad LD3 taptų formaliu atsiskaitymu, vėliau reikės projektuoti kartu:
1. assessment startą;
2. assessment primary semantiką be teisingumo atskleidimo;
3. completeness kontrolę;
4. pavyzdžio blokavimą / practice žymėjimą;
5. autosave/restore;
6. aiškų studento režimo indikatorių;
7. testus, kurie realiai vykdo assessment kelią.

Šiame etape niekas netaisyta.
