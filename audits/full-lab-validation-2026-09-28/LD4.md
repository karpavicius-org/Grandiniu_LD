# LD4 auditas — studento UI → dėstytojo UI

Data: 2026-09-28  
Audituotas `main` prieš šį checkpointą: `cd70781f7afaeefe1b85aec64d7bd4695999274c`

## Būsena

LD4 tema, fizikinis modelis ir graderio logika atitinka oficialų darbą **„Tiesinių rezistorių tyrimas“**. Variantų banke faktinės R1/R2 reikšmės deterministiškai laikomos ±5 % nominalų ribose. Matavimų ir iš jų išvestų skaičiavimų vertinimas suprojektuotas gerai.

Tačiau normalus studento kelias, kaip ir LD3, šiuo metu yra mokymosi / savikontrolės, o ne formalus atsiskaitymo kelias. Funkcinis kodas šiame etape nekeistas.

## Patvirtinta kaip veikianti

- Studentas rankiniu būdu sujungia pradinę R1 matavimo grandinę.
- Grandinės topologija tikrinama nepriklausomai nuo laidų paspaudimo krypties.
- R1 ir R2 tiriami trimis U/I taškais.
- Variantų bankas naudoja nominalus ir faktines deterministines rezistorių reikšmes ±5 % ribose.
- Graderis atskirai vertina faktinius U/I matavimus prieš modelį.
- 4 etapo R1m/R2m etalonai skaičiuojami iš studento užfiksuotų U/I taškų, todėl teisingas skaičiavimas iš savo matavimo nėra baudžiamas antrą kartą už matavimo nuokrypį.
- 5 etapo R1/R2 nuolydžiai taip pat skaičiuojami iš studento matavimo taškų.
- 6 etapo Rs vertinamas iš studento faktinio nuoseklaus U/I matavimo.
- Atskirai tikrinami 1 etapo R1 sujungimas ir 6 etapo nuoseklus R1+R2 sujungimas.
- Netinkami, dublikuoti ar papildomi laidai sujungimo įrodyme nepriimami.
- Ataskaita perduoda:
  - R1, R2 ir nuoseklaus jungimo matavimus;
  - studento skaičiavimus;
  - 1 ir 6 etapų faktinius laidus;
  - faktinius ir nominalius parametrus.
- Rubrika turi 27 kriterijus.
- CI realiais GUI callbackais tikrina variantus 1, 17 ir 64, laidų pašalinimą / perjungimą, matavimų rodmenis, raw edit tekstą, realų report export ir 42 geometrijos scenarijus.
- Ankstesnė nepriklausoma variantų patikra nerado ±5 % banko ar bazinių fizikinių neatitikimų.

## CRITICAL — normalus LD4 paleidimas nėra atsiskaitymo režimas

`ld4_student_main()` po registracijos sukuria tik:

`LD4=struct("root",root,"cfg",cfg,"student",st)`

ir kviečia `ld4_start()`.

Nei normalus paleidimas, nei `ld4_init_state()` nenustato:

`LD4.assessment=%t`.

`bench_report_data("LD4")` pagal nutylėjimą kuria:

`mode="learning"`.

Todėl normaliai, net idealiai atlikta LD4 ataskaita:
- įvertinama;
- gauna grįžtamąjį ryšį;
- tačiau **nepatenka į galutinę dėstytojo pažymių suvestinę**.

## CRITICAL — realiame studento UI nėra atsiskaitymo / mokymosi režimo pasirinkimo

Bendra `bench_mode("LD4")` funkcija egzistuoja, tačiau realus LD4 Pagalbos meniu turi tik:
- Kaip sujungti;
- Žemėlapis;
- Pavyzdys;
- Ataskaita;
- Atkurti stendą;
- Iš naujo.

Todėl studentas normaliame produkto kelyje neturi priemonės įjungti `assessment=true`.

## CRITICAL/METHODIC — pagrindinis LD4 srautas visada reikalauja teisingo atsakymo prieš tęsiant

