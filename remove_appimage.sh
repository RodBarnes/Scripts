#!/usr/bin/env bash
#v1.1

# This has been tested on LinxuMint and works well.
# It should work under Fedora and downstream debian-based with little or no changes.

STMT=$(basename $0)

source /usr/local/lib/colors
function printx {
  printf "${YELLOW}$1${NOCOLOR}\n"
}

if [[ "$EUID" = 0 ]]; then
  printx "This must be run as the standard user that will use the device.\nIt will prompt for sudo when it is needed.\n"
  exit
fi


# This is a test comment to demonstrate an addition.

if [[ $# < 1 ]]; then
  printx "Syntax: $STMT 'command'\nWhere:  command is the name to be used to invoke the program\n"
  exit
fi

COMMAND=$1

# Get the name of the AppImage package
cd /opt/$COMMAND
APPIMAGE=$(ls *.AppImage)

# Confirm
printx "This entirely removes the command '$COMMAND' and '$APPIMAGE' from the system."
while true; do
read -p "Do you want to proceed? (yes/no) " yn
case $yn in 
	yes ) echo ok, we will proceed;
        printx "Proceeding to remove the application..."
		break;;
	no ) echo exiting...;
		exit;;
	* ) echo invalid response;;
esac
done

sudo ./$APPIMAGE --appimage-extract 1> /dev/null
cd squashfs-root
DESKTOPFILE=$(ls *.desktop)
cd /opt
sudo rm /usr/local/share/applications/$DESKTOPFILE
sudo rm /usr/local/bin/$COMMAND
sudo rm -rf /opt/$COMMAND
sudo update-desktop-database

printx "Removal complete"
