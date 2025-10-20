#!/usr/bin/env bash

# Restore a backup using rsync command as done by TimeShift.
# One of the followin is required parameter: <device>, <label>, or <uuid> for mounting the device
# Optional parameter: -t -- Include to do a dry-run

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

echo "Device:$device"
echo "Label:$label"
echo "UUID:$uuid"
echo "Dry-run:$dryrun"
echo "Snapshot:$snapshotname"

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

if [ -z snapshotname ]; then
  # Get the snapshots and allow selecting
  printx "Listing backup files..."

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
  sudo rsync -aAX $dryrun --verbose --delete --exclude-from=/etc/timeshift-excludes $snapshotpath/$snapshotname/ /mnt/root/

  if [ -z $dryrun ]; then
    # Delete the timeshift.desc file from the target
   sudo rm /$descfile
  fi
else
  printx "No snapshot was identified."
fi

sudo umount $mountpath