`ld4_student_primary()` neskiria assessment ir learning.

Logika visada:
1. išsaugo studento tekstą;
2. kviečia `ld4_check_step()`;
3. tik jei etapas pažymimas `done=true`, leidžia pereiti toliau.

Dėl to studentas negali:
- pateikti klaidingo, bet užpildyto atsakymo;
- išsaugoti jo kaip formalų atsiskaitymo bandymą;
- gauti balą iš dėstytojo graderio.

Jis verčiamas kartoti iki teisingo rezultato.

Tai neatitinka bendros sistemos deklaruojamos assessment architektūros.

## HIGH — savikontrolė atskleidžia etalonines reikšmes

Klaidingo atsakymo atveju `ld4_check_step()` rodo, pvz.:

- teorinei srovei: `Tikimasi ≈ ... mA`;
- 4 etapo R ir δ: `Tikimasi ≈ ...`;
- 5 etapo nuolydžiams: `Tikimasi ≈ ...`;
- 6 etapo Rs: `Tikimasi ≈ ... (Rs = R1 + R2)`.

Mokymosi režime tai naudinga.

Formaliame atsiskaityme toks elgesys būtų netinkamas, todėl būsimas taisymas negali apsiriboti vien `assessment=true` nustatymu — reikės atskiros primary semantikos.

## HIGH — realiame LD4 nėra autosave / restore produkto srauto

Bendras session mechanizmas LD4 būseną išsaugoti ir atkurti techniškai moka.

Tačiau normalus LD4 paleidimas:
- nenustato `autosave_enabled=true`;
- answer callbacks nekviečia veikiančio produkto autosave kelio;
- Pagalbos meniu neturi „Tęsti išsaugotą darbą“ / automatinio juodraščio atkūrimo.

Todėl bendras mechanizmas egzistuoja, bet studento produkte nėra įjungtas.

## HIGH/UI — instrukcijose trūksta mA → A konversijos keliuose svarbiuose skaičiavimuose

LD4 žurnale srovė rodoma **mA**.

Tačiau studento instrukcijose:

- 4 etapas: `R = U/I`;
- 5 etapas: `R = ΔU/ΔI`;
- 6 etapas: `Rs = U/I`;

ne visur aiškiai parašyta, kad mA reikia paversti į A arba formulėje taikyti ×1000.

Tuo tarpu:
- atsakymo laukas laukia Ω;
- graderis skaičiuoja teisingai su ×1000;
- testai taip pat skaičiuoja su ×1000.

Tai studento instrukcijos, o ne skaitinio branduolio klaida.

LD3 ši vieta suformuluota geriau ir gali būti laikoma gero pateikimo precedentu.

## MEDIUM/HIGH — virtualus stendas leidžia perjunginėti laidus palikus maitinimą įjungtą

Realiame LD4 workflow:
- 2 etape įjungiamas maitinimas ir jungiklis;
- po R1 matavimų jie neišjungiami;
- 3 etape `ld4_set_resistor(2)` automatiškai pakeičia laidus į R2;
- 6 etape studentas faktiniais terminalų callbackais šalina ir prideda laidus į nuoseklų R1+R2 jungimą.

`ld4_terminal_click()` ir `ld4_set_resistor()` neturi apsaugos „pirma išjunkite maitinimą“.

Virtualiame 3–12 V modelyje tai nėra reali elektros trauma, tačiau mokymo požiūriu stendas įtvirtina blogą laboratorinę praktiką:

> grandinės perjungimas / perjungimas laidais atliekamas esant įjungtam šaltiniui.

Industrinio lygio laboratoriniame produkte turėtų būti aiški de-energize-before-rewire semantika arba bent jau automatinis maitinimo atjungimas perjungiant topologiją.

## MEDIUM — R2 grandinė perjungiama automatiškai, o ne studento rankomis

3 etape mygtukas `ld4_set_resistor(2)` tiesiog priskiria:

`LD4.wires = ld4_canonical_wires(2)`.

