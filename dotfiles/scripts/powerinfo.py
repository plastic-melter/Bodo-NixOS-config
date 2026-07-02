#!/usr/bin/env python3
"""
powerinfo - dump every power-relevant knob on this machine in human-readable form.

Targeted at a ThinkPad X210ai (Meteor Lake 185H iGPU + amdgpu eGPU), but everything
is presence-checked, so it degrades gracefully on any box / missing subsystem.

Most interesting reads (RAPL energy_uj, MSRs) are root-only:  doas python3 powerinfo.py
For package C-state residency + MSR cross-check you also need the msr module:
    doas modprobe msr

Flags:
    --interval SEC   sampling window for live watts / C-state residency (default 0.3)
    --no-color       plain output (also auto-disabled when stdout isn't a TTY)
"""

import os, sys, glob, time, struct, argparse, subprocess

# ----------------------------------------------------------------------------- helpers

def r(path):
    """Read a sysfs file, return stripped str or None on any failure."""
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

class Col:
    def __init__(self, on):
        def m(code): return (lambda s: f"\033[{code}m{s}\033[0m") if on else (lambda s: s)
        self.bold = m("1"); self.dim = m("2")
        self.red = m("31"); self.grn = m("32"); self.yel = m("33")
        self.blu = m("34"); self.cyn = m("36")

C = None  # set in main

def hdr(title):
    line = "\u2500" * max(3, 56 - len(title))
    print(f"\n{C.bold(C.cyn('\u25b8 ' + title))} {C.dim(line)}")

def kv(key, val, note=""):
    val = "\u2014" if val is None or val == "" else str(val)
    note = f"  {C.dim(note)}" if note else ""
    print(f"  {key:<26} {val}{note}")

def warn(msg):  print(f"  {C.yel('\u26a0 ' + msg)}")
def good(msg):  print(f"  {C.grn('\u2713 ' + msg)}")
def bad(msg):   print(f"  {C.red('\u2717 ' + msg)}")

# unit formatters
def W(uw):
    return None if uw is None else f"{uw/1e6:.2f} W"
def MHz_from_kHz(khz):
    return None if khz is None else f"{khz/1000:.0f} MHz"
def secs(us):
    if us is None: return None
    if us >= 1_000_000: return f"{us/1e6:.3f} s"
    if us >= 1000:      return f"{us/1000:.1f} ms"
    return f"{us} \u00b5s"
def degC(milli):
    return None if milli is None else f"{milli/1000:.1f} \u00b0C"

# ----------------------------------------------------------------------------- MSR

def read_msr(msr, cpu=0):
    try:
        with open(f"/dev/cpu/{cpu}/msr", "rb") as f:
            f.seek(msr)
            return struct.unpack("<Q", f.read(8))[0]
    except Exception:
        return None

MSR_RAPL_POWER_UNIT = 0x606
MSR_PKG_POWER_LIMIT = 0x610
MSR_TSC             = 0x10
PKG_CSTATE_MSRS = {  # name -> msr
    "pc2": 0x60D, "pc3": 0x3F8, "pc6": 0x3F9,
    "pc7": 0x3FA, "pc8": 0x630, "pc9": 0x631, "pc10": 0x632,
}

# ----------------------------------------------------------------------------- sampling
# We take two snapshots <interval> apart so live watts (RAPL energy deltas) and
# package C-state residency (MSR deltas vs TSC) can be computed over one window.

def rapl_domains():
    out = []
    for d in sorted(glob.glob("/sys/class/powercap/intel-rapl:*")):
        if ":" in os.path.basename(d):
            out.append(d)
    return out

def snapshot(domains, want_msr):
    snap = {"t": time.monotonic(), "energy": {}, "tsc": None, "cstate": {}}
    for d in domains:
        snap["energy"][d] = ri(os.path.join(d, "energy_uj"))
    if want_msr:
        snap["tsc"] = read_msr(MSR_TSC)
        for name, msr in PKG_CSTATE_MSRS.items():
            snap["cstate"][name] = read_msr(msr)
    return snap

