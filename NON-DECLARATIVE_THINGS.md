# Ad-hoc / Non-Declarative Configuration

Things that aren't tracked in the NixOS config and need to be redone manually on a fresh setup.

---

## Dolphin Emulator stuff
- ISO paths
- Controller config
- Gecko codes

## Files to copy over on new systems
- Folders in `~`: Desktop, Downloads, Documents, Videos, Images, Backups, Arduino, qmk_firmware
- Dotfiles in `~`: `.zsh_history`, `.ssh/` (keys), `.vim/`, `.platformio/`, `.notes.md`, `.arduino15/`
- `~/.mozilla/firefox/` — Firefox profiles
- `~/.config/`: Slippi Launcher, obs-studio, qBittorrent, PrusaSlicer, libvirt
- `~/.local/share/`: dolphin-emu, lutris, qBittorrent, nvim, prusa-slicer, vlc, Trash, syncthing, game saves
- VM image at `/var/lib/libvirt/images/win11.qcow2`

## Games
Steam manages all games that aren't in `~/Backups` (incl. save files), download as needed.

---

## Win11 VM (libvirt/QEMU)

### Re-setup procedure (on a new install)

1. Copy `win11.qcow2` to `/var/lib/libvirt/images/`
2. In virt-manager, create new VM → **Import existing disk image** → point to qcow2
   - Memory: 49152 MB, vCPUs: 6
   - OS: Windows 11, Firmware: UEFI
   - Check "Customize before install"
   - NIC: virtio
3. Add PCI Host Device `0000:01:00.0` (NVIDIA RTX PRO 1000) via Add Hardware
4. Start default network: `virsh -c qemu:///system net-autostart default`
5. Apply CPU pinning via `virsh -c qemu:///system edit win11` (see below)
6. Connect via RDP

### VM Definition
The VM XML lives outside NixOS config at `/var/lib/libvirt/qemu/win11.xml`.
To back up after changes:
```bash
virsh -c qemu:///system dumpxml win11 > /etc/nixos/dotfiles/vms/win11.xml
```
To restore on a new machine:
```bash
virsh define /etc/nixos/dotfiles/vms/win11.xml
```

### Disk image
Located at `/var/lib/libvirt/images/win11.qcow2`. Back up manually — this is the full Windows install.

### CPU Pinning
Applied via `virsh -c qemu:///system edit win11`. VM gets CPUs 0,1 (P-core) + 6,7,8,9 (Skymont E-core). Host keeps CPUs 2,3,4,5 (P-core) + 10-13 (Skymont) + 14,15 (Crestmont LP).

```xml
<cputune>
  <vcpupin vcpu='0' cpuset='0'/>
  <vcpupin vcpu='1' cpuset='1'/>
  <vcpupin vcpu='2' cpuset='6'/>
  <vcpupin vcpu='3' cpuset='7'/>
  <vcpupin vcpu='4' cpuset='8'/>
  <vcpupin vcpu='5' cpuset='9'/>
</cputune>
```

### Windows Firewall Rules (applied manually in Win11 admin cmd)
```cmd
netsh advfirewall firewall set rule group="Remote Desktop" new enable=Yes
netsh advfirewall firewall add rule name="ICMP Allow" protocol=icmpv4:8,any dir=in action=allow
```

### VirtIO Network Driver
Installed manually from virtio-win ISO (`NetKVM\w11\amd64`) via Device Manager during initial setup.

### NVIDIA Driver
Installed manually in Win11. Version 595.97. GPU passed through via vfio-pci (PCI `0000:01:00.0`, ID `10de:2db8`).

### NX / AWS VPN
- AWS VPN Client minimizes to system tray
- Connect to VPN before launching NX to reach floating license server

### RDP Access
Connect from host:
```bash
xfreerdp /v:192.168.122.XX /u:odinn /dynamic-resolution
```
Note: VM IP may change. Check with:
```bash
virsh -c qemu:///system domifaddr win11
```
