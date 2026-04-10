#!/bin/sh
GPUstatus=$(cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status)
CPUPOWER=$(cat /tmp/turbostat.log | tail -n 1 | cut -d $'\t' -f 1 | xargs printf "%.1f\n")
if [[ "$GPUstatus" == "active" ]]; then
  GPUPOWER=$(nvidia-smi --query-gpu=power.draw | tail -n 1 | cut -b -4 | cut -d ' ' -f 1 | xargs printf "%.1f\n")
  echo "${CPUPOWER}W + ${GPUPOWER}W"
else
  echo "${CPUPOWER}W"
fi

