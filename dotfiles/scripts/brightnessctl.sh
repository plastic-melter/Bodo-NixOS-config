#!/usr/bin/env zsh
MAX=38787
# Same % steps: 0 0ish 0ish 1 2 3 4 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100
STEPS=(0 1 100 388 776 1163 1551 1939 3879 5818 7757 9697 11636 13576 15515 17454 19394 21333 23272 25212 27151 29090 31030 32969 34909 36848 38787)

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
