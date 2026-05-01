#!/usr/bin/env zsh

# Toggle mute state using wpctl
wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

# Check the current mute state
MUTE_STATE=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -oE '[^ ]+$')

if [ "$MUTE_STATE" = "[MUTED]" ]; then
    # Send a notification for mute
    notify-send "音量ミュート"
else
    # Send a notification for unmute
    notify-send "音量ミュート解除"
fi

