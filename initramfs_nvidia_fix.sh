#!/usr/bin/env bash

# This is a convenience script to address an issue that periodically happens when a
# new kernel is received.  Sometimes, the nvidia-related module files aren't uncompressed
# and, thus, do not get included in the initramfs when it is built. Lately, the dkms files
# haven't even been present and a reinstall is required.
# Obviously, this script is unnecessary on a non-Nvidia system.

source /usr/local/lib/colors
function printx {
  printf "${YELLOW}$1${NOCOLOR}\n"
}

STMT=$(basename $0)

if [[ $# == 1 ]]; then
  arg=$1
  if [ $arg == "?" ] || [ $arg == "-h" ]; then
    printx "Syntax: $STMT <kernel>\nWhere:  <kernel> is the name of the initramfs to be fixed; e.g., 6.11.0-28-generic"
    printx "If no kernel is specified it will rebuild the current initramfs.\n"
    exit
  else
    KERNEL=$arg
  fi
else
  KERNEL=$(uname -r)
fi

if [[ "$EUID" != 0 ]]; then
  printx "This must be run as sudo.\n"
  exit
fi

# Check for DKMS
if [ ! -d "/usr/lib/modules/$KERNEL/updates/dkms" ]; then
  # prompt for what version to install
  echo "The DKMS files are missing."

  unset drivers
  while IFS= read -r LINE; do
    IFS='/' read NAME f2 <<< $LINE
    IFS='-' read f1 f2 VERSION f4 f5 <<< $NAME
    drivers+=("${VERSION}")
  done < <(sudo apt list --installed nvidia-driver* 2> /dev/null )

  options=($(printf '%s\n' "${drivers[@]}" | sort -u))   

  if [ ${#options[@]} == 1 ]; then
    selected=${options[0]}
  else
    printf "Select the driver to reinstall...\n"
    # Iterate over an array to create select menu
    select SEL in "${options[@]}" "Quit"; do
      case ${SEL} in
        "Quit")
          # If the user selects the Quit option...
          break
          ;;
        *)
          selected=${SEL}
          break
          ;;
      esac
    done
  fi

  printf "Reinstalling nvidia-dkms-${selected}\n"

  #DRIVER=$(nvidia-smi --version | grep 'DRIVER version ' | cut -d ':' -f 2 | cut -d '.' -f 1 | tr -d ' ')
  sudo apt install --reinstall nvidia-dkms-$selected
fi

# Uncompress the module and create the initramfs
sudo unzstd /usr/lib/modules/$KERNEL/updates/dkms/nvidia*.ko.zst
sudo update-initramfs -u -k $KERNEL
#sudo rm /usr/lib/modules/$KERNEL/updates/dkms/nvidia*.zst
