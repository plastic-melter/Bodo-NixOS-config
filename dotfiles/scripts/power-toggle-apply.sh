#!/usr/bin/env bash
# Runs as root via doas. Prints the mode it landed in.
set -eu
CPU=/sys/devices/system/cpu

if [ "$(cat $CPU/cpu0/cpufreq/scaling_governor)" = performance ]; then
  # -> Battery. Governor first: dropping to powersave unlocks the EPP files.
  for f in $CPU/cpu*/cpufreq/scaling_governor; do echo powersave > "$f"; done
  for f in $CPU/cpu*/cpufreq/energy_performance_preference; do echo balance_power > "$f"; done
  echo 1 > $CPU/intel_pstate/no_turbo
  echo Battery
else
  # -> Performance. EPP is forced to `performance` and read-only here; writing it gives EBUSY.
  for f in $CPU/cpu*/cpufreq/scaling_governor; do echo performance > "$f"; done
  echo 0 > $CPU/intel_pstate/no_turbo
  echo Performance
fi
