#!/usr/bin/env bash
CPU=/sys/devices/system/cpu

mode=$(doas @apply@ "$@") || {
  notify-send -u critical "CPU toggle failed" "doas rejected or script errored"
  exit 1
}

case "$mode" in
  Battery)     w_gov=powersave   w_epp='balance_power|power' w_turbo=off ;;
  Balanced)    w_gov=powersave   w_epp=balance_performance   w_turbo=on  ;;
  Performance) w_gov=performance w_epp='performance|default' w_turbo=on  ;;
esac

g_gov=$(cat $CPU/cpu0/cpufreq/scaling_governor)
g_epp=$(cat $CPU/cpu0/cpufreq/energy_performance_preference)
if [ "$(cat $CPU/intel_pstate/no_turbo)" = 0 ]; then g_turbo=on; else g_turbo=off; fi

ok=1; body=""
row() {
  case "|$2|" in
    *"|$3|"*) body+="$1  $3 ✓"$'\n' ;;
    *)        ok=0; body+="$1  $3 ✗ (wanted ${2//|/ or })"$'\n' ;;
  esac
}
row 'gov  ' "$w_gov"   "$g_gov"
row 'epp  ' "$w_epp"   "$g_epp"
row 'turbo' "$w_turbo" "$g_turbo"

[ "$ok" = 1 ] && notify-send "CPU: $mode" "$body" \
              || notify-send -u critical "CPU: $mode — partial" "$body"

pkill -RTMIN+13 waybar
