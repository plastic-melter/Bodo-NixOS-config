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
    name = "Firefox (Odin)";
    exec = "firefox --no-remote -P Ofin";
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
  # GAMES - TOUHOU
  # ============================================
  
  th06 = {
    name = "東方06";
    genericName = "th06";
    exec = "wine /home/joe/Backups/Games/quick-access/th06/th06english/th06e.exe";
    icon = "/etc/nixos/dotfiles/images/th6.png";
    terminal = false;
    categories = [ "Game" ];
    comment = "Embodiment of Scarlet Devil";
    type = "Application";
  };
  
  th07 = {
    name = "東方07";
    genericName = "th07";
    exec = "wine /home/joe/Backups/Games/quick-access/th07/th07/th07patched.exe";
    icon = "/etc/nixos/dotfiles/images/th7.png";
    terminal = false;
    categories = [ "Game" ];
    comment = "Perfect Cherry Blossom";
    type = "Application";
  };
  
  th075 = {
    name = "東方07.5";
    genericName = "th07.5";
    exec = "wine /home/joe/Backups/Games/quick-access/th07.5/th07.5/th075.exe";
    icon = "/etc/nixos/dotfiles/images/th7.5.png";
    terminal = false;
    categories = [ "Game" ];
    comment = "Immaterial and Missing Power";
    type = "Application";
  };
  
  th08 = {
    name = "東方08";
    genericName = "th08";
    exec = "wine /home/joe/Backups/Games/quick-access/th08/th08/th08.exe";
    icon = "/etc/nixos/dotfiles/images/th8.png";
    terminal = false;
    categories = [ "Game" ];
    comment = "Imperishable Night";
    type = "Application";
  };
  
  th09 = {
    name = "東方09";
    genericName = "th09";
    exec = "wine /home/joe/Backups/Games/quick-access/th09/th09/th09.exe";
    icon = "/etc/nixos/dotfiles/images/th9.png";
    terminal = false;
    categories = [ "Game" ];
    comment = "Phantasmagoria of Flower View";
    type = "Application";
  };
  
  th095 = {
    name = "東方09.5";
    genericName = "th09.5";
    exec = "wine /home/joe/Backups/Games/quick-access/th09.5/th09.5/th095.exe";
    icon = "/etc/nixos/dotfiles/images/th9.5.png";
    terminal = false;
    categories = [ "Game" ];
    comment = "Shoot the Bullet";
    type = "Application";
  };
  
  th10 = {
    name = "東方10";
    genericName = "th10";
    exec = "wine /home/joe/Backups/Games/quick-access/th10/th10/th10.exe";
    icon = "/etc/nixos/dotfiles/images/th10.png";
    terminal = false;
    categories = [ "Game" ];
    comment = "Mountain of Faith";
    type = "Application";
  };
  
  th105 = {
    name = "東方10.5";
    genericName = "th10.5";
    exec = "wine /home/joe/Backups/Games/quick-access/th10.5/th10.5/th105.exe";
    icon = "/etc/nixos/dotfiles/images/th10.5.png";
    terminal = false;
    categories = [ "Game" ];
    comment = "Scarlet Weather Rhapsody";
    type = "Application";
  };
  
  th11 = {
    name = "東方11";
    genericName = "th11";
    exec = "wine /home/joe/Backups/Games/quick-access/th11/th11/th11.exe";
    icon = "/etc/nixos/dotfiles/images/th11.png";
    terminal = false;
    categories = [ "Game" ];
    comment = "Subterranean Animism";
    type = "Application";
  };
  
  th12 = {
    name = "東方12";
    genericName = "th12";
    exec = "wine /home/joe/Backups/Games/quick-access/th12/th12/th12.exe";
    icon = "/etc/nixos/dotfiles/images/th12.png";
    terminal = false;
    categories = [ "Game" ];
    comment = "Undefined Fantastic Object";
    type = "Application";
  };
  
  th123 = {
    name = "東方12.3";
    genericName = "th12.3";
    exec = "wine /home/joe/Backups/Games/quick-access/th12.3/th12.3/th123.exe";
    icon = "/etc/nixos/dotfiles/images/th12.3.png";
    terminal = false;
    categories = [ "Game" ];
    comment = "Hisoutensoku";
    type = "Application";
  };
  
  th125 = {
    name = "東方12.5";
    genericName = "th12.5";
    exec = "wine /home/joe/Backups/Games/quick-access/th12.5/th12.5/th125.exe";
    icon = "/etc/nixos/dotfiles/images/th12.5.png";
    terminal = false;
    categories = [ "Game" ];
    comment = "Double Spoiler";
    type = "Application";
  };
  
  th128 = {
    name = "東方12.8";
    genericName = "th12.8";
    exec = "wine /home/joe/Backups/Games/quick-access/th12.8/th12.8/th128.exe";
    icon = "/etc/nixos/dotfiles/images/th12.8.png";
    terminal = false;
    categories = [ "Game" ];
    comment = "Great Fairy Wars";
    type = "Application";
  };
  
  th13 = {
    name = "東方13";
    genericName = "th13";
    exec = "wine /home/joe/Backups/Games/quick-access/th13/th13/th13.exe";
    icon = "/etc/nixos/dotfiles/images/th13.png";
    terminal = false;
    categories = [ "Game" ];
    comment = "Ten Desires";
    type = "Application";
  };
  
  th14 = {
    name = "東方14";
    genericName = "th14";
    exec = "wine /home/joe/Backups/Games/quick-access/th14/th14/th14.exe";
    icon = "/etc/nixos/dotfiles/images/th14.png";
    terminal = false;
    categories = [ "Game" ];
    comment = "Double Dealing Character";
    type = "Application";
  };
  
  th143 = {
    name = "東方14.3";
    genericName = "th14.3";
    exec = "wine /home/joe/Backups/Games/quick-access/th14.3/th14.3/th143.exe";
    icon = "/etc/nixos/dotfiles/images/th14.3.png";
    terminal = false;
    categories = [ "Game" ];
    comment = "Impossible Spell Card";
    type = "Application";
  };
  
  th15 = {
    name = "東方15";
    genericName = "th15";
    exec = "wine /home/joe/Backups/Games/quick-access/th15/th15/th15.exe";
    icon = "/etc/nixos/dotfiles/images/th15.png";
    terminal = false;
    categories = [ "Game" ];
    comment = "Legacy of Lunatic Kingdom";
    type = "Application";
  };
  
  th16 = {
    name = "東方16";
    genericName = "th16";
    exec = "wine /home/joe/Backups/Games/quick-access/th16/th16/th16.exe";
    icon = "/etc/nixos/dotfiles/images/th16.png";
    terminal = false;
    categories = [ "Game" ];
    comment = "Hidden Star in Four Seasons";
    type = "Application";
  };
  
  th165 = {
    name = "東方16.5";
    genericName = "th16.5";
    exec = "wine /home/joe/Backups/Games/quick-access/th16.5/th16.5/th165.exe";
    icon = "/etc/nixos/dotfiles/images/th16.5.png";
    terminal = false;
    categories = [ "Game" ];
    comment = "Violet Detector";
    type = "Application";
  };
  
  th17 = {
    name = "東方17";
    genericName = "th17";
    exec = "wine /home/joe/Backups/Games/quick-access/th17/th17/th17.exe";
    icon = "/etc/nixos/dotfiles/images/th17.png";
    terminal = false;
    categories = [ "Game" ];
    comment = "Wily Beast and Weakest Creature";
    type = "Application";
  };
  
  th18 = {
    name = "東方18";
    genericName = "th18";
    exec = "wine /home/joe/Backups/Games/quick-access/th18/th18/th18.exe";
    icon = "/etc/nixos/dotfiles/images/th18.png";
    terminal = false;
    categories = [ "Game" ];
    comment = "Unconnected Marketeers";
    type = "Application";
  };
  
  th185 = {
    name = "東方18.5";
    genericName = "th18.5";
    exec = "wine /home/joe/Backups/Games/quick-access/th18.5/th18.5/th185.exe";
    icon = "/etc/nixos/dotfiles/images/th18.5.png";
    terminal = false;
    categories = [ "Game" ];
    comment = "100th Black Market";
    type = "Application";
  };
  
  th19 = {
    name = "東方19";
    genericName = "th19";
    exec = "wine /home/joe/Backups/Games/quick-access/th19/th19/th19.exe";
    icon = "/etc/nixos/dotfiles/images/th19.png";
    terminal = false;
    categories = [ "Game" ];
    comment = "Unfinished Dream of All Living Ghost";
    type = "Application";
  };

  # ============================================
  # GAMES - SEIHOU
  # ============================================
  
  seihou1 = {
    name = "西方1";
    genericName = "seihou1";
    exec = "wine /home/joe/Backups/Games/quick-access/Seihou1/seihou1.exe";
    icon = "/etc/nixos/dotfiles/images/seihou1.jpg";
    terminal = false;
    categories = [ "Game" ];
    comment = "秋霜玉 (Shuusou Gyoku)";
    type = "Application";
  };
  
  seihou2 = {
    name = "西方2";
    genericName = "seihou2";
    exec = "wine /home/joe/Backups/Games/quick-access/Seihou2/seihou2.exe";
    icon = "/etc/nixos/dotfiles/images/seihou2.jpg";
    terminal = false;
    categories = [ "Game" ];
    comment = "稀翁玉 (Kioh Gyoku)";
    type = "Application";
  };
  
  seihou3 = {
    name = "西方3";
    genericName = "seihou3";
    exec = "wine /home/joe/Backups/Games/quick-access/Seihou3/seihou3.exe";
    icon = "/etc/nixos/dotfiles/images/seihou3.jpg";
    terminal = false;
    categories = [ "Game" ];
    comment = "幡紫竜 (Banshiryuu)";
    type = "Application";
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
