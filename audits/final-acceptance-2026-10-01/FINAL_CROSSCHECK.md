# Galutinė kryžminė priėmimo patikra

Data: 2026-10-01  
Bazinis `main`: `285955d1bb305e994499591491582b2de125e4a8`

## Tikslas

Patikrinti perduodamą sistemą nuo studento veiksmo iki galutinio dėstytojo rezultato:

1. studento valdikliai ir callbackai;
2. studento assessment / learning būsena, autosave ir restore;
3. HTML ataskaitos generavimas;
4. C++ graderio schema, variantai, matavimai, wiring ir rubrikos;
5. kanoninis dėstytojo kelias `DESTYTOJUI.sce` / `ldcheck`;
6. papildomas `mokytojas --ui` kelias;
7. Windows / Linux / macOS paleidimas;
8. platforminių ZIP paketų sudėtis ir `RELEASE.json`;
9. studento delivery langai LD1–LD12.

## Statinė būsena prieš pilną CI

- LD1–LD12 turi trackintas `VARIANTAI.csv` lenteles.
- LD3–LD12 formalus assessment kelias atskirtas nuo learning tikrinimo; LD1/LD2 taip pat turi formalų assessment kelią.
- LD1–LD12 juodraščio mechanizmas įjungtas produkto sraute; restore deenergizuoja stendą ten, kur yra maitinimas.
- LD12 ataskaita ir graderis naudoja du realius matavimus (`is`, `id`), rubrika — 14 kriterijų.
- `mokytojas` Google Drive failai neištrinami prieš vertinimą.
- `mokytojas --ui` žurnalo lentelė kuriama DOM `textContent`, ne nepatikimu `innerHTML`.
- `package_native.py` paketą stato iš konkretaus Git commit, prideda `RELEASE.json` ir tikrina 12 variantų lentelių.
- `test_student_delivery.sce` atidaro LD1–LD12.
- `native.yml` naudoja tik standartinius `ubuntu-22.04` ir `windows-2022` runnerius.
- `macos.yml` naudoja standartinius `macos-15` ir `macos-15-intel` runnerius.
- larger/GPU/custom mokamų runnerių nėra.

## Priėmimo kriterijai

Pilnas priėmimas laikomas sėkmingu tik jeigu galutiniam commit:

- CMake/CTest praeina Windows, Linux, macOS arm64 ir macOS x86_64;
- automatinės LD1–LD12 ataskaitos pereina Scilab → HTML → C++ graderį;
- tiksliniai LD1 ir LD4–LD12 GUI testai praeina aktualiose platformose;
- student delivery praeina LD1–LD12 langams;
- `mokytojas` ir `mokytojas_ui` testai praeina;
- LD12 grading testas praeina su 14 kriterijų sutartimi;
- platforminiai paketai sukuriami be trūkstamų runtime failų;
- artefaktų `RELEASE.json.source_commit` sutampa su testuotu commit.

## Semantinis apribojimas

Kanoniniu formalaus vertinimo keliu laikomas `DESTYTOJUI.sce` / `ldcheck`, nes jis turi submission-ID conflict ir selected-for-summary semantiką. `mokytojas --ui` išlieka patogus persistent CSV/Drive įrankis, bet jo istorinis agregavimo modelis nėra naudojamas kaip kanoninės konfliktų semantikos įrodymas.

Kliento HTML nėra kriptografiškai pasirašytas, todėl ši sistema tikrina duomenų schemą, variantą, matavimus ir atsakymus, bet neįrodo failo autorystės prieš tyčinį rankinį redagavimą. Tai yra architektūrinis apribojimas, ne šio CI priėmimo kriterijus.

## Pilno CI būsena

PENDING — šis checkpointas paleidžia galutinį Windows/Linux/macOS acceptance. Rezultatai bus įrašyti po realaus run.
