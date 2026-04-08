#!/bin/sh
current=$(hyprctl monitors | grep -oP '\d+\.\d+Hz' | head -1)
if echo "$current" | grep -q "^120"; then
    hyprctl keyword monitor eDP-1,3072x1920@60,0x0,1
    notify-send "Refresh Rate" "Switched to 60Hz"
else
    hyprctl keyword monitor eDP-1,3072x1920@120,0x0,1
    notify-send "Refresh Rate" "Switched to 120Hz"
fi
