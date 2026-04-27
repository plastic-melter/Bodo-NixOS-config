#!/usr/bin/env bash
STATE_FILE="/tmp/worldclock_expanded"

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

if [[ -f "$STATE_FILE" ]]; then
  echo "$JST JST  $PST PST  $EST EST  $BST BST"
else
  echo "$PST PST"
fi
