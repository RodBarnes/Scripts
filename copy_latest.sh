#!/usr/bin/env bash

show_syntax() {
  echo "Copy scripts from one path to another, removing the .sh extension, and set them executable."
  echo "Syntax: $(basename $0) <source_path> <destination_path> [days_back]"
  echo "Where:  <source_path> is the location from where to copy copy the files"
  echo "        <destination_path> is the location to where they should be copied."
  echo "        [days_back] is an optional number of days old (default is 1) by which to filter the files."
  exit
}

source=$1
destination=$2
daysback=$3

if [[ $# < 2 ]]; then
  show_syntax
fi

if [ -z $daysback ]; then
  daysback=1
fi

# echo "source=$source"
# echo "destination=$destination"
# echo "daysback=$daysback"
# exit

# Copy all *.sh files newer than daysback
find "$source" -type f -mtime "-$daysback" -name "*.sh" -exec cp {} "$destination" \;

# Set executable
find "$destination" -type f ! -executable -exec chmod +x {} \;
