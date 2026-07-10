#!/usr/bin/env zsh
D=rs.wl-gammarelay; P=/; I=rs.wl.gammarelay
running() { pgrep -f wl-gammarelay-rs >/dev/null; }

case $1 in
  up)    running && busctl --user -- call $D $P $I UpdateBrightness d  0.05 ;;
  down)  running && busctl --user -- call $D $P $I UpdateBrightness d -0.05 ;;
  reset) running && busctl --user -- set-property $D $P $I Brightness d 1.0 ;;
  toggle)
    if running; then
      pkill -f wl-gammarelay-rs
    else
      setsid -f wl-gammarelay-rs >/dev/null 2>&1
    fi ;;
esac

if running; then
  b=$(busctl --user get-property $D $P $I Brightness 2>/dev/null | awk '{print $2}')
  [[ -n $b ]] && printf '󰃟  %.0f%%\n' $(( b * 100 )) || print -r -- '󰃟  NA'
else
  print -r -- '󰃟  NA'
fi
