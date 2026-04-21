{ inputs, outputs, lib, config, pkgs, ... }: {

#############################################
############# P14sG6 CONFIG #################
#############################################

imports = [
  ./hardware-configuration.nix
];

# ============================================
# NIX, NIXPKGS, BOOT, SWAP
# ============================================

nix = {
  package = pkgs.nixVersions.latest;
  extraOptions = "experimental-features = nix-command flakes";
  settings = {
    trusted-users = [ "root" "joe" ];
    extra-substituters = [
      "https://cache.nixos.org"
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
    ];
    require-sigs = true;
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    accept-flake-config = true;
  };
};

nixpkgs.config = {
  allowUnfree = true;
  allowBroken = false;
  allowInsecure = false;
  qt5 = {
    enable = true;
    platformTheme = "qt5ct";
    style = {
      package = pkgs.kvantum-catppuccin;
      name = "kvantum";
    };
  };
};

boot = {
  loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 25;
      editor = false; # prevent root access by passing kernel param int=/bin/sh
      extraEntries = {
        "reboot.conf" = ''
          title Reboot
          efi /EFI/systemd/systemd-bootx64.efi
          options systemd.unit=reboot.target
        '';
        "poweroff.conf" = ''
          title Power Off
          efi /EFI/systemd/systemd-bootx64.efi
          options systemd.unit=poweroff.target
        '';
      };
    };
    efi.canTouchEfiVariables = true;
  };
  kernelModules = [ 
    "ntsync" # CoD WaW performance
    "uinput" # B0XX native USB
    "kvm-intel" # enables hardware-accelerated virtualization (VMX)
    "vfio" # VFIO subsystem: allows QEMU to access hardware directly
    "vfio_iommu_type1" # IOMMU backend for VFIO: handles addr trans/isolation between VM and hardware
    "vfio_pci" # allows binding specific PCI devices (ex: GPU) to VFIO driver isntead of host driver
  ];
  kernelPackages = pkgs.linuxPackages_xanmod_latest; # gaming
  kernelParams = [
    "mem_sleep_default=s2idle" # Arrow Lake has no S3, forces the only working sleep state
    "intel_iommu=on" # enable IOMMU for VFIO passthrough
    "iommu=pt" # passthrough mode, tells IOMMU to only translate for devices that need it (VMs)
    "pci_aspm=force" # ignore BIOS ASPM settings and enable ASPM on all PCIe links
    "nvme.noacpi=1" # let NVMe driver ignore ACPI PM hints and do PM itself
    "acpi.ec_no_wakeup=1" # prevent ACPI EC from waking things up during suspend
    "resume=UUID=ad157f4a-b51d-4760-a774-4ac86322f9c2" # hibernation: swap file
    "resume_offset=687831040" # hibernation: swap file
    "quiet" # surpress kernel boot messages: still readable via dmesg/journalctl
  ];
  resumeDevice = "/dev/mapper/luks-ad157f4a-b51d-4760-a774-4ac86322f9c2";
  kernel.sysctl."net.ipv4.ip_forward" = 1; # IP forwarding
  blacklistedKernelModules = [ "k10temp" ];
  extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom=US
    options vfio-pci ids=10de:2db8
  ''; 
  # Modprobe config explanation:
  #   - cfg...  = resolve JP/US IR flag mismatch
  #   - vfio... = let pvfio-pci kernel module claim RTX 1000 at boot
  #               This means the dGPU is only ever used for VM use
  #               All NixOS stuff, including gaming, uses the iGPU
};

swapDevices = [{
  device = "/var/lib/swapfile";
  size = 96*1024; # 96 GiB
}];

# ============================================
# NETWORKING, FWUPD
# ============================================

networking = {
  hostName = "P14sG6";
  useDHCP = false;
  networkmanager = {
    enable = true;
  };
};

systemd.network = {
  enable = true;
  wait-online.enable = false;
};

systemd.services = {
  dhcpcd.enable = false;
  NetworkManager-wait-online.enable = false;
  "systemd-networkd-wait-online".enable = false;
  vboxnet0.wantedBy = lib.mkForce [];
  libvirtd.stopIfChanged = false;
  fwupd = {
    wantedBy = lib.mkForce []; # Prevent boot slowdown
  };
  "fwupd-refresh" = {
    enable = lib.mkForce false;
  };
};

# ============================================
# LOCALIZATION
# ============================================

#time.timeZone = "America/Los_Angeles";
time.timeZone = "Asia/Tokyo";
i18n = {
  defaultLocale = "en_US.UTF-8";
  inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-gtk
      fcitx5-nord
    ];
    fcitx5.waylandFrontend = true;
  };
};

console = {
  font = "Lat2-Terminus16";
  keyMap = "jp106";
};

