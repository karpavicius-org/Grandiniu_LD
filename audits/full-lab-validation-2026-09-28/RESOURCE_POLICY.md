# GitHub resursų ir sąnaudų politika

Data: 2026-09-28

## Pagrindinė taisyklė

**Jokių naujų mokamų įsipareigojimų be aiškaus projekto savininko leidimo.**

Tikslas: maksimalus darbo greitis ir patikimumas, papildomos GitHub sąnaudos — **0 €**.

## Taisyklės

1. Naudoti tik resursus, įtrauktus į esamą GitHub Enterprise planą.
2. Nenaudoti larger runners, GPU runnerių, mokamų cloud sandbox, papildomų Actions minučių, AI credits, papildomos storage ar runner capacity be aiškaus leidimo.
3. Pirmenybė standartiniams GitHub-hosted runneriams ir, kai tinkama, self-hosted runneriams be papildomo GitHub mokesčio.
4. Prieš keičiant `runs-on`, runnerio dydį, OS, storage ar kitą resursą, patikrinti dabartinę GitHub kainodarą.
5. Neįjungti mokamų paslaugų ir nedidinti spending limit automatiškai.
6. Jei kainodara neaiški, veiksmo nevykdyti; rinktis į planą įtrauktą alternatyvą.
7. Išlaikyti naudingą lygiagretumą, jei jis nekuria papildomų sąnaudų.
8. Nevykdyti nereikalingų ar dubliuotų CI workflow.
9. Neliesti kitų šakų ir nepriklausomų eksperimentų vien dėl taupymo, jei jie naudoja į planą įtrauktus resursus.
10. Mažinti nereikalingą Actions artifacts, cache ir Packages saugojimą; retention laikyti minimalų praktiškai reikalingą.
11. Nenaudoti mokamų AI/Copilot automatizacijų, kurios sunaudoja papildomus kreditus.
12. Pirmiausia naudoti lokalius build/test, kai tai nemažina patikimumo; GitHub Actions naudoti platforminiam CI patvirtinimui.
13. Dabartinio audito metu nekeisti runnerių klasės ir rankiniu būdu nekartoti jau turimų to paties SHA CI patikrų.

Dabartiniuose workflow naudojamos standartinės etiketės: `ubuntu-22.04`, `windows-2022`, `macos-15`, `macos-15-intel`. Jų nekeisti į larger/GPU runnerius be aiškaus leidimo.
