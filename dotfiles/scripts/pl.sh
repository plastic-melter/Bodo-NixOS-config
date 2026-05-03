#!/usr/bin/env zsh
setopt NULL_GLOB

pl_name() {
  case "$1" in
    long_term)  echo "PL1 (long_term)"  ;;
    short_term) echo "PL2 (short_term)" ;;
    peak_power) echo "PL4 (peak_power)" ;;
    *)          echo "$1"               ;;
  esac
}

# Read a file into a variable using zsh builtin (no `cat`)
read_file() {
  local f=$1
  [[ -r "$f" ]] || return 1
  print -r -- "$(<$f)"
}

scale_micro() {
  local u=$1
  [[ -z "$u" ]] && echo "N/A" && return
  awk "BEGIN {printf \"%.1f\", $u/1000000}"
}

print_domain() {
  local path=$1
  local indent=$2
  local name="${$(read_file "$path/name"):-unknown}"
  local base="${path:t}"   # zsh modifier: tail of path, replaces basename
  # strip trailing slash if present
  base="${base%/}"
  echo "${indent}Domain: $name  ($base)"
  for i in 0 1 2; do
    local cname_f="$path/constraint_${i}_name"
    [[ -f "$cname_f" ]] || continue
    local cname=$(read_file "$cname_f")
    local label=$(pl_name "$cname")
    local limit_uw=$(read_file "$path/constraint_${i}_power_limit_uw")
    local max_uw=$(read_file "$path/constraint_${i}_max_power_uw")
    local tw_us=$(read_file "$path/constraint_${i}_time_window_us")
    local limit_w=$(scale_micro "$limit_uw")
    local tw_s=$(scale_micro "$tw_us")
    if [[ -n "$max_uw" ]]; then
      local max_w=$(scale_micro "$max_uw")
      echo "${indent}  [$i] $label: ${limit_w}W (max ${max_w}W, window ${tw_s}s)"
    else
      echo "${indent}  [$i] $label: ${limit_w}W (window ${tw_s}s)"
    fi
  done
}

for parent in /sys/devices/virtual/powercap/intel-rapl /sys/devices/virtual/powercap/intel-rapl-mmio; do
  [[ -d "$parent" ]] || continue
  for domain in "$parent"/intel-rapl*:*/; do
    [[ -d "$domain" ]] || continue
    # trim trailing slash for ${path:t}
    domain="${domain%/}"
    print_domain "$domain" ""
    for subdomain in "$domain"/intel-rapl*:*/; do
      [[ -d "$subdomain" ]] || continue
      subdomain="${subdomain%/}"
      print_domain "$subdomain" "  "
    done
    echo
  done
done
