#!/usr/bin/env zsh
current_hz=$(hyprctl monitors | grep '@' | head -1 | grep -oP '\d+(?=\.\d+000)')
if [ "$current_hz" = "165" ]; then
    hyprctl keyword monitor eDP-1,2560x1600@60,0x0,1
    notify-send "Refresh Rate" "Switched to 60Hz"
else
    hyprctl keyword monitor eDP-1,2560x1600@165,0x0,1
    notify-send "Refresh Rate" "Switched to 165Hz"
fi
