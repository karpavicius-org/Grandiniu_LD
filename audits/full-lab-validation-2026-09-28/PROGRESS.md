# LD1–LD12 pilno audito kontrolinis taškas

Data: 2026-09-28
Bazinis main SHA: `a3f59a87d8f92ee2d281bb87db93eff0d205c0fe`

## Apimtis

Šiame etape funkcinis kodas nekeičiamas. Fiksuojami tik testų rezultatai, audito įrodymai ir nustatyti neatitikimai.

## Patikrinta

- Funkcinis bazinis SHA `a3f59a87d8f92ee2d281bb87db93eff0d205c0fe`: Windows/Linux acceptance PASS (run `36162442906`) ir macOS arm64/x86_64 PASS (run `36162442730`).
- Nuo `a3f59a...` iki dabartinio `main` audito metu pakeisti tik `audits/full-lab-validation-2026-09-28/*` failai; studento/core/tools/workflow runtime nepakeistas, todėl šis keturių platformų funkcionalumo įrodymas tebėra taikomas dabartiniam runtime.
- C++ testai: 15/15 PASS.
- Automatinės ataskaitos: 769 eksportuotos ataskaitos.
- LD1–LD12: po 64 variantus pilnoje automatinėje eigoje.
- Tikros Scilab GUI sekos vykdytos variantams 1, 17 ir 64.
- Student delivery bendras langų testas realiai vykdo LD1–LD8; 1280×720 darbo sritis bei 1024×768 ir 900×600 mažų ekranų slinkimas tikrinami šiame delivery teste. LD9–LD12 turi atskirus targeted GUI/geometrijos testus, bet nėra įtraukti į `test_student_delivery.sce` ciklą.
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


## Checkpoint — pateikimo vientisumas ir dėstytojo galutinė eiga

### Kritinis: studento pakete yra dėstytojo etalonų vertintuvas

- `tools/package_native.py` ir `tools/package_student.py` į studentams platinamus paketus sąmoningai įtraukia `ldcheck` ir `mokytojas` binarus.
- `STENDAS.sce` bendrame meniu taip pat rodo punktą „Dėstytojui · automatinis ataskaitų vertinimas“.
- Realiu iš CI studento paketo paimtu `ldcheck` patvirtinta: studento klaidingą LD12 ataskaitą programa įvertina ir `vertinimai.html` parodo „Atsakymas / etalonas“ bei tikslų teisingą skaitinį etaloną.
- Todėl studentas, nekeisdamas programos kodo, gali lokaliai paleisti dėstytojo vertintuvą ir pasižiūrėti atsakymų etalonus.
- Vien binarų pašalinimo nepakaks aukšto vientisumo atsiskaitymui: studento pakete lieka Scilab šaltiniai su `*_expected_answers` ir kita sprendimo logika. Vietinis/offline paketas negali kriptografiškai įrodyti autorystės; projektas tai jau pripažįsta savo R13 priėmimo pastaboje.
- Gamybiniam naudojimui būtina aiškiai atskirti mokymosi paketą nuo patikimo atsiskaitymo modelio arba aiškiai dokumentuoti, kad automatinis vertinimas yra mokomasis/administracinis, o ne apsauga nuo atsakymų išgavimo.

### Tapatybė ir variantas tarp dviejų dėstytojo kelių

Kontroliuojamu realių binarų bandymu pateikti du tobuli LD12 darbai:
- tas pats vardas: `Tas Pats Studentas`;
- ta pati grupė: `EG-1`;
- skirtingi studento/varianto numeriai: 1 ir 2.

Rezultatas:
- `ldcheck`: abu 10.0 ir abu `selected_for_summary=true`, nes geriausio bandymo raktas apima visą studento objektą, įskaitant numerį.
- `mokytojas`: `IVERTINIMAI.csv` turi abu bandymus, bet `ZURNALAS.csv` turi vieną vardas+grupė eilutę ir vieną LD12 langelį 10.0.
- Vadinasi, pakeitus varianto numerį, dvi dėstytojo sąsajos studento tapatybę interpretuoja skirtingai.

### Registracijos ir eksporto ribų neatitikimas

- `student_profile.sci` tikrina, kad vardas ir grupė nebūtų tušti, tačiau jų ilgio neriboja.
- C++ graderio `text()` numatytoji riba — 256 UTF-8 baitai.
- Realiu `ld_export_report` bandymu:
  - 300 ASCII simbolių vardas → eksportas FAIL, failas nesukuriamas;
  - 200 lietuviškų „ą“ (400 UTF-8 baitų) → eksportas FAIL;
  - 200 ASCII simbolių → eksportas PASS.