Studentas:
- rankiniu būdu sujungia R1;
- R2 grandinei laidai permėtomi automatiškai;
- vėliau 6 etape nuoseklų R1+R2 jungimą vėl formuoja rankiniu būdu.

Kadangi oficialus LD4 tikslas yra tiesinių rezistorių tyrimas, o ne būtinai kiekvieno rezistoriaus jungimo technikos kartojimas, tai nėra automatinė klaida.

Tačiau metodikos dokumente reikia sąmoningai nuspręsti, ar:
- automatinis R1→R2 perjungimas yra pageidaujamas ergonominis supaprastinimas; ar
- studentas turi demonstruoti ir antro rezistoriaus sujungimą.

## HIGH — CI patvirtina mokymosi, ne formalų atsiskaitymo kelią

`bench_ld4_workflow()`:
- sukuria LD4 objektą be `assessment=true`;
- vykdo `ld4_start()`;
- kiekviename etape tikisi `done(step)=true`;
- klaidingą atsakymą turi atmesti;
- tik pataisytas atsakymas leidžia judėti toliau.

Targeted GUI testas taip pat specialiai įveda „0“ ir tikrina, kad etapas liktų nebaigtas.

Tai gera mokymosi režimo regresija, bet ne formalios assessment semantikos testas.

Ataskaita po šio workflow eksportuojama nepakeitus režimo į assessment.

## MEDIUM — pavyzdžio apsauga dalinai paruošta geriau nei LD3

`ld4_toggle_solution()` nustato:

`LD4.practice_used=%t`.

Todėl net jei ateityje assessment režimas būtų įjungtas, pavyzdį naudojęs bandymas galėtų būti pašalintas iš galutinės suvestinės.

Tai geresnė situacija nei LD3.

Vis dėlto dabartinis pavyzdys nėra tiesiogiai blokuojamas pagal `assessment`; būsimoje produkto semantikoje reikės aiškiai nuspręsti, ar:
- assessment metu Pavyzdys apskritai nerodomas; ar
- jo atvėrimas sąmoningai paverčia bandymą mokymosi/practice bandymu su aiškiu perspėjimu.

## MEDIUM — Pagalbos „Ataskaita“ galima eksportuoti bet kuriuo momentu, bet studentui nepasakoma, kad ji neįskaitinė

Tai naudinga nebaigtam darbui perduoti.

Tačiau dabartinis normalus LD4 yra `learning`, o UI neturi aiškaus režimo indikatoriaus.

Todėl studentas gali spausti „Ataskaita“ ir pagrįstai manyti, kad pateikė formalų atsiskaitymą, nors dėstytojo suvestinė jį atmes kaip mokymosi bandymą.

## MEDIUM — bendros dėstytojo UI problemos taikomos ir LD4

LD4 taip pat veikia bendri radiniai:

- `ldcheck` ir `mokytojas --ui` skirtingai tvarko vienodą `submission_id` su pakeistu turiniu;
- studento grupavimo raktas tarp dviejų dėstytojo kelių skiriasi;
- `mokytojas --ui` studento vardą/grupę deda į `innerHTML` be escapinimo;
- studentas pats deklaruoja vardą, grupę ir variantą.

## LD4 audito išvada

LD4 matematinė ir vertinimo architektūra yra gera:
- matavimo klaida ir skaičiavimo klaida atskiriamos;
- variantų ±5 % tolerancija modeliuojama prasmingai;
- laidų įrodymai vertinami;
- oficiali LD4 tema atitinka virtualų darbą.

Didžiausios problemos yra studento produkto sraute:

1. nėra realaus assessment starto ir režimo UI;
2. klaidingas atsakymas negali būti pateiktas dėstytojui — studentui iškart rodomas etalonas;
3. nėra produkto autosave/restore;
4. keliuose skaičiavimuose neaiški mA→A konversija;
5. stendas leidžia perjunginėti grandinę palikus maitinimą įjungtą;
6. CI daugiausia patvirtina mokymosi savikontrolės kelią.

Šiame etape niekas netaisyta.
