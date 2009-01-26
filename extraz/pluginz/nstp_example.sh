#!/bin/bash
#
# Title: Nexuiz Ninjaz - Nexuiz Server Toolz Extended
# Created By: Tyler "-z-" Mulligan of the Nexuiz Ninjaz (www.nexuizninjaz.com)
#
# This script is an extension of the Nexuiz Server Toolz script to help
# manage game servers.  This file is included when you run NST if extend=true.
#

# Example function
function example() {
	echo -e "[I'm an example] $1 $2 $3"
}

# Extended Help
nn_servers_ext_help ()
{
	core_file=$(ls nst_core*.sh |egrep "[0-9]{6}" |sort -r |head -n 1)
	./$core_file --nn_servers_help
	
echo "
+======================+
|  Extended Functions  |
+======================+

--example function [param 1] [param 2] [param 3]		An example of an extended function passing 3 parameters
"
} # End nn_servers_ext_help

# Case swtich to filter params
case $1 in
  --example) example $2 $3 $4;;		# Search packages for a string
  --ext_help) nn_servers_ext_help;;			# command line parameter help
  *) nn_servers_ext_help;;					# gigo
esac
