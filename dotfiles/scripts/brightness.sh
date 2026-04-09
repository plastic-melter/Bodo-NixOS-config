#!/usr/bin/env bash
print_status() {
  brightness=$(cat /sys/class/backlight/intel_backlight/actual_brightness)
  max=$(cat /sys/class/backlight/intel_backlight/max_brightness)
  pct=$(( brightness * 100 / max ))
  rate=$(hyprctl monitors | awk '/eDP-1/{found=1} found && /@[0-9]/{match($0, /@([0-9]+)/, a); print a[1]"Hz"; exit}')
  echo "${pct}% ${rate}"
}

print_status
inotifywait -m -e close_write /sys/class/backlight/intel_backlight/actual_brightness 2>/dev/null | while read -r; do
  print_status
done
