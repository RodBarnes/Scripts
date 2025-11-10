#!/usr/bin/env bash

source /usr/local/lib/display
source /usr/local/lib/device

show_syntax() {
  echo "Move designated files from a directory to the same directory on another drive."
  echo "Syntax: $(basename $0) <path> <filename> <drive>"
  echo "Where   <path> is the target directory"
  echo "        <filename> is a standard filename.  If wildcards are used (*), it must be placed in single quotes."
  echo "        <drive> is the target drive."
}

# --------------------
# ------- MAIN -------
# --------------------

tmpmnt="/mnt/$(cat /proc/sys/kernel/random/uuid)"

trap 'unmount_device_at_path "$tmpmnt"' EXIT

if [ $# -ge 3 ]; then
  path="$1"
  shift 1
  if [ ! -d $path ]; then
    printx "No valid directory was found for '$path'."
    exit
  fi
  filename="$1"
  shift 1
  drive="$1"
  shift 1
  if [[ ! -b "$drive" ]]; then
    printx "No valid device was found for '$drive'."
    exit
  fi
else
  show_syntax
  exit
fi

# echo "path=$path"
# echo "filename=$filename"
# echo "drive=$drive"
# exit

mount_device_at_path "$drive" $tmpmnt

for file in $path/$filename; do
  if [ -e "$file" ]; then
    sudo cp "$file" "$tmpmnt$path"
  else
    echo "No files matching '$filename' found in '$path'."
    exit 1
  fi
done

unmount_device_at_path $tmpmnt
sudo rmdir $tmpmnt