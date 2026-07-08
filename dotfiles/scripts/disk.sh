#!/usr/bin/env zsh
# ~/.config/waybar/disk.sh
read used total pct < <(df -BG --output=used,size,pcent / | tail -1 | tr -d 'G%')

nvme='?'
for h in /sys/class/hwmon/hwmon*; do
  [[ "$(<$h/name)" == nvme ]] || continue
  max=0
  for f in $h/temp*_input; do
    (( t = $(<$f)/1000, t > max )) && max=$t
  done
  nvme=$max
  break
done

printf '{"text":"󰋊  %s%%  %s°","tooltip":"%sG / %sG used\\nNVMe %s°"}\n' \
  "$pct" "$nvme" "$used" "$total" "$nvme"
