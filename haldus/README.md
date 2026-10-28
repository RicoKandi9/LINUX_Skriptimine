# BASH haldus - praks1: kasutajate haldus

Kasutajaid saab hallata ainult root, seepärast käivitatakse skriptid `sudo` abil.

| Ülesanne | Skript | Andmefail(id) |
|----------|--------|---------------|
| 1. kasutaja loomine parameetriga | `lisa_kasutaja` | - |
| 2. kasutajad failist | `kasutajad_failist` (kutsub `lisa_kasutaja`) | `kasutajad` |
| 3. kasutajad paroolidega failist | `kasutajad_failist_parooliga` | `kasutajad_paroolid` (kasutaja:parool) |
| 4. kasutajad ja paroolid eraldi | `kasutajad_paroolid_eraldi` | `kasutajanimed`, `paroolid` |
| 5. paroolide genereerimine ja logimine | `kasutajad_paroolid_genereeritud` | `uued_kasutajad` |
| 6. root kasutaja kontroll | `kasutajad_paroolid_genereeritud` | - |
| abiskript | `kustuta_kasutajad` (userdel -r) | ükskõik milline ülaltoodud fail |

## Kontrollimine

```bash
chmod +x lisa_kasutaja kasutajad_failist kasutajad_failist_parooliga \
         kasutajad_paroolid_eraldi kasutajad_paroolid_genereeritud kustuta_kasutajad

sudo sh lisa_kasutaja testkasutaja                     # 1
sudo sh kasutajad_failist kasutajad                    # 2
sudo sh kustuta_kasutajad kasutajad                    # vanad kasutaja1-3 ära
sudo sh kasutajad_failist_parooliga kasutajad_paroolid # 3
sudo sh kasutajad_paroolid_eraldi kasutajanimed paroolid           # 4
sudo sh kasutajad_paroolid_genereeritud uued_kasutajad             # 5
sudo cat loodud_kasutajad_paroolidega
sh kasutajad_paroolid_genereeritud uued_kasutajad      # 6 - tavakasutajana keelatud

cat /etc/passwd | grep kasutaja
sudo cat /etc/shadow | grep kasutaja
```

## Märkused

- `useradd -m` loob kodukataloogi ja kopeerib sinna `/etc/skel` peidetud failid (`.bashrc`, `.profile`, `.bash_logout`).
- `chpasswd` salvestab parooli räsi faili `/etc/shadow`.
- Viimane rida loetakse ka siis, kui faili lõpus pole reavahetust (`|| [ -n "$rida" ]`).
- Genereeritud paroolide logi `loodud_kasutajad_paroolidega` on õigustega 600 ja `.gitignore` failis,
  et paroolid GitHubi ei satuks.
- Ülesanne 6: kontroll `whoami` abil - kui käivitaja ei ole root, lõpetab skript töö (kood 4).
