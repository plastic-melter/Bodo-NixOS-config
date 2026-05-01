#!/usr/bin/env zsh

# Directory containing wallpapers
WALLPAPER_DIR="/etc/nixos/dotfiles/wallpapers"
# File to store the last used wallpaper
LAST_WALLPAPER_FILE="/tmp/last_wallpaper"

# Ensure the wallpaper directory exists
if [[ ! -d "$WALLPAPER_DIR" ]]; then
    echo "Wallpaper directory not found: $WALLPAPER_DIR" >&2
    exit 1
fi

# Get a sorted list of wallpapers
wallpapers=($(ls "$WALLPAPER_DIR" | sort))

# Check if there are any wallpapers
if [[ ${#wallpapers[@]} -eq 0 ]]; then
    echo "No wallpapers found in $WALLPAPER_DIR" >&2
    exit 1
fi

# Function to cycle up in the wallpaper list
cycle_up() {
    # Get the last used wallpaper
    if [[ -f "$LAST_WALLPAPER_FILE" ]]; then
        last_wallpaper=$(cat "$LAST_WALLPAPER_FILE")
    else
        last_wallpaper=""
    fi

    # Determine the next wallpaper
    next_wallpaper=""
    if [[ -n "$last_wallpaper" ]]; then
        for i in "${!wallpapers[@]}"; do
            if [[ "${wallpapers[$i]}" == "$last_wallpaper" ]]; then
                next_index=$(( (i + 1) % ${#wallpapers[@]} ))
                next_wallpaper="${wallpapers[$next_index]}"
                break
            fi
        done
    fi

    # If no previous wallpaper found or invalid, use the first one
    if [[ -z "$next_wallpaper" ]]; then
        next_wallpaper="${wallpapers[0]}"
    fi

    echo "$next_wallpaper"
}

# Function to cycle down in the wallpaper list
cycle_down() {
    # Get the last used wallpaper
    if [[ -f "$LAST_WALLPAPER_FILE" ]]; then
        last_wallpaper=$(cat "$LAST_WALLPAPER_FILE")
    else
        last_wallpaper=""
    fi

    # Determine the previous wallpaper
    prev_wallpaper=""
    if [[ -n "$last_wallpaper" ]]; then
        for i in "${!wallpapers[@]}"; do
            if [[ "${wallpapers[$i]}" == "$last_wallpaper" ]]; then
                prev_index=$(( (i - 1 + ${#wallpapers[@]}) % ${#wallpapers[@]} ))
                prev_wallpaper="${wallpapers[$prev_index]}"
                break
            fi
        done
    fi

    # If no previous wallpaper found or invalid, use the last one
    if [[ -z "$prev_wallpaper" ]]; then
        prev_wallpaper="${wallpapers[-1]}"
    fi

    echo "$prev_wallpaper"
}

# Function to select a random wallpaper
random_wallpaper() {
    echo "${wallpapers[RANDOM % ${#wallpapers[@]}]}"
}

# Determine direction (up, down, or random)
if [[ "$1" == "down" ]]; then
    selected_wallpaper=$(cycle_down)
elif [[ "$1" == "random" ]]; then
    selected_wallpaper=$(random_wallpaper)
else
    selected_wallpaper=$(cycle_up)
fi

# Full path to the selected wallpaper
selected_wallpaper_path="$WALLPAPER_DIR/$selected_wallpaper"

# Save the selected wallpaper to the file
echo "$selected_wallpaper" > "$LAST_WALLPAPER_FILE"

# Run the enkei command
enkei "$selected_wallpaper_path"

# Send a dunst notification
notify-send "Wallpaper Changed" "Using: $selected_wallpaper"

