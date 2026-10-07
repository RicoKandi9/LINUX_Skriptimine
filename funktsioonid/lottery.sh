#!/bin/bash

# Laadime moodulid (abifailid)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/files.sh"
source "$SCRIPT_DIR/input.sh"
source "$SCRIPT_DIR/lottery_functions.sh"
source "$SCRIPT_DIR/result.sh"

main() {
    local player_name=""
    local player_numbers=()
    local lottery_numbers=()
    local matches=0
    local result_text=""

    # 1. Alustamine ja ettevalmistus
    show_header
    clear_files

    # 2. Sisendi kogumine
    player_name=$(read_player_name)
    echo -e "\nTere, $player_name! Vali 5 erinevat numbrit vahemikust 1–50.\n"

    read_player_numbers player_numbers
    save_player_numbers_file player_numbers
    show_player_numbers player_numbers

    # 3. Loosimine
    generate_lottery_numbers lottery_numbers
    save_lottery_numbers_file lottery_numbers
    show_lottery_numbers lottery_numbers

    # 4. Tulemuste analüüs
    matches=$(check_matches player_numbers lottery_numbers)
    result_text=$(get_result_text "$matches")

    # 5. Tulemuste väljastus ja salvestamine
    show_final_result "$player_name" "$matches" "$result_text"
    save_game_result "$player_name" player_numbers lottery_numbers "$matches" "$result_text"
}

# Käivita põhiprogramm
main
