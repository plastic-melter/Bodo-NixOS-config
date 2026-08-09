#!/usr/bin/env zsh
# display.zsh [hz|60|165]
MON=eDP-1
RATES=(165 60)

apply() {
  local mode=$(wlr-randr --json | jq -r --arg m "$MON" --argjson r "$1" '
    .[] | select(.name==$m) | .modes
    | map(select(.width==2560 and .height==1600))
    | min_by(((.refresh - $r) | length))
    | "\(.width)x\(.height)@\((.refresh*1000|round)/1000)"')
  wlr-randr --output $MON --mode "$mode" || { notify-send "Display" "failed: $mode"; return 1; }
  notify-send -h string:x-canonical-private-synchronous:display "Display" "$1 Hz"
  pkill -RTMIN+10 waybar
}

hz=$(wlr-randr --json | jq -r --arg m "$MON" \
       '.[]|select(.name==$m)|.modes[]|select(.current)|.refresh|round')

case "$1" in
  ""|hz) i=${RATES[(Ie)$hz]}
         (( i == 0 )) && i=$#RATES
         apply ${RATES[$(( i % $#RATES + 1 ))]} ;;
  60|165) apply $1 ;;
  *) print -u2 "usage: $0 [hz|60|165]"; exit 1 ;;
esac
