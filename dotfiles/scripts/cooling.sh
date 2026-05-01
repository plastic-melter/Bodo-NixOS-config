#!/usr/bin/env zsh
GPUTEMP=$(sensors | grep GPU | grep -oP '\+\K[0-9]+' | head -1)
CPUTEMP=$(sensors | grep CPU | grep -oP '\+\K[0-9]+' | head -1)

if [ -z "$GPUTEMP" ]; then
  echo -n "${CPUTEMP}°C"
else
  echo -n "${CPUTEMP}${GPUTEMP}°C"
fi
