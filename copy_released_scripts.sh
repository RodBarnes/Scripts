#!/usr/bin/env bash

sourcedir=$1
destdir=$2

while IFS= read -r file; do
  cp "$sourcedir/$file" "$destdir/${file%.sh}"
done < $sourcedir/released.txt