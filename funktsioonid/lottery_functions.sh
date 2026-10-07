#!/bin/bash

# Loosib 5 kordumatut numbrit vahemikus 1–50
generate_lottery_numbers() {
    local -n lottery_array=$1

    while [ ${#lottery_array[@]} -lt 5 ]; do
        local rand=$(( (RANDOM % 50) + 1 ))
        local duplicate=0

        for existing in "${lottery_array[@]}"; do
            if [ "$existing" -eq "$rand" ]; then
                duplicate=1
                break
            fi
        done

        if [ "$duplicate" -eq 0 ]; then
            lottery_array+=("$rand")
        fi
    done
}

# Võrdleb mängija ja loositud numbreid, kuvab teated ning tagastab tabamuste arvu
check_matches() {
    local -n p_numbers=$1
    local -n l_numbers=$2
    local matches=0

    echo -e "\n--- TULEMUSED ---"
    for p_num in "${p_numbers[@]}"; do
        echo "Kontrollin numbrit $p_num..."
        local is_match=0

        for l_num in "${l_numbers[@]}"; do
            if [ "$p_num" -eq "$l_num" ]; then
                is_match=1
                break
            fi
        done

        if [ "$is_match" -eq 1 ]; then
            echo -e "TABAMUS!\n"
            matches=$((matches + 1))
        else
            echo -e "Ei tabanud.\n"
        fi
    done

    echo "$matches"
}
