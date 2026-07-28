// Values with no Astal library behind them still need polling.
// Everything else (network, bluetooth, audio, mpris, battery, powerprofiles)
// is event-driven via astal and lives in the widgets themselves.

import { createPoll } from "ags/time"
import { execAsync } from "ags/process"

const sh = (cmd: string) => ["sh", "-c", cmd]

/** Backlight percentage, 0-100. */
export const brightness = createPoll(
  0,
  2000,
  sh("brightnessctl -m | cut -d, -f4 | tr -d %"),
  (out) => Number(out.trim()) || 0,
)

export const setBrightness = (pct: number) =>
  execAsync(`brightnessctl set ${Math.round(pct)}%`).catch(console.error)

/** CPU busy percentage. */
export const cpu = createPoll(
  0,
  3000,
  sh("top -bn1 | grep 'Cpu(s)' | awk '{print int($2+$4)}'"),
  (out) => Number(out.trim()) || 0,
)

/** Memory used percentage. */
export const memory = createPoll(
  0,
  5000,
  sh("free | awk '/Mem:/ {printf \"%d\", $3/$2*100}'"),
  (out) => Number(out.trim()) || 0,
)

/** Root filesystem used percentage. */
export const disk = createPoll(
  0,
  30000,
  sh("df / | awk 'NR==2 {print $5}' | tr -d %"),
  (out) => Number(out.trim()) || 0,
)

/** Local IP on the default route. */
export const localIp = createPoll(
  "n/a",
  10000,
  sh("ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}'"),
  (out) => out.trim() || "n/a",
)

/** Is waybar running right now? */
export const waybarRunning = createPoll(
  false,
  3000,
  sh("pgrep -x waybar >/dev/null && echo 1 || echo 0"),
  (out) => out.trim() === "1",
)

export const toggleWaybar = (running: boolean) =>
  execAsync(
    running ? "pkill -x waybar" : "sh -c 'setsid waybar >/dev/null 2>&1 &'",
  ).catch(console.error)

/** hyprctl debug:damage_blink state. */
export const damageBlink = createPoll(
  false,
  3000,
  sh("hyprctl getoption debug:damage_blink | awk '/int:/ {print $2}'"),
  (out) => out.trim() === "1",
)

export const toggleDamageBlink = (on: boolean) =>
  execAsync(`hyprctl keyword debug:damage_blink ${on ? 0 : 1}`).catch(
    console.error,
  )

/**
 * Raw powerinfo.py output.
 *
 * The eww version needed a Python wrapper that emitted yuck markup as a
 * string; here it is just text in a monospace label. Delete powerinfo-eww.
 *
 * RAPL energy and MSR C-states need root: `doas -n` is tried first so the
 * poll never blocks on a password prompt, falling back to an unprivileged
 * run where those two sections print their own warning lines.
 */
const POWERINFO = "/etc/nixos/dotfiles/scripts/powerinfo.py --no-color --interval 0.2"
export const powerinfo = createPoll(
  "loading power overview...",
  5000,
  sh(`doas -n ${POWERINFO} 2>/dev/null || ${POWERINFO}`),
  (out) => out.replace(/\x1b\[[0-9;]*m/g, "").trimEnd() || "(no output)",
)

/** Calendar grid for the current month, without the month header line. */
export const calendar = createPoll(
  "",
  60000,
  sh("cal | tail -n +2"),
  (out) => out.trimEnd(),
)
