#!/bin/bash

# Tühjendab või loob vajalikud tööfailid
clear_files() {
    > player_numbers.txt
    > lottery_numbers.txt
}

# Appendib mängija numbrid faili
save_player_numbers_file() {
    local -n numbers_ref=$1
    printf "%s\n" "${numbers_ref[@]}" >> player_numbers.txt
}

# Appendib loositud numbrid faili
save_lottery_numbers_file() {
    local -n numbers_ref=$1
    printf "%s\n" "${numbers_ref[@]}" >> lottery_numbers.txt
}

# Salvestab koondtulemuse ajaloo faili results.txt
save_game_result() {
    local player_name="$1"
    local -n p_numbers=$2
    local -n l_numbers=$3
    local matches="$4"
    local result_text="$5"
    local current_date
    current_date=$(date)

    {
        echo "========================================"
        echo "Date: $current_date"
        echo "Player: $player_name"
        echo "Player numbers:"
        printf "%s\n" "${p_numbers[@]}"
        echo "Lottery numbers:"
        printf "%s\n" "${l_numbers[@]}"
        echo "Matches: $matches"
        echo "Result: $result_text"
    } >> results.txt
}
