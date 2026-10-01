# Laboratorinių darbų stendai studentui

LD1–LD12 naudoja bendrą studento darbo principą: kairėje grandinė ir prietaisai, dešinėje
vieno etapo užduotis ir atsakymai. LD1–LD12 atsiskaitymo režime **Įrašyti ir toliau**
išsaugo jūsų atsakymus. Mokymosi režime **Patikrinti** parodo klaidas.
Papildomi veiksmai ir režimo pasirinkimas yra skiltyje **Pagalba**.

**LD1:** stendas automatiškai sujungia grandinę, parenka varžą ir įrašo matavimą.
Studentas pasirenka grandinės tipą, įrašo savo skaičiavimus ir palygina rodmenis.
**Įrašyti ir toliau** išsaugo atsakymą ir perkelia į kitą etapą; **Atgal** leidžia
jį pataisyti. Tuščias atsakymas nepraleidžiamas, neteisingas skaičius nepakeičiamas
teisingu. Visuose darbuose darbo sritis yra 1280 × 720 px, mygtukų vietos
etapuose nekinta. Mažesniame ekrane naudojamos slinkties juostos, kontaktai nemažinami.
Rankinį jungimą galima pasirinkti per **Pagalba → Daugiau → Automatinis / rankinis
stendo valdymas**. Ataskaitoje nurodoma, kad naudotas automatinis paruošimas.
Automatinio LD1 vertinime skiriama iki **15 balų už studento atsakymus** (LD1-2);
automatinis jungimas ir matavimai papildomų balų nesuteikia. Senos LD1-1 ataskaitos
išlieka suderinamos su ankstesne 22 balų rubrika.

**LD3 – Omo dėsnio veikimas realioje grandinėje:** pradedama atsiskaitymo režimu.
**Įrašyti ir toliau** išsaugo studento raw atsakymą; teisingumą vertina dėstytojo
programa, todėl vietoje teisinga reikšmė neatskleidžiama. Įtampą parinkite U1 / U2 / U3,
maitinimą ir jungiklį valdykite stende. **Pagalba → Mokymosi / atsiskaitymo režimas**
leidžia pasirinkti savikontrolę; mokymosi režime **Tikrinti** parodo klaidas, o pavyzdys
pasiekiamas tik mokymuisi. Kartą pasirinkus mokymąsi ar pavyzdį, practice žyma išlieka
ir toks bandymas neįtraukiamas į pažymių suvestinę. Laidai, matavimai ir atsakymai
automatiškai saugomi vietiniame juodraštyje; tęsti galima per **Pagalba → Tęsti
išsaugotą darbą**. Atkurtas stendas būna be maitinimo. Laido tarpas sankirtoje reiškia,
kad laidai elektriškai nesujungti.

**LD4 – tiesinių rezistorių tyrimas:** pradedama atsiskaitymo režimu. Studentas
išmatuoja po tris R1 ir R2 U/I taškus, apskaičiuoja varžas, nuokrypius, nuolydžius,
laidumą ir nuoseklaus R1+R2 jungimo varžą. Kai srovė rodoma mA, varžai omų vienetais
naudokite **R = 1000·U/I_mA** ir **R = 1000·ΔU/ΔI_mA**. Atsiskaityme užpildytas raw
atsakymas išsaugomas ir jo teisingumą vertina dėstytojo programa; mokymosi režime
**Tikrinti** pateikia savikontrolę. Pavyzdys formaliame atsiskaityme blokuojamas.
Perjungiant į R2 ir pereinant prie nuoseklaus jungimo maitinimas išjungiamas; rankiniu
būdu keisti laidus leidžiama tik be maitinimo. Laidai, matavimai ir atsakymai
automatiškai saugomi vietiniame juodraštyje; tęsti galima per **Pagalba → Tęsti
išsaugotą darbą**. Mokymosi / pavyzdžio žyma po restarto neišnyksta.


