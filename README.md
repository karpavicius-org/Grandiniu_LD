# Grandinių virtualūs laboratoriniai darbai (Scilab)

Interaktyvūs elektros grandinių laboratoriniai darbai: Scilab sąsaja, bendras C++ branduolys ir automatinis LD1–LD12 ataskaitų vertinimas.

LD12: simetrinė trifazė grandinė — trys vienodi imtuvai žvaigždėje ir trikampyje; Uf = Ul/√3, fazinės ir linijinės srovės, Il = √3·If bei galios P = √3·Ul·Il = 3PY (trikampis tris kartus galingesnis); 64 variantai, šeši etapai ir automatinis 14 kriterijų vertinimas.

LD11: rišlė (R, L) su 50 Hz generatoriumi, ampermetru, voltmetru ir vatmetru; aktyvioji P, reaktyvioji Q ir pilnutinė S galia bei cos φ prieš kompensaciją; teorinis kompensuojantis kondensatorius Ck ir matavimai su juo — P nepakinta, S ir I sumažėja, cos φ artėja į 1; 64 variantai, šeši etapai ir automatinis 20 kriterijų vertinimas.

LD10: lygiagretė RLC grandinė tais pačiais trimis dažnio taškais, ampermetras perkeliamas į keturias padėtis (IR, IL, IC, pagrindinė linija); srovių rezonansas — bendroji srovė minimali, IL = IC; srovių trikampis, laidis Y, cos φ ir galios P, Q, S; 64 variantai, šeši etapai ir automatinis 28 kriterijų vertinimas.

LD9: nuosekli RLC grandinė trimis dažnio taškais (0,5·f0, f0, 2·f0) ir vienu kilnojamu voltmetru (R, L, C, generatorius); įtampų, varžų ir galių trikampiai bei įtampų rezonansas (UL = UC, kokybė Q); 64 variantai, šeši etapai ir automatinis 28 kriterijų vertinimas.

LD8: trijų rezistorių nuoseklus, lygiagretus ir mišrus jungimas; kiekvienai grandinei matuojami U ir I, skaičiuojamos teorinė ir eksperimentinė ekvivalentinės varžos bei lygiagretės grandinės šakų srovės; 64 variantai, šeši etapai ir automatinis 21 kriterijaus vertinimas.

LD7: šaltinis E su vidine varža r, reostatas penkiose padėtyse; išorinė charakteristika U(I), galios kreivė P(R), suderinamumo režimas R = r, tuščiosios eigos ir trumpojo jungimo matavimai; 64 variantai, šeši etapai ir automatinis 27 kriterijų vertinimas. [LD7 Windows ir Linux priėmimo patikra](audits/ld7-f5dd729/README.md).

LD6: E1, nuoseklus, priešpriešinis ir lygiagretus šaltinių jungimas; 64 variantai, šeši etapai ir automatinis 25 kriterijų vertinimas. [Studento eiga](studentui/README.md) · [LD6 pataisų patikra](audits/ld6-1b0f00a-fixes/README.md).

[LD5 pataisos ir Windows/Linux patikra](audits/ld5-c9b18f3-fixes/README.md): gnybtai, gyvi rodmenys, studento eiga ir automatinis ataskaitų vertinimas.

**Studentas pateikia vieną HTML ataskaitą. Dėstytojas pasirenka darbų aplanką ir gauna balus, klaidų komentarus bei CSV suvestinę.** [Naudojimas, rubrika ir surinkimas](core/README.md). [Naujausia automatinio vertinimo patikra](audits/closure-2026-09-13/README.md).

