#!/usr/bin/env bash
JST=$(TZ="Asia/Tokyo" date +"%H:%M")
PST=$(TZ="America/Los_Angeles" date +"%H:%M")
EST=$(TZ="America/New_York" date +"%H:%M")
echo "$JST JST   $PST PST  $EST EST"
