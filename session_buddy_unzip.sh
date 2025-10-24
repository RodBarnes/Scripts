#!/bin/bash

# This script assumed it is run from ~/Downloads since that is the logical
# for where the archive will be located.  Especially if using LocalSend.

source /usr/local/lib/colors
function printx {
  printf "${YELLOW}$1${NOCOLOR}\n"
}

scriptname=$(basename $0)
if [[ $# < 1 ]]; then
  printx "Syntax: $scriptname 'filename'\nWhere:  filename is the name of the archive containing the session buddy content"
  printx "NOTE: It is assumed the archive is located in ~/Downloads\n"
  exit
fi

# Obtain the name of the archive
filename=$1

# Push into the target directory for the Session Buddy database
# Remove all current content, extract the contents of the archive, then pop back
pushd /home/$(whoami)/.config/BraveSoftware/Brave-Browser/Default/IndexedDB/chrome-extension_edacconmaakjimmfgnblocblbcdcpbko_0.indexeddb.leveldb
rm * 2> /dev/null
unzip ~/Downloads/$filename
popd

