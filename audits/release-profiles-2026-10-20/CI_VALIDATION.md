# Grandinių LD1–LD12: pertvarkymas ir galutinė patikra

Patikros data: 2026-10-20. Tikrintos galutinės iš **švarių GitHub Actions** surinkimų parsisiųstos ZIP versijos, ne vien tarpiniai vietiniai failai.

## Projekto versija

- Šaka: `work/student-teacher-release-profiles-20261020`.
- Commit: [`6b624db0f722ca4ec34d861c2d7b300c4c76f096`](https://github.com/karpavicius-org/Grandiniu_LD/commit/6b624db0f722ca4ec34d861c2d7b300c4c76f096).
- `main` šaka nekeista. C++ skaičiavimo algoritmai ir LD1–LD12 Scilab kodas nekeisti.
- Studentui: Scilab, `ldcore` ir LD1–LD12; be atskirų `ldcheck`, `mokytojas` vykdomųjų programų.
- Dėstytojui: tie patys laboratoriniai failai ir branduolys, papildomai abu administravimo vykdomieji failai.

## Patikrų rezultatai

1. Vietinis keturių platformų išskaidymas ir visų dvylikos LD kontrolė: praėjo.
2. Kiekvienos platformos 6 tyčia sugadintų paketų variantai teisingai atmesti (24 iš 24).
3. Vietinėje Linux aplinkoje realiai vykdyti C++ FFI bandymai su nepriklausoma DC/trifazių grandinių matematika ir klaidingų parametrų kontrolė: praėjo.
4. Vietinės dėstytojo priemonės: `ldcheck` sugeneravo HTML, CSV ir JSON; `mokytojas` sugeneravo `IVERTINIMAI.csv` ir `ZURNALAS.csv`.
5. Realūs LD1 atsiskaitymo kontroliniai pavyzdžiai: 22/22 teisingam ir 21/22 vieną klaidingą atsakymą turinčiam, žurnale abu įrašyti.
6. Po vietinės patikros atlikti švarūs CI surinkimai ir grafinės Scilab aplinkos bandymai visose keturiose sistemose. Visų šešių atskirų CI sekų galutinė būsena: **success**.
7. Galutinių iš CI atsisiųstų 8 paketų ZIP CRC, SHA-256, manifestai, LD1–LD12 duomenys, studento ir dėstytojo failų sutapimas, vienodas Scilab turinys tarp platformų ir nesaugūs ZIP keliai: **praėjo**.

## GitHub Actions įrodymai

- [Windows ir Linux bendras priėmimas](https://github.com/karpavicius-org/Grandiniu_LD/actions/runs/39387025999): success.
- [macOS Intel ir Apple Silicon bendras priėmimas](https://github.com/karpavicius-org/Grandiniu_LD/actions/runs/39387025972): success.
- [LD9](https://github.com/karpavicius-org/Grandiniu_LD/actions/runs/39387026002): success, 2 bandymas (1 bandyme nutrūko išorinis Scilab atsisiuntimas, `curl 92`).
- [LD10](https://github.com/karpavicius-org/Grandiniu_LD/actions/runs/39387026010): success.
- [LD11](https://github.com/karpavicius-org/Grandiniu_LD/actions/runs/39387025937): success.
- [LD12](https://github.com/karpavicius-org/Grandiniu_LD/actions/runs/39387026060): success.

## Galutiniai paketai

| Sistema | Profilis | Failų | Dydis, baitais | SHA-256 |
|---|---|---:|---:|---|
| Windows | Studentas | 174 | 898,853 | `41a3fca01610e22427544ae314637a495f9438341243dbc5c5f33a355a57382b` |
| Windows | Destytojas | 176 | 1,271,617 | `2f7fda0078f1b430ffcc9f749fc150248d5a21ac800fda022e8ef2075ad26323` |
| Linux | Studentas | 174 | 807,649 | `971d0a76722028ebb23681200ec24ff146cc6cfbe27ebdd2eab1ab8d4c352f21` |
| Linux | Destytojas | 176 | 940,817 | `583681756043bcd141c30b224aa84ca8cf09d6e7419e233c7727b59097c7ed66` |
| macOS-arm64 | Studentas | 174 | 697,405 | `a5da0727d020e700d8c3e9348adfe6c3b7d556c4fc2f9f383ebed9bea51cf754` |
| macOS-arm64 | Destytojas | 176 | 800,707 | `3d445114cc0009c37a6fbda91a50ad9e06727e83af9c52d0d9342d71308f3610` |
| macOS-x86_64 | Studentas | 174 | 722,703 | `7457fd2b9b445083423bb8278719ead96cf0f0cdc381ae6c122709d3e4e50418` |
| macOS-x86_64 | Destytojas | 176 | 833,132 | `0b3c80d08194267917867c609b5a009cb75121cce60ddf2b84c42c6286deba12` |

## Ribojimai

- Antivirusinis skenavimas ir „Google Drive“ pakartotinis vertinimas nebuvo atlikti, todėl negalima teigti, kad naujasis studento ZIP nebebus ribojamas.
- Windows ir macOS vykdomieji komponentai vis dar nėra pasirašyti sertifikatais.
- „Google Drive“ atsisiuntimas išsaugotas dėstytojo vykdomojoje programoje, tačiau nuotolinis autentifikavimas nebuvo patikrintas su tikra asmenine Drive paskyra; CI testai tikrino vietinius scenarijus ir esamą funkcionalumą.

## Priėmimas

Visos patikrintos techninės funkcijos ir CI sąsajos scenarijai praėjo. Nepatikrintas išlieka „Google Drive“ grėsmės klasifikatoriaus sprendimas konkrečiam naujam failui.