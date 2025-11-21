#!/usr/bin/env bash
#v1.01

# This has been tested on Fedora 39 Cinnamon and works well.
# It should work under Ubuntu and downstream with little or no changes.

source /usr/local/lib/display.sh

show_syntax() {
  echo "Syntax: $(basename $0) <command> <appimage>"
  echo "Where:  <command> is the name to be used to invoke the program"
  echo "        <appimage> is the filename (without extension) of the AppImage"
  echo "NOTE:   Must be run as sudo."
  exit
}

# --------------------
# ------- MAIN -------
# --------------------

scriptname=$(basename $0)
if [[ $# < 2 ]]; then
  show_syntax
fi

if [[ "$EUID" = 0 ]]; then
  printx "This must be run as the standard user that will use the device.\nIt will prompt for sudo when it is needed.\n"
  exit
fi

command=$1
filename=$2
user=$(whoami)

# Strip any extension that may've been provided
appname=$(basename $filename .AppImage)

# Confirm the AppImage can be found using the supplied filename
if [ ! -f /home/$user/Downloads/$appname.AppImage ]; then
  printx "Unable to locate specified '$filename' or '$filename.AppImage' in '/home/$user/Downloads/'"
  exit
fi

# Create the folder, move the AppImage, make it executable, and create the command
printx "Installing app..."
sudo mkdir /opt/$command
sudo mv /home/$user/Downloads/$appname.AppImage /opt/$command
sudo chmod +x /opt/$command/$appname.AppImage
sudo chown root /opt/$command/$appname.AppImage
sudo chgrp root /opt/$command/$appname.AppImage
sudo ln -s /opt/$command/$appname.AppImage /usr/local/bin/$command

# Install in menu
printx "Installing in menu..."
cd /opt/$command
sudo ./$appname.AppImage --appimage-extract 1> /dev/null
sudo chmod +xr -R ./squashfs-root
sudo cp ./squashfs-root/.DirIcon .
desktoppath=$(ls ./squashfs-root/*.desktop)
sudo sed -i "s|Exec=.*|Exec=$command|g" $desktoppath
sudo sed -i "s|Icon=.*|Icon=/opt/$command/.DirIcon|g" $desktoppath
sudo desktop-file-install --dir=/usr/local/share/applications $desktoppath
sudo update-desktop-database
sudo rm -rf ./squashfs-root

printx "Installation complete"

