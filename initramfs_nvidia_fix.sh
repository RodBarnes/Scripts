#!/usr/bin bash

# This is a convenience script to address an issue that periodically happens when a
# new kernel is received.  Sometimes, the nvidia-related module files aren't uncompressed
# and, thus, do not get included in the initramfs when it is built. Lately, the dkms files
# haven't even been present and a reinstall is required.
# Obviously, this script is unnecessary on a non-Nvidia system.

source /usr/local/lib/color

show_syntax() {
  echo "Syntax: $(basename $0) <kernel>"
  echo "Where:  <kernel> is the name of the initramfs to be fixed; e.g., 6.11.0-28-generic"
  echo "If no kernel is specified it will rebuild the current initramfs.\n"
  exit
}

# --------------------
# ------- MAIN -------
# --------------------

if [[ $# == 1 ]]; then
  arg=$1
  if [ $arg == "?" ] || [ $arg == "-h" ]; then
    show_syntax
  else
    kernel=$arg
  fi
else
  kernel=$(uname -r)
fi

if [[ "$EUID" != 0 ]]; then
  printx "This must be run as sudo.\n"
  exit
fi

# Check for DKMS
if [ ! -d "/usr/lib/modules/$kernel/updates/dkms" ]; then
  # prompt for what version to install
  echo "The DKMS files are missing."

  # Get a list of the currently installed drivers
  # If more than one, display the list and allow the user to select.
  # NOTE: There should only be one, but...
  unset drivers
  while IFS= read -r line; do
    IFS='/' read name f2 <<< $line
    IFS='-' read f1 f2 version f4 f5 <<< $name
    drivers+=("${version}")
  done < <(sudo apt list --installed nvidia-driver* 2> /dev/null )

  if [ ${#options[@]} == 1 ]; then
    # There is just one so select that one.
    selected=${options[0]}
  else
    # Remove any duplicates in the list
    options=($(printf '%s\n' "${drivers[@]}" | sort -u))   

    count="${#options[@]}"
    ((count++))

    printf "Select the driver to reinstall...\n"
    # Iterate over an array to create select menu
    select SEL in "${options[@]}" "Quit"; do
      if [[ "$REPLY" =~ ^[0-9]+$ && "$REPLY" -ge 1 && "$REPLY" -le $count ]]; then
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
      else
        printx "Invalid selection. Please enter a number between 1 and $count."
      fi
    done
  fi

  # Inform the user of what is happening and reinstall the DKMS files
  printf "Reinstalling nvidia-dkms-${selected}\n"
  sudo apt install --reinstall nvidia-dkms-$selected
fi

# Uncompress the module and create the initramfs
sudo unzstd /usr/lib/modules/$kernel/updates/dkms/nvidia*.ko.zst
sudo update-initramfs -u -k $kernel
#sudo rm /usr/lib/modules/$kernel/updates/dkms/nvidia*.zst
