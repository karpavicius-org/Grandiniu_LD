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
