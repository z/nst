#!/bin/bash
#
# Title: NST - Automaps
# Created By: Tyler "-z-" Mulligan of the Nexuiz Ninjaz (www.nexuizninjaz.com)
#
# This plugin automates some of the map mangaging process
#

# Needed to work with aliases
core_dir=$(cd $(dirname $0); pwd | sed 's#/extraz/pluginz##')

# Include config
source $core_dir/config/base.conf

# Example function
function maps2server() {
	# Get Gametype
	if [ "$1" != "" ]; then
		t=$1
	else
		echo -e "\n[FAIL] No gametype has been set, please set it and try again"
		exit 0
	fi
	
	# Server name
	if [ "$2" != "" ]; then
		d=$2
	else
		echo -e "\n[FAIL] No servername has been set, please set it and try again.  You need to have a directory by that name in your extraz/files directory."
		exit 0
	fi
	
	# Get the a list of all properly packaged bsps
	cd $core_dir/extraz/map_pool
	for map in $(ls *.pk3); do
		cd $core_dir/extraz/map_pool
		
		# Used to tell if the package mapinfo and generate map info exist
		m=false
		m2=false
		
		# List contents, grab the name of the bsp, remove the folder name, drop any bsp not in the maps folder
		mapname=$(unzip -l $map | grep .bsp | awk '{ print $4 }' | sed 's/maps\/\([A-Za-z_0-9.-]*\)\.bsp/\1/' | grep -vi .bsp)
		# If a map bsp is present
		if [ "$mapname" != "" ]; then
		
			# Check mapinfo's gametype against $t
			echo
			game_type=$(unzip -p $map maps/$mapname.mapinfo | grep "^type")
			
			if [ "$game_type" != "" ]; then
				echo "Checking package ($map) for mapinfo: [OK]"
				m=true
				
				game_type=$(unzip -p $map maps/$mapname.mapinfo | grep "^type $t")
				if [ "$game_type" == "" ]; then
					echo "Checking mapinfo for gametype compatiability ($mapname): [NO]"
				else
					# The mapinfo from the package has this gametype
					echo "Checking mapinfo for gametype compatiability ($mapname): [OK]"
				fi
			else
				echo "Checking package ($mapname) for mapinfo: [FAILED]"
			fi
			
			# If it doesn't exist, check the generated mapinfo folder
			if [ "$game_type" == "" ]; then
			
				echo "Checking ~/.nexuiz/data/data/maps/ for generated mapinfo: $mapname.mapinfo"
				cd ~/.nexuiz/data/data/maps/

				if [ ! -r "$mapname.mapinfo" ]; then
					echo "[WARNING] No generated mapinfo found for $mapname - not adding to list"
					status="warning"
				else
					# the generated mapinfo file exists
					echo "Check for generated $mapname.mapinfo file: [OK]"
					m2=true
										
					game_type=$(grep "^type $t" $mapname.mapinfo)
					
					if [ "$game_type" != "" ]; then
						# The check for the generated mapinfo compatiability passed
						echo "Checking generated mapinfo for gametype compatiability ($t): [OK]"
					fi
				fi
			fi
			
			# Everything looks good, add it to the list.
			if [ "$game_type" != "" ]; then
				echo "[LINKING] $mapname"
				ln -s $core_dir/extraz/map_pool/$map $core_dir/extraz/files/$d/$map
			else
				if [ $m2 == true ]; then
					echo "Checking generated mapinfo for gametype compatiability ($t): [NO]"
				fi
			fi

		fi
	done
}

# Extended Help
help ()
{
echo -e "\n
+======================+
|  Automaps Functions  |
+======================+

--maps2server <gametype> <server>			links all maps from the map pool of a specified gametype to a files/<server> director
"
} # End help

# Case swtich to filter params
case $1 in
  --maps2server) maps2server $2 $3;;	# Search packages for a string
  --help) help;;						# command line parameter help
  *) help;;								# gigo
esac