def rapl_live_watts(d, s0, s1):
    e0, e1 = s0["energy"].get(d), s1["energy"].get(d)
    if e0 is None or e1 is None:
        return None
    de = e1 - e0
    if de < 0:  # wrap
        mx = ri(os.path.join(d, "max_energy_range_uj"))
        if mx: de += mx
    dt = s1["t"] - s0["t"]
    return de / 1e6 / dt if dt > 0 else None

# ----------------------------------------------------------------------------- sections

def sec_rapl(domains, s0, s1):
    hdr("RAPL power limits & live draw")
    if not domains:
        warn("no intel-rapl powercap domains (need CONFIG_INTEL_RAPL + root for energy_uj)")
        return
    # MSR power unit for cross-check decode
    runit = read_msr(MSR_RAPL_POWER_UNIT)
    p_unit = (1.0 / (1 << (runit & 0xF))) if runit else None
    msr_pl = read_msr(MSR_PKG_POWER_LIMIT)
    for d in domains:
        name = r(os.path.join(d, "name")) or os.path.basename(d)
        live = rapl_live_watts(d, s0, s1)
        print(f"  {C.bold(name)}  ({os.path.basename(d)})")
        kv("    live draw", f"{live:.2f} W" if live is not None else None,
           "from energy_uj delta")
        # constraints
        for i in range(0, 3):
            base = os.path.join(d, f"constraint_{i}")
            lim = ri(base + "_power_limit_uw")
            if lim is None:
                continue
            cname = r(base + "_name") or f"constraint{i}"
            tw = ri(base + "_time_window_us")
            kv(f"    {cname}", W(lim),
               f"tau={secs(tw)}" if tw is not None else "")
        en = r(os.path.join(d, "enabled"))
        kv("    enabled", en)
        mx = ri(os.path.join(d, "max_power_uw"))
        if mx: kv("    max_power", W(mx))
        # cross-check package domain against MSR 0x610 (reveals EC/MMIO override)
        if name == "package-0" and msr_pl and p_unit:
            pl1_msr = (msr_pl & 0x7FFF) * p_unit
            pl2_msr = ((msr_pl >> 32) & 0x7FFF) * p_unit
            pl1_lock = bool(msr_pl & (1 << 31))
            sysfs_pl1 = ri(os.path.join(d, "constraint_0_power_limit_uw"))
            kv("    MSR 0x610 PL1", f"{pl1_msr:.1f} W",
               "LOCKED" if pl1_lock else "")
            kv("    MSR 0x610 PL2", f"{pl2_msr:.1f} W")
            if sysfs_pl1 is not None and abs(sysfs_pl1/1e6 - pl1_msr) > 0.5:
                warn(f"sysfs PL1 ({sysfs_pl1/1e6:.1f} W) != MSR PL1 ({pl1_msr:.1f} W) "
                     "\u2014 EC/MMIO enforcing a different limit")

def sec_cstate_residency(s0, s1):
    hdr("Package C-state residency (idle depth)")
    if s0["tsc"] is None:
        warn("MSR unreadable \u2014 run as root and `doas modprobe msr` for this section")
        return
    dtsc = s1["tsc"] - s0["tsc"]
    if dtsc <= 0:
        warn("TSC delta non-positive; skipping")
        return
    any_shown = False
    for name in PKG_CSTATE_MSRS:
        a, b = s0["cstate"].get(name), s1["cstate"].get(name)
        if a is None or b is None:
            continue
        pct = (b - a) / dtsc * 100.0
        any_shown = True
        label = name.upper()
        mark = ""
        if name in ("pc8", "pc10") and pct > 40:
            mark = C.grn("deep idle ok")
        kv(f"  {label}", f"{pct:5.1f} %", mark)
    if not any_shown:
        warn("no package C-state MSRs readable on this CPU")
    else:
        print(C.dim("    (high PC8/PC10 = good idle power; stuck low often = a "
                    "PCIe/USB/eGPU device blocking deep idle)"))

