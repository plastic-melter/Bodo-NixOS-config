#!/bin/sh
laptop_display="eDP-1"

# Resolutions (with refresh rates where applicable)
res_4k_120="3072x1920@120"
res_4k_60="3072x1920@60"
res_1920="1920x1200"
res_touhou="1680x1050"
res_mid="1280x800"
res_vga="640x480"

current=$(hyprctl monitors | grep -A 2 "$laptop_display" | grep -oP '\d+x\d+' | head -1)
current_hz=$(hyprctl monitors | grep -A 2 "$laptop_display" | grep -oP '\d+\.\d+Hz' | head -1)

set_resolution() {
    hyprctl keyword monitor "$laptop_display,$1,0x0,1"
    notify-send "Screen Resolution" "Resolution set to $1"
}

case "$current" in
    "3072x1920")
        case "$current_hz" in
            "120"*) set_resolution "$res_4k_60" ;;
            *)      set_resolution "$res_1920" ;;
        esac
        ;;
    "1920x1200") set_resolution "$res_touhou" ;;
    "1680x1050") set_resolution "$res_mid" ;;
    "1280x800")  set_resolution "$res_vga" ;;
    "640x480")   set_resolution "$res_4k_120" ;;
    *)           set_resolution "$res_4k_120" ;;
esac
