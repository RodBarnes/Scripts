#!/usr/bin/env bash

# Given an identifying string for which to search the output of lsusb,
# return the full name of the device and the USB version

source /usr/local/lib/color

show_syntax() {
  echo "Syntax: $(basename $0)"
  exit
}

# --------------------
# ------- MAIN -------
# --------------------

unset devices
while IFS= read -r line; do
  IFS=' ' read f1 bus f3 dev f5 ID name <<< $line
  dev="${dev//:}"
  IFS=' ' read f1 f2 class rest <<< $(lsusb -D /dev/bus/usb/${bus}/${dev} 2>/dev/null | grep bInterfaceClass)
  if [ $class == 'Mass' ]
  then
    devices+=("${line}")
  fi
done < <(lsusb)

if [ ${#devices[@]} -eq 0 ]; then
  printx "No USB devices were found."
  exit
fi

if [[ "$EUID" -ne 0 ]]
then
  echo 'No speed test will be performed. To include the speed test, run as sudo.'
fi

# Get the count of options and increment to include the cancel
count="${#devices[@]}"
((count++))

# Iterate over an array to create select menu
select selection in "${devices[@]}" "Cancel"; do
  if [[ "$REPLY" =~ ^[0-9]+$ && "$REPLY" -ge 1 && "$REPLY" -le $count ]]; then
    case ${selection} in
      "Cancel")
        # If the user selects the Cancel option...
        break
        ;;
      *)
        # Identify the bus and dev
        IFS=' ' read f1 bus f3 dev f5 ID BALANCE <<< ${selection}
        dev="${dev//:}"

        # Read the specific values
        IFS=' ' read f1 f2 SN <<< $(lsusb -D /dev/bus/usb/${bus}/${dev} 2>/dev/null | grep iSerial)
        IFS=' ' read f1 f2 mfg <<< $(lsusb -D /dev/bus/usb/${bus}/${dev} 2>/dev/null | grep iManufacturer)
        IFS=' ' read f1 f2 prod <<< $(lsusb -D /dev/bus/usb/${bus}/${dev} 2>/dev/null | grep iProduct)
        IFS=' ' read f1 pwr <<< $(lsusb -D /dev/bus/usb/${bus}/${dev} 2>/dev/null | grep MaxPower)
        IFS=' ' read f1 spec <<< $(lsusb -D /dev/bus/usb/${bus}/${dev} 2>/dev/null | grep bcdUSB)
        IFS=' ' read f1 hwv <<< $(lsusb -D /dev/bus/usb/${bus}/${dev} 2>/dev/null | grep bcdDevice)

        # Display the device info
        echo Manufacturer: ${mfg}
        echo Product: ${prod}
        echo Version: ${hwv}
        echo Serial: ${sn}
        echo -n 'Label: "'
        echo -n ${selection} | awk '{ s = ""; for (i = 7; i < NF; i++) s = s $i " "; printf s } {printf $NF}'
        echo '"'
        echo ID: $(echo -n ${selection} | awk '{printf $6}')
        echo USB Spec: ${spec}
        echo MaxPower: ${pwr}

        # Display the block info
        IFS=' ' read f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 link <<< $(ls -l /dev/disk/by-id/usb-*${prod// /_}_${sn}-0:0 2> /dev/null)
        if [ -z "$link" ]
        then
          # Some off brands don't put in the expected info for creating the link
          # So try just using the serial number which should normally be sufficient
          IFS=' ' read f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 link <<< $(ls -l /dev/disk/by-id/usb-*_${SN}-0:0 2> /dev/null)
          if [ -z "$link" ]
          then
            # Apparently this one is really not even close.  Just try to see what can be found
            IFS=' ' read f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 link <<< $(ls -l /dev/disk/by-id/usb-*-0:0 2> /dev/null)
          fi
        fi

        if [ -z "$link" ]
        then
          # Unable to get a reference to the link so don't try any of the rest
          echo 'Unable to get a reference to the /dev/ device.'
          exit
        else
          IFS='/' read f1 f2 mount <<< ${link}
          IFS=' ' read f1 SIZE f3 <<< $(echo -n $(lsblk -o SIZE /dev/${mount}))
          echo Size: ${SIZE}

          if [[ "$EUID" -eq 0 ]]
          then
            # Test the speed
            echo -n 'Speed: '
            result=$(sudo hdparm -t --direct /dev/${mount})
            IFS=' ' read f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 speed unit <<< $(echo $result)
            echo ${speed} ${unit}
          fi

          # Show the block info
          echo ''
          lsblk -o NAME,SIZE,FSTYPE,FSVER,MOUNTPOINTS /dev/${mount}
        fi

        break
        ;;
    esac
    break # Exit the select loop on valid input
  else
    printx "Invalid selection. Please enter a number between 1 and $count."
  fi
done
