# CI ir studento paketų auditas

Data: 2026-09-28
Audituotas main prieš šį checkpointą: b9f24f9da18a184df09994cbd1cca67048120c31

## Apimtis

Audituota:
- dabartiniai GitHub Actions workflow;
- studento ir platforminių ZIP kūrimo scenarijai;
- PATIKRA.json manifestas;
- VARIANTAI.csv generavimas;
- repozitorijoje laikomų dist paketų šviežumas;
- dokumentacinių commitų poveikis CI;
- 0 € papildomų GitHub sąnaudų politikos atitiktis.

Funkcinis laboratorijų kodas šiame etape nekeistas.

## CRITICAL — README nuorodos veda į pasenusius trackintus paketus

Repo dist failų istorija rodo:

- dist/Grandiniu_LD-studentui.zip paskutinį kartą atnaujintas 2026-09-23 commit 34245982d2bf1ddf4bc43197c6b17cabfa995432.
- dist/Grandiniu_LD-macOS-arm64.zip paskutinį kartą atnaujintas tame pačiame 2026-09-23 commit.
- dist/Grandiniu_LD-macOS-x86_64.zip paskutinį kartą atnaujintas tame pačiame 2026-09-23 commit.

Tuo tarpu:
- LD8 įvestas 2026-09-24;
- LD9 įvestas 2026-09-24;
- LD10 įvestas 2026-09-25;
- LD11 įvestas 2026-09-25;
- LD12 įvestas 2026-09-25.

README po kiekvieno šių darbų buvo atnaujintas ir dabar aprašo LD1–LD12, bet jo nuorodos vis dar rodo į 2026-09-23 ZIP failus.

Todėl tiesiogiai iš repo README parsisiųstas studento paketas negali būti laikomas dabartinio main atitikmeniu ir chronologiškai yra surinktas dar prieš LD8–LD12 įtraukimą.

## CRITICAL — PATIKRA.json manifestas pasenęs

studentui/tests/results/PATIKRA.json paskutinį kartą atnaujintas 2026-09-23.

Dabartiniame manifeste:
- source_sha256 įrašų: 97;
- LD1–LD7 failai yra;
- LD8–LD12 failų nėra nė vieno.

Dabartinis tools/check_student_package.py sudaro realų dabartinio studentui/ runtime failų rinkinį ir reikalauja:

runtime == set(manifest["source_sha256"])

Kadangi main jau turi LD8–LD12 runtime, ši lygybė švariame dabartinio main checkout'e negali būti teisinga.

Vadinasi esamas package-integrity checker šiuo metu negali patvirtinti dabartinio produkto paketo.

## CRITICAL — check_student_package.py ir dabartinis medis nesuderinti dėl VARIANTAI.csv

Checkeris tiesiogiai reikalauja:
- LD9/VARIANTAI.csv;
- LD10/VARIANTAI.csv;
- LD11/VARIANTAI.csv;
- LD12/VARIANTAI.csv.

Dabartiniame main šių keturių failų nėra.

Tiesioginis GitHub katalogų sąrašas patvirtino, kad LD9–LD12 kataloguose yra .sce/.sci failai, bet VARIANTAI.csv nėra.

Todėl net atnaujinus PATIKRA.json checkerio statinių failų patikra vis tiek sustotų, jei prieš tai CSV nebūtų sugeneruoti.

## HIGH — LD9–LD12 VARIANTAI.csv generuojami tik HEADLESS.sce

Paieška patvirtino, kad:
- mputl(table9,...LD9/VARIANTAI.csv);
- mputl(table10,...LD10/VARIANTAI.csv);
- mputl(table11,...LD11/VARIANTAI.csv);
- mputl(table12,...LD12/VARIANTAI.csv)

yra studentui/tests/HEADLESS.sce.

Dabartiniai GitHub Actions workflow:
- native.yml;
- macos.yml

HEADLESS.sce tiesiogiai nevykdo.

test_automatic_reports.py vykdo AUTMATINIS.sce, ne HEADLESS.sce.
Targeted LD9–LD12 testai VARIANTAI.csv negeneruoja.

Todėl Actions platforminių paketų build'e nėra aiškios garantijos, kad LD9–LD12 VARIANTAI.csv egzistuos prieš package_native.py.

## HIGH — package_native.py rezultatas priklauso nuo prieš tai workspace likusių sugeneruotų failų

package_native.py naudoja:

source.rglob('*')

ir pakuoja visus tuo metu studentui/ medyje esančius tinkamus failus, nepriklausomai nuo to, ar jie trackinti Git.

Tai reiškia:
- jei HEADLESS.sce buvo vykdytas tame pačiame workspace, sugeneruoti VARIANTAI.csv gali patekti į ZIP;
- jei HEADLESS.sce nevykdytas, jų nebus.

Tai build'o reprodukuojamumo problema: paketo turinys priklauso ne tik nuo Git commit, bet ir nuo ankstesnių komandų side-effect.

