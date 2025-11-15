#!/usr/bin/env bash
#Version 1.1

# Intended to take a MVK ripped from a DVD and convert it to decent-video H.265

source /usr/local/lib/display.sh

STMT=$(basename $0)

if [[ $# < 2 ]]; then
  printx "Syntax: $STMT '<filepath>' '<outpath>'\nWhere:  <filepath> is the FQPN for the file to be processed and <outpath>\n        is the name of the path where the output file should be placed.\n"
  exit
fi

ENCODING=hevc_nvenc
CRF=20
BITRATE=384k

FILEPATH=$1
OUTPATH=$2

if [[ "$1" =~ /$ ]]; then
  # Assume mulitple files and loop through all
  for i in $FILEPATH*.mkv; do
    FILENAME=${i##*/}
    OUTFILE="$OUTPATH/$FILENAME"
    echo INFILE=$i
    echo OUTFILE=$OUTFILE
    ffmpeg -i "$i" -c:v $ENCODING -crf $CRF -preset slow -rc vbr_hq -c:a aac -b:a $BITRATE -c:s copy "$OUTPATH/$FILENAME"
    echo
  done
else
  # Explicit, single file if of type path/filename
  echo INFILE=$FILEPATH
  FILENAME=${FILEPATH##*/}
  OUTFILE="$OUTPATH/$FILENAME"
  echo OUTFILE=$OUTFILE
  ffmpeg -i "$FILEPATH" -c:v $ENCODING -crf $CRF -preset slow -rc vbr_hq -c:a aac -b:a $BITRATE -c:s copy "$OUTPATH/$FILENAME"
  echo
fi
