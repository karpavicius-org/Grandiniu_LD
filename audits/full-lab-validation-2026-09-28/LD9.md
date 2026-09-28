# LD9 auditas — studento UI → dėstytojo UI

Data: 2026-09-28  
Audituotas `main` prieš šį checkpointą: `62889a3d80422daa6ec42c4e57c8fe668819d47e`

## Būsena

Virtualus LD9 yra nuoseklios RLC grandinės rezonanso laboratorija:
- teorinis f0;
- 0,5·f0, f0 ir 2·f0 taškai;
- I, UR, UL, UC ir U matavimai;
- Q;
- UL−UC;
- įtampų trikampis;
- Z, cos φ;
- P, Q, S;
- rezonanso išvados.

Fizikinis modelis ir 28 kriterijų graderis yra stiprūs. Pagal oficialų dalyko numeravimą ši tema semantiškai atitinka **oficialų LD10**, ne oficialų LD9.

Funkcinis kodas šiame etape nekeistas.

## Patvirtinta kaip veikianti

- Studentas realiai sujungia nuoseklią generatorius → jungiklis → ampermetras → R → L → C grandinę.
- Laidų keitimas blokuojamas, kol generatorius įjungtas.
- Wiring pakeitimas:
  - išvalo matavimų žurnalą;
  - anuliuoja visų etapų `done`;
  - anuliuoja report wiring įrodymą.
- Studentas matuoja trijuose dažnio taškuose:
  - 0,5·f0;
  - f0;
  - 2·f0.
- Kiekviename taške užfiksuojami:
  - I;
  - UR;
  - UL;
  - UC;
  - U.
- Tai duoda 15 atskirai graderio tikrinamų matavimo reikšmių.
- Vienas dažnio/taikinio derinys negali būti įrašytas antrą kartą kaip naujas matavimas.
- C++ graderis nepriklausomai perskaičiuoja kiekvieno taško AC būseną.
- Rezonanso dažnis skaičiuojamas nepriklausomai iš L ir C.
- Ties f0 tikrinama:
  - Q = UL/U;
  - UL−UC ≈ 0.
- 0,5·f0 taške tikrinama:
  - įtampų trikampio dydis;
  - Z;
  - cos φ;
  - P;
  - Q;
  - S.
- Graderis turi:
  - 15 matavimo kriterijų;
  - 12 studento atsakymų;
  - 1 wiring kriterijų;
  - iš viso 28.
- Galios skaičiavimuose V·mA teisingai interpretuojama kaip mW/mvar/mVA.
- Pavyzdžio būsena izoliuota nuo studento darbo.
- Pavyzdžio naudojimas nustato `practice_used=true`.
- Generic session sistema techniškai moka snapshot/restore LD9.
- Targeted testai tikrina variantus 1/17/64, 12 įtampos taikinio matavimų įrašų per tris dažnius, realius MNA/AC rodmenis, report wiring evidence, demo izoliaciją, draft restore, geometriją ir Scilab↔C++ grading ribas.
- Graderio ir Scilab etalonai skaičiuoja Z teisingai:
  - studento matuota srovė mA paverčiama į A;
  - `Z=U/(I/1000)`.

## CRITICAL — normalus LD9 paleidimas nėra atsiskaitymo režimas

`ld9_student_main()` po registracijos sukuria:

`LD9 = struct("root", root, "cfg", cfg, "student", st)`

ir nenustato:

`LD9.assessment=%t`.

Todėl normalus studento report pagal nutylėjimą yra:

`mode="learning"`.

Net teisingas 28/28 darbas nepatenka į galutinę pažymių suvestinę.

## CRITICAL — realiame studento UI nėra režimo pasirinkimo

Bendra `bench_mode("LD9")` funkcija egzistuoja.

Tačiau realus LD9 Pagalbos meniu turi tik:
- Kaip sujungti;
- Žemėlapis;
- Pavyzdys;
- Ataskaita;
- Atkurti stendą;
- Iš naujo.

Studentas neturi normalaus produkto kelio į formalų assessment režimą.

## CRITICAL/METHODIC — primary visada reikalauja teisingumo prieš tęsiant

`ld9_student_primary()` assessment būsenos nenaudoja.

