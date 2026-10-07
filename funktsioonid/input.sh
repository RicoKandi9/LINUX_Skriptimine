#!/bin/bash

# Küsib mängija nime
read_player_name() {
    local name
    read -p "Sisesta oma nimi: " name
    if [ -z "$name" ]; then
        name="Unknown"
    fi
    echo "$name"
}

# Valideerib sisendi (täisarv, vahemik 1-50, duplikaadi kontroll)
# Tagastab 0 kui OK, muidu 1
validate_number() {
    local num="$1"
    local -n existing_numbers=$2

    # Kas on täisarv
    if ! [[ "$num" =~ ^[0-9]+$ ]]; then
        echo "Viga: Sisend peab olema täisarv!"
        return 1
    fi

    # Vahemik 1-50
    if [ "$num" -lt 1 ] || [ "$num" -gt 50 ]; then
        echo "Viga: Number peab olema vahemikus 1–50!"
        return 1
    fi

    # Duplikaadi kontroll
    for existing in "${existing_numbers[@]}"; do
        if [ "$existing" -eq "$num" ]; then
            echo "Viga: Oled selle numbri juba valinud! Vali mõni muu number."
            return 1
        fi
    done

    return 0
}

# Küsib mängijalt 5 numbrit
read_player_numbers() {
    local -n player_array=$1

    while [ ${#player_array[@]} -lt 5 ]; do
        local input
        read -p "Sisesta number $(( ${#player_array[@]} + 1 )): " input

        if validate_number "$input" player_array; then
            player_array+=("$input")
        fi
    done
}
