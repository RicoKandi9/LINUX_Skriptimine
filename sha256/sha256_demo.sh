#!/bin/bash
# sha256_demo.sh - SHA-256 kontrollsumma mini-praktikum
# Autor: Rico Kandi
#
# Kasutamine: ./sha256_demo.sh [töökaust]
#   töökaust - kaust, kuhu demofailid luuakse (vaikimisi ~/praks_sha256)
#
# Skript teeb läbi õpiku "SHA-256 kontrollsumma Linux skriptimine" mini-praktika:
#   1) loob faili demo.txt ja arvutab sellele kontrollsumma (demo.txt.sha256)
#   2) kontrollib faili -> peab tulema OK
#   3) "rikub" faili (lisab ühe rea) ja kontrollib uuesti -> peab tulema FAILED
#   4) teeb mitu arhiivi (ka tühikuga nimega) ja kontrollib neid ühe nimekirjaga checksums.txt

tookaust="${1:-$HOME/praks_sha256}"

# töökausta loomine ja sinna liikumine - kontroll tehakse samas kaustas, kus fail asub
mkdir -p "$tookaust" || exit 1
cd "$tookaust" || exit 1
echo "Töökaust: $(pwd)"

echo
echo "== 1) Faili loomine ja kontrollsumma arvutamine =="
echo "hello" > demo.txt
# sha256sum väljund: HASH<kaks tühikut>FAILINIMI
sha256sum demo.txt > demo.txt.sha256
cat demo.txt.sha256

echo
echo "== 2) Kontrollimine (oodatav tulemus: OK) =="
sha256sum -c demo.txt.sha256

echo
echo "== 3) Faili rikkumine ja uus kontroll (oodatav tulemus: FAILED) =="
echo "x" >> demo.txt
# sha256sum -c tagastab vea koodi, kui summa ei klapi - kasutame seda tingimuses
if sha256sum -c demo.txt.sha256; then
    echo "Ootamatu tulemus: fail ei ole muutunud?"
else
    echo "Fail on muutunud - kontrollsumma ei klapi (nii peabki olema)"
fi

echo
echo "== 4) Mitme faili kontroll korraga =="
rm -f ./*.tar.gz checksums.txt
for i in 1 2 3
do
    echo "sisu $i" > "fail$i.txt"
    tar -czf "arhiiv $i.tar.gz" "fail$i.txt"
done
# -print0 ja xargs -0: failinimed eraldatakse nullbaidiga, nii töötavad ka tühikuga nimed
find . -maxdepth 1 -type f -name '*.tar.*' -print0 | xargs -0 sha256sum > checksums.txt
cat checksums.txt
sha256sum -c checksums.txt

echo
echo "Uuesti pakitud arhiivil on peaaegu alati teine räsi (tar salvestab ka ajad):"
sleep 1
touch fail1.txt
tar -czf "arhiiv 1.tar.gz" fail1.txt
sha256sum -c checksums.txt
echo "Valmis."
