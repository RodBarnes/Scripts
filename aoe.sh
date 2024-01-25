echo "Lower main 4K screen resolution to 1680x1050"
xrandr --output HDMI-1  --mode 1680x1050 --pos 1280x0
echo "Start Age of Empires II (2013)"
xed
# flatpak run com.valvesoftware.Steam steam://rungameid/221380
echo "Press [Enter] to restore resolution back to normal"
read
echo "Restore main 4k screen resolution"
xrandr --output HDMI-1  --mode 2560x1440 --pos 1280x0
