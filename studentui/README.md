# Grandinių laboratoriniai darbai · v7

12 darbų su dabartine numeracija ir pažįstamais fiziniais stendais. Studentas jungia kabelius, spaudžia „Įjungti ir matuoti“ ir perrašo prietaiso rodmenį. Paleidimas: `PALEISTI.bat` arba `STENDAS.sce` grafiniame Scilab. Trumpa instrukcija: `PRADĖKITE.txt`.

Pagalba įjungiama studento prašymu. Ji geltonai žymi konkretų kabelio galą, matavimo mygtuką arba rodmens lauką; rodo visą kabelio porą ir jo numerį. Pasirinktas kontaktas pažymimas mėlynai. Nesutampantis įrašas paaiškinamas prie lauko, pavyzdžiui: „Voltmetras rodo 5 V. Įrašykite 5 be V.“ Juodraštis išlieka. Tinkami laidai paliekami kitam bandymui. Senų, šiai eigai nenaudojamų laukų studentas nemato.

LD1 lenta neperkuriama po kiekvieno kontakto paspaudimo. LD7–LD12 kabelių trasos sutrumpintos ir atitrauktos nuo mygtukų. LD9–LD12 prietaisai turi tikrus matavimo prijungimus; LD10 vienas ampermetras perkeliamas į matuojamą šaką, LD11 vatmetras turi srovės ir įtampos grandines. Matavimas priimamas tik su visu bandymo sujungimu. Iki matavimo prietaisai rodo brūkšnį.

LD8 nagrinėjami ir atskiri rezistoriai, LD9 – elementų įtampos, LD10 – šakų bei bendroji srovė. LD11 lyginamos keturios kompensavimo talpos. LD12 lyginami faziniai ir linijiniai rodmenys abiejuose jungimuose. Kiekvienas bandymas turi trumpą matomą tikslą.

Paskutinį rodmenį patvirtinus atnaujinamas vienas bendras studento HTML failas. Jame kaupiami visi užbaigti LD1–LD12: matavimai, tinkamai sugrupuoti grafikai, paaiškinimai ir išvados. Atvėrus failą galima pasirinkti darbą; matyti, kiek darbų jau atlikta. Dėstytojui perduodamas šis vienas failas. Kiekvienas darbas turi jam skirtą vaizdų paaiškinimą: LD1 – srovių pasiskirstymą, LD2 – signalų amplitudes bei fazę, LD3–LD6 – matavimų ir jungimų palyginimus, LD7 – didžiausią išmatuotą apkrovos galią, LD8 – rezistorių jungimus, LD9 – įtampų atsvarą, LD10 – šakų srovių atsvarą, LD11 – galios trikampius vienodu masteliu su pradiniu kontūru, LD12 – tris fazes ir abu jungimus. Grafiko serijas galima slėpti, rinktis bandymą ir palyginti du matavimus. Mygtukas „Spausdinti / PDF“ atveria naršyklės spausdinimo langą. Viskas veikia be interneto.

Užbaigimo lange rodomas bendras studento failas; galima jį atverti, parodyti aplanką ar įrašyti kopiją kitur. Kito LD pabaigoje pasipildo tas pats pagrindinis failas. Įrašymo klaida nepašalina matavimų. Darbo kopija leidžia grįžti į tą patį etapą, o pakartotinai atvėrus baigtą darbą jo HTML pasiekiamas vėl. V5 darbo kopijos suderinamos. Anksčiau užbaigti dabartinės eigos v5/v6 darbai įtraukiami į bendrą failą, išsaugant ankstesnius HTML. Pradėtų darbų kopijos išlieka.

Dėstytojui: `DESTYTOJUI.sce`. Pasirinkto aplanko ir jo poaplankių HTML sudedami į studentų × LD1–LD12 matricą. Bendrame studento faile kiekvienas LD tikrinamas atskirai. Tie patys pateikimai, rasti ir bendrame, ir ankstesniame atskirame faile, nesidubliuoja. Pateikiamos būsenos, grupės filtras, paieška, pateikimų istorija ir CSV. Naujos ataskaitos tikrinamos pagal žinomą varianto grandinę bei modelio rodmenis. Ankstesnės versijos žymimos atskirai. Pagalbos naudojimas ir taisymai yra darbo eigos informacija.

Techninė sandara: originalūs stendai, tikslinės `rt_ld*_bridge.sci` jungtys, bendra matavimo eiga ir išsaugojimas. Prietaisų prijungimus tikrina fizinio grafo detektoriai. Skaitiniai C++ metodai ir Windows DLL išsaugoti.

Paketas turi Windows x64, Linux x86_64 ir universalų macOS Intel / Apple Silicon branduolius. Windows: `PALEISTI.bat`; Linux: `PALEISTI.sh`; macOS: `PALEISTI.command`. Visur reikalingas įdiegtas grafinis Scilab. Mac instrukcija: `MACOS.txt`.

Dabartinė eiga ir bendras failas tikrinti Linux su Scilab 2024.0.0. Mac branduolių ankstesnis natyvus Intel ir Apple Silicon vykdymas patvirtintas; jų originalūs baitai sujungti į universalų failą. Šios v7 sąsajos Windows ir macOS grafinėse aplinkose vietoje nevykdžiau. Tiksli patikros apimtis ir branduolių kilmė pateikiama kartu su paketu.