- Tokia klaida turi būti aptikta registruojant studentą, o ne darbo pabaigoje.

### Pavyzdžio / mokymosi atsekamumas

- LD1 ir LD2 pavyzdžiai atsiskaitymo režime blokuojami; norint juos atverti reikia pereiti į mokymosi režimą, o režimo pakeitimas palieka `practice_used=true`.
- LD4–LD12 pavyzdžio callbackai (išskyrus LD3) tiesiogiai nustato `practice_used=true`, žyma grįžus nenuimama.
- LD3 `ld3_toggle_solution()` parodo ir į būseną įrašo teisingus atsakymus, tačiau `practice_used=true` nenustato.
- Dabartiniu kodu LD3 ataskaita vis tiek pagal nutylėjimą yra `learning`, todėl į pažymių žurnalą nepatenka. Tačiau taisant LD3 assessment režimą šį trūkumą būtina taisyti kartu, kitaip pavyzdžio naudojimas galėtų likti nepažymėtas.

### Dėstytojo UI ergonomika ir atkūrimas

- `mokytojas --ui` realus HTTP testas projekte tikrina paleidimą, būseną, pakartotinį paleidimą, klaidos kelią ir `/quit` iškart po 100 failų batch starto; workeris atšaukiamas/joininamas prieš uždarymą.
- Kontroliuojamame lokaliame UI bandyme `/quit` taip pat tvarkingai uždarė procesą; audito metu fone nepaliktas nė vienas `mokytojas --ui` procesas.
- Atkūrus tikslų dėstytojo lentelės CSS su normalaus ilgio duomenimis, 15 stulpelių žurnalas yra apie 855 px pločio ir telpa net 900 px lange. Horizontalaus slinkimo trūkumo su normaliomis reikšmėmis nelaikome defektu.

### Trūksta žmogaus sprendimo audito grandinės

- Automatinis graderis laisvos teksto išvados turinio semantiškai nevertina.
- `review`, `conflict` ir metodiniai ginčytini atvejai reikalauja dėstytojo sprendimo.
- Nei `DESTYTOJUI.sce`, nei `mokytojas --ui` neturi integruoto rankinio pažymio pataisymo/patvirtinimo su priežastimi ir istorija.
- Projekto `core/README.md` tai jau įvardija kaip atvirą priėmimo klausimą („dėstytojo rankinių pažymio pataisų istorija“). Pramoniniam vertinimo workflow tai turi būti uždaryta prieš oficialų naudojimą.


## Checkpoint — paketas, pateikimo politika ir infrastruktūra

### Studento paketo švara ir atsekamumas

Realiame Linux studento ZIP patvirtinta, kad kartu su stendais platinami ir vidiniai / dėstytojo komponentai:
- `DESTYTOJUI.sce`;
- `bin/ldcheck`, `bin/mokytojas`;
- `GUI_PATIKRA.sce`, `PATIKRINTI.sh`;
- `PERZIURA.sce` ir `PERZIURA_LD2…LD12.sce`;
- `tests/AUTOMATINIS.sce`, `tests/HEADLESS.sce`, `tests/workflows.sci`;
- `capture_window.py`.

Tai nėra švarus studento leidinys ir be reikalo atveria vidinius testavimo/vertinimo mechanizmus.

Pakete taip pat nerastas aiškus release/build manifestas su repo commit SHA, leidinio numeriu ir failų kontrolinėmis sumomis. `studentui/tests/results/PATIKRA.json` repozitorijoje tokį kontekstą turi, bet `package_native.py` visą `results` katalogą iš studento paketo pašalina. Dėl to gavus ZIP sunkiau patikimai nustatyti, kokio commit/CI leidinys naudojamas.

### Bandymų skaičius ir terminai

- `ldcheck` sąmoningai saugo visus bandymus ir suvestinei parenka aukščiausią galiojantį pažymį.
- `mokytojas` taip pat žurnale palieka geriausią pažymį (pagal savo, kitokią tapatybės grupavimo taisyklę).
- Repo schemoje nėra `course_id`, semestro/akademinių metų, deadline, leistino bandymų skaičiaus ar patikimo pateikimo laiko.
- `IVERTINIMAI.csv` stulpelis `Data` pildomas `now_local()` vertinimo momentu, ne studento pateikimo momentu.
- `submission_id` laiko dalis generuojama studento kompiuteryje ir yra redaguojamo HTML JSON dalis.

