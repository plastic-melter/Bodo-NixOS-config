#!/usr/bin/env zsh

# For X210Ai
# Toggles three three main performance governers (scaling, EPP, turbo)
# between battery optimized and performance optimized.

gov=/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

if [[ "$(<$gov)" == performance ]]; then
  g=powersave epp=balance_power turbo=1 mode="Battery"   # no_turbo=1 → turbo OFF
else
  g=performance epp=performance turbo=0 mode="AC / Performance"
fi

echo $g    | doas tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor            >/dev/null
echo $epp  | doas tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference >/dev/null
echo $turbo| doas tee /sys/devices/system/cpu/intel_pstate/no_turbo                     >/dev/null

notify-send "CPU: $mode"  "gov=$g \nepp=$epp \nturbo=$([[ $turbo == 0 ]] && echo on || echo off)"
