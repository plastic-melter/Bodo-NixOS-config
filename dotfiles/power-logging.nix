{ config, lib, pkgs, ... }:

let
  logDir = "/var/log/turbostat";
  retentionDays = "14d";

  # turbostat columns to hide (per-core stays; drop noise). Empty = full default set.
  # To shrink logs, add e.g. "--Summary" below to drop per-core rows entirely.
  turbostat = pkgs.linuxPackages.turbostat;

  # Per-boot filename stem: <UTC-timestamp>-<boot_id[:8]>
  stem = pkgs.writeShellScript "power-log-stem" ''
    ts=$(${pkgs.coreutils}/bin/date -u +%Y%m%dT%H%M%SZ)
    bid=$(${pkgs.coreutils}/bin/cut -c1-8 /proc/sys/kernel/random/boot_id)
    printf '%s-%s' "$ts" "$bid"
  '';

  sampler = ./scripts/powersample.py;   # the script from this repo
in
{
  # --- retention: prune anything older than N days, no logrotate needed --------
  systemd.tmpfiles.rules = [
    # 2775 = group-writable + setgid so both root (turbostat) and the user
    # sampler can create files here, all owned by group `users`. Trailing age
    # arg makes systemd-tmpfiles prune files older than it on the timer.
    "d ${logDir} 2775 root users ${retentionDays}"
  ];

  # --- root service: turbostat, per-boot file, epoch timestamp column ----------
  systemd.services.turbostat = {
    description = "turbostat background sampler (per-boot log)";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "always";
      RestartSec = 2;
      User = "root";
      Nice = 5;
      IOSchedulingClass = "idle";
      ExecStart = pkgs.writeShellScript "turbostat-start" ''
        f="${logDir}/turbostat-$(${stem}).log"
        exec ${pkgs.coreutils}/bin/stdbuf -oL \
          ${turbostat}/bin/turbostat \
            --quiet --interval 1 \
            --enable Time_Of_Day_Seconds \
            >> "$f" 2>&1
      '';
    };
  };

  # --- one-shot boot header: static context the sampler must NOT poll ----------
  systemd.services.power-meta = {
    description = "dump static power context once per boot";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    serviceConfig.ExecStart = pkgs.writeShellScript "power-meta" ''
      set -u
      f="${logDir}/meta-$(${stem}).txt"
      exec >> "$f" 2>&1
      echo "# boot $(${pkgs.coreutils}/bin/date -u +%FT%TZ)  boot_id=$(cat /proc/sys/kernel/random/boot_id)"
      echo "## charge thresholds"
      for b in /sys/class/power_supply/BAT*; do
        echo "$b start=$(cat $b/charge_control_start_threshold 2>/dev/null) end=$(cat $b/charge_control_end_threshold 2>/dev/null)"
      done
      echo "## ASPM policy"; cat /sys/module/pcie_aspm/parameters/policy 2>/dev/null
      echo "## SATA LPM"
      for h in /sys/class/scsi_host/host*/link_power_management_policy; do echo "$h $(cat $h)"; done
      echo "## cpuidle disable flags (cpu0)"
      for st in /sys/devices/system/cpu/cpu0/cpuidle/state*; do
        echo "$(basename $st) $(cat $st/name) disable=$(cat $st/disable)"
      done
      echo "## power daemons"
      for d in thermald tlp power-profiles-daemon auto-cpufreq tuned; do
        echo "$d $(${pkgs.systemd}/bin/systemctl is-active $d 2>/dev/null)"
      done
    '';
  };

  # --- user service: NDJSON sampler, inside graphical session (hyprctl access) --
  systemd.user.services.powersample = {
    description = "NDJSON power sampler (battery/AC/amdgpu/knobs)";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Restart = "always";
      RestartSec = 2;
      Nice = 5;
      # graphical-session.target must carry the session env (XDG_RUNTIME_DIR,
      # HYPRLAND_INSTANCE_SIGNATURE) for refresh-rate reads — see note below.
      ExecStart = pkgs.writeShellScript "powersample-start" ''
        f="${logDir}/powersample-$(${stem}).ndjson"
        exec ${pkgs.python3}/bin/python3 ${sampler} "$f"
      '';
    };
  };
}
