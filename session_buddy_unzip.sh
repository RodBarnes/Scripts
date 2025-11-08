#!/bin/bash

# This script assumed it is run from ~/Downloads since that is the logical
# for where the archive will be located.  Especially if using LocalSend.

source /usr/local/lib/colors

show_syntax() {
  echo "Syntax: $(basename $0) <filename>"
  echo "Where:  <filename> is the name of the archive containing the session buddy content"
  echo "NOTE: It is assumed the archive is located in ~/Downloads"
  exit  
}

# --------------------
# ------- MAIN -------
# --------------------

if [ $# -lt 1 ]; then
  show_syntax
fi


# Obtain the name of the archive
filename=$1

# Push into the target directory for the Session Buddy database
# Remove all current content, extract the contents of the archive, then pop back
pushd /home/$(whoami)/.config/BraveSoftware/Brave-Browser/Default/IndexedDB/chrome-extension_edacconmaakjimmfgnblocblbcdcpbko_0.indexeddb.leveldb
rm * 2> /dev/null
unzip ~/Downloads/$filename
popd

