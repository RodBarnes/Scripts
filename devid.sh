#!/usr/bin/env bash

# Provided the name of the device file-system; e.g., Storage
# return the device id; e.g., sdxn

show_syntax() {
	echo "Syntax: $(basename $0) <label>"
	echo "Where:  <label> is the filesystem label"
	exit
}

# --------------------
# ------- MAIN -------
# --------------------

if [[ $# < $1 ]]; then
  show_syntax
fi

devname=$1

devpath=$(lsblk -l | grep $devname)
tmp=(${devpath/ })
devid=${tmp[0]} 
echo $devid