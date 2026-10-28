# SHA-256 kontrollsumma

SHA-256 kontrollsumma on faili "digisõrmejälg": 64 kuueteistkümnendsümbolist koosnev string.
Kui failis muutub kasvõi üks bait, muutub kogu kontrollsumma. Kontrollsumma ei krüpti faili
ega tõesta autorit, see näitab ainult, kas fail on muutunud.

## Failid

| Fail | Kirjeldus |
|------|-----------|
| `sha256_demo.sh` | mini-praktikum: demo.txt loomine, kontroll (OK), rikkumine (FAILED), mitme arhiivi kontroll |
| `kontrollsumma.sh` | üldine skript .sha256 ja checksums.txt failide loomiseks ning kontrollimiseks |
| `tulemus.txt` | `sha256_demo.sh` väljund virtuaalmasinas |

## Põhikäsud

```bash
sha256sum FILE > FILE.sha256      # summa arvutamine
sha256sum -c FILE.sha256          # kontroll -> FILE: OK / FILE: FAILED
find . -maxdepth 1 -type f -name '*.tar.*' -print0 | xargs -0 sha256sum > checksums.txt
sha256sum -c checksums.txt        # kõigi failide kontroll korraga
```

## Kasutamine

```bash
chmod +x sha256_demo.sh kontrollsumma.sh
./sha256_demo.sh | tee tulemus.txt

./kontrollsumma.sh loo ~/praks2/backup/src_2026-10-28_12-00-00.tar.zst
./kontrollsumma.sh kontrolli ~/praks2/backup/src_2026-10-28_12-00-00.tar.zst
./kontrollsumma.sh loo-kaust ~/praks2/backup
./kontrollsumma.sh kontrolli-kaust ~/praks2/backup
```

## Tähelepanekud

- Kontroll tuleb teha samas kaustas, kus fail asub (`.sha256` failis on ainult failinimi), skript teeb `cd` ise.
- Uuesti pakitud arhiiv annab peaaegu alati uue räsi, sest tar salvestab ka failide ajad.
- `-print0` ja `xargs -0` hoiavad tühikuga failinimed terviklikud.
