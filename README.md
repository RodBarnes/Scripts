# Scripts
Just a collection of `bash` scripts for working with Linux systems.

## colors.sh
A library for inclusion by other scripts that sets up some colors for text.

## cpumode.sh
Usage: `sudo cpumode [powersave|performance|current]`

Sets or shows the current cpumode.

## devid.sh
Usage: `devid <device_label>`

Displays the corresponding device id (e.g., sda1) that matches the specified label as reported by `blikid`.

## howlong.sh
Usage: `howlong <program_name> [<user>]`

Displays how long any matching process has been running.

## install_appimage.sh
Usage: `install_appimage.sh <name> <path_to_appimage>`

On LinxuMint, installs the AppImage under `/opt` and adds an entry to the menu based upon the information and icon found in the AppImage.

## launch_gateway.sh
Usage: `nohup launch_gateway.sh {browser} 2\> /dev/null`

On LinxMint running on a laptop, it will not automatically bring up the gateway for logging in when that is required to connecte to the internet; e.g., with hotel networks.  This will bring up that gateway page.  It is recommended this be added to a short-cut key for easy access.

## nlog.sh
Usage: `nlog.sh <path_to_log>`

Purpose: On LinuxMint, notifications are displayed but not logged.  If they aren't seen, there is no way to find out what was the notification. This captures the output into a log that is cleared when the process is started.

## remove_appimage.sh
Usage: `remove_appimage <name>`

Uninstall an AppImage matching `name` that was installed using `install_appimage`.  This also removes the menu entry that was created.

## show_crontab_users.sh
Usage: `show_crontab_users`

Show a list of users running crontab tasks.

## show_volume_device.sh
Usage: `show_volume_device <device_lable>`

Show the full device path for the device with the specified label.  This is similar to `devid.sh`

## sysinfo.sh

## usbinfo.sh
Usage: `usbinfo`

Select a USB from the menu and display the USB info -- size, spec, etc. -- for that device.

## vmtoggle.sh
Usage: 'vmtoggle <name>`

Locate the specified VM and start it up or power it down.