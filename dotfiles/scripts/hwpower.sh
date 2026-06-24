#!/usr/bin/env zsh
LAST=$(cat /tmp/turbostat.log | tail -n 1)
CPUPOWER=$(grep '^-' /tmp/turbostat.log | tail -1 | awk '{printf "%.1f\n", $32}')  # PkgWatt
#IGPUPOWER=$(echo "$LAST" | cut -d $'\t' -f 3 | xargs printf "%.1f\n") # GFXWatt

  echo "${CPUPOWER}W"
