#!/bin/bash
# kodukataloogide_varundus.sh - kasutajate kodukataloogide varundamine
# Autor: Rico Kandi
#
# Kasutamine: sudo ./kodukataloogide_varundus.sh [varukaust]
#   varukaust - kuhu pakitud arhiivid kopeeritakse (vaikimisi /home_bcp)
#
# Iga /home all olev kodukataloog arhiveeritakse ja pakitakse (tar + gzip) faili
# kasutaja.PP.KK.AAAA.tar.gz (nt rico.28.10.2026.tar.gz) ja kopeeritakse varukausta.
# Skript töötab sõltumata sellest, millises kaustas see käivitatakse:
# tar -C /home liigub ise /home kausta ja arhiivi tehakse ajutises kaustas.
#
# Käsitsi samm-sammult (ühe kasutaja näitel):
#   sudo mkdir -p /home_bcp && sudo chmod 700 /home_bcp
#   sudo tar -czf /tmp/rico.$(date +%d.%m.%Y).tar.gz -C /home rico
#   sudo cp /tmp/rico.$(date +%d.%m.%Y).tar.gz /home_bcp/
#   sudo tar -tzf /home_bcp/rico.$(date +%d.%m.%Y).tar.gz | head

# kodukataloogide lugemiseks on vaja root õigusi
if [ "$(whoami)" != "root" ]; then
    echo "Skript vajab root õigusi: sudo $0 [varukaust]"
    exit 1
fi

varukaust="${1:-/home_bcp}"
kuupaev=$(date +%d.%m.%Y)

# ajutine kaust arhiivide jaoks, mis kustutatakse skripti lõpus automaatselt
ajutine=$(mktemp -d) || exit 1
trap 'rm -rf "$ajutine"' EXIT

# varukausta loomine, õigused ainult rootile (arhiivides on kasutajate andmed)
mkdir -p "$varukaust" || exit 2
chmod 700 "$varukaust"

edukad=0
vead=0
for kodu in /home/*/
do
    [ -d "$kodu" ] || continue
    kasutaja=$(basename "$kodu")
    arhiiv="$kasutaja.$kuupaev.tar.gz"

    # -c loo arhiiv, -z paki gzip-iga, -f faili nimi, -C liigu enne pakkimist /home kausta
    if tar -czf "$ajutine/$arhiiv" -C /home "$kasutaja" && cp "$ajutine/$arhiiv" "$varukaust/"; then
        echo "OK:   $kasutaja -> $varukaust/$arhiiv ($(du -h "$varukaust/$arhiiv" | cut -f1))"
        edukad=$((edukad + 1))
    else
        echo "VIGA: kasutaja $kasutaja kodukataloogi varundamine ebaõnnestus"
        vead=$((vead + 1))
    fi
done

echo "Varundatud kodukatalooge: $edukad, vigu: $vead"
ls -lh "$varukaust"

if [ $vead -gt 0 ]; then
    exit 3
fi
