#!/usr/bin/env zsh
STATE_FILE="/tmp/worldclock_expanded"
export TZDIR=/etc/zoneinfo

if [[ "$1" == "toggle" ]]; then
  if [[ -f "$STATE_FILE" ]]; then
    rm "$STATE_FILE"
  else
    touch "$STATE_FILE"
  fi
  exit 0
fi

JST=$(TZ="Asia/Tokyo" date +"%H:%M")
PST=$(TZ="America/Los_Angeles" date +"%H:%M")
EST=$(TZ="America/New_York" date +"%H:%M")
BST=$(TZ="Europe/London" date +"%H:%M")
HST=$(TZ="Pacific/Honolulu" date +"%H:%M")

if [[ -f "$STATE_FILE" ]]; then
  echo "$JST JST  $HST HST  $PST PST  $EST EST  $BST BST"
else
  echo "$PST"
fi
