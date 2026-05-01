#!/usr/bin/env zsh

# sleep a sec to let the XF86 command do its thing on the backedn
sleep 0.2
# Is Wireless LAN soft blocked by rfkill? output is yes or no
isblocked=$(rfkill list | grep -A 1 'Wireless LAN' | grep Soft | awk '{print $3}')

if [ "$isblocked" = "no" ]; then
    # If soft blocked, unblock it
#    rfkill unblock wlan
    notify-send "WiFi enabled" "Wireless LAN has been enabled."
elif [ "$isblocked" = "yes" ]; then
    # If not soft blocked, block it
#    rfkill block wlan
    notify-send "WiFi disabled" "Wireless LAN has been disabled."
else
    notify-send "XF86WLAN Error" "Could not determine the WiFi status."
fi

