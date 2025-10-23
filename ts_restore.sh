#!/usr/bin/env bash

# Restore a backup using rsync command as done by TimeShift.
# One of the followin is required parameter: <device>, <label>, or <uuid> for mounting the device
# Optional parameter: -t -- Include to do a dry-run

# NOTE: This script expects to find the listed mountpoints.  If not present, it will fail.

source /usr/local/lib/colors

stmt=$(basename $0)
backuppath=/mnt/backup
restorepath=/mnt/restore
snapshotpath=$backuppath/snapshots
descfile=backup.desc
regex="^\S{8}-\S{4}-\S{4}-\S{4}-\S{12}$"

function printx {
  printf "${YELLOW}$1${NOCOLOR}\n"
}

function show_syntax () {
  printx "Syntax: $stmt <backup_device> <restore_device> [-t] [-s snapshot]"
  printx "Where:  <backup_device> and <restore_device> can be a device designator (e.g., /dev/sdb6), a UUID, or a filesystem LABEL."
  printx "        [-t] means to do a test without actually creating the backup; i.e., an rsync dry-run"
  printx "        [snapshot] is the name (timestamp) of the snapshot to restore."
  printx "If no snapshot is specified, the device will be queried for the available snapshots."
  exit  
}

function mount_backup_device () {
  sudo mount $device $backuppath
  if [ $? -ne 0 ]; then
    printx "Unable to mount the backup device."
    exit 2
  fi
}

function unmount_backup_device () {
  sudo umount $backuppath
}

function mount_restore_device () {
  sudo mount $device $restorepath
  if [ $? -ne 0 ]; then
    printx "Unable to mount the restore device."
    exit 2
  fi
}

function unmount_restore_device () {
  sudo umount $restorepath
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

# Get the restore_device
i=1
if [[ "${args[$i]}" =~ "/dev/" ]]; then
  restoredevice="${args[$i]}"
elif [[ "${args[$i]}" =~ $regex ]]; then
  restoredevice="UUID=${args[$i]}"
else
  # Assume it is a label
  restoredevice="LABEL=${args[$i]}"
fi

# Get optional parameters
i=2
check=$#
while [ $i -le $check ]; do
  if [ "${args[$i]}" == "-t" ]; then
    dryrun=--dry-run
  elif [ "${args[$i]}" == "-s" ]; then
    ((i++))
    snapshotname="${args[$i]}"
  fi
  ((i++))
done

echo "Backup device:$backupdevice"
echo "Restore device:$restoredevice"
echo "Dry-run:$dryrun"
echo "Snapshot:$snapshotname"

exit

if [[ "$EUID" != 0 ]]; then
  printx "This must be run as sudo.\n"
  exit
fi

if [ ! -e $restoredevice ]; then
  printx "There is no such device: $restoredevice."
  exit
fi

mount_restore_device
mount_backup_device

if [ -z $snapshotname ]; then
  # Get the snapshots and allow selecting
  printx "Listing backup files..."

  # Get the snapshots
  unset snapshots
  while IFS= read -r LINE; do
    snapshots+=("${LINE}")
  done < <( find $snapshotpath -mindepth 1 -maxdepth 1 -type d | cut -d '/' -f5 )

  select selection in "${snapshots[@]}" "Cancel"; do
    case ${selection} in
      "Cancel")
        # If the user decides to cancel...
        break
        ;;
      *)
        snapshotname=$selection
        break
        ;;
    esac
  done
fi

if [ ! -z $snapshotname ]; then
  printx "This will completely OVERWRITE the operating system on '$snapshotname' and is NOT recoverable."
  read -p "Are you sure you want to proceed? (y/N) " yn
  if [[ $yn != "y" && $yn != "Y" ]]; then
    printx "Operation cancelled."
    unmount_backup_device
    unmount_restore_device
    exit
  else
    # Restore the snapshot
    echo "sudo rsync -aAX $dryrun --delete $snapshotpath/$snapshotname/ /mnt/restore/"

    if [ -z $dryrun ]; then
      # Delete the description file from the target
      echo "sudo rm $snapshotpath/$descfile"
    fi
  fi
else
  printx "No snapshot was identified."
fi

unmount_backup_device
unmount_restore_device