Jis visada:
1. išsaugo raw atsakymus;
2. kviečia `ld9_check_step()`;
3. reikalauja visų atsakymų atitikties etalonui;
4. tik tada pažymi etapą `done` ir leidžia tęsti.

Todėl formaliam atsiskaitymui neteisingas, bet užpildytas atsakymas negali būti išsaugotas kaip studento bandymas.

Tai mokymosi savikontrolės, ne formaliojo assessment semantika.

## HIGH — CI maskuoja režimo problemą nustatydamas `assessment=true` tik prieš eksportą

`studentui/tests/workflows.sci::bench_ld9_workflow()`:
- sukuria LD9 be assessment;
- visus 6 etapus atlieka learning logika;
- kiekviename etape reikalauja teisingų atsakymų;
- tik **po to**, prieš spaudžiant galutinį report mygtuką GUI teste, vykdo:

`LD9.assessment=%t`.

Todėl CI sugeneruota ataskaita atrodo kaip tinkamas formalus assessment ir `tools/test_ld9.py` gali teisingai patvirtinti:

- `mode=assessment`;
- `selected_for_summary=true`;
- 28/28.

Tačiau tai nėra realus studento produkto kelias.

CI šiuo metu patvirtina kombinaciją:
- darbą atlikti kaip learning;
- tik eksportui ranka perjungti metadata į assessment.

Tai tiesiogiai maskuoja produkto defektą.

## HIGH/UI — Z formulės instrukcija gali sukelti 1000× klaidą

5 etape studentui rodoma:

`Z = U/I`

ir to paties sakinio gale nurodyta:

`I — mA`.

Tačiau atsakymo laukas laukia **Ω**.

Jei studentas tiesiog į formulę įstato I mA skaičių, rezultatas gaunamas 1000 kartų per mažas.

Teisinga forma turi būti, pvz.:

`Z = U/(I/1000)`

arba aiškiai pasakyta:
- Z formulei I pirmiausia paversti į amperus.

C++ graderio feedback tai jau aiškiai sako: **„I – amperais.“**

Scilab etalonas taip pat skaičiuoja teisingai iš srovės amperais.

Taigi klaida yra tik studentui pateikiamoje instrukcijoje.

## HIGH/UI — generatoriaus kortelėje rodomas literalus `<br>`

`ld9_render_wires()` komponento tekstą generuoja:

`5 V ~<br>...`

Ši eilutė nėra pateikiama per tą patį HTML-aware mygtuko helperį kaip valdymo mygtukai.

Realiuose CI GUI artefaktuose jau patvirtinta, kad studentas mato literalų:

`<br>`

Tai nėra fizikos klaida, bet pramoninio lygio UI toks formatavimo likutis neturi būti matomas.

## HIGH — realiame produkto kelyje nėra autosave / restore

Generic `bench_session.sci` LD9 palaiko.

Targeted testas ranka nustato:

`LD9.autosave_enabled=%t`

ir patvirtina mechanizmą.

Tačiau normalus LD9 paleidimas:
- autosave neįjungia;
- answer/wiring/measure callbacks jo realiame produkte nenaudoja;
- Pagalbos meniu neturi „Tęsti išsaugotą darbą“.

Todėl CI įrodo bibliotekos mechanizmą, bet ne studentui prieinamą produkto funkciją.

## HIGH/TRACEABILITY — virtualus LD9 semantiškai yra oficialus LD10

Oficialus:
- LD9 — paprastos AC grandinės;
- LD10 — nuoseklioji RLC, įtampų rezonansas.

Virtualus LD9 yra būtent nuosekliosios RLC rezonanso darbas.

Todėl `ZURNALAS.csv` stulpelis **LD9** semantiškai nėra oficialaus LD9 pažymys.

## MEDIUM/HIGH — virtualus LD9 dalinai dubliuoja virtualaus LD2 RLC dalį

Virtualus LD2 jau turi:
- nuoseklią RLC;
- rezonanso paiešką;
- UL/UC ekstremumus;
- rezonanso dažnį;
- f1/f2 pusės galios taškus;
- BW ir Q;
- dažninę charakteristiką.

