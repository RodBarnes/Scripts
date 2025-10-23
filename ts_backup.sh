#!/usr/bin/env bash

# Create a snapshot using rsync command as done by TimeShift.
# One of the followin is required parameter: <backupdevice>, <label>, or <uuid> for mounting the backupdevice
# Optional parameter: <desc> -- Description of the snapshot, quote-bounded
# Optional parameter: -t -- Include to do a dry-run

# NOTE: This script expects to find the listed mountpoints.  If not present, it will fail.

source /usr/local/lib/colors

stmt=$(basename $0)
backuppath=/mnt/backup
snapshotpath=$backuppath/snapshots
timestamp=$(date +%Y-%m-%d-%H%M%S)
descfile=snapshot.desc
minspace=5000000
regex="^\S{8}-\S{4}-\S{4}-\S{4}-\S{12}$"

function printx {
  printf "${YELLOW}$1${NOCOLOR}\n"
}

function show_syntax () {
  printx "Syntax: $stmt <backup_device> [-t] [-c comment]"
  printx "Where:  <backup_device> can be a backupdevice designator (e.g., /dev/sdb6), a UUID, or a filesystem LABEL."
  printx "        [-t] means to do a test without actually creating the backup; i.e., an rsync dry-run"
  printx "        [-c comment] is a quote-bounded comment for the snapshot"
  exit
}

function mount_backup_device () {
  sudo mount $backupdevice $backuppath
  if [ $? -ne 0 ]; then
    printx "Unable to mount the backup backupdevice."
    exit 2
  fi
}

function unmount_backup_device () {
  sudo umount $backuppath
}

args=("$@")
if [ $# == 0 ]; then
  show_syntax
fi
# echo "args=${args[@]}"

# Get the backup_device
i=0
if [[ "${args[$i]}" =~ "/dev/" ]]; then
  backupdevice="${args[$i]}"
elif [[ "${args[$i]}" =~ $regex ]]; then
  backupdevice="UUID=${args[$i]}"
else
  # Assume it is a label
  backupdevice="LABEL=${args[$i]}"
fi

# Get optional parameters
i=1
check=$#
while [ $i -lt $check ]; do
  if [ "${args[$i]}" == "-t" ]; then
    dryrun=--dry-run
  elif [ "${args[$i]}" == "-c" ]; then
    ((i++))
    description="${args[$i]}"
  fi
  ((i++))
done

# echo "Device:$backupdevice"
# echo "Dry-run:$dryrun"
# echo "Desc:$description"

# Confirm running as sudo
if [[ "$EUID" != 0 ]]; then
  printx "This must be run as sudo.\n"
  exit 1
fi

mount_backup_device

# Check how much space is left
space=$(df /mnt/backup | sed -n '2p;')
IFS=' ' read dev size used avail pcent mount <<< $space
if [[ $avail -lt $minspace ]]; then
  printx "The backupdevice '$backupdevice' has less only $avail space left of the total $size."
  read -p "Do you want to proceed? (y/N) " yn
  if [[ $yn != "y" && $yn != "Y" ]]; then
    printx "Operation cancelled."
    unmount_backup_device
    exit
  fi
fi

# Creat the snapshot
if [ -n "$(find $snapshotpath -mindepth 1 -maxdepth 1 -type f -o -type d 2>/dev/null)" ]; then
  echo "Creating incremental snapshot..."
  # Snapshots exist so create incremental snapshot referencing the latest
  sudo rsync -aAX $dryrun --delete --link-dest=../latest --exclude-from=/etc/ts_excludes / "$snapshotpath/$timestamp/"
else
  echo "Creating full snapshot..."
  # This is the first snapshot so create full snapshot
  sudo rsync -aAX $dryrun --delete --exclude-from=/etc/ts_excludes / "$snapshotpath/$timestamp/"
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

unmount_backup_device