Todėl sistema pati negali patikimai įgyvendinti „iki termino“, „vienas bandymas“ ar „N bandymų“ politikos. Jei tokia politika reikalinga, pateikimo laikas ir bandymo teisė turi ateiti iš dėstytojo/LMS valdomo kanalo.

### Google Drive importas

- `mokytojas` Drive keliui naudoja tik API key, ne OAuth.
- Google Drive dokumentacija API-key kelią sieja su viešai / „Anyone with the link“ pasiekiamais aplankais; privačiam vartotojo Drive turiniui reikia OAuth autorizacijos.
- Studentų ataskaitose yra vardas, grupė ir rezultatai, todėl viešai per nuorodą bendrinamas ataskaitų aplankas nėra tinkamas numatytasis privatumo modelis.
- Vietinis importas rekursinis, Drive importas skaito tik tiesioginius aplanko vaikus.
- Dabartinis klientas nenaudoja resource-key antraštės ir Shared Drive parametrų `supportsAllDrives/includeItemsFromAllDrives`, todėl dalis link-shared / Shared Drive scenarijų gali neveikti.

### Oficialaus žurnalo numeracija

Empiriškai patvirtinta: repo LD12 (oficialus kurso LD13) `mokytojas` žurnale įrašomas į stulpelį `LD12`, o stulpelis `LD13` lieka tuščias. Kadangi oficialus LD2 lieka fizinis, dabartinis `ZURNALAS.csv` negali būti laikomas oficialia 13 laboratorinių darbų matrica.

Pilna atsekamumo lentelė: `OFFICIAL_LD_MAPPING.md`.

### Repo perkėlimo nuorodos

Po perkėlimo į `karpavicius-org/Grandiniu_LD` aktyviame šakniniame `README.md` tebėra Actions nuorodos į `Karpavicius82/Grandiniu_LD`.
Istoriniuose auditų failuose senas savininkas gali būti paliktas kaip to meto CI įrodymo adresas, tačiau aktualios vartotojui skirtos README nuorodos turi rodyti dabartinę organizacijos saugyklą.


## Kryžminio audito papildymas — ataskaitos pateikimo UX

### HIGH — learning ataskaita vis tiek pateikiama kaip „siųstina dėstytojui“

`bench_export_current(lab)` visiems LD po sėkmingo eksporto nustato būseną „Ataskaita išsaugota“ ir tekstą „Persiųskite šį HTML failą dėstytojui.“. Po to `bench_report_saved()` taip pat rodo bendrą instrukciją „Persiųskite dėstytojui vieną HTML failą.“.

Ši logika neatsižvelgia į `report.mode` ar `practice_used`.

Todėl LD3–LD7 ir LD9–LD12, kurie normaliame studento paleidime eksportuojami kaip `mode="learning"`, po eksporto studentui vis tiek tiesiogiai nurodo siųsti failą dėstytojui, nors toks bandymas vėliau neįtraukiamas į pažymių suvestinę.

Pats HTML viduje teisingai rodo „Mokymasis“, tačiau paskutinio produkto veiksmo instrukcija su tuo nesutampa. Tai stiprina pagrindinį assessment režimo defektą ir gali sukurti realų studento→dėstytojo nesusipratimą.


## Kryžminio audito papildymas — shared-workstation privatumo/tapatybės rizika

- `student_remember(st)` įrašo paskutinį studentą į globalų `BENCH_STUDENT`.
- Kitas `student_enroll()` tame pačiame Scilab procese šį objektą naudoja kaip numatytą ankstesnę registraciją.
- Repo nerasta veiksmo, kuris aiškiai išvalytų `BENCH_STUDENT`.
- Visi studento HTML reportai ir `.sod` juodraščiai pagal nutylėjimą saugomi bendrame to OS vartotojo kataloge `Grandiniu_LD_darbai`.

Jei laboratorijos kompiuteriu keli studentai naudojasi paeiliui su ta pačia OS paskyra, ankstesnio studento vardas/grupė/numeris gali būti pasiūlytas kitam, o vietiniai reportai ir juodraščiai lieka prieinami tame pačiame kataloge.

Individualiame studento kompiuteryje tai daug mažesnė rizika; bendroje auditorijos darbo vietoje reikia aiškios sesijos išvalymo / studento atskyrimo politikos.
