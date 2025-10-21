#!/usr/bin/env bash

# Create a snapshot using rsync command as done by TimeShift.
# One of the followin is required parameter: <device>, <label>, or <uuid> for mounting the device
# Optional parameter: <desc> -- Description of the snapshot, quote-bounded
# Optional parameter: -t -- Include to do a dry-run

source /usr/local/lib/colors

stmt=$(basename $0)
mountpath=/mnt/backup
snapshotpath=$mountpath/snapshots
timestamp=$(date +%Y-%m-%d-%H%M%S)
descfile=snapshot.desc
minspace=5000000

function printx {
  printf "${YELLOW}$1${NOCOLOR}\n"
}

function show_syntax () {
  printx "Syntax: $stmt <device> [-t] [-c comment]"
  printx "Where:  <device> can be a device designator (e.g., /dev/sdb6), a UUID, or a filesystem LABEL."
  printx "        [-t] means to do a test without actually creating the backup; i.e., an rsync dry-run"
  printx "        [-c comment] is a quote-bounded comment for the snapshot"
  exit
}

function mount_device () {
  sudo mount $device $mountpath
  if [ $? -ne 0 ]; then
    printx "Unable to mount the backup device."
    exit 2
  fi
}

function unmount_device () {
  sudo umount $mountpath
}

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
    device="UUID=${args[$i]}"
  elif [ "${args[$i]}" == "-t" ]; then
    dryrun=--dry-run
  elif [ "${args[$i]}" == "-c" ]; then
    ((i++))
    description="${args[$i]}"
  else
    # Assume it is a label
    device="LABEL=${args[$i]}"
  fi
  ((i++))
done

# echo "Device:$device"
# echo "Dry-run:$dryrun"
# echo "Desc:$description"

# Confirm running as sudo
if [[ "$EUID" != 0 ]]; then
  printx "This must be run as sudo.\n"
  exit 1
fi

mount_device

# Check how much space is left
space=$(df /mnt/backup | sed -n '2p;')
IFS=' ' read dev size used avail pcent mount <<< $space
if [[ $avail -lt $minspace ]]; then
  printx "The device '$device' has less only $avail space left of the total $size."
  read -p "Do you want to proceed? (y/N) " yn
  if [[ $yn != "y" && $yn != "Y" ]]; then
    printx "Operation cancelled."
    unmount_device
    exit
  fi
fi

# Creat the snapshot
if [ -n "$(find $snapshotpath -mindepth 1 -maxdepth 1 -type f -o -type d 2>/dev/null)" ]; then
  echo "Creating incremental snapshot..."
  # Snapshots exist so create incremental snapshot referencing the latest
  sudo rsync -aAX $dryrun --delete --verbose --link-dest=../latest --exclude-from=/etc/backup-excludes / "$snapshotpath/$timestamp/"
else
  echo "Creating full snapshot..."
  # This is the first snapshot so create full snapshot
  sudo rsync -aAX $dryrun --delete --verbose --exclude-from=/etc/backup-excludes / "$snapshotpath/$timestamp/"
fi

if [ -z $dryrun ]; then
  # Update "latest"
  ln -sfn $timestamp $snapshotpath/latest

  if [ -z "$description" ]; then
    description="<no desc>"
  fi
  # Create description in the snapshot directory
  echo "$(sudo du -sh $snapshotpath/$snapshot | awk '{print $1}') -- $description" > "$snapshotpath/$timestamp/$descfile"
else
  echo "Dry run complete"
fi

unmount_device
