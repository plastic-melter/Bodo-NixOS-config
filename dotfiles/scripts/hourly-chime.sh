#!/usr/bin/env zsh

eww update chime_time="$(date +'%I:%M %p')"
eww update chime_date="$(date +'%A, %B %d')"
eww open hourly-chime

sleep 3
eww close hourly-chime
