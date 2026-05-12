#!/usr/bin/env bash
# theme.sh — derive current palette from dotfiles, generate new one from
# wallpaper (or arbitrary image), diff, confirm, apply, save.
#
# usage:
#   theme.sh                  use current awww wallpaper
#   theme.sh -i path/img.png  use arbitrary image
#   theme.sh -y               auto-accept (no prompts, default name)
#   theme.sh --preview        show new palette only
#   theme.sh --dry-run        show all replacements, no writes
#   theme.sh --rollback       restore a saved palette
#   theme.sh -h | --help

set -euo pipefail

DOTFILES="/etc/nixos/dotfiles"
PALETTE_DIR="$DOTFILES/wallpapers/palettes"
WAL_CACHE="$HOME/.cache/wal/colors.sh"
WAL_BIN="/etc/profiles/per-user/joe/bin/wal"

F_HYPR="$DOTFILES/hypr/hyprland.conf"
F_WAYBAR="$DOTFILES/waybar/style.css"
F_WOFI="$DOTFILES/wofi/style.css"
F_LOCK="$DOTFILES/hypr/hyprlock/colors-hyprlock.conf"
F_WLOGOUT="$DOTFILES/wlogout/style.css"
F_DUNST="$DOTFILES/dunst/dunstrc"
F_WEZTERM="$DOTFILES/wezterm/wezterm.lua"
F_STARSHIP="$DOTFILES/starship/starship.toml"

DRY=0
IMAGE=""
YES=0

# ─── help ─────────────────────────────────────────────────────────────────
usage() {
    sed -n '2,11p' "$0" | sed 's/^# \?//'
    exit 0
}

# ─── tiny helpers ─────────────────────────────────────────────────────────
strip() { echo "${1#\#}"; }

hex_rgb_csv() {  # "0d0f1c" -> "13, 15, 28"
    local h; h=$(strip "$1")
    printf "%d, %d, %d" "0x${h:0:2}" "0x${h:2:2}" "0x${h:4:2}"
}

