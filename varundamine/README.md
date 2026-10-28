# Andmete varundamine (backupi tegemine)

## 1. Kasutajate kodukataloogide varundamine

Iga kasutaja kodukataloog arhiveeritakse ja pakitakse koos kuupäevaga (nt `kasutaja1.28.10.2026.tar.gz`)
ning kopeeritakse eraldi kataloogi `/home_bcp`.

Käsitsi katsetamine ühe kasutaja näitel:

```bash
sudo mkdir -p /home_bcp && sudo chmod 700 /home_bcp            # varukaust
sudo tar -czf /tmp/kasutaja1.$(date +%d.%m.%Y).tar.gz -C /home kasutaja1   # arhiveerimine + pakkimine
sudo cp /tmp/kasutaja1.$(date +%d.%m.%Y).tar.gz /home_bcp/      # kopeerimine varukausta
sudo tar -tzf /home_bcp/kasutaja1.$(date +%d.%m.%Y).tar.gz      # kontroll
```

Kõigi kasutajate jaoks: `sudo ./kodukataloogide_varundus.sh` (tulemus failis `kodukataloogide_varundus.txt`).
Skript töötab sõltumata käivitamise kaustast (`tar -C /home`), arhiivid tehakse ajutises kaustas
(`mktemp -d`) ja kopeeritakse `/home_bcp` kausta.

## 2. Varukoopia kuupäevaga ja kontrolliga (~/praks2)

| Fail | Kirjeldus |
|------|-----------|
| `loo_src.sh` | loob testandmed `~/praks2/src` (docs, imgs, bin) ning kaustad backup ja logs |
| `sammud.sh` | sammud 1-11 eraldi käskudena, väljund failis `sammud_valjund.txt` |
| `backupexec.sh` | samm 12: kõik sammud ühes automaatses skriptis |
| `.backupignore.naide` | näide välistuste failist (kopeeri `~/praks2/src/.backupignore`) |

| Samm | Käsk |
|------|------|
| 1. varukoopia | `tar -I 'zstd -19 -T0' -cf ~/praks2/backup/src_$(date +%F_%H-%M-%S).tar.zst -C ~/praks2 src` |
| 2. kontroll | `tar -I 'zstd -d' -tf fail.tar.zst \| head -n 5` |
| 3. suurus | `du -h ~/praks2/backup/src_*.tar.zst \| awk '{print $1}'` |
| 4. 3 viimast | `ls -1t src_*.tar.zst \| tail -n +4 \| xargs -r rm -f` |
| 5. välistamine | `tar ... --exclude='*.jpg' --exclude='bin' ...` |
| 6. kuiv jooks | `tar -cf - -C ~/praks2 src \| tar -tvf -` |
| 7. logimine | `echo "[ $(date '+%F %T') ] BACKUP START" >> ~/praks2/logs/backup.log` |
| 8. vaba ruum | `du -sb ~/praks2/src` ja `df -B1 ~/praks2/backup \| awk 'NR==2{print $4}'` |
| 9. SHA-256 | `sha256sum fail.tar.zst > fail.tar.zst.sha256; sha256sum -c fail.tar.zst.sha256` |
| 10. kompressorid | `tar -I 'zstd -19 -T0' -cf`, `tar -czf`, `tar -cJf` |
| 11. .backupignore | `tar --exclude-from=~/praks2/src/.backupignore ...` |

## backupexec.sh

```bash
./backupexec.sh            # varukoopia, kompressor valitakse automaatselt (väikseim arhiiv)
./backupexec.sh -n         # kuiv jooks
./backupexec.sh -c zstd -k 5   # kindel kompressor, 5 viimast koopiat
./backupexec.sh -h         # abi
```

Skript kontrollib parameetreid, lähtekausta, vaba ruumi ja sama nimega arhiivi olemasolu,
pakib ajutises kaustas (`mktemp -d`, `trap ... EXIT` kustutab selle), valib kompressori,
kontrollib et arhiiv avaneb, sisaldab alamkaustu ja kõiki faile, arvutab ning kontrollib
SHA-256 summa, jätab alles N viimast koopiat ja logib kõik faili `~/praks2/logs/backup.log`.
Tulemus on failis `backupexec_valjund.txt`.

Märkus: GNU tar ei arvesta välistust kujul `imgs/` (lõpus kaldkriips), seepärast eemaldab
`backupexec.sh` `.backupignore` ridadelt lõpus oleva `/` enne `--exclude-from` kasutamist.
