#!/usr/bin/env bash

# List the snapshots found on the specified backupdevice.
# One of the following is required parameter: <backupdevice>, <label>, or <uuid> for mounting the backupdevice

# NOTE: This script expects to find the listed mountpoints.  If not present, it will fail.

source /usr/local/lib/colors

stmt=$(basename $0)
backuppath=/mnt/backup
snapshotpath=$backuppath/snapshots
descfile=snapshot.desc
regex="^\S{8}-\S{4}-\S{4}-\S{4}-\S{12}$"
regex="^\S{8}-\S{4}-\S{4}-\S{4}-\S{12}$"

function printx {
  printf "${YELLOW}$1${NOCOLOR}\n"
}

function show_syntax () {
  printx "Syntax: $stmt <backup_device>"
  printx "Where:  <backup_device> can be a backupdevice designator (e.g., /dev/sdb6), a UUID, or a filesystem LABEL."
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

# echo "Device:$backupdevice"

if [[ "$EUID" != 0 ]]; then
  printx "This must be run as sudo.\n"
  exit 1
fi

mount_backup_device

# Get the snapshots
unset snapshots
while IFS= read -r LINE; do
  snapshot=("${LINE}")
  if [ -f "$snapshotpath/$snapshot/$descfile" ]; then
    description="$(cat $snapshotpath/$snapshot/$descfile)"
  else
    description="<no desc>"
  fi
  snapshots+=("$snapshot: $description")
done < <( find $snapshotpath -mindepth 1 -maxdepth 1 -type d | sort -r | cut -d '/' -f5 )

if [ ${#snapshots[@]} -eq 0 ]; then
  printx "There are no backups on $backupdevice"
else
  printx "Listing snapshots files on $backupdevice"
  for snapshot in "${snapshots[@]}"; do
    printf "$snapshot\n"
  done
fi

unmount_backup_device
