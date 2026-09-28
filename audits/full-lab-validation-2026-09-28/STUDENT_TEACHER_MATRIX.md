# Studento → dėstytojo workflow matrica

Data: 2026-09-28  
Būsena: auditas, funkcinis kodas nekeistas.

## LD1–LD12 studento srautas

| LD | Etapai | Tikras assessment paleidime | Assessment neišduoda teisingumo vietoje | Autosave realiame sraute | Tęsti juodraštį UI | Pavyzdys pažymimas / blokuojamas | Ataskaita | Rubrika |
|---|---:|---|---|---|---|---|---|---:|
| LD1 | 9 | TAIP | TAIP | TAIP | TAIP | assessment režime blokuojamas; mokymosi režimas palieka practice žymą | TAIP | 15 (guided), 22 legacy/manual |
| LD2 | 12 | TAIP | TAIP | TAIP | TAIP | assessment režime blokuojamas; mokymosi režimas palieka practice žymą | TAIP | 50 |
| LD3 | 6 | **NE** | **NE** | **NE** | **NE** | **Pavyzdys rodo teisingus atsakymus, bet practice_used nenustato** | TAIP | 15 |
| LD4 | 7 | **NE** | **NE** | **NE** | **NE** | practice_used nustatomas | TAIP | 27 |
| LD5 | 6 | **NE** | **NE** | **NE** | **NE** | practice_used nustatomas | TAIP | 16 |
| LD6 | 6 | **NE** | **NE** | **NE** | **NE** | practice_used nustatomas | TAIP | 25 |
| LD7 | 6 | **NE** | **NE** | **NE** | **NE** | practice_used nustatomas | TAIP | 27 |
| LD8 | 6 | TAIP | TAIP | TAIP | TAIP | practice_used nustatomas | TAIP | 21 |
| LD9 | 6 | **NE** | **NE** | **NE** | **NE** | practice_used nustatomas | TAIP | 28 |
| LD10 | 6 | **NE** | **NE** | **NE** | **NE** | practice_used nustatomas | TAIP | 28 |
| LD11 | 6 | **NE** | **NE** | **NE** | **NE** | practice_used nustatomas | TAIP | 20 |
| LD12 | 6 | **NE** | **NE** | **NE** | **NE** | practice_used nustatomas | TAIP | 19 |

Pastaba: bendras `bench_mode()` moka įrašyti `assessment` lauką ir LD3–LD7/LD9–LD12, tačiau jų realus `student_primary()` šios būsenos nenaudoja ir vis tiek reikalauja vietoje teisingai išspręsto atsakymo. Todėl vien `assessment=true` pridėjimas nėra pakankamas taisymas.

## Dėstytojo workflow palyginimas

| Savybė | DESTYTOJUI.sce / ldcheck | mokytojas --ui |
|---|---|---|
| Tas pats C++ graderis | TAIP | TAIP |
| Vietinis aplankas | TAIP, native folder picker per Scilab | TAIP, kelias įvedamas tekstu |
| Google Drive | NE šiame kelyje | TAIP, bet tik API key modelis |
| Rezultatų vieta | naujas `Vertinimai-...` įvesties aplanke | proceso current working directory |
| Tiksli SHA kopija | duplicate pagal submission duomenis | praleidžiama pagal failo SHA256 |
| Tas pats submission_id, skirtingi duomenys | **conflict, balas sustabdomas** | **konflikto neaptinka** |
| Geriausio bandymo studento raktas | pilnas student objektas (nr+vardas+grupė) + LD | vardas+grupė + LD |
| Learning/practice neįskaitomas | TAIP | TAIP |
| HTML studento tekstas escapinamas | TAIP | **NE ZURNALAS naršyklės lentelėje** |
| Rankinis pažymio pataisymas su istorija | NE | NE |
| Sustabdymas / saugus uždarymas | batch cancel/checkpoint | worker cancel/join testuotas |
| Pakartotinio vertinimo įvesties švara | ankstesni `Vertinimai-*` gali patekti į recursive scan kaip review | SHA žurnalas deduplikuoja jau vertintus failus |

## Kritiniai vientisumo radiniai

### 1. Studentų pakete yra dėstytojo vertintuvas ir etalonai

Studentams skirtuose paketuose yra:
- `DESTYTOJUI.sce`;
- `bin/ldcheck`;
- `bin/mokytojas`;
- bendras `ldcore`, kuriame sukompiliuotas graderis;
- Scilab šaltiniai su dalimi `*_expected_answers` logikos.

Realiu studento paketo `ldcheck` bandymu klaidingai LD12 ataskaitai sugeneruotas dėstytojo `vertinimai.html` parodė tikslų atsakymo etaloną.

