# Oficialios programos ir virtualių laboratorinių darbų atsekamumas

Data: 2026-09-28  
Oficialus šaltinis: KVK dalyko aprašas `Grandinių teorija`, TF-EA-2025-07, Google Drive failas `1KTrmWEDCLcE6aQQYU_wXDKMuUnhpcbNx`.

## Oficialūs 13 laboratorinių darbų

| Oficialus Nr. | Oficialus pavadinimas | Virtualus stendas | Audito pastaba |
|---:|---|---|---|
| 1 | Elektrinių grandinių jungimas | VLD1 / repo LD1 | Dengia nuoseklias/lygiagrečias DC grandines; numatytasis guided režimas jungimą paruošia automatiškai, rankinis režimas yra |
| 2 | Įtampos ir srovės matavimas | **Nėra atskiro virtualaus LD** | `core/README.md` aiškiai nurodo, kad šis darbas lieka realiojo stendo tema |
| 3 | Omo dėsnio veikimas realioje elektros grandinėje | VLD3 / repo LD3 | Tiesioginė teminė atitiktis |
| 4 | Tiesinių rezistorių tyrimas | VLD4 / repo LD4 | Tiesioginė teminė atitiktis |
| 5 | Nuosekliai, lygiagrečiai, mišriai jungiamų grandinės elementų tyrimas | **VLD8 / repo LD8** | Virtuali numeracija nesutampa su oficialia |
| 6 | Įtampos daliklio tyrimas | **VLD5 / repo LD5** | Virtuali numeracija nesutampa su oficialia |
| 7 | Nuoseklaus ir lygiagretaus šaltinių jungimo tyrimas | **VLD6 / repo LD6** | Virtuali numeracija nesutampa su oficialia |
| 8 | Įtampos, srovės ir galios suderinamumo tyrimas | **VLD7 / repo LD7** | Virtuali numeracija nesutampa su oficialia |
| 9 | Paprastųjų kintamosios srovės grandinių tyrimas | VLD2 / repo LD2 (RC/RL dalis) | LD2 metodika pati deklaruoja sąsają su oficialių 9–10 darbų tematika |
| 10 | Nuosekliai sujungtos R,L,C vienfazės grandinės tyrimas. Įtampų rezonansas | VLD9 / repo LD9; dalinai ir VLD2 | Yra teminis persidengimas / dubliavimas |
| 11 | Lygiagrečiai sujungtos R,L,C vienfazės grandinės tyrimas. Srovių rezonansas | VLD10 / repo LD10 | Tiesioginė teminė atitiktis, bet numeris paslinktas |
| 12 | Aktyviosios, reaktyviosios, pilnutinės galios tyrimas | VLD11 / repo LD11 | Tiesioginė teminė atitiktis, bet numeris paslinktas |
| 13 | Trikampiu ir žvaigžde jungiamų imtuvų tyrimas | VLD12 / repo LD12 | Tiesioginė teminė atitiktis, bet numeris paslinktas |

## Audito išvada dėl numeracijos

Repo `LD1…LD12` yra **virtualaus produkto ID**, o ne oficialaus studijų dalyko laboratorinių numeriai.

Dabartinis `mokytojas` kuria `ZURNALAS.csv` su antraštėmis `LD1…LD13`. Tai klaidina, nes:
- oficialus LD2 virtualiame produkte neturi atskiro darbo;
- repo LD2 tematiškai atitinka oficialius LD9–LD10;
- repo LD5–LD8 oficialioje programoje yra 6, 7, 8 ir 5;
- repo LD9–LD12 oficialioje programoje yra 10–13;
- repo LD12 pažymys realiame `ZURNALAS.csv` patenka į stulpelį `LD12`, o `LD13` lieka tuščias, nors pagal oficialią programą tas darbas yra LD13.

## Reikalavimas prieš studentų dokumentacijos užbaigimą

Reikia atskirti du identifikatorius:
1. stabilų techninį virtualaus modulio ID (pvz. `VLD1…VLD12` arba dabartinį repo ID);
2. oficialų studijų programos laboratorinio darbo numerį ir pavadinimą.

Dėstytojo žurnale negalima vieno iš jų pateikti taip, lyg jis būtų kitas. Oficialus fizinis LD2 turi turėti aiškią vietą (rankiniam įvertinimui arba išoriniam importui), jei norima vieno pilno 13 darbų žurnalo.