Dabartiniuose Actions workflow HEADLESS nėra, todėl pasikliauti šiuo side-effect negalima.

## HIGH — package_student.py negali įtraukti ne-trackintų LD9–LD12 CSV net jei jie sugeneruoti

Bendras Windows+Linux package_student.py šaltinių sąrašą ima per:

git ls-files -z studentui

Todėl HEADLESS sugeneruoti, bet Git netrackinami:
- LD9/VARIANTAI.csv;
- LD10/VARIANTAI.csv;
- LD11/VARIANTAI.csv;
- LD12/VARIANTAI.csv

į šaltinių dalį nepatenka.

Iš Windows/Linux platforminių ZIP package_student.py kopijuoja tik šešis binarus:
- ldcore;
- ldcheck;
- mokytojas
abiejoms OS.

CSV iš platforminių ZIP jis neperkelia.

Todėl dabartinis package_student.py pagal savo kodą negali sukurti bendro ZIP, kuris tenkintų dabartinį check_student_package.py LD9–LD12 CSV reikalavimą.

## HIGH — dabartinis Actions apskritai nekuria ir netikrina bendro Grandiniu_LD-studentui.zip

.github/workflows kataloge dabartiniame main yra tik:
- native.yml;
- macos.yml.

native.yml kuria platforminius Grandiniu_LD-Windows.zip / Grandiniu_LD-Linux.zip artefaktus per package_native.py.
macos.yml kuria platforminius Mac paketus per package_native.py.

Nė vienas dabartinis workflow:
- nevykdo tools/package_student.py;
- nevykdo tools/check_student_package.py;
- neatnaujina trackinto dist/Grandiniu_LD-studentui.zip.

Todėl žalias dabartinis CI nėra įrodymas, kad README nurodytas bendras studento ZIP yra dabartinis ar teisingas.

## HIGH — trackintas paketas ir CI artefaktas yra dvi skirtingos release linijos

Dabartinė struktūra turi dvi lygiagrečias platinimo formas:

