#!/usr/bin/env bash
# theme.sh — run pywal on a wallpaper, write palette.nix, rebuild.
#
# Home-manager reads palette.nix at eval time and interpolates the values
# into dotfile templates via builtins.replaceStrings. This script's only
# job is to derive the palette and emit the nix file.
#
# usage:
#   theme.sh                  use current awww wallpaper
#   theme.sh -i path/img.png  use arbitrary image
#   theme.sh -y               auto-accept (skip prompt)
#   theme.sh --preview        show palette only, do not write
#   theme.sh --dry-run        write palette.nix but skip yeet
#   theme.sh -h | --help

set -euo pipefail

DOTFILES="/etc/nixos/dotfiles"
PALETTE_NIX="$DOTFILES/palette.nix"
WAL_CACHE="$HOME/.cache/wal/colors.sh"
WAL_BIN="/etc/profiles/per-user/joe/bin/wal"
YEET="$DOTFILES/scripts/yeet.sh"

# Per-module identity colors (static pastels) and the theme target they
# blend toward. MIX_RATIO is percent of theme bleed (0=keep identity,
# 100=full theme).
MIX_RATIO=35

# Identity colors keyed by module short-name.
IDENT_CLOCK="ba97ff"
IDENT_WORLDCLOCK="a8e8b8"
IDENT_COOLING="a8c8e8"
IDENT_NVIDIA="a8d8b8"
IDENT_BATTERY="a8d8b8"
IDENT_BATTERY_WARN="e8d8a0"
IDENT_BATTERY_CRIT="e8a0a8"
IDENT_BATTERY_CHARGE="a8c8e8"
IDENT_NETWORK="a8c8e8"
IDENT_NETWORK_DISC="e8a0a8"
IDENT_PULSEAUDIO="e8b8d8"
IDENT_CPU="e8c8a8"
IDENT_MEMORY="c8a8e8"
IDENT_TEMP="e8b8d8"
IDENT_TEMP_CRIT="e8a0a8"
IDENT_BACKLIGHT="e8e8a8"
IDENT_REFRESHRATE="e8a565"
IDENT_POWER="e8a565"
IDENT_DISK="a8c8e8"
IDENT_PLAYERCTL="e8b8d8"
IDENT_LAUNCHER="7ad4f0"
IDENT_RECORDER="e8a0a8"

DRY=0
YES=0
PREVIEW=0
IMAGE=""

usage() { sed -n '2,15p' "$0" | sed 's/^# \?//'; exit 0; }
strip() { echo "${1#\#}"; }

