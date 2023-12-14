#!/usr/bin/env bash

# Reset installation of Appimage
#bash ~/Scripts/install_appimage.sh localsend LocalSend-1.13.1-linux-x86-64

# reset
sudo rm /usr/local/bin/localsend
sudo rm -rf /opt/localsend
cp /home/rod/LocalSend-1.13.1-linux-x86-64.AppImage /home/rod/Downloads
sudo rm /usr/share/applications/*localsend*
sudo update-desktop-database

