#!/usr/bin/env bash

# List the snapshots found on the specified device.
# One of the following is required parameter: <device>, <label>, or <uuid> for mounting the device

source /usr/local/lib/colors
function printx {
  printf "${YELLOW}$1${NOCOLOR}\n"
}

function show_syntax () {
  printx "Syntax: $stmt <-d <device> | -l <label> | -u <uuid>  [-t] [-s snapshot]"
  printx "Where:  <device> is the device containing the snapshots; e.g., /dev/sdb6"
  printx "        [-l <label>] mount the backup device via its filesystem label"
  printx "        [-u <uuid>] mount the backup devices via the its UUID"
  printx "        [-t] means to do a test without actually creating the backup; i.e., an rsync dry-run"
  printx "        [snapshot] is the name (timestamp) of the snapshot to restore."
  printx "If no snapshot is specified, the device will be queried for the available snapshots."
  exit  
}

stmt=$(basename $0)

args=("$@")
if [ $# == 0 ]; then
  show_syntax
fi

# Analyze the arguments
for i in "${!args[@]}"; do
  if [ "-d" == "${args[$i]}" ]; then
    ((i++))
    device="${args[$i]}"
  elif [ "-l" == "${args[$i]}" ]; then
    ((i++))
    label="${args[$i]}"
  elif [ "-u" == "${args[$i]}" ]; then
    ((i++))
    uuid="${args[$i]}"
  elif [ "-s" == "${args[$i]}" ]; then
    ((i++))
    snapshotname="${args[$i]}"
  elif [ "-t" == "${args[$i]}" ]; then
    dryrun=--dry-run
  fi
done

# echo "Device:$device"
# echo "Label:$label"
# echo "UUID:$uuid"
# echo "Dry-run:$dryrun"
# echo "Snapshot:$snapshotname"

# Confirm a backup device was identified
if [ -z $device ] && [ -z $label ] && [ -z $uuid ]; then
  show_syntax
fi

if [ ! -e $device ]; then
  printx "There is no such device: $device."
  exit
fi

# if [[ "$EUID" != 0 ]]; then
#   printx "This must be run as sudo.\n"
#   exit
# fi

mountpath=/mnt/backup
snapshotpath=$mountpath/timeshift/snapshots
descfile=timeshift.desc

# !!!!!!!!!!!!!!!!
# Before proceeding, the /root filesystem must be mounted -- which can only be done if running from a live image or
# in some way the /root system is not in use and can be replaced.
# !!!!!!!!!!!!!!!!

if [ ! -z $device ]; then
  sudo mount $device $mountpath
elif [ ! -z $label ]; then
  sudo mount LABEL=$label $mountpath
elif [ ! -z $uuid ]; then
  sudo mount UUID=$uuid $mountpath
else
  # It should never be able to get here, but...
  printx "No device|label|uuid specified."
fi

if [ $? -ne 0 ]; then
  printx "Unable to mount the backup device."
  exit 1
fi

# Get the snapshots
unset snapshots
while IFS= read -r LINE; do
  snapshots+=("${LINE}")
done < <( find $snapshotpath -mindepth 1 -maxdepth 1 -type d | cut -d '/' -f6 )

if [ ${#snapshots[@]} -eq 0 ]; then
  printx "There are no backups on $device"
else
  printx "Listing backup files on $device"
  for snapshot in "${snapshots[@]}"; do
    printf "$snapshot: $(sudo du -sh $snapshotpath/$snapshot | awk '{print $1}') -- "
    if [ -f "$snapshotpath/$snapshot/$descfile" ]; then
      printf "$(cat $snapshotpath/$snapshot/$descfile)\n"
    else
      printf "<no desc>\n"
    fi
  done
fi

sudo umount $mountpath
