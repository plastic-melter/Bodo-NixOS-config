#!/usr/bin/env zsh
source /etc/nixos/dotfiles/scripts/gamma-common.zsh

case $1 in
  up)    running && busctl --user -- call $D $P $I UpdateTemperature n  500 ;;
  down)  running && busctl --user -- call $D $P $I UpdateTemperature n -500 ;;
  day)   running && busctl --user -- set-property $D $P $I Temperature q 6500 ;;
  night) running && busctl --user -- set-property $D $P $I Temperature q 4000 ;;
  toggle)
    if running; then
      t=$(prop Temperature)
      if (( t > 5000 )); then
        busctl --user -- set-property $D $P $I Temperature q 4000
      else
        busctl --user -- set-property $D $P $I Temperature q 6500
      fi
    fi ;;
esac
[[ -n $1 ]] && pkill -RTMIN+12 waybar

if running; then
  t=$(prop Temperature)
  [[ -n $t ]] && printf '󰖙  %d%%\n' $(( t * 100 / 6500 )) || print -r -- '󰖙  NA'
else
  print -r -- '󰖙  NA'
fi