# ============================================
# HARDWARE
# ============================================

hardware = {
  nvidia = {
    modesetting.enable = true;
    open = true; # Required for Blackwell
    nvidiaSettings = true;
    powerManagement = {
      enable = true;
    };
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    prime = {
      sync.enable = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };
  graphics = {
    enable = true;
    enable32Bit = true; # for steam/wine/32-bit GL
      extraPackages = with pkgs; [ # drivers not auto-installed
      intel-media-driver  # iHD, for Gen 8+
      intel-vaapi-driver  # i965 fallback
    ];
  };
  cpu.intel.updateMicrocode = true;
  uinput.enable = true; # B0XX native USB
  bluetooth = {
    enable = true;
    hsphfpd.enable = false;
  };
  enableAllFirmware = true;
  trackpoint = {
    emulateWheel = true;
    speed = 97;
    sensitivity = 128;
  };
};

powerManagement = {
  cpuFreqGovernor = "ondemand";
  powertop.enable = true;
};

systemd.tmpfiles.rules = [
  "w /sys/module/pcie_aspm/parameters/policy - - - - powersupersave" 
  # ^ let devices negotiate low power state when idle: combos with kernelParam "pcie_aspm=force"
];

# ============================================
# SECURITY
# ============================================

security = {
  rtkit.enable = true;
  polkit = {
    enable = true;
#    extraConfig = ''
#      polkit.addRule(function(action, subject) {
#        if (action.id == "org.libvirt.unix.manage" &&
#        subject.isInGroup("libvirtd")) {
#          return polkit.Result.YES;
#        }
#      });
#    '';
  };
  sudo.enable = false;
  doas = {
    enable = true;
    wheelNeedsPassword = false;
    extraRules = [{
      groups = [ "doas" ];
      noPass = true;
      keepEnv = true;
      users = [ "joe" ];
    }];
  };
};

# ============================================
# SERVICES
# ============================================

# Display and Desktop
services = {
  xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];
    xkb = {
      layout = "jp";
      model = "jp106";
    };
    desktopManager.runXdgAutostartIfNone = true;
  };
  displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
      theme = "catppuccin-mocha-mauve";
      package = pkgs.kdePackages.sddm;
    };
    sessionPackages = [ pkgs.hyprland ];
    defaultSession = "hyprland";
    autoLogin = {
      enable = true;
      user = "joe";
    };
  };

  # Input
  libinput = {
    enable = true;
    touchpad = { 
      disableWhileTyping = true;
      naturalScrolling = true;
    };
    mouse = {
     accelProfile = "flat";
     accelSpeed = "0.0";
    };
  };

  # Audio
  pulseaudio.enable = false;
  pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
    jack.enable = true;
    wireplumber = {
      enable = true;
      configPackages = [
        (pkgs.writeTextDir "share/wireplumber/bluetooth.lua.d/51-bluez-config.lua" ''
          bluez_monitor.properties = {
            ["bluez5.enable-sbc-xq"] = true,
            ["bluez5.enable-msbc"] = true,
            ["bluez5.enable-hw-volume"] = true,
            ["bluez5.headset-roles"] = "[]"
          }
        '')
      ];
    };
  };

  # System Services
  udisks2.enable = true;
  fstrim.enable = true;
  fwupd.enable = true;
  printing = {
    enable = true;
    drivers = [ pkgs.brlaser ];
  };
  openssh.enable = true;
  blueman.enable = true;
  gvfs.enable = true; # required for Thunar to use .local/share/Trash

  syncthing = {
    enable = true;
    openDefaultPorts = true;
  };

  # Power Management / Hardware
  tlp = {
    enable = true;
    settings = { 
      START_CHARGE_THRESH_BAT0 = 90; 
      STOP_CHARGE_THRESH_BAT0 = 95; 
    };
  };
  thermald.enable = true;

  # USB Device Rules
  udev.extraRules = ''
    # B0XX native USB
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="045e", ATTRS{idProduct}=="02a1", MODE="0666", GROUP="input"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="045e", ATTRS{idProduct}=="02a1", MODE="0666", GROUP="input"
    # GCC adapter
    SUBSYSTEM=="usb", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="0337", MODE="0666"
    # Teensy 4.1
    ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04*", ENV{ID_MM_DEVICE_IGNORE}="1", ENV{ID_MM_PORT_IGNORE}="1"
    ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789a]*", ENV{MTP_NO_PROBE}="1"
    KERNEL=="ttyACM*", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04*", MODE:="0666"
    KERNEL=="hidraw*", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04*", MODE:="0666"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04*", MODE:="0666"
    # NXP boards (Teensy 4.x bootloader)
    KERNEL=="hidraw*", ATTRS{idVendor}=="1fc9", ATTRS{idProduct}=="013*", MODE:="0666"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="1fc9", ATTRS{idProduct}=="013*", MODE:="0666"
    # PicoScope
    SUBSYSTEM=="usb", ATTR{idVendor}=="0ce9", MODE="0666"
    # STM32 flashing in DFU mode
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", MODE="0666"
  '';
};

