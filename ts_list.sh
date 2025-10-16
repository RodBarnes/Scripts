#!/usr/bin/env bash

# List the backups on the specified drive.
# Required parameter: <device> -- the device to be mounted which contains the backups

source /usr/local/lib/colors
function printx {
  printf "${YELLOW}$1${NOCOLOR}\n"
}

backuppath=/mnt/backup/timeshift/snapshots
stmt=$(basename $0)

function show_syntax () {
  printx "Syntax: $stmt <device>\nWhere:  <device> is the device containing the backups; e.g., /dev/sdb6"
  exit  
}

if [[ $# == 1 ]]; then
  arg=$1
  if [ $arg == "?" ] || [ $arg == "-h" ]; then
    show_syntax
  else
    device=$arg
  fi
else
  show_syntax
fi

if [[ "$EUID" != 0 ]]; then
  printx "This must be run as sudo.\n"
  exit
fi

printx "Listing backup files on $device"

sudo mount -t ext4 $device /mnt/backup

# Get the backups
unset snapshots
while IFS= read -r LINE; do
  snapshots+=("${LINE}")
done < <( find $backuppath -mindepth 1 -maxdepth 1 -type d | cut -d '/' -f6 )

# Display the backups
for snapshot in "${snapshots[@]}"; do
  printf "$snapshot: "
  if [ -f "$backuppath/$snapshot/timeshift.desc" ]; then
    printf "$(cat $backuppath/$snapshot/timeshift.desc)\n"
  else
    printf "<no desc>\n"
  fi
done

sudo umount /dev/sdb6