Windows / Linux paketai su C++ branduoliu kuriami [GitHub Actions](https://github.com/karpavicius-org/Grandiniu_LD/actions/workflows/native.yml). macOS Intel ir Apple Silicon tikrinami [atskiroje patikroje](https://github.com/karpavicius-org/Grandiniu_LD/actions/workflows/macos.yml). Kiekviename naujame CI pakete yra `RELEASE.json` su konkrečiu Git commit ir platformos binarų SHA-256. Šaltinių kopijai pirmiausia reikia surinkti branduolį pagal `core/README.md`.

[Stendų ergonomikos auditas](audits/ergonomics-2026-09-13/README.md): LD1–LD3 kontaktų koordinatės, 36 × 40 px paspaudimo zonos, bent 8 px tarpai, laidų sankirtos, langų vaizdai ir C++ patikra. Linux CI tikrina tikrus Scilab langus.

## Studentui

Linux aplinkoje paleiskite:

```bash
./PALEISTI.sh
```

Scilab aplinkoje vykdykite šakninį `STENDAS.sce`. Pasirinkęs darbą studentas
įveda eilės numerį (1–64), vardą ir pavardę bei grupę. Prieš pradedant
parodomos variantui priskirtos reikšmės. Stende rodoma vieno etapo užduotis;
atsiskaitymo režime **Įrašyti ir toliau** išsaugo tikrus atsakymus. Mokymosi režime **Patikrinti** leidžia gauti grįžtamąjį ryšį.

LD1 turi naujus 64 pastovius virtualius variantus. LD2 išlaiko originalų
`LD2-64-A-2026` priskyrimą. Vardas, grupė ir variantas išlieka eksportuose;
LD2 juos išlaiko ir išsaugotame darbe. Pakeitus tik vardą ar grupę atliktas darbas išlieka.

[Naudojimas ir variantai](studentui/README.md). Naujausi naudotini paketai yra konkretaus sėkmingo GitHub Actions paleidimo artefaktai: Windows/Linux – `native.yml`, macOS arm64/x86_64 – `macos.yml`. Repo kataloge `dist/` esantys seni archyvai yra tik istoriniai ir nelaikomi dabartinio `main` leidiniu.

Galutinis priėmimas turi sutapti su paketo `RELEASE.json` nurodytu `source_commit`; vien failo pavadinimas be šio manifesto nelaikomas leidinio tapatybės įrodymu.

## Automatinė patikra

```bash
./PATIKRINTI.sh
```

Komanda pati jungia grandines, atlieka matavimus, įveda atsakymus ir tikrina
etapus. Rankomis spręsti nereikia. Testų langai atidaromi atskirame Scilab
procese ir uždaromi pasibaigus patikrai.

- Visi 64 LD1 variantai tikrinami skaitiniu grandinės sprendikliu.
- Visi 64 LD2 variantai atlieka visus 12 etapų (768 etapų).
- Su 1, 17 ir 64 variantais tiksliniai testai vykdo LD1–LD12 studento srautus per realias callback funkcijas; tikrinami matavimai, ataskaitos, sesijų atkūrimas ir pagrindiniai kraštiniai atvejai.
- Atskiras studento pristatymo testas atidaro ir patikrina visus 12 laboratorinių langų.

Naudojamas **Scilab 2026.1.0**. [LD6 Windows ir Linux patikra](audits/ld6-1b0f00a-fixes/README.md)
apima tikrus valdiklius, geometriją ir ataskaitų vertinimą. Paketų šaltinių SHA256:
[`studentui/tests/results/PATIKRA.json`](studentui/tests/results/PATIKRA.json).
Fizinių ekranų ir visų DPI skalių patikra neatlikta.

## Turinys

- `studentui/` – vienintelis aktyvus šaltinis: bendra studento sąsaja, LD1–LD12
  variantai, elementų numerių registrai (T/B/E/F/V/H/W/D/A kodai) ir automatinė patikra.
- `audits/` – LD2 nepriklausomo kryžminio audito medžiaga, naudota prieš v2.0.
- `dist/` – lokalaus / CI paketavimo išvestis; naudoti galima tik paketą, kurio `RELEASE.json` commit sutampa su priimta Git būsena.

Studento versijos vykdomojo kodo pagrindas – pilni LD1 v1.7 ir LD2 v1.1
paketai, papildyti originaliu LD2 v2 variantų moduliu. Senieji šakniniai
`LD1/` ir `LD2/` medžiai pašalinti (2026-09) – jų istorija išlieka git'e,
o elementų numerių registro architektūra gyvena `studentui/LD1/ld1_ids.sci`
ir `studentui/LD2/ld2_ids.sci`; kiekviena [kodo] nuoroda instrukcijose
mašiniškai tikrinama (`tools/check_instruction_registry.py`, CI testas
`instruction_registry`).

## Pastaba

Studentų sugeneruotos ataskaitos ir asmens duomenys į saugyklą neįtraukiami.

## Plėtra iki 13 LD

[Techninė C++ / Scilab patikra](audits/architecture-2026-09-11/README.md) aprašo
bendrą branduolį, atkuriamus integracijos ir ataskaitų bandymus, rastus trūkumus
bei atviras Windows ir aprobacijos sąlygas.
[Minimalūs priėmimo kriterijai](audits/architecture-2026-09-11/MINIMALUS_PRIEMIMAS.md)
atskiria patikrintas galimybes nuo dar neįgyvendintų produkto reikalavimų.
