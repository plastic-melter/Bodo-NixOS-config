#!/usr/bin/env zsh

ARTIST=$(cmus-remote -Q | grep 'tag artist' | cut -b 12-)
TRACK=$(cmus-remote -Q | grep 'tag title' | cut -b 11-)
STATUS=$(cmus-remote -Q | grep status | awk '{print $2}')

case $STATUS in
    playing)
        echo -n " $TRACK ($ARTIST)"
    ;;
    paused)
        echo -n " [PAUSED]"
    ;;
    *)
        echo -n " [cmus off]"
esac
