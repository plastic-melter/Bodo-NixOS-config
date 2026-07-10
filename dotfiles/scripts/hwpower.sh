#!/usr/bin/env zsh
W=/run/pkg_watts
[[ -r $W ]] || { print -u2 "hwpower: rapl-watts not running"; exit 1 }
if [[ "$(</sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)" == performance ]]; then
  glyph=" "
else
  glyph="󰌪 "
fi
printf "%s %.1fW\n" "$glyph" "$(<$W)"
