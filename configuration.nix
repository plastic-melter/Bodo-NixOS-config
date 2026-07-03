{ inputs, outputs, lib, config, pkgs, ... }: {

#############################################
############# X210Ai CONFIG #################
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
    efi.canTouchEfiVariables = true;
    timeout = 1;
    systemd-boot = {
      enable = true;
      configurationLimit = 20;
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
  };
  kernelModules = [ 
    "ntsync" # CoD WaW performance
    "uinput" # B0XX native USB
    "kvm-intel" # enables hardware-accelerated virtualization (VMX)
    "hid_nintendo" # Switch controller pairing
    "vfio" # core VFIO framework: lets userspace (QEMU) own PCI devices
    "vfio_iommu_type1" # IOMMU backend for VFIO, enforces memory isolation between VM and host
    "vfio_pci" # the actual driver that claims PCI devices on behalf of VFIO
  ];
  kernelPackages = pkgs.linuxPackages_xanmod_latest; # gaming
  kernelParams = [
    "quiet" # surpress kernel boot messages: still readable via dmesg/journalctl
    "acpi.dump_ecdt=1" # more EC logging
    "no_console_suspend" # keep console active during suspend for better logging
    "intel_iommu=on" # enable Intel's IOMMU hardware, required for device isolation
    "iommu=pt" # passthrough mode: devices not assigned to VMs use DMA directly (better performance)
    #"amdgpu.ppfeaturemask=0xfffd7fff" # enables some GPU features for waybar
    #"pcie_aspm=off" # eGPU troubleshoot: let BIOS determine ASPM
    #"pcie_aspm.policy=performance" # force disable ASPM
    "pcie_port_pm=off" # eGPU troubleshot
    "amdgpu.runpm=0" # eGPU troubleshoot
  ];
  #resumeDevice = "/dev/disk/by-uuid/2ef9551c-28e6-484b-9afa-5de05f928942";
  kernel.sysctl."net.ipv4.ip_forward" = 1; # IP forwarding
  extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom=US
  ''; 
  #   cfg...  = resolve JP/US IR flag mismatch
  # below: X210Ai AMD eGPU binding at boot for VMs only
  # options vfio-pci ids=1002:73a5,1002:ab28
};

swapDevices = [{
  device = "/var/lib/swapfile";
  size = 96*1024; # 96 GiB, matching system RAM
}];

# ============================================
# NETWORKING, SYSTEMD SERVICES
# ============================================

networking = {
  hostName = "X210Ai";
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
  libvirtd = {
    stopIfChanged = false;
  };
  # Save the trouble of running 'virsh netstart default' each time:
  libvirtd.postStart = ''
    sleep 2
    virsh net-start default || true
    virsh net-autostart default || true
  '';
};

# ============================================
# LOCALIZATION
# ============================================

time = { 
  timeZone = "America/Los_Angeles";
  hardwareClockInLocalTime = false; # RTC is set to UTC for Windows
};
i18n = {
  defaultLocale = "en_US.UTF-8";
  inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-gtk
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
  graphics = {
    enable = true;
    enable32Bit = true; # for steam/wine/32-bit GL
    extraPackages = with pkgs; [ # drivers not auto-installed
      intel-media-driver  # iHD, for Gen 8+
    ];
  };
  cpu.intel.updateMicrocode = true;
  uinput.enable = true; # B0XX native USB
  bluetooth.enable = true;
  bluetooth.powerOnBoot = true;
  enableRedistributableFirmware = true;
  sane = {
    enable = true; # for scanning from printer/scanner
    brscan4 = {
      enable = true; # for Brother MFC printer/scanner
      netDevices = {
        brother = {
          ip = "192.168.1.16";
          model = "MFC-L2820DW";
        };
      };
    };
  };
};

# ============================================
# SECURITY
# ============================================

security = {
  rtkit.enable = true;
  polkit = {
    enable = true;
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
    videoDrivers = [ "modesetting" ];
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
  joycond.enable = true; # Switch controller

  # AMD eGPU
  lact.enable = true;

  # Local AI
  ollama = {
    enable = true;
    package = pkgs.ollama-rocm; # AMD eGPU
  };

  # Turbostat logging
  logrotate.settings.turbostat = {
    files = "/var/log/turbostat/turbostat.log";
    rotate = 10;
    size = "500M";
    compress = true;
    delaycompress = true;
    missingok = true;
    notifempty = true;
    copytruncate = true;   # turbostat holds the fd open — truncate in place instead of rename+restart
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
  udisks2.enable = true; # auto-mount removeable drives
  fstrim.enable = true; # periodic SSD/NVMe trim for health
  fwupd.enable = true; # firmware updates via LVFS
  journald.storage = "persistent"; # persistent journald for troubleshooting things that cause system crashes
  timesyncd.enable = true; # syncs clock to NTP servers over internet
  printing = {
    enable = true; # enable CUPS for using printers
    drivers = [ pkgs.brlaser ]; # Brother MFC printer-scanner
  };
  openssh.enable = true; # enable SSH
  blueman.enable = true; # convenient bluetooth GUI
  gvfs.enable = true; # required for Thunar to use .local/share/Trash

  # Syncthing
  syncthing = {
    enable = true;
    openDefaultPorts = true;
  };

  # Power Management / Hardware
  power-profiles-daemon.enable = false; # don't fight tlp
  tlp = {
    enable = true;
    settings = { 
      RUNTIME_PM_ON_AC = "on"; # Allow runtime PM even on AC (ex: don't power on the dGPU if it's not needed)
    };
  };
  thermald.enable = true; # Intel thermal daemon
  upower.enable = true; # dbus service that abstracts PM hardware an gives a nice API rather than poking /sys directly
  thinkfan = {
    enable = false;
    levels = [
      [ 0                    0  60 ]
      [ 1                   55  68 ]
      [ 2                   64  82 ]
      [ 3                   78  85 ]
      [ 5                   82  92 ]
      [ 7                   90  97 ]
      [ "level full-speed"  95  32767 ]
    ];
  };

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

  # Printers/scanners: access to scanner
  avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = false; # only for printer discovery
  };
};

# Run turbostat in the background: can pull Intel CPU/iGPU power data from this
systemd.services.turbostat = {
  description = "turbostat background sampler";
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    Restart = "always";
    User = "root";
    LogsDirectory = "turbostat";                  # makes /var/log/turbostat
    ExecStart = "${pkgs.writeShellScript "turbostat-start" ''
      exec ${pkgs.coreutils}/bin/stdbuf -oL \
        ${pkgs.linuxPackages.turbostat}/bin/turbostat \
          --quiet --interval 1 \
          >> /var/log/turbostat/turbostat.log 2>&1
    ''}";
  };
};

