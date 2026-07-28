#!/usr/bin/env zsh
source /etc/nixos/dotfiles/scripts/gamma-common.zsh

case $1 in
  up)    running && busctl --user -- call $D $P $I UpdateBrightness d  0.05 ;;
  down)  running && busctl --user -- call $D $P $I UpdateBrightness d -0.05 ;;
  reset) running && busctl --user -- set-property $D $P $I Brightness d 1.0 ;;
esac
[[ -n $1 ]] && pkill -RTMIN+11 waybar

if running; then
  b=$(prop Brightness)
  [[ -n $b ]] && printf '󰃟  %.0f%%\n' $(( b * 100 )) || print -r -- '󰃟  NA'
else
  print -r -- '󰃟  NA'
fi
