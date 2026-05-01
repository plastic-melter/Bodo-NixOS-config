#!/usr/bin/env zsh

if eww active-windows | grep -q "stats"; then
  eww close stats
else
  eww open stats
fi
