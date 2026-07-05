#!/usr/bin/env python3
"""
plot_power.py — plot a paired (turbostat + powersample) session.

Usage:
  python3 plot_power.py turbostat-<stem>.log [powersample-<stem>.ndjson] [-o out.png] [--cores]

Both streams share a wall-clock epoch (turbostat's Time_Of_Day_Seconds column,
enabled in the service; the sampler's `t`). Everything is plotted on one real-time
x-axis (minutes since session start) so eGPU/battery telemetry lines up with
package power, and config changes (AC/EPP/profile/refresh) show as markers.

If the ndjson path is omitted it's inferred by swapping the turbostat filename
stem. Per-core heatmaps (--cores) are unchanged from the old script.
"""

import argparse, sys, os, re, json
from collections import defaultdict

import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec

# ------------------------------------------------------------------ theme
BG_FIG, BG_AX, GRID, FG = "#1a1a2e", "#12122a", "#333355", "#e0e0e0"
COLORS = ["#7ec8e3", "#f4a261", "#2a9d8f", "#e76f51", "#a8dadc", "#457b9d", "#c77dff"]

# ============================================================ turbostat parse
HEADER_RE = re.compile(r"^Core\s+CPU\s+Avg_MHz")

def parse_turbostat(path):
    summary, per_core = [], defaultdict(list)
    headers = None
    cur_sum, cur_cores, interval = None, {}, 0
    with open(path, "r", errors="replace") as f:
        for line in f:
            line = re.sub(r"^[^\w\-]+", "", line.rstrip()).strip()
            if not line:
                continue
            if HEADER_RE.match(line):
                if cur_sum is not None:
                    summary.append(cur_sum)
                    for k, v in cur_cores.items():
                        per_core[k].append(v)
                headers = line.split()
                cur_sum, cur_cores = None, {}
                interval += 1
                continue
            if headers is None:
                continue
            parts = line.split()
            if len(parts) < len(headers) - 5:
                continue
            while len(parts) < len(headers):
                parts.append("0")
            row = {}
            for i, h in enumerate(headers):
                try:
                    row[h] = float(parts[i])
                except (ValueError, IndexError):
                    row[h] = float("nan")
            if parts[0] == "-" and parts[1] == "-":
                cur_sum = row
            else:
                try:
                    cid = int(parts[0])
                    if cid not in cur_cores:
                        cur_cores[cid] = row
                except ValueError:
                    pass
    if cur_sum is not None:
        summary.append(cur_sum)
        for k, v in cur_cores.items():
            per_core[k].append(v)
    return summary, per_core

def col(rows, key):
    return np.array([r.get(key, np.nan) for r in rows], dtype=float)

# ============================================================ ndjson parse
def parse_ndjson(path):
    samples, configs, events = [], [], []
    if not path or not os.path.exists(path):
        return samples, configs, events
    with open(path, "r", errors="replace") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                o = json.loads(line)
            except json.JSONDecodeError:
                continue
            t = o.get("type")
            (samples if t == "sample" else
             configs if t == "config" else
             events if t == "event" else []).append(o)
    return samples, configs, events

def sarr(samples, key):
    t = np.array([s["t"] for s in samples if key in s], dtype=float)
    v = np.array([s[key] for s in samples if key in s], dtype=float)
    return t, v

# ============================================================ time base
def turbostat_time(summary):
    tod = col(summary, "Time_Of_Day_Seconds")
    if np.isfinite(tod).any():
        return tod
    return np.arange(len(summary), dtype=float)   # fallback: interval index (sec)

# ============================================================ plotting
def ax_style(ax):
    ax.set_facecolor(BG_AX)
    ax.tick_params(colors=FG, labelsize=8)
    ax.xaxis.label.set_color(FG); ax.yaxis.label.set_color(FG); ax.title.set_color(FG)
    for sp in ax.spines.values():
        sp.set_edgecolor(GRID)
    ax.grid(color=GRID, linewidth=0.5, alpha=0.7)

def config_markers(ax, configs, t0, keys=("ac", "epp", "platform_profile")):
    """Vertical dashed line + label whenever a watched config key changes."""
    prev = {}
    for c in configs:
        x = (c["t"] - t0) / 60.0
        for k in keys:
            if k in c and c[k] != prev.get(k):
                if prev:  # skip the very first snapshot
                    ax.axvline(x, color=COLORS[6], lw=0.7, alpha=0.6, ls="--")
                    ax.text(x, ax.get_ylim()[1], f"{k}={c[k]}", rotation=90,
                            va="top", ha="right", fontsize=6, color=COLORS[6], alpha=0.9)
                prev[k] = c[k]

