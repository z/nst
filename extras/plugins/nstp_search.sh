#!/bin/bash
#
# Title: Nexuiz Ninjaz - Nexuiz Server Toolz Extension: Search
# Created By: Tyler "-z-" Mulligan of the Nexuiz Ninjaz (www.nexuizninjaz.com)
#
# This script allows admins to extend Nexuiz Server Toolz with their own
# functions This file is called by nn_server_toolz.sh if extend=true in your base.conf
#
# Usage: ./nn_server_toolz.sh --()
# 		 type --ext_help for more
#
# Note: If Using independent from Nexuiz Server Toolz, call file by
# name, i.e. ./nn_nstext_search.sh --search_packs my_string
#
# todo - make search string qouted or reverse parameters
#

# include the global shiz
source plugin.inc

# Search packs searches all packages in your data directory
search_packs() {
	
	# Get Gametype
	if [[ "$1" != "" ]]; then
		string=$1
	else
		echo; echo "[YOU FAIL] How can I search packages for nothing?"
		exit 1
	fi
	
	# Handle Optional Directory Parameter
	if [[ "$2" != "" ]]; then
		if [[ -d "$2" ]]; then
			d=$2
		fi
	else
		d=~/.nexuiz/data
	fi
	
	# Get the a list of all packages
	for package in $( ls $d/*.pk3 ); do
		echo "Searhing: " $package
		
		# List contents, grab the name of the bsp, remove the folder name, drop any bsp not in the maps folder
		search_string=`unzip -l $package | grep $string | awk '{ print $4 }'`
		# If the string is found
		if [[ "$search_string" != "" ]]; then
			echo -e "\n  -- found --> " $search_string "\n"
		fi
	done
	
} # End search_packs

# Extended Help
help ()
{
echo -e "\n
+=========================+
|  NSTP Search Functions  |
+=========================+

--search_packs [string] [directory]			Searches all packages in your data directory
						
							[string]:	grep is used to search the packages.  man grep for more information.		
						
							[directory]:	(Optional) if you wan to use a folder other than ~/.nexuiz/data
"
} # End help

#set -- `echo "$1" | tr [:upper:] [:lower:]`
case $1 in
  --search_packs) search_packs $2 $3;;	# Search packages for a string
  --help) help;;						# command line parameter help
  *) help;;								# gigo
esac
