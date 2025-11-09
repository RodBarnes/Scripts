#!/usr/bin/env bash

# Move the list of files to an executable path

source /usr/local/lib/display

show_syntax() {
  echo "Move designated files to a directory."
  echo "Syntax: $(basename $0) <path> <filename> [-p:--permissions perm] [-o:--owner user] "
  echo "Where   <path> is the target directory"
  echo "        <filename> is a standard filename.  If wildcards are used (*), it must be placed in single quotes."
  echo "        [-p|--permissions perm] is an optional argument to specify to what permissions the file should be set."
  echo "        [-o|--owner user] is to whom the file should be marked as owner."
  echo "NOTE:   Must be run as sudo."
  exit
}

# --------------------
# ------- MAIN -------
# --------------------

# Get the arguments
arg_short=p:o:
arg_long=permissions:,owner:
arg_opts=$(getopt --options "$arg_short" --long "$arg_long" --name "$0" -- "$@")
if [ $? != 0 ]; then
  show_syntax
  exit 1
fi

eval set -- "$arg_opts"
while true; do
  case "$1" in
    -p|--permissions)
      perm="$2"
      shift 2
      ;;
    -o|--owner)
      user="$2"
      shift 2
      ;;
    --) # End of options
      shift
      break
      ;;
    *)
      echo "Error parsing arguments: arg=$1"
      exit 1
      ;;
  esac
done

if [ $# -ge 2 ]; then
  directory="$1"
  shift 1
  if [ ! -d $directory ]; then
    printx "No valid device was found for '$directory'."
    exit
  fi
  filename="$1"
  shift 1
  ext=${filename##*.}
else
  show_syntax
fi

# echo "directory=$directory"
# echo "filename=$filename"
# echo "ext=$ext"
# echo "perm=$perm"
# echo "user=$user"
# exit

if [[ "$EUID" != 0 ]]; then
  printx "This must be run as sudo.\n"
  exit
fi

for file in $filename
do
  newname=${file%.$ext}
  if ! sudo mv "$file" "$directory/$newname"; then
    printx "Failed to move '$newname' to '$directory'"
    exit
  # else
  #   echo "moved to '$directory"
  fi

  if [[ ! -z $user ]]; then
    if ! sudo chown $user:$user "$directory/$newname"; then
      printx "Failed to change ownership"
    # else
    #   echo "ownership set to '$user'"
    fi
  fi

  if [[ ! -z $perm ]]; then
    if ! sudo chmod $perm "$directory/$newname"; then
      printx "Failed to set permissions."
    # else
    #   echo "permissions set to '$perm'"
    fi
  fi
done
