# LD1 auditas — studento UI → dėstytojo UI

Data: 2026-09-28  
Audituotas `main` prieš šį checkpointą: `6159b236c299fb66316defb88a974d5d09652c9c`

## Būsena

LD1 skaitinė fizika, variantai, ataskaitos formatas, juodraščio atkūrimas ir automatinis vertinimas techniškai veikia. Funkcinis kodas šiame etape nekeistas.

## Patvirtinta kaip veikianti

- Normalus studento paleidimas reikalauja eilės numerio 1–64, vardo/pavardės ir grupės.
- Variantą deterministiškai parenka eilės numeris; graderis patikrina, kad `student.number == variant`.
- Normalus LD1 paleidimas inicijuoja `assessment=true`.
- Klaidingi, bet sintaksiškai galiojantys studento atsakymai atsiskaitymo režime išsaugomi nepakeisti ir perduodami dėstytojo vertinimui.
- Tušti / ne skaitiniai privalomi laukai neleidžia pereiti toliau.
- Skaičių įvestis priima kablelį arba tašką; formulės / vykdomas kodas nelaikomi skaičiumi.
- Autosave realiame studento kelyje įjungtas; juodraštis išsaugo ne tik atsakymus, bet ir matavimus / būseną.
- Juodraščio atkūrimas išjungia maitinimą ir grąžina studento atsakymus bei etapą; tai tikrinama realiu GUI testu.
- Pavyzdys / sprendimas atsiskaitymo režime blokuojamas. Mokymosi režime demonstracinė būsena izoliuojama nuo studento darbo.
- Studentų HTML ataskaita rodo jų atsakymus, bet nerodo etaloninių atsakymų.
- Studentų tekstas HTML ataskaitoje escapinamas; JSON blokas yra inertinis.
- LD1-2 vertinime automatiniai matavimai ir automatinis jungimas turi 0 balų svorį; jie lieka tik diagnostikai.
- LD1-2 turi 15 studento atsakymų kriterijų. Senos LD1-1 ataskaitos tebėra suderinamos su 22 kriterijų rubrika.
- Scilab batch/`ldcheck` ir `mokytojas` abu normalizuoja skirtingų rubrikų rezultatus iki pažymio iš 10.
- Mokymosi režimas ir `practice_used=true` nepatenka į galutinę pažymių suvestinę.
- Nepriklausoma ankstesnio audito fizikos patikra LD1 variantams nerado bazinių serijinės / lygiagrečios grandinės neatitikimų.
- CI studento GUI testuoja realius variantus 1, 17 ir 64 per visus 9 etapus; tikrina klaidingo atsakymo išlaikymą, report export, juodraštį ir rankinį režimą.

## HIGH — numatytasis atsiskaitymas nevertina oficialaus LD1 pagrindinio praktinio gebėjimo

Oficialiame dalyko apraše LD1 įvardytas **„Elektrinių grandinių jungimas“**.

Tačiau normalus studento paleidimas nustato:
- `assessment=true`;
- `guided=true`.

Pirmasis `ld1_set_step(1)` iš karto vykdo `ld1_guided_prepare()`, kuris:
- automatiškai sudeda kanoninius laidus;
- automatiškai parenka matuoklio režimą;
- kituose etapuose automatiškai nustato VR1;
- matavimo etapuose automatiškai įjungia maitinimą ir atlieka matavimą;
- nustato `guided_used=true`.

Todėl įprasto studento darbo ataskaita tampa `LD1-2`: 15 balų už studento atsakymus, o 5 matavimai + 2 sujungimo kriterijai gauna 0 balų.

Išvada: dabartinis numatytasis LD1 gerai tikrina grandinių atpažinimą, skaičiavimus ir rezultatų interpretavimą, bet **nepatikrina, ar studentas savarankiškai moka sujungti grandinę ir atlikti matavimą**, nors tai yra oficialus LD1 pavadinimas / praktinis tikslas.

Tai metodikos sprendimo reikalaujanti problema, ne skaitinio branduolio klaida.

## HIGH — „Rankinis valdymas“ normaliame paleidime neatkuria pilnos LD1-1 rubrikos

Studentas gali per Pagalbą persijungti į rankinį stendo valdymą.

Tačiau iki tol pirmasis guided etapas jau būna įvykdytas ir `guided_used=true`.

`guided_used` neanuliuojamas persijungus į rankinį valdymą. Ataskaitoje:
- `evidence.automatic_setup=true`;
- rubrika perjungiama į `LD1-2`;
- matavimai ir jungimai lieka 0 balų diagnostika.

Todėl normaliai paleidus LD1 studentas praktiškai negali pasirinkti pilno rankinio 22 kriterijų atsiskaitymo vien tik persijungdamas į „Rankinis valdymas“.

Vėlesniame projektavimo etape reikės aiškiai apsispręsti, ar:
1. LD1 atsiskaitymas sąmoningai lieka 15 atsakymų virtuali užduotis; ar
2. turi egzistuoti tikras rankinis atsiskaitymo kelias, kuriame jungimas ir matavimas vertinami.

## MEDIUM/HIGH — režimo pakeitimas į mokymąsi negrįžtamai diskvalifikuoja bandymą, bet UI to aiškiai nepasako

