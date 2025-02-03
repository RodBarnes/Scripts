#!/usr/bin/env bash
#v1.0

# Given an identifying string for which to search the output of lsusb,
# return the full name of the device and the USB version

source /usr/local/lib/colors
function printx {
  printf "${YELLOW}$1${NOCOLOR}\n"
}

if [[ $# < 1 ]]; then
  printx "Syntax: $STMT 'string'\nWhere:  'string' is some unique value to identify the USB device; e.g., name, etc.\n"
  exit
fi

IFS=' ' read blank1 BUS blank2 DEV BALANCE <<< $(lsusb | grep ${1})
DEV="${DEV//:}"

echo $BALANCE

VERSTR=$(lsusb -D /dev/bus/usb/${BUS}/${DEV} 2> /dev/null | grep bcdUSB)
#echo VER=${VER}

IFS=' ' read label VER <<< ${VERSTR}
echo USB version: $VER
