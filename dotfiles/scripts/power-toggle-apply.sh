#!/usr/bin/env bash
# Runs as root via doas. Cycles Battery -> Balanced -> Performance. Prints the mode it landed in.
set -eu
CPU=/sys/devices/system/cpu

set_all() { for f in $CPU/cpu*/cpufreq/$1; do echo "$2" > "$f"; done; }

gov=$(cat $CPU/cpu0/cpufreq/scaling_governor)
epp=$(cat $CPU/cpu0/cpufreq/energy_performance_preference)

if [ "$gov" = performance ]; then
  # Performance -> Battery. Governor first: dropping to powersave unlocks the EPP files.
  set_all scaling_governor powersave
  set_all energy_performance_preference balance_power
  echo 1 > $CPU/intel_pstate/no_turbo
  echo Battery
elif [ "$epp" = balance_power ]; then
  # Battery -> Balanced
  set_all energy_performance_preference balance_performance
  echo 0 > $CPU/intel_pstate/no_turbo
  echo Balanced
else
  # Balanced -> Performance. EPP is forced to `performance` and read-only here; writing it gives EBUSY.
  set_all scaling_governor performance
  echo 0 > $CPU/intel_pstate/no_turbo
  echo Performance
fi
