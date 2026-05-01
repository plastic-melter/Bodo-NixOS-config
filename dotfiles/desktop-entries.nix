# Desktop Entry Definitions
{
  # ============================================
  # BROWSER PROFILES
  # ============================================
  
  firefox-personal = {
    name = "Firefox (Personal)";
    exec = "firefox --no-remote -P Personal";
    terminal = false;
    icon = "firefox";
    categories = [ "Network" "WebBrowser" ];
  };
  
  firefox-work = {
    name = "Firefox (Work)";
    exec = "firefox --no-remote -P Odin";
    terminal = false;
    icon = "firefox";
    categories = [ "Network" "WebBrowser" ];
  };

  # ============================================
  # UTILITIES
  # ============================================

  picoscope = {
    name = "picoscope";
    genericName = "picoscope";
    exec = "picoscope";
    icon = "/etc/nixos/dotfiles/images/pico-logo.png";
    terminal = false;
    categories = [ "Utility" ];
    comment = "PicoScope USB Oscilloscope";
    type = "Application";
  };
  
  hyprpicker = {
    name = "hyprpicker";
    genericName = "color-picker";
    exec = "foot -e hyprpicker";
    icon = "/etc/nixos/dotfiles/images/picker.png";
    terminal = true;
    categories = [ "Utility" ];
    comment = "Color picker tool from hyprwm";
    type = "Application";
  };
  
  radeontop = {
    name = "GPU Monitor";
    genericName = "radeontop";
    exec = "foot -e radeontop";
    icon = "/etc/nixos/dotfiles/images/gpu.png";
    terminal = false;
    categories = [ "Utility" ];
    comment = "Radeon GPU monitor (TUI)";
    type = "Application";
  };
  
  zenmonitor = {
    name = "Zenmonitor"; 
    icon = "/etc/nixos/dotfiles/images/amd.png";
    exec = "zenmonitor";
    categories = [ "Utility" ];
    type = "Application";
  };
  
  pavucontrol = {
    name = "Pavucontrol";
    exec = "pavucontrol";
    icon = "/etc/nixos/dotfiles/images/mixer.png";
    terminal = false;
    categories = [ "Utility" ];
    comment = "Pulseaudio volume control / mixer";
    type = "Application";
  }; 
  
  qt5ct = {
    name = "qt5 config tool";
    exec = "qt5ct";
    icon = "/etc/nixos/dotfiles/images/qtlogo.png";
    terminal = false;
    categories = [ "Utility" ];
    comment = "GUI configuration tool for qt5";
    type = "Application";
  }; 
  
  qt6ct = {
    name = "qt6 config tool";
    exec = "qt6ct";
    icon = "/etc/nixos/dotfiles/images/qtlogo.png";
    terminal = false;
    categories = [ "Utility" ];
    comment = "GUI configuration tool for qt6";
    type = "Application";
  }; 
  
  htop = {
    name = "htop";
    exec = "foot -w 1500x750-e htop";
    icon = "/etc/nixos/dotfiles/images/htop.png";
  };
  
  imv = {
    name = "imv";
    genericName = "imv";
    exec = "imv %f";
    terminal = false;
    categories = [ "Graphics" ];
    mimeType = [ "image/png" "image/jpeg" "image/jpg" "image/gif" "image/webp" ];
  };

  vlc = {
    name = "VLC Media Player";
    exec = "vlc %U";
    terminal = false;
    mimeType = [
      "video/mp4"
      "video/x-matroska"
      "video/webm"
      "video/avi"
      "video/x-msvideo"
      "video/quicktime"
      "audio/mpeg"
      "audio/x-wav"
    ];
  };

  gimp = {
    name = "GIMP";
    exec = "gimp %U";
    terminal = false;
    mimeType = [
      "image/png"
      "image/jpeg"
      "image/gif"
      "image/bmp"
      "image/webp"
      "image/tiff"
    ];
  };

  mpv = {
    name = "mpv Media Player";
    exec = "mpv %U";
    terminal = false;
    mimeType = [
      "video/mp4"
      "video/x-matroska"
      "video/webm"
      "video/avi"
      "video/x-msvideo"
      "video/quicktime"
      "video/mpeg"
      "audio/mpeg"
      "audio/x-wav"
      "audio/flac"
      "audio/ogg"
    ];
  };

  # ============================================
  # GAMES - OTHER
  # ============================================
  
  bwr = {
    name = "Blue Wish Resurrection Plus";
    genericName = "BWR";
    exec = "WINEDLLOVERRIDES=winemenubuilder.exe=d wine /home/joe/Backups/Games/quick-access/BWR/BWR_PLUS1.11/BWRP1.11.exe";
    icon = "/home/joe/Backups/Games/quick-access/BWR/BWR_PLUS1.11/htm_data/title_bwrp.gif";
    terminal = true;
    categories = [ "Game" ];
    comment = "Blue Wish Resurrection Plus 1.11";
    type = "Application";
  };
  
  brda = {
    name = "Blue Revolver";
    genericName = "BRDA";
    exec = "/etc/nixos/dotfiles/scripts/BRDA.sh";
    icon = "/home/joe/Backups/Games/quick-access/BRDA/Blue.Revolver.v1.52/Blue.Revolver.v1.52/Soundtrack/mp3/Cover.jpg";
    terminal = false;
    categories = [ "Game" ];
    comment = "DRM-free copy!";
    type = "Application";
  };

  slippi = {
    name = "Slippi";
    genericName = "Slippi";
    exec = "appimage-run /home/joe/Backups/Games/Slippi-Launcher-2.13.3-x86_64.AppImage";
    icon = "/etc/nixos/dotfiles/images/shine.png";
    terminal = false;
    categories = [ "Game" ];
    comment = "Melee netplay!";
    type = "Application";
  };

  # ============================================
  # HIDDEN ENTRIES
  # ============================================
  
  protontricks = {
    name = "Protontricks";
    noDisplay = true;
  };
  kbd-layout-viewer5 = {
    name = "Keyboard Layout Viewer";
    noDisplay = true;
  };
  kvantum = {
    name = "Kvantum";
    noDisplay = true;
  };
  xterm = {
    name = "XTerm";
    noDisplay = true;
  };
  android-file-transfer = {
    name = "Android File Transfer";
    noDisplay = true;
  };
}
