#!/usr/bin/env bash
# Runs as your user. Calls the apply script, then reports intended vs actual.
CPU=/sys/devices/system/cpu

mode=$(doas @apply@) || {
  notify-send -u critical "CPU toggle failed" "doas rejected or script errored"
  exit 1
}

if [ "$mode" = Battery ]; then
  w_gov=powersave   w_epp=balance_power        w_turbo=off
else
  # governor=performance pins HWP EPP to 0 and the sysfs file reads back as `default`
  w_gov=performance w_epp='performance|default' w_turbo=on
fi

g_gov=$(cat $CPU/cpu0/cpufreq/scaling_governor)
g_epp=$(cat $CPU/cpu0/cpufreq/energy_performance_preference)
if [ "$(cat $CPU/intel_pstate/no_turbo)" = 0 ]; then g_turbo=on; else g_turbo=off; fi

ok=1
body=""
row() { # label  want(alternatives separated by |)  got
  case "|$2|" in
    *"|$3|"*) body+="$1  $3 ✓"$'\n' ;;
    *)        ok=0; body+="$1  $3 ✗ (wanted ${2//|/ or })"$'\n' ;;
  esac
}
row 'gov  ' "$w_gov"   "$g_gov"
row 'epp  ' "$w_epp"   "$g_epp"
row 'turbo' "$w_turbo" "$g_turbo"

if [ "$ok" = 1 ]; then
  notify-send "CPU: $mode" "$body"
else
  notify-send -u critical "CPU: $mode — partial" "$body"
fi
