#!/bin/bash
# backupexec.sh - automaatne varukoopia kuupäeva ja kontrolliga (samm 12)
# Autor: Rico Kandi
#
# Kasutamine: ./backupexec.sh [-n] [-k N] [-c auto|zstd|xz|gzip] [-s lähtekaust] [-d sihtkaust]
#   -n  kuiv jooks: näitab, mis failid läheksid arhiivi, arhiivi ei tehta
#   -k  mitu viimast koopiat alles jätta (vaikimisi 3)
#   -c  kompressor; auto = proovib kõiki olemasolevaid ja valib väikseima arhiivi (vaikimisi)
#   -s  varundatav kaust (vaikimisi ~/praks2/src)
#   -d  varukoopiate kaust (vaikimisi ~/praks2/backup)
#   -h  abi
#
# Mida skript teeb (sammud 1-11 ühes skriptis):
#   1. kontrollib parameetreid ja lähtekausta olemasolu
#   2. loeb välistused failist <lähtekaust>/.backupignore (--exclude-from)
#   3. kuiva jooksu korral näitab ainult failide nimekirja (tar -tv)
#   4. kontrollib vaba ruumi (du -sb ja df -B1)
#   5. kontrollib, et sama nimega arhiivi juba ei ole
#   6. pakib ajutises kaustas (mktemp -d) ja valib kompressori (zstd / xz / gzip)
#   7. kontrollib arhiivi: avaneb, sisaldab alamkaustu ja kõiki faile
#   8. arvutab SHA-256 kontrollsumma ja kontrollib seda varukoopiate kaustas
#   9. jätab alles ainult N viimast koopiat
#  10. logib kõik sammud faili ~/praks2/logs/backup.log ja kustutab ajutised failid (trap)
#
# Väljumiskoodid: 0 OK, 1 vale kasutus, 2 lähtekaust puudub, 3 arhiiv on juba olemas,
#                 4 ruumi on liiga vähe, 5 pakkimine ebaõnnestus, 6 kontroll ebaõnnestus

# kui skript käivitati käsuga sh, käivitatakse see uuesti bash-iga (massiivid on vaja)
if [ -z "$BASH_VERSION" ]; then
    exec bash "$0" "$@"
fi

ALLIKAS=~/praks2/src
SIHT=~/praks2/backup
LOGI=~/praks2/logs/backup.log
HOIA=3
KOMPRESSOR=auto
KUIV=0
AJUTINE=""

kasutus() {
    sed -n '5,11p' "$0" | sed 's/^# \{0,1\}//'
    exit 1
}

while getopts "nk:c:s:d:h" valik
do
    case "$valik" in
        n) KUIV=1 ;;
        k) HOIA=$OPTARG ;;
        c) KOMPRESSOR=$OPTARG ;;
        s) ALLIKAS=$OPTARG ;;
        d) SIHT=$OPTARG ;;
        *) kasutus ;;
    esac
done

mkdir -p "$(dirname "$LOGI")" || exit 1

# log TASE TEKST - kirjutab rea ekraanile ja logifaili
log() {
    tase=$1
    shift
    printf '[ %s ] %-5s %s\n' "$(date '+%F %T')" "$tase" "$*" | tee -a "$LOGI"
}

# lõpetamisel kustutatakse ajutised failid ja logitakse tulemus
lopp() {
    kood=$?
    if [ -n "$AJUTINE" ] && [ -d "$AJUTINE" ]; then
        rm -rf "$AJUTINE"
        echo "Ajutised failid kustutatud"
    fi
    if [ $kood -eq 0 ]; then
        log INFO "BACKUP END: edukas"
    else
        log VIGA "BACKUP END: ebaõnnestus (kood $kood)"
    fi
}
trap lopp EXIT

# --- 1. parameetrite kontroll ---
case "$HOIA" in
    ''|*[!0-9]*|0) echo "Viga: -k väärtus peab olema positiivne täisarv"; trap - EXIT; exit 1 ;;
esac
case "$KOMPRESSOR" in
    auto|zstd|xz|gzip) ;;
    *) echo "Viga: tundmatu kompressor $KOMPRESSOR"; trap - EXIT; exit 1 ;;
esac

log INFO "BACKUP START: $ALLIKAS -> $SIHT (kompressor: $KOMPRESSOR, alles jäetakse $HOIA)"

if [ ! -d "$ALLIKAS" ]; then
    log VIGA "Lähtekausta $ALLIKAS ei ole olemas"
    exit 2
fi
ALLIKAS=$(cd "$ALLIKAS" && pwd)
VANEM=$(dirname "$ALLIKAS")
NIMI=$(basename "$ALLIKAS")
mkdir -p "$SIHT" || exit 2
SIHT=$(cd "$SIHT" && pwd)

# ajutine kaust samas failisüsteemis, et valmis arhiivi saaks kiiresti liigutada
AJUTINE=$(mktemp -d "$SIHT/.tmp.XXXXXX") || exit 5

# --- 2. välistused .backupignore failist ---
# kommentaarid ja tühjad read jäetakse välja, lõpus olev / eemaldatakse (tar ei tunne "imgs/")
VALISTUS=()
if [ -f "$ALLIKAS/.backupignore" ]; then
    sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e 's#/*$##' -e '/^$/d' "$ALLIKAS/.backupignore" > "$AJUTINE/ignore"
    VALISTUS=(--exclude-from="$AJUTINE/ignore")
    log INFO ".backupignore välistused: $(tr '\n' ' ' < "$AJUTINE/ignore")"
fi