`bench_mode("LD1")` pasirinkus „Mokymasis“ nustato:
- `assessment=false`;
- `practice_used=true`.

Vėliau grįžus į „Atsiskaitymas“:
- `assessment` vėl tampa true;
- `practice_used` lieka true.

Tokį failą dėstytojo vertintuvai teisingai atpažįsta kaip mokymosi bandymą ir neįtraukia į galutinę suvestinę.

Tačiau pačiame režimo pasirinkimo UI nėra aiškaus perspėjimo, kad pasirinkus mokymosi režimą **šis konkretus bandymas nebegalės būti galutinis atsiskaitymas net sugrįžus į „Atsiskaitymas“**.

Tai gali sukelti studento klaidą be techninės sistemos klaidos.

## MEDIUM — studento tapatybė ir priskirtas variantas nėra susieti su dėstytojo sąrašu

Studento UI leidžia pačiam įvesti:
- vardą/pavardę;
- grupę;
- eilės numerį 1–64.

Graderis patikrina tik vidinį nuoseklumą:
- ataskaitos variantas turi sutapti su įrašytu studento numeriu.

Sistema nepatikrina, ar konkretus vardas/grupė iš tikrųjų turi būtent tokį dėstytojo priskirtą eilės numerį.

Tai reiškia:
- ataskaita yra techniškai vientisa;
- tačiau pati savaime neįrodo studento tapatybės ar oficialiai priskirto varianto.

Šis apribojimas jau iš dalies pripažintas projekto dokumentacijoje („vietinė ataskaita nepatvirtina studento autorystės“), bet dėstytojo darbo srautui vėliau reikės aiškios politikos.

## MEDIUM — du dėstytojo keliai skirtingai grupuoja studentą, jei pakeistas variantas

Scilab batch/`ldcheck` geriausio bandymo raktui naudoja visą `student` objektą kartu su `lab_id`; studento numeris yra tapatybės dalis.

`mokytojas --ui` žurnalas studentą grupuoja pagal:
- vardą;
- grupę;
- laboratorinio darbo ID.

Todėl tas pats vardas+grupė su kitu eilės numeriu / variantu:
- batch kelyje gali tapti atskira studento tapatybe;
- `mokytojas --ui` kelyje gali būti sujungtas į tą patį LD langelį ir pasirinktas geresnis pažymys.

Tai ypač aktualu LD1, nes studentas numerį įveda pats.

## MEDIUM — bendras dėstytojo UI saugumo radinys taikomas ir LD1

`mokytojas --ui` `ZURNALAS.csv` duomenis naršyklėje įterpia per `innerHTML` be HTML escapinimo.

LD1 studento vardas ir grupė yra laisvas tekstas, todėl LD1 ataskaita taip pat gali pernešti HTML į dėstytojo naršyklės lentelę.

Scilab/`ldcheck` `vertinimai.html` studento tekstą escapina ir šios konkrečios problemos neturi.

## LOW/MEDIUM — studento vardo ir grupės ilgio ribos UI ir graderio pusėje nesutampa

`student_profile()` tikrina, kad vardas ir grupė nebūtų tušti, bet nenustato aiškios ilgio ribos.

C++ graderio `text()` tapatybės laukams taiko 256 baitų ribą.

Todėl labai ilgas, studento UI priimtas vardas arba grupė gali:
1. būti įrašyti į HTML ataskaitą;
2. vėliau dėstytojo pusėje gauti `review` / `text_limit`, o ne automatinį pažymį.

Normaliems vardams tai praktiškai neaktualu, bet UI ir importo kontraktas nėra identiškas.

## Dėstytojo pusės LD1 vertinimo stipriosios vietos

- LD1-1 ir LD1-2 lyginami pagal pažymį iš 10, ne pagal skirtingą maksimalių taškų skaičių.
- `practice_used=true` ir `mode=learning` neįtraukiami į žurnalą.
- Studentui klaidingas atsakymas nerodomas kaip „teisingas“ vien todėl, kad automatinis matavimas buvo teisingas.
- 3 ir 4 etapų „sutampa / nesutampa“ kriterijai lyginami su paties studento ankstesniu skaičiavimu, todėl tas pats skaičiavimo netikslumas nėra mechaniškai baudžiamas antrą kartą.
- Scilab batch kelias aptinka tą patį `submission_id` su pakeistu turiniu kaip konfliktą.
- Ataskaitos parametrai tikrinami prieš variantų banką, todėl studentas negali pakeisti R1/R2/R3 ataskaitoje ir gauti balo pagal pakeistus parametrus.

## LD1 audito išvada

Skaitinis ir techninis LD1 pagrindas yra stabilus. Didžiausias klausimas nėra formulėse ar C++ branduolyje, o **atsiskaitymo metodikoje**:

> dabartinis normalus LD1 kelias automatiškai atlieka būtent tą praktinį veiksmą, kurį oficialus LD1 pavadinimas nurodo kaip laboratorinio darbo objektą — elektrinės grandinės sujungimą.

Kol atliekamas tik auditas, niekas nekeista. Šį sprendimą reikia nagrinėti tik po to, kai bus užbaigtas visų LD studento→dėstytojo srauto auditas.