**LD5 – įtampos daliklis:** pradedama atsiskaitymo režimu. Sujunkite septynis laidus
pagal **Pagalba → Kaip sujungti**; laidus keiskite tik išjungę maitinimą. Toliau
įjunkite maitinimą, uždarykite jungiklį ir rinkitės **P1 / P2 / P3**. Parinkta padėtis
išryškinama, o **Matuoti** įrašo U ir I į žurnalą. Atsiskaityme užpildytas raw atsakymas
išsaugomas, jo teisingumą vertina dėstytojo programa; mokymosi režime **Tikrinti**
pateikia savikontrolę. 5 etapo srovei mA vienetais naudokite
**I2 = 1000·E/(R1+RVd)**. Pavyzdys formaliame atsiskaityme blokuojamas; mokymosi ar
pavyzdžio žyma po restarto neišnyksta. Laidai, matavimai, padėtis ir atsakymai
automatiškai saugomi vietiniame juodraštyje; tęsti galima per **Pagalba → Tęsti
išsaugotą darbą**. Atkurtas stendas būna be maitinimo. LD5 skaičiavimams ir
ataskaitų vertinimui naudojamas bendras C++ branduolys; yra 64 variantai:
`LD5/VARIANTAI.csv`. Pastaba: šiame techniniame stendo numeravime LD5 yra įtampos
daliklis; oficialaus dalyko darbų numerių susiejimas turi būti tvarkomas atskiru
kurso žemėlapiu, o ne vien techniniu `LD5` identifikatoriumi.

**LD12 – trifazės grandinės: žvaigždė ir trikampis:** šeši etapai, simetrinis
trifazis šaltinis (Ul pagal variantą, 50 Hz) ir trys vienodi imtuvai R. Jungimas
mygtukais [B10] žvaigžde (imtuvai tarp linijų ir neutralio N) ir [B11] trikampiu
(tarp linijų L1–L2, L2–L3, L3–L1); matuojama fazė renkama [B12]–[B14]. Fizika —
trifazė MNA branduolyje (ld_ac kind 6). Studentas skaičiuoja Uf = Ul/√3, fazines
ir linijines sroves, Il = √3·If bei abiejų jungimų galias ir palygina:
P(trikampis) = 3·P(žvaigždė). 64 variantai: `LD12/VARIANTAI.csv`.

**LD11 – aktyvioji, reaktyvioji ir pilnutinė galia; cos φ gerinimas:** šeši
etapai, rišlė (R, L nuosekliai) prie 50 Hz generatoriaus; stende ampermetras,
voltmetras ir vatmetras (P). Režimai [B10] be Ck ir [B11] su Ck — kompensuojančiu
kondensatoriumi lygiagrečiai rišlei. Pirmas matavimas: S = U·I, Q = √(S²−P²),
cos φ = P/S. Studentas apskaičiuoja teorinį Ck = XL/(ω(R²+XL²)) ir palygina:
po kompensacijos P nepakinta, S bei I sumažėja, cos φ → 1 (galios trikampio
susispaudimas). 64 variantai: `LD11/VARIANTAI.csv`, bankas `LD11-64-A-2026`.

**LD10 – lygiagretė RLC grandinė: srovių rezonansas:** šeši etapai, generatorius →
jungiklis → ampermetras → mazgas, kuriame R, L ir C šakos jungiamos lygiagrečiai.
Tie patys trys dažnio taškai [B10]–[B12]; ampermetras perkeliamas mygtukais
[B13]–[B16] (IR, IL, IC šakose ir pagrindinėje linijoje); U vienoda visose šakose.
Ties f0 bendroji srovė minimali (lygi U/R), IL = IC abi viršija ją (srovių
kokybė Q). Skaičiuojami srovių trikampis √(IR²+(IL−IC)²), laidis Y = I/U,
cos φ = IR/I ir galios P, Q, S. Išvados atspindi kontrastą su nuosekliąja grandine.
64 variantai: `LD10/VARIANTAI.csv`, bankas `LD10-64-A-2026`, ataskaitos revizija 1.

**LD9 – nuosekli RLC grandinė: trikampiai ir įtampų rezonansas:** šeši etapai,
viena nuosekli grandinė generatorius → jungiklis → ampermetras → R → L → C.
Dažnis nustatomas mygtukais [B10]–[B12] (0,5·f0, f0, 2·f0); vienas voltmetras
pereina taikiniais [B13]–[B16] (UR, UL, UC, U). Kiekviename taške matuojami I ir
visos keturios įtampos. Skaičiuojami teorinis f0, kokybė Q, įtampų trikampis
√(UR²+(UL−UC)²), varžų Z ir cos φ bei galių P, Q, S. Ties f0 tikrinama UL = UC.
64 variantai: `LD9/VARIANTAI.csv`, bankas `LD9-64-A-2026`, ataskaitos revizija 1.