systemd.user.services = {
  # Check for firmware updates AFTER boot, sometimes saves a few seconds of boot time
  fwupd-check = {
    description = "Check for firmware updates";
    script = ''
      if ${pkgs.networkmanager}/bin/nmcli -t -f TYPE,STATE device | grep -q "wifi:connected"; then
        ${pkgs.libnotify}/bin/notify-send "Checking firmware updates..." -u low
        ${pkgs.fwupd}/bin/fwupdmgr refresh
        updates=$(${pkgs.fwupd}/bin/fwupdmgr get-updates 2>/dev/null)
        if [ -n "$updates" ]; then
          ${pkgs.libnotify}/bin/notify-send "Firmware updates available" "$updates" -u normal
        fi
      fi
    '';
    serviceConfig.Type = "oneshot";
  };
};

# Run turbostat in the background: can pull Intel CPU/iGPU power data from this
systemd.services.turbostat = {
  description = "turbostat background sampler";
  wantedBy = [ "multi-user.target" ];
  script = ''
    ${pkgs.linuxPackages.turbostat}/bin/turbostat \
      --quiet --show PkgWatt,CorWatt,GFXWatt,RAMWatt \
      --interval 1 --no-msr \
      > /tmp/turbostat.log 2>/dev/null
  '';
  serviceConfig = {
    Restart = "always";
    User = "root";
  };
};

systemd.user.timers.fwupd-check = {
  description = "Check for firmware updates after boot";
  wantedBy = [ "timers.target" ];
  timerConfig = {
    OnBootSec = "5min";
    OnUnitActiveSec = "1week";
  };
};

# ============================================
# VIRTUALIZATION
# ============================================

virtualisation.libvirtd = {
  enable = true;
  qemu = {
    package = pkgs.qemu_kvm;
    runAsRoot = true;
    swtpm.enable = true; # TPM for Win11
  };
};

# ============================================
# SYSTEM-WIDE PROGRAM CONFIG
# ============================================

programs = {
  bash = {
    enable = true;
    shellAliases = {
      rm = "trash-put"; # system-wide safety
    };
  };
  zsh = {
    enable = true;
    shellAliases = {
      rm = "trash-put"; # system-wide safety
    };
  };
  dconf.enable = true;
  seahorse.enable = true;
  gamescope.enable = true;
  xwayland.enable = true;
  ydotool.enable = true;
  steam = {
    enable = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
    package = pkgs.steam.override {
      extraEnv = {
        SDL_KEYBOARD_LAYOUT = "jp";
      };
    };
  };
  hyprland = {
    enable = true;
    portalPackage = pkgs.xdg-desktop-portal-hyprland;
  };
  wayfire = {
    enable = true;
    xwayland.enable = true;
    plugins = with pkgs.wayfirePlugins; [
      wcm # wayfire config manager: GTK app
      wayfire-plugins-extra
    ];
  };
};

# ============================================
# FONTS
# ============================================

fonts = {
  packages = with pkgs; [
    carlito
    dejavu_fonts
    ipafont
    kochi-substitute
    liberation_ttf
    nerd-fonts.fira-code
    nerd-fonts.symbols-only
    noto-fonts-cjk-sans
    source-code-pro
    ttf_bitstream_vera
  ];
  fontconfig.defaultFonts = {
    monospace = [ "DejaVu Sans Mono" "IPAGothic" ];
    sansSerif = [ "DejaVu Sans" "IPAPGothic" ];
    serif = [ "DejaVu Serif" "IPAPMincho" ];
  };
};

# ============================================
# ENVIRONMENT VARIABLES
# ============================================

environment.variables = {
  QT_IM_MODULE = "fcitx";     # https://fcitx-im.org/wiki/Using_Fcitx_5_on_Wayland
  XMODIFIERS = "@im=fcitx";
  SDL_IM_MODULE = "fcitx";
  GLFW_IM_MODULE = "ibus";
  QT_QPA_PLATFORMTHEME = "qt5ct";
  XDG_ICON_FALLBACK = "/etc/nixos/dotfiles/images/blankicon.png";
};

