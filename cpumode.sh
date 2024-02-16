#!/usr/bin/env bash
# Originally from https://unix.cafe/wp/en/2020/07/toggle-between-cpu-powersave-and-performance-in-linux/
# ----------------------------------------------------------------------

# usage menu
function show_usage() { #{{{
    echo -e "Syntax:\t$0 powersave|performance|current"
    echo -e "\tpowersave\tSet CPU in power-saving mode"
    echo -e "\tperformance\tSet CPU in performance mode"
    echo -e "\tcurrent\t\tShow the current CPU mode"
    echo -e "\thelp\t\tShow this menu"
    exit 1
} #}}}

# get cpu mode
function getcpumode() {
    cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
}

# set cpu mode
function setcpumode() {
    [ $1 != 'powersave' -a $1 != 'performance' ] && ee 'Invalid given value..'
    [ $(getcpumode) == $1 ] && ee "It's already in '$1' mode"
    echo $1 | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
}

if [ "$1" == "help" ]; then
    show_usage; exit 1
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
    *)              ee "Try: $0 help"                   ;;
esac