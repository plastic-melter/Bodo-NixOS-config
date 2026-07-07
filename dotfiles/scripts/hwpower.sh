#!/usr/bin/env zsh
# newest matching log by mtime; N=nullglob, .=regular file, om=mtime order
LOG=(/var/log/turbostat/turbostat*212c.log(N.om[1]))
(( $#LOG )) || { print -u2 "hwpower: no turbostat log"; exit 1 }
pkg=$(tail -n 600 $LOG | awk -F'\t' '
  $1=="Time_Of_Day_Seconds" { for(i=1;i<=NF;i++) if($i=="PkgWatt") c=i; next }
  $2=="-" && c        { v=$c }   # summary row carries package totals
  END                 { print v }
')

# glyph reflects power state (governor as proxy)
if [[ "$(</sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)" == performance ]]; then
  glyph=" "   # AC / performance
else
  glyph="󰌪 "   # battery save
fi

printf "%s %.1fW\n" "$glyph" "${pkg:-0}"
