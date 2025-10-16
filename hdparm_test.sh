#!/usr/bin/env bash

# Provided the name of the device file-system; e.g., Storage
# return the device id; e.g., sdxn

if [ -z $1 ]; then
	echo "Syntax: $0 <device_name>"
	exit 1
fi

devname=$1
devid=$(devid $devname)

echo "Testing $devid..."

echo "Pass #1..."
pass1=$(sudo hdparm -t --direct /dev/$devid)
tmp=(${pass1/:})
size1+=(${tmp[5]})
time1+=(${tmp[8]})
rate1+=(${tmp[11]})

echo "Pass #2..."
pass2=$(sudo hdparm -t --direct /dev/$devid)
tmp=(${pass2/:})
size2+=(${tmp[5]})
time2+=(${tmp[8]})
rate2+=(${tmp[11]})

echo "Pass #3..."
pass3=$(sudo hdparm -t --direct /dev/$devid)
tmp=(${pass3/:})
size3+=(${tmp[5]})
time3+=(${tmp[8]})
rate3+=(${tmp[11]})

expsize="( $size1 + $size2 + $size3 ) / 3.00"
avgsize=$(printf "%.2f" $(bc -l <<< $expsize))

exptime="( $time1 + $time2 + $time3 ) / 3.00"
avgtime=$(printf "%.2f \n" $(bc -l <<< $exptime))

exprate="( $rate1 + $rate2 + $rate3 ) / 3.00"
avgrate=$(printf "%.2f \n" $(bc -l <<< $exprate))

echo "Size: $avgsize Time: $avgtime Rate: $avgrate"