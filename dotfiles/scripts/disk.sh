#!/usr/bin/env zsh
# ~/.config/waybar/disk.sh
read used total pct < <(df -BG --output=used,size,pcent / | tail -1 | tr -d 'G%')

nvme='?'
lines=()
for h in /sys/class/hwmon/hwmon*(N); do
  [[ -r $h/name && "$(<$h/name)" == nvme ]] || continue
  for f in $h/temp*_input(N); do
    lbl=${f%_input}_label
    if [[ -r $lbl ]]; then name="$(<$lbl)"; else name="${${f:t}%_input}"; fi
    t=$(( $(<$f) / 1000 ))
    lines+=("${name}: ${t}°")
    [[ $name == Composite ]] && nvme=$t
  done
  [[ $nvme == '?' && -r $h/temp1_input ]] && nvme=$(( $(<$h/temp1_input) / 1000 ))
  break
done

tip="${(F)lines}"
tip="${tip//$'\n'/'\n'}"

printf '{"text":"󰋊  %s%%  %s°","tooltip":"%sG / %sG used\\n%s"}\n' \
  "$pct" "$nvme" "$used" "$total" "$tip"
