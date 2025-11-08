#!/usr/bin/env bash

# Move the list of files to an executable path

source /usr/local/lib/colors

filepath=/usr/local/bin

show_syntax() {
  echo "Move designated files to /usr/local/bin, strips the extension, makes them executable and owned by root."
	echo "Syntax: $(basename $0) <filename>"
  echo "Where   <filename> is a standard filename.  If wildcards are used (*), it must be placed in single quotes."
  echo "NOTE:   Must be run as sudo."
	exit
}

parse_arguments() {
  i=0
  filename="${args[$i]}"
  ext=${filename##*.}

  # echo "filename=$filename"
  # echo "ext=$ext"
  # echo "filepath=$filepath"
  # exit
}

# --------------------
# ------- MAIN -------
# --------------------

args=("$@")
argcnt=$#
if [ $argcnt == 0 ]; then
  show_syntax
fi

parse_arguments

if [[ "$EUID" != 0 ]]; then
  printx "This must be run as sudo.\n"
  exit
fi

for file in $filename
do
  newname=${file%.$ext}
  if ! sudo mv "$file" "$filepath/$newname"; then
    echo "Failed to move the file"
  fi
  if ! sudo chown root:root "$filepath/$newname"; then
    echo "Failed to change ownership"
  fi
  if ! sudo chmod +x "$filepath/$newname"; then
    echo "Failed to set permissions"
  fi
done