Be to, `report_html()` studento HTML generavimui pats kviečia `grade(r)`, kad gautų rubrikos etiketes. Tai architektūriškai susieja studento ataskaitos eksportą su pilnu graderiu. Todėl vien `ldcheck` EXE pašalinimas neatskirs atsakymų etalonų nuo studento runtime.

### 2. HTML ataskaitos būseną galima pakeisti po eksporto

Ataskaita nėra kriptografiškai pasirašyta. Realiu `ldcheck` bandymu:
- originalas: `mode=learning`, `practice_used=true`, grade 10.0, `selected_for_summary=false`;
- ranka pakeistas tas pats turinys: `mode=assessment`, `practice_used=false`, grade 10.0, `selected_for_summary=true`.

Taigi `mode`, `practice_used`, `submission_id` ir deklaruota tapatybė yra studento valdomo failo duomenys, ne patikimas įrodymas. `submission_id` konfliktų apsauga saugo nuo atsitiktinių konfliktų, bet nėra apsauga nuo sąmoningo failo redagavimo, nes ID taip pat galima pakeisti.

### 3. Tapatybės raktas tarp dėstytojo UI skiriasi

Empirinis LD12 bandymas tuo pačiu vardu+grupe, bet variantais 1 ir 2:
- `ldcheck`: abu 10.0 ir abu atskiri galiojantys bandymai;
- `mokytojas`: du įrašai `IVERTINIMAI.csv`, bet viena eilutė/vienas LD12 langelis `ZURNALAS.csv`.

Reikia vienos aiškios tapatybės sutarties: grupė + stabilus studento ID / sąrašo numeris (arba LMS ID), o ne skirtingų taisyklių skirtinguose UI.

### 4. Studentų registracija leidžia tekstą, kurio eksportas nepriima

`student_profile.sci` vardo/grupės ilgio neriboja. C++ tekstų riba — 256 UTF-8 baitai.

Empirinis `ld_export_report`:
- 300 ASCII simbolių vardas: FAIL;
- 200 lietuviškų „ą“ (400 UTF-8 baitų): FAIL;
- 200 ASCII simbolių: PASS.

Riba turi būti tikrinama įvedimo metu ir studentui paaiškinta.

## Google Drive dėstytojo importas

Dabartinis `mokytojas`:
- naudoja `GRANDINIU_DRIVE_API_KEY` arba `drive_raktas.txt`;
- nenaudoja OAuth access token;
- Drive sąrašą gauna tik užklausa `'<folder>' in parents`, t. y. tik tiesioginiams aplanko vaikams;
- Google-native failus ignoruoja;
- nerekursuoja į Drive poaplankius;
- nesiunčia resource-key antraštės;
- nesiunčia `supportsAllDrives/includeItemsFromAllDrives`.

Google Drive dokumentacija nurodo, kad API raktas vietoje OAuth tinka viešai / „Anyone with the link“ bendrinamam aplankui. Privačiai vartotojo Drive informacijai reikalinga OAuth autorizacija. Todėl studentų ataskaitoms su vardais ir grupėmis dabartinis Drive kelias nėra tinkamas privatumo modelis.

Papildomai:
- vietinis aplankas skenuojamas rekursiškai, Drive — tik vienas lygis;
- kai kurioms link-shared byloms gali reikėti resource key;
- Shared Drive atvejui Drive API dokumentacija reikalauja papildomų `supportsAllDrives/includeItemsFromAllDrives` parametrų, kurių dabartinis klientas nenaudoja.

## Dėstytojo žmogaus sprendimas

Automatinis vertintuvas:
- nevertina laisvo teksto išvadų semantikos;
- gali palikti `review` / `conflict`;
- neturi integruoto rankinio balo pataisymo/patvirtinimo su dėstytoju, priežastimi, laiku ir ankstesnio automatinio balo išsaugojimu.

Tai būtina pramoniniam oficialaus vertinimo workflow, jei automatinis balas bus laikomas pažymiu, o ne rekomendacija.

## Teigiami patvirtinti dalykai

- C++ graderis nepasitiki studento pateiktais etalonais ar pažymiu; etalonus skaičiuoja iš savo banko/rubrikos.
- Variantas ir ataskaitos parametrai kryžmiškai tikrinami.
- Nežinoma/sugadinta versija negauna automatinio nulio — nukreipiama į review.
- Studentų HTML matomas tekstas generuojant escapinamas.
- CSV apsaugotas nuo skaičiuoklių formulės įterpimo.
- `mokytojas --ui` serveris klausosi tik localhost ir workeris saugiai joininamas uždarant.
- Dėstytojo žurnalo lentelė su normalaus ilgio duomenimis telpa ~900 px pločio lange.
