#!/usr/bin/env python3
"""
powersample.py — quiet NDJSON power sampler (companion to turbostat).

Runs as a *user* systemd service inside the graphical session so it can read the
Hyprland IPC socket for refresh rate. Only touches world-readable sysfs, so no
root. turbostat (root service) covers pkg/core/gfx watts, C-states, MHz, IPC,
per-core; this covers everything turbostat can't: battery, AC, amdgpu eGPU, and
the current tunable knobs. Merge the two streams on the epoch timestamp `t`.

Two rate tiers:
  fast  (every tick)  : amdgpu power/busy/temp/fan + battery power_now
  config(on change)   : AC, platform_profile, EPP, governor, no_turbo,
                        refresh, amdgpu perf/sclk/mclk, battery status/capacity

--fast SEC raises only the fast tick (default 1.0). Battery + config stay ~1 Hz
regardless (the EC gauge can't go faster and config only fires on deltas).

Line types:
  {"t":<epoch>,"type":"sample", ...fast fields...}
  {"t":<epoch>,"type":"config", ...all config fields...}   # start + on change
  {"t":<epoch>,"type":"event","event":"egpu","present":bool}
"""

import os, sys, glob, json, time, socket, argparse

# --------------------------------------------------------------------------- io
def r(path):
    try:
        with open(path) as f:
            return f.read().strip()
    except Exception:
        return None

def ri(path):
    v = r(path)
    try:
        return int(v)
    except (TypeError, ValueError):
        return None

def first(paths):
    for p in paths:
        if os.path.exists(p):
            return p
    return None

# ------------------------------------------------------------------ discovery
def find_amdgpu():
    """Return (device_dir, hwmon_dir) for the amdgpu card, or (None, None)."""
    for cd in sorted(glob.glob("/sys/class/drm/card[0-9]*")):
        link = os.path.join(cd, "device", "driver")
        if os.path.islink(link) and os.path.basename(os.readlink(link)) == "amdgpu":
            dev = os.path.join(cd, "device")
            hw = first(sorted(glob.glob(os.path.join(dev, "hwmon", "hwmon*"))))
            return dev, hw
    return None, None

def cpu0(leaf):
    return f"/sys/devices/system/cpu/cpu0/cpufreq/{leaf}"

def ac_online():
    for s in (glob.glob("/sys/class/power_supply/AC*/online") +
              glob.glob("/sys/class/power_supply/ADP*/online")):
        v = r(s)
        if v is not None:
            return int(v == "1")
    return None

def bat_dir():
    b = sorted(glob.glob("/sys/class/power_supply/BAT*"))
    return b[0] if b else None

def dpm_current(path):
    """Parse a pp_dpm_* table, return the freq token of the '*'-marked line."""
    txt = r(path)
    if not txt:
        return None
    for ln in txt.splitlines():
        if ln.rstrip().endswith("*"):
            toks = ln.split()
            for tk in toks:
                if "hz" in tk.lower():
                    return tk
    return None

# ------------------------------------------------------------- refresh (hypr)
def refresh_hz():
    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    rt = os.environ.get("XDG_RUNTIME_DIR")
    if not sig or not rt:
        return None
    sock_path = os.path.join(rt, "hypr", sig, ".socket.sock")
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.settimeout(0.25)
            s.connect(sock_path)
            s.sendall(b"j/monitors")
            buf = b""
            while True:
                chunk = s.recv(65536)
                if not chunk:
                    break
                buf += chunk
        mons = json.loads(buf)
        foc = next((m for m in mons if m.get("focused")), mons[0] if mons else None)
        return round(foc["refreshRate"], 2) if foc else None
    except Exception:
        return None

# ----------------------------------------------------------------- samplers
def read_amdgpu(dev, hw):
    if not dev or not os.path.isdir(dev):
        return None
    d = {}
    busy = ri(os.path.join(dev, "gpu_busy_percent"))
    if busy is not None:
        d["amd_busy"] = busy
    if hw and os.path.isdir(hw):
        p = ri(os.path.join(hw, "power1_average"))
        if p is not None:
            d["amd_power_w"] = round(p / 1e6, 2)
        for k, fn in (("amd_temp_edge", "temp1_input"),
                      ("amd_temp_junction", "temp2_input")):
            t = ri(os.path.join(hw, fn))
            if t is not None:
                d[k] = round(t / 1000, 1)
        fan = ri(os.path.join(hw, "fan1_input"))
        if fan is not None:
            d["amd_fan_rpm"] = fan
    return d or None

