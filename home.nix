{ inputs, config, pkgs, lib, ... }:
let

  # Some dotfiles will source color codes (by pywal) from palette.nix
  # ...base and overrides are split, and merged here:
  palette = (import ./dotfiles/palette-base.nix)
         // (import ./dotfiles/palette-overrides.nix);
  themed = path: builtins.replaceStrings
    (map (k: "__${k}__") (builtins.attrNames palette))
    (builtins.attrValues palette)
    (builtins.readFile path);

  # LLM convenience launcher
  llama-up = pkgs.writeShellScriptBin "llama-up" ''
    export HSA_OVERRIDE_GFX_VERSION=10.3.0
    MODEL="$HOME/Desktop/AI/models/$(ls ~/Desktop/AI/models | ${pkgs.fzf}/bin/fzf)"
    # GPU present: let -fit auto-place as many layers as fit (partial offload).
    # No GPU: pin to CPU.
    if ${pkgs.pciutils}/bin/lspci | grep -qi "amd.*navi\|1002:73a5"; then
      GPU=(-fit on)
    else
      GPU=(-ngl 0)
    fi
    exec ${(pkgs.llama-cpp.override { rocmSupport = true; })}/bin/llama-server \
      -m "$MODEL" \
      -c 16384 -t 14 --load-mode mlock "''${GPU[@]}" \
      --host 127.0.0.1 --port 8080
  '';

  # Let GTK use palette colors pulled from wallpaper
  themeDir = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}";
  gtkNamedColors = ''
    @define-color window_bg_color #${palette.BG};
    @define-color window_fg_color #${palette.TEXT};
    @define-color view_bg_color #${palette.BG_ALT};
    @define-color view_fg_color #${palette.TEXT};
    @define-color headerbar_bg_color #${palette.SURFACE};
    @define-color headerbar_fg_color #${palette.TEXT};
    @define-color headerbar_backdrop_color #${palette.BG};
    @define-color sidebar_bg_color #${palette.BG_ALT};
    @define-color sidebar_fg_color #${palette.TEXT};
    @define-color sidebar_backdrop_color #${palette.BG};
    @define-color secondary_sidebar_bg_color #${palette.BG_ALT};
    @define-color card_bg_color #${palette.SURFACE};
    @define-color dialog_bg_color #${palette.BG_ALT};
    @define-color popover_bg_color #${palette.SURFACE};
    @define-color thumbnail_bg_color #${palette.SURFACE};
    @define-color accent_bg_color #${palette.ACCENT};
    @define-color accent_fg_color #${palette.TEXT};
    @define-color accent_color #${palette.ACCENT};
    @define-color borders #${palette.BORDER};
    @define-color theme_bg_color #${palette.BG};
    @define-color theme_fg_color #${palette.TEXT};
    @define-color theme_base_color #${palette.BG_ALT};
    @define-color theme_text_color #${palette.TEXT};
    @define-color theme_selected_bg_color #${palette.ACCENT};
    @define-color theme_selected_fg_color #${palette.TEXT};
  '';

