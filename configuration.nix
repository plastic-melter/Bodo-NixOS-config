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
      configurationLimit = 10;
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
  ];
  kernelPackages = pkgs.linuxPackages_xanmod_latest; # gaming
  kernelParams = [
    "quiet" # surpress kernel boot messages: still readable via dmesg/journalctl
    "acpi.dump_ecdt=1"  # more EC logging
    "no_console_suspend"  # keep console active during suspend for better logging
    #"i915.enable_psr=0" # disable panel self refresh (PSR = only refresh panel if frame actually changed)
  ];
  #resumeDevice = "/dev/disk/by-uuid/2ef9551c-28e6-484b-9afa-5de05f928942";
  kernel.sysctl."net.ipv4.ip_forward" = 1; # IP forwarding
  extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom=US
  ''; 
  #   - cfg...  = resolve JP/US IR flag mismatch
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
  libvirtd.postStart = ''
    sleep 2
    virsh net-start default || true
    virsh net-autostart default || true
  ''; # Above: save the trouble of running 'virsh netstart default' each time
};

# ============================================
# LOCALIZATION
# ============================================

time.timeZone = "America/Los_Angeles";
#time.timeZone = "Asia/Tokyo";
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
      intel-vaapi-driver  # i965 fallback
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

powerManagement.powertop.enable = false; # powertop sometimes randomly enforces weird low power limits on AC

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

  # Turbostat logging
  logrotate.settings.turbostat = {
    files = "/var/log/turbostat/turbostat.log";
    rotate = 10;        # keep 10 logs
    size = "500M";       # rotate when file hits 50M
    compress = true;
    delaycompress = true;
    missingok = true;
    notifempty = true;
    postrotate = "systemctl restart turbostat";
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

  # Syncthing
  syncthing = {
    enable = true;
    openDefaultPorts = true;
  };

  # Power Management / Hardware
  power-profiles-daemon.enable = false; # don7t fight tlp
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

    # AC plugged in: full performance (PL1=55W, PL2=65W)
    #SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="${pkgs.bash}/bin/sh -c 'echo 55000000 > /sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/constraint_0_power_limit_uw && echo 65000000 > /sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/constraint_1_power_limit_uw'"
    # On battery: conservative (PL1=35W, PL2=65W)
    #SUBSYSTEM=="power_supply", ATTR{online}=="0", RUN+="${pkgs.bash}/bin/sh -c 'echo 35000000 > /sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/constraint_0_power_limit_uw && echo 65000000 > /sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/constraint_1_power_limit_uw'"

    # AC plugged in: full performance (PL1=55W, PL2=65W)
    #SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="${pkgs.bash}/bin/sh -c 'echo 55000000 > /sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/constraint_0_power_limit_uw && echo 65000000 > /sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/constraint_1_power_limit_uw && echo 50000000 > /sys/class/powercap/intel-rapl-mmio:0/constraint_0_power_limit_uw'"

    # On battery: conservative (PL1=35W, PL2=65W)
    #SUBSYSTEM=="power_supply", ATTR{online}=="0", RUN+="${pkgs.bash}/bin/sh -c 'echo 35000000 > /sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/constraint_0_power_limit_uw && echo 65000000 > /sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/constraint_1_power_limit_uw && echo 28000000 > /sys/class/powercap/intel-rapl-mmio:0/constraint_0_power_limit_uw'"

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
  script = ''
    ${pkgs.linuxPackages.turbostat}/bin/turbostat --quiet --interval 1 > /tmp/turbostat.log 2>/dev/null
  '';
  serviceConfig = {
    Restart = "always";
    User = "root";
    LogsDirectory = "turbostat";
  };
};

# Set CPU power limits at boot: there's a udev rule for changing it whenever AC adapter is plugged/unplugged too
#systemd.services.rapl-init = {
#  description = "Initialize RAPL limits based on power source";
#  wantedBy = [ "multi-user.target" ];
#  after = [ "systemd-udevd.service" ];
#  script = ''
#    if grep -q 1 /sys/class/power_supply/AC/online 2>/dev/null; then
#      echo 55000000 > /sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/constraint_0_power_limit_uw
#      echo 65000000 > /sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/constraint_1_power_limit_uw
#    else
#      echo 35000000 > /sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/constraint_0_power_limit_uw
#      echo 65000000 > /sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/constraint_1_power_limit_uw
#    fi
#  '';
#  serviceConfig.Type = "oneshot";
#};

#systemd.services.rapl-pl1 = {
#  description = "Reapply RAPL PL1 limits (EC override workaround)";
#  serviceConfig.Type = "oneshot";
#  script = ''
#    online=$(cat /sys/class/power_supply/AC/online 2>/dev/null || echo 0)
#    if [[ "$online" == "1" ]]; then
#      pl1=55000000
#      pl2=65000000
#    else
#      pl1=28000000
#      pl2=65000000
#    fi
#    echo $pl1 > /sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/constraint_0_power_limit_uw
#    echo $pl1 > /sys/class/powercap/intel-rapl-mmio:0/constraint_0_power_limit_uw
#    echo $pl2 > /sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/constraint_1_power_limit_uw
#    echo $pl2 > /sys/class/powercap/intel-rapl-mmio:0/constraint_1_power_limit_uw
#  '';
#};

#systemd.timers.rapl-pl1 = {
#  description = "Reapply RAPL PL1 every 5s";
#  wantedBy = [ "timers.target" ];
#  timerConfig = {
#    OnBootSec = "10s";
#    OnUnitActiveSec = "5s";
#    AccuracySec = "1s";
#  };
#};

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
#  LIBVA_DRIVER_NAME = "iHD";
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

environment.systemPackages = with pkgs; [

  # Machine-specific stuff
  freerdp # RDP client on host connects to VM NAT
  intel-gpu-tools # check iGPU resource utilization
  linuxKernel.packages.linux_xanmod.turbostat # CPU power use stats
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
];

################################################
########## DO NOT EVER CHANGE THIS #############
################################################
system.stateVersion = "25.11";
################################################
}
