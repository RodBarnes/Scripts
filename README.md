# Scripts
A collection of `bash` scripts for working with Linux systems.  Each is intended to be instantiated within the `$PATH`, set as executable, and without the `.sh` extension.  The recommended location is `/usr/local/bin`.

## blkdevinfo.sh
Usage: `blkdevinfo [drive]`

Uses `smartctl` to display information about the non-removable drives found on the system.  If no drive is specified, it iterates all the drives.

## colors.sh
A library for inclusion by other scripts that sets up some colors for text.  It must be accessible via `$PATH` for the scripts to find it.  The recommended location is `/usr/local/lib`

## common.sh
A library for includsion by other scripts for common functions and other commands.  Includes source of colors.sh

## cpumode.sh
Usage: `sudo cpumode [powersave|performance|current]`

Sets or shows the current cpumode.

## devid.sh
Usage: `devid <device_label>`

Displays the corresponding device id (e.g., sda1) that matches the specified label as reported by `blikid`.

## howlong.sh
Usage: `howlong <program_name> [<user>]`

Displays how long any matching process has been running.

## initramfs_nvidia_fix.sh
Usage: `sudo initramfs_nvidia_fix <kerneL>`

Sometimes, when a new kernel is received, the nvidia-related DKMS modules are missing or left compressed and the build of `initramfs` fails to include them.  The visual manifestation of this is that logos and graphics displayed by Plymouth during the boot of the OS are based upon the default resolution and will appear distorted or fuzzy or, if they are missing, the login screen comes up a default resolution.

This tool uncompresses those files and updates initramfs to correct this.

## install_appimage.sh
Usage: `install_appimage <name> <path_to_appimage>`

Installs the AppImage under `/opt` and adds an entry to the menu based upon the information and icon found in the AppImage.

## launch_gateway.sh
Usage: `nohup launch_gateway {browser} 2\> /dev/null`

This script can be used to bring up the gateway for logging in when that is required to connect to the internet; e.g., with hotel networks.  (With some Linux OS, this does not happen automatically.)  It is recommended this be added to a short-cut key for easy access.

## nlog.sh
Usage: `nlog <path_to_log>`

Purpose: On LinuxMint, notifications are displayed but not logged.  If they aren't seen, there is no way to find out what was the notification. This captures the output into a log that is cleared when the process is started.

## remove_appimage.sh
Usage: `remove_appimage <name>`

Uninstall an AppImage matching `name` that was installed using `install_appimage`.  This also removes the menu entry that was created.

## show_crontab_users.sh
Usage: `show_crontab_users`

Show a list of users running crontab tasks.

## show_volume_device.sh
Usage: `show_volume_device <device_label>`

Show the full device path for the device with the specified label.  This is similar to `devid.sh`

## sysinfo.sh

## usbinfo.sh
Usage: `usbinfo`

Select a USB from the menu and display the USB info -- size, spec, etc. -- for that device.  This relies upon `lsusb` for obtaining the info and `hdparm` for determining the speed.

## vmtoggle.sh
Usage: `vmtoggle <name>`

Specify a VM by its name and start it up or power it down.
