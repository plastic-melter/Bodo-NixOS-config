{ inputs, config, pkgs, lib, ... }: {

#################################################
################## HOME.NIX #####################
#################################################

home = {
  stateVersion = "25.11"; # DO NOT EVER EDIT THIS
  username = "joe";
  homeDirectory = "/home/joe";
};

# ============================================
# DOTFILE SOURCING
# ============================================

home.file = {
  ".config/ags" = {
    source = ./dotfiles/ags;
    recursive = true;
  };
  ".config/eww" = {
    source = ./dotfiles/eww;
    recursive = true;
  };
  ".config/foot".source = ./dotfiles/foot;
  ".config/hypr".source = ./dotfiles/hypr;
  ".config/nwg-drawer".source = ./dotfiles/nwg-drawer;
  ".config/plutonium".source = ./dotfiles/plutonium;
  ".config/scripts".source = ./dotfiles/scripts;
  ".config/waybar".source = ./dotfiles/waybar;
  ".config/wayfire".source = ./dotfiles/wayfire;
  ".config/wezterm".source = ./dotfiles/wezterm;
  ".config/wlogout".source = ./dotfiles/wlogout;
  ".config/wofi".source = ./dotfiles/wofi;
  ".config/xdg-desktop-portal".source = ./dotfiles/xdg-desktop-portal;
  ".config/yazi".source = ./dotfiles/yazi;
};

# ============================================
# XDG STUFF
# ============================================

xdg.userDirs.enable = false;

xdg.configFile = {
  # Neovim configuration
  "nvim/lua/settings.lua".source = ./dotfiles/neovim/lua/settings.lua;
  "nvim/lua/keymaps.lua".source = ./dotfiles/neovim/lua/keymaps.lua;
  "nvim/lua/plugins.lua".source = ./dotfiles/neovim/lua/plugins.lua;

  # User directories, hopefully these get indexed by nwg
  "user-dirs.conf".text = "enabled=True";
  "user-dirs.dirs".text = ''
    XDG_DESKTOP_DIR="/home/joe/Desktop"
    XDG_DOCUMENTS_DIR="/home/joe/Documents"
    XDG_DOWNLOAD_DIR="/home/joe/Downloads"
    XDG_MUSIC_DIR="/home/joe/Music"
    XDG_PICTURES_DIR="/home/joe/Pictures"
    XDG_PUBLICSHARE_DIR="/home/joe/Public"
    XDG_TEMPLATES_DIR="/home/joe/Templates"
    XDG_VIDEOS_DIR="/home/joe/Videos"
    XDG_BACKUP_DIR="/home/joe/Backups"
  '';

  # Qt configuration
  "qt5ct/qt5ct.conf" = {
    force = true;
    text = ''
      [Appearance]
      style=Kvantum
      icon_theme=breeze
    '';
  };
  "qt6ct/qt6ct.conf" = {
    force = true;
    text = ''
      [Appearance]
      style=Kvantum
      icon_theme=breeze
    '';
  };

  # Disable annoying fctix popup about GTK_IM_MODULE
  "fcitx5/config".text = ''
    [Hotkey]
    # Enumerate when holding modifier of Toggle key
    EnumerateWithTriggerKeys=True
    # Enumerate Input Method Forward
    EnumerateForwardKeys=
    # Enumerate Input Method Backward
    EnumerateBackwardKeys=
    # Skip first input method while enumerating
    EnumerateSkipFirst=False
    # Time limit in milliseconds for triggering modifier key shortcuts
    ModifierOnlyKeyTimeout=250
    [Hotkey/TriggerKeys]
    0=Zenkaku_Hankaku
    1=Zenkaku_Hankaku
    2=Hangul
    [Hotkey/ActivateKeys]
    0=Hangul_Hanja
    [Hotkey/DeactivateKeys]
    0=Hangul_Romaja
    [Hotkey/AltTriggerKeys]
    0=Shift_L
    [Hotkey/EnumerateGroupForwardKeys]
    0=Super+space
    [Hotkey/EnumerateGroupBackwardKeys]
    [Hotkey/PrevPage]
    0=Up
    [Hotkey/NextPage]
    0=Down
    [Hotkey/PrevCandidate]
    0=Shift+Tab
    [Hotkey/NextCandidate]
    0=Tab
    [Hotkey/TogglePreedit]
    0=Control+Alt+P
    [Behavior]
    # Active By Default
    ActiveByDefault=False
    # Reset state on Focus In
    resetStateWhenFocusIn=No
    # Share Input State
    ShareInputState=No
    # Show preedit in application
    PreeditEnabledByDefault=True
    # Show Input Method Information when switch input method
    ShowInputMethodInformation=True
    # Show Input Method Information when changing focus
    showInputMethodInformationWhenFocusIn=False
    # Show compact input method information
    CompactInputMethodInformation=True
    # Show first input method information
    ShowFirstInputMethodInformation=True
    # Default page size
    DefaultPageSize=5
    # Override XKB Option
    OverrideXkbOption=False
    # Custom XKB Option
    CustomXkbOption=
    # Force Enabled Addons
    EnabledAddons=
    # Force Disabled Addons
    DisabledAddons=
    # Preload input method to be used by default
    PreloadInputMethod=True
    # Allow input method in the password field
    AllowInputMethodForPassword=False
    # Show preedit text when typing password
    ShowPreeditForPassword=False
    # Interval of saving user data in minutes
    AutoSavePeriod=30
    [Notifications]
    HiddenNotifications=wayland-diagnose
  '';

  # Make thunar use wezterm
  "xfce4/helpers.rc".text = "TerminalEmulator=wezterm";
};

# ============================================
# PROGRAMS
# ============================================

programs = {

  direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  git = {
    enable = true;
    package = pkgs.git;
    settings = {
      user.name = "plastic-melter";
      user.email = "140357149+plastic-melter@users.noreply.github.com";
    };
    settings = {
      safe.directory = "/etc/nixos";
    };
  };

  neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;
    plugins = with pkgs.vimPlugins; [
      nvim-treesitter.withAllGrammars  # Syntax highlighting and parsing
      catppuccin-nvim                   # Mocha colorscheme
      telescope-nvim                    # Fuzzy finder for files/buffers/grep
      plenary-nvim                      # Lua utility library (telescope dependency)
      lualine-nvim                      # Statusline
      nvim-web-devicons                 # File icons
      gitsigns-nvim                     # Git diff indicators in sign column
      indent-blankline-nvim             # Indent guide lines
      neoscroll-nvim                    # Smooth scrolling
      toggleterm-nvim                   # Floating terminal
    ];
    initLua = builtins.readFile ./dotfiles/neovim/init.lua;
  };

  zsh = import ./dotfiles/zsh/zshrc.nix { inherit pkgs lib; };
};

