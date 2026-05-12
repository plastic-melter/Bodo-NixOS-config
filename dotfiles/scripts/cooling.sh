#!/usr/bin/env zsh
STATE_FILE="/tmp/cooling_expanded"

if [[ "$1" == "toggle" ]]; then
  [[ -f "$STATE_FILE" ]] && rm "$STATE_FILE" || touch "$STATE_FILE"
  exit 0
fi

GPUTEMP=$(sensors | grep GPU | grep -oP '\+\K[0-9]+' | head -1)
CPUTEMP=$(sensors | grep CPU | grep -oP '\+\K[0-9]+' | head -1)
FAN_LEVEL=$(awk '/^level:/ {print $2}' /proc/acpi/ibm/fan)
FAN1=$(cat /sys/class/hwmon/hwmon8/fan1_input)
FAN2=$(cat /sys/class/hwmon/hwmon8/fan2_input)
FAN_AVG=$(( (FAN1 + FAN2) / 2 ))

if [[ -f "$STATE_FILE" ]]; then
  if [ -z "$GPUTEMP" ]; then
    echo -n "${CPUTEMP}°C (L${FAN_LEVEL}) ${FAN_AVG}rpm"
  else
    echo -n "${CPUTEMP}${GPUTEMP}°C (L${FAN_LEVEL}) ${FAN_AVG}rpm"
  fi
else
  if [ -z "$GPUTEMP" ]; then
    echo -n "${CPUTEMP}°C"
  else
    echo -n "${CPUTEMP}${GPUTEMP}°C"
  fi
fi
