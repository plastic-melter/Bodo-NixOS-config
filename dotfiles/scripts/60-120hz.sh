#!/usr/bin/env zsh

rate=$(hyprctl monitors | grep '@' | head -n 1 | cut -d '@' -f 2 | cut -d '.' -f 1)

if [ "$rate" = "60" ]; then
    hyprctl keyword monitor eDP-1,3072x1920@120,auto,1
    notify-send "Display" "Switched to 120Hz"
else
    hyprctl keyword monitor eDP-1,3072x1920@60,auto,1
    notify-send "Display" "Switched to 60Hz"
fi
