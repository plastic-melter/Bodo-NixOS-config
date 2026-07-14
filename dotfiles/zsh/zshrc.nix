{ pkgs, lib, ... }:
{
  enable = true;
  history.size = 1000000; # yes, one million: might wanna look back on this, decades in the future
  initContent = lib.mkOrder 550 ''
    bindkey -e
    bindkey "^[[3~" delete-char
    function y() {
      local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
      yazi "$@" --cwd-file="$tmp"
      IFS= read -r -d "" cwd < "$tmp"
      [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
      rm -f -- "$tmp"
    }
  '';
  envExtra = ''
    if [[ -z "$__NIXOS_SET_ENVIRONMENT_DONE" ]]; then
      source /etc/set-environment
    fi
  '';
  localVariables = {
    EDITOR = "vi";
  };
  shellAliases = {
    rm = "trash-put";
    yazi = "y";
    r = "y";
    ranger = "y";
    theme = "/etc/nixos/dotfiles/scripts/theme.sh";
    odin = "yazi /home/joe/Documents/Odin";
    gens = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
    yeet = "/etc/nixos/dotfiles/scripts/yeet.sh";
    megayeet = "/etc/nixos/dotfiles/scripts/megayeet.sh";
    sudo = "doas";
    sys = "vim /etc/nixos/configuration.nix";
    home = "vim /etc/nixos/home.nix";
    flake = "vim /etc/nixos/flake.nix";
    dots = "yazi /etc/nixos/dotfiles";
    scripts = "yazi /etc/nixos/dotfiles/scripts";
    kms = "/etc/nixos/dotfiles/scripts/kms.sh";
    notes = "vim ~/.notes.md";
    homeclean = "env --chdir=/home/joe /etc/nixos/dotfiles/scripts/homeclean.sh";
    gc = "git add -A && git commit -m";
    nxrdp = "xfreerdp /v:192.168.122.166 /u:odinn /dynamic-resolution /sound:sys:pulse";
    flashcards = "~/Desktop/wanikani/1to14/flashcard.sh";
    power = "doas python3 /etc/nixos/dotfiles/scripts/powerinfo.py";
    comfy-egpu = "cd ~/Desktop/AI/ComfyUI && source venv/bin/activate && HSA_OVERRIDE_GFX_VERSION=10.3.0 LD_LIBRARY_PATH=$(nix eval --raw nixpkgs#stdenv.cc.cc.lib)/lib:$(nix eval --raw nixpkgs#zstd.out)/lib python main.py --listen";
    comfy-cpu = "cd ~/Desktop/AI/ComfyUI && source venv/bin/activate && LD_LIBRARY_PATH=$(nix eval --raw nixpkgs#stdenv.cc.cc.lib)/lib:$(nix eval --raw nixpkgs#zstd.out)/lib python main.py --cpu --listen";
    ytdl = "yt-dlp -f bestaudio -x --audio-format opus --audio-quality 0 --embed-thumbnail --embed-metadata --convert-thumbnails jpg --sleep-interval 3 --max-sleep-interval 10 --sleep-requests 1 -i --no-warnings";
  };
}
