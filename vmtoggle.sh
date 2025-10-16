#!/usr/bin/env bash

# Given the name of a VM, check if it running.
# If not, start it; if it is, shutdown

source /usr/local/lib/colors
function printx {
  printf "${YELLOW}$1${NOCOLOR}\n"
}

stmt=$(basename $0)

if [[ $# < 1 ]]; then
  printx "Syntax: $stmt 'vm_name'\nWhere:  vm_name is the name of the VM to be started or shutdown\n"
  exit
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
