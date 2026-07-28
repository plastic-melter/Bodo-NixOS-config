D=rs.wl-gammarelay; P=/; I=rs.wl.gammarelay
UNIT=wl-gammarelay-rs

running() { systemctl --user is-active --quiet $UNIT }
prop()    { busctl --user get-property $D $P $I $1 2>/dev/null | awk '{print $2}' }
refresh() { pkill -RTMIN+11 waybar; pkill -RTMIN+12 waybar }
