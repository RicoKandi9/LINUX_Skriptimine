#!/bin/bash

# Päise kuvamine
show_header() {
    echo "========================================"
    echo "            LOTO MÄNG 5/50              "
    echo "========================================"
}

# Mängija valitud numbrite kuvamine
show_player_numbers() {
    local -n numbers_ref=$1
    echo -e "\nSinu valitud numbrid:"
    printf "%s\n" "${numbers_ref[@]}"
}

# Loositud võidunumbrite kuvamine
show_lottery_numbers() {
    local -n numbers_ref=$1
    echo -e "\n--- LOOSIMINE ---"
    echo "Loositud võidunumbrid:"
    printf "%s\n" "${numbers_ref[@]}"
}

# Mängu tulemusele teksti ehitamine vastavalt tabamustele
get_result_text() {
    local matches="$1"

    case $matches in
        5) echo "JACKPOT!" ;;
        4) echo "Väga hea tulemus!" ;;
        3) echo "Hea tulemus." ;;
        2) echo "Kaks tabamust." ;;
        1) echo "Üks tabamus." ;;
        0) echo "Seekord tabamusi ei olnud." ;;
    esac
}

# Lõpptulemuse kuvamine
show_final_result() {
    local player_name="$1"
    local matches="$2"
    local result_text="$3"

    echo "Mängija: $player_name"
    echo "Tabamusi: $matches / 5"
    echo "Hinnang: $result_text"
}
