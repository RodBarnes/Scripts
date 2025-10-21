#!/usr/bin/env bash

# List the snapshots found on the specified device and allow selecting to delete.
# One of the following is required parameter: <device>, <label>, or <uuid> for mounting the device

source /usr/local/lib/colors

stmt=$(basename $0)
mountpath=/mnt/backup
snapshotpath=$mountpath/snapshots
descfile=snapshot.desc

function printx {
  printf "${YELLOW}$1${NOCOLOR}\n"
}

function show_syntax () {
  printx "Syntax: $stmt <device>"
  printx "Where:  <device> can be a device designator (e.g., /dev/sdb6), a UUID, or a filesystem LABEL."
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
  else
    # Assume it is a label
    device="LABEL=${args[$i]}"
  fi
  ((i++))
done

# echo "Device:$device"

if [[ "$EUID" != 0 ]]; then
  printx "This must be run as sudo.\n"
  exit 1
fi

mount_device

# Get the snapshots
unset snapshots
while IFS= read -r LINE; do
  snapshots+=("${LINE}")
done < <( find $snapshotpath -mindepth 1 -maxdepth 1 -type d | sort -r | cut -d '/' -f5 )

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

printx "This will completely DELETE the snapshot '$snapshotname' and is not recoverable."
read -p "Are you sure you want to proceed? (y/N) " yn
if [[ $yn != "y" && $yn != "Y" ]]; then
  printx "Operation cancelled."
else
  sudo rm -Rf $snapshotpath/$snapshotname
  printx "'$snapshotname' has been deleted."
fi

unmount_device