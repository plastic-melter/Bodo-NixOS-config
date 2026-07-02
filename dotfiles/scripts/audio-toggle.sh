#!/usr/bin/env zsh
CARD="alsa_card.pci-0000_00_1f.3"
ANALOG="output:analog-stereo+input:analog-stereo"
OPTICAL="output:iec958-stereo+input:analog-stereo"

current=$(pactl list cards \
  | grep -A99 "$CARD" \
  | grep -m1 "Active Profile:" \
  | sed 's/.*Active Profile: //')

if [ "$current" = "$OPTICAL" ]; then
  pactl set-card-profile "$CARD" "$ANALOG"
  notify-send "Audio" "→ Analog (speakers/aux)" -t 1500
else
  pactl set-card-profile "$CARD" "$OPTICAL"
  notify-send "Audio" "→ Optical (S/PDIF)" -t 1500
fi