def sec_cpufreq():
    hdr("cpufreq / HWP (intel_pstate)")
    def _cpunum(cpufreq_path):
        # parent dir is "cpuN"; basename-of-dirname avoids splitting on "cpufreq"
        return int(os.path.basename(os.path.dirname(cpufreq_path))[3:])
    cpus = sorted(glob.glob("/sys/devices/system/cpu/cpu[0-9]*/cpufreq"),
                  key=_cpunum)
    if not cpus:
        warn("no cpufreq sysfs")
    else:
        drv = r(os.path.join(cpus[0], "scaling_driver"))
        kv("driver", drv)
        print(f"  {C.dim('CPU   gov            EPP                 cur       min       max')}")
        for cd in cpus:
            n = os.path.basename(os.path.dirname(cd))[3:]
            gov = r(os.path.join(cd, "scaling_governor")) or "-"
            epp = r(os.path.join(cd, "energy_performance_preference")) or "-"
            cur = MHz_from_kHz(ri(os.path.join(cd, "scaling_cur_freq"))) or "-"
            lo  = MHz_from_kHz(ri(os.path.join(cd, "scaling_min_freq"))) or "-"
            hi  = MHz_from_kHz(ri(os.path.join(cd, "scaling_max_freq"))) or "-"
            print(f"  {n:<4}  {gov:<13}  {epp:<18}  {cur:<8}  {lo:<8}  {hi:<8}")
    # intel_pstate globals
    g = "/sys/devices/system/cpu/intel_pstate"
    if os.path.isdir(g):
        print()
        for key in ("status", "no_turbo", "turbo_pct", "max_perf_pct",
                    "min_perf_pct", "hwp_dynamic_boost"):
            v = r(os.path.join(g, key))
            if v is not None:
                note = ""
                if key == "no_turbo":
                    note = "turbo DISABLED" if v == "1" else "turbo on"
                kv(f"intel_pstate/{key}", v, note)

def sec_platform_profile():
    hdr("Platform profile (ACPI / EC)")
    cur = r("/sys/firmware/acpi/platform_profile")
    ch  = r("/sys/firmware/acpi/platform_profile_choices")
    if cur is None:
        warn("no platform_profile (EC may not expose it)")
        return
    kv("current", C.bold(cur))
    kv("choices", ch)
    print(C.dim("    (this often drives the EC's RAPL enforcement \u2014 if RAPL keeps "
                "clamping back, watch this)"))

def sec_idle_states():
    hdr("CPU idle states (cpu0)")
    states = sorted(glob.glob("/sys/devices/system/cpu/cpu0/cpuidle/state[0-9]*"))
    if not states:
        warn("no cpuidle states")
        return
    print(f"  {C.dim('state  name        disabled   usage          residency')}")
    for st in states:
        nm   = r(os.path.join(st, "name")) or "?"
        dis  = r(os.path.join(st, "disable"))
        dis_s = "yes" if dis == "1" else "no"
        usage = r(os.path.join(st, "usage")) or "-"
        time_us = ri(os.path.join(st, "time"))
        res = f"{time_us/1e6:.1f} s" if time_us is not None else "-"
        idx = os.path.basename(st).replace("state", "")
        print(f"  {idx:<5}  {nm:<10}  {dis_s:<9}  {usage:<13}  {res}")

def sec_pcie_aspm():
    hdr("PCIe ASPM & runtime PM")
    pol = r("/sys/module/pcie_aspm/parameters/policy")
    kv("ASPM policy", pol)
    devs = glob.glob("/sys/bus/pci/devices/*/power/control")
    auto = on = 0
    blockers = []
    for c in devs:
        v = r(c)
        if v == "auto": auto += 1
        elif v == "on":
            on += 1
            dev = c.rsplit("/power/", 1)[0]
            addr = os.path.basename(dev)
            drv = None
            link = os.path.join(dev, "driver")
            if os.path.islink(link):
                drv = os.path.basename(os.readlink(link))
            spd = r(os.path.join(dev, "current_link_speed"))
            blockers.append((addr, drv or "-", spd or "-"))
    kv("runtime PM", f"{auto} auto / {on} on (forced active)")
    if blockers:
        print(C.dim("    devices NOT autosuspending (potential deep-idle blockers):"))
        for addr, drv, spd in blockers[:20]:
            print(f"      {addr}  {C.dim(drv):<28}  {spd}")

