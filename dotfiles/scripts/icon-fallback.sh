#!/usr/bin/env zsh

FALLBACK_ICON="/path/to/your/fallback/icon.png"

# Function to get icon of an application
get_icon() {
    local app_name="$1"
    local icon_path

    # Command to fetch application icon (adapt to your needs)
    icon_path=$(xdg-icon-resource --query "$app_name")

    if [ -z "$icon_path" ]; then
        echo "$FALLBACK_ICON"
    else
        echo "$icon_path"
    fi
}

# Example usage
get_icon "$1"

