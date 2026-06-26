#!/usr/bin/env zsh
ADDR="0000:04:00.0"
DRIVER_PATH="/sys/bus/pci/devices/$ADDR/driver"

if ! lspci -s "$ADDR" &>/dev/null; then
  echo '{"text": "no eGPU", "class": "absent"}'
  exit
fi

if [ ! -L "$DRIVER_PATH" ]; then
  echo '{"text": "󰢮 unbound", "class": "unbound"}'
  exit
fi

DRIVER=$(basename "$(readlink -f "$DRIVER_PATH")")

case "$DRIVER" in
  amdgpu)
    # Find the right card
    CARD=$(ls /sys/bus/pci/devices/$ADDR/drm/ 2>/dev/null | grep "^card" | head -1)
    BUSY=$(cat /sys/bus/pci/devices/$ADDR/drm/$CARD/device/gpu_busy_percent 2>/dev/null || echo "?")
    TEMP=$(cat /sys/bus/pci/devices/$ADDR/hwmon/hwmon*/temp1_input 2>/dev/null)
    TEMP=$((TEMP / 1000))
    echo "{\"text\": \"󰹑  ${BUSY}% ${TEMP}°C\", \"class\": \"host\"}"
    ;;
  vfio-pci)
    echo '{"text": "󰯮 VM", "class": "vm"}'
    ;;
  *)
    echo "{\"text\": \"? $DRIVER\", \"class\": \"unknown\"}"
    ;;
esac
