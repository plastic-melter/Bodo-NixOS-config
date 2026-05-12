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
    fetch = "fastfetch";
    sys = "vim /etc/nixos/configuration.nix";
    home = "vim /etc/nixos/home.nix";
    flake = "vim /etc/nixos/flake.nix";
    dots = "yazi /etc/nixos/dotfiles";
    scripts = "yazi /etc/nixos/dotfiles/scripts";
    clc = "clear";
    kms = "/etc/nixos/dotfiles/scripts/kms.sh";
    notes = "vim ~/.notes.md";
    homeclean = "env --chdir=/home/joe /etc/nixos/dotfiles/scripts/homeclean.sh";
    gc = "git add -A && git commit -m";
    nxrdp = "xfreerdp /v:192.168.122.188 /u:odinn /dynamic-resolution /sound:sys:pulse";
    nxlg = "looking-glass-client -f /dev/kvmfr0";
  };
}