Virtualus LD9 vėl tiria nuoseklią RLC, tačiau kitokia struktūra:
- fiksuoti 0,5·f0, f0, 2·f0 taškai;
- atskiri UR/UL/UC/U matavimai;
- įtampų trikampis;
- Z/cosφ/P/Q/S.

Tai gali būti metodologiškai prasminga, jei:
- LD2 yra platesnis AC mokymosi modulis;
- LD9/official LD10 yra atskiras formalus rezonanso laboratorinis.

Tačiau galutiniame studijų žemėlapyje būtina aiškiai paaiškinti, kodėl studentui reikia abiejų ir kokie jų skirtingi studijų rezultatai.

## MEDIUM — žymėjimas „f1“ gali būti painiojamas su LD2 pusės galios dažniu f1

LD9 graderis ir UI pirmą matavimo tašką 0,5·f0 vietomis vadina **f1**:
- „taškas f1“;
- „Z ... f1“;
- „P ... f1“.

Tačiau virtualiame LD2 `f1` ir `f2` reiškia -3 dB / pusės galios ribinius dažnius.

LD9 pirmasis taškas nėra apskaičiuotas pusės galios f1 — jis tiesiog yra 0,5·f0.

Todėl bendroje kurso terminijoje žymėjimas gali klaidinti.

Aiškesnė semantika būtų:
- „0,5·f0 taškas“;
- „f0 taškas“;
- „2·f0 taškas“;

jei tai nėra oficialiai apibrėžti f1/f2.

## MEDIUM — pavyzdys assessment ateityje turi būti blokuojamas arba aiškiai paversti bandymą practice

Dabartinis `ld9_toggle_solution()`:
- nustato `practice_used=true`;
- izoliuoja studento būseną;
- demonstraciniame režime report eksportas neleidžiamas.

Tai gera techninė bazė.

Tačiau kai bus įdiegtas tikras assessment, studentui reikia aiškiai pranešti, kad Pavyzdžio naudojimas esamą bandymą padaro neįskaitinį.

## CRITICAL / BENDRAS ASSESSMENT VIENTISUMAS — studento pakete esančiu graderiu galima atsivertinti LD9

Kaip ir LD8:
- studento distribucijoje yra `ldcheck`, `mokytojas` ir pilnas graderis `ldcore`;
- studentas gali lokaliai paleisti dėstytojo vertinimą;
- gauti tikslų balą ir etalonų feedback;
- pataisyti atsakymus prieš pateikimą.

Kai LD9 bus paverstas realiu formal assessment, ši globali architektūrinė problema turi būti išspręsta kartu.

## MEDIUM — bendros dėstytojo UI problemos taikomos ir LD9

LD9 taip pat paveikia:
- skirtinga `submission_id` konfliktų semantika tarp batch ir `mokytojas --ui`;
- skirtingas studento grupavimo raktas;
- `mokytojas --ui` XSS paviršius iš studento vardo/grupės;
- nepasirašyta lokali HTML ataskaita;
- studento savarankiškai deklaruojama tapatybė/variantas.

## LD9 audito išvada

LD9 skaitinis ir eksperimentinis modelis yra stiprus:
- 3 dažniai;
- 5 matavimo dydžiai kiekviename dažnyje;
- RLC rezonanso fizika;
- įtampų trikampis;
- Z/cosφ/P/Q/S;
- 28 kriterijų graderis;
- saugus rewiring.

Pagrindinės problemos yra produkto ir metodikos sluoksnyje:

1. realus studento paleidimas nėra assessment;
2. primary reikalauja teisingumo vietoje;
3. CI assessment būseną įrašo tik prieš report eksportą ir taip maskuoja realų kelią;
4. nėra realaus autosave/restore;
5. Z formulės instrukcijoje neaiški mA→A konversija;
6. komponento kortelėje matomas literalus `<br>`;
7. virtualus LD9 iš tiesų yra oficialus LD10;
8. dalis temos dubliuojasi su virtualiu LD2;
9. „f1“ terminija konfliktuoja su LD2 pusės galios dažnio reikšme;
10. globaliai studentui prieinamas pilnas graderis silpnina formalų assessment.

Šiame etape niekas netaisyta.
