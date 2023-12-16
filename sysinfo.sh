#!/usr/bin/env bash

# interrogate the system with the listed commands in an attempt to
# identify all devices, hardware, configurations, etc. that define
# the system

OUTPATH=$1

OSTYPE=$(grep -E '^ID=.+' /etc/os-release | sed 's\ID=\\g')
OSFAMILY=$(grep -E '^ID_LIKE=.+' /etc/os-release | sed 's\ID_LIKE=\\g')

if [ -z "$1" ]; then
        echo Syntax: $0 '<pathname>'
        echo
        exit
fi

if [ `whoami` != root ]; then
	echo Run this script via sudo or as root
	echo
	exit
fi

if [ ! -d "${OUTPATH}" ]; then
    mkdir ${OUTPATH}
fi

echo Writing to ${OUTPATH}...

#blkid
blkid > ${OUTPATH}/blkid

#dev
ls /dev > ${OUTPATH}/dev

#df
df -h > ${OUTPATH}/df

#dmesg
dmesg > ${OUTPUT}/dmesg

#dmidecode
dmidecode > ${OUTPUT}/dmidecode

#kernel
if [[ $OSTYPE == "fedora" ]]; then
    rpm -qa | grep -Ei 'kernel-[0-9]' > ${OUTPATH}/kernel
elif [[ $OSFAMILY == *"debian"* ]]; then
    dpkg --list | grep -Ei --color 'linux-image-[0-9]' > ${OUTPATH}/kernel
fi

#kernel -> drivers
ls /lib/modules/$(uname -r)/kernel/drivers > ${OUTPATH}/kernel_driver

#driver -> device
find /sys/bus/*/drivers/* -maxdepth 1 -lname '*devices*' -ls > ${OUTPATH}/driver_device

#fdisk
fdisk -l > ${OUTPATH}/fdisk

#hwinfo
hwinfo > ${OUTPATH}/hwinfo

#inxi
inxi -Fxxxrz > ${OUTPATH}/inxi

#lsblk
lsblk > ${OUTPUT}/lsblk

#lsdev
lsdev > ${OUTPATH}/lsdev

#lshw
lshw -short > ${OUTPATH}/lshw

#lsmod
lsmod > ${OUTPATH}/lsmod

#lspci
lspci > ${OUTPATH}/lspci

#lsscsi
lsscsi > ${OUTPATH}/lsscsi

#lsusb
lsusb > ${OUTPATH}/lsusb
lsusb -t > ${OUTPATH}/lsusb-t
lsusb -v > ${OUTPATH}/lsusb-v

#modules.boot
grep "=y" /boot/config-$(uname -r) > ${OUTPATH}/modules_boot

#modules.builtin
cat /lib/modules/$(uname -r)/modules.builtin > ${OUTPATH}/modules_builtin

#modules.parameters
ls /sys/module/*/parameters > ${OUTPATH}/modules_parameters

#os_release
cat /etc/os-release > ${OUTPATH}/os-release

#uname
uname -a > ${OUTPATH}/uname

#xinput
xinput list > ${OUTPATH}/xinput

#xrandr
xrandr --prop > ${OUTPATH}/xrandr
