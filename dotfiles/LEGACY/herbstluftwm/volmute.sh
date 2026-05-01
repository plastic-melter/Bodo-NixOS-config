#!/usr/bin/env zsh

for SINK in $(pacmd list-sinks | grep 'index:' | cut -b12-)
do
      pactl set-sink-mute $SINK toggle
done
