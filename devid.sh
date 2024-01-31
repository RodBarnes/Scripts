#!/usr/bin/env bash

# Provided the name of the device file-system; e.g., Storage
# return the device id; e.g., sdxn

if [ -z $1 ]; then
	echo "Syntax: $(basename $0) <device_name>"
	exit 1
fi

DEVNAME=$1

DEVPATH=$(lsblk -l | grep $DEVNAME)
TMP=(${DEVPATH/ })
DEVID=${TMP[0]} 
echo $DEVID