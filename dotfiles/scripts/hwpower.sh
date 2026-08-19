#!/usr/bin/env zsh
W=/run/pkg_watts
[[ -r $W ]] || { print -u2 "hwpower: rapl-watts not running"; exit 1 }
CPU=/sys/devices/system/cpu

gov=$(cat $CPU/cpu*/cpufreq/scaling_governor | sort -u)
epp=$(cat $CPU/cpu*/cpufreq/energy_performance_preference | sort -u)
nt=$(<$CPU/intel_pstate/no_turbo)

case "$gov:$epp:$nt" in
  powersave:balance_power:1|powersave:power:1)      glyph="󰌪 " ;;  # Battery
  powersave:balance_performance:0)                  glyph="󰗑 " ;;  # Balanced
  performance:performance:0|performance:default:0)  glyph=" " ;;  # Performance
  *)                                                glyph="󰀦 " ;;  # mismatch
esac

printf "%s %.1fW\n" "$glyph" "$(<$W)"
