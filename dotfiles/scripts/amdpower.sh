#!/usr/bin/env zsh

declare -a power_samples=()
sample_rate=5           # 5 samples per second
window_size=$((sample_rate * 3))  # 3 seconds worth of samples (15 samples)

while true; do

    # AMD package power, format 0.00-99.99 (example: 5.20)
    POWER=$(sensors | grep PPT | awk '{print $2}')
    
    # Add the current POWER value to the array
    power_samples+=("$POWER")

    # Trim the array to the last 15 samples
    if [ "${#power_samples[@]}" -gt "$window_size" ]; then
        power_samples=("${power_samples[@]:1}")
    fi

    # Compute and output the average once per second
    if (( ${#power_samples[@]} == window_size )); then
        sum=0
        for value in "${power_samples[@]}"; do
            sum=$(echo "$sum + $value" | bc)
        done
        avg=$(echo "scale=2; $sum / $window_size" | bc)
        echo "Running Average: $avg W"
    fi

    # Sleep for 0.2 seconds (5 times per second sampling rate)
    sleep 0.2
done