def sec_sata_usb():
    hdr("SATA / USB link power")
    sata = glob.glob("/sys/class/scsi_host/host*/link_power_management_policy")
    if sata:
        vals = {}
        for s in sata:
            v = r(s) or "?"
            vals[v] = vals.get(v, 0) + 1
        kv("SATA LPM", ", ".join(f"{k}\u00d7{n}" for k, n in vals.items()))
    usb = glob.glob("/sys/bus/usb/devices/*/power/control")
    if usb:
        auto = sum(1 for u in usb if r(u) == "auto")
        kv("USB autosuspend", f"{auto}/{len(usb)} auto")

def detect_drm():
    cards = {}
    for cd in sorted(glob.glob("/sys/class/drm/card[0-9]*")):
        if "-" in os.path.basename(cd):  # skip connectors card0-eDP-1
            continue
        drv = None
        link = os.path.join(cd, "device", "driver")
        if os.path.islink(link):
            drv = os.path.basename(os.readlink(link))
        cards[cd] = drv
    return cards

def sec_igpu(cards):
    hdr("Intel iGPU (i915 / xe)")
    found = False
    for cd, drv in cards.items():
        if drv not in ("i915", "xe"):
            continue
        found = True
        base = os.path.basename(cd)
        kv("device", f"{base}  ({drv})")
        if drv == "i915":
            for label, fn in (("min", "gt_min_freq_mhz"), ("cur", "gt_cur_freq_mhz"),
                              ("act", "gt_act_freq_mhz"), ("max", "gt_max_freq_mhz"),
                              ("boost", "gt_boost_freq_mhz")):
                v = r(os.path.join(cd, fn))
                if v is not None:
                    kv(f"  freq {label}", f"{v} MHz")
            rc6 = r(os.path.join(cd, "power", "rc6_enable"))
            if rc6 is not None: kv("  RC6", rc6)
        else:  # xe
            g = first(glob.glob(os.path.join(cd, "device/tile0/gt0/freq0")))
            if g:
                for label, fn in (("min", "min_freq"), ("cur", "cur_freq"),
                                  ("act", "act_freq"), ("max", "max_freq")):
                    v = r(os.path.join(g, fn))
                    if v is not None:
                        kv(f"  freq {label}", f"{v} MHz")
        # live iGPU watts come from RAPL pp1 subdomain (shown in RAPL section)
    if not found:
        warn("no i915/xe GPU found")

def sec_amdgpu(cards):
    hdr("AMD eGPU (amdgpu)")
    found = False
    for cd, drv in cards.items():
        if drv != "amdgpu":
            continue
        found = True
        dev = os.path.join(cd, "device")
        base = os.path.basename(cd)
        kv("device", f"{base}  ({drv})")
        kv("  perf level",
           r(os.path.join(dev, "power_dpm_force_performance_level")))
        busy = r(os.path.join(dev, "gpu_busy_percent"))
        if busy is not None: kv("  GPU busy", f"{busy} %")
        # current sclk/mclk (line marked with *)
        for label, fn in (("sclk", "pp_dpm_sclk"), ("mclk", "pp_dpm_mclk")):
            txt = r(os.path.join(dev, fn))
            if txt:
                cur = next((ln for ln in txt.splitlines() if ln.endswith("*")), None)
                kv(f"  {label} (current)", cur.strip() if cur else txt.splitlines()[-1])
        # hwmon: power, temp, fan
        for hw in glob.glob(os.path.join(dev, "hwmon", "hwmon*")):
            avg = ri(os.path.join(hw, "power1_average"))
            cap = ri(os.path.join(hw, "power1_cap"))
            capmax = ri(os.path.join(hw, "power1_cap_max"))
            if avg is not None: kv("  power draw", W(avg))
            if cap is not None:
                kv("  power cap", W(cap),
                   f"max {W(capmax)}" if capmax else "")
            t = ri(os.path.join(hw, "temp1_input"))
            if t is not None: kv("  edge temp", degC(t))
            tj = ri(os.path.join(hw, "temp2_input"))
            if tj is not None: kv("  junction temp", degC(tj))
            fan = ri(os.path.join(hw, "fan1_input"))
            if fan is not None: kv("  fan", f"{fan} RPM")
    if not found:
        warn("no amdgpu device (eGPU unplugged or vfio-bound?)")

