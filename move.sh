#!/usr/bin/env bash

# Move the list of files to an executable path

source /usr/local/lib/colors

scriptname=$(basename $0)

function printx {
  printf "${YELLOW}$1${NOCOLOR}\n"
}

function show_syntax () {
	printx "Syntax: $(basename $0) <filepath> <perm> <file> [<file>...]"
	printx "Where:  <filepath> is the filepath to where the files should be moved."
  printx "        <perm> are the permissions to be set on the file at the target."
  printx "        <file> is on or more files to be moved."
  printx "        If no special permissions are necessary, just set it to '+r'".
	exit
}

function parse_arguments () {
  # Get the required arguments
  filepath="${args["0"]}"
  perm="${args["1"]}"

  # echo "filepath=$filepath"
  # echo "perm=$perm"

  # Get optional parameters
  i=2
  files=()
  while [ $i -lt $argcnt ]; do
    files+=("${args[$i]}")
    ((i++))
  done
}

args=("$@")
argcnt=$#
if [ $# -lt 2 ]; then
  show_syntax
fi
# echo "args=${args[@]}"

parse_arguments

if [[ "$EUID" != 0 ]]; then
  printx "This must be run as sudo.\n"
  exit
fi

# --------------------
# ------- MAIN -------
# --------------------

for file in "${files[@]}"; do
  printf "Moving '$file' to '$filepath'...\n"
  sudo mv "$file" "$filepath"
  sudo chown root:root "$filepath/$file"
  sudo chmod "$perm" "$filepath/$file"
done

