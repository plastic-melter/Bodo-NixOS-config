#!/usr/bin/env bash
# Extracted from pinkSakoora/sakoora.hyprlock (MIT)
# Generates sizes-hyprlock.conf and sizes-hyprlock.sh based on current display resolution.

CONF_OUT="${1:-./sizes-hyprlock.conf}"
SH_OUT="${2:-./sizes-hyprlock.sh}"

resolution=$(hyprctl monitors | grep -m1 -oP '\S.{1,}(?=@)')
width=$(echo "$resolution" | cut -dx -f1)
height=$(echo "$resolution" | cut -dx -f2)
[ $((4*height/9)) -ge $((width/4)) ] && pw=$((width/4)) || pw=$((4*height/9))
pp=$((pw/12))

cat > "$CONF_OUT" <<EOF
#################
### UNIVERSAL ###
#################
\$body_font = $((pp/2))
\$huge_font = $((pp*5/2))
\$heading_font = $((pp*5/4))
\$large_font = $((pp*3/4))
\$small_font = $((pp*3/8))

################
### TOP LEFT ###
################
\$top_left_offset = $((-pw/2-pp/2)), $((pw/4+pp/2))
\$pw_box_offset = $((-pw/2-pp/2)), $((height/2-pp*3/2))
\$un_box_offset = $((-pw/2-pp/2)), $((height/2+pp*3/2))
\$pw_text_offset = $((width/2-pw+pp)), $((height/2))
\$un_text_offset = $((width/2-pw+pp)), $((height/2+pp*3))
\$login_text_offset = $((-pw/2-pp/2)), $((height/2+pp*5))
\$hostname_text_offset = $((-pw/2-pp/2)), $((height/2+pp*15/2))
\$un_value_offset = $((width/2-pw+pp)), $((height/2+pp*9/4))
\$input_field_offset = $((width/2-pw+pp/2)), $((height/2-pp*3/2))
\$top_left_size = $pw
\$container_box_size = $((pw-pp*2)), $((pp*5/2))
\$input_field_size = $((pw-pp*2)), $((pp*2))

###################
### BOTTOM LEFT ###
###################
\$bottom_left_offset = $((-pw/2-pp/2)), $((-pw/2-pp/2))
\$time_text_offset = $((-pw/2-pp/2)), $((-height/2-pw/4-pp*3/2))
\$uptime_ltext_offset = $((width/2-pw+pp*5/2)), $((height/2-pw*3/4+pp/2))
\$uptime_rtext_offset = $((-width/2-pp*7/2)), $((height/2-pw*3/4+pp/2))
\$bottom_left_size = $((pw/2))

#############
### RIGHT ###
#############
\$right_offset = $((pw/2+pp/2)), 0
\$right_bottom_box_offset = $((pw/2+pp/2)), $((height/2-pw))
\$network_box_offset = $((pw*3/16+pp*3/2)), $((height/2-pw*5/8+pp*2))
\$bluetooth_box_offset = $((pw*9/16+pp*5/2)), $((height/2-pw*5/8+pp*2))
\$power_box_offset = $((pw/2+pp/2)), $((height/2-pw+pp))
\$image_offset = $((pw/2+pp/2)), $((height/2+pw*1/8+pp*5))
\$media_symbol_offset = $((pw/2+pp/2)), $((-height/2+pp/2))
\$network_symbol_offset = $((pw*3/16+pp*3/2)), $((height/2-pw*5/8+pp*7/2))
\$bluetooth_symbol_offset = $((pw*9/16+pp*5/2)), $((height/2-pw*5/8+pp*7/2))
\$day_value_offset = $((pw/2+pp/2)), $((height/2+pw*1/8+pp*2))
\$date_value_offset = $((pw/2+pp/2)), $((height/2+pw*1/8+pp))
\$media_content_value_offset = $((pw/2+pp/2)), $((-height/2-pp/2))
\$media_player_value_offset = $((pw/2+pp/2)), $((-height/2-pp*5/4))
\$network_value_offset = $((pw*3/16+pp*3/2)), $((height/2-pw*5/8+pp*11/4))
\$bluetooth_value_offset = $((pw*9/16+pp*5/2)), $((height/2-pw*5/8+pp*11/4))
\$power_status_value_offset = $((pw/2+pp/2)), $((height/2-pw+pp*2))
\$power_percent_value_offset = $((pw/2+pp/2)), $((height/2-pw+pp*5/2))
\$power_indicator_value_offset = $((pw/2+pp/2)), $((height/2-pw+pp*4))
\$right_size = $pw
\$right_bottom_box_size = $pw, $((pw*9/8))
\$power_box_size = $((pw-pp*2)), $((pw*3/8))
\$connection_box_size = $((pw*3/8)), $((pw/4))
\$image_size = $((pw/3))
EOF

cat > "$SH_OUT" <<EOF
initial_cutout_offset=$((width/2-pw))+$((height/2-pp/2-pw))
top_left_offset=0+$((pw*1/3-pp/2))
bottom_left_offset=0+$((pw*4/3-pp*3/2))
right_offset=$((pw+pp))+0
initial_cutout_size=$((pw*2+pp))x$((pw*2))
top_left_size=${pw}x$pw
bottom_left_size=${pw}x$((pw/2))
right_size=${pw}x$((pw*2))
EOF

echo "Generated: $CONF_OUT"
echo "Generated: $SH_OUT"
