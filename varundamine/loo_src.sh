#!/bin/bash
# loo_src.sh - testandmete loomine varundamise harjutuste jaoks
# Autor: Rico Kandi
#
# Kasutamine: ./loo_src.sh [juurkaust]   (vaikimisi ~/praks2)
#
# Loob struktuuri:
#   ~/praks2/src/docs  - tekstifailid (hästi pakitavad)
#   ~/praks2/src/imgs  - pildid (b.jpg)
#   ~/praks2/src/bin   - skript run.sh
#   ~/praks2/backup    - varukoopiate kaust
#   ~/praks2/logs      - logide kaust

juur="${1:-$HOME/praks2}"

mkdir -p "$juur/src/docs" "$juur/src/imgs" "$juur/src/bin" "$juur/backup" "$juur/logs" || exit 1

echo "Praktikumi märkmed" > "$juur/src/docs/markmed.txt"
echo "# Varundamise harjutus" > "$juur/src/docs/README.md"
seq 1 20000 > "$juur/src/docs/numbrid.txt"
head -c 20000 /dev/urandom > "$juur/src/imgs/b.jpg"
head -c 10000 /dev/urandom > "$juur/src/imgs/a.png"
printf '#!/bin/bash\necho "Tere!"\n' > "$juur/src/bin/run.sh"
chmod +x "$juur/src/bin/run.sh"
echo "ajutine" > "$juur/src/docs/vahe.tmp"

echo "Testandmed loodud:"
find "$juur/src" | sort
