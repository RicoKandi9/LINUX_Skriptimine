#!/bin/bash
# kontrollsumma.sh - SHA-256 kontrollsummade loomine ja kontrollimine
# Autor: Rico Kandi
#
# Kasutamine:
#   ./kontrollsumma.sh loo FAIL               -> loob faili FAIL.sha256
#   ./kontrollsumma.sh kontrolli FAIL         -> kontrollib faili FAIL.sha256 abil
#   ./kontrollsumma.sh loo-kaust KAUST        -> loob KAUST/checksums.txt kõigist *.tar.* failidest
#   ./kontrollsumma.sh kontrolli-kaust KAUST  -> kontrollib kõiki faile KAUST/checksums.txt abil
#
# Näide (varukoopiate kaust):
#   ./kontrollsumma.sh loo ~/praks2/backup/src_2026-10-28_12-00-00.tar.zst
#   ./kontrollsumma.sh kontrolli-kaust ~/praks2/backup
#
# Skript liigub alati faili kausta, sest .sha256 failis on ainult failinimi (ilma teeta).
# Väljumiskood: 0 - kõik OK, 1 - vale kasutus, 2 - faili/kausta pole, muu - kontroll ebaõnnestus

kasutus() {
    echo "Kasutamine: $0 loo|kontrolli FAIL"
    echo "            $0 loo-kaust|kontrolli-kaust KAUST"
    exit 1
}

if [ $# -ne 2 ]; then
    kasutus
fi

tegevus=$1
siht=$2

case "$tegevus" in
    loo)
        if [ ! -f "$siht" ]; then
            echo "Faili $siht ei ole olemas"
            exit 2
        fi
        cd "$(dirname "$siht")" || exit 2
        nimi=$(basename "$siht")
        sha256sum "$nimi" > "$nimi.sha256"
        echo "Loodud: $(pwd)/$nimi.sha256"
        cat "$nimi.sha256"
        ;;
    kontrolli)
        if [ ! -f "$siht.sha256" ]; then
            echo "Kontrollsumma faili $siht.sha256 ei ole olemas"
            exit 2
        fi
        cd "$(dirname "$siht")" || exit 2
        sha256sum -c "$(basename "$siht").sha256"
        ;;
    loo-kaust)
        cd "$siht" || exit 2
        # .sha256 failid jäetakse nimekirjast välja
        find . -maxdepth 1 -type f -name '*.tar.*' ! -name '*.sha256' -print0 | xargs -0 -r sha256sum > checksums.txt
        echo "Loodud: $(pwd)/checksums.txt ($(wc -l < checksums.txt) faili)"
        cat checksums.txt
        ;;
    kontrolli-kaust)
        cd "$siht" || exit 2
        if [ ! -f checksums.txt ]; then
            echo "Kaustas $siht ei ole faili checksums.txt"
            exit 2
        fi
        sha256sum -c checksums.txt
        ;;
    *)
        kasutus
        ;;
esac
