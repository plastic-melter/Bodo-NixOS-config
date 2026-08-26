#!/usr/bin/env zsh

mic_id=$(wpctl status | grep 'Digital Mic' | awk '{print $3}' | cut -d '.' -f 1)

if [ -z "$mic_id" ]; then
    echo "Couldn't find the mic."
    exit 1
fi

mute_state=$(wpctl get-volume "$mic_id" | grep -o "MUTED")

if [ "$mute_state" = "MUTED" ]; then
    wpctl set-mute "$mic_id" 0
    echo "Mic unmuted successfully."
    echo 0 | doas tee /sys/class/leds/platform::micmute/brightness # LED off
    notify-send "Mic un-muted"
else
    wpctl set-mute "$mic_id" 1
    echo "Mic muted successfully."
    echo 1 | doas tee /sys/class/leds/platform::micmute/brightness # LED on
    notify-send "Mic muted"
fi

