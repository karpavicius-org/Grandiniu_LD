# LD1–LD12 pilno audito kontrolinis taškas

Data: 2026-09-28
Bazinis main SHA: `a3f59a87d8f92ee2d281bb87db93eff0d205c0fe`

## Apimtis

Šiame etape funkcinis kodas nekeičiamas. Fiksuojami tik testų rezultatai, audito įrodymai ir nustatyti neatitikimai.

## Patikrinta

- Windows/Linux CI dabartiniam `main`: PASS.
- macOS arm64/x86_64 CI dabartiniam `main`: PASS.
- C++ testai: 15/15 PASS.
- Automatinės ataskaitos: 769 eksportuotos ataskaitos.
- LD1–LD12: po 64 variantus pilnoje automatinėje eigoje.
- Tikros Scilab GUI sekos vykdytos variantams 1, 17 ir 64.
- Student delivery patikra: LD1–LD12, 1280×720 darbo sritis, 1024×768 ir 900×600 mažų ekranų slinkimas.
- Nepriklausoma LD1–LD8 analitinė fizikos patikra: 2368 papildomi atvejai; LD2 AC paklaida prieš nepriklausomas kompleksines formules ~5.7e-14; LD4 nuokrypiai telpa ±5 %; LD7 galios maksimumas ties R=r.
- Dėstytojo vertinimo grandinė patikrinta: assessment ir learning atskiriami; learning nepatenka į pažymių suvestinę.
- Variantų bankai LD1–LD8 turi po 64 variantus.

## Aukšto prioriteto radiniai

1. LD3–LD7 ir LD9–LD12 realiame studento paleidime neinicijuoja `assessment=true`. `bench_report_data` pagal nutylėjimą nustato `mode="learning"`, todėl realios ataskaitos nepatenka į pažymių suvestinę.
2. CI dalį šio defekto maskuoja: LD9–LD12 testų workflow prieš eksportą ranka nustato `LDx.assessment=%t`.
3. LD3–LD7 ir LD9–LD12 realiame studento paleidime neinicijuoja `autosave_enabled`; jų testai autosave mechanizmą įjungia ranka. Studentui realiame UI taip pat nerasta `Tęsti išsaugotą darbą` funkcija, išskyrus LD1, LD2 ir LD8.
4. LD3–LD7 ir LD9–LD12 pagrindinis srautas naudoja `TIKRINTI` ir reikalauja teisingo atsakymo prieš perėjimą, nors galutinė ataskaita vėliau vertinama balais. LD8 jau turi tikrą assessment srautą, kuris išsaugo ir klaidingus atsakymus.
5. Vienetų/instrukcijų defektai: LD5, LD6, LD7, LD8 ir LD12 keliuose ekrano tekstuose formulės rodo rezultatą mA/mW, tačiau praleidžia ×1000 konversiją.
6. LD9–LD12 GUI komponentų kortelėse realiuose Scilab artefaktuose rodomas literalus `<br>`.
7. LD10, LD11 ir LD12 pasisveikinimo tekstuose likęs nukopijuotas `sujunkite nuoseklią RLC grandinę`; LD10 dažnio pasirinkimo pranešime lieka `voltmetro taikinys`, nors perkeliamas ampermetras.
8. LD12 instrukcijos 2 etape studentui rodo literalų `R = %g Ω`, nes formatavimo argumentas nepaduotas.
9. `studentui/README.md` LD9–LD12 nurodo neegzistuojančius `VARIANTAI.csv`.
10. Oficialus dalyko aprašas turi 13 LD, o virtualus paketas LD1–LD12. Oficialus „Įtampos ir srovės matavimas“ lieka realiojo stendo tema; LD2 papildomai aprėpia oficialių 9–10 tematiką.
11. LD1 numatytasis `guided=true`: stendas pats paruošia jungimą ir matavimus; rankinis režimas yra. Atsiskaitymui tai metodinis sprendimas, ne branduolio klaida.
12. CI artefaktams nenurodytas `retention-days`; numatytasis saugojimas ilgesnis nei reikalinga trumpalaikiams audito artefaktams.

Šis failas yra tarpinis audito kontrolinis taškas, ne galutinė išvada.


## Studento UI → dėstytojo UI auditas

### Patvirtinta studento pusėje

- Registracija: eilės numeris griežtai tikrinamas kaip sveikas 1–64; vardas ir grupė privalomi; prieš darbo pradžią parodomas deterministinis variantas ir jo parametrai.
- LD1 ir LD2 realiame studento paleidime inicijuoja atsiskaitymo režimą bei autosave.
- LD8 realiame studento paleidime turi pilną atsiskaitymo semantiką: klaidingas, bet netuščias atsakymas išsaugomas ir perduodamas dėstytojo vertinimui; mokymosi režime atsakymas tikrinamas vietoje.
- LD3–LD7 ir LD9–LD12 bendras `bench_mode()` techniškai egzistuoja, tačiau realiame UI nėra pasiekiamas ir jų `student_primary()` `assessment` būsenos nenaudoja. Net ranka įjungus `assessment`, eiga vis tiek reikalauja teisingo atsakymo prieš perėjimą.
- LD3–LD7 ir LD9–LD12 realiame paleidime taip pat neįjungia autosave ir UI neturi „Tęsti išsaugotą darbą“. Testai mechanizmą įjungia tiesiogiai, todėl CI nepatvirtina realaus studento kelio.

### Ataskaitos perdavimas

