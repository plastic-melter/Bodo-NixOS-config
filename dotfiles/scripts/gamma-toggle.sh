#!/usr/bin/env zsh
source /etc/nixos/dotfiles/scripts/gamma-common.zsh

if running; then
  systemctl --user stop $UNIT
else
  systemctl --user start $UNIT
  # unit goes active before the bus name is claimed
  for i in {1..40}; do
    busctl --user get-property $D $P $I Brightness &>/dev/null && break
    sleep 0.05
  done
fi
refresh