**LD8 – varžų nuoseklus, lygiagretus ir mišrus jungimas:** šeši etapai, trys studento
sujungiamos grandinės: nuoseklioji (R1→R2→R3), lygiagretė (visos varžos tarp tų pačių
mazgų) ir mišrioji (R1 nuosekliai su lygiagrečiais R2 ir R3). Voltmetro zondai prie
šaltinio galų; kiekvienoje grandinėje matuojami U ir I, žurnale rodoma Re = U/I.
Skaičiuojamos teorinės ir eksperimentinės varžos bei lygiagretės grandinės šakų srovės.
64 variantai: `LD8/VARIANTAI.csv`, bankas `LD8-64-A-2026`, ataskaitos revizija 1.
Pradedama atsiskaitymo režimu: **Įrašyti ir toliau** išsaugo jūsų atsakymą,
o jo teisingumą vertina dėstytojo programa (21 kriterijus). Tuščius laukus reikia
užpildyti. **Pagalba → Mokymosi / atsiskaitymo režimas** leidžia tikrintis;
naudojus mokymąsi ar pavyzdį, ataskaita pažymima mokomąja ir neįtraukiama į
pažymių suvestinę. Naują atsiskaitymą pradėkite iš naujo.
Laidai, matavimai ir atsakymai automatiškai išsaugomi vietiniame juodraštyje;
uždarant išsaugomas ir dar nepatvirtintas įvedimas. Grįžkite per
**Pagalba → Tęsti išsaugotą darbą**. Atkurtas stendas visada būna be maitinimo.
**Pagalba → Studentas ir priskirtos reikšmės** leidžia pakartotinai peržiūrėti duomenis.

**LD7 – įtampos, srovės ir galios suderinamumas:** pradedama atsiskaitymo režimu.
Studentas tiria darbinę grandinę E → jungiklis → ampermetras → reostatas R penkiose
padėtyse P1–P5, tuščiąją eigą ir **virtualų kontroliuojamą trumpąjį jungimą**.
Atsiskaityme užpildytas raw atsakymas išsaugomas, o jo teisingumą vertina dėstytojo
programa; mokymosi režime **Tikrinti** pateikia savikontrolę. Srovės žurnale yra mA,
todėl vidinei varžai naudokite **r = 1000·(U5−U1)/(I1_mA−I5_mA)**. Galiai
**P = U·I_mA** tiesiogiai gaunami mW, o teorinei didžiausiai galiai naudokite
**Pmax = 1000·E²/(4r), mW**. Virtualiam trumpajam jungimui
**Ik = 1000·E/r, mA**. Realiame laboratoriniame stende trumpojo jungimo bandymas
atliekamas tik pagal dėstytojo nustatytą schemą ir srovės ribojimo procedūrą; šio
virtualaus scenarijaus nereikia interpretuoti kaip leidimo trumpinti realų šaltinį.
Laidus galima keisti tik išjungus maitinimą, o režimo keitimas jį išjungia automatiškai.
Pavyzdys formaliame atsiskaityme blokuojamas; mokymosi / pavyzdžio žyma po restarto
neišnyksta. Laidai, režimas, matavimai ir atsakymai automatiškai saugomi vietiniame
juodraštyje; tęsti galima per **Pagalba → Tęsti išsaugotą darbą**. Atkurtas stendas
būna be maitinimo. 64 variantai: `LD7/VARIANTAI.csv`, bankas `LD7-64-A-2026`.
Pastaba: šiame techniniame stendo numeravime LD7 semantiškai atitinka oficialų kurso
LD8; oficialų numerį turi nustatyti atskiras kurso žemėlapis.

**LD6 – nuoseklus ir lygiagretus šaltinių jungimas:** pradedama atsiskaitymo
režimu. Studentas sujungia keturias schemas: E1, nuosekliai, priešpriešiais ir
lygiagrečiai. Režimo keitimas automatiškai išjungia maitinimą; laidus galima
keisti tik be maitinimo. Atsiskaityme užpildytas raw atsakymas išsaugomas, o jo
teisingumą vertina dėstytojo programa; mokymosi režime **Tikrinti** pateikia
savikontrolę. Sroves mA vienetais skaičiuokite su ×1000: pvz.
**I = 1000·(E1+E2)/(R+r1+r2)**, o lygiagrečiai
**I = 1000·U/R**, **I1 = 1000·(E1−U)/r1**, **I2 = 1000·(E2−U)/r2**.
Nevienodų idealizuotų šaltinių tiesioginis lygiagretus jungimas nebūtų tinkamas;
šiame modelyje sroves riboja įtrauktos vidinės varžos r1 ir r2. Neigiamas šaltinio
srovės ženklas reiškia srovę į šaltinį. Pavyzdys formaliame atsiskaityme blokuojamas;
mokymosi / pavyzdžio žyma po restarto neišnyksta. Laidai, režimas, matavimai ir
atsakymai automatiškai saugomi vietiniame juodraštyje; tęsti galima per
**Pagalba → Tęsti išsaugotą darbą**. Atkurtas stendas būna be maitinimo.
C++ branduolys vertina 25 kriterijus; bankas `LD6-64-B-2026`, ataskaitos
revizija 2. Pastaba: šiame techniniame stendo numeravime LD6 yra šaltinių jungimas,
o oficialaus kurso numerių susiejimas turi būti tvarkomas atskiru kurso žemėlapiu.

