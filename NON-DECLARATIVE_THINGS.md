# Ad-hoc / Non-Declarative Configuration

Things that aren't tracked in the NixOS config and need to be redone manually on a fresh setup.

---

## Win11 VM (libvirt/QEMU)

### VM Definition
The VM XML lives outside NixOS config at `/var/lib/libvirt/qemu/win11.xml`.
To back up after changes:
```
virsh -c qemu:///system dumpxml win11 > /etc/nixos/dotfiles/vms/win11.xml
```
To restore on a new machine:
```
virsh define /etc/nixos/dotfiles/vms/win11.xml
```

### Disk image
Located at `/var/lib/libvirt/images/win11.qcow2`. Back up manually — this is the full Windows install.

### CPU Pinning
Applied via `virsh edit`. VM gets CPUs 0,1 (P-core) + 6,7,8,9 (Skymont E-core). Host keeps CPUs 2,3,4,5 (P-core) + 10-13 (Skymont) + 14,15 (Crestmont LP).

### Windows Firewall Rules (applied manually in Win11)
- RDP enabled: `netsh advfirewall firewall set rule group="Remote Desktop" new enable=Yes`
- ICMP allowed: `netsh advfirewall firewall add rule name="ICMP Allow" protocol=icmpv4:8,any dir=in action=allow`

### VirtIO Network Driver
Installed manually from virtio-win ISO (`NetKVM\w11\amd64`) via Device Manager during initial setup.

### NVIDIA Driver
Installed manually in Win11. Version 595.97. GPU passed through via vfio-pci (PCI 0000:01:00.0, `10de:2db8`).

### RDP Access
Connect from host:
```
xfreerdp /v:192.168.122.58 /u:odinn /dynamic-resolution
```
Note: VM IP may change. Check with `virsh -c qemu:///system domifaddr win11`.

---

## To Do
- [ ] Dynamic GPU bind/unbind hook script (for switching GPU between VM and host gaming)
- [ ] Install NX + AWS VPN client in VM
- [ ] Activate Windows (Win11 Pro key)
