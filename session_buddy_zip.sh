#!/bin/bash

# This script assumed it is run from ~/Downloads since that is the logical
# for where the archive will be located.  Especially if using LocalSend.

# Get the date and create a filename that appends that date
dt=$(date '+%Y%m%d_%H%M%S');
filename="sessionbuddy_${dt}.zip"
path=~/Downloads

# Push into the target directory for the Session Buddy database
# Zip up the contents into an archive that is stored in ~/Downloads, then pop back
pushd /home/$(whoami)/.config/BraveSoftware/Brave-Browser/Default/IndexedDB/chrome-extension_edacconmaakjimmfgnblocblbcdcpbko_0.indexeddb.leveldb
zip $path/$filename *
popd

echo "Created $path/$filename"
