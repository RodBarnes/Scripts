#!/usr/bin/env bash

# This is a convenience script to address an issue that periodically happens when a
# new kernel is received.  Sometimes, the nvidia-related module files aren't uncompressed
# and, thus, do not get included in the initramfs when it is built.
# Obviously, this script is unnecessary on a non-Nvidia system.

source /usr/local/lib/colors
function printx {
  printf "${YELLOW}$1${NOCOLOR}\n"
}

if [[ "$EUID" != 0 ]]; then
  printx "This must be run as sudo.\n"
  exit
fi

STMT=$(basename $0)

if [[ $# == 1 ]]; then
  arg=$1
  if [ $arg == "?" ] || [ $arg == "-h" ]; then
    printx "Syntax: $STMT <kernel>\nWhere:  <kernel> is the name of the initramfs to be fixed; e.g., 6.11.0-28-generic"
    printx "If no kernel is specified it will rebuild the current initramfs.\n"
    exit
  else
    KERNEL=$arg
    sudo unzstd /usr/lib/modules/$KERNEL/updates/dkms/nvidia*.ko.zst
    sudo sudo update-initramfs -u -k $KERNEL
  fi
else
  KERNEL=$(uname -r)
  sudo unzstd /usr/lib/modules/$KERNEL/updates/dkms/nvidia*.ko.zst
  sudo sudo update-initramfs -u
fi
echo KERNEL=$KERNEL