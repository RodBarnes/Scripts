#!/usr/bin/env bash

# Move the list of files to an executable path

source /usr/local/lib/colors

stmt=$(basename $0)

function printx {
  printf "${YELLOW}$1${NOCOLOR}\n"
}

function show_syntax () {
	printx "Syntax: $(basename $0) <filepath> <file> [<file>...]"
	printx "Where:  <filepath> is the filepath to where the files should be moved."
  printx "        <file> is on or more files to be moved."
	exit
}

args=("$@")
if [ $# -lt 2 ]; then
  show_syntax
fi
# echo "args=${args[@]}"

# Get the required arguments
filepath="${args["0"]}"

echo "filepath=$filepath"

# Get optional parameters
i=1
check=$#
echo "check=$check"
files=()
while [ $i -lt $check ]; do
  files+=("${args[$i]}")
  ((i++))
done

if [[ "$EUID" != 0 ]]; then
  printx "This must be run as sudo.\n"
  exit
fi

for file in "${files[@]}"; do
  printf "Moving '$file' to '$filepath'...\n"
  sudo mv "$file" "$filepath"
  sudo chown root:root "$filepath/$file"
  sudo chmod +x "$filepath/$file"
done

