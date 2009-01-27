#!/bin/bash
#
# !! WARNING !! THIS SCRIPT IS A MESS AND INCOMPLETE !!!!!!!!
#
# Title: Nexuiz Ninjaz - Nexuiz Server Toolz Extended
# Created By: Tyler "-z-" Mulligan of the Nexuiz Ninjaz (www.nexuizninjaz.com)
#
# This script is an extension of the Nexuiz Server Toolz script to help
# manage game servers.  This file is included when you call
# nn_server_toolz.sh if extend=true.
#
# Usage: ./nn_server_toolz.sh --()
# 		 type --ext_help for more
#

# Needed to work with aliases
core_dir=$(dirname $(which $0) | sed 's/\/[a-Z0-9_-]*\/[a-Z0-9_-]*\/.$//' )

# Include config
source $core_dir/config/base.conf

# Install Nexuiz from SVN
#install_nexuiz() {
	#cd $core_dir
	#cd ../../install && chmod +x nst_install.sh
	#./nst_install.sh
#}

# Install Nexuiz from SVN
install_nexuiz_old() {
	# Get Install Folder Name
	if [ "$1" != "" ]; then
		dirname=$1
	else
		echo; echo "[YOU FAIL] I need a folder name"
		exit 1
	fi
	
	mkdir -p ~/nn_servers/svn && cd ~/nn_servers/svn
	svn co svn://svn.icculus.org/nexuiz/trunk
	svn co svn://svn.icculus.org/twilight/trunk/darkplaces
	svn co https://fteqw.svn.sourceforge.net/svnroot/fteqw/trunk/engine/qclib/ 
	
	compile_nexuiz svn
}

image_colorize() {
	# 1 = image name 2 = folder name
	for image in $(locate $1 |grep $2); do
		mogrify -modulate 100,0,0  $image
	done
}

image_format() {
	# 1 = image name 2 = folder name
	for image in $(locate $1 |grep $2 | grep -v ".svn"); do
		echo "processing image: $image"
		mogrify -format jpg $image
	done
	ls -R $2
}

rcon_old() {
	head -n3 $core_dir/config/serverz/rcon2irc/$1\.conf | tail -n2 | sed 's/ = /=/' > $core_dir/config/serverz/rcon2irc/temp_rcon.conf
	source $core_dir/config/serverz/rcon2irc/temp_rcon.conf
	echo "rcon to: $dp_server"
	#echo "execing command: "rcon_address=$dp_server rcon_password=$dp_password $basedir/Docs/server/./rcon.pl "$2 $3 $4"
	rcon_address=$dp_server rcon_password=$dp_password $basedir/Docs/server/./rcon.pl "$2 $3 $4"
	rm $core_dir/config/serverz/rcon2irc/temp_rcon.conf
}


# you can pass up to 3 arguments
update_nexuiz() {

	# Get Install Folder Name
	if [ "$1" != "" ]; then
		dirname=$1
	else
		echo; echo "[YOU FAIL] I need a folder name"
		exit 1
	fi
	
	# get old rev
	cd $dirname/darkplaces
	DP_SVNVERS_OLD=`svn info | grep Revision | awk '{print $2}'`
	cd $dirname/trunk
	NEX_SVNVERS_OLD=`svn info | grep Revision | awk '{print $2}'`
	cd $dirname/qclib
	QC_SVNVERS_OLD=`svn info | grep Revision | awk '{print $2}'`

	echo " Begin of svn up..."
	cd $dirname/trunk
	svn up
	#svn co svn:/svn.icculus.org/twilight/trunk/darkplaces
	cd $dirname/darkplaces
	svn up
	#svn co svn:/svn.icculus.org/nexuiz/trunk
	cd $dirname/qclib
	svn up

	# get new rev
	cd $dirname/darkplaces
	DP_SVNVERS_NEW=`svn info | grep Revision | awk '{print $2}'`
	cd $dirname/trunk
	NEX_SVNVERS_NEW=`svn info | grep Revision | awk '{print $2}'`
	cd $dirname/qclib
	QC_SVNVERS_NEW=`svn info | grep Revision | awk '{print $2}'`
	
	# write new rev to logfile
	cd $dirname
	echo "`date`   DP_$DP_SVNVERS_NEW    NEX_$NEX_SVNVERS_NEW    QC_$QC_SVNVERS_NEW" >> cos.log
}

