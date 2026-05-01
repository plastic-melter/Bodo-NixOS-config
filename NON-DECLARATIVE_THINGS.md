# Ad-hoc / Non-Declarative Configuration

Things that aren't tracked in the NixOS config and need to be redone manually on a fresh setup.

---

## Files to copy over on new systems
- Folders in `~`: Desktop, Downloads, Documents, Videos, Images, Backups, Arduino, qmk_firmware
- Dotfiles in `~`: `.zsh_history`, `.ssh/` (keys), `.vim/`, `.platformio/`, `.notes.md`, `.arduino15/`
- `~/.mozilla/firefox/` — Firefox profiles
- `~/.config/`: Slippi Launcher, obs-studio, qBittorrent, PrusaSlicer, libvirt
- `~/.local/share/`: dolphin-emu, lutris, qBittorrent, nvim, prusa-slicer, vlc, Trash, syncthing, game saves
- VM image at `/var/lib/libvirt/images/win11.qcow2`

# Win11 VM Manual Setup Checklist

## Restore VM

- [ ] Copy `win11.qcow2` → `/var/lib/libvirt/images/`
- [ ] `virsh define /etc/nixos/dotfiles/vms/win11.xml`
- [ ] `virsh -c qemu:///system net-autostart default`
- [ ] `virsh -c qemu:///system net-start default`

## VM XML (`virsh edit win11`)

- [ ] Domain tag: `<domain type='kvm' xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>`
- [ ] CPU topology (1 socket, 6 cores, host-passthrough)
- [ ] CPU pinning: vCPUs 0,1 → host CPUs 0,1 (P-cores); vCPUs 2–5 → host CPUs 6,7,8,9 (E-cores)
- [ ] PCI passthrough: `0000:01:00.0` (RTX PRO 1000)
- [ ] kvmfr commandline block (`size=256M`, must match modprobe `static_size_mb=256`)
- [ ] `<memoryBacking><locked/></memoryBacking>`

## Verify

- [ ] `/dev/kvmfr0` exists, owned by joe:kvm, mode 660
- [ ] VM boots and shows 1 socket / 6 cores in Task Manager
- [ ] RTX PRO 1000 shows in Device Manager (no Code 43)

## Connect

```bash
# RDP
virsh -c qemu:///system domifaddr win11
xfreerdp /v:<IP> /u:odinn /dynamic-resolution /sound:sys:pulse /cert:ignore

# Looking Glass
looking-glass-client -f /dev/kvmfr0
```

## In Windows (if fresh qcow2)

- [ ] VirtIO drivers (NetKVM, vioinput) from virtio-win ISO
- [ ] NVIDIA driver 595.97
- [ ] AWS VPN Client
- [ ] Enable RDP: `netsh advfirewall firewall set rule group="Remote Desktop" new enable=Yes`
- [ ] Looking Glass B7 host binary (install as service)
- [ ] NX floating license config

