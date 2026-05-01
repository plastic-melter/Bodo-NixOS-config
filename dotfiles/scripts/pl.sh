#!/usr/bin/env zsh
setopt NULL_GLOB # zsh will error out if the "$domain"intel-rapl:*/ glob matches nothing
RAPL=/sys/devices/virtual/powercap/intel-rapl

# Map constraint names to PL terminology
pl_name() {
  case "$1" in
    long_term)  echo "PL1 (long_term)"  ;;
    short_term) echo "PL2 (short_term)" ;;
    peak_power) echo "PL4 (peak_power)" ;;
    *)          echo "$1"               ;;
  esac
}

uw_to_w() {
  local uw=$1
  [[ -z "$uw" ]] && echo "N/A" && return
  awk "BEGIN {printf \"%.1f\", $uw/1000000}"
}

print_domain() {
  local path=$1
  local indent=$2
  local name=$(cat "$path/name" 2>/dev/null || echo "unknown")
  echo "${indent}Domain: $name"
  for i in 0 1 2; do
    local cname_f="$path/constraint_${i}_name"
    [[ -f "$cname_f" ]] || continue
    local cname=$(cat "$cname_f")
    local label=$(pl_name "$cname")
    local limit_uw=$(cat "$path/constraint_${i}_power_limit_uw" 2>/dev/null)
    local max_uw=$(cat "$path/constraint_${i}_max_power_uw" 2>/dev/null)
    local tw_us=$(cat "$path/constraint_${i}_time_window_us" 2>/dev/null)
    local limit_w=$(uw_to_w "$limit_uw")
    local tw_s=$(uw_to_w "$tw_us")
    if [[ -n "$max_uw" ]]; then
      local max_w=$(uw_to_w "$max_uw")
      echo "${indent}  [$i] $label: ${limit_w}W (max ${max_w}W, window ${tw_s}s)"
    else
      echo "${indent}  [$i] $label: ${limit_w}W (window ${tw_s}s)"
    fi
  done
}

for domain in "$RAPL"/intel-rapl:*/; do
  [[ -d "$domain" ]] || continue
  print_domain "$domain" ""
  for subdomain in "$domain"intel-rapl:*/; do
    [[ -d "$subdomain" ]] || continue
    print_domain "$subdomain" "  "
  done
  echo
done
