#!/usr/bin/env zsh
CPUTEMP=$(sensors | grep CPU | cut -d '+' -f 2)
#POWER=$(sensors | grep PPT | awk '{print $2}')
FANSPEED=$(sensors | grep fan1 | awk '{print $2}')
echo -n "$CPUTEMP(${FANSPEED}rpm)"