manual = {
  html.enable = false;
  json.enable = false;
  manpages.enable = false;
};

# ============================================
# WAYLAND COMPOSITOR
# ============================================

wayland.windowManager = {

  hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = false;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
  };

  # wayfire? already installed via conf.nix, and wayfire.ini is written to .config...

};

# ============================================
# SERVICES
# ============================================

services = {
  playerctld.enable = true;
  syncthing.enable = true;

  dunst = {
    enable = true;
    settings.global = {
      timeout = 2;
      width = "(0, 600)";
      height = 200;
      offset = "0x30";
      origin = "top-center";
      corner_radius = 15;
      notification_limit = 5;
      idle_threshold = 0;
      progress_bar = true;
      progress_bar_height = 15;
      progress_bar_horizontal_alignment = "center";
      progress_bar_corner_radius = 3;
      progress_bar_min_width = 150;
      progress_bar_max_width = 350;
      progress_bar_frame_width = 2;
      separator_height = 3;
      separator_color = "auto";
      sort = "false";
      layer = "overlay";
      line_height = 0;
      format = "<b>%s</b>\n%b";
      padding = 5;
      horizontal_padding = 5;
      icon_corner_radius = 5;
      text_icon_padding = 5;
      frame_width = 4;
      frame_color = "#5E81AC";
      background_color = "#181b28";
      foreground_color = "#ffffd8";
      font = "NotoSansCJK 18";
      min_icon_size = 128;
      max_icon_size = 128;
      background = "#090909B5";
    };
  };
};

