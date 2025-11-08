#!/usr/bin/env bash

# Names for terminal color codes for use with printx & readx

NOCOLOR='\033[0m' # No Color
GREEN='\033[0;32m' # Green
LTGREEN='\033[1;32m' # Light Green
BLUE='\033[0;34m' # Blue
LTBLUE='\033[1;34m' # Light Blue
BLACK='\033[0;30m' # Black
DKGRAY='\033[1;30m' # Light Gray
RED='\033[0;31m' # Red
LTRED='\033[1;31m' # Light Red
ORANGE='\033[0;33m' # Orange
YELLOW='\033[1;33m' # Yellow
PURPLE='\033[0;35m' # Purple
LTPURPLE='\033[1;35m' # Light Purple
CYAN='\033[0;36m' # Cyan
LTCYAN='\033[1;36m' # Light Cyan
LTGRAY='\033[0;37m' # Light Gray
WHITE='\033[1;37m' # White

# Display text using color
printx() {
  printf "${YELLOW}$1${NOCOLOR}\n"
}

# Read using color
readx() {
  printf "${YELLOW}$1${NOCOLOR}" >&2
  read $2
}

# Echo within a function to prevent it being part of the output
show() {
  echo "$*" >&2
}

# Printx within a function to prevent it being part of the output
showx() {
  printx "$*" >&2
}
