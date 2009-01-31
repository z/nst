#!/bin/bash
#
# Title: NST - Automaps
# Created By: Tyler "-z-" Mulligan of the Nexuiz Ninjaz (www.nexuizninjaz.com)
#
# This plugin automates some of the map mangaging process
#

# include the global shiz
source plugin.inc

# Used to dynamically build a maplist based on the pk3's in your directory rather
# than rely on the g_maplist="" emergency override
function create_maplist {
	# Start the maplist string
	i="g_maplist=\""
	
	# Get Gametype
	if [[ "$1" != "" ]]; then
		t=$1
	else
		echo; echo "[WARNING] No gametype has been set, setting to dm"
		t="dm"
	fi
	
	# Handle Optional Directory Parameter
	if [[ "$2" != "" ]]; then
		if [[ -d "$2" ]]; then
			d=$2
		fi
	else
		d=~/.nexuiz/data
	fi

	# Get the a list of all properly packaged bsps
	for map in $(ls $d/*.pk3); do
		
		# Used to tell if the package mapinfo and generate map info exist
		m=false
		m2=false
		
		# List contents, grab the name of the bsp, remove the folder name, drop any bsp not in the maps folder
		mapname=$(unzip -l $map | grep .bsp | awk '{ print $4 }' | sed 's/maps\/\([A-Za-z_0-9.-]*\)\.bsp/\1/' | grep -vi .bsp)
		# If a map bsp is present
		if [[ "$mapname" != "" ]]; then
		
			# Check mapinfo's gametype against $t
			echo
			game_type=$(unzip -p $map maps/$mapname.mapinfo | grep "^type")
			
			if [[ "$game_type" != "" ]]; then
				echo "Checking package ($map) for mapinfo: [OK]"
				m=true
				
				game_type=$(unzip -p $map maps/$mapname.mapinfo | grep "^type $t")
				if [[ "$game_type" == "" ]]; then
					echo "Checking mapinfo for gametype compatiability ($mapname): [NO]"
				else
					# The mapinfo from the package has this gametype
					echo "Checking mapinfo for gametype compatiability ($mapname): [OK]"
				fi
			else
				echo "Checking package ($mapname) for mapinfo: [FAILED]"
			fi
			
			# If it doesn't exist, check the generated mapinfo folder
			if [[ "$game_type" == "" ]]; then
			
				echo "Checking ~/.nexuiz/data/data/maps/ for generated mapinfo: $mapname.mapinfo"
				cd ~/.nexuiz/data/data/maps/

				if [[ ! -r "$mapname.mapinfo" ]]; then
					echo "[WARNING] No generated mapinfo found for $mapname - not adding to list"
					status="warning"
				else
					# the generated mapinfo file exists
					echo "Check for generated $mapname.mapinfo file: [OK]"
					m2=true
										
					game_type=$(grep "^type $t" $mapname.mapinfo)
					
					if [[ "$game_type" != "" ]]; then
						# The check for the generated mapinfo compatiability passed
						echo "Checking generated mapinfo for gametype compatiability ($t): [OK]"
					fi
				fi
			fi
			
			# Everything looks good, add it to the list.
			if [[ "$game_type" != "" ]]; then
				# Print with quotes and a comma then append to string 'i'
				echo "[ADDING] $mapname to the list"
				mapname="$t"\_"$mapname "
				i=$i$mapname
			else
				if [[ $m2 == true ]]; then
					echo "Checking generated mapinfo for gametype compatiability ($t): [NO]"
				fi
			fi

		fi
	done

	# Trim the last space and echo maplist
	i=$(echo $i | sed 's/ $//')
	i=$i"\""
	
	if [[ "$status" == "warning" ]]; then
		echo; echo "[WARNING] Some maps weren't added because no mapinfo files were found.  Some maps may not be included!  Restart Nexuiz to generate them automatically, then run this script again."
	fi
	
	echo; echo "-- Printing $t Maplist -----------"; echo; echo $i; echo
} # End create_maplist

# Example function
function maps2server() {
	# Get Gametype
	if [[ "$1" != "" ]]; then
		t=$1
	else
		echo -e "\n[FAIL] No gametype has been set, please set it and try again"
		exit 0
	fi
	
	# Server name
	if [[ "$2" != "" ]]; then
		d=$2
	else
		echo -e "\n[FAIL] No servername has been set, please set it and try again.  You need to have a directory by that name in your extras/files directory."
		exit 0
	fi
	
	# Get the a list of all properly packaged bsps
	cd $core_dir/extras/map_pool
	for map in $(ls *.pk3); do
		cd $core_dir/extras/map_pool
		
		# Used to tell if the package mapinfo and generate map info exist
		m=false
		m2=false
		
		# List contents, grab the name of the bsp, remove the folder name, drop any bsp not in the maps folder
		mapname=$(unzip -l $map | grep .bsp | awk '{ print $4 }' | sed 's/maps\/\([A-Za-z_0-9.-]*\)\.bsp/\1/' | grep -vi .bsp)
		# If a map bsp is present
		if [[ "$mapname" != "" ]]; then
		
			# Check mapinfo's gametype against $t
			echo
			game_type=$(unzip -p $map maps/$mapname.mapinfo | grep "^type")
			
			if [[ "$game_type" != "" ]]; then
				echo "Checking package ($map) for mapinfo: [OK]"
				m=true
				
				game_type=$(unzip -p $map maps/$mapname.mapinfo | grep "^type $t")
				if [[ "$game_type" == "" ]]; then
					echo "Checking mapinfo for gametype compatiability ($mapname): [NO]"
				else
					# The mapinfo from the package has this gametype
					echo "Checking mapinfo for gametype compatiability ($mapname): [OK]"
				fi
			else
				echo "Checking package ($mapname) for mapinfo: [FAILED]"
			fi
			
			# If it doesn't exist, check the generated mapinfo folder
			if [[ "$game_type" == "" ]]; then
			
				echo "Checking ~/.nexuiz/data/data/maps/ for generated mapinfo: $mapname.mapinfo"
				cd ~/.nexuiz/data/data/maps/

				if [[ ! -r "$mapname.mapinfo" ]]; then
					echo "[WARNING] No generated mapinfo found for $mapname - not adding to list"
					status="warning"
				else
					# the generated mapinfo file exists
					echo "Check for generated $mapname.mapinfo file: [OK]"
					m2=true
										
					game_type=$(grep "^type $t" $mapname.mapinfo)
					
					if [[ "$game_type" != "" ]]; then
						# The check for the generated mapinfo compatiability passed
						echo "Checking generated mapinfo for gametype compatiability ($t): [OK]"
					fi
				fi
			fi
			
			# Everything looks good, add it to the list.
			if [[ "$game_type" != "" ]]; then
				echo "[LINKING] $mapname"
				ln -s $core_dir/extras/map_pool/$map $core_dir/extras/files/$d/$map
			else
				if [[ $m2 == true ]]; then
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

--create_maplist [gametype] [directory]			Create a maplist for a specific gametype based on the maps found
							in your data directory (default folder: ~/.nexuiz/data/)
								
							[gametype]:	(dm|tdm|ctf|lms|dom ... etc)
									default gametype is dm
										
							[directory]:	(Optional) if you wan to use a folder other than ~/.nexuiz/data
							
--maps2server <gametype> <server>			links all maps from the map pool of a specified gametype to a files/<server> director
"
} # End help

# Case swtich to filter params
case $1 in
  --create_maplist) create_maplist $2 $3;;	# create maplist for the passed <gametype> <directory>
  --maps2server) maps2server $2 $3;;		# Search packages for a string
  --help) help;;							# command line parameter help
  *) help;;									# gigo
esac