1. Git repozitorijoje trackinti dist/*.zip, į kuriuos README tiesiogiai nurodo.
2. Actions run artefaktai, kurie kuriami iš naujo kiekvienam funkciniam commit.

Šios dvi linijos automatiškai nesusiejamos.

Rezultatas:
- CI gali patvirtinti naują main;
- README vartotojas gali parsisiųsti seną dist ZIP.

Prieš oficialų platinimą reikia vieno kanoninio release proceso arba mašininio freshness check, kuris neleistų README rodyti į paketą iš kito commit.

## HIGH — studento paketas nėra atskirtas nuo dėstytojo / vidinių testų įrankių

package_native.py studentui skirtame ZIP sąmoningai palieka:
- DESTYTOJUI.sce;
- mokytojas;
- ldcheck;
- bendrus dėstytojo callbackus;
- preview / patikros / testavimo scenarijus, jei jie yra studentui/ medyje.

Tai jau aprašyta TEACHER_UI.md kaip formaliojo vertinimo vientisumo rizika.

Paketavimo lygiu tai taip pat reiškia, kad „studento leidinys“ ir „pilnas vidinis runtime“ šiuo metu nėra atskiri produktai.

## MEDIUM/HIGH — dokumentaciniai audit commitai paleido pilną acceptance

native.yml ir macos.yml turi:

on: push

be paths-ignore audito/dokumentacijos katalogams.

Todėl kiekvienas atskiras LD audito checkpoint commit į main paleido:
- Windows/Linux acceptance;
- macOS Intel/Apple Silicon acceptance;
- papildomą platformos push patikrą.

Funkcinis kodas tarp šių checkpointų nesikeitė.

Audito metu GitHub rodė kelis vienu metu in_progress acceptance run'us ankstesnėms dokumentacinėms main būsenoms.

Tai neprideda atskiro mokamo larger/GPU resurso ir naudoja standartinius runnerius, bet prieštarauja projekto taisyklei vengti nereikalingų/dubliuotų CI paleidimų.

Nuo šio checkpointo audito dokumentų commitams naudojamas [skip ci].

## MEDIUM — native.yml dubliuoja Linux paketų paruošimo darbą

LD6, LD7, LD8, LD9, LD10, LD11 ir LD12 Linux GUI žingsniai kiekvienas atskirai vykdo:

sudo apt-get update
sudo apt-get install -y xvfb x11-utils python3-gi gir1.2-gtk-3.0

Tą pačią priklausomybių instaliaciją galima būtų atlikti vieną kartą prieš visus GUI testus.

Tai nekeičia rezultatų, bet didina run laiką ir nereikalingai naudoja CI resursus.

## MEDIUM — LD4 ir LD5 Linux testai vykdomi pakartotinai

native.yml:
- LD5 turi atskirą Windows testą;
- vėliau „Existing Linux bench geometry“ žingsnyje LD5 vykdomas Linux;
- LD4 Windows testuojamas atskirai ir dar kartą Linux geometry bloke.

Dalį aprėpties galima sugrupuoti racionaliau, bet vėlesniame optimizavime negalima mažinti platforminės patikros kokybės vien dėl minučių.

## MEDIUM — Actions artefaktams nenurodytas retention-days

Visi upload-artifact@v4 žingsniai naudoja numatytą artifact retention.

Trumpalaikėms:
- PNG;
- TSV;
- acceptance JSON;
- tarpinėms logų kopijoms

dabartinis numatytasis saugojimas yra ilgesnis nei būtina kasdieniam CI.

Pagal projekto 0 € politiką vėlesniame įgyvendinime retention turi būti mažiausias praktiškai reikalingas, išlaikant tik aiškiai pasirinktus priėmimo checkpointus ilgiau.

## MEDIUM — nėra release manifesto, susieto su dabartiniu commit

Trackintame studento ZIP vartotojas neturi paprasto kanoninio release failo su:
- repo commit SHA;
- build data;
- Scilab versija;
- platforminių binarų SHA256;
- studento runtime SHA256;
- virtualių LD sąrašu / versijomis.

PATIKRA.json turėjo atlikti dalį šios funkcijos, bet dabar pats yra pasenęs.

Tai apsunkina tikslų atsekamumą, kai dėstytojas ar studentas po kelių savaičių pateikia konkretų ZIP.

## Teigiami dalykai

- Workflows naudoja standartinius runnerių labelius; larger/GPU runnerių nerasta.
- Funkcinis C++/Scilab CI yra platus ir realiai apima Windows, Linux, macOS Intel ir Apple Silicon.
- package_native.py tikrina, kad platforminis ldcore/ldcheck/mokytojas egzistuoja prieš paketavimą.
- package_student.py prieš kopijuodamas platformų binarus kryžmiškai tikrina .sci/.sce šaltinių tapatumą platforminiuose ZIP.
- CI įrodymai funkciniam branduoliui yra geri; problema yra release/paketo atsekamumo sluoksnyje, ne skaitinio branduolio kokybėje.

## Audito išvada

Dabartinį main CI galima laikyti geru funkcinio kodo testavimo mechanizmu, bet negalima automatiškai laikyti, kad repo README nurodyti studento ZIP yra to paties main release.

Prieš platinimą reikės suprojektuoti vieną deterministinę release grandinę:

Git commit → testai → variantų artefaktų generavimas be side-effect priklausomybės → vienas studento paketo aprašas → package-integrity check → manifestas su tuo pačiu SHA → platinimo nuoroda.

Šiame etape tai tik audito išvada; build/workflow kodas nekeistas.


## MEDIUM / SUPPLY CHAIN — Scilab CI instaliatoriai nėra checksum-verifikuojami

C++ trečiųjų šalių priklausomybių kelias yra gerai užrakintas:
- Eigen 5.0.0 turi konkretų SHA-256;
- nlohmann/json 3.12.0 turi konkretų SHA-256;
- archyvo ekstrakcija atmeta symlink/hardlink ir path traversal.

Tačiau Scilab CI diegimas kitoks.

Linux:
- `curl https://www.scilab.org/.../scilab-2026.1.0...tar.xz`;
- checksum nepatikrinamas.

Windows:
- `Invoke-WebRequest https://www.scilab.org/.../scilab-2026.1.0...exe`;
- checksum / Authenticode publisher verifikacija workflow lygyje neatliekama.

macOS:
- DMG gaunamas iš `https://www.utc.fr/~mottelet/scilab/download/2026.1.0/...`;
- checksum ir code-signature/notarization patikra workflow lygyje neatliekama.

HTTPS ir fiksuotas versijos URL mažina riziką, bet reprodukuojamam pramoniniam build'ui neužtenka vien failo pavadinimo.

Vėlesniame CI hardening etape Scilab distribution turi būti tikrinama patikimu paskelbtu digest/signature arba kita deterministine tiekimo grandine.


## MEDIUM / DISTRIBUTION — Windows/macOS projekto paketai nepasirašomi

Repo nerasta:
- Windows `signtool` / Authenticode pasirašymo;
- macOS `codesign` su projekto Developer ID;
- Apple notarization žingsnio.

Studento README macOS tai aiškiai pripažįsta.

Windows pusėje analogiškas nepasirašymo faktas dokumentacijoje neakcentuojamas, nors studentams platinami:
- `ldcore.dll`;
- `ldcheck.exe`;
- `mokytojas.exe`.

Tai nėra skaitinio veikimo klaida, tačiau gali sukelti:
- SmartScreen/reputacijos perspėjimus;
- antiviruso false-positive/trust problemas;
- silpnesnį leidinio kilmės patvirtinimą.

Prieš formalų platinimą reikia nuspręsti, ar studentų programinė įranga turi būti pasirašyta platformų leidėjo sertifikatais.