Pabaigoje spauskite **Išsaugoti ataskaitą**. Langas pasiūlo **Atverti ataskaitą** arba **Atverti ataskaitų aplanką**.
Sukurtą vieną HTML failą iš
naudotojo aplanko `Grandiniu_LD_darbai` persiųskite dėstytojui. Nebaigtą
ataskaitą taip pat galima išsaugoti per Pagalbą. LD1–LD12 juodraščiai saugomi automatiškai
įrašant atsakymus ir pereinant į kitą etapą; juos atverkite per Pagalbą.

Dėstytojui: vykdykite `DESTYTOJUI.sce` ir pasirinkite aplanką su ataskaitomis.
Programa sukuria `vertinimai.html`, `suvestine.csv` ir `vertinimai.json`.
Mokymosi ar pavyzdžio pagalbą naudoję bandymai gauna komentarus, bet neįtraukiami
į atsiskaitymų suvestinę. Skirtingų rubrikų bandymai lyginami pagal pažymį iš 10.

## Paleidimas

Reikia Scilab 2026.1.0 ir jūsų OS atitinkančio paketo su `bin/ldcore.dll`
(Windows), `bin/ldcore.so` (Linux) arba `bin/ldcore.dylib` (macOS). Kompiliatorius studentui nereikalingas.

macOS: pasirinkite paketą pagal Scilab architektūrą (`arm64` arba `x86_64`),
paleiskite `PALEISTI.command` arba Scilab lange vykdykite `STENDAS.sce`.
Paketai nėra pasirašyti Apple Developer sertifikatu ar notarizuoti.

Linux: `./PALEISTI.sh`. Scilab aplinkoje: vykdykite `STENDAS.sce` ir pasirinkite darbą.
Windows: dukart paspauskite `PALEISTI.bat` arba vykdykite `STENDAS.sce` grafiniame
Scilab lange. `bin/ldcheck.exe` skirtas dėstytojo ataskaitų tikrinimui.
Atskirai galima vykdyti atitinkamą `LD1/LD1.sce`–`LD12/LD12.sce` failą.
Paleidiklis ieško įdiegto Scilab; prireikus nurodykite `SCILAB_BIN=/visas/kelias/bin/scilab`.

