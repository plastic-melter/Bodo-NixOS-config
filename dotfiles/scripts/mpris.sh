#!/usr/bin/env zsh
esc() { print -r -- ${${${1//\&/&amp;}//</&lt;}//>/&gt;} }

build() {
  local line
  line=$(playerctl -a metadata --format $'{{status}}\t{{title}}' 2>/dev/null | grep -m1 $'^Playing\t')
  if [[ -n $line ]]; then
    jq -cn --arg t "󰎇 $(esc ${line#*$'\t'})" '{text:$t,class:"playing"}'
  elif [[ $(mpc status '%state%' 2>/dev/null) == paused ]]; then
    jq -cn --arg t "<i>󰎊 $(esc "$(mpc current -f '%title%')")</i>" '{text:$t,class:"paused"}'
  else
    line=$(playerctl -a metadata --format $'{{status}}\t{{title}}' 2>/dev/null | grep -m1 $'^Paused\t')
    [[ -n $line ]] \
      && jq -cn --arg t "<i>󰎊 $(esc ${line#*$'\t'})</i>" '{text:$t,class:"paused"}' \
      || echo '{"text":""}'
  fi
}

last=""
out() { local o=$(build); [[ $o != $last ]] && { print -r -- "$o"; last=$o; }; }

out
playerctl -a -F metadata --format '{{status}}' 2>/dev/null | while read -r _; do out; done
