#!/usr/bin/env zsh
W=$(cat /sys/class/power_supply/BAT0/power_now)
#W=$(echo $W1)
S=$(cat /sys/class/power_supply/BAT0/status)

if test $W -lt 999999 # if power is <1W, consider it idle
then
  echo -n " Idle"
else
  printf -v W1 "%.1f" "${W::-6}.${W: -6:3}"
  case $S in
  Idle)
    echo " Idle"
    ;;
  Unknown)
    echo " UNK"
    ;;
  Charging)
    echo -n " +${W1}W"
    ;;
  Discharging)
    echo -n " -${W1}W"
    ;;
  'Not charging')
    echo -n " Idle"
    ;;
  *)
    echo " ERR"
    ;;
  esac
fi
