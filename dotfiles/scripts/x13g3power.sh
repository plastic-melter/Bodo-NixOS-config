#!/usr/bin/env zsh

    cpu_w=$(doas bash -c 'E1=$(cat /sys/class/powercap/intel-rapl:0/energy_uj); sleep 1; E2=$(cat /sys/class/powercap/intel-rapl:0/energy_uj); echo "scale=2; ($E2 - $E1) / 1000000" | bc')
    echo "${cpu_w}W"

