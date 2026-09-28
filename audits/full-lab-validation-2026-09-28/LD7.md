# LD7 auditas — studento UI → dėstytojo UI

Data: 2026-09-28  
Audituotas `main` prieš šį checkpointą: `403f0fd3031e62ccad5bfdc6e21c0bfa7be28f9f`

## Būsena

Virtualus LD7 tiria:
- šaltinio išorinę U(I) charakteristiką;
- vidinę varžą r;
- apkrovos galią;
- maksimalios galios perdavimo sąlygą R=r;
- 50 % naudingumą suderinimo taške;
- tuščiąją eigą;
- trumpąjį jungimą.

Fizikinis modelis ir 27 kriterijų graderis yra nuoseklūs. Virtualus LD7 semantiškai atitinka oficialų **LD8 „Įtampos, srovės ir galios suderinamumas“**, o ne oficialų LD7. Funkcinis kodas šiame etape nekeistas.

## Patvirtinta kaip veikianti

- Studentas realiai sujungia darbinę grandinę.
- Penkios reostato padėtys deterministiškai išsidėsto abipus r, o P3 = r.
- Studentas kiekvienoje padėtyje realiai užfiksuoja U ir I.
- Matavimų žurnalas rodo ir apskaičiuotą P=U·I.
- C++ graderis nepriklausomai tikrina 5×U ir 5×I.
- 3 etape r skaičiuojama iš dviejų studento matavimo taškų.
- 4 etape vertinamos P1, P3, P5, teorinė Pmax ir η.
- 5 etape yra atskiros tikros topologijos:
  - tuščioji eiga;
  - trumpasis jungimas.
- Graderis tikrina U0 ir Ik.
- Ataskaita perduoda 12 matavimo reikšmių:
  - 5×(U,I);
  - U0;
  - Ik;
  ir trijų topologijų laidų įrodymus.
- Modelyje tuščioji eiga realizuota labai didele apkrova, trumpasis jungimas – labai maža apkrova, todėl sprendiniai baigtiniai ir kontroliuojami.
- Graderis maksimalios galios teoriją skaičiuoja pagal `Pmax=E²/(4r)`.
- P3 varianto banke yra R3=r, todėl η=50 % ir maksimalios galios dėsnis testuojamas ne apytiksliai, o ties konkrečiu matavimo tašku.
- Laidų keitimas blokuojamas, kol maitinimas įjungtas.
- Perjungiant darbinė / TE / TJ režimus maitinimas ir jungiklis išjungiami.
- Pavyzdys izoliuotas ir nustato `practice_used=true`.
- Generic snapshot mechanizmas teisingai grąžina matavimus ir raw tekstą, o po restore maitinimą išjungia.
- Targeted GUI testai tikrina 3 variantus, darbinę/TE/TJ topologijas, MNA rodmenis, report evidence, kablelio įvestį, demo izoliaciją, draft restore, resize ir 144 Scilab↔grader tolerancijos atvejus.
- Ankstesnė nepriklausoma patikra patvirtino, kad ties R=r gaunama E²/(4r) galia ir 50 % naudingumas.

## CRITICAL — normalus LD7 paleidimas nėra atsiskaitymo režimas

`ld7_student_main()` po registracijos sukuria:

`LD7 = struct("root", root, "cfg", cfg, "student", st)`

ir nenustato `assessment=true`.

Todėl pilnai atliktas normalus LD7 report yra:

`mode="learning"`.

Dėstytojo graderis gali skirti 27/27, tačiau galutinė pažymių suvestinė tokio failo nepasirenka.

## CRITICAL — realiame UI nėra režimo pasirinkimo

Bendras `bench_mode("LD7")` egzistuoja, tačiau realus LD7 Pagalbos meniu jo nekviečia.

Studentui nėra normalaus produkto kelio į assessment režimą.

## CRITICAL/METHODIC — primary visada reikalauja teisingo rezultato

`ld7_student_primary()` assessment būsenos nenaudoja.

Jis visada:
1. išsaugo atsakymus;
2. vykdo `ld7_check_step()`;
3. tik teisingą etapą pažymi kaip `done`;
4. tik tada leidžia judėti toliau.

Todėl studentas negali pateikti dėstytojui klaidingo, bet užpildyto formaliojo atsakymo.

## HIGH/UI — Pmax formulėje nenurodyta W → mW konversija

Studento instrukcija:

`Pmax = E²/(4r), mW`

yra dimensijų požiūriu nepilna.

Kai E yra V, r — Ω:

`E²/r` rezultatas yra **W**, ne mW.

Kad gauti mW, reikia:

`Pmax = E²/(4r) × 1000, mW`.

C++ graderis tai daro teisingai:

`1000*E*E/(4*r)`.

Todėl klaida yra studentui rodomame paaiškinime.

