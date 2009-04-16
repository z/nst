#!/bin/bash
#
# Title: Nexuiz Ninjaz - -z-'s map tools
# Created By: Tyler "-z-" Mulligan of the Nexuiz Ninjaz (www.nexuizninjaz.com)
#
# This script is an extension of the Nexuiz Server Toolz script to help
# manage game servers.
#

# include the global shiz
source plugin.inc

# Example function
function css_desaturate() {
	cp /var/www/experiments/css_desaturate/css/$1 /var/www/experiments/css_desaturate/css/desaturated.css
	for line in $(grep -i "\#\([0-9a-f]\{3\}\|[0-9a-f]\{6\}\)" /var/www/experiments/css_desaturate/css/${1}); do
		#echo $line
		color=$(echo $line | grep -i "\#\([0-9a-f]\{3\}\|[0-9a-f]\{6\}\)" | sed 's/.*\#\([0-9a-f]\{6\}\|[0-9a-f]\{3\}\).*/\#\1/gi')
		if [[ "$color" != "" ]]; then
			desaturated=$(hex_desaturate $color)
			echo $color " to " $desaturated
			sed -i "s/${color}/${desaturated}/g" /var/www/experiments/css_desaturate/css/desaturated.css
		fi
	done
}

function hex_desaturate() {
	echo $1 | sed 's/\#\([0-9a-f]\{1\}\|[0-9a-f]\{2\}\)\([0-9a-f]\{1\}\|[0-9a-f]\{2\}\)\([0-9a-f]\{1\}\|[0-9a-f]\{2\}\)/\1 \2 \3/gi' | sed 's/\([0-9a-f]\)\{1\} \([0-9a-f]\)\{1\} \([0-9a-f]\)\{1\}/\1\1 \2\2 \3\3/gi' | awk '{ printf "%d\n%d\n%d\n\n", "0x" $1, "0x" $2, "0x" $3 }' | sort -g | tail -n1 | awk '{ printf "#%02X%02X%02X\n", $1, $1, $1 }'
}

# Example function
function revision() {
	
	# needs to be made dynamic
	cd ~/.nexuiz/data
	
	package_name=$1
	map_name=$(echo $package_name | sed 's/^map-//' | sed 's/.pk3$//')

	mkdir map_temp
	unzip $package_name -d map_temp
	cd map_temp
	
	#old_revision=$(ls -R | grep .bsp | awk -F .bsp '{ print $1 }' | awk -F _ '{ print $NF }' | awk -F r '{ print $NF }')
	old_revision=$(ls -R | grep .bsp | sed -e 's/^.*r\([0-9]*\).bsp$/\1/')
	new_revision=$(($old_revision+1))

	echo -e "\nConverting $package_name to revision: $new_revision\n"

	# Update all the file names
	map_files=$(find -type f -print | grep "${map_name}" | grep -v .pk3 )
	for file in $map_files; do
		echo "Renaming file: $file"
		mv $file $(echo $file | sed "s/${old_revision}/${new_revision}/")
	done
	
	new_package_name=map-$(echo $map_name | sed "s/${old_revision}/${new_revision}/").pk3
	
	echo -e "\nRepackaging as $new_package_name\n"
	zip -r $new_package_name . -x *.pk3
	
	mv *.pk3 ..
	cd ..
	rm -R map_temp
	
	echo -e "\nComplete\n"
}

# Extended Help
help ()
{
echo -e "\n
+====================+
|  -z-'s Map Tools   |
+====================+

--revision <map name> <directory>
"
} # End help

# Case swtich to filter params
case $1 in
  --css_desaturate) css_desaturate $2;;			# Search packages for a string
  --revision) revision $2;;			# Search packages for a string
  --help) help;;					# command line parameter help
  *) help;;							# gigo
esac
