#!/usr/bin/env bash

# Open a web page to the gateway to the current connection.
# This was written to get around how, too often, the "Login" page never auto-displays
# when connecting to a public network that requires accepting a license, logging in,
# etc. in order to access the network.
# For conveninence, I add a keyboard shortcut of Ctrl-Alt-G to bring this up when needed.

# This has been tested on Fedora 39 Cinnamon and works well.
# It should work under Ubuntu and downstream with little or no changes.

# Confirm there is a network connection

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

ip route > chk.net
if [[ -s chk.net ]]; then
    brave-browser $(ip route | grep -Po '(?<=via )(\d{1,3}.){4}')
else
    notify-send -i "$SCRIPT_DIR/warning.png" "Cannot find gateway.  Did you connect to WiFi?"
fi
