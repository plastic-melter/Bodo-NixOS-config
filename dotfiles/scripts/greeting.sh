#!/usr/bin/env zsh

hour=$(date +%H)

if [ $hour -lt 12 ]; then
  greeting="Good morning"
  image="/etc/nixos/dotfiles/images/greetings/clock.jpg"
elif [ $hour -lt 17 ]; then
  greeting="Good afternoon"
  image="/etc/nixos/dotfiles/images/greetings/clock.jpg"
else
  greeting="Good evening"
  image="/etc/nixos/dotfiles/images/greetings/clock.jpg"
fi

date_text="$(date +'%A, %B %d, %Y')"

# Update eww variables and open window
eww update greeting_image="$image"
eww update greeting_text="${greeting}..."
eww update date_text="$date_text"
eww open greeting

# Close after 3 seconds
sleep 3
eww close greeting
