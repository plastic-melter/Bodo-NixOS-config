#!/usr/bin/env zsh
LOG=/var/log/turbostat/turbostat.log
pkg=$(tail -n 600 "$LOG" | awk -F'\t' '
  /(^|\t)PkgWatt(\t|$)/ {            # header line: locate the column
    for (i=1;i<=NF;i++) if ($i=="PkgWatt") c=i
    sawhdr=1; next
  }
  sawhdr {                          # first row after a header = summary (the totals)
    if ($c != "") v=$c
    sawhdr=0
  }
  END { print v }
')
printf "%.1fW\n" "${pkg:-0}"
