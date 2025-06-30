#!/usr/bin/env bash

# Show info for all non-removable block devices; aka drives

source /usr/local/lib/colors
function printx {
  printf "${YELLOW}$1${NOCOLOR}\n"
}

STMT=$(basename $0)

# if [[ "$EUID" -ne 0 ]]
# then
#   echo 'This must be run as sudo as it relies upon smartctrl to obtain information.'
#   echo
# fi

# info=() while IFS= read -r line; do
# done < <(`sudo smartctl -a /dev/sda`)

showInfo () {
  printx "/dev/$1"

  output=$(sudo smartctl -a /dev/$1)
  echo "$output" | grep "Device Model"
  echo "$output" | grep "Model Number"
  echo "$output" | grep "Serial Number"
  echo "$output" | grep "Firmware Version"
  echo "$output" | grep "User Capacity"
  echo "$output" | grep "Total NVM Capacity"
  echo "$output" | grep "Form Factor"
  echo "$output" | grep "SATA Version"
  echo "$output" | grep "Temperature"

  printf "\n"
}

lsblk -d -n -oNAME,RM | while read -r name rm; do
  if [ $rm -eq 0 ]; then
    showInfo $name
  fi
done
