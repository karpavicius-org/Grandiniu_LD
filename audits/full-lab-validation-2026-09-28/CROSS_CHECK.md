# Kryžminio audito checkpointas

Data: 2026-09-28
Bazinis main prieš šį checkpointą: aac8d0a3048945cf7b066b4cc1f271f3c4d64dd1

## Patikrinta kryžmai

- LD1–LD12 atskiri auditai yra main šakoje.
- Nuo pradinio audito bazės funkciniai studentui/core/tools/workflow failai šiame audito etape nekeisti; pridėta tik audito dokumentacija.
- Oficialus KVK 13 laboratorinių darbų sąrašas dar kartą patikrintas tiesiai prieš dalyko aprašą; OFFICIAL_LD_MAPPING.md žemėlapis atitinka dokumentą.
- Reali assessment/autosave/restore produkto matrica patvirtinta tiesiai pagal dabartinius šaltinius: pilnai prijungta LD1, LD2 ir LD8; LD3–LD7 bei LD9–LD12 bendras mechanizmas egzistuoja, bet normalus studento UI jo nenaudoja.
- test_automatic_reports.py 769 graded ataskaitos patvirtina graderio gebėjimą įvertinti visas laboratorijas, bet nepatvirtina, kad visi reportai yra formalūs assessment bandymai.
- tools/test_student_delivery.py acceptance metaduomenys deklaruoja labs 1–12, tačiau realus tools/test_student_delivery.sce ciklas vykdo tik LD1–LD8. LD9–LD12 turi atskirus targeted GUI testus.
- LD1 22 kriterijų rubrika nėra normalus UI kelias po guided starto; normalus guided assessment yra LD1-2 su 15 vertinamų studento atsakymų.
- mokytojas vietinis skenavimas pats symlink neatmeta, tačiau galutinis read_report() symlink atmeta, todėl simbolinės nuorodos automatinio pažymio negauna.
- Scilab/ldcheck ir mokytojas --ui tebėra semantiškai nevienodi submission konfliktų bei studento tapatybės grupavimo požiūriu.
- mokytojas --ui Google Drive kelio temp failų pašalinimo prieš process() defektas tebėra patvirtintas pagal dabartinį kodą.
- LD12 report evidence tebėra semantiškai neatitinkantis realių studento matavimų: 2 realūs matavimai išplečiami iki 7 graderio observations.
- studento HTML nėra pasirašytas, o studento pakete tebėra dėstytojo graderio/etalonų prieiga.
- Repo trackinti dist ZIP ir PATIKRA.json yra senesni už LD8–LD12 įvedimą; dabartinis CI funkcionalumą testuoja, bet trackintų README platinimo ZIP freshness negarantuoja.
- package_student.py ir check_student_package.py kontraktas dėl LD9–LD12 VARIANTAI.csv nėra nuoseklus.
- Dokumentaciniams audito commitams naudojamas [skip ci], kad nebekartotume pilnų Windows/Linux/macOS acceptance be funkcinio kodo pakeitimų.

## Kryžminės patikros išvada

Pagrindinės ankstesnių auditų išvados pasitvirtino. Reikšmingiausi patikslinimai:
1. bendras student delivery testas yra LD1–LD8, ne LD1–LD12;
2. 769 graded reportai nėra 769 įskaitinių assessment reportų įrodymas;
3. LD1 22 taškų rubrika nėra normalus guided UI atsiskaitymo kelias;
4. symlink apsauga galutinai veikia read_report() lygyje ir nėra atskiras mokytojas defektas.

Funkcinis kodas šiame checkpoint'e nekeistas. Tolimesnis etapas — tik po atskiro sprendimo, kaip įgyvendinti nustatytus pakeitimus.
