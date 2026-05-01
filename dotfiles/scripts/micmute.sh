#!/usr/bin/env zsh

# Snatch that mic ID dynamically, no more hardcoding that junk
mic_id=$(wpctl status | grep 'Digital Mic' | awk '{print $3}' | cut -d '.' -f 1)

# If we ain't gettin' no mic ID, bounce out
if [ -z "$mic_id" ]; then
    echo "Yo, where the mic at? Ain't found one, so I'm out."
    exit 1
fi

# Check if that mic muted or vibin'
mute_state=$(wpctl get-volume "$mic_id" | grep -o "MUTED")

if [ "$mute_state" = "MUTED" ]; then
    # Unmute that mic, let it breathe
    wpctl set-mute "$mic_id" 0
    echo "Ayy, mic unmuted! We back in business."
    echo 0 | doas tee /sys/class/leds/platform::micmute/brightness  # Kill the LED flex
    notify-send "マイクミュート解除"
else
    # Mute that mic, cut the noise
    wpctl set-mute "$mic_id" 1
    echo "Shhh... mic muted, silence activated."
    echo 1 | doas tee /sys/class/leds/platform::micmute/brightness  # LED flex ON
    notify-send "マイクミュート"
fi

