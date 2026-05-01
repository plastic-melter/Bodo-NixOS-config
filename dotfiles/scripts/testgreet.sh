#!/usr/bin/env zsh

for greeting in "morning" "afternoon" "evening"; do
  eww update greeting_image="/etc/nixos/dotfiles/images/greetings/${greeting}.jpg"
  eww update greeting_text="Good ${greeting}"
  eww update date_text="$(date +'%A, %B %d, %Y')"
  eww open greeting
  sleep 3
  eww close greeting
  sleep 1
done
