#!/usr/bin/env bash

# Propagate the specified program to specified systems
# They will end up in the /home/<user> directory of the target system(s)
# and will still require ssh into each system and movebin to place themn

source /usr/local/lib/display

show_syntax() {
  echo "Propagate file[s] to another system."
	echo "Syntax: $(basename $0) <filepath> <user> <system> [<system>...]"
	echo "Where:  <filepath> is the filepath to the file to be propagated."
  echo "        <user> is the user that should be used for login."
  echo "        <system> is one or more systems to which the file should be copied."
	exit
}

parse_arguments() {
  # Get the required arguments
  filepath="${args["0"]}"
  user="${args["1"]}"

  # echo "filepath=$filepath"
  # echo "user=$user"

  # Get optional parameters
  i=2
  systems=()
  while [ $i -lt $argcnt ]; do
    systems+=("${args[$i]}")
    ((i++))
  done
}

# --------------------
# ------- MAIN -------
# --------------------

args=("$@")
argcnt=$#
if [ $# -lt 2 ]; then
  show_syntax
fi
# echo "args=${args[@]}"

parse_arguments

for system in "${systems[@]}"; do
  printf "Copying to '$system'..."
  scp $filepath $user@$system:/home/$user/ >/dev/null 2>1
  if [ $? -gt 0 ]; then
    printx "no access"
  else
    printx "success"
  fi
done
