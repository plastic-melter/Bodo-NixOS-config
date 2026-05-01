#!/usr/bin/env zsh
# Power draw tracker: Battery, CPU breakdown, GPU, platform remainder

while true; do
    # Battery total (µW -> W)
    bat=$(cat /sys/class/power_supply/BAT0/power_now 2>/dev/null)
    bat_w=$(echo "scale=2; $bat / 1000000" | bc)

    # CPU via turbostat - skip header, take first data line
    read pkg cor gfx ram << EOF
$(sudo turbostat --quiet --show PkgWatt,CorWatt,GFXWatt,RAMWatt --interval 1 2>/dev/null | awk 'NR==2{print $1, $2, $3, $4}')
EOF

    # Nvidia GPU power (watts)
    gpu_w=$(nvidia-smi --query-gpu=power.draw --format=csv,noheader,nounits 2>/dev/null | xargs)

    # Platform remainder (everything else: display, wifi, nvme, etc.)
    remainder=$(echo "scale=2; $bat_w - ${pkg:-0} - ${gpu_w:-0}" | bc)

    clear
    printf "%-26s %6s W\n" "Battery (total):"               "$bat_w"
    echo "----------------------------"
    printf "%-26s %6s W\n" "CPU package:"                   "${pkg:-n/a}"
    printf "%-26s %6s W\n" "  └ cores:"                     "${cor:-n/a}"
    printf "%-26s %6s W\n" "  └ iGPU (Arc):"                "${gfx:-n/a}"
    printf "%-26s %6s W\n" "Nvidia dGPU:"                   "${gpu_w:-n/a}"
    printf "%-26s %6s W\n" "Platform (display+wifi+nvme):"  "$remainder"
    echo "----------------------------"
    date

    sleep 3
done
