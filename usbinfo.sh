#!/usr/bin/env bash
#v1.1

# Given an identifying string for which to search the output of lsusb,
# return the full name of the device and the USB version

source /usr/local/lib/colors
function printx {
  printf "${YELLOW}$1${NOCOLOR}\n"
}

STMT=$(basename $0)

# The following example for creating a menu from bash is from https://stackoverflow.com/questions/61953905/how-to-make-a-command-output-list-into-a-menu-option-list-with-bash

unset DEVICES
while IFS= read -r LINE; do
  DEVICES+=("${LINE}")
# done < <(lsusb | awk '{ s = ""; for (i = 7; i <= NF; i++) s = s $i " "; print s }')
done < <(lsusb)

# Iterate over an array to create select menu
select SEL in "${DEVICES[@]}" "Quit"; do
  case ${SEL} in
    "Quit")
      # If the user selects the Quit option...
      break
      ;;
    *)
      # Identify the BUS and DEV
      IFS=' ' read blank1 BUS blank2 DEV blank3 ID BALANCE <<< ${SEL}
      DEV="${DEV//:}"

      # Read the specific values
      IFS=' ' read label f SN <<< $(lsusb -D /dev/bus/usb/${BUS}/${DEV} 2>/dev/null | grep iSerial)
      IFS=' ' read label f MFG <<< $(lsusb -D /dev/bus/usb/${BUS}/${DEV} 2>/dev/null | grep iManufacturer)
      IFS=' ' read label f PROD <<< $(lsusb -D /dev/bus/usb/${BUS}/${DEV} 2>/dev/null | grep iProduct)
      IFS=' ' read label PWR <<< $(lsusb -D /dev/bus/usb/${BUS}/${DEV} 2>/dev/null | grep MaxPower)
      IFS=' ' read label SPEC <<< $(lsusb -D /dev/bus/usb/${BUS}/${DEV} 2>/dev/null | grep bcdUSB)
      IFS=' ' read label HWV <<< $(lsusb -D /dev/bus/usb/${BUS}/${DEV} 2>/dev/null | grep bcdDevice)

      # Display the info
      echo Manufacturer: ${MFG}
      echo Product: ${PROD}
      echo Version: ${HWV}
      echo Serial: ${SN}
      echo -n 'Label: "'
      echo -n ${SEL} | awk '{ s = ""; for (i = 7; i < NF; i++) s = s $i " "; printf s } {printf $NF}'
      echo '"'
      echo ID: $(echo -n ${SEL} | awk '{printf $6}')
      echo USB Spec: ${SPEC}
      echo MaxPower: ${PWR}
      break
      ;;
  esac
done
