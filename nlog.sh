#!/bin/bash

# Usage
# nlog <dir>

source /usr/local/lib/colors
function printx {
  printf "${YELLOW}$1${NOCOLOR}\n"
}

STMT=$(basename $0)
if [[ $# < 1 ]]; then
  printx "Syntax: $STMT 'directory'\nWhere:  directory is the name of the location where the log should be stored"
  exit
fi

# Get the current user and create the filename
USER=$(whoami)
LOGFILE="$1/notifications_${USER}.log"

# Clear the log from previous sessions
rm $LOGFILE 2> /dev/null

# Monitor DBus for notification events
dbus-monitor "interface='org.freedesktop.Notifications'" | while read -r line; do
    # Check for the start of a "Notify" method call
    if [[ "$line" == *"member=Notify"* ]]; then
        app_name=""
        icon=""
        title=""
        body=""
        hints=""
        capturing_body=false

        # Read subsequent lines for details
        while read -r line; do
            # Capture app name, icon, title, or start capturing body
            if [[ "$line" == *"string \""* ]]; then
                value=$(echo "$line" | sed 's/^.*string "\(.*\)"/\1/')
                
                if [ -z "$app_name" ]; then
                    app_name="$value"
                elif [ -z "$icon" ]; then
                    icon="$value"
                elif [ -z "$title" ]; then
                    title="$value"
                else
                    capturing_body=true
                    body="$value"
                fi
            elif $capturing_body; then
                # Continue capturing body text if we're in the body section
                if [[ "$line" == *"array ["* ]]; then
                    capturing_body=false
                else
                    # Strip leading spaces and trailing quotes from the body
                    line=$(echo "$line" | sed -e 's/^ *//' -e 's/"$//')
                    body+=" $line"
                fi
            elif [[ "$line" == *"dict entry("* ]]; then
                capturing_body=false
                hint_key=""
                hint_value=""
            elif [[ "$line" == *"string \""* ]]; then
                if [ -z "$hint_key" ]; then
                    hint_key=$(echo "$line" | sed 's/.*string "\(.*\)"/\1/')
                else
                    hint_value=$(echo "$line" | sed 's/.*string "\(.*\)"/\1/')
                    hints+="$hint_key: $hint_value\n"
                fi
            elif [[ "$line" == *"]"* ]]; then
                break
            fi
        done

        # Remove the `string "` prefix and trailing `"` from the body, and trim leading/trailing whitespace
        body="${body#string \"}"
        body="${body%\"}"
        body="$(echo -e "${body}" | sed -e 's/^[[:space:]]*//')"

        # Prepare the formatted notification summary
        notification="App Name:$app_name, "
        notification+="Icon:$icon, "
        notification+="Title:$title, "
        notification+="Body:$body, "
        notification+="Hints:$hints"

        # Output the notification summary
        echo "$notification" >> $LOGFILE
    fi
done
