#!/usr/bin/env bash

# Given a volume label, return the device associate with the label

LABEL=$1

DEVICE=$(sudo blkid | grep LABEL=\"$LABEL\" | grep -Po '^(.+):' | sed 's/://g')

echo $DEVICE

