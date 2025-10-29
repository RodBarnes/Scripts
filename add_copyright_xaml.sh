#!/bin/bash

# Could not get this to work with the CS delimiters so
# created a separate script for CS

#Syntax: add_copyright_xaml.sh <path_to_copyright_file>

insert_filepath=$1

curyear=$(date +'%Y')
ext_type=xaml

getdel() {
	case "${!1}" in
		xaml)
			comment_start="<!--"
			comment_end="-->"
			;;
		cs)
			comment_start="/*"
			comment_end="*/"
			;;
		*) echo "Unreconized extension ${!1}";;
	esac
}

getdel ext_type

cat <<EOF > xaml_header
<!-- \n * Copyright (c) $curyear Rod Barnes\n * See the LICENSE.txt file in the project root for specific restrictions.\n -->
EOF

comment=`cat xaml_header`
rm xaml_header

for file in *; do
	[[ -f "$file" ]] || continue					# only regular files
	[[ "${file##*.}" != $ext_type ]] && continue	# skip other files
	sed -i "2i\\$comment" "$file"
done