hex_rgb_csv() {
    local h; h=$(strip "$1")
    printf "%d, %d, %d" "0x${h:0:2}" "0x${h:2:2}" "0x${h:4:2}"
}
hex_rgb_compact() {
    local h; h=$(strip "$1")
    printf "%d,%d,%d" "0x${h:0:2}" "0x${h:2:2}" "0x${h:4:2}"
}
darken() {
    local h; h=$(strip "$1"); local amt="${2:-30}"
    local r g b
    r=$(( 16#${h:0:2} - amt )); (( r < 0 )) && r=0
    g=$(( 16#${h:2:2} - amt )); (( g < 0 )) && g=0
    b=$(( 16#${h:4:2} - amt )); (( b < 0 )) && b=0
    printf "%02x%02x%02x" $r $g $b
}
# mix hex1 hex2 ratio_percent → hex
# ratio = how much of hex2 to mix in (0=all hex1, 100=all hex2)
mix() {
    local h1=$(strip "$1") h2=$(strip "$2") ratio="$3"
    local r1=$(( 16#${h1:0:2} )) g1=$(( 16#${h1:2:2} )) b1=$(( 16#${h1:4:2} ))
    local r2=$(( 16#${h2:0:2} )) g2=$(( 16#${h2:2:2} )) b2=$(( 16#${h2:4:2} ))
    local r=$(( (r1 * (100 - ratio) + r2 * ratio) / 100 ))
    local g=$(( (g1 * (100 - ratio) + g2 * ratio) / 100 ))
    local b=$(( (b1 * (100 - ratio) + b2 * ratio) / 100 ))
    printf "%02x%02x%02x" "$r" "$g" "$b"
}
swatch() {
    local label="$1" hex="$2"
    local h; h=$(strip "$hex")
    local r=$(( 16#${h:0:2} )) g=$(( 16#${h:2:2} )) b=$(( 16#${h:4:2} ))
    printf "  \e[48;2;%d;%d;%dm        \e[0m  #%s  %s\n" "$r" "$g" "$b" "$h" "$label"
}

get_wallpaper() {
    local wp
    wp=$(awww query 2>/dev/null \
        | grep -m1 'currently displaying: image:' \
        | sed -E 's/.*currently displaying: image:[[:space:]]*//')
    if [[ -z "$wp" || ! -f "$wp" ]]; then
        echo "error: could not determine wallpaper from 'awww query'" >&2
        exit 1
    fi
    echo "$wp"
}
run_wal() {
    echo "→ pywal on: $(basename "$1")"
    "$WAL_BIN" -i "$1" -n -q
    [[ -f "$WAL_CACHE" ]] || { echo "error: wal produced no $WAL_CACHE" >&2; exit 1; }
}

load_palette() {
    set +u
    # shellcheck source=/dev/null
    source "$WAL_CACHE"
    BG=$(strip "$background")
    BG_ALT=$(strip "$color0")
    SURFACE=$(strip "$color8")
    BORDER=$(strip "$color5")
    BORDER_ACTIVE=$(strip "$color1")
    BORDER_ACTIVE2=$(strip "$color4")
    BORDER_INACTIVE=$(darken "$color0" 20)
    ACCENT=$(strip "$color1")
    TEXT=$(strip "$foreground")
    TEXT_DIM=$(strip "$color7")
    BG_RGB=$(hex_rgb_csv "$BG")
    BG_ALT_RGB=$(hex_rgb_csv "$BG_ALT")
    ACCENT_RGB=$(hex_rgb_csv "$ACCENT")
    LOCK_BG=$(hex_rgb_compact "$background")
    LOCK_FG=$(hex_rgb_compact "$foreground")
    LOCK_C1=$(hex_rgb_compact "$color4")
    LOCK_C2=$(hex_rgb_compact "$color1")

    # Per-module accents: blend each identity color toward BORDER_ACTIVE2
    local t="$BORDER"
    MOD_CLOCK=$(mix          "$IDENT_CLOCK"          "$t" "$MIX_RATIO")
    MOD_WORLDCLOCK=$(mix     "$IDENT_WORLDCLOCK"     "$t" "$MIX_RATIO")
    MOD_COOLING=$(mix        "$IDENT_COOLING"        "$t" "$MIX_RATIO")
    MOD_NVIDIA=$(mix         "$IDENT_NVIDIA"         "$t" "$MIX_RATIO")
    MOD_BATTERY=$(mix        "$IDENT_BATTERY"        "$t" "$MIX_RATIO")
    MOD_BATTERY_WARN=$(mix   "$IDENT_BATTERY_WARN"   "$t" "$MIX_RATIO")
    MOD_BATTERY_CRIT=$(mix   "$IDENT_BATTERY_CRIT"   "$t" "$MIX_RATIO")
    MOD_BATTERY_CHARGE=$(mix "$IDENT_BATTERY_CHARGE" "$t" "$MIX_RATIO")
    MOD_NETWORK=$(mix        "$IDENT_NETWORK"        "$t" "$MIX_RATIO")
    MOD_NETWORK_DISC=$(mix   "$IDENT_NETWORK_DISC"   "$t" "$MIX_RATIO")
    MOD_PULSEAUDIO=$(mix     "$IDENT_PULSEAUDIO"     "$t" "$MIX_RATIO")
    MOD_CPU=$(mix            "$IDENT_CPU"            "$t" "$MIX_RATIO")
    MOD_MEMORY=$(mix         "$IDENT_MEMORY"         "$t" "$MIX_RATIO")
    MOD_TEMP=$(mix           "$IDENT_TEMP"           "$t" "$MIX_RATIO")
    MOD_TEMP_CRIT=$(mix      "$IDENT_TEMP_CRIT"      "$t" "$MIX_RATIO")
    MOD_BACKLIGHT=$(mix      "$IDENT_BACKLIGHT"      "$t" "$MIX_RATIO")
    MOD_REFRESHRATE=$(mix    "$IDENT_REFRESHRATE"    "$t" "$MIX_RATIO")
    MOD_POWER=$(mix          "$IDENT_POWER"          "$t" "$MIX_RATIO")
    MOD_DISK=$(mix           "$IDENT_DISK"           "$t" "$MIX_RATIO")
    MOD_PLAYERCTL=$(mix      "$IDENT_PLAYERCTL"      "$t" "$MIX_RATIO")
    MOD_LAUNCHER=$(mix       "$IDENT_LAUNCHER"       "$t" "$MIX_RATIO")
    MOD_RECORDER=$(mix       "$IDENT_RECORDER"       "$t" "$MIX_RATIO")
    set -u
}

show_palette() {
    echo ""
    echo "  new palette"
    echo "  ────────────────────────────────────────────────"
    swatch "bg"               "#$BG"
    swatch "bg_alt"           "#$BG_ALT"
    swatch "surface"          "#$SURFACE"
    swatch "border"           "#$BORDER"
    swatch "border_active"    "#$BORDER_ACTIVE"
    swatch "border_active2"   "#$BORDER_ACTIVE2"
    swatch "border_inactive"  "#$BORDER_INACTIVE"
    swatch "accent"           "#$ACCENT"
    swatch "text"             "#$TEXT"
    swatch "text_dim"         "#$TEXT_DIM"
    echo ""
    echo "  rgb triplets: bg=$BG_RGB  bg_alt=$BG_ALT_RGB  accent=$ACCENT_RGB"
    echo "  hyprlock:     bg=$LOCK_BG  fg=$LOCK_FG  c1=$LOCK_C1  c2=$LOCK_C2"
    echo ""
    echo "  per-module accents (mixed ${MIX_RATIO}% toward border_active2)"
    echo "  ────────────────────────────────────────────────"
    swatch "clock"            "#$MOD_CLOCK"
    swatch "worldclock"       "#$MOD_WORLDCLOCK"
    swatch "cooling"          "#$MOD_COOLING"
    swatch "nvidia"           "#$MOD_NVIDIA"
    swatch "battery"          "#$MOD_BATTERY"
    swatch "battery_warn"     "#$MOD_BATTERY_WARN"
    swatch "battery_crit"     "#$MOD_BATTERY_CRIT"
    swatch "battery_charge"   "#$MOD_BATTERY_CHARGE"
    swatch "network"          "#$MOD_NETWORK"
    swatch "network_disc"     "#$MOD_NETWORK_DISC"
    swatch "pulseaudio"       "#$MOD_PULSEAUDIO"
    swatch "cpu"              "#$MOD_CPU"
    swatch "memory"           "#$MOD_MEMORY"
    swatch "temp"             "#$MOD_TEMP"
    swatch "temp_crit"        "#$MOD_TEMP_CRIT"
    swatch "backlight"        "#$MOD_BACKLIGHT"
    swatch "refreshrate"      "#$MOD_REFRESHRATE"
    swatch "power"            "#$MOD_POWER"
    swatch "disk"             "#$MOD_DISK"
    swatch "playerctl"        "#$MOD_PLAYERCTL"
    swatch "launcher"         "#$MOD_LAUNCHER"
    swatch "recorder"         "#$MOD_RECORDER"
    echo ""
}

write_palette_nix() {
    cat > "$PALETTE_NIX" <<EOF
# Generated by theme.sh from $(basename "$IMAGE") on $(date -Iseconds).
# Do not edit by hand — re-run theme.sh to regenerate.
{
  BG = "$BG";
  BG_ALT = "$BG_ALT";
  SURFACE = "$SURFACE";
  BORDER = "$BORDER";
  BORDER_ACTIVE = "$BORDER_ACTIVE";
  BORDER_ACTIVE2 = "$BORDER_ACTIVE2";
  BORDER_INACTIVE = "$BORDER_INACTIVE";
  ACCENT = "$ACCENT";
  TEXT = "$TEXT";
  TEXT_DIM = "$TEXT_DIM";
  BG_RGB = "$BG_RGB";
  BG_ALT_RGB = "$BG_ALT_RGB";
  ACCENT_RGB = "$ACCENT_RGB";
  LOCK_BG = "$LOCK_BG";
  LOCK_FG = "$LOCK_FG";
  LOCK_C1 = "$LOCK_C1";
  LOCK_C2 = "$LOCK_C2";

  MOD_CLOCK = "$MOD_CLOCK";
  MOD_WORLDCLOCK = "$MOD_WORLDCLOCK";
  MOD_COOLING = "$MOD_COOLING";
  MOD_NVIDIA = "$MOD_NVIDIA";
  MOD_BATTERY = "$MOD_BATTERY";
  MOD_BATTERY_WARN = "$MOD_BATTERY_WARN";
  MOD_BATTERY_CRIT = "$MOD_BATTERY_CRIT";
  MOD_BATTERY_CHARGE = "$MOD_BATTERY_CHARGE";
  MOD_NETWORK = "$MOD_NETWORK";
  MOD_NETWORK_DISC = "$MOD_NETWORK_DISC";
  MOD_PULSEAUDIO = "$MOD_PULSEAUDIO";
  MOD_CPU = "$MOD_CPU";
  MOD_MEMORY = "$MOD_MEMORY";
  MOD_TEMP = "$MOD_TEMP";
  MOD_TEMP_CRIT = "$MOD_TEMP_CRIT";
  MOD_BACKLIGHT = "$MOD_BACKLIGHT";
  MOD_REFRESHRATE = "$MOD_REFRESHRATE";
  MOD_POWER = "$MOD_POWER";
  MOD_DISK = "$MOD_DISK";
  MOD_PLAYERCTL = "$MOD_PLAYERCTL";
  MOD_LAUNCHER = "$MOD_LAUNCHER";
  MOD_RECORDER = "$MOD_RECORDER";
}
EOF
    echo "→ wrote $PALETTE_NIX"
}

reload_live() {
    echo ""
    echo "→ reloading live config"
    command -v hyprctl >/dev/null 2>&1 && hyprctl reload >/dev/null && echo "  ✓ hyprctl reload"
    local bartoggle="$DOTFILES/scripts/bartoggle.sh"
    if [[ -x "$bartoggle" ]]; then
        "$bartoggle" >/dev/null 2>&1; sleep 0.2; "$bartoggle" >/dev/null 2>&1
        echo "  ✓ waybar restarted"
    fi
    if pgrep -x dunst >/dev/null; then
        pkill -x dunst; sleep 0.1
        setsid dunst >/dev/null 2>&1 < /dev/null & disown
        echo "  ✓ dunst restarted"
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)  usage ;;
        --preview)  PREVIEW=1; shift ;;
        --dry-run)  DRY=1; shift ;;
        -y|--yes)   YES=1; shift ;;
        -i)         IMAGE="$2"; shift 2 ;;
        *)          echo "unknown: $1"; usage ;;
    esac
done

[[ -n "$IMAGE" ]] || IMAGE=$(get_wallpaper)
[[ -f "$IMAGE" ]] || { echo "no such image: $IMAGE" >&2; exit 1; }

notify-send "Running pywal..." 2>/dev/null || true
run_wal "$IMAGE"
load_palette
show_palette

if [[ "$PREVIEW" == "1" ]]; then
    exit 0
fi

if [[ "$YES" != "1" ]]; then
    read -rp "  write palette.nix? [y/N] " c
    [[ "$c" =~ ^[Yy]$ ]] || { echo "aborted"; exit 0; }
fi

write_palette_nix

if [[ "$DRY" == "1" ]]; then
    echo "  [dry-run] skipping yeet"
    exit 0
fi

notify-send "Rebuilding..." 2>/dev/null || true
"$YEET"
notify-send "Rebuild completed" 2>/dev/null || true
reload_live
