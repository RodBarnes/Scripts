#!/bin/bash

#Syntax: add_copyright_xaml.sh <path_to_copyright_file>

curyear=$(date +'%Y')
ext_type=cs

for file in *; do
  [[ -f "$file" ]] || continue								# only regular files
  [[ "${file##*.}" != $ext_type ]] && continue				# skip other files

cat <<EOF > temp_out
/*
 * Copyright (c) $curyear Rod Barnes
 * See the LICENSE.txt file in the project root for specific restrictions.
 */
EOF

cat "$file" >> temp_out && mv temp_out "$file"

done