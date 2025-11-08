#!/usr/bin/env bash
# Originally from https://unix.cafe/wp/en/2020/07/toggle-between-cpu-powersave-and-performance-in-linux/
# ----------------------------------------------------------------------

show_syntax() {
    echo "Syntax: $(basename $0) powersave|performance|current"
    echo "        powersave    Set CPU in power-saving mode"
    echo "        performance  Set CPU in performance mode"
    echo "        current      Show the current CPU mode"
    echo "        help         Show this menu"
    exit
}

# get cpu mode
getcpumode() {
  cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
}

setcpumode() {
  [ $1 != 'powersave' -a $1 != 'performance' ] && ee 'Invalid given value..'
  [ $(getcpumode) == $1 ] && ee "It's already in '$1' mode"
  echo $1 | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
}

# --------------------
# ------- MAIN -------
# --------------------

# set cpu mode

if [ "$1" == "help" ]; then
    show_syntax
fi

# make sure we have root's power
if [ $UID -ne 0 ]; then
    echo 'Script must be executed by "root" or prefixed with "sudo".'
fi

# get & set actions
case "$1" in
    performance)    setcpumode performance; exit 0      ;;
    powersave)      setcpumode powersave; exit 0        ;;
    current|get)    getcpumode; exit 0                  ;;
    help)           show_usage                          ;;
    *)              echo "Try: $0 help"                 ;;
esac