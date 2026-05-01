#!/usr/bin/env zsh

# The laptop's display is always eDP-1
laptop_display="eDP-1"

# Define target resolutions
laptop_resolution_high="2560x1600"
laptop_resolution_low="1680x1050"

# Get the current resolution of the laptop display
current_resolution=$(hyprctl monitors | grep -A 1 "$laptop_display" | tail -n 1 | cut -d '@' -f 1 | xargs)

# Function to set resolution
set_resolution() {
    if [[ "$1" == "high" ]]; then
        echo "detected low res"
        # Set high resolution for the laptop display
        hyprctl keyword monitor "$laptop_display,$laptop_resolution_default,0x0,1"
    else
        echo "detected high res"
        # Set lower resolution for the laptop display
        hyprctl keyword monitor "$laptop_display,$laptop_resolution_low,0x0,1"
    fi
}

# Toggle based on current laptop resolution
if [[ "$current_resolution" == "$laptop_resolution_high" ]]; then
    # Set to lower resolution
    set_resolution "low"
else
    # Set to higher resolution
    set_resolution "high"
fi
