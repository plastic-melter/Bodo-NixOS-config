#!/bin/sh
#GPUstatus=$(cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status)
LAST=$(cat /tmp/turbostat.log | tail -n 1)
CPUPOWER=$(echo "$LAST" | cut -d $'\t' -f 1 | xargs printf "%.1f\n")  # PkgWatt
IGPUPOWER=$(echo "$LAST" | cut -d $'\t' -f 3 | xargs printf "%.1f\n") # GFXWatt

#if [[ "$GPUstatus" == "active" ]]; then
#  echo "CPU ${CPUPOWER}W  iGPU ${IGPUPOWER}W  dGPU ON"
#else
  echo "CPU ${CPUPOWER}W   iGPU ${IGPUPOWER}W"
#fi
