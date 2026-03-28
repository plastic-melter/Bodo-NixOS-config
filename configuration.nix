{ inputs, outputs, lib, config, pkgs, ... }: {

#############################################
############## X13G3 CONFIG #################
#############################################

imports = [
  ./hardware-configuration.nix
];

# ============================================
# NIXPKGS CONFIGURATION
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

# ============================================
# BOOT CONFIGURATION
# ============================================

#boot = {
#  kernelPackages = pkgs.linuxPackages_latest;
#  loader = {
#    timeout = 1;
#    efi.canTouchEfiVariables = true;
#    grub = {
#      enable = true;
#      device = "nodev";
#      useOSProber = false;
#      enableCryptodisk = true;
#      efiSupport = true;
#      default = "2";
#      extraConfig = ''
#        timeout=-1
#        GRUB_GFXMODE=2560x1600x128,auto
#        menuentry "Reboot" {
#          reboot
#        }
#        menuentry "Poweroff" {
#          halt
#        }
#      '';
#      theme = pkgs.stdenv.mkDerivation {
#        pname = "distro-grub-themes";
#        version = "3.1";
#        src = pkgs.fetchFromGitHub {
#          owner = "AdisonCavani";
#          repo = "distro-grub-themes";
#          rev = "v3.1";
#          hash = "sha256-ZcoGbbOMDDwjLhsvs77C7G7vINQnprdfI37a9ccrmPs=";
#        };
#        installPhase = "cp -r customize/thinkpad $out";
#      };
#    };
#  };
#};

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
  kernelModules = [ "zenpower" "ntsync" ]; # ntsync for CoD WaW
  kernelPackages = pkgs.linuxPackages_xanmod_latest; # ePiC gAmInG kErNel
  blacklistedKernelModules = [ "k10temp" ];
  extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom=US
  ''; # above: JP/US IR flag mismatch
};

swapDevices = [{device = "/swapfile"; size = 16000;}];

# ============================================
# NETWORKING
# ============================================

networking = {
  hostName = "X13G3";
  useDHCP = false;
  networkmanager = {
    enable = true;
  };
};

# Disable network wait services for faster boot
systemd.network.wait-online.enable = false;
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

time.timeZone = "America/Los_Angeles";
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
#  nvidia = {
#    modesetting.enable = true;
#    open = true; # Required for Blackwell
#    nvidiaSettings = true;
#    powerManagement.enable = false;
#    package = config.boot.kernelPackages.nvidiaPackages.stable // {
#      open = config.boot.kernelPackages.nvidiaPackages.stable.open.overrideAttrs (old: {
#        patches = (old.patches or [ ]) ++ [
#          (pkgs.fetchpatch {
#            name = "get_dev_pagemap.patch";
#            url = "https://github.com/NVIDIA/open-gpu-kernel-modules/commit/3e230516034d29e84ca023fe95e284af5cd5a065.patch";
#            hash = "sha256-BhL4mtuY5W+eLofwhHVnZnVf0msDj7XBxskZi8e6/k8=";
#          })
#        ];
#      });
#    };
#  };
  bluetooth = {
    enable = true;
    hsphfpd.enable = false;
  };
  graphics = {
    enable = true;
    enable32Bit = true;
  };
  enableAllFirmware = true;
  trackpoint = {
    emulateWheel = true;
    speed = 97;
    sensitivity = 128;
  };
};

powerManagement.cpuFreqGovernor = "ondemand";

# ============================================
# SECURITY
# ============================================

security = {
  rtkit.enable = true;
  polkit.enable = true;
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
    videoDrivers = [ "radeon" ];
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

  # Power Management
  tlp = {
    enable = true;
    settings = { 
      START_CHARGE_THRESH_BAT0 = 90; 
      STOP_CHARGE_THRESH_BAT0 = 95; 
    };
  };

  # USB Device Rules
  udev.extraRules = ''
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

# Firmware update checker (runs AFTER boot to avoid slowdown)
systemd.user.services.fwupd-check = {
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

systemd.user.timers.fwupd-check = {
  description = "Check for firmware updates after boot";
  wantedBy = [ "timers.target" ];
  timerConfig = {
    OnBootSec = "5min";
    OnUnitActiveSec = "1week";
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

lib.mkForce = {
  environment.variables = {
    GTK_IM_MODULE = "wayland";  # Not ideal but w/e... 
    QT_IM_MODULE = "fcitx";     # https://fcitx-im.org/wiki/Using_Fcitx_5_on_Wayland
    XMODIFIERS = "@im=fcitx";
    SDL_IM_MODULE = "fcitx";
    GLFW_IM_MODULE = "ibus";
  };
};

environment.variables = {
  QT_QPA_PLATFORMTHEME = "qt5ct";
  XDG_ICON_FALLBACK = "/etc/nixos/dotfiles/images/blankicon.png";
};

#environment.sessionVariables = {
#  WLR_RENDERER = "vulkan";
#  WLR_NO_HARDWARE_CURSORS = "1";
#  __GLX_VENDOR_LIBRARY_NAME = "nvidia";
#  LIBVA_DRIVER_NAME = "nvidia";
#  GBM_BACKENDS_PATH = "/run/opengl-driver/lib/gbm";
#  FCITX_NO_PREEDIT_ON_PASSWORD = "1";
#};

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
      "adbusers"	# access to android debug stuff
      "dialout"		# access to serial ports
#      "libvirtd"	# access to libvirt VM management
      "plugdev" # access to USB devices such as rpi flashing
      "audio"		# access to audio devices
      "disk"		# access to raw disk devices
      "video"		# access to video devices
      "power"		# access to power management
      "plugdev"		# access to removable devices
      "network"		# access to network interface
      "wheel"		# access to sudo
      "input"		# access to input devices
      "uinput"		# access to virtual input devices
    ];
  };
}; 

# ============================================
# SYSTEM PACKAGES
# ============================================

environment.systemPackages = with pkgs; [

  # HARDWARE + DRIVERS + EXTERNAL DEVICES
  acpid # watch ACPI events
  alsa-utils # sound utils
  android-tools # contains ADB, fastboot, etc
  brightnessctl # control laptop display backlight
  dfu-util # flash STM32s in DFU mode
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
  radeontop # AMD iGPU monitor
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

  qmk # temporary
dos2unix
];

################################################
########## DO NOT EVER CHANGE THIS #############
################################################
system.stateVersion = "25.11";
################################################
}
