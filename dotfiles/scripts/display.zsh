#!/usr/bin/env zsh
# display.zsh [hz|60|120|165]

MON=eDP-1
RATES=(60 120 165)

hz=$(hyprctl -j monitors | jq -r --arg m "$MON" \
       '.[] | select(.name==$m) | .refreshRate|round')

apply() {
  hyprctl keyword monitor "$MON,2560x1600@$1,0x0,1,vrr,2"
  notify-send -h string:x-canonical-private-synchronous:display "Display" "$1 Hz"
  pkill -RTMIN+10 waybar
}

case "$1" in
  ""|hz) i=${RATES[(i)$hz]}; (( i > $#RATES )) && i=0
         apply ${RATES[$(( i % $#RATES + 1 ))]} ;;
  60|120|165) apply $1 ;;
  *) echo "usage: $0 [hz|60|120|165]" >&2; exit 1 ;;
esac
