#!/usr/bin/env bash

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
APPFILE=$2
USER=$(whoami)
APPIMAGE=$APPFILE

if [ -f /home/$USER/Downloads/$APPFILE ]; then
    APPIMAGE=$(basename $APPFILE)
elif [ -f /home/$USER/Downloads/$APPFILE.AppImage ]; then
    APPIMAGE=$APPFILE
else
    printx "Unable to locate specified '$APPFILE' or '$APPFILE.AppImage' in '/home/$USER/Downloads/'"
    exit
fi

if [ -f /usr/local/bin/$COMMAND ]; then
  printx "'$COMMAND' is already present in /usr/local/bin"
  exit
fi

# Create the folder, move the AppImage, make it executable, and create the command
printx "Installing app..."
sudo mkdir /opt/$COMMAND
sudo mv /home/$USER/Downloads/$APPIMAGE.AppImage /opt/$COMMAND
sudo chmod +x /opt/$COMMAND/$APPIMAGE.AppImage
sudo chown root /opt/$COMMAND/$APPIMAGE.AppImage
sudo chgrp root /opt/$COMMAND/$APPIMAGE.AppImage
sudo ln -s /opt/$COMMAND/$APPIMAGE.AppImage /usr/local/bin/$COMMAND

# Install in menu
printx "Installing in menu..."
cd /opt/$COMMAND
sudo ./$APPIMAGE.AppImage --appimage-extract 1> /dev/null
sudo chmod +xr -R ./squashfs-root
sudo cp ./squashfs-root/.DirIcon .
DESKTOPPATH=$(ls ./squashfs-root/*.desktop)
sudo sed -i "s|Exec=.*|Exec=$COMMAND|g" $DESKTOPPATH
sudo sed -i "s|Icon=.*|Icon=/opt/$COMMAND/.DirIcon|g" $DESKTOPPATH
sudo desktop-file-install --dir=/usr/local/share/applications $DESKTOPPATH
sudo update-desktop-database
sudo rm -rf ./squashfs-root

printx "Installation complete"

