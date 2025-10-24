#!/usr/bin/env bash
#v1.0

source /usr/local/lib/colors
function printx {
  printf "${YELLOW}$1${NOCOLOR}\n"
}

# Show how long a process has been running
scriptname=$(basename $0)

if [ -z $1 ]; then
	printx "Syntax: $scriptname <program_name> [<user>]"
	exit 1
fi

# Get the arguments
# 1st argument is the program for which to search
# 2nd argument is the user -- defaults to current user
# See if used bash to execute
if [ $1 == "bash" ]; then
	progname=$2
	cuser=$3
else
	progname=$1
	cuser=$2
fi

if [ -z $cuser ]; then
	cuser=$USER
fi

srchname="[${progname:0:1}]${progname:1:100}"

# Get the process entry
PS_ENTRY=$(ps -u $cuser -o etime,cmd | grep "${srchname}")
etime=$(echo $PS_ENTRY | cut -d' ' -f 1)
if [ $etime == "00:00" ]; then
	echo "Process '$progname' not found"
	exit 1
fi

echo $etime $progname