Paketą platinkite atsisiuntimo nuoroda. Gmail gali blokuoti archyvą dėl jame esančių
DLL, EXE ar BAT failų ([Google taisyklės](https://support.google.com/mail/answer/6590?hl=en)).
Vien toks pranešimas nepatvirtina nei užkrėtimo, nei Scilab lūžio priežasties.
Neišjunkite apsaugos ir nepervadinkite failų blokavimui apeiti.

Prieš pradedant studentas įveda **eilės numerį sąraše (1–64), vardą ir pavardę,
grupę**. Tada parodomos jo variantui priskirtos reikšmės. Patvirtinus jos
naudojamos visuose to darbo etapuose. Vardas, grupė ir varianto numeris matomi
lango viršuje; visos reikšmės pasiekiamos per **Pagalba → Studentas ir priskirtos reikšmės**.

Tas pats eilės numeris visada priskiria tą patį variantą. Keičiant tik vardą ar
grupę atsakymai ir matavimai išlieka. Keičiant numerį, studentui patvirtinus,
pradedamas naujas darbas, kad skirtingų variantų matavimai nesusimaišytų.
Registracijos atšaukimas neatidaro tuščio stendo.

## Variantai

- **LD1-64-A-2026** – naujas šios sąsajos virtualių variantų rinkinys, sukurtas
  pagal vartotojo prašymą. Aštuonios R1 reikšmės × aštuonios R2 reikšmės;
  R3 parenkama pastoviu ciklu iš to paties rinkinio. E = 10 V, VR1 etapai
  lieka 1000, 500 ir 0 Ω. Lentelė: `LD1/VARIANTAI.csv`.
- **LD2-64-A-2026** – grąžintas originalus 64 variantų priskyrimas iš
  `Karpavicius82/Grandiniu_LD`, commit `77e443a471616d9f237307900200f1b5912aadbf`,
  failo `LD2/ld2_variants.sci`. Priskyrimo formulės nepakeistos.
  Lentelė: `LD2/VARIANTAI.csv`.

Tai virtualių darbų parametrai. Jie nėra fizinio laboratorinio modulio vardinės reikšmės.

## Valdymas ir išsaugojimas

- Laidui prijungti spauskite du matomus gnybtus. **Atšaukti laidą** grąžina paskutinį jungimą.
- Šaltinį įjunkite jo kortelėje, matuokite pačiame prietaise.
- LD2 zondus perjunkite per **Nuimti zondus**. Dažnis įvedamas Hz; galima keisti po 1 Hz.
- Neteisingo atsakymo nurodymas rodomas stendo apačioje; LD2 tikrinimo klaida nebeatveria blokuojančio lango.
- Pavyzdys neįskaito rezultatų; **Grįžti į savo darbą** atkuria studento įrašus.
- LD1 baigus **Išsaugoti ataskaitą** sukuria HTML failą su studento duomenimis,
  atsakymais ir matavimais automatiniam dėstytojo vertinimui.
- LD2 **Pagalba → Išsaugoti darbą** išlaiko studento duomenis, variantą, laidus,
  atsakymus ir matavimus `.sod` faile. CSV eksportas prideda `LD2_studentas.csv`.
  Atveriant darbą patikrinama, ar parametrai atitinka išsaugotą variantą.

## Automatinė patikra

Vartotojui spręsti užduočių nereikia:

```bash
./PATIKRINTI.sh
```

Komanda pati atlieka bandymus ir pateikia **PASS** arba **FAIL**. Testų langai
pažymėti **PATIKRA** ir uždaromi pasibaigus bandymui. Naudojamas atskiras Scilab
procesas. Įprastai atidarant studento stendą ši testų seka nevykdoma.
Vienai patikros daliai skirtas 10 minučių laiko limitas; pasibaigus laikui
pateikiama nesėkmė, o ne sėkmės pranešimas.

- `./PATIKRINTI.sh modelis`: visi 64 LD1 variantai tikrinami skaitiniu grandinės
  sprendikliu; visi 64 LD2 variantai nuosekliai atlieka 12 etapų (768 etapų).
  Tikrinamos ir netinkamos registracijos įvestys bei bazinės LD2 regresijos.
- `./PATIKRINTI.sh langai`: variantai 1, 17 ir 64 atlieka LD1 9 ir LD2 12 etapų
  per realių valdiklių funkcijas. Patikrinami įvedimo laukai, mygtukų prieinamumas,
  matavimai, neteisingi atsakymai, pavyzdžio grąžinimas, eksporto ir sesijos
  įrašymas bei atkūrimas, duomenų išlaikymas ir naujo varianto pradžia.
- Žurnalai: `tests/results/modelis.log`, `tests/results/langai.log` ir
  `GUI_PATIKRA_LAST.txt`. Juose aiškiai pažymėtas paskutinis pasiektas etapas.

Valdiklių testas vykdo jų tikras callback funkcijas; jis nesimuliuoja operacinės
sistemos pelės ir klaviatūros įvykių. Vaizdo ir langų tvarkyklės patikrą tai papildo,
jos nepakeičia. `PERZIURA.sce` ir `PERZIURA_LD2.sce` yra tik sąsajos peržiūros,
kuriose registracija praleidžiama; studento darbui naudokite įprastą paleidimą.

## Kilmė ir aplinka

Pagrindas – pilni vietiniai LD1 v1.7 ir LD2 v1.1 paketai; LD2 variantų modulis
grąžintas iš v2 šaltinio. GitHub saugykloje ši versija laikoma `studentui/`,
o pradiniai LD1 ir LD2 šaltiniai išlaikyti atskirai.
Sąsaja yra `student_style.sci`, `student_profile.sci`, `LD1/ld1_student.sci`,
`LD2/ld2_student.sci`. Skaičiavimų ir etapų tikrintuvai išlaikyti.

Tikrinama su Scilab 2026.1.0 Linux. Windows vaizdas šioje aplinkoje netikrintas.
Šiame kompiuteryje rastas Scilab yra `/tmp`; išvalius laikiną katalogą reikės
įdiegto Scilab arba naujo programos kelio.
Aktualios šios sąsajos patikros laikomos šio paketo `tests` kataloge.
Pradinių paketų auditai nevertina vėlesnių sąsajos pakeitimų.
