#!/usr/bin/env bash
#v1.0

# Given a volume label, return the device associate with the label

LABEL=$1

DEVICE=$(sudo blkid | grep LABEL=\"$LABEL\" | grep -Po '^(.+):' | sed 's/://g')

echo $DEVICE

