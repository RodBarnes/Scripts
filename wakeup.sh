#!/usr/bin/env bash
#v1.0

# Intended to be used in a cron job to set a wakeup everyday
# at a specific time.  The purpose being so that the system will wake from suspend
# and allow other, later cron jobs to run.

DIR=$(dirname $(readlink -f $0))
#echo "DIR=${DIR}"

STMT=$(basename $0)

source ${DIR}/colors.sh
function printx {
  printf "${YELLOW}$1${NOCOLOR}\n"
}

if [ $# -eq	 0 ]; then
	WAKETIME='03:29'
else
	WAKETIME=$1
fi

# Get the current suspend timeout
SUSPEND_TIMEOUT=$(gsettings get org.cinnamon.settings-daemon.plugins.power sleep-inactive-ac-timeout)

# Disable suspend
gsettings set org.cinnamon.settings-daemon.plugins.power sleep-inactive-ac-timeout 0

# iDrive login
sudo /opt/IDriveForLinux/bin/idrive --login

# iDrive backup
sudo /opt/IDriveForLinux/bin/idrive --backup

# Enable suspend
gsettings set org.cinnamon.settings-daemon.plugins.power sleep-inactive-ac-timeout $SUSPEND_TIMEOUT

# Set the system to wake tomorrow at specified time
TIMEVAL=$(date -d "tomorrow $WAKETIME" '+%s')
sudo rtcwake -m no -l -t "$TIMEVAL"

