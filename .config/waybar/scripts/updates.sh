#!/bin/bash

# Pobieranie listy aktualizacji (używając checkupdates i yay dla AUR)
# Wymaga zainstalowanego pakietu pacman-contrib
updates_arch=$(checkupdates 2> /dev/null | wc -l)
updates_aur=$(yay -Qum 2> /dev/null | wc -l)

total=$((updates_arch + updates_aur))

if [ "$total" -gt 0 ]; then
    # Pobieramy nazwy paczek do tooltipa i formatujemy je do jednej linii
    list_arch=$(checkupdates 2> /dev/null | awk '{print $1}')
    list_aur=$(yay -Qum 2> /dev/null | awk '{print $1}')
    tooltip=$(echo -e "Arch:\n$list_arch\n\nAUR:\n$list_aur")

    # Używamy jq do bezpiecznego zbudowania JSONa
    jq -nc --arg text "$total" --arg tooltip "$tooltip" \
        '{"text": $text, "tooltip": $tooltip}'
else
    # Jeśli zero, nie wypisuj nic - to powie Waybarowi, by ukrył moduł
    exit 0
fi
