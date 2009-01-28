#!/bin/bash
#
# Title: Nexuiz Ninjaz - Nexuiz Server Toolz Extended
# Created By: Tyler "-z-" Mulligan of the Nexuiz Ninjaz (www.nexuizninjaz.com)
#
# This script is an extension of the Nexuiz Server Toolz script to help
# manage game servers.  This file is included when you run NST if extend=true.
#

# Needed to work with aliases
core_dir=$(cd $(dirname $0); pwd | sed 's#extraz/pluginz##')

# Include config
source $core_dir/config/base.conf

# Example function
function example() {
	echo -e "[I'm an example] $1 $2 $3"
}

# Extended Help
help ()
{
echo -e "\n
+==============================+
|  Extended Example Functions  |
+==============================+

--example function [param 1] [param 2] [param 3]	An example of an extended function passing 3 parameters
"
} # End help

# Case swtich to filter params
case $1 in
  --example) example $2 $3 $4;;		# Search packages for a string
  --help) help;;					# command line parameter help
  *) help;;							# gigo
esac