# ============================================
# SYSTEMD USER SERVICES
# ============================================

systemd.user = {
  targets.tray = {
    Unit = {
      Description = "Home Manager System Tray";
      Requires = [ "graphical-session-pre.target" ];
    };
  };

  services = {
    udiskie = {
      Unit.Description = "udiskie automounter";
      Service.ExecStart = "${pkgs.udiskie}/bin/udiskie --smart-tray";
      Install.WantedBy = [ "default.target" ];
    };

    hourly-chime = {
      Unit.Description = "Hourly time notification";
      Service = {
        Type = "oneshot";
        ExecStart = "/etc/nixos/dotfiles/scripts/hourly-chime.sh";
      };
    };
  };

  timers.hourly-chime = {
    Unit.Description = "Hourly chime timer";
    Timer = {
      OnCalendar = "hourly";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };
};

# ============================================
# ENVIRONMENT VARIABLES
# ============================================

home.sessionVariables = {
  TERMINAL = "wezterm";
  TERM_PROGRAM = "wezterm";
  GI_TYPELIB_PATH = "/run/current-system/sw/lib/girepository-1.0";
  EDITOR = "nvim";
  VISUAL = "nvim";
};

systemd.user.sessionVariables = {
  GTK_THEME = "Arc-Dark";
  XDG_ICON_FALLBACK = "/etc/nixos/dotfiles/images/blankicon.png";
  QT_QPA_PLATFORM = "wayland";
  QT_QPA_PLATFORMTHEME = "qt5ct";
  QT6_QPA_PLATFORMTHEME = "qt6ct";
  SDL_VIDEODRIVER = "wayland";
  XDG_SESSION_TYPE = "wayland";
  GTK_USE_PORTAL = "0";
  LIBINPUT_ATTR_TRACKPOINT_ACCEL = "0.5";
};

# ============================================
# DCONF SETTINGS
# ============================================

dconf.settings = {
  "org/virt-manager/virt-manager/connections" = {
    autoconnect = ["qemu:///system"];
    uris = ["qemu:///system"];
  };
  "org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    gtk-theme = "Arc-Dark"; 
    icon-theme = "Papirus-Dark";
  };
};

# ============================================
# GTK & QT THEMING
# ============================================

gtk = {
  enable = true;
  theme = {
    name = "Arc-Dark";
    package = pkgs.arc-theme;
  };
  iconTheme = {
    name = "Papirus-Dark";
    package = pkgs.papirus-icon-theme;
  };
};

qt = {
  enable = true;
  platformTheme.name = "qt5ct";
  style.name = "kvantum";
};

# ============================================
# DESKTOP ENTRIES
# ============================================

xdg.desktopEntries = import ./dotfiles/desktop-entries.nix;

# ============================================
# DEFAULT APPS
# ============================================

xdg.mimeApps = {
  enable = true;
  defaultApplications = {
    # Images → imv
    "image/png"  = [ "imv.desktop" ];
    "image/jpeg" = [ "imv.desktop" ];
    "image/jpg"  = [ "imv.desktop" ];
    "image/webp" = [ "imv.desktop" ];
    "image/gif"  = [ "imv.desktop" ];
    # Video → VLC
    "video/mp4"        = [ "vlc.desktop" ];
    "video/x-matroska" = [ "vlc.desktop" ]; # mkv
    "video/x-msvideo"  = [ "vlc.desktop" ]; # avi
    "video/webm"       = [ "vlc.desktop" ];
    "video/quicktime"  = [ "vlc.desktop" ];
    # Others
    "application/pdf" = "firefox.desktop";
  };
};


# ============================================
# USER PACKAGES
# ============================================

