{ pkgs, lib, ... }:

{
  enable = true;
  plugins = [
    {
      name = "powerlevel10k";
      src = pkgs.zsh-powerlevel10k;
      file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
    }
  ];
  initContent = lib.mkOrder 550 ''
    bindkey -e
    bindkey "^[[3~" delete-char
    P10K_INSTANT_PROMPT="$XDG_CACHE_HOME/p10k-instant-prompt-''${(%):-%n}.zsh"
    [[ ! -r "$P10K_INSTANT_PROMPT" ]] || source "$P10K_INSTANT_PROMPT"
    function y() {
      local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
      yazi "$@" --cwd-file="$tmp"
      IFS= read -r -d "" cwd < "$tmp"
      [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
      rm -f -- "$tmp"
    }
  '';
  localVariables = {
    POWERLEVEL9K_SHORTEN_STRATEGY = "truncate_middle";
    POWERLEVEL9K_SHORTEN_DIR_LENGHTH = "2";
    POWERLEVEL9K_PROMPT_ON_NEWLINE = false;
    POWERLEVEL9K_PROMPT_ADD_NEWLINE = false;
    POWERLEVEL9K_LEFT_PROMPT_ELEMENTS = [
      "custom_nix"
      "dir"
    ];
    POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS = [ ];
    POWERLEVEL9K_CUSTOM_NIX = "echo 󱄅";
    POWERLEVEL9K_CUSTOM_NIX_FOREGROUND = "014";
    POWERLEVEL9K_CUSTOM_NIX_BACKGROUND = "239";
    POWERLEVEL9K_DIR_FOREGROUND = "133";
    POWERLEVEL9K_DIR_BACKGROUND = "236";
    POWERLEVEL9K_STATUS_OK_FOREGROUND = "046";
    POWERLEVEL9K_STATUS_OK_BACKGROUND = "000";
    POWERLEVEL9K_STATUS_ERROR_FOREGROUND = "203";
    POWERLEVEL9K_STATUS_ERROR_BACKGROUND = "000";
    POWERLEVEL9K_TIME_FOREGROUND = "105";
    POWERLEVEL9K_TIME_BACKGROUND = "233";
    EDITOR = "vi";
  };
  shellAliases = {
    rm = "trash-put";
    yazi = "y";
    r = "y";
    ranger = "y";
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
  };
}
