#!/bin/bash
# sammud.sh - ülesande "Varukoopia kuupäevaga ja kontrolliga" sammud 1-11
# Autor: Rico Kandi
#
# Kasutamine: ./sammud.sh | tee sammud_valjund.txt
# Eeldus: testandmed on loodud (./loo_src.sh), kaust ~/praks2/src on olemas.
# Iga samm näitab käsku ja selle tulemust. Samm 12 on eraldi skript backupexec.sh.

P=~/praks2
B=$P/backup
T=$B/test            # võrdlusarhiivid (sammud 5, 10, 11), et need ei segaks rotatsiooni
mkdir -p "$B" "$T" "$P/logs"

samm() { echo; echo "===== $1 ====="; }
aeg() { date +%F_%H-%M-%S; }

samm "1) Lihtne varukoopia .tar.zst"
# -I 'zstd -19 -T0' paki zstd-ga (19 = tugev, T0 = kõik tuumad), -c loo, -f fail, -C liigu kausta
tar -I 'zstd -19 -T0' -cf "$B/src_$(aeg).tar.zst" -C "$P" src
ARCHIVE="$(ls -1t "$B"/src_*.tar.zst | head -n1)"
echo "Loodud: $ARCHIVE"

samm "2) Arhiivi kontrollimine"
# -t näita sisu, -I 'zstd -d' paki lahti zstd-ga
tar -I 'zstd -d' -tf "$ARCHIVE" | head -n 5

samm "3) Varukoopia suurus"
du -h "$ARCHIVE" | awk '{print $1}'

samm "4) Ainult 3 viimast koopiat"
for i in 1 2 3 4
do
    sleep 1
    tar -I 'zstd -19 -T0' -cf "$B/src_$(aeg).tar.zst" -C "$P" src
done
echo "Enne: $(ls -1 "$B"/src_*.tar.zst | wc -l) koopiat"
cd "$B" || exit 1
# ls -1t uuemad ees, tail -n +4 jätab 3 esimest vahele, xargs -r rm -f kustutab ülejäänud
ls -1t src_*.tar.zst | tail -n +4 | xargs -r rm -f
echo "Pärast: $(ls -1 src_*.tar.zst | wc -l) koopiat"
ls -1t src_*.tar.zst
cd - > /dev/null || exit 1

samm "5) Failide välistamine (*.jpg ja bin)"
tar -I 'zstd -19 -T0' -cf "$T/valistus.tar.zst" --exclude='*.jpg' --exclude='bin' -C "$P" src
tar -I 'zstd -d' -tf "$T/valistus.tar.zst"
if tar -I 'zstd -d' -tf "$T/valistus.tar.zst" | grep -E 'b\.jpg|run\.sh'; then
    echo "VIGA: välistatud failid on arhiivis"
else
    echo "OK: b.jpg ja run.sh ei ole arhiivis"
fi

samm "6) Kuiv jooks (arhiivi ei teki)"
enne=$(ls -1 "$B" | wc -l)
tar -cf - -C "$P" src | tar -tvf -
parast=$(ls -1 "$B" | wc -l)
echo "Faile kaustas backup enne: $enne, pärast: $parast"

samm "7) Logimine"
LOG=$P/logs/backup.log
echo "[ $(date '+%F %T') ] BACKUP START" >> "$LOG"
tar -I 'zstd -19 -T0' -cf "$B/src_$(aeg).tar.zst" -C "$P" src
printf '[ %s ] BACKUP END (%s)\n' "$(date '+%F %T')" "$(ls -1t "$B"/src_*.tar.zst | head -n1)" >> "$LOG"
tail -n 4 "$LOG"

samm "8) Vaba ruumi kontroll"
vaja=$(du -sb "$P/src" | awk '{print $1}')
vaba=$(df -B1 "$B" | awk 'NR==2{print $4}')
echo "Vaja: $vaja baiti, vaba: $vaba baiti"
if [ "$vaba" -gt "$vaja" ]; then
    echo "OK: ruumi piisab, varundus võib alata"
else
    echo "VIGA: ruumi on liiga vähe, varundust ei alustata"
fi

samm "9) SHA-256 kontrollsumma"
ARCHIVE="$(ls -1t "$B"/src_*.tar.zst | head -n1)"
cd "$B" || exit 1
sha256sum "$(basename "$ARCHIVE")" > "$(basename "$ARCHIVE").sha256"
cat "$(basename "$ARCHIVE").sha256"
sha256sum -c "$(basename "$ARCHIVE").sha256"
cd - > /dev/null || exit 1

samm "10) Kompressorite võrdlus"
tar -I 'zstd -19 -T0' -cf "$T/src.tar.zst" -C "$P" src
tar -czf "$T/src.tar.gz" -C "$P" src
tar -cJf "$T/src.tar.xz" -C "$P" src
ls -l "$T"/src.tar.*

samm "11) .backupignore kasutamine"
printf 'imgs\n*.tmp\n' > "$P/src/.backupignore"
echo ".backupignore sisu:"; cat "$P/src/.backupignore"
tar -I 'zstd -19 -T0' -cf "$T/ignore.tar.zst" --exclude-from="$P/src/.backupignore" -C "$P" src
tar -I 'zstd -d' -tf "$T/ignore.tar.zst"
if tar -I 'zstd -d' -tf "$T/ignore.tar.zst" | grep -q 'imgs'; then
    echo "VIGA: imgs on arhiivis"
else
    echo "OK: imgs kausta ja .tmp faile arhiivis ei ole"
fi