# you can pass up to 3 arguments
compile_nexuiz() {

	# Get Install Folder Name
#	if [ "$1" != "" ]; then
#		dirname=$1
#	else
#		echo; echo "[YOU FAIL] I need a folder name"
#		exit 1
#	fi
	
	echo "Begin of build..."
	# qcc
	#if [ $QC_SVNVERS_NEW != $QC_SVNVERS_OLD ]; then
		cd ~/nn_servers/svn/qclib
		make
	#fi

	# nexuiz
	#if [ $NEX_SVNVERS_NEW != $NEX_SVNVERS_OLD ]; then
		cd ~/nn_servers/svn/trunk/data/qcsrc/client
		~/nn_servers/svn/qclib/fteqcc.bin 
		cd ~/nn_servers/svn/trunk/data/qcsrc/server
		~/nn_servers/svn/qclib/fteqcc.bin 
		cd ~/nn_servers/svn/trunk/data/qcsrc/menu
		~/nn_servers/svn/qclib/fteqcc.bin 
	#fi

	# darkplaces
	#if [ $DP_SVNVERS_NEW != $DP_SVNVERS_OLD ]; then
		cd ~/nn_servers/svn/darkplaces/
		make clean
		#make CC="gcc -g -arch i386 -arch ppc -isysroot /Developer/SDKs/MacOSX10.4u.sdk" cl-nexuiz
		#make cl-nexuiz
		make sv-nexuiz
	#fi
}

# Search packs searches all packages in your data directory
search_packs() {
	
	# Get Gametype
	if [ "$1" != "" ]; then
		string=$1
	else
		echo; echo "[YOU FAIL] How can I search packages for nothing?"
		exit 1
	fi
	
	# Handle Optional Directory Parameter
	if [ "$2" != "" ]; then
		if [ -d "$2" ]; then
			d=$2
		fi
	else
		d=~/.nexuiz/data
	fi
	
	# Get the a list of all packages
	for package in $( ls $d/*.pk3 ); do
		echo "Searching: " $package
		
		# List contents, grab the name of the bsp, remove the folder name, drop any bsp not in the maps folder
		search_string=`unzip -l $package | grep $string | awk '{ print $4 }'`
		# If the string is found
		if [ "$search_string" != "" ]; then
			echo -e "\n  -- found --> " $search_string "\n"
		fi
	done
	
} # End search_packs

# Extended Help
nn_servers_ext_help ()
{
	# how about this hackjob?
	cd $core_dir
	core_file=$(ls nst_core*.sh |egrep "[0-9]{6}" |sort -r |head -n 1)
	./$core_file --nn_servers_help
	
echo "
+======================+
|  Extended Functions  |
+======================+

--install_nexuiz [directory]			This installs Nexuiz

--search_packs [string] [directory]		Searches all packages in your data directory
						
						[string]:	grep is used to search the packages.  man grep for more information.		
						
						[directory]:	(Optional) if you wan to use a folder other than ~/.nexuiz/data
"
} # End nn_servers_ext_help

# Case swtich to filter params
case $1 in

  --image_colorize) image_colorize $2 $3;;	# Updates your SVN install
  --image_format) image_format $2 $3;;	# changes the format of a directory of images
  --rcon_old) rcon_old $2 $3 $4 $5;;				# Updates your SVN install
  --update_nexuiz) update_nexuiz $2;;		# Updates your SVN install
  --compile_nexuiz) compile_nexuiz $2;;		# Compiles your SVN install
  --search_packs) search_packs $2 $3;;		# Search packages for a string
  --ext_help) nn_servers_ext_help;;			# command line parameter help
  *) nn_servers_ext_help;;					# gigo
esac