def read_bat_power(bd):
    if not bd:
        return None
    pw = ri(os.path.join(bd, "power_now"))
    if pw is not None:
        return round(pw / 1e6, 2)
    cur = ri(os.path.join(bd, "current_now"))
    vol = ri(os.path.join(bd, "voltage_now"))
    if cur and vol:
        return round(cur * vol / 1e12, 2)
    return None

def read_config(dev, bd):
    c = {
        "ac": ac_online(),
        "platform_profile": r("/sys/firmware/acpi/platform_profile"),
        "epp": r(cpu0("energy_performance_preference")),
        "governor": r(cpu0("scaling_governor")),
        "no_turbo": r("/sys/devices/system/cpu/intel_pstate/no_turbo"),
        "refresh_hz": refresh_hz(),
    }
    if bd:
        c["bat_status"] = r(os.path.join(bd, "status"))
        c["bat_capacity"] = ri(os.path.join(bd, "capacity"))
    if dev and os.path.isdir(dev):
        c["amd_perf"] = r(os.path.join(dev, "power_dpm_force_performance_level"))
        c["amd_sclk"] = dpm_current(os.path.join(dev, "pp_dpm_sclk"))
        c["amd_mclk"] = dpm_current(os.path.join(dev, "pp_dpm_mclk"))
    return c

# --------------------------------------------------------------------- main
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("logfile", help="output NDJSON path")
    ap.add_argument("--fast", type=float, default=1.0,
                    help="fast-tier interval sec (amdgpu). default 1.0")
    ap.add_argument("--flush", type=float, default=10.0,
                    help="flush buffer every N sec (default 10)")
    args = ap.parse_args()

    interval = max(0.05, args.fast)
    slow_every = max(1, round(1.0 / interval))   # ~1 Hz for battery + config

    dev, hw = find_amdgpu()
    bd = bat_dir()
    prev_cfg = None
    prev_egpu = dev is not None

    out = open(args.logfile, "a", buffering=1)
    buf = []
    last_flush = time.monotonic()

    def emit(obj):
        buf.append(json.dumps(obj, separators=(",", ":")))

    def flush():
        if buf:
            out.write("\n".join(buf) + "\n")
            out.flush()
            buf.clear()

    tick = 0
    next_t = time.monotonic()
    try:
        while True:
            now = time.time()

            # re-detect eGPU on the slow cadence (hotplug)
            if tick % slow_every == 0 and (dev is None or not os.path.isdir(dev)):
                dev, hw = find_amdgpu()
            present = dev is not None and os.path.isdir(dev)
            if present != prev_egpu:
                emit({"t": round(now, 3), "type": "event",
                      "event": "egpu", "present": present})
                prev_egpu = present
                if not present:
                    dev, hw = None, None

            # fast tier
            samp = {"t": round(now, 3), "type": "sample"}
            amd = read_amdgpu(dev, hw)
            if amd:
                samp.update(amd)
            # battery power at ~1 Hz only
            if tick % slow_every == 0:
                bp = read_bat_power(bd)
                if bp is not None:
                    samp["bat_power_w"] = bp
            if len(samp) > 2:
                emit(samp)

            # config tier (on change) at ~1 Hz
            if tick % slow_every == 0:
                cfg = read_config(dev if present else None, bd)
                if cfg != prev_cfg:
                    line = {"t": round(now, 3), "type": "config"}
                    line.update(cfg)
                    emit(line)
                    prev_cfg = cfg

            if time.monotonic() - last_flush >= args.flush:
                flush()
                last_flush = time.monotonic()

            tick += 1
            next_t += interval
            sleep = next_t - time.monotonic()
            if sleep > 0:
                time.sleep(sleep)
            else:
                next_t = time.monotonic()   # fell behind; resync
    except KeyboardInterrupt:
        pass
    finally:
        flush()
        out.close()

if __name__ == "__main__":
    main()