def plot_session(summary, samples, configs, events, out_path, title=""):
    if not summary:
        print("No turbostat summary rows.", file=sys.stderr)
        return
    tod = turbostat_time(summary)
    t0 = tod[0]
    if samples:
        t0 = min(t0, min(s["t"] for s in samples))
    x = (tod - t0) / 60.0   # minutes

    fig = plt.figure(figsize=(16, 22))
    fig.patch.set_facecolor(BG_FIG)
    gs = gridspec.GridSpec(6, 2, figure=fig, hspace=0.5, wspace=0.32)

    def mk(pos):
        ax = fig.add_subplot(pos); ax_style(ax); return ax

    def xt(ts):
        return (ts - t0) / 60.0

    # 1. Package power + eGPU power overlay
    ax = mk(gs[0, :])
    ax.plot(x, col(summary, "PkgWatt"), color=COLORS[0], lw=1.1, label="CPU Pkg")
    ax.plot(x, col(summary, "GFXWatt"), color=COLORS[2], lw=0.9, label="iGPU")
    tp, vp = sarr(samples, "amd_power_w")
    if len(tp):
        ax.plot(xt(tp), vp, color=COLORS[3], lw=1.1, label="eGPU")
    ax.set_title("Power"); ax.set_ylabel("W")
    ax.legend(facecolor="#222244", labelcolor=FG, fontsize=8)
    config_markers(ax, configs, t0)

    # 2. Battery power draw
    ax = mk(gs[1, 0])
    tb, vb = sarr(samples, "bat_power_w")
    if len(tb):
        ax.plot(xt(tb), vb, color=COLORS[1], lw=1.0)
    ax.set_title("Battery Power (0 = on AC / idle)"); ax.set_ylabel("W")
    config_markers(ax, configs, t0, keys=("ac",))

    # 3. eGPU busy %
    ax = mk(gs[1, 1])
    tbu, vbu = sarr(samples, "amd_busy")
    if len(tbu):
        ax.plot(xt(tbu), vbu, color=COLORS[3], lw=1.0)
    ax.set_title("eGPU Busy %"); ax.set_ylabel("%"); ax.set_ylim(0, 105)

    # 4. Temps: pkg + eGPU edge/junction
    ax = mk(gs[2, 0])
    ax.plot(x, col(summary, "PkgTmp"), color=COLORS[0], lw=1.0, label="CPU pkg")
    for key, c, lbl in (("amd_temp_edge", COLORS[3], "eGPU edge"),
                        ("amd_temp_junction", COLORS[1], "eGPU junction")):
        tt, vt = sarr(samples, key)
        if len(tt):
            ax.plot(xt(tt), vt, color=c, lw=0.9, label=lbl)
    ax.set_title("Temperatures"); ax.set_ylabel("°C")
    ax.legend(facecolor="#222244", labelcolor=FG, fontsize=8)

    # 5. eGPU fan
    ax = mk(gs[2, 1])
    tf, vf = sarr(samples, "amd_fan_rpm")
    if len(tf):
        ax.plot(xt(tf), vf, color=COLORS[5], lw=1.0)
    ax.set_title("eGPU Fan"); ax.set_ylabel("RPM")

    # 6. CPU busy %
    ax = mk(gs[3, 0])
    ax.plot(x, col(summary, "Totl%C0"), color=COLORS[0], lw=1.0)
    ax.set_title("CPU Busy %"); ax.set_ylabel("%"); ax.set_ylim(0, 105)

    # 7. C-state residency
    ax = mk(gs[3, 1])
    ax.stackplot(x, col(summary, "C1E%"), col(summary, "C6%"), col(summary, "C10%"),
                 labels=["C1E", "C6", "C10"],
                 colors=[COLORS[1], COLORS[2], COLORS[4]], alpha=0.8)
    ax.set_title("Pkg C-State Residency"); ax.set_ylabel("%"); ax.set_ylim(0, 105)
    ax.legend(facecolor="#222244", labelcolor=FG, fontsize=8, loc="upper right")

    # 8. Frequency
    ax = mk(gs[4, 0])
    ax.plot(x, col(summary, "Bzy_MHz"), color=COLORS[1], lw=1.0, label="Busy")
    ax.plot(x, col(summary, "Avg_MHz"), color=COLORS[0], lw=1.0, label="Avg")
    ax.set_title("CPU Frequency"); ax.set_ylabel("MHz")
    ax.legend(facecolor="#222244", labelcolor=FG, fontsize=8)

    # 9. Refresh rate (step, from config stream)
    ax = mk(gs[4, 1])
    rt = [(c["t"], c["refresh_hz"]) for c in configs
          if c.get("refresh_hz") is not None]
    if rt:
        rx = [xt(t) for t, _ in rt]; ry = [v for _, v in rt]
        ax.step(rx, ry, where="post", color=COLORS[6], lw=1.2)
    ax.set_title("Refresh Rate"); ax.set_ylabel("Hz")

    # 10. eGPU present timeline (hotplug events)
    ax = mk(gs[5, 0])
    if events:
        for e in events:
            if e.get("event") == "egpu":
                c = COLORS[2] if e.get("present") else COLORS[3]
                ax.axvline(xt(e["t"]), color=c, lw=1.2,
                           label="plug" if e.get("present") else "unplug")
    ax.set_title("eGPU Hotplug Events"); ax.set_yticks([])

    # 11. IPC
    ax = mk(gs[5, 1])
    ax.plot(x, col(summary, "IPC"), color=COLORS[2], lw=1.0)
    ax.set_title("IPC"); ax.set_ylabel("IPC")

    for a in fig.get_axes():
        a.set_xlabel("minutes")

    fig.suptitle(f"Power Session{title}", color=FG, fontsize=14, y=0.997)
    plt.savefig(out_path, dpi=150, bbox_inches="tight", facecolor=BG_FIG)
    print(f"Saved: {out_path}")
    plt.close(fig)