# --- 3. kuiv jooks ---
if [ $KUIV -eq 1 ]; then
    log INFO "Kuiv jooks: arhiivi ei tehta, arhiivi läheksid järgmised failid:"
    tar -cf - "${VALISTUS[@]}" -C "$VANEM" "$NIMI" | tar -tvf -
    log INFO "Kokku $(tar -cf - "${VALISTUS[@]}" -C "$VANEM" "$NIMI" | tar -tf - | wc -l) kirjet"
    exit 0
fi

# --- 4. vaba ruumi kontroll (varuga: ajutised arhiivid + valmis arhiiv) ---
vaja=$(du -sb "$ALLIKAS" | awk '{print $1}')
vaba=$(df -B1 "$SIHT" | awk 'NR==2{print $4}')
if [ "$vaba" -le $((vaja * 2)) ]; then
    log VIGA "Ruumi on liiga vähe: vaja ~$((vaja * 2)) baiti, vaba $vaba baiti"
    exit 4
fi
log INFO "Ruumi piisab: lähtekaust $vaja baiti, vaba $vaba baiti"

# --- 5. kas sama nimega arhiiv on juba olemas ---
AEG=$(date +%F_%H-%M-%S)
ALUS="${NIMI}_$AEG"
if ls "$SIHT/$ALUS".tar.* > /dev/null 2>&1; then
    log VIGA "Arhiiv $ALUS on juba olemas, uut ei tehta"
    exit 3
fi

# --- 6. pakkimine ja kompressori valik ---
# pakkimine KOMPRESSOR -> loob faili ajutisse kausta ja prindib selle nime
paki() {
    case "$1" in
        zstd) laiend=tar.zst; valikud=(-I 'zstd -19 -T0') ;;
        xz)   laiend=tar.xz;  valikud=(-J) ;;
        gzip) laiend=tar.gz;  valikud=(-z) ;;
    esac
    tar "${valikud[@]}" -cf "$AJUTINE/$ALUS.$laiend" "${VALISTUS[@]}" -C "$VANEM" "$NIMI" 2>> "$AJUTINE/vead" || return 1
    echo "$ALUS.$laiend"
}

if [ "$KOMPRESSOR" = auto ]; then
    proovida="zstd xz gzip"
else
    proovida=$KOMPRESSOR
fi

PARIM=""
PARIM_SUURUS=0
for k in $proovida
do
    if ! command -v "$k" > /dev/null 2>&1; then
        log HOIAT "Kompressorit $k ei ole süsteemis, jätan vahele"
        continue
    fi
    fail=$(paki "$k") || { log HOIAT "Pakkimine kompressoriga $k ebaõnnestus"; continue; }
    suurus=$(stat -c %s "$AJUTINE/$fail")
    log INFO "Kompressor $k: $fail $suurus baiti"
    if [ -z "$PARIM" ] || [ "$suurus" -lt "$PARIM_SUURUS" ]; then
        PARIM=$fail
        PARIM_SUURUS=$suurus
    fi
done

if [ -z "$PARIM" ]; then
    log VIGA "Arhiivi loomine ebaõnnestus: $(cat "$AJUTINE/vead" 2> /dev/null)"
    exit 5
fi
log INFO "Valitud arhiiv: $PARIM ($(du -h "$AJUTINE/$PARIM" | cut -f1))"

# --- 7. arhiivi kontroll ---
# tar tunneb lugemisel pakkimisviisi ise ära
if ! tar -tf "$AJUTINE/$PARIM" > "$AJUTINE/sisu.txt" 2>> "$AJUTINE/vead"; then
    log VIGA "Arhiiv ei avane"
    exit 6
fi
alamkaustad=$(grep -c "^$NIMI/[^/]*/$" "$AJUTINE/sisu.txt")
if [ "$alamkaustad" -lt 1 ]; then
    log VIGA "Arhiivis ei ole alamkaustu"
    exit 6
fi
log INFO "Arhiiv avaneb, alamkaustad: $(grep "^$NIMI/[^/]*/$" "$AJUTINE/sisu.txt" | tr '\n' ' ')"
oodatud=$(tar -cf - "${VALISTUS[@]}" -C "$VANEM" "$NIMI" | tar -tf - | wc -l)
tegelik=$(wc -l < "$AJUTINE/sisu.txt")
if [ "$oodatud" -ne "$tegelik" ]; then
    log VIGA "Arhiivis on $tegelik kirjet, oodati $oodatud"
    exit 6
fi
log INFO "Kõik $tegelik kirjet on arhiivis"

# --- 8. SHA-256 kontrollsumma ---
(cd "$AJUTINE" && sha256sum "$PARIM" > "$PARIM.sha256") || exit 6
mv "$AJUTINE/$PARIM" "$AJUTINE/$PARIM.sha256" "$SIHT/" || exit 6
if (cd "$SIHT" && sha256sum -c "$PARIM.sha256" > /dev/null 2>&1); then
    log INFO "SHA-256 kontroll: $PARIM: OK ($(cut -c1-16 < "$SIHT/$PARIM.sha256")...)"
else
    log VIGA "SHA-256 kontroll: $PARIM: FAILED"
    exit 6
fi

# --- 9. ainult N viimast koopiat ---
ls -1t "$SIHT/${NIMI}_"*.tar.* 2> /dev/null | grep -v '\.sha256$' | tail -n +$((HOIA + 1)) | while read -r vana
do
    rm -f "$vana" "$vana.sha256"
    log INFO "Kustutatud vana koopia: $(basename "$vana")"
done

echo
echo "Varukoopia valmis: $SIHT/$PARIM"
echo "Alles olevad koopiad:"
ls -1t "$SIHT/${NIMI}_"*.tar.* | grep -v '\.sha256$'
