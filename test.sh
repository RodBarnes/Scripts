#!/usr/bin/env bash

#bash ~/Scripts/install_appimage.sh joplin Joplin-2.13.8

DIR=$(dirname $(readlink -f $0))
#echo "DIR=${DIR}"

STMT=$(basename $0)

source ${DIR}/colors.sh
function printx {
  printf "${YELLOW}$1${NOCOLOR}\n"
}

if [ ! -f /home/rod/Downloads/LocalSend-1.13.1-linux-x86-64.AppImage ]; then
  printx "Unable to locate file 'LocalSend-1.13.1-linux-x86-64.AppImage' in '/home/rod/Downloads/'"
  exit
fi

if [ -f /usr/local/bin/localsend ]; then
  printx "'localsend' is already present in /usr/local/bin"
  exit
fi

# Create the folder, move the AppImage, make it executable, and create the command
printx "Installing app..."
sudo mkdir /opt/localsend
sudo mv /home/rod/Downloads/LocalSend-1.13.1-linux-x86-64.AppImage /opt/localsend
cd /opt/localsend
sudo chmod +x ./LocalSend-1.13.1-linux-x86-64.AppImage
sudo chown root ./LocalSend-1.13.1-linux-x86-64.AppImage
sudo chgrp root ./LocalSend-1.13.1-linux-x86-64.AppImage
sudo ln -s /opt/localsend/LocalSend-1.13.1-linux-x86-64.AppImage /usr/local/bin/localsend

# Install in menu
printx "Installing in menu..."
sudo ./LocalSend-1.13.1-linux-x86-64.AppImage --appimage-extract 1> /dev/null
sudo chmod +xr -R ./squashfs-root
DESKTOPPATH=$(ls ./squashfs-root/*.desktop)
sudo sed -i 's|Exec=.*|Exec=localsend|g' $DESKTOPPATH
sudo desktop-file-install --dir=/usr/share/applications $DESKTOPPATH
sudo update-desktop-database
sudo rm -rf ./squashfs-root

printx "Installation complete"