hex_rgb_compact() {  # "0d0f1c" -> "13,15,28"
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

swatch() {
    local label="$1" hex="$2"
    local h; h=$(strip "$hex")
    local r=$(( 16#${h:0:2} )) g=$(( 16#${h:2:2} )) b=$(( 16#${h:4:2} ))
    printf "  \e[48;2;%d;%d;%dm        \e[0m  #%s  %s\n" "$r" "$g" "$b" "$h" "$label"
}

# ─── live reload ──────────────────────────────────────────────────────────
reload_live() {
    echo ""
    echo "→ reloading live config"
    # hyprland: reload reads hyprland.conf
    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl reload >/dev/null && echo "  ✓ hyprctl reload"
    fi
    # waybar: toggle off and on via the user's bartoggle script
    local bartoggle="$DOTFILES/scripts/bartoggle.sh"
    if [[ -x "$bartoggle" ]]; then
        "$bartoggle" >/dev/null 2>&1
        sleep 0.2
        "$bartoggle" >/dev/null 2>&1
        echo "  ✓ waybar restarted via bartoggle.sh"
    fi
    # dunst: needs SIGUSR2 or restart to pick up new colors
    if pgrep -x dunst >/dev/null; then
        pkill -x dunst
        sleep 0.1
        setsid dunst >/dev/null 2>&1 < /dev/null &
        disown
        echo "  ✓ dunst restarted"
    fi
    # hyprlock/wlogout/wofi pick up their config on next launch
}

# ─── wallpaper ────────────────────────────────────────────────────────────
# Ask the awww daemon directly what it's currently displaying.
# Output format: ": eDP-1: 3072x1920, scale: 1, currently displaying: image: /path/to/img.jpg"
get_wallpaper() {
    local wp
    wp=$(awww query 2>/dev/null \
        | grep -m1 'currently displaying: image:' \
        | sed -E 's/.*currently displaying: image:[[:space:]]*//')
    if [[ -z "$wp" || ! -f "$wp" ]]; then
        echo "error: could not determine current wallpaper from 'awww query'" >&2
        echo "       (got: '$wp')" >&2
        exit 1
    fi
    echo "$wp"
}

# ─── pywal ────────────────────────────────────────────────────────────────
run_wal() {
    local img="$1"
    echo "→ pywal on: $(basename "$img")"
    "$WAL_BIN" -i "$img" -n -q
    [[ -f "$WAL_CACHE" ]] || { echo "error: wal produced no $WAL_CACHE" >&2; exit 1; }
}

# ─── derive CURRENT palette from dotfiles ────────────────────────────────
# All reads anchor on file content, not line numbers. Uses POSIX grep/sed
# only (no gawk-specific features).

# Extract first capture group from first matching line.
#   pat must be an ERE with a single group "(...)".
# Implementation: grep -oE on the whole pattern, then sed off the
# surrounding non-capture text. To do that we require callers to pass a
# wrapping regex and a "strip" sed expression. To avoid that complexity,
# we instead use a two-step approach: match the surrounding context,
# then extract the value with a second narrower pattern.

# first_match FILE FULL_PATTERN STRIP_SED
#   FULL_PATTERN: ERE matched by grep -oE (matches whole substring)
#   STRIP_SED: sed -E expression to extract just the value from match
first_match() {
    local file="$1" pat="$2" strip="$3"
    grep -m1 -oEi "$pat" "$file" 2>/dev/null | sed -E "$strip" | head -1
}

# after_marker FILE MARKER FULL_PATTERN STRIP_SED
#   Skip lines until MARKER (fixed string) matches, then run first_match
#   logic on remaining lines.
after_marker() {
    local file="$1" marker="$2" pat="$3" strip="$4"
    awk -v mark="$marker" 'index($0,mark){found=1;next} found' "$file" \
        | grep -m1 -oEi "$pat" 2>/dev/null | sed -E "$strip" | head -1
}

# from_marker FILE MARKER FULL_PATTERN STRIP_SED
#   Like after_marker but INCLUDES the marker line itself in the search.
from_marker() {
    local file="$1" marker="$2" pat="$3" strip="$4"
    awk -v mark="$marker" 'index($0,mark){found=1} found' "$file" \
        | grep -m1 -oEi "$pat" 2>/dev/null | sed -E "$strip" | head -1
}

read_current() {
    # ── hyprland ──
    CUR_BORDER_ACTIVE=$(first_match "$F_HYPR" \
        'col\.active_border = rgba\([0-9a-fA-F]{6}ff\)' \
        's/.*rgba\(([0-9a-fA-F]{6})ff\)/\1/')
    CUR_BORDER_ACTIVE2=$(first_match "$F_HYPR" \
        'col\.active_border = rgba\([0-9a-fA-F]{6}ff\) rgba\([0-9a-fA-F]{6}ff\)' \
        's/.*rgba\([0-9a-fA-F]{6}ff\) rgba\(([0-9a-fA-F]{6})ff\)/\1/')
    CUR_BORDER_INACTIVE=$(first_match "$F_HYPR" \
        'col\.inactive_border = rgba\([0-9a-fA-F]{6}ff\)' \
        's/.*rgba\(([0-9a-fA-F]{6})ff\)/\1/')

    # ── waybar ──
    # Body text color: after '#waybar' selector
    CUR_WB_TEXT=$(after_marker "$F_WAYBAR" '#waybar' \
        'color: #[0-9a-fA-F]{6}' 's/color: #//')
    # Dim text: after '#workspaces button' selector
    CUR_WB_DIM=$(after_marker "$F_WAYBAR" '#workspaces button' \
        'color: #[0-9a-fA-F]{6}' 's/color: #//')
    # Top border-bottom (first occurrence; shared across modules)
    CUR_WB_TOPBAR=$(first_match "$F_WAYBAR" \
        'border-bottom: 2px solid #[0-9a-fA-F]{6}' 's/.*#//')
    # Module border (first 'border: 1px solid')
    CUR_WB_BORDER=$(first_match "$F_WAYBAR" \
        'border: 1px solid #[0-9a-fA-F]{6}' 's/.*#//')
    # Hover/surface bg (first literal-hex background-color)
    CUR_WB_HOVER=$(first_match "$F_WAYBAR" \
        'background-color: #[0-9a-fA-F]{6}' 's/.*#//')
    # Bg rgba triplet (first rgba in file)
    CUR_BG_RGB=$(first_match "$F_WAYBAR" \
        'rgba\([0-9]+, [0-9]+, [0-9]+,' 's/rgba\(//;s/,$//')
    # workspaces button.active: gradient(135deg, #AAA, #BBB) — two hexes
    CUR_WB_ACTIVE_GRAD1=$(after_marker "$F_WAYBAR" 'button.active' \
        'linear-gradient\(135deg, #[0-9a-fA-F]{6}' 's/.*#//')
    CUR_WB_ACTIVE_GRAD2=$(after_marker "$F_WAYBAR" 'button.active' \
        '#[0-9a-fA-F]{6}\)' 's/[#)]//g')
    # workspaces button.active border (lavender, distinct from main border)
    CUR_WB_ACTIVE_BORDER=$(after_marker "$F_WAYBAR" 'button.active' \
        'border: 1px solid #[0-9a-fA-F]{6}' 's/.*#//')

    # ── wofi ──
    # Three nested borders: #window (outer), #outer-box (middle), #scroll (inner).
    CUR_WOFI_BORDER=$(first_match "$F_WOFI" \
        'border: 2px solid #[0-9a-fA-F]{6}' 's/.*#//')
    CUR_WOFI_BORDER_MID=$(after_marker "$F_WOFI" '#outer-box' \
        'border: 2px solid #[0-9a-fA-F]{6}' 's/.*#//')
    CUR_WOFI_BORDER2=$(after_marker "$F_WOFI" '#scroll' \
        'border: 2px solid #[0-9a-fA-F]{6}' 's/.*#//')
    # First non-(0,0,0)/(255,255,255) rgba
    CUR_WOFI_BG_RGB=$(grep -oE 'rgba\([0-9]+, [0-9]+, [0-9]+,' "$F_WOFI" \
        | sed -E 's/rgba\(//;s/,$//' \
        | grep -vE '^(0, 0, 0|255, 255, 255)$' | head -1)
    CUR_WOFI_ACCENT_RGB=$(after_marker "$F_WOFI" ':selected' \
        'rgba\([0-9]+, [0-9]+, [0-9]+,' 's/rgba\(//;s/,$//')

    # ── hyprlock ──
    CUR_LOCK_BG=$(first_match "$F_LOCK" '^\$background = rgb\([0-9,]+\)' \
        's/.*rgb\(//;s/\)//')
    CUR_LOCK_FG=$(first_match "$F_LOCK" '^\$foreground = rgb\([0-9,]+\)' \
        's/.*rgb\(//;s/\)//')
    CUR_LOCK_C1=$(first_match "$F_LOCK" '^\$color1 = rgb\([0-9,]+\)' \
        's/.*rgb\(//;s/\)//')
    CUR_LOCK_C2=$(first_match "$F_LOCK" '^\$color2 = rgb\([0-9,]+\)' \
        's/.*rgb\(//;s/\)//')

    # ── wlogout ──
    # Anchor by selectors so it works whether or not bg/btn share a color.
    # 'window' bg: first rgba(...) in file (under 'window {' block)
    CUR_WL_BG_RGB=$(first_match "$F_WLOGOUT" \
        'rgba\([0-9]+, [0-9]+, [0-9]+,' 's/rgba\(//;s/,$//')
    # button bg: first rgba after the 'button' selector (excluding pseudos)
    CUR_WL_BTN_RGB=$(after_marker "$F_WLOGOUT" 'button {' \
        'rgba\([0-9]+, [0-9]+, [0-9]+,' 's/rgba\(//;s/,$//')
    # selected/hover bg: first rgba after ':focus' or ':hover' or ':active'
    CUR_WL_SEL_RGB=$(after_marker "$F_WLOGOUT" 'button:' \
        'rgba\([0-9]+, [0-9]+, [0-9]+,' 's/rgba\(//;s/,$//')
    # border-color: anchored by 'button' selector
    CUR_WL_BORDER=$(after_marker "$F_WLOGOUT" 'button' \
        'border-color: #[0-9a-fA-F]{6}' 's/.*#//')

    # ── dunst ──
    CUR_DUNST_FRAME=$(first_match "$F_DUNST" \
        'frame_color = "#[0-9a-fA-F]{6}"' 's/.*#//;s/"//')
    CUR_DUNST_BG=$(first_match "$F_DUNST" \
        'background_color = "#[0-9a-fA-F]{6}"' 's/.*#//;s/"//')
    CUR_DUNST_FG=$(first_match "$F_DUNST" \
        'foreground_color = "#[0-9a-fA-F]{6}"' 's/.*#//;s/"//')
    # 'background' (8-char with alpha): match the standalone background line
    CUR_DUNST_BG_ALPHA=$(first_match "$F_DUNST" \
        '^[[:space:]]*background = "#[0-9a-fA-F]{8}"' 's/.*#//;s/"//')

    # ── wezterm ──
    # gradient color list — first hex inside window_background_gradient block
    CUR_WEZ_GRAD=$(after_marker "$F_WEZTERM" 'window_background_gradient' \
        "'#[0-9a-fA-F]{6}'" "s/[#']//g")
    # second background-layer Color (uppercase hex, no #)
    CUR_WEZ_LAYER=$(from_marker "$F_WEZTERM" 'Color =' \
        '"[0-9a-fA-F]{6}"' 's/"//g')

    # ── starship.toml ──
    # [os] segment: fg + bg
    CUR_STAR_NIX_FG=$(after_marker "$F_STARSHIP" '[os]' \
        'fg:#[0-9a-fA-F]{6}' 's/.*fg:#//')
    CUR_STAR_NIX_BG=$(after_marker "$F_STARSHIP" '[os]' \
        'bg:#[0-9a-fA-F]{6}' 's/.*bg:#//')
    # [directory] segment: fg + bg
    CUR_STAR_DIR_FG=$(after_marker "$F_STARSHIP" '[directory]' \
        'fg:#[0-9a-fA-F]{6}' 's/.*fg:#//')
    CUR_STAR_DIR_BG=$(after_marker "$F_STARSHIP" '[directory]' \
        'bg:#[0-9a-fA-F]{6}' 's/.*bg:#//')

    # ── sanity check ──
    local missing=()
    for v in CUR_BORDER_ACTIVE CUR_BORDER_ACTIVE2 CUR_BORDER_INACTIVE \
             CUR_WB_TEXT CUR_WB_DIM CUR_WB_TOPBAR CUR_WB_BORDER CUR_WB_HOVER \
             CUR_WB_ACTIVE_GRAD1 CUR_WB_ACTIVE_GRAD2 CUR_WB_ACTIVE_BORDER \
             CUR_BG_RGB CUR_WOFI_BORDER CUR_WOFI_BORDER_MID CUR_WOFI_BORDER2 \
             CUR_WOFI_BG_RGB CUR_WOFI_ACCENT_RGB CUR_LOCK_BG CUR_LOCK_FG \
             CUR_LOCK_C1 CUR_LOCK_C2 CUR_WL_BG_RGB CUR_WL_BORDER \
             CUR_WL_BTN_RGB CUR_WL_SEL_RGB \
             CUR_DUNST_FRAME CUR_DUNST_BG CUR_DUNST_FG CUR_DUNST_BG_ALPHA \
             CUR_WEZ_GRAD CUR_WEZ_LAYER \
             CUR_STAR_NIX_FG CUR_STAR_NIX_BG CUR_STAR_DIR_FG CUR_STAR_DIR_BG; do
        [[ -z "${!v}" ]] && missing+=("$v")
    done
    if (( ${#missing[@]} > 0 )); then
        echo "error: failed to extract current values for:" >&2
        printf "  %s\n" "${missing[@]}" >&2
        echo "anchor matching failed — dotfiles may have diverged." >&2
        exit 1
    fi
}

# ─── derive NEW palette from wal ─────────────────────────────────────────
read_new_from_wal() {
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
    set -u
}

read_new_from_file() {
    set +u
    # shellcheck source=/dev/null
    source "$1"
    BG_RGB=$(hex_rgb_csv "$BG")
    BG_ALT_RGB=$(hex_rgb_csv "$BG_ALT")
    ACCENT_RGB=$(hex_rgb_csv "$ACCENT")
    set -u
}

# ─── preview ──────────────────────────────────────────────────────────────
show_palette() {
    echo ""
    echo "  new palette"
    echo "  ────────────────────────────────────────────────"
    swatch "bg" "#$BG"
    swatch "bg_alt" "#$BG_ALT"
    swatch "surface" "#$SURFACE"
    swatch "border" "#$BORDER"
    swatch "border_active  (start)" "#$BORDER_ACTIVE"
    swatch "border_active2 (end)" "#$BORDER_ACTIVE2"
    swatch "border_inactive" "#$BORDER_INACTIVE"
    swatch "accent" "#$ACCENT"
    swatch "text" "#$TEXT"
    swatch "text_dim" "#$TEXT_DIM"
    echo ""
    echo "  hyprlock: bg=$LOCK_BG  fg=$LOCK_FG  c1=$LOCK_C1  c2=$LOCK_C2"
    echo ""
}

# ─── diff ─────────────────────────────────────────────────────────────────
# Track all (file, literal_old, literal_new) tuples. Apply phase replays them.
declare -a R_FILES R_OLDS R_NEWS

add_repl() { R_FILES+=("$1"); R_OLDS+=("$2"); R_NEWS+=("$3"); }

build_replacements() {
    R_FILES=(); R_OLDS=(); R_NEWS=()

    # hyprland
    add_repl "$F_HYPR" \
        "rgba(${CUR_BORDER_ACTIVE}ff) rgba(${CUR_BORDER_ACTIVE2}ff)" \
        "rgba(${BORDER_ACTIVE}ff) rgba(${BORDER_ACTIVE2}ff)"
    add_repl "$F_HYPR" \
        "rgba(${CUR_BORDER_INACTIVE}ff)" \
        "rgba(${BORDER_INACTIVE}ff)"

    # waybar — replace the bg triplet (preserves any alpha), and the 4 structural hexes
    add_repl "$F_WAYBAR" "rgba(${CUR_BG_RGB}," "rgba(${BG_RGB},"
    # topbar border-bottom appears multiple times with the same color — single sed replaces all
    add_repl "$F_WAYBAR" "border-bottom: 2px solid #${CUR_WB_TOPBAR}" \
                          "border-bottom: 2px solid #${BORDER}"
    add_repl "$F_WAYBAR" "border: 1px solid #${CUR_WB_BORDER}" \
                          "border: 1px solid #${BORDER}"
    add_repl "$F_WAYBAR" "border: 1px solid #${CUR_WB_TOPBAR}" \
                          "border: 1px solid #${BORDER}"
    add_repl "$F_WAYBAR" "background-color: #${CUR_WB_HOVER}" \
                          "background-color: #${SURFACE}"
    # text on lines 23 and 28 (same color)
    add_repl "$F_WAYBAR" "color: #${CUR_WB_TEXT};" "color: #${TEXT};"
    # dim text on 39 and 102 (same color)
    add_repl "$F_WAYBAR" "color: #${CUR_WB_DIM};" "color: #${TEXT_DIM};"
    # workspaces button.active gradient (light → dark)
    add_repl "$F_WAYBAR" \
        "linear-gradient(135deg, #${CUR_WB_ACTIVE_GRAD1}, #${CUR_WB_ACTIVE_GRAD2})" \
        "linear-gradient(135deg, #${BORDER}, #${ACCENT})"
    # workspaces button.active border — match within the linear-gradient context
    # so it doesn't collide with the generic "border: 1px solid" replacement.
    add_repl "$F_WAYBAR" \
        "linear-gradient(135deg, #${BORDER}, #${ACCENT});
    border: 1px solid #${CUR_WB_ACTIVE_BORDER}" \
        "linear-gradient(135deg, #${BORDER}, #${ACCENT});
    border: 1px solid #${BORDER}"

    # wofi: three nested borders fade outer→inner
    add_repl "$F_WOFI" "border: 2px solid #${CUR_WOFI_BORDER}" \
                       "border: 2px solid #${BORDER}"
    add_repl "$F_WOFI" "border: 2px solid #${CUR_WOFI_BORDER_MID}" \
                       "border: 2px solid #$(darken "$BORDER" 10)"
    add_repl "$F_WOFI" "border: 2px solid #${CUR_WOFI_BORDER2}" \
                       "border: 2px solid #$(darken "$BORDER" 20)"
    add_repl "$F_WOFI" "rgba(${CUR_WOFI_BG_RGB}," "rgba(${BG_RGB},"
    add_repl "$F_WOFI" "rgba(${CUR_WOFI_ACCENT_RGB}," "rgba(${ACCENT_RGB},"

    # hyprlock
    add_repl "$F_LOCK" "\$background = rgb(${CUR_LOCK_BG})" \
                       "\$background = rgb(${LOCK_BG})"
    add_repl "$F_LOCK" "\$foreground = rgb(${CUR_LOCK_FG})" \
                       "\$foreground = rgb(${LOCK_FG})"
    add_repl "$F_LOCK" "\$color1 = rgb(${CUR_LOCK_C1})" \
                       "\$color1 = rgb(${LOCK_C1})"
    add_repl "$F_LOCK" "\$color2 = rgb(${CUR_LOCK_C2})" \
                       "\$color2 = rgb(${LOCK_C2})"

    # wlogout
    add_repl "$F_WLOGOUT" "rgba(${CUR_WL_BG_RGB}," "rgba(${BG_ALT_RGB},"
    add_repl "$F_WLOGOUT" "rgba(${CUR_WL_BTN_RGB}," "rgba(${BG_RGB},"
    add_repl "$F_WLOGOUT" "rgba(${CUR_WL_SEL_RGB}," "rgba(${ACCENT_RGB},"
    add_repl "$F_WLOGOUT" "border-color: #${CUR_WL_BORDER}" \
                          "border-color: #${BORDER}"

    # dunst: frame → BORDER, bg → BG, fg → TEXT.
    # Keep the original alpha byte on the rgba 'background' field.
    local dunst_bg_alpha="${CUR_DUNST_BG_ALPHA:6:2}"
    add_repl "$F_DUNST" \
        "frame_color = \"#${CUR_DUNST_FRAME}\"" \
        "frame_color = \"#${BORDER}\""
    add_repl "$F_DUNST" \
        "background_color = \"#${CUR_DUNST_BG}\"" \
        "background_color = \"#${BG}\""
    add_repl "$F_DUNST" \
        "foreground_color = \"#${CUR_DUNST_FG}\"" \
        "foreground_color = \"#${TEXT}\""
    add_repl "$F_DUNST" \
        "background = \"#${CUR_DUNST_BG_ALPHA}\"" \
        "background = \"#${BG}${dunst_bg_alpha}\""

    # wezterm: gradient color → BG, second-layer Color → BG_ALT.
    # The layer Color is bare uppercase hex with no '#'.
    add_repl "$F_WEZTERM" \
        "'#${CUR_WEZ_GRAD}'" \
        "'#${BG}'"
    add_repl "$F_WEZTERM" \
        "Color = \"${CUR_WEZ_LAYER}\"" \
        "Color = \"${BG_ALT^^}\""

    # starship.toml — Nix segment + directory segment.
    # Replace style strings literally; this also catches the same color
    # references inside the format-block triangle style annotations because
    # all three triangle styles use the same two colors as the segments.
    add_repl "$F_STARSHIP" \
        "fg:#${CUR_STAR_NIX_FG} bg:#${CUR_STAR_NIX_BG}" \
        "fg:#${ACCENT} bg:#${BG_ALT}"
    add_repl "$F_STARSHIP" \
        "fg:#${CUR_STAR_DIR_FG} bg:#${CUR_STAR_DIR_BG}" \
        "fg:#${TEXT} bg:#${SURFACE}"
    # Triangle separators use bare-bg / bare-fg color refs; replace those.
    # Leading triangle (terminal → nix bg): fg:#${CUR_STAR_NIX_BG}
    # Middle triangle (nix bg → dir bg): bg:#${CUR_STAR_DIR_BG} fg:#${CUR_STAR_NIX_BG}
    # Trailing triangle (dir bg → terminal): fg:#${CUR_STAR_DIR_BG}
    add_repl "$F_STARSHIP" \
        "bg:#${CUR_STAR_DIR_BG} fg:#${CUR_STAR_NIX_BG}" \
        "bg:#${SURFACE} fg:#${BG_ALT}"
    # Bare fg: references for leading/trailing triangles.
    # These can collide with other fg: occurrences, so use the full
    # bracketed style annotation as the literal.
    add_repl "$F_STARSHIP" \
        "](fg:#${CUR_STAR_NIX_BG})" \
        "](fg:#${BG_ALT})"
    add_repl "$F_STARSHIP" \
        "](fg:#${CUR_STAR_DIR_BG})" \
        "](fg:#${SURFACE})"
    # error_symbol left untouched — semantic red
    # error_symbol left untouched — semantic red
}

show_diff() {
    echo "  replacements (literal string → literal string)"
    echo "  ────────────────────────────────────────────────"
    local i
    local cur_file=""
    for i in "${!R_FILES[@]}"; do
        if [[ "${R_FILES[i]}" != "$cur_file" ]]; then
            cur_file="${R_FILES[i]}"
            echo ""
            echo "  ${cur_file#$DOTFILES/}"
        fi
        # show if old appears in file at all
        local n
        n=$(grep -cF "${R_OLDS[i]}" "${R_FILES[i]}" 2>/dev/null || echo 0)
        printf "    [%dx]  %s\n          → %s\n" \
            "$n" "${R_OLDS[i]}" "${R_NEWS[i]}"
    done
    echo ""
}

apply_replacements() {
    local i
    for i in "${!R_FILES[@]}"; do
        local old="${R_OLDS[i]}" new="${R_NEWS[i]}" file="${R_FILES[i]}"
        # literal replace via awk (no regex escaping headaches)
        local tmp; tmp=$(mktemp)
        awk -v o="$old" -v n="$new" '
            { while ((p = index($0, o)) > 0) {
                $0 = substr($0,1,p-1) n substr($0,p+length(o))
              }
              print
            }
        ' "$file" > "$tmp" && mv "$tmp" "$file"
    done
}

# ─── save ─────────────────────────────────────────────────────────────────
save_palette() {
    local name="$1"
    mkdir -p "$PALETTE_DIR"
    cat > "$PALETTE_DIR/${name}.sh" <<EOF
# palette: $name
# saved: $(date '+%Y-%m-%d %H:%M')
# source: ${IMAGE_LABEL:-unknown}

BG="$BG"
BG_ALT="$BG_ALT"
SURFACE="$SURFACE"
BORDER="$BORDER"
BORDER_ACTIVE="$BORDER_ACTIVE"
BORDER_ACTIVE2="$BORDER_ACTIVE2"
BORDER_INACTIVE="$BORDER_INACTIVE"
ACCENT="$ACCENT"
TEXT="$TEXT"
TEXT_DIM="$TEXT_DIM"
LOCK_BG="$LOCK_BG"
LOCK_FG="$LOCK_FG"
LOCK_C1="$LOCK_C1"
LOCK_C2="$LOCK_C2"
EOF
    echo "→ saved: $PALETTE_DIR/${name}.sh"
}

# ─── rollback ─────────────────────────────────────────────────────────────
do_rollback() {
    mkdir -p "$PALETTE_DIR"
    local palettes=()
    while IFS= read -r -d '' f; do palettes+=("$f"); done \
        < <(find "$PALETTE_DIR" -maxdepth 1 -name '*.sh' -print0 | sort -z)

    [[ ${#palettes[@]} -gt 0 ]] || { echo "no saved palettes"; exit 1; }

    echo ""
    echo "  saved palettes:"
    local i=1
    for p in "${palettes[@]}"; do
        local saved; saved=$(grep '^# saved:' "$p" | sed 's/# saved: //')
        local src;   src=$(grep '^# source:' "$p" | sed 's/# source: //')
        printf "  %2d)  %-30s  %s  %s\n" "$i" "$(basename "${p%.sh}")" "$saved" "$src"
        ((i++))
    done
    echo ""
    read -rp "  select number: " sel
    local chosen="${palettes[$((sel-1))]:-}"
    [[ -f "$chosen" ]] || { echo "invalid"; exit 1; }

    echo "→ loading: $(basename "${chosen%.sh}")"
    read_new_from_file "$chosen"
    read_current
    build_replacements
    show_diff
    show_palette

    read -rp "  apply? [y/N] " c
    [[ "$c" =~ ^[Yy]$ ]] || { echo "aborted"; exit 0; }

    apply_replacements
    echo ""
    "$DOTFILES/scripts/yeet.sh"

    reload_live
}

# ─── arg parsing ──────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)     usage ;;
        --rollback|-rb) do_rollback; exit 0 ;;
        --preview)     ACTION=preview; shift ;;
        --dry-run)     DRY=1; shift ;;
        -y|--yes)      YES=1; shift ;;
        -i)            IMAGE="$2"; shift 2 ;;
        *)             echo "unknown: $1"; usage ;;
    esac
done

# ─── main ─────────────────────────────────────────────────────────────────
if [[ -n "$IMAGE" ]]; then
    [[ -f "$IMAGE" ]] || { echo "no such image: $IMAGE" >&2; exit 1; }
    IMAGE_LABEL="$IMAGE"
else
    IMAGE=$(get_wallpaper)
    IMAGE_LABEL="$IMAGE (awww)"
fi

notify-send "Running pywal..."
run_wal "$IMAGE"
read_new_from_wal
read_current

if [[ "${ACTION:-}" == "preview" ]]; then
    show_palette
    exit 0
fi

build_replacements
show_diff
show_palette

if [[ "$DRY" == "1" ]]; then
    echo "  [dry-run] no files written. would run: doas nixos-rebuild switch"
    exit 0
fi

if [[ "$YES" == "1" ]]; then
    echo "  -y: auto-applying"
else
    read -rp "  apply? [y/N] " c
    [[ "$c" =~ ^[Yy]$ ]] || { echo "aborted"; exit 0; }
fi

# name + save
wp_base=$(basename "$IMAGE" | sed 's/\.[^.]*$//')
default_name="${wp_base}_$(date '+%Y%m%d_%H%M')"
if [[ "$YES" == "1" ]]; then
    palette_name="$default_name"
else
    read -rp "  palette name [${default_name}]: " palette_name
    palette_name=$(echo "${palette_name:-$default_name}" | tr ' /' '_')
fi
save_palette "$palette_name"

notify-send "Color palette written, nixos-rebuild underway..."
apply_replacements
echo ""
"$DOTFILES/scripts/yeet.sh"
notify-send "Rebuild completed"

reload_live