environment.sessionVariables = {
  LIBVA_DRIVER_NAME = "iHD";
  MOZ_ENABLE_WAYLAND = "1";
#  WLR_RENDERER = "vulkan";
#  WLR_NO_HARDWARE_CURSORS = "1";
#  __GLX_VENDOR_LIBRARY_NAME = "nvidia";
#  LIBVA_DRIVER_NAME = "nvidia";
#  GBM_BACKENDS_PATH = "/run/opengl-driver/lib/gbm";
#  FCITX_NO_PREEDIT_ON_PASSWORD = "1";
};

# ============================================
# XDG PORTAL
# ============================================

xdg.portal = {
  enable = true;
  extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
  config = {
    common = {
      default = "hyprland";
      "org.freedesktop.impl.portal.FileChooser" = "gtk";
    };
  };
};

# ============================================
# USER ACCOUNT
# ============================================

users = {
  defaultUserShell = pkgs.zsh;
  users.joe = {
    isNormalUser = true;
    extraGroups = [
      "adbusers"  # access to android debug stuff
      "dialout"   # access to serial ports
      "libvirtd"  # access to libvirt VM management
      "plugdev"   # access to USB devices such as rpi flashing
      "audio"     # access to audio devices
      "disk"      # access to raw disk devices
      "video"     # access to video devices
      "power"     # access to power management
      "plugdev"   # access to removable devices
      "network"   # access to network interface
      "wheel"     # access to sudo
      "input"     # access to input devices
      "uinput"    # access to virtual input devices
    ];
  };
}; 

# ============================================
# SYSTEM PACKAGES
# ============================================

environment.systemPackages = with pkgs; [

  # P14sG6-specific stuff
  linuxKernel.packages.linux_xanmod.turbostat # CPU power use stats
  virt-manager # manage VMs
  freerdp # RDP client on host connects to VM NAT
  intel-gpu-tools # check iGPU resource utilization

  # HARDWARE + DRIVERS + EXTERNAL DEVICES
  acpid # watch ACPI events
  alsa-utils # sound utils
  android-tools # contains ADB, fastboot, etc
  brightnessctl # control laptop display backlight
  dfu-util # flash STM32s in DFU mode
  efibootmgr # manage boot entries on EUFI NVRAM
  exfatprogs # format stuff as exfat
  jmtpfs # allows for Android MTP; use instead of mtpfs
  lm_sensors # tons of hardware sensors
  lshw # list hardware inventory
  pciutils # contains PCI tools like lspci
  powertop # Intel-only power tuning/analyzer
  udisks2 # for mounting disks from userland

  # UTILS
  bc # calculations
  btop # like htop but nicer
  cachix # binary cache
  cpufrequtils # cpu frequency control/query
  curl # download web stuff
  dislocker # unlock Bitlocker encryption
  fcitx5 # input method framework
  fcitx5-mozc # IME
  file # determines file type/info
  git # distributed version control system
  htop # view resource usage
  id3v2 # view/edit mp3 metadata
  inetutils # network tools such as telnet
  iotop # view disk usage/processes
  kdePackages.audex # CD ripper for videos
  killall # allows for killing processes by name
  moreutils # useful UNIX tools: ts, sponge, vidir, etc.
  neovim # vim with more goodness
  nixos-option # query NixOS module options
  ntfs3g # allows to read/write NTFS
  p7zip # 7z/rar/zip compression tool
  ranger # TUI file browser
  rpiboot # tool to boot Pis over USB
  s-tui # terminal TUI for CPU temp/power/freq
  scanmem # reverse engineering LoT2 lol
  stress # hardware stress tool
  tmux # terminal multiplexer
  traceroute # traces network hops
  trash-cli # alias rm -> similar to Recycle Bin
  unzip # extracting .zip files
  upower #dbus service for power management
  usbutils # handy USB utils like lsusb
  vim # the best text editor
  wget # network downloader
  woeusb # writes ISO to drives nicer than dd
  
  # LIBRARIES
  libarchive # tools for tar, zip, etc.
  libguestfs-with-appliance # view/modify VM disk images
  libnotify # desktop notification library
  libusb1 # various; flash STM32s
  libva-utils # power management stuff
  libsForQt5.qtstyleplugin-kvantum # kvantum = qt config tool
  libsForQt5.qt5ct # qt config tool

  # LOGIN STUFF FOR USERS
  catppuccin-sddm # nice sddm themes
  (catppuccin-sddm.override {
    flavor = "macchiato";
    accent = "mauve";
    font = "Noto Sans";
    fontSize = "14";
    background = "/etc/nixos/dotfiles/wallpapers/apple-dark.jpg";
    loginBackground = false;
    userIcon = true;
  })

  # AGS stuff
  ags
  astal.astal3
  astal.hyprland
  astal.mpris
  astal.battery
  astal.wireplumber
  astal.network
];

################################################
########## DO NOT EVER CHANGE THIS #############
################################################
system.stateVersion = "25.11";
################################################
}
