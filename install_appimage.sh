#!/usr/bin/env bash
#v1.01

# This has been tested on Fedora 39 Cinnamon and works well.
# It should work under Ubuntu and downstream with little or no changes.

DIR=$(dirname $(readlink -f $0))
#echo "DIR=${DIR}"

STMT=$(basename $0)

source ${DIR}/colors.sh
function printx {
  printf "${YELLOW}$1${NOCOLOR}\n"
}

if [[ "$EUID" = 0 ]]; then
  printx "This must be run as the standard user that will use the device.\nIt will prompt for sudo when it is needed.\n"
  exit
fi

if [[ $# < 2 ]]; then
  printx "Syntax: $STMT 'command' 'appimage'\nWhere:  command is the name to be used to invoke the program\n        appimage is the filename (without extension) of the AppImage\n"
  exit
fi

COMMAND=$1
FILENAME=$2
USER=$(whoami)

# Strip any extension that may've been provided
APPNAME=$(basename $FILENAME .AppImage)

# Confirm the AppImage can be found using the supplied filename
if [ ! -f /home/$USER/Downloads/$APPNAME.AppImage ]; then
  printx "Unable to locate specified '$FILENAME' or '$FILENAME.AppImage' in '/home/$USER/Downloads/'"
  exit
fi

# Create the folder, move the AppImage, make it executable, and create the command
printx "Installing app..."
sudo mkdir /opt/$COMMAND
sudo mv /home/$USER/Downloads/$APPNAME.AppImage /opt/$COMMAND
sudo chmod +x /opt/$COMMAND/$APPNAME.AppImage
sudo chown root /opt/$COMMAND/$APPNAME.AppImage
sudo chgrp root /opt/$COMMAND/$APPNAME.AppImage
sudo ln -s /opt/$COMMAND/$APPNAME.AppImage /usr/local/bin/$COMMAND

# Install in menu
printx "Installing in menu..."
cd /opt/$COMMAND
sudo ./$APPNAME.AppImage --appimage-extract 1> /dev/null
sudo chmod +xr -R ./squashfs-root
sudo cp ./squashfs-root/.DirIcon .
DESKTOPPATH=$(ls ./squashfs-root/*.desktop)
sudo sed -i "s|Exec=.*|Exec=$COMMAND|g" $DESKTOPPATH
sudo sed -i "s|Icon=.*|Icon=/opt/$COMMAND/.DirIcon|g" $DESKTOPPATH
sudo desktop-file-install --dir=/usr/local/share/applications $DESKTOPPATH
sudo update-desktop-database
sudo rm -rf ./squashfs-root

printx "Installation complete"

