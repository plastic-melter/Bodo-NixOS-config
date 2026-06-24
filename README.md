# P14sG6 (Intel/NVIDIA) NixOS Config

Backup and reproducible config for my personal [NixOS](https://nixos.org) system, currently configured for an [X210Ai](https://macdat.net/laptops/jxtech/x210ai.php). I don't really know how to use git.

![Desktop Screenshot](./.desktop-screenie.png)
![X210Ai](./.x210ai.jpg)

## Config files for:
- [Hyprland](https://hyprland.org) a spicy wayland compositor.
- [WezTerm](https://wezfurlong.org/wezterm/), a fast cool terminal.
- [Neovim](https://neovim.io), my preferred text editor.
- [Zsh](https://ohmyz.sh/), a great shell with cool wrappers.
- [Waybar](https://github.com/Alexays/Waybar), an extensible status bar.
- [nwg-shell](https://nwg-piotr.github.io/nwg-shell/), some nice Wayland UI stuff.
- [Wofi](https://hg.sr.ht/~scoopta/wofi), an application launcher.
- [Yazi](https://yazi-rs.github.io), an efficient TUI file browser.
- [EWW](https://elkowar.github.io/eww/), handy widget maker.

...and more, along with some useful scripts. 

## To-do list (hardware):
- get NOS keyboard + palmrest
- eGPU connector installation + bezel design/print
- half-size mSATA<>SATA drive installation
- reclaim the other 48GB SODIMM for 96GB RAM
- test/resolve trackpoint<>panel interference
- test JIS keyboard scancodes and Esc/A/Z issue
- photodiode test backlight PWM
- 6-cell battery capacity tuning
- 9-cell battery issues
- resolve boot issues...
- test TB/USB-C port funtionalities
- speaker upgrade
- reinforce lid

## To-do list (software)
- see if PL limits can be set properly in BIOS and userspace
- test cooling system max load + set PL values accordingly
- suspend testing and optimization (Meteor Lake doesn't do s3)
- Win10LTSC installation + config on mSATA<>SATA drive
- resolve hypr compositing CPU util
- eww panel/buttons
- local AI optimization
- help menu for other ppl
- fcitx5 mozc IME issues (??)
- make things look nicer (ongoing skill issue)
- set up game launcher/wrapper, WINE tweaks/testing for old game library, plutonium setup 

## Why NixOS?
- **Declarative system configuration**: your entire system lives in version-controlled text files you can read, understand, and modify in one place (no more mystery edits buried deep in /etc, forgotten PPAs, config drift, or "I ran some command 3 years ago and now I can't remember what it was")
- **Reproducible**: same config = same system bit-for-bit identical, deploy to new machines in minutes, no messy "hope it works" install scripts
- **Atomic updates and rollbacks**: system changes are transactional (either fully applied or not at all) and trivially reversible, making your system unbreakable
- **Isolated dependencies**: multiple versions of packages coexist without conflicts, never encounter dependency hell
- **Security**: immutable system files, easy auditing of the entire system state
- **Nixpkgs**: largest (ever-growing) collection of pre-built, reproducibly packages software for any distro
- **Nix-shell**: per-project environments on the fly, without all the annoying complex overhead of things like docker

## X210Ai EC quirks as of June-ish 2026
- (FW bug) battery TDP setting isn't possible: currently gimped
- (FW bug) manual VRAM allocation for iGPU isn't possible
- (FW bug) <100% boot success rate (takes a minute + reboots)
- (FW bug) no custom fan curves
- (FW bug) resuming from suspend/hibernate is not reliable
