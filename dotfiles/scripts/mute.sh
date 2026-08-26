#!/usr/bin/env zsh

wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

MUTE_STATE=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -oE '[^ ]+$')

if [ "$MUTE_STATE" = "[MUTED]" ]; then
    notify-send "Volume muted"
else
    notify-send "Volume un-muted"
fi
