#!/usr/bin/env zsh
ADDR="0000:04:00.0"

# If device isn't enumerated at all, OR link speed is Unknown = no eGPU
SPEED=$(cat /sys/bus/pci/devices/$ADDR/current_link_speed 2>/dev/null)
if [ -z "$SPEED" ] || [ "$SPEED" = "Unknown" ]; then
  echo '{"text": "󱃓  eGPU", "class": "absent"}'
  exit
fi

DRIVER=$(basename "$(readlink -f /sys/bus/pci/devices/$ADDR/driver 2>/dev/null)")

if [ "$DRIVER" = "vfio-pci" ]; then
  echo '{"text": "󰯮 VM", "class": "vm"}'
  exit
fi

CARD=$(ls /sys/bus/pci/devices/$ADDR/drm/ 2>/dev/null | grep "^card" | head -1)
BUSY=$(cat /sys/bus/pci/devices/$ADDR/drm/$CARD/device/gpu_busy_percent 2>/dev/null || echo "?")
TEMP=$(cat /sys/bus/pci/devices/$ADDR/hwmon/hwmon*/temp1_input 2>/dev/null | head -1)
TEMP=$(( ${TEMP:-0} / 1000 ))

echo "{\"text\": \"󰹑  ${BUSY}% ${TEMP}°C\", \"class\": \"host\"}"