def sec_battery():
    hdr("Battery")
    bats = sorted(glob.glob("/sys/class/power_supply/BAT*"))
    if not bats:
        warn("no battery")
        return
    for b in bats:
        name = os.path.basename(b)
        kv(name, r(os.path.join(b, "status")))
        cap = r(os.path.join(b, "capacity"))
        if cap is not None: kv("  charge", f"{cap} %")
        st = ri(os.path.join(b, "charge_control_start_threshold"))
        en = ri(os.path.join(b, "charge_control_end_threshold"))
        if en is not None:
            kv("  charge thresholds", f"{st if st is not None else '?'} \u2013 {en} %")
        pw = ri(os.path.join(b, "power_now"))
        if pw is not None:
            kv("  live draw", W(pw))
        else:
            cur = ri(os.path.join(b, "current_now"))
            vol = ri(os.path.join(b, "voltage_now"))
            if cur and vol:
                kv("  live draw", f"{cur*vol/1e12:.2f} W", "I\u00d7V")

def sec_daemons():
    hdr("Power daemons (conflict check)")
    candidates = ["thermald", "tlp", "power-profiles-daemon",
                  "auto-cpufreq", "tuned"]
    active = []
    for svc in candidates:
        try:
            out = subprocess.run(["systemctl", "is-active", svc],
                                  capture_output=True, text=True, timeout=3)
            state = out.stdout.strip()
        except Exception:
            state = "?"
        if state == "active":
            active.append(svc)
        kv(svc, state, "ACTIVE" if state == "active" else "")
    profile_daemons = {"tlp", "power-profiles-daemon", "auto-cpufreq", "tuned"}
    clash = profile_daemons & set(active)
    if len(clash) > 1:
        bad(f"multiple power-profile daemons active: {', '.join(sorted(clash))} "
            "\u2014 they fight each other")
    elif clash:
        good(f"single power-profile daemon: {next(iter(clash))}")

# ----------------------------------------------------------------------------- main

def main():
    global C
    ap = argparse.ArgumentParser(description="Human-readable power-state inspector")
    ap.add_argument("--interval", type=float, default=0.3,
                    help="sampling window (s) for live watts / C-state residency")
    ap.add_argument("--no-color", action="store_true")
    args = ap.parse_args()

    C = Col(sys.stdout.isatty() and not args.no_color)

    is_root = (os.geteuid() == 0)
    want_msr = is_root and os.path.exists("/dev/cpu/0/msr")

    print(C.bold("Power inspector") + C.dim(f"  \u2014 {time.strftime('%Y-%m-%d %H:%M:%S')}"
          f"  interval={args.interval}s  {'root' if is_root else 'NON-root'}"))
    if not is_root:
        warn("not running as root \u2014 RAPL energy_uj and MSR sections will be blank. "
             "Re-run with: doas python3 powerinfo.py")
    if is_root and not want_msr:
        warn("/dev/cpu/0/msr missing \u2014 `doas modprobe msr` to enable MSR cross-check "
             "& package C-state residency")

    domains = rapl_domains()
    s0 = snapshot(domains, want_msr)
    time.sleep(args.interval)
    s1 = snapshot(domains, want_msr)

    cards = detect_drm()

    sec_rapl(domains, s0, s1)
    sec_cstate_residency(s0, s1)
    sec_cpufreq()
    sec_platform_profile()
    sec_idle_states()
    sec_pcie_aspm()
    sec_sata_usb()
    sec_igpu(cards)
    sec_amdgpu(cards)
    sec_battery()
    sec_daemons()
    print()

if __name__ == "__main__":
    main()
