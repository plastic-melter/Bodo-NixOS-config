#!/usr/bin/env zsh
D=rs.wl-gammarelay; P=/; I=rs.wl.gammarelay
case $1 in
  up)    busctl --user -- call $D $P $I UpdateTemperature n  500 ;;
  down)  busctl --user -- call $D $P $I UpdateTemperature n -500 ;;
  day)   busctl --user -- set-property $D $P $I Temperature q 6500 ;;
  night) busctl --user -- set-property $D $P $I Temperature q 4000 ;;
  toggle)
    t=$(busctl --user get-property $D $P $I Temperature | awk '{print $2}')
    (( t > 5000 )) && $0 night || $0 day ;;
esac
t=$(busctl --user get-property $D $P $I Temperature | awk '{print $2}')
printf '󰖙  %dK\n' $t
pkill -RTMIN+12 waybar
