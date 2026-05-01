#!/usr/bin/env zsh
current_hz=$(hyprctl monitors | grep '@' | head -1 | grep -oP '\d+(?=\.\d+000)')
if [ "$current_hz" = "120" ]; then
    hyprctl keyword monitor eDP-1,3072x1920@60,0x0,1
    notify-send "Refresh Rate" "Switched to 60Hz"
else
    hyprctl keyword monitor eDP-1,3072x1920@120,0x0,1
    notify-send "Refresh Rate" "Switched to 120Hz"
fi