home.packages = with pkgs; [

  # PROGRAMS
  arduino # arduino suite incl. GUI
  arduino-cli # CLI arduino tools
  audacious # music player
  bolt-launcher # OSRS RuneLite launcher
  chromium # ...in case Teams/etc doesn't play nice with Firefox
  drawio # flowchart/diagram tool
  firefox # the best web browser
  gimp # GNU image manipulation program
  grayjay # youtube frontend
  kdePackages.kcolorchooser # hex color tool GUI
  #kdePackages.kdenlive # video editing suite
  libreoffice-fresh # office app suite
  moonlight-qt # desktop steaming / remote access
  mpv # simple video player
  obsidian # cross-platform notes program
  obs-studio # desktop recording
  picoscope # pocket oscilloscope
  platformio # arduino TUI + utils
  prusa-slicer # 3DP slicer
  qbittorrent # peer-to-peer file sharing
  qalculate-gtk # GUI calculator
  spotify # music streaming
  tagainijisho # japanese dictionary
  thunar # GUI file manager
  vlc # video player
  webcord # webkit app for discord
  wezterm # dope-ass terminal emulator
  yazi # TUI file manager
  zoom-us # video chat software

  # UTILITIES
  bluetooth_battery # fetch info form BT devices
  cdrdao # burn CDs
  cdrkit # burn CDs
  cliphist # wayland clipboard history manager
  eww # widgets and stuff
  fastfetch # quickly fetch general system info
  fd # better file finding
  ffmpeg # video re-encoding CLI
  fzf # yazi: quick file subtree navigation
  gnome-bluetooth # GUI for bluetooth devices
  imagemagick # image editing CLI
  imv # image viewer
  jq # JSON preview in TUI file manager
  mission-center # system monitoring GUI
  networkmanagerapplet # nm-applet tray utility
  pavucontrol # audio control GUI
  playerctl # audio playback control utility
  poppler # PDF previews in TUi file manager
  resvg # yazi: SVG image preview
  ripgrep # nvim: required for telescope live_grep
  tumbler # image previews in file manager
  unrar # extract .rar files
  wofi # app launcher
  zsh-powerlevel10k # fancy ZSH PS1

  # WAYLAND, HYPRLAND, RICE
  catppuccin-kvantum # qt theme, apply with kvantum
  grim # grab images from wayland compositors
  hyprdim # dims inactive windows
  hypridle # auto idle screen lock, suspend, etc
  hyprland-workspaces # workspace integration for bars
  hyprlock # session locker
  hyprnome # GNOME-like workspace switching logic
  hyprpaper # wallpaper util
  hyprpicker # color picker tool
  hyprshot # screenshot util
  nwg-clipman # clipboard manager for wayland
  nwg-dock-hyprland # dock for hyprland
  nwg-drawer # app launcher
  nwg-icon-picker # icon selection tool
  nwg-launchers # lightweight program launchers
  nwg-look # GUI theme/config tool
  nwg-menu # basically a start menu
  nwg-panel # like a settings panel with sliders etc.
  swaybg # set desktop wallpaper; hyprpaper not work w/ wayfire
  waybar # wayland status bar
  wdisplays # wayland display settings GUI
  wev # identify keystrokes in wayland
  wlogout # wayang logout menu
  wlr-randr # like xrandr but for wayland
  wl-clipboard # enable copy-paste in wayland

  # GAMING
  dolphin-emu # GameCube/Wii emulator
  lutris # game manager like steam
  mame # arcade emulator
  nsnake # terminal snake game
  protontricks # allows for Steam proton prefixes
  wineWowPackages.waylandFull # wine for wayland
  winetricks # install DLLs/etc into wine prefixes

  # PROGRAMMING
  (python3.withPackages (ps: with ps; [
    matplotlib # self-explanatory
    pandas # data structures
    requests # HTTP client
    rich # fancy terminal output
    scipy #SciPy: lots of handy tools
  ]))
];

################################################
}           # END OF HOME.NIX # 
################################################
