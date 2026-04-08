# NOTE: includes comments showing what changed from X13G3->P14sG6 migration
# "nixos-generate-config" will overwrite this

{ config, lib, pkgs, modulesPath, ... }:
{
  imports =
    [ # NEW: Intel NPU support module (Arrow Lake-P has a built-in NPU, absent on X13G3's AMD)
      (modulesPath + "/hardware/cpu/intel-npu.nix")
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  # usb_storage and sd_mod retained from X13G3 config (dropped by generate-config, added back manually)
  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];

  # CHANGED: kvm-amd -> kvm-intel (Intel VMX instead of AMD SVM)
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # Unchanged: same physical NVMe drive, LUKS UUID carries over
  fileSystems."/" =
    { device = "/dev/mapper/luks-ad157f4a-b51d-4760-a774-4ac86322f9c2";
      fsType = "ext4";
    };

  # Unchanged: same drive, same LUKS device
  boot.initrd.luks.devices."luks-ad157f4a-b51d-4760-a774-4ac86322f9c2".device =
    "/dev/disk/by-uuid/ad157f4a-b51d-4760-a774-4ac86322f9c2";

  # Unchanged: same EFI partition
  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/F6C2-E304";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # NEW: Enable Intel NPU (neural processing unit on Arrow Lake-P, not present on Ryzen 6850U)
  hardware.cpu.intel.npu.enable = true;

  # CHANGED: amd.updateMicrocode -> intel.updateMicrocode
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
