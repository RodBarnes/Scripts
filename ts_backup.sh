#!/usr/bin/env bash

# Create a snapshot using rsync command as done by TimeShift.
# Required parameter: <device> -- The device where backups are stored
# Optional parameter: <desc> -- Description of the snapshot, quote-bounded
# Optional parameter: -d -- Include to do a dry-run

source /usr/local/lib/colors
function printx {
  printf "${YELLOW}$1${NOCOLOR}\n"
}

function show_syntax () {
  printx "Syntax: $stmt <device> [-d] [desc]"
  printx "Where:  <device> is the device containing the snapshots; e.g., /dev/sdb6"
  printx "        [-d] means to do a dry-run"
  printx "        [desc] is a quote-bounded decription for the snapshot"
  exit  
}

stmt=$(basename $0)

args=("$@")
if [ $# == 0 ]; then
  show_syntax
fi

# Analyze the arguments
for i in "${!args[@]}"; do
  if [[ $i == 0 ]]; then
    if [ "${args[$i]}" == "?" ] || [ "${args[$i]}" == "-h" ]; then
      show_syntax
    else
      # Assume it is the device designator
      device="${args[$i]}"
    fi
  else
    if [ "-d" == "${args[$i]}" ]; then
      dryrun=--dry-run
    else
      # Assume it is a description
      description="${args[$i]}"
    fi
  fi
done

# echo "Device:$device"
# echo "Dry-run:$dryrun"
# echo "Desc:$description"

if [[ "$EUID" != 0 ]]; then
  printx "This must be run as sudo.\n"
  exit
fi

if [ ! -e $device ]; then
  printx "There is no such device: $device."
  exit
fi

mountpath=/mnt/backup
snapshotpath=$mountpath/timeshift/snapshots
timestamp=$(date +%Y-%m-%d-%H%M%S)
descfile=timeshift.desc

sudo mount -t ext4 $device $mountpath

if [ -n "$(find $snapshotpath -mindepth 1 -maxdepth 1 -type f -o -type d 2>/dev/null)" ]; then
  echo "Creating incremental snapshot..."
  # Snapshots exist so create incremental snapshot referencing the latest
  sudo rsync -aAX $dryrun --delete --verbose --link-dest=../latest --exclude-from=/etc/timeshift-excludes / $snapshotpath/$timestamp/
else
  echo "Creating full snapshot..."
  # This is the first snapshot so create full snapshot
  sudo rsync -aAX $dryrun --delete --verbose --exclude-from=/etc/timeshift-excludes / $snapshotpath/$timestamp/
fi

if [ -z $dryrun ]; then
  # Create timeshift.desc in the snapshot directory
  echo $description > $snapshotpath/$timestamp/$descfile
  
  # Update "latest"
  ln -sfn $timestamp $snapshotpath/latest
else
  echo "Dry run complete"
fi

sudo umount $device
