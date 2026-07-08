#!/usr/bin/env zsh
D=rs.wl-gammarelay; P=/; I=rs.wl.gammarelay
case $1 in
  up)   busctl --user -- call $D $P $I UpdateBrightness d  0.05 ;;
  down) busctl --user -- call $D $P $I UpdateBrightness d -0.05 ;;
  reset)busctl --user -- set-property $D $P $I Brightness d 1.0 ;;
esac
b=$(busctl --user get-property $D $P $I Brightness | awk '{print $2}')
printf '󰃟  %.0f%%\n' $(( b * 100 ))
pkill -RTMIN+11 waybar
