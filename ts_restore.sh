#!/usr/bin/env bash

# Restore a backup using rsync command as done by TimeShift.
# One of the followin is required parameter: <device>, <label>, or <uuid> for mounting the device
# Optional parameter: -t -- Include to do a dry-run

# NOTE: This script expects to find the listed mountpoints.  If not present, they will be created.

source /usr/local/lib/colors

stmt=$(basename $0)
backuppath=/mnt/backup
restorepath=/mnt/restore
snapshotpath=$backuppath/snapshots
descfile=backup.desc
dryrun_log=ts_restore_dryrun.log
regex="^\S{8}-\S{4}-\S{4}-\S{4}-\S{12}$"

function printx {
  printf "${YELLOW}$1${NOCOLOR}\n"
}

function show_syntax () {
  printx "Syntax: $stmt <backup_device> <restore_device> [-t] [-g <boot_device>] [-s snapshot]"
  printx "Where:  <backup_device> and <restore_device> can be a device designator (e.g., /dev/sdb6), a UUID, or a filesystem LABEL."
  printx "        [-t] means to do a test without actually creating the backup; i.e., an rsync dry-run"
  printx "        [-g] means to rebuild grub on the specified device; e.g., /dev/sda1"
  printx "        [snapshot] is the name (timestamp) of the snapshot to restore."
  printx "If no snapshot is specified, the device will be queried for the available snapshots."
  exit  
}

function mount_backup_device () {
  if [ ! -d $backuppath ]; then
    printx "'$backuppath' was not found; creating it..."
    sudo mkdir $backuppath
  fi

  sudo mount $backupdevice $backuppath
  if [ $? -ne 0 ]; then
    printx "Unable to mount the backup device."
    exit 2
  fi
}

function unmount_backup_device () {
  sudo umount $backuppath
}

function mount_restore_device () {
  if [ ! -d $restorepath ]; then
    printx "'$restorepath' was not found; creating it..."
    sudo mkdir $restorepath
  fi

  sudo mount $restoredevice $restorepath
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
  elif [ "${args[$i]}" == "-g" ]; then
    ((i++))
    bootdevice="${args[$i]}"
  elif [ "${args[$i]}" == "-s" ]; then
    ((i++))
    snapshotname="${args[$i]}"
  fi
  ((i++))
done

# echo "Backup device:$backupdevice"
# echo "Restore device:$restoredevice"
# echo "Dry-run:$dryrun"
# echo "Boot device:$bootdevice"
# echo "Snapshot:$snapshotname"

# osid=$(grep "^ID=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
# partno="${restoredevice: -1}"
# echo "osid=$osid"
# echo "partno=$partno"

if [[ "$EUID" != 0 ]]; then
  printx "This must be run as sudo.\n"
  exit 1
fi

if [ ! -e $restoredevice ]; then
  printx "There is no such device: $restoredevice."
  exit 2
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
  printx "This will completely OVERWRITE the operating system on '$restoredevice' and is NOT reversible."
  read -p "Are you sure you want to proceed? (y/N) " yn
  if [[ $yn != "y" && $yn != "Y" ]]; then
    printx "Operation cancelled."
    unmount_backup_device
    unmount_restore_device
    exit
  elif [ ! -z $dryrun ]; then
    # Do a dry run and record the output
      sudo rsync -aAX --dry-run --delete --verbose --exclude-from=/etc/ts_excludes $snapshotpath/$snapshotname/ $restorepath/ > $dryrun_log
      printx "The dry run restore is completed.  The output is located in '$dryrun_log'."
  else
    # Restore the snapshot
    sudo rsync -aAX --delete --exclude-from=/etc/ts_excludes $snapshotpath/$snapshotname/ $restorepath/ > rsync.out

    if [ $? -ne 0 ]; then
      printx "Something went wrong with the restore."
      cat rsync.out
      rm rsync.out
      exit 3
    fi

    if [ -f $snapshotpath/$descfile ]; then
      # Delete the description file from the target
      sudo rm $snapshotpath/$descfile
    fi

    # Done
    printx "The snapshot '$snapshotname' was successfully restored."

    if [ ! -z $bootdevice ]; then
      # Mount the necessary directories
      sudo mount $bootdevice $restorepath/boot/efi
      sudo mount --bind /dev $restorepath/dev
      sudo mount --bind /proc $restorepath/proc
      sudo mount --bind /sys $restorepath/sys
      sudo mount --bind /dev/pts $restorepath/dev/pts

      printx "Updating grub on $restoredevice..."
      # Use chroot to rebuild grub on the restored partion
      sudo chroot $restorepath update-grub > update-grub.out 2>1
      if [ $? -ne 0 ]; then
        printx "Something went wrong with 'update-grub':"
        cat update-grub.out
        rm update-grub.out
      fi
      printx "Installing grub on $restoredevice..."
      sudo chroot $restorepath grub-install --target=x86_64-efi --efi-directory=/boot/efi --boot-directory=/boot > grub-install.out 2>1
      if [ $? -ne 0 ]; then
        printx "Something went wrong with 'grub-install':"
        cat grub-install.out
        rm grub-install.out
      fi

      printx "Building the UEFI boot entry on $bootdevice with an entry for $restoredevice..."
      osid=$(grep "^ID=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
      partno="${restoredevice: -1}"
      # Look for shimx64.efi; if present, use it else use grubx64.efi
      if [ -f $restorepath/boot/efi/EFI/$osid/shimx64.efi ]; then
        bootfile="shimx64"
      else
        bootfile=grubx64
      fi
      # Set UEFI boot entry -- where partno is the target partition for the boot entry
      sudo efibootmgr -c -d $bootdevice -p $partno -L $osid -l "/EFI/$osid/$bootfile.efi" > /dev/null 2>1
      # Establish a fall back in case the above fails to succeed
      sudo cp $restorepath/boot/efi/EFI/$osid/$bootfile.efi $restorepath/boot/efi/EFI/BOOT/BOOTX64.EFI

      # Unbind the directories
      sudo umount $restorepath/boot/efi $restorepath/dev/pts $restorepath/dev $restorepath/proc $restorepath/sys

      # Done
      printx "The system may now be rebooted into the restored partition."
    fi
  fi
else
  printx "No snapshot was identified."
fi

unmount_backup_device
unmount_restore_device
