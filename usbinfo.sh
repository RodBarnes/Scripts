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
      IFS=' ' read f1 BUS f3 DEV f5 ID BALANCE <<< ${SEL}
      DEV="${DEV//:}"

      # Read the specific values
      IFS=' ' read f1 f2 SN <<< $(lsusb -D /dev/bus/usb/${BUS}/${DEV} 2>/dev/null | grep iSerial)
      IFS=' ' read f1 f2 MFG <<< $(lsusb -D /dev/bus/usb/${BUS}/${DEV} 2>/dev/null | grep iManufacturer)
      IFS=' ' read f1 f2 PROD <<< $(lsusb -D /dev/bus/usb/${BUS}/${DEV} 2>/dev/null | grep iProduct)
      IFS=' ' read f1 PWR <<< $(lsusb -D /dev/bus/usb/${BUS}/${DEV} 2>/dev/null | grep MaxPower)
      IFS=' ' read f1 SPEC <<< $(lsusb -D /dev/bus/usb/${BUS}/${DEV} 2>/dev/null | grep bcdUSB)
      IFS=' ' read f1 HWV <<< $(lsusb -D /dev/bus/usb/${BUS}/${DEV} 2>/dev/null | grep bcdDevice)

      # Display the device info
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

      # Display the block info
      IFS=' ' read f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 LINK <<< $(ls -l /dev/disk/by-id/usb-*${PROD// /_}_${SN}-0:0 2> /dev/null)
      if [ -z "$LINK" ]
      then
        # Some off brands don't put in the expected info for creating the link
        # So try just using the serial number which should normally be sufficient
        IFS=' ' read f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 LINK <<< $(ls -l /dev/disk/by-id/usb-*_${SN}-0:0 2> /dev/null)
        if [ -z "$LINK" ]
        then
          # Apparently this one is really not even close.  Just try to see what can be found
          IFS=' ' read f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 LINK <<< $(ls -l /dev/disk/by-id/usb-*-0:0 2> /dev/null)
        fi
      fi

      if [ -z "$LINK" ]
      then
        # Unable to get a reference to the link so don't try any of the rest
        echo 'Unable to get a reference to the /dev/ device.'
        exit
      else
        IFS='/' read f1 f2 MOUNT <<< ${LINK}
        IFS=' ' read f1 SIZE f3 <<< $(echo -n $(lsblk -o SIZE /dev/${MOUNT}))
        echo Size: ${SIZE}
        # This line can show the partition info
        # echo 'Format:'
        # lsblk -o NAME,SIZE,FSTYPE,FSVER /dev/${MOUNT}

        # Test the speed
        echo -n 'Speed: '
        RESULT=$(sudo hdparm -t --direct /dev/${MOUNT})
        IFS=' ' read f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 SPEED UNIT <<< $(echo $RESULT)
        echo ${SPEED} ${UNIT}
      fi

      break
      ;;
  esac
done
