#!/usr/bin/env bash
#v1.0

# Given a volume label, return the device associate with the label

label=$1

device=$(sudo blkid | grep label=\"$label\" | grep -Po '^(.+):' | sed 's/://g')

echo $device