in {

#################################################
################## HOME.NIX #####################
#################################################


imports = [
  inputs.ags.homeManagerModules.default 
];

home = {
  stateVersion = "25.11"; # DO NOT EVER EDIT THIS
  username = "joe";
  homeDirectory = "/home/joe";
};

# ============================================
# DOTFILE SOURCING
# ============================================
home.file = {
  # ags
  ".config/ags/app.tsx".source          = ./dotfiles/ags/app.tsx;
  ".config/ags/widget/Panel.tsx".source = ./dotfiles/ags/widget/Panel.tsx;
  ".config/ags/widget/Help.tsx".source  = ./dotfiles/ags/widget/Help.tsx;
  ".config/ags/lib/system.ts".source    = ./dotfiles/ags/lib/system.ts;
  ".config/ags/style.scss".text       = themed ./dotfiles/ags/style.scss;
  # eww
  ".config/eww/eww.yuck".source = ./dotfiles/eww/eww.yuck;
  ".config/eww/eww.scss".text = themed ./dotfiles/eww/eww.scss;
  ".config/eww/scripts" = {
    source = ./dotfiles/eww/scripts;
    recursive = true;
  };
  # fcitx
  ".config/fcitx5/profile".source = ./dotfiles/fcitx5/profile; # link just profile, so the home dir is still writeable
  # fastfetch
  ".config/fastfetch".source = ./dotfiles/fastfetch;
  # GTK
  ".config/gtk-4.0/assets".source = "${themeDir}/gtk-4.0/assets";
  ".config/gtk-4.0/gtk.css".text = builtins.readFile "${themeDir}/gtk-4.0/gtk.css" + "\n" + gtkNamedColors;
  # Hyprland
  ".config/hypr/hyprland.lua".text = themed ./dotfiles/hypr/hyprland.lua;
  ".config/hypr/hypridle.conf".source = ./dotfiles/hypr/hypridle.conf;
  ".config/hypr/hyprlock.conf".source = ./dotfiles/hypr/hyprlock.conf;
  ".config/hypr/hyprpaper.conf".source = ./dotfiles/hypr/hyprpaper.conf;
  ".config/hypr/hyprlock/colors-hyprlock.conf".text = themed ./dotfiles/hypr/hyprlock/colors-hyprlock.conf;
  ".config/hypr/hyprlock/colors-hyprlock.sh".text = themed ./dotfiles/hypr/hyprlock/colors-hyprlock.sh;
  ".config/hypr/hyprlock/sizes-hyprlock.conf".source = ./dotfiles/hypr/hyprlock/sizes-hyprlock.conf;
  ".config/hypr/hyprlock/sizes-hyprlock.sh".source = ./dotfiles/hypr/hyprlock/sizes-hyprlock.sh;
  ".config/hypr/hyprlock/hyprlock-run".source = ./dotfiles/hypr/hyprlock/hyprlock-run;
  ".config/hypr/hyprlock/profile.png".source = ./dotfiles/hypr/hyprlock/profile.png;
  # nwg-drawer
  ".config/nwg-drawer/drawer.css".text = themed ./dotfiles/nwg-drawer/drawer.css;
  ".config/nwg-drawer/config".source = ./dotfiles/nwg-drawer/config;
  ".config/nwg-drawer/settings".source = ./dotfiles/nwg-drawer/settings;
  # nwg-panel
  ".config/nwg-panel/menu-start.css".text = themed ./dotfiles/nwg-panel/menu-start.css;
  # rmpc
  ".config/rmpc".source = ./dotfiles/rmpc;
  # waybar
  ".config/waybar/style.css".text = themed ./dotfiles/waybar/style.css;
  ".config/waybar/config".source = ./dotfiles/waybar/config;
  # wlogout
  ".config/wlogout/style.css".text = themed ./dotfiles/wlogout/style.css;
  ".config/wlogout/config".source = ./dotfiles/wlogout/config;
  ".config/wlogout/layout".source = ./dotfiles/wlogout/layout;
  ".config/wlogout/assets" = {
    source = ./dotfiles/wlogout/assets;
    recursive = true;
  };
  ".config/wlogout/icons" = {
    source = ./dotfiles/wlogout/icons;
    recursive = true;
  };
  # wofi
  ".config/wofi/style.css".text = themed ./dotfiles/wofi/style.css;
  ".config/wofi/config".source = ./dotfiles/wofi/config;
  # wezterm
  ".config/wezterm/wezterm.lua".text = themed ./dotfiles/wezterm/wezterm.lua;
  # yazi
  ".config/yazi/yazi.toml".source = ./dotfiles/yazi/yazi.toml;
  ".config/yazi/open.toml".source = ./dotfiles/yazi/open.toml;
  ".config/yazi/theme.toml".text  = themed ./dotfiles/yazi/theme-dark.toml;
  # MISC THINGS
  ".config/plutonium".source = ./dotfiles/plutonium;
  ".config/scripts".source = ./dotfiles/scripts;
  ".config/waypaper".source = ./dotfiles/waypaper;
  ".vim/undodir/.keep".text = ""; # creates ~/.vim/undodir
};

# ============================================
# XDG STUFF (mostly ~/.config files)
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
      style=Fusion
      icon_theme=Papirus-Dark
      custom_palette=true
      color_scheme_path=/home/joe/.config/qt5ct/colors/wal.conf
    '';
  };
  "qt6ct/qt6ct.conf" = {
    force = true;
    text = ''
      [Appearance]
      style=Fusion
      icon_theme=Papirus-Dark
      custom_palette=true
      color_scheme_path=/home/joe/.config/qt6ct/colors/wal.conf
    '';
  };
  "qt5ct/colors/wal.conf".text = let p = palette; in ''
    [ColorScheme]
    active_colors=#ff${p.TEXT}, #ff${p.SURFACE}, #ff${p.SURFACE}, #ff${p.SURFACE}, #ff${p.BG}, #ff${p.BORDER}, #ff${p.TEXT}, #ff${p.TEXT}, #ff${p.TEXT}, #ff${p.BG_ALT}, #ff${p.BG}, #ff${p.BG}, #ff${p.ACCENT}, #ff${p.BG}, #ff${p.ACCENT}, #ff${p.TEXT_DIM}, #ff${p.SURFACE}, #ff${p.BG}, #ff${p.SURFACE}, #ff${p.TEXT}, #ff${p.TEXT_DIM}
    disabled_colors=#ff${p.TEXT_DIM}, #ff${p.SURFACE}, #ff${p.SURFACE}, #ff${p.SURFACE}, #ff${p.BG}, #ff${p.BORDER}, #ff${p.TEXT_DIM}, #ff${p.TEXT}, #ff${p.TEXT_DIM}, #ff${p.BG_ALT}, #ff${p.BG}, #ff${p.BG}, #ff${p.SURFACE}, #ff${p.TEXT_DIM}, #ff${p.ACCENT}, #ff${p.TEXT_DIM}, #ff${p.SURFACE}, #ff${p.BG}, #ff${p.SURFACE}, #ff${p.TEXT_DIM}, #ff${p.TEXT_DIM}
    inactive_colors=#ff${p.TEXT}, #ff${p.SURFACE}, #ff${p.SURFACE}, #ff${p.SURFACE}, #ff${p.BG}, #ff${p.BORDER}, #ff${p.TEXT}, #ff${p.TEXT}, #ff${p.TEXT}, #ff${p.BG_ALT}, #ff${p.BG}, #ff${p.BG}, #ff${p.SURFACE}, #ff${p.TEXT}, #ff${p.ACCENT}, #ff${p.TEXT_DIM}, #ff${p.SURFACE}, #ff${p.BG}, #ff${p.SURFACE}, #ff${p.TEXT}, #ff${p.TEXT_DIM}
  '';
  "qt6ct/colors/wal.conf".source =
    config.xdg.configFile."qt5ct/colors/wal.conf".source;
  # Make thunar use wezterm
  "xfce4/helpers.rc".text = "TerminalEmulator=wezterm";
  # Dunst config file (themed)
  "dunst/dunstrc".text = themed ./dotfiles/dunst/dunstrc;
  # ZSH prompt (themed)
  "starship.toml".text = themed ./dotfiles/starship/starship.toml;
  # Foliate color schemes (epub reader)
  "com.github.johnfactotum.Foliate/themes/gruvbox.json".source = ./dotfiles/foliate/custom.json;
};

# ============================================
# PROGRAMS
# ============================================

programs = {

  ags = {
    enable = true;
    configDir = null;
    extraPackages = with inputs.astal.packages.${pkgs.stdenv.hostPlatform.system}; [
      network bluetooth wireplumber mpris battery
      powerprofiles hyprland apps notifd tray cava
    ];
  };

  aichat = {
    enable = true;
    settings = {
      clients = [{
        type = "openai-compatible";
        name = "local";
        api_base = "http://127.0.0.1:8080/v1";
        models = [{ name = "local"; max_input_tokens = 16384; }];
      }];
      model = "local:local";
    };
  };

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
      safe.directory = "/etc/nixos";
    };
  };

  mangohud = {
    enable = true;
    settings = {
      fps = true;
      frametime = true;
      gpu_mem_clock = true;
      ram = true;
      throttling_status = true;   # Intel: shows thermal/power throttle reasons
      battery = true;             # laptop, and battery_watt / battery_time
      gpu_name = true;
      vulkan_driver = true;
      gpu_stats = true;
      gpu_power = true;
      gpu_temp = true;
      gpu_core_clock = true;
      cpu_power = true;
      cpu_temp = true;
      cpu_stats = true;
      cpu_mhz = true;
      vram = true;
      frame_timing = true;
      fps_metrics = "avg,1%,0.1%";
      histogram = true;
      #pci_dev = "0000:04:00.0"; # eGPU only
    };
  };

  neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;
    withRuby = false;
    withPython3 = false;
    plugins = with pkgs.vimPlugins; [
      (nvim-treesitter.withPlugins (p: builtins.attrValues p)) #Syntax highlighting and parsing
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

  obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [ obs-vkcapture ];
  };

  starship = {
    enable = true;
    enableZshIntegration = true;
  };

  waybar = {
    enable = true;
    systemd.enable = true;
  };

  zsh = import ./dotfiles/zsh/zshrc.nix { inherit pkgs lib; };

};

manual = {
  html.enable = false;
  json.enable = false;
  manpages.enable = false;
};

# ============================================
# SERVICES
# ============================================

services = {
  blueman-applet.enable = true;
  cliphist.enable = true;
  dunst.enable = true;
  gnome-keyring = {
    enable = true;
    components = [ "secrets" "ssh" ];
  };
  hypridle.enable = true;
  mpd = {
    enable = true;
    musicDirectory = "/home/joe/Music";
    network.startWhenNeeded = true;
    extraConfig = ''
      audio_output {
        type "pipewire"
        name "PipeWire"
      }
    '';
  };
  mpd-mpris.enable = true;
  network-manager-applet.enable = true;
  playerctld.enable = true;
  syncthing.enable = true;
};

# ============================================
# SYSTEMD USER SERVICES, TIMERS, ETC
# ============================================

systemd.user = {

  targets.tray = {
    Unit = {
      Description = "Home Manager System Tray";
      Requires = [ "graphical-session-pre.target" ];
    };
  };

  timers = {
    battery-notify = {
      Unit.Description = "Battery low notification timer";
      Timer = {
        OnBootSec = "1min";
        OnUnitActiveSec = "2min";
        Unit = "battery-notify.service";
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };

  services = {
    awww = {
      Unit = {
        Description = "awww daemon";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "forking";
        ExecStart = "awww-daemon";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  
    battery-notify = {
      Unit.Description = "Battery low notification";
      Service = {
        Type = "oneshot";
        ExecStart = let
          script = pkgs.writeShellScript "battery-notify" ''
            BAT=$(cat /sys/class/power_supply/BAT0/capacity)
            STATUS=$(cat /sys/class/power_supply/BAT0/status)
            if [ "$STATUS" != "Charging" ] && [ "$BAT" -le 20 ]; then
              ${pkgs.libnotify}/bin/notify-send \
                -u critical \
                -i battery-low \
                "Battery Low" "Battery at ''${BAT}%"
            fi
          '';
        in "${script}";
      };
    };
  
    fcitx5 = {
      Unit = {
        Description = "Fcitx5 input method";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.fcitx5}/bin/fcitx5";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  
    homeclean = {
      Unit = {
        Description = "Home cleanup";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "/etc/nixos/dotfiles/scripts/homeclean.sh";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  
    nwg-dock = {
      Unit = {
        Description = "nwg-dock-hyprland";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.nwg-dock-hyprland}/bin/nwg-dock-hyprland -d -p bottom";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  
    udiskie = {
      Unit.Description = "udiskie automounter";
      Service.ExecStart = "${pkgs.udiskie}/bin/udiskie --smart-tray";
      Install.WantedBy = [ "default.target" ];
    };
  
    waypaper-restore = {
      Unit = {
        Description = "Restore wallpaper";
        PartOf = [ "graphical-session.target" ];
        Requires = [ "awww.service" ];
        After = [ "awww.service" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.bash}/bin/sh -c 'until awww query >/dev/null 2>&1; do sleep 0.05; done; ${pkgs.waypaper}/bin/waypaper --restore'";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  
    wl-gammarelay-rs = {
      Unit = {
        Description = "wl-gammarelay-rs gamma/temp/brightness daemon";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.wl-gammarelay-rs}/bin/wl-gammarelay-rs";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  
    xrdb = {
      Unit = {
        Description = "Load Xresources";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.xorg.xrdb}/bin/xrdb -load %h/.Xresources";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
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
  SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/keyring/ssh";
};

systemd.user.sessionVariables = {
  QT_QPA_PLATFORMTHEME = "qt5ct";
  XDG_ICON_FALLBACK = "/etc/nixos/dotfiles/images/blankicon.png";
  QT_QPA_PLATFORM = "wayland";
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
    icon-theme = "Papirus-Dark";
  };
};

# ============================================
# GTK & QT THEMING
# ============================================

gtk = {
  enable = true;
  theme = {
    name = "Colloid-Dark-Catppuccin";
    #package = pkgs.colloid-gtk-theme.override {
    #  themeVariants = [ "default" ];
    #  colorVariants = [ "dark" ];
    #  sizeVariants  = [ "standard" ];
    #  tweaks        = [ "catppuccin" ];
    #};
    package = pkgs.adw-gtk3;
  };
  iconTheme = {
    name = "Papirus-Dark";
    package = pkgs.catppuccin-papirus-folders.override {
      flavor = "frappe";
      accent = "lavender";
    };
  };
  gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
  gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
  gtk4.theme = null; # required for stateVersion <26.05
  gtk3.extraCss = gtkNamedColors; # use colors from dotfiles/palette.nix
};

qt = {
  enable = true;
  platformTheme.name = "qtct"; # covers qt5ct and qt6ct
  style.name = "Fusion";
};

xresources.properties = {
  "Nsxiv.window.background" = "#1e1e1e";
  "Nsxiv.window.foreground" = "#d4d4d4";
};

home.pointerCursor = {
  enable = true;
  gtk.enable = true;
  package = pkgs.adwaita-icon-theme;
  name = "Adwaita";
  size = 18;
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
    # Images → nsxiv
    "image/png"  = [ "nsxiv.desktop" ];
    "image/jpeg" = [ "nsxiv.desktop" ];
    "image/jpg"  = [ "nsxiv.desktop" ];
    "image/webp" = [ "nsxiv.desktop" ];
    "image/gif"  = [ "nsxiv.desktop" ];
    # Video → VLC
    "video/mp4"        = [ "vlc.desktop" ];
    "video/x-matroska" = [ "vlc.desktop" ]; # mkv
    "video/x-msvideo"  = [ "vlc.desktop" ]; # avi
    "video/webm"       = [ "vlc.desktop" ];
    "video/quicktime"  = [ "vlc.desktop" ];
    # Others
    "application/pdf"           = "firefox.desktop";
    "text/html"                 = "firefox.desktop";
    "text/plain" = [ "nvim-wezterm.desktop" ];
    "text/x-shellscript" = [ "nvim-wezterm.desktop" ];
    "text/x-script.python" = [ "nvim-wezterm.desktop" ];
    "text/x-csrc" = [ "nvim-wezterm.desktop" ];
    "text/x-chdr" = [ "nvim-wezterm.desktop" ];
    "text/x-python" = [ "nvim-wezterm.desktop" ];
    "text/markdown" = [ "nvim-wezterm.desktop" ];
    "application/json" = [ "nvim-wezterm.desktop" ];
    "application/x-shellscript" = [ "nvim-wezterm.desktop" ];
    "x-scheme-handler/http"     = "firefox-personal.desktop";
    "x-scheme-handler/https"    = "firefox-personal.desktop";
    "x-scheme-handler/about"    = "firefox-personal.desktop";
    "x-scheme-handler/unknown"  = "firefox-personal.desktop";
  };
};


# ============================================
# USER PACKAGES
# ============================================

home.packages = with pkgs; [

  # USER APPLICATIONS / PROGRAMS
  arduino # arduino suite incl. GUI
  arduino-cli # CLI arduino tools
  audacious # music player
  bolt-launcher # OSRS RuneLite launcher
  drawio # flowchart/diagram tool
  firefox # to be replaced soon
  foliate # epub reader
  gimp # GNU image manipulation program
  grayjay # youtube frontend
  kdePackages.kcolorchooser # hex color tool GUI
  kdePackages.kdenlive # video editing suite
  kicad # open-source IDE for PCB design
  libreoffice-fresh # office app suite
  moonlight-qt # desktop steaming / remote access
  mpc # CLI to control MPD
  mpv # simple video player
  obsidian # cross-platform notes program
  obs-studio-plugins.obs-vkcapture # speedier vulkan screen recording
  openscad # text-based 3D parametric model compiler (CAD)
  picoscope # pocket oscilloscope
  platformio # arduino TUI + utils
  prusa-slicer # 3DP slicer
  qbittorrent # peer-to-peer file sharing
  qalculate-gtk # GUI calculator
  rmpc # TUI music player with images
  signal-desktop # secure messenger
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
  fastfetch # quickly fetch general system info
  fd # better file finding
  ffmpeg # video re-encoding CLI
  fzf # fuzzy finder: useful for yazi, llama, etc.
  gnome-bluetooth # GUI for bluetooth devices
  imagemagick # image editing CLI
  imv # image viewer
  jq # JSON preview in TUI file manager
  mission-center # system monitoring GUI
  networkmanagerapplet # nm-applet tray utility
  nsxiv # image viewer, more features than imv
  opustags # view and edit OPUS metadata
  pavucontrol # audio control GUI
  playerctl # audio playback control utility
  poppler # PDF previews in TUi file manager
  resvg # yazi: SVG image preview
  ripgrep # nvim: required for telescope live_grep
  simple-scan # for scanning from printer/scanner combo
  synology-drive-client # desktop client for Synology NAS
  tumbler # image previews in file manager
  unrar # extract .rar files
  vips # fast image processing for large images
  wofi # app launcher
  xfburn # GUI for burning CDs
  yt-dlp # youtube downloader

  # WAYLAND, HYPRLAND, RICE
  adwaita-qt # Qt5 Adwaita-Dark
  adwaita-qt6 # Qt6 Adwaita-Dark
  awww # swww got renamed upstream (wayland desktop background)
  eww # widgets and stuff
  gammastep # screen dimmer
  grim # grab images from wayland compositors
  gsettings-desktop-schemas # check on GTK stuff
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
  pywal # generate color palette from an image
  swaybg # set desktop wallpaper; hyprpaper not work w/ wayfire
  waybar # wayland status bar
  waypaper # wallpaper manager GUI
  wdisplays # wayland display settings GUI
  wev # identify keystrokes in wayland
  wlogout # wayang logout menu
  wlr-randr # like xrandr but for wayland
  wl-clipboard # enable copy-paste in wayland
  wl-gammarelay-applet # applet to control display temp/brightness
  wl-gammarelay-rs # dbus interface to control display temp/brightness

  # GAMING
  appimage-run # just for Slippi
  discord # sucks
  dolphin-emu # GameCube/Wii emulator
  mame # arcade emulator
  nsnake # terminal snake game
  protontricks # allows for Steam proton prefixes
  vitetris # terminal tetris
  wineWow64Packages.waylandFull # wine for wayland
  winetricks # install DLLs/etc into wine prefixes

  # PROGRAMMING
  rpiboot # flash RPi EEPROM over USB
  rpi-imager # convenient GUI to flash RPi OSes
  (python3.withPackages (ps: with ps; [
    matplotlib # self-explanatory
    pandas # data structures
    requests # HTTP client
    rich # fancy terminal output
    scipy #SciPy: lots of handy tools
  ]))

  # AI
  python312Packages.huggingface-hub # interface w/ Hugging Face Hub (open-source ML)
  llama-cpp # LLM inference
  llama-up # LLM convenience helper

  # ags
  dart-sass # ags compiles scss through this
  inputs.astal.packages.${pkgs.stdenv.hostPlatform.system}.io # astal CLI

];

################################################
}           # END OF HOME.NIX # 
################################################
