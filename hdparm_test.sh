#!/usr/bin/env bash

# Provided the name of the device file-system; e.g., Storage
# return the device id; e.g., sdxn

if [ -z $1 ]; then
	echo "Syntax: $0 <device_name>"
	exit 1
fi

DEVNAME=$1
DEVID=$(devid $DEVNAME)

echo "Testing $DEVID..."

echo "Pass #1..."
PASS1=$(sudo hdparm -t --direct /dev/$DEVID)
TMP=(${PASS1/:})
SIZE1+=(${TMP[5]})
TIME1+=(${TMP[8]})
RATE1+=(${TMP[11]})

echo "Pass #2..."
PASS2=$(sudo hdparm -t --direct /dev/$DEVID)
TMP=(${PASS2/:})
SIZE2+=(${TMP[5]})
TIME2+=(${TMP[8]})
RATE2+=(${TMP[11]})

echo "Pass #3..."
PASS3=$(sudo hdparm -t --direct /dev/$DEVID)
TMP=(${PASS3/:})
SIZE3+=(${TMP[5]})
TIME3+=(${TMP[8]})
RATE3+=(${TMP[11]})

EXPSIZE="( $SIZE1 + $SIZE2 + $SIZE3 ) / 3.00"
AVGSIZE=$(printf "%.2f" $(bc -l <<< $EXPSIZE))

EXPTIME="( $TIME1 + $TIME2 + $TIME3 ) / 3.00"
AVGTIME=$(printf "%.2f \n" $(bc -l <<< $EXPTIME))

EXPRATE="( $RATE1 + $RATE2 + $RATE3 ) / 3.00"
AVGRATE=$(printf "%.2f \n" $(bc -l <<< $EXPRATE))

echo "Size: $AVGSIZE Time: $AVGTIME Rate: $AVGRATE"