#!/usr/bin/env bash
#v1.0

source /usr/local/lib/colors
function printx {
  printf "${YELLOW}$1${NOCOLOR}\n"
}

# Show how long a process has been running
STMT=$(basename $0)

if [ -z $1 ]; then
	printx "Syntax: $STMT <program_name> [<user>]"
	exit 1
fi

# Get the arguments
# 1st argument is the program for which to search
# 2nd argument is the user -- defaults to current user
# See if used bash to execute
if [ $1 == "bash" ]; then
	PROGNAME=$2
	CUSER=$3
else
	PROGNAME=$1
	CUSER=$2
fi

if [ -z $CUSER ]; then
	CUSER=$USER
fi

SRCHNAME="[${PROGNAME:0:1}]${PROGNAME:1:100}"

# Get the process entry
PS_ENTRY=$(ps -u $CUSER -o etime,cmd | grep "${SRCHNAME}")
ETIME=$(echo $PS_ENTRY | cut -d' ' -f 1)
if [ $ETIME == "00:00" ]; then
	echo "Process '$PROGNAME' not found"
	exit 1
fi

echo $ETIME $PROGNAME

