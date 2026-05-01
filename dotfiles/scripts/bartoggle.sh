#!/usr/bin/env zsh

# Check if waybar is running using ps and grep
if ps ax | grep -v grep | grep -q "waybar"; then
    # If running, kill waybar
    echo "killing waybar"
    pkill "waybar"
else
    # If not running, start waybar
    echo "starting waybar"
    nohup waybar > /dev/null 2>&1 &
fi


