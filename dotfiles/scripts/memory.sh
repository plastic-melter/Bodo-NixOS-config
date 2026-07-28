#!/usr/bin/env zsh
# ~/.config/waybar/memory.sh
pct=$(free | awk '/Mem:/{printf "%.0f",$3/$2*100}')
read used total < <(free -g | awk '/Mem:/{print $3,$2}')

ram='?'
for h in /sys/class/hwmon/hwmon*; do
  [[ "$(<$h/name)" == spd5118 ]] && ram=$(( $(<$h/temp1_input)/1000 )) && break
done

printf '{"text":"  %s%%  %s°","tooltip":"%sG / %sG\\nDIMM %s°"}\n' \
  "$pct" "$ram" "$used" "$total" "$ram"