# ============================================================ per-core (unchanged)
def plot_heatmap(per_core, out_path, key="Busy%", title=None):
    cids = sorted(per_core.keys())
    if not cids:
        return
    mx = max(len(per_core[c]) for c in cids)
    data = np.full((len(cids), mx), np.nan)
    for i, cid in enumerate(cids):
        vals = [r.get(key, np.nan) for r in per_core[cid]]
        data[i, :len(vals)] = vals
    fig, ax = plt.subplots(figsize=(16, max(4, len(cids) * 0.4 + 1)))
    fig.patch.set_facecolor(BG_FIG); ax.set_facecolor(BG_AX)
    cmap = "plasma" if key in ("Busy%", "CoreTmp") else "viridis"
    im = ax.imshow(data, aspect="auto", interpolation="nearest", cmap=cmap)
    cb = fig.colorbar(im, ax=ax); cb.ax.tick_params(colors=FG); cb.set_label(key, color=FG)
    ax.set_yticks(range(len(cids))); ax.set_yticklabels([f"Core {c}" for c in cids],
                                                        fontsize=7, color=FG)
    ax.set_xlabel("Interval", color=FG); ax.tick_params(colors=FG)
    ax.set_title(title or f"Per-Core {key}", color=FG)
    for sp in ax.spines.values():
        sp.set_edgecolor(GRID)
    plt.savefig(out_path, dpi=150, bbox_inches="tight", facecolor=BG_FIG)
    print(f"Saved: {out_path}")
    plt.close(fig)

# ============================================================ main
def infer_ndjson(turbo_path):
    base = os.path.basename(turbo_path)
    m = re.match(r"turbostat-(.+)\.log$", base)
    if not m:
        return None
    cand = os.path.join(os.path.dirname(turbo_path), f"powersample-{m.group(1)}.ndjson")
    return cand if os.path.exists(cand) else None

def main():
    ap = argparse.ArgumentParser(description="Plot paired turbostat + powersample session")
    ap.add_argument("turbostat", help="turbostat-<stem>.log")
    ap.add_argument("ndjson", nargs="?", help="powersample-<stem>.ndjson (inferred if omitted)")
    ap.add_argument("--output", "-o", default="power_session.png")
    ap.add_argument("--cores", action="store_true", help="also emit per-core heatmaps")
    args = ap.parse_args()

    nd = args.ndjson or infer_ndjson(args.turbostat)
    print(f"turbostat: {args.turbostat}")
    print(f"ndjson:    {nd or '(none found)'}")

    summary, per_core = parse_turbostat(args.turbostat)
    samples, configs, events = parse_ndjson(nd)
    print(f"  {len(summary)} intervals, {len(per_core)} cores, "
          f"{len(samples)} samples, {len(configs)} config rows, {len(events)} events")

    plot_session(summary, samples, configs, events, args.output,
                 title=f"  ({os.path.basename(args.turbostat)})")

    if args.cores:
        stem = args.output.rsplit(".", 1)[0]
        plot_heatmap(per_core, f"{stem}_busy_heatmap.png", "Busy%", "Per-Core Busy %")
        plot_heatmap(per_core, f"{stem}_temp_heatmap.png", "CoreTmp", "Per-Core Temp")

if __name__ == "__main__":
    main()
