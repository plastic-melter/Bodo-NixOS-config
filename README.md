# X13G3 (AMD) NixOS Config

Backup and reproducible config for my personal [NixOS](https://nixos.org) system, currently configured for a ThinkPad [X13 Gen 3 AMD](https://psref.lenovo.com/syspool/Sys/PDF/ThinkPad/ThinkPad_X13_Gen_3_AMD/ThinkPad_X13_Gen_3_AMD_Spec.pdf).

Config files for:
- [Hyprland](https://hyprland.org) the coolest wayland compositor with extra goodies.
- [WezTerm](https://wezfurlong.org/wezterm/), a super cool terminal.
- [Neovim](https://neovim.io), the best text editor.
- [Zsh](https://ohmyz.sh/), a great shell with a neat wrapper.
- [Waybar](https://github.com/Alexays/Waybar), a standard status bar.
- [nwg-shell](https://nwg-piotr.github.io/nwg-shell/), a set of great Wayland UI stuff.
- [Wofi](https://hg.sr.ht/~scoopta/wofi), a little application launcher. **⚠️ Replace soon**
- [Yazi](https://yazi-rs.github.io), an awesome TUI file browser.
- [AGS](https://aylur.github.io/ags/), a great way to ruin your sleep schedule. **⚠️ WIP**
- [EWW](https://elkowar.github.io/eww/), an easier way to ruin your sleep schedule **⚠️ WIP**
...and more, along with some useful scripts. 

Personal to-do list: 
- wayfire config
- explore AGS and EWW
- make things look nicer (skill issue)

Why NixOS?
- **Declarative system configuration**: your entire system lives in version-controlled text files you can read, understand, and modify in one place (no more mystery edits buried deep in /etc, forgotten PPAs, or "I ran some command 3 years ago and now I can't remember what it was")
- **Reproducible**: same config = same system bit-for-bit identical, deploy to new machines in minutes, no more messy "hope it works" install scripts
- **Atomic updates and rollbacks**: system changes are transactional, either fully applied or not at all, and trivially reversible, making your system unbreakable
- **Isolated dependencies**: multiple versions of packages coexist without conflicts, never encounter dependency hell
- **Security**: immutable system files, easy auditing of the entire system state
- **Nixpkgs**: largest (ever-growing) collection of pre-built, reproducibly packages software for any distro
