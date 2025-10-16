#!/usr/bin/env bash

# List the backups on the specified drive.
# Required parameter: <device> -- the device to be mounted which contains the backups

source /usr/local/lib/colors
function printx {
  printf "${YELLOW}$1${NOCOLOR}\n"
}

function show_syntax () {
  printx "Syntax: $stmt <device>\nWhere:  <device> is the device containing the backups; e.g., /dev/sdb6"
  exit  
}

stmt=$(basename $0)

if [[ "$EUID" != 0 ]]; then
  printx "This must be run as sudo.\n"
  exit
fi

if [[ $# == 1 ]]; then
  arg=$1
  if [ $arg == "?" ] || [ $arg == "-h" ]; then
    show_syntax
  else
    # Assume the argument is a device designator
    device=$arg
  fi
else
  show_syntax
fi

if [ ! -e $device ]; then
  printx "There is no such device: $device."
  exit
fi

mountpath=/mnt/backup
backuppath=$mountpath/timeshift/snapshots
descfile=timeshift.desc

printx "Listing backup files on $device"

sudo mount -t ext4 $device $mountpath

# Get the backups
unset snapshots
while IFS= read -r LINE; do
  snapshots+=("${LINE}")
done < <( find $backuppath -mindepth 1 -maxdepth 1 -type d | cut -d '/' -f6 )

# Display the backups and descriptions
for snapshot in "${snapshots[@]}"; do
  printf "$snapshot: "
  if [ -f "$backuppath/$snapshot/$descfile" ]; then
    printf "$(cat $backuppath/$snapshot/$descfile)\n"
  else
    printf "<no desc>\n"
  fi
done

sudo umount $device
