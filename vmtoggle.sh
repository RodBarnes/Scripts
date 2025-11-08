#!/usr/bin/env bash

# Given the name of a VM, check if it running.
# If not, start it; if it is, shutdown

source /usr/local/lib/display

show_syntax() {
  echo "Syntax: $(basename $0) <vm_name>"
  echo "Where:  <vm_name> is the name of the VM to be started or shutdown"
  exit
}

# --------------------
# ------- MAIN -------
# --------------------

if [[ $# < 1 ]]; then
  show_syntax
fi

vmname=$1

# FInd out if it is running
if vboxmanage list runningvms | grep -q $vmname; then
    # Shutdown
    vboxmanage controlvm $vmname shutdown
else
    # Start
    vboxmanage startvm $vmname
fi