## HIGH/UI — Ik formulėje nenurodyta A → mA konversija

5 etape studentui rodoma:

`Ik = E/r`

ir tuo pačiu atsakymas prašomas mA.

V/Ω duoda A.

Turi būti aiškiai:

`Ik = E/r × 1000, mA`

arba atskirai paaiškinta A→mA konversija.

Graderis vėl skaičiuoja teisingai su ×1000.

## HIGH — realiame produkto kelyje nėra autosave / restore

Generic session sistema LD7 snapshot palaiko.

Targeted testas ranka įjungia:

`LD7.autosave_enabled=%t`

ir patvirtina, kad autosave veikia.

Tačiau normalus `ld7_student_main()`:
- autosave neįjungia;
- Pagalbos meniu neturi automatinio juodraščio atkūrimo.

Todėl studento produkto patikimumas mažesnis nei LD1/LD2/LD8.

## HIGH — CI testuoja learning, ne assessment semantiką

`bench_ld7_workflow()` konstruoja LD7 be `assessment=true`.

Visi etapai praeinami tik po vietinio teisingumo patikrinimo.

Targeted testas net specialiai:
- įveda neteisingą `1+2`;
- tikisi, kad etapas nebus užbaigtas;
- tada įveda teisingą reikšmę.

Tai stiprus mokymosi workflow testas, bet ne formalus atsiskaitymo testas.

## HIGH/TRACEABILITY — virtualus LD7 yra oficialus LD8

Oficialiame dalyko apraše:
- LD7 — šaltinių jungimas;
- LD8 — įtampos, srovės ir galios suderinamumas.

Virtualioje sistemoje:
- LD6 — šaltinių jungimas;
- **LD7 — įtampos, srovės ir galios suderinamumas**.

Todėl `ZURNALAS.csv` stulpelis **LD7** semantiškai atitinka oficialų LD8.

## MEDIUM/HIGH — virtualaus trumpojo jungimo scenarijui reikia aiškaus saugos konteksto

Virtualiame stende trumpasis jungimas yra saugiai modeliuojamas:
- srovę riboja vidinė r;
- skaitiniame modelyje naudojama labai maža, bet ne nulinė apkrova;
- nėra realios fizinės energijos.

Pedagogiškai tai vertinga.

Tačiau studento metodikoje turi būti labai aišku, kad:
- tai yra **virtualus kontroliuojamas trumpasis jungimas**;
- realiame stende trumpąjį jungimą galima atlikti tik pagal laboratorijos schemą, su tinkamu srovės ribojimu ir dėstytojo nustatyta procedūra;
- negalima bendrinti taisyklės „šaltinį galima tiesiog trumpinti“.

Tai ypač svarbu todėl, kad UI žingsnis tiesiogiai sako „ampermetras vietoj R“.

## MEDIUM — vidinė varža studento schemoje „nežymima“, nors ji yra esminis modelio elementas

1 etapo instrukcijoje sakoma, kad šaltinio vidinė varža nežymima.

Vėliau:
- visas U(I) dėsnis;
- Pmax;
- TE/TJ;
- η

remiasi būtent r.

Tai nėra skaičiavimo klaida, tačiau pedagogiškai verta apsvarstyti, ar studentui neturėtų būti parodytas bent konceptualus šaltinio Thevenin modelis E+r, ypač prieš TE/TJ etapą.

## MEDIUM — pavyzdžio apsauga techniškai paruošta

`ld7_toggle_solution()`:
- saugo studento būseną;
- nustato `practice_used=true`;
- demonstraciniame režime report neleidžiamas.

Tai gera bazė būsimam assessment srautui.

## MEDIUM — bendros dėstytojo UI problemos taikomos ir LD7

LD7 taip pat paveikia:
- skirtinga submission konfliktų semantika tarp dviejų dėstytojo kelių;
- skirtingas studento grupavimo raktas;
- neescapintas studento vardas/grupė `mokytojas --ui`;
- savarankiškai studento deklaruojamas variantas.

## LD7 audito išvada

LD7 fizikinė ir matavimo dalis yra stipri:
- penki apkrovos taškai;
- maksimalios galios perdavimo dėsnis;
- TE/TJ;
- atskiros realios topologijos;
- saugus rewiring valdymas;
- 27 kriterijų graderis.

Pagrindinės problemos:
1. nėra realaus assessment produkto kelio;
2. primary priverčia atsakymą pataisyti prieš tęsiant;
3. nėra realaus autosave/restore UI;
4. Pmax ir Ik instrukcijose praleistos ×1000 vienetų konversijos;
5. virtualus LD7 numeris atitinka oficialų LD8;
6. trumpojo jungimo scenarijui reikia aiškesnio saugos konteksto;
7. CI testuoja learning, ne formalų assessment.

Šiame etape niekas netaisyta.
