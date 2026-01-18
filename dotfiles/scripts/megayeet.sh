#!/bin/sh
# Color codes
CYAN='\033[1;36m'
NC='\033[0m'
PURPLE='\033[1;35m'
RED='\033[1;31m'

# --- PRINT SYSTEM INFO --------------------------------------------------------
echo -e "${CYAN}Current NixOS version:${NC}"
nixos-version
sleep 0.3

echo -e "${CYAN}Currently running NixOS generation:${NC}"
readlink /nix/var/nix/profiles/system | cut -d '-' -f 2
sleep 0.3

echo -e "${CYAN}...which was built at:${NC}"
stat -c '%y' /run/current-system
sleep 0.3

# Show flake inputs
NIXURL=$(grep 'nixpkgs.url' /etc/nixos/flake.nix | cut -d '"' -f 2)
HMURL=$(grep 'home-manager.url' /etc/nixos/flake.nix | cut -d '"' -f 2)
echo -e "${CYAN}Current flake inputs:${NC}"
echo -e "\033[1m Nixpkgs:      \033[0m $NIXURL"
echo -e "\033[1m Home-manager: \033[0m $HMURL"
sleep 0.3

echo -e "${CYAN}Last boot time:${NC}"
systemd-analyze | head -1
sleep 0.3

# --- UPDATE FLAKE -------------------------------------------------------------
echo -e "${PURPLE}Updating flake inputs...${NC}"
cd /etc/nixos

doas nix flake update
# Proper fail check
if [ $? -ne 0 ]; then
    echo -e "${RED}flake update failed.${NC}"
    exit 1
fi

echo -e "${CYAN}Updated packages:${NC}"
git diff flake.lock | grep -E '(Updated input|→)' | head -10

echo -e "${PURPLE}Committing flake changes to Git...${NC}"
git add .
git commit -m "flake update: $(date '+%Y-%m-%d %H:%M:%S')" 2>/dev/null

echo -e "${PURPLE}Syncing with GitHub...${NC}"
git pull --rebase origin main || true
git push -u origin main

echo -e "${CYAN}Git push complete. Repo is clean for rebuild.${NC}"
echo -e "\e[3m~ Flake updated successfully ~\e[0m"
sleep 0.3

# --- SYSTEM REBUILD -----------------------------------------------------------
echo -e "${PURPLE}Rebuilding system with flake...${NC}"
doas nixos-rebuild switch --upgrade --flake /etc/nixos

if [ $? -ne 0 ]; then
    echo -e "${RED}nixos-rebuild failed.${NC}"
    exit 1
fi

echo -e "${CYAN}System generation count:${NC}"
doas nix-env --list-generations --profile /nix/var/nix/profiles/system | wc -l

# --- DISK USAGE ---------------------------------------------------------------
echo -e "${CYAN}Disk usage summary:${NC}"
df -h | grep -v 'tmpfs' | grep -v 'efi'

# --- OPTIONAL SECOND GIT SYNC -------------------------------------------------
echo -e "${PURPLE}Syncing /etc/nixos to GitHub...${NC}"
git add .
git commit -m "update: $(date '+%Y-%m-%d %H:%M:%S')" 2>/dev/null

git pull --rebase origin main || true
git push -u origin main

if [ $? -eq 0 ]; then
    echo -e "${CYAN}Git push successful.${NC}"
else
    echo -e "${RED}Git push failed.${NC}"
fi

# --- DONE ---------------------------------------------------------------------
echo -e "${PURPLE}Full system upgrade complete.${NC}"
