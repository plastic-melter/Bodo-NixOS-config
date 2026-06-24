#!/usr/bin/env zsh
STATE_FILE="/tmp/cooling_expanded"

if [[ "$1" == "toggle" ]]; then
  [[ -f "$STATE_FILE" ]] && rm "$STATE_FILE" || touch "$STATE_FILE"
  exit 0
fi

CPUTEMP=$(sensors | grep 'id 0' | awk '{print $4}' | cut -d '+' -f 2 | cut -d '.' -f 1)

if [[ -f "$STATE_FILE" ]]; then
    echo -n "${CPUTEMP} (L${FAN_LEVEL}) ${FAN_AVG}rpm"
else
    echo -n "${CPUTEMP}°C"
fi
