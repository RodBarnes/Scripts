#!/usr/bin/env bash

# Restore a backup using rsync command as done by TimeShift.
# Required parameter: <device> -- The device where backups are stored
# Optional parameter: -d -- Include to do a dry-run

source /usr/local/lib/colors
function printx {
  printf "${YELLOW}$1${NOCOLOR}\n"
}

function show_syntax () {
  printx "Syntax: $stmt <device> [-d] [snapshot]"
  printx "Where:  <device> is the device containing the snapshots; e.g., /dev/sdb6"
  printx "        [-d] means to do a dry-run"
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
      # Assume it is a snapshot name
      snapshotname="${args[$i]}"
    fi
  fi
done

echo "Device:$device"
echo "Dry-run:$dryrun"
echo "Snapshot:$snapshotname"

# if [[ "$EUID" != 0 ]]; then
#   printx "This must be run as sudo.\n"
#   exit
# fi

if [ ! -e $device ]; then
  printx "There is no such device: $device."
  exit
fi

mountpath=/mnt/backup
snapshotpath=$mountpath/timeshift/snapshots
descfile=timeshift.desc

# !!!!!!!!!!!!!!!!
# Before proceeding, the /root filesystem must be mounted -- which can only be done if running from a live image or
# in some way the /root system is not in use and can be replaced.
# !!!!!!!!!!!!!!!!

sudo mount -t ext4 $device $mountpath

if [ ! -z snapshotname ]; then
  # Get the snapshots and allow selecting
  printx "Listing backup files on $device"

  # Get the snapshots
  unset snapshots
  while IFS= read -r LINE; do
    snapshots+=("${LINE}")
  done < <( find $snapshotpath -mindepth 1 -maxdepth 1 -type d | cut -d '/' -f6 )

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

  echo $snapshotname
fi

if [ ! -z $snapshotname ]; then
  # Restore the snapshot
  echo "sudo rsync -aAX $dryrun --verbose --delete --exclude-from=/etc/timeshift-excludes $snapshotpath/$snapshotname/ /mnt/root/"

  # Delete the timeshift.desc file from the target
  echo "sudo rm /$descfile"
fi

sudo umount $device
