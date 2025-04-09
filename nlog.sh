#!/bin/bash

# Usage
# nlog <path_to_file>

# Clear the log from previous sessions
rm "$1"

# Output function to handle printing to either stdout or a file
output() {
    if [ -n "$logfile" ]; then
        echo -e "$1" >> "$logfile"
    else
        echo -e "$1"
    fi
}

# Check if a filename argument is provided
logfile=""
if [ -n "$1" ]; then
    logfile="$1"
    # Create the directory if it doesn't exist
    logdir=$(dirname "$logfile")
    mkdir -p "$logdir"
    touch $logfile
fi

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
        notification="----------------------------------\n"
        notification+="App Name: $app_name\n"
        notification+="Icon: $icon\n"
        notification+="Title: $title\n"
        notification+="Body: \n$body\n"
        notification+="Hints:\n$hints\n"

        # Output the notification summary
        output "$notification"
    fi
done