- Studentų HTML generuojamas su inertiniu JSON bloku; matomas HTML tekstas escapinamas, `<` JSON bloke koduojamas, studento įvestis importo metu nevykdoma.
- Failų importas ribojamas 2 MiB, simbolinės nuorodos atmetamos, nežinomos/sugadintos ataskaitos gauna review/NEVERTINTA, o ne 0 balų.
- CSV generavime yra apsauga nuo skaičiuoklių formulės įterpimo (`=+-@` pradžia prefiksuojama apostrofu).

### Dėstytojo UI — du skirtingi keliai

1. `DESTYTOJUI.sce` / `ldcheck`:
   - kuria naują `Vertinimai-...` aplanką;
   - generuoja `vertinimai.html`, `suvestine.csv`, `vertinimai.json`;
   - aptinka vienodą `submission_id` su skirtingais duomenimis kaip `conflict` ir sustabdo automatinį balą;
   - tiksli kopija pažymima `duplicate`;
   - geriausią bandymą parenka tik iš assessment, nenaudojusių practice.

2. `mokytojas --ui`:
   - kuria `IVERTINIMAI.csv`, `ZURNALAS.csv`, `atsiliepimai/`;
   - dublikatus atpažįsta pagal failo SHA-256;
   - realiu bandymu patvirtinta, kad tas pats `submission_id` su pakeistais duomenimis čia **neaptinkamas kaip konfliktas**: abu failai įvertinami, o žurnalas pasirenka geresnį balą. Tai nesutampa su `ldcheck` vientisumo taisykle.
   - `ZURNALAS.csv` studentą grupuoja pagal vardą+grupę; `ldcheck` geriausio bandymo raktui naudoja visą studento objektą, įskaitant numerį. Skirtingo varianto bandymai tarp dviejų dėstytojo kelių gali būti sugrupuoti skirtingai.

### Patvirtinta dėstytojo naršyklės UI saugumo spraga

- `mokytojas --ui` grąžina `ZURNALAS.csv` studento vardą/grupę kaip tekstą, bet JavaScript lentelę kuria su `innerHTML` be HTML escapinimo.
- Kontroliuojamu bandymu galiojanti LD12 ataskaita su studento vardu `<b>AUDITAS</b>` buvo įvertinta 10.0; `/zurnalas` atsakyme žymėjimas išliko neescapintas ir UI rendereris jį perduoda `innerHTML`.
- Tai yra potenciali lokali XSS iš studento ataskaitos į dėstytojo naršyklės sąsają. Scilab/`ldcheck` generuojamas `vertinimai.html` studento tekstą escapina ir šios konkrečios problemos neturi.

### Ergonomikos / nuoseklumo pastabos dėstytojui

- `DESTYTOJUI.sce` ir `mokytojas --ui` turi skirtingą rezultatų modelį ir skirtingus failų pavadinimus; dokumentacijoje jie pristatomi kaip alternatyvos, tačiau šiuo metu nėra semantiškai lygiaverčiai.
- `mokytojas --ui` rezultatų failus rašo į proceso dabartinį darbo katalogą, o UI tekstas sako „šalia programos“. Tai nėra tas pats dalykas visose paleidimo situacijose.
- Scilab vertinimas rezultatų aplanką kuria studentų ataskaitų aplanko viduje. Pakartotinai vertinant tą patį tėvinį aplanką, ankstesni `Vertinimai-*/vertinimai.html` failai patenka į rekursinę inventorizaciją ir gali atsirasti kaip papildomi review įrašai.


## Checkpoint — studento UI → dėstytojo UI grandinė

Fiksavimo momentu `main` prieš šį commitą: `f9c147fb7d9a059b3ec9a1e3ca2f62bce1d02e36`.

Papildomai patvirtinta šiame audito etape:

- Dėstytojui egzistuoja du realūs vertinimo keliai: Scilab `DESTYTOJUI.sce` (batch/`ldcheck`) ir C++ `mokytojas --ui`. Jie naudoja tą patį grader branduolį, bet **ne tą pačią bandymų vientisumo/suvestinės semantiką**.
- `ldcheck` aptinka tą patį `submission_id` su skirtingais duomenimis kaip konfliktą; `mokytojas --ui` deduplikuoja tik pagal viso failo SHA-256, todėl pakeista ataskaita su tuo pačiu submission ID gali būti įvertinta kaip atskiras bandymas.
- `mokytojas --ui` žurnalas grupuoja studentą pagal vardą+grupę, o batch suvestinės parinkimas remiasi pilnesne deklaruota studento tapatybe. Tai gali lemti skirtingą bandymų sugrupavimą tarp dviejų dėstytojo kelių.
- `mokytojas --ui` naršyklės lentelė `ZURNALAS.csv` reikšmes įterpia per `innerHTML` jų neescapindama. Kadangi studento vardas ir grupė yra laisvas tekstas ir patenka į žurnalą, tai yra realus lokalaus HTML/XSS įterpimo paviršius dėstytojo UI.
- Scilab `DESTYTOJUI.sce` vertinimo išvestį kuria studentų darbų aplanko viduje. Kadangi importas yra rekursinis, pakartotinai vertinant tą patį aplanką ankstesnių `Vertinimai-*/vertinimai.html` failai gali būti nuskaityti kaip įvestis ir patekti į review srautą.
- `mokytojas --ui` rezultatų failus rašo į proceso dabartinį darbo katalogą, nors UI vartotojui teigia, kad rezultatai rašomi „šalia programos“. Paleidimo būdas gali pakeisti faktinę rezultatų vietą.
- Šiame etape funkcinis kodas sąmoningai nepakeistas. Radiniai skirti vėlesniam taisymo etapui po pilno studento→dėstytojo srauto audito.
