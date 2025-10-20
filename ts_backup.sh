#!/usr/bin/env bash

# Create a snapshot using rsync command as done by TimeShift.
# One of the followin is required parameter: <device>, <label>, or <uuid> for mounting the device
# Optional parameter: <desc> -- Description of the snapshot, quote-bounded
# Optional parameter: -t -- Include to do a dry-run

source /usr/local/lib/colors
function printx {
  printf "${YELLOW}$1${NOCOLOR}\n"
}

function show_syntax () {
  printx "Syntax: $stmt <-d <device> | -l <label> | -u <uuid>  [-t] [-c comment]"
  printx "Where:  [-d <device>] mount the backup device via its device designator; e.g., /dev/sdb6"
  printx "        [-l <label>] mount the backup device via its filesystem label"
  printx "        [-u <uuid>] mount the backup devices via the its UUID"
  printx "        [-t] means to do a test without actually creating the backup; i.e., an rsync dry-run"
  printx "        [-c comment] is a quote-bounded comment for the snapshot"
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
  elif [ "-c" == "${args[$i]}" ]; then
    ((i++))
    description="${args[$i]}"
  elif [ "-t" == "${args[$i]}" ]; then
    dryrun=--dry-run
  fi
done

# echo "Device:$device"
# echo "Label:$label"
# echo "UUID:$uuid"
# echo "Dry-run:$dryrun"
# echo "Desc:$description"

# Confirm a backup device was identified
if [ -z $device ] && [ -z $label ] && [ -z $uuid ]; then
  show_syntax
fi

# Confirm the specified device exists
if [ ! -e $device ]; then
  printx "There is no such device: $device."
  exit
fi

# Confirm running as sudo
if [[ "$EUID" != 0 ]]; then
  printx "This must be run as sudo.\n"
  exit
fi

mountpath=/mnt/backup
snapshotpath=$mountpath/timeshift/snapshots
timestamp=$(date +%Y-%m-%d-%H%M%S)
descfile=timeshift.desc

if [ ! -z $device ]; then
  sudo mount -t ext4 $device $mountpath
elif [ ! -z $label ]; then
  sudo mount -t ext4 LABEL=$label $mountpath
elif [ ! -z $uuid ]; then
  sudo mount -t ext4 UUID=$uuid $mountpath
else
  # It should never be able to get here, but...
  printx "No device|label|uuid specified."
fi

if [ $? -ne 0 ]; then
  printx "Unable to mount the backup device."
  exit 1
fi

if [ -n "$(find $snapshotpath -mindepth 1 -maxdepth 1 -type f -o -type d 2>/dev/null)" ]; then
  echo "Creating incremental snapshot..."
  # Snapshots exist so create incremental snapshot referencing the latest
  sudo rsync -aAX $dryrun --delete --verbose --link-dest=../latest --exclude-from=/etc/timeshift-excludes / "$snapshotpath/$timestamp/"
else
  echo "Creating full snapshot..."
  # This is the first snapshot so create full snapshot
  sudo rsync -aAX $dryrun --delete --verbose --exclude-from=/etc/timeshift-excludes / "$snapshotpath/$timestamp/"
fi

if [ -z $dryrun ]; then
  # Update "latest"
  ln -sfn $timestamp $snapshotpath/latest

  if [ -z "$description" ]; then
    description="<no desc>"
  fi
  # Create timeshift.desc in the snapshot directory
  echo "$(sudo du -sh $snapshotpath/$snapshot | awk '{print $1}') -- $description" > "$snapshotpath/$timestamp/$descfile"
else
  echo "Dry run complete"
fi

sudo umount $mountpath
