#!/bin/bash
# apache_paigaldus.sh - apache2 teenuse kontroll ja paigaldus
# Autor: Rico Kandi
#
# Kasutamine: sudo sh apache_paigaldus.sh
#
# Kui apache2 ei ole paigaldatud, siis skript paigaldab selle.
# Kui apache2 on juba paigaldatud, siis skript annab sellest teada,
# käivitab teenuse ja näitab teenuse staatust.

# teenuse paigaldamiseks on vaja root õigusi
if [ "$(whoami)" != "root" ]; then
    echo "Skript vajab root õigusi: sudo sh $0"
    exit 1
fi

# dpkg-query näitab paketi staatust, grep -c loeb read, kus on "ok installed"
# tulemus 0 - apache2 ei ole paigaldatud, 1 - apache2 on paigaldatud
APACHE2=$(dpkg-query -W -f='${Status}' apache2 2>/dev/null | grep -c 'ok installed')

if [ $APACHE2 -eq 0 ]; then
    # apache2 ei ole paigaldatud - paigaldame
    echo "apache2 ei ole paigaldatud, paigaldame apache2"
    apt-get update -q
    apt-get install -y apache2
    echo "apache2 on paigaldatud"
elif [ $APACHE2 -eq 1 ]; then
    # apache2 on juba paigaldatud - käivitame teenuse ja näitame staatust
    echo "apache2 on juba paigaldatud"
    systemctl start apache2
    systemctl status apache2 --no-pager
fi
# skripti lõpp
