#!/usr/bin/env zsh
notify-send "Locking..."
~/.config/hypr/hyprlock/hyprlock-run/panels
hyprctl dispatch exec hyprlock
