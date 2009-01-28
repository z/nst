#!/bin/bash
#
# Title: Nexuiz Ninjaz - Nexuiz Server Toolz Extended
# Created By: Tyler "-z-" Mulligan of the Nexuiz Ninjaz (www.nexuizninjaz.com)
#
# This script is an extension of the Nexuiz Server Toolz script to help
# manage game servers.  This file is included when you run NST if extend=true.
#

# Needed to work with aliases
core_dir=$(dirname $(which $0) | sed 's/\/[a-Z0-9_-]*\/[a-Z0-9_-]*\/.$//' )

# Include config
source $core_dir/config/base.conf

# Example function
function example() {
	echo -e "[I'm an example] $1 $2 $3"
}

# Extended Help
nn_servers_ext_help ()
{
	#cd $core_dir
	#core_file=$(ls *.sh |grep nst_core |tail -n1)
	#./$core_file --nn_servers_help
	
echo "
+==============================+
|  Extended Example Functions  |
+==============================+

--example function [param 1] [param 2] [param 3]		An example of an extended function passing 3 parameters
"
} # End nn_servers_ext_help

# Case swtich to filter params
case $1 in
  --example) example $2 $3 $4;;		# Search packages for a string
  --ext_help) nn_servers_ext_help;;			# command line parameter help
  *) nn_servers_ext_help;;					# gigo
esac
