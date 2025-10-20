#!/usr/bin/env bash

# List the snapshots found on the specified device.
# One of the following is required parameter: <device>, <label>, or <uuid> for mounting the device

source /usr/local/lib/colors
function printx {
  printf "${YELLOW}$1${NOCOLOR}\n"
}

function show_syntax () {
  printx "Syntax: $stmt <device>"
  printx "Where:  <device> can be a device designator (e.g., /dev/sdb6), a UUID, or a filesystem LABEL."
  exit  
}

stmt=$(basename $0)

args=("$@")
if [ $# == 0 ]; then
  show_syntax
fi

# Analyze the arguments6
regex="^\S{8}-\S{4}-\S{4}-\S{4}-\S{12}$"
i=0
check=$#
while [ $i -lt $check ]; do
  if [[ "${args[$i]}" =~ "/dev/" ]]; then
    device="${args[$i]}"
  elif [[ "${args[$i]}" =~ $regex ]]; then
    uuid="${args[$i]}"
  else
    # Assume it is a label
    label="${args[$i]}"
  fi
  ((i++))
done


# echo "Device:$device"
# echo "Label:$label"
# echo "UUID:$uuid"

# Confirm a backup device was identified
if [ -z $device ] && [ -z $label ] && [ -z $uuid ]; then
  show_syntax
fi

if [ ! -e $device ]; then
  printx "There is no such device: $device."
  exit 2
fi

if [[ "$EUID" != 0 ]]; then
  printx "This must be run as sudo.\n"
  exit 1
fi

mountpath=/mnt/backup
snapshotpath=$mountpath/timeshift/snapshots
descfile=timeshift.desc

# !!!!!!!!!!!!!!!!
# Before proceeding, the /root filesystem must be mounted -- which can only be done if running from a live image or
# in some way the /root system is not in use and can be replaced.
# !!!!!!!!!!!!!!!!

if [ ! -z $device ]; then
  snapshotdevice=$device
  sudo mount $device $mountpath
elif [ ! -z $label ]; then
  snapshotdevice=$label
  sudo mount LABEL=$label $mountpath
elif [ ! -z $uuid ]; then
  snapshotdevice=$uuid
  sudo mount UUID=$uuid $mountpath
else
  # It should never be able to get here, but...
  printx "No device|label|uuid specified."
  exit
fi

if [ $? -ne 0 ]; then
  printx "Unable to mount the backup device."
  exit 2
fi

# Get the snapshots
unset snapshots
while IFS= read -r LINE; do
  snapshots+=("${LINE}")
done < <( find $snapshotpath -mindepth 1 -maxdepth 1 -type d | sort -r | cut -d '/' -f6 )

if [ ${#snapshots[@]} -eq 0 ]; then
  printx "There are no backups on $snapshotdevice"
else
  printx "Listing backup files on $snapshotdevice"
  for snapshot in "${snapshots[@]}"; do
    if [ -f "$snapshotpath/$snapshot/$descfile" ]; then
      printf "$snapshot: $(cat $snapshotpath/$snapshot/$descfile)\n"
    else
      printf "<no desc>\n"
    fi
  done
fi

sudo umount $mountpath
