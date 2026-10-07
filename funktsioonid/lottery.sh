#!/bin/bash

# 1. Tühjenda või loo vajalikud failid iga uue mängu alguses
> player_numbers.txt
> lottery_numbers.txt

# 2. Küsi mängija nime (kui nime ei sisestata, kasuta 'Unknown')
read -p "Sisesta oma nimi: " PLAYER_NAME
if [ -z "$PLAYER_NAME" ]; then
    PLAYER_NAME="Unknown"
fi

echo -e "\nTere, $PLAYER_NAME! Vali 5 erinevat numbrit vahemikust 1–50.\n"

# 3. Mängija numbrite sisestamine ja kontroll
PLAYER_NUMBERS=()

while [ ${#PLAYER_NUMBERS[@]} -lt 5 ]; do
    read -p "Sisesta number $(( ${#PLAYER_NUMBERS[@]} + 1 )): " num

    # Kontroll A: kas midagi sisestati ja kas tegemist on täisarvuga
    if ! [[ "$num" =~ ^[0-9]+$ ]]; then
        echo "Viga: Sisend peab olema täisarv!"
        continue
    fi

    # Kontroll B: kas number on vahemikus 1–50
    if [ "$num" -lt 1 ] || [ "$num" -gt 50 ]; then
        echo "Viga: Number peab olema vahemikus 1–50!"
        continue
    fi

    # Kontroll C: kas sama numbrit on juba varem valitud
    duplicate=0
    for existing in "${PLAYER_NUMBERS[@]}"; do
        if [ "$existing" -eq "$num" ]; then
            duplicate=1
            break
        fi
    done

    if [ "$duplicate" -eq 1 ]; then
        echo "Viga: Oled selle numbri juba valinud! Vali mõni muu number."
        continue
    fi

    # Kui kõik kontrollid läbitud, lisatakse number massiivi ja faili
    PLAYER_NUMBERS+=("$num")
    echo "$num" >> player_numbers.txt
done

echo -e "\nSinu valitud numbrid:"
printf "%s\n" "${PLAYER_NUMBERS[@]}"

# 4. Loosimine ($RANDOM abil 5 kordumatut numbrit vahemikus 1–50)
LOTTERY_NUMBERS=()

while [ ${#LOTTERY_NUMBERS[@]} -lt 5 ]; do
    # $RANDOM annab numbri 0..32767 -> % 50 annab 0..49 -> + 1 annab 1..50
    random_num=$(( (RANDOM % 50) + 1 ))

    duplicate=0
    for existing in "${LOTTERY_NUMBERS[@]}"; do
        if [ "$existing" -eq "$random_num" ]; then
            duplicate=1
            break
        fi
    done

    if [ "$duplicate" -eq 0 ]; then
        LOTTERY_NUMBERS+=("$random_num")
        echo "$random_num" >> lottery_numbers.txt
    fi
done

echo -e "\n--- LOOSIMINE ---"
echo "Loositud võidunumbrid:"
printf "%s\n" "${LOTTERY_NUMBERS[@]}"

# 5. Tulemuse kontrollimine
echo -e "\n--- TULEMUSED ---"
MATCHES=0

for p_num in "${PLAYER_NUMBERS[@]}"; do
    echo "Kontrollin numbrit $p_num..."
    is_match=0
    for l_num in "${LOTTERY_NUMBERS[@]}"; do
        if [ "$p_num" -eq "$l_num" ]; then
            is_match=1
            break
        fi
    done

    if [ "$is_match" -eq 1 ]; then
        echo -e "TABAMUS!\n"
        MATCHES=$((MATCHES + 1))
    else
        echo -e "Ei tabanud.\n"
    fi
done

# Hinnangu määramine vastavalt tabamuste arvule
case $MATCHES in
    5) RESULT_TEXT="JACKPOT!" ;;
    4) RESULT_TEXT="Väga hea tulemus!" ;;
    3) RESULT_TEXT="Hea tulemus." ;;
    2) RESULT_TEXT="Kaks tabamust." ;;
    1) RESULT_TEXT="Üks tabamus." ;;
    0) RESULT_TEXT="Seekord tabamusi ei olnud." ;;
esac

echo "Mängija: $PLAYER_NAME"
echo "Tabamusi: $MATCHES / 5"
echo "Hinnang: $RESULT_TEXT"

# 6. Tulemuste salvestamine faili results.txt (faili lõppu lisamine: >>)
CURRENT_DATE=$(date)

{
    echo "========================================"
    echo "Date: $CURRENT_DATE"
    echo "Player: $PLAYER_NAME"
    echo "Player numbers:"
    printf "%s\n" "${PLAYER_NUMBERS[@]}"
    echo "Lottery numbers:"
    printf "%s\n" "${LOTTERY_NUMBERS[@]}"
    echo "Matches: $MATCHES"
    echo "Result: $RESULT_TEXT"
} >> results.txt
