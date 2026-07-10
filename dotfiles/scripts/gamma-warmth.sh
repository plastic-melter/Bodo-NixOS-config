#!/usr/bin/env zsh
D=rs.wl-gammarelay; P=/; I=rs.wl.gammarelay
running() { pgrep -f wl-gammarelay-rs >/dev/null; }

case $1 in
  up)    running && busctl --user -- call $D $P $I UpdateTemperature n  500 ;;
  down)  running && busctl --user -- call $D $P $I UpdateTemperature n -500 ;;
  day)   running && busctl --user -- set-property $D $P $I Temperature q 6500 ;;
  night) running && busctl --user -- set-property $D $P $I Temperature q 4000 ;;
  toggle)
    if running; then
      t=$(busctl --user get-property $D $P $I Temperature | awk '{print $2}')
      (( t > 5000 )) \
        && busctl --user -- set-property $D $P $I Temperature q 4000 \
        || busctl --user -- set-property $D $P $I Temperature q 6500
    fi ;;
esac

if running; then
  t=$(busctl --user get-property $D $P $I Temperature 2>/dev/null | awk '{print $2}')
  [[ -n $t ]] && printf '󰖙  %d%%\n' $(( t * 100 / 6500 )) || print -r -- '󰖙  NA'
else
  print -r -- '󰖙  NA'
fi
