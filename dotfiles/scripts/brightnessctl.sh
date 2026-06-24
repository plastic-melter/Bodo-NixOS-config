#!/usr/bin/env zsh
MAX=192000
STEPS=(0 1 192 1920 3840 5760 7680 9600 19200 28800 38400 48000 57600 67200 76800 86400 96000 105600 115200 124800 134400 144000 153600 163200 172800 182400 192000)

get_current() {
    brightnessctl -m | awk -F, '{print $3}'
}

find_next() {
    local cur=$1 dir=$2
    if [[ $dir == up ]]; then
        for s in $STEPS; do
            if (( s > cur )); then
                print $s
                return
            fi
        done
        print $cur
    else
        local last=$cur
        for s in $STEPS; do
            if (( s >= cur )); then
                print $last
                return
            fi
            last=$s
        done
        print $last
    fi
}

case "$1" in
    up)
        cur=$(get_current)
        nxt=$(find_next $cur up)
        brightnessctl set "$nxt"
        ;;
    down)
        cur=$(get_current)
        nxt=$(find_next $cur down)
        brightnessctl set "$nxt"
        ;;
    set)
        brightnessctl set "$2"
        ;;
    *)
        print "Usage: $0 {up|down|set <value>}"
        exit 1
        ;;
esac