# After NTP syncs, write the correct time to the RTC chip
systemd.services.rtc-writeback = {
  after = [ "systemd-timesyncd.service" "time-sync.target" ];
  wants = [ "time-sync.target" ];
  wantedBy = [ "time-sync.target" ];
  serviceConfig = { Type = "oneshot"; ExecStart = "${pkgs.util-linux}/bin/hwclock --systohc"; };
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
    verbatimConfig = ''
      cgroup_controllers = [ "cpu", "memory", "blkio", "cpuset", "cpuacct" ]
    '';
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
  nix-ld = {
    enable = true; # run things that expect FHS paths
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      zstd
    ];
  };
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
    powerline-symbols
    powerline-fonts
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
# ENV VARS
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
  MOZ_ENABLE_WAYLAND = "1"; # firefox wants this
#  AQ_DRM_DEVICES = "/dev/dri/by-path/pci-0000:00:02.0-card"; # make Hyprland use iGPU; NOT eGPU!
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
      "scanner"   # access to scanner
      "lp"        # access to scanner
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

environment.systemPackages = let
  egpu-to-vm = pkgs.writeShellScriptBin "gpu-to-vm" ''
    set -euo pipefail
    for dev in 0000:04:00.0 0000:04:00.1; do
      echo vfio-pci > /sys/bus/pci/devices/$dev/driver_override
      [ -e /sys/bus/pci/devices/$dev/driver ] && \
        echo "$dev" > /sys/bus/pci/devices/$dev/driver/unbind
      echo "$dev" > /sys/bus/pci/drivers/vfio-pci/bind
    done
    echo "eGPU -> vfio-pci"
  '';
  egpu-to-host = pkgs.writeShellScriptBin "gpu-to-host" ''
    set -euo pipefail
    bind() {
      echo "" > /sys/bus/pci/devices/$1/driver_override
      [ -e /sys/bus/pci/devices/$1/driver ] && \
        echo "$1" > /sys/bus/pci/devices/$1/driver/unbind
      echo "$1" > /sys/bus/pci/drivers/$2/bind
    }
    bind 0000:04:00.0 amdgpu
    bind 0000:04:00.1 snd_hda_intel
    echo "eGPU -> host (amdgpu)"
  '';
in (with pkgs; [

  # VM and eGPU stuff
  freerdp # RDP client on host connects to VM NAT
  intel-gpu-tools # check iGPU resource utilization
  lact # GUI for AMD GPU tuning
  linuxKernel.packages.linux_xanmod.turbostat # CPU power use stats
  radeontop # AMD GPU monitor
  virt-manager # manage VMs

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
  msr-tools # read/write to/from the MSR
  pulseaudio # gives pactl for steam
  pciutils # contains PCI tools like lspci
  udisks2 # for mounting disks from userland

  # UTILS
  bc # calculations
  btop # like htop but nicer
  cachix # binary cache
  cpufrequtils # cpu frequency control/query
  curl # download web stuff
  dislocker # unlock Bitlocker encryption
  file # determines file type/info
  git # distributed version control system
  htop # view resource usage
  id3v2 # view/edit mp3 metadata
  iftop # like htop but for network stuff
  inetutils # network tools such as telnet
  iotop # view disk usage/processes
  kdePackages.audex # CD ripper for videos
  killall # allows for killing processes by name
  lsof # shows which processes have files/devices open
  moreutils # useful UNIX tools: ts, sponge, vidir, etc.
  neovim # vim with more goodness
  nethogs # view per-process network throughput
  nixos-option # query NixOS module options
  ntfs3g # allows to read/write NTFS
  p7zip # 7z/rar/zip compression tool
  powertop # diagnose and optimize power consumption
  ranger # TUI file browser
  rpiboot # tool to boot Pis over USB
  s-tui # terminal TUI for CPU temp/power/freq
  scanmem # reverse engineering LoT2 lol
  smartmontools # monitor storage systems (ex: SSD health)
  stress-ng # hardware stress tool
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
]) ++ [ egpu-to-vm egpu-to-host ];

################################################
########## DO NOT EVER CHANGE THIS #############
################################################
system.stateVersion = "25.11";
################################################
}
