#!/usr/bin/env bash
#v1.1

# This has been tested on LinxuMint and works well.
# It should work under Fedora and downstream debian-based with little or no changes.

stmt=$(basename $0)

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
  printx "Syntax: $stmt 'command'\nWhere:  command is the name to be used to invoke the program\n"
  exit
fi

command=$1

# Get the name of the AppImage package
cd /opt/$command
appimage=$(ls *.AppImage)

# Confirm
printx "This entirely removes the command '$command' and '$appimage' from the system."
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

sudo ./$appimage --appimage-extract 1> /dev/null
cd squashfs-root
desktopfile=$(ls *.desktop)
cd /opt
sudo rm /usr/local/share/applications/$desktopfile
sudo rm /usr/local/bin/$command
sudo rm -rf /opt/$command
sudo update-desktop-database

printx "Removal complete"
