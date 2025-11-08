#!/usr/bin/env bash

# Show info for all non-removable block devices; aka drives

source /usr/local/lib/colors

show_syntax() {
  echo "Syntax: $(basename $0) [drive]"
  echo "Where [drive] is an optional drive designator; e.g., /dev/sda, sda, etc."
  echo "If no drive is specified, then all drives are iterated."
  exit
}

showInfo() {
  output=$(sudo smartctl -a /dev/$1)
  printx "/dev/$1"
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

# --------------------
# ------- MAIN -------
# --------------------

# Check for smartctl
if [ -z $(command -v smartctl) ]; then
  printx "This utility requires the 'smartctl' command.  It isn't present either because"
  printx " it isn't needed (i.e., there are no smart devices) or it has not been installed.\n"
  exit
fi

if [[ $# == 1 ]]; then
  arg=$1
  if [ $arg == "?" ] || [ $arg == "-h" ]; then
    show_syntax
  else
    # Assume a specific block device was provided
    specific=${arg#/dev/}
    showInfo $specific
  fi
else
  # Iterate for all block devices
  lsblk -d -n -oNAME,RM | while read -r name rm; do
    if [ $rm -eq 0 ]; then
      showInfo $name
    fi
  done
fi
