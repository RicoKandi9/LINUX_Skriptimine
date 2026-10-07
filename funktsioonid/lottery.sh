#!/bin/bash

# ==============================================================================
# MUUTUJAD JA KONSTANDID
# ==============================================================================
PLAYER_NAME=""
PLAYER_NUMBERS=()
LOTTERY_NUMBERS=()
MATCHES=0
RESULT_TEXT=""

# ==============================================================================
# FUNKTSIOONID
# ==============================================================================

# 1. Päise kuvamine
show_header() {
    echo "========================================"
    echo "            LOTO MÄNG 5/50              "
    echo "========================================"
}

# 2. Vajalike failide tühjendamine/loomine
clear_files() {
    > player_numbers.txt
    > lottery_numbers.txt
}

# 3. Mängija nime küsimine
read_player() {
    read -p "Sisesta oma nimi: " PLAYER_NAME
    if [ -z "$PLAYER_NAME" ]; then
        PLAYER_NAME="Unknown"
    fi
    echo -e "\nTere, $PLAYER_NAME! Vali 5 erinevat numbrit vahemikust 1–50.\n"
}

# 4. Ühe numbri valideerimise abifunktsioon
# Tagastab 0 kui number on korrektne, muidu 1 koos veateatega
validate_number() {
    local num="$1"

    # Kontroll A: kas on täisarv
    if ! [[ "$num" =~ ^[0-9]+$ ]]; then
        echo "Viga: Sisend peab olema täisarv!"
        return 1
    fi

    # Kontroll B: vahemik 1-50
    if [ "$num" -lt 1 ] || [ "$num" -gt 50 ]; then
        echo "Viga: Number peab olema vahemikus 1–50!"
        return 1
    fi

    # Kontroll C: duplikaat juba valitud numbrite hulgas
    for existing in "${PLAYER_NUMBERS[@]}"; do
        if [ "$existing" -eq "$num" ]; then
            echo "Viga: Oled selle numbri juba valinud! Vali mõni muu number."
            return 1
        fi
    done

    return 0
}

# 5. Mängija 5 numbri sisestamine
read_player_numbers() {
    while [ ${#PLAYER_NUMBERS[@]} -lt 5 ]; do
        local input
        read -p "Sisesta number $(( ${#PLAYER_NUMBERS[@]} + 1 )): " input

        if validate_number "$input"; then
            PLAYER_NUMBERS+=("$input")
            echo "$input" >> player_numbers.txt
        fi
    done
}

# 6. Mängija valitud numbrite kuvamine
show_player_numbers() {
    echo -e "\nSinu valitud numbrid:"
    printf "%s\n" "${PLAYER_NUMBERS[@]}"
}

# 7. Loosimine ($RANDOM abil 5 kordumatut numbrit)
generate_lottery_numbers() {
    while [ ${#LOTTERY_NUMBERS[@]} -lt 5 ]; do
        local rand=$(( (RANDOM % 50) + 1 ))
        local duplicate=0

        for existing in "${LOTTERY_NUMBERS[@]}"; do
            if [ "$existing" -eq "$rand" ]; then
                duplicate=1
                break
            fi
        done

        if [ "$duplicate" -eq 0 ]; then
            LOTTERY_NUMBERS+=("$rand")
            echo "$rand" >> lottery_numbers.txt
        fi
    done
}

# 8. Loositud võidunumbrite kuvamine
show_lottery_numbers() {
    echo -e "\n--- LOOSIMINE ---"
    echo "Loositud võidunumbrid:"
    printf "%s\n" "${LOTTERY_NUMBERS[@]}"
}

# 9. Tabamuste kontrollimine ja kuvamine
check_matches() {
    echo -e "\n--- TULEMUSED ---"
    MATCHES=0

    for p_num in "${PLAYER_NUMBERS[@]}"; do
        echo "Kontrollin numbrit $p_num..."
        local is_match=0

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
}

# 10. Hinnangu leidmine ja koondtulemuse kuvamine
show_result() {
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
}

# 11. Tulemuste salvestamine ajaloofiili results.txt
save_result() {
    local current_date
    current_date=$(date)

    {
        echo "========================================"
        echo "Date: $current_date"
        echo "Player: $PLAYER_NAME"
        echo "Player numbers:"
        printf "%s\n" "${PLAYER_NUMBERS[@]}"
        echo "Lottery numbers:"
        printf "%s\n" "${LOTTERY_NUMBERS[@]}"
        echo "Matches: $MATCHES"
        echo "Result: $RESULT_TEXT"
    } >> results.txt
}

# ==============================================================================
# PROGRAMMI PÕHIOSA (Main Execution Flow)
# ==============================================================================
main() {
    show_header
    clear_files
    read_player
    read_player_numbers
    show_player_numbers
    generate_lottery_numbers
    show_lottery_numbers
    check_matches
    show_result
    save_result
}

# Käivita programm
main
