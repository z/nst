#!/bin/bash
#
# Nexuiz Ninjaz Proudly Present
# 
# Nexuiz Server Toolz
#
# Version: 0.98
# Released: 01/26/09
# Created By: Tyler "-z-" Mulligan of the Nexuiz Ninjaz (www.nexuizninjaz.com)
#
# Required Software: screen
# Optional Software: 'unzip' for package functions , 'qstat' for player numbers,
# 'svn' for nexuiz install, perl for rcon2irc
#
# Description:
# This script was created to help admins manage many instances of servers by loading them
# into seperate screens they can easily call by name.  For more information check --help.
#
# Usage: nexst --(start_all|stop_all|restart_all|start <server>|stop <server>|restart <server>|list|view <server>|edit <server>|rcon2irc (start |stop|restart|view) <server>|create_maplist <gametype>|help)
# 		 type --help for more
#
# Copyright (c) 2008 Tyler "-z-" Mulligan of www.nexuizninjaz.com
# 
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#

# DO NOT EDIT THIS SCRIPT TO CONFIGURE!! please edit your base.conf or extend
# this script with a plugin if you wish to easily update your NST core in
# the future

###############
# Globals
####################################################################

# Needed to work with aliases in .bashrc
core_dir=$(cd $(dirname $0); pwd)
# Just in case we need to access self
core_file=$(ls $core_dir |grep nst_core |tail -n1)

# Include config
source $core_dir/config/base.conf

###############
# Start Server Functions
####################################################################

# Starts all Nexuiz Servers
start_all()
{
	pgrep nexuiz-dedicate &> /dev/null && {
		echo -e "\n[ERROR] There are running servers.  Please use --restart.  Aborting.\n"
		exit 1
	}
	
	# This can be hardcoded because it's where QuakeC puts them unless -userdir flag is set
	if [ ! -d ~/.nexuiz/data/data/oldlogs ];then mkdir -p ~/.nexuiz/data/data/oldlogs;fi

	# check if basedir exists
	if [ ! -d $basedir ]; then
		echo -e "\n[FAIL] The basedir '$basedir' is incorrect, please edit your config and try again.\n"
		exit 1
	fi
	cd $basedir

	# for each moddir find configs and load them into screens

	# List any nn_server configs found
	for cfg in $(ls $core_dir/config/serverz/*.cfg); do
		cfgname=$(echo $cfg | awk -F/ '{print $NF}')
		screenname=$(echo $cfgname | awk -F . '{ print $1 }')
		
		start_server $screenname
	done
	list_servers
} # End start_all

# start an individual server by its cfg name minus .cfg
start_server()
{
	if [ "$1" != "" ]; then
		screenname=$1
		cfgname="$screenname.cfg"
		
		# check if basedir exists
		if [ ! -d $basedir ]; then
			echo -e "\n[FAIL] The basedir '$basedir' is incorrect, please edit your config and try again.\n"
			exit 1
		fi
		
		cd $basedir
		
		if [ -f $core_dir/config/serverz/$cfgname ]; then
			if [ ! -f ~/.nexuiz/data/$cfgname ]; then
				 ln -s $core_dir/config/serverz/$cfgname ~/.nexuiz/data/$cfgname
			fi
			echo -e "\n[Starting Server] $screenname"
			# This can be hardcoded because it's where QuakeC puts them -- THIS NEEDS TO BE UPDATED
			if [ ! -d ~/.nexuiz/data/data/oldlogs ];then mkdir -p ~/.nexuiz/data/data/oldlogs;fi
			if [ -f ~/.nexuiz/data/data/$screenname*.log ]; then
				mv ~/.nexuiz/data/data/$screenname*.log ~/.nexuiz/data/data/oldlogs
				echo -e " -- [Archiving Server Logs for: $screenname]"
			else
				echo -e " -- [No logs to archive for: $screenname]"
			fi
			
			# if there is a folder for this server in extraz/files -- start with that as the game dir
			if [ -d $core_dir/extraz/files/$screenname ];then
				screen -m -d -S $screenname $basedir/./nexuiz-dedicated -game $screenname +exec $cfgname -userdir logs
			# otherwise use .nexuiz
			else
				screen -m -d -S $screenname $basedir/./nexuiz-dedicated +exec $cfgname
			fi
			
			if [ "$auto_rcon" == "true" ]; then
				rcon2irc_start $screenname
			fi
		else
			echo -e "\n[ERROR] Config: $cfgname not found in $core_dir/config/serverz\n"
		fi
	# No server name was passed
	else
		echo -e "\nSyntax is: --start <server name>\n\n<server name> is built from your server cfg file name.\n\"nn_server_ctf_242.cfg\" would be titled \"ctf_242\".\nType --help for more.\n"
	fi
} #end start_server

stop_all()
{
	list_servers
	echo -e "\n[Stopping All]\n"
	for cfg in $(ls $core_dir/config/serverz/*.cfg); do
		cfgname=$(echo $cfg | awk -F/ '{print $NF}')
		screenname=$(echo $cfgname | awk -F . '{ print $1 }')
		
		stop_server $screenname
	done
	echo -e "\n[Stopped All]\n"
} # End stop_all

# stop a single server by it's session name
stop_server()
{
	if [ "$1" != "" ]; then
		gsname=$1
		requested=$(ps -ef | grep SCREEN | grep nexuiz-dedicated | grep -v grep | awk '{ print $12 }' | grep ^${gsname}$)

		if [ "$requested" != "" ]; then
			#pid=$(ps -ef | grep SCREEN | grep nexuiz-dedicated | grep -v grep | grep "+exec *\/.*${gsname}.cfg" | awk '{ print $2 }')
			pid=$(ps -ef | grep SCREEN | grep nexuiz-dedicated | grep -v grep | grep "+exec ${gsname}.cfg" | awk '{ print $2 }')
			pkill -P $pid
			if [ "$auto_rcon" == "true" ]; then
				rcon2irc_stop $gsname
			fi
			echo -e "[Stopped] $gsname\n"
		else
			echo "[ERROR] $gsname is not running"
		fi
	else
		echo -e "\nSyntax is: --stop <server name>\n\n<server name> is built from your server cfg file name.\n\"ctf_242.cfg\" would be titled \"ctf_242\".\nType --help for more.\n"
	fi
} # End stop_server

restart_all()
{
	stop_all
	echo "waiting 5 seconds to restart"
	sleep 1; echo "4"; sleep 1; echo "3"; sleep 1; echo "2"; sleep 1; echo "1";
	echo "Restarting"
	start_all
	#list_servers # Why is the grep for the port failing?
} # End restart_all

# Restarts a specific server
restart_server()
{
	if [ "$1" != "" ]; then
		gsname=$1
		
		requested=$(ps -ef | grep SCREEN | grep nexuiz-dedicated | grep -v grep | awk '{ print $12 }' | grep ^${gsname}$)

		if [ "$requested" != "" ]; then
			stop_server $gsname
			
			echo -e "\nRestarting $gsname in 5..."
		
			sleep 1; echo "4"; sleep 1; echo "3"; sleep 1; echo "2"; sleep 1; echo "1";
			start_server $gsname
		else
			echo -e "\n[ERROR] That server is not running."
			list_servers
			echo -e "[WARNING] No server was restarted.  Please type the name EXACTLY as you read it above.\n"
		fi
	else
		echo -e "\nNo Nexuiz servers are currently running\n"
	fi
} # End restart_server

list_servers() # Format all the current running servers in a easy to read way
{
	if [ "$( ps -ef | grep nexuiz-dedicated | grep SCREEN | grep -v grep )" != "" ]; then
		echo; echo -e "Currently Running Nexuiz Servers\n-----------------------------------------------------------------------------------------------------------------------"
		gsname=$(ps -ef | grep nexuiz-dedicated | grep SCREEN | grep -v grep | awk '{ print $12 }')
		
		ps -ef | grep nexuiz-dedicated | grep SCREEN | grep -v grep | awk '{printf "%s %s\n", $2, $12}' | while read gspid gsname
		do
			gscfg=$(echo $gsname | sed "s/\(.*\)/\1.cfg/")
			gsport=$(grep ^port -r $core_dir/config/serverz/${gscfg} | awk '{ print $2 }')
			gsaddress=$(grep ^net_address -r $core_dir/config/serverz/${gscfg} | awk '{ print $2 }')
			if [ "$gsaddress" == "" ]; then gsaddress="$base_address"; fi
			if [ "$qstat_enabled" == true ]; then
				gsplayers=$(qstat -P -nexuizs $gsaddress:$gsport | head -n 2 | tail -n 1 | awk '{ print $2 }')
			else
				gsplayers="enable qstat"
			fi
			
			rconstatus="no"
			if [ "$auto_rcon" == "true" ]; then
				rconscreen=$(screen -ls | grep $gsname | awk '{ print $1 }' | grep \.$gsname$ | grep "rcon_")
				if [ "$rconscreen" != "" ]; then
					rconstatus="yes"
				fi
			fi
			
			echo -e "Address:" $gsaddress:$gsport "\t  PID:" $gspid "  \tName:" $gsname "    \tPlayers:" $gsplayers "\trcon2irc:" $rconstatus
		done; echo
	else
		echo -e "\n[WARNING] No Nexuiz servers are currently running"
		echo -e "\n[ATTENTION] Here's a list of available cfgs:\n"
		ls $core_dir/config/serverz/ |grep .cfg
		echo
	fi
} # End list_servers

# Loads a specific server into screen
function view_server {
	if [ "$1" != "" ]; then
		gsname=$1
		
		screenid=$(screen -ls | grep $gsname | awk '{ print $1 }' | grep \.$gsname$ | grep -v "rcon_" | awk -F . '{ print $1 }')
		echo -e "\n!!!IMPORTANT!!! To get out of a screen, hold ctrl, then press a, then d\n\nPress enter to continue"
		read # pause until message is acknowledged
		screen -r ${screenid}
	else
		echo -e "\n[ERROR] No server specified\n"
	fi
} # End view_server

###############
# Start rcon2irc Functions
####################################################################

# Routes rcon2irc commands
function rcon2irc_router {
	case $1 in
	  start) rcon2irc_start $2;;				# start a specific rcon2irc bot
	  stop) rcon2irc_stop $2;;					# stop a specific rcon2irc bot
	  restart) rcon2irc_restart $2;;			# restart a specific rcon2irc bot
	  restart_all) rcon2irc_restart_all;;		# restarts all rcon2irc bots
	  view) rcon2irc_view $2;;					# view a specific rcon2irc bot
	  *) echo -e "nah, that's not a function";;
	esac
}

# Starts an rcon2irc server by name
function rcon2irc_start {
	if [ "$1" != "" ]; then
		screenname=$1
		confname="$screenname.conf"
		# If an rcon2irc config exists, start it.
		if [ -f $core_dir/config/serverz/rcon2irc/$confname ]; then	
			echo -e "[Starting rcon2irc bot] $screenname\n"
			screen -m -d -S rcon_$screenname /usr/bin/perl $basedir server/rcon2irc/rcon2irc.pl $core_dir/config/serverz/rcon2irc/$confname
		else
			echo -e "\n -- [tip] If you create a file in your '$core_dir/config/serverz/rcon2irc' folder called '$confname' per div's rcon2irc requirements, it will automatically be loaded.\n"
		fi
	else
		echo -e "\nSyntax is: --rcon2irc start <server name>\n\n<server name> is built from your server cfg file name.\n\"ctf_242.cfg\" would be titled \"ctf_242\".\nType --help for more.\n"
	fi
} # End rcon2irc_start

# Starts an rcon2irc server by name
function rcon2irc_stop {
	if [ "$1" != "" ]; then
		gsname=$1
		echo -e "[Stopping rcon2irc bot] $screenname"
		screenid=$(screen -ls | grep $gsname | awk '{ print $1 }' | grep \.$gsname$ | grep "rcon_" | awk -F . '{ print $1 }')
		if [ "$screenid" != "" ]; then
			kill -9 $screenid
			screen -wipe
		else
			echo -e "[WARNING] rcon2irc bot for $gsname is not running"
		fi
	else
		echo -e "\nSyntax is: --rcon2irc stop <server name>\n\n<server name> is built from your server cfg file name.\n\"ctf_242.cfg\" would be titled \"ctf_242\".\nType --help for more.\n"
	fi
} # End rcon2irc_stop

# Restarts an rcon2irc server by name
function rcon2irc_restart {
	if [ "$1" != "" ]; then
		gsname=$1
		echo -e "[Restarting rcon2irc bot] $screenname\n"
		rcon2irc_stop $gsname
		rcon2irc_start $gsname
	else
		echo -e "\nSyntax is: --rcon2irc restart <server name>\n\n<server name> is built from your server cfg file name.\n\"ctf_242.cfg\" would be titled \"ctf_242\".\nType --help for more.\n"
	fi
} # End rcon2irc_restart

# Restarts all rcon2irc servers
function rcon2irc_restart_all {
	for conf in $(ls $core_dir/config/serverz/rcon2irc/*.conf); do
		rcon2irc_restart $conf
	done
} # End rcon2irc_restart_all

# Loads a specific rcon server into screen
function rcon2irc_view {
	if [ "$1" != "" ]; then
		gsname=$1
		screenid=$(screen -ls | grep $gsname | awk '{ print $1 }' | grep \.$gsname$ | grep "rcon_" | awk -F . '{ print $1 }')
		echo -e "\n!!!IMPORTANT!!! To get out of a screen, hold ctrl, then press a, then d\n\nPress enter to continue"
		read
		screen -r ${screenid}
	else
		echo -e "\nSyntax is: --rcon2irc view <server name>\n\n<server name> is built from your server cfg file name.\n\"ctf_242.cfg\" would be titled \"ctf_242\".\nType --help for more.\n"
	fi
} # End rcon2irc_server

# Passes rcon commands to the server based on the rcon2irc conf
rcon() { # LITTLE BROKEN RIGHT NOW
	# server name
	#servername="nns_ctf_light"
	servername=$(echo $* | awk '{ print $2 }')
	
	# get server login info
	head -n3 $core_dir/config/serverz/rcon2irc/$servername\.conf | tail -n2 | sed 's/ = /=/' > $core_dir/config/serverz/rcon2irc/temp_rcon.conf
	source $core_dir/config/serverz/rcon2irc/temp_rcon.conf

	#shopt -s extglob
	#while IFS= read -r LINE; do
		#key=${LINE%%=*}
		#value=${LINE#*=}
		#key=${key%%*([  ])}
		#value=${value##*([  ])}
		#eval "rcon2irc_$key=\$value"
	#done
	
	echo "rcon to: $dp_server"

	# not the best regex but it works - takes the whole passed string and cuts out only the command
	#command=$(echo $* | sed 's/^--rcon [a-z0-9_-]* //' )
	command=$(echo $* | sed 's/^--rcon [a-z0-9_-]* //' | sed 's/"/\\\"/g' )
	#echo $command
	#echo "execing command: rcon_address=$dp_server rcon_password=$dp_password $basedir/Docs/server/./rcon.pl $command"
	rcon_address=$dp_server rcon_password=$dp_password $basedir/server/./rcon.pl "$command"
	
	#cleanup
	rm $core_dir/config/serverz/rcon2irc/temp_rcon.conf
}

###############
# Start Server Tool Functions
####################################################################

# Edits a specific server config based on the session name (--list name)
function edit_server {
	if [ "$1" != "" ]; then
		gsname=$1
	
		$default_editor $core_dir/config/serverz/$1.cfg
		echo "Do you want to restart this server now (y/n)?"
		read answer
		if [ "$answer" == "y" ]; then
			restart_server $gsname
		else
			echo "[alert] Not restarting $gsname"
		fi
	else
		echo -e "\n[ERROR] No server specified\n"
	fi
} # End edit_server

# Used to dynamically build a maplist based on the pk3's in your directory rather
# than rely on the g_maplist="" emergency override
function create_maplist {
	# Start the maplist string
	i="g_maplist=\""
	
	# Get Gametype
	if [ "$1" != "" ]; then
		t=$1
	else
		echo; echo "[WARNING] No gametype has been set, setting to dm"
		t="dm"
	fi
	
	# Handle Optional Directory Parameter
	if [ "$2" != "" ]; then
		if [ -d "$2" ]; then
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
				# Print with quotes and a comma then append to string 'i'
				echo "[ADDING] $mapname to the list"
				mapname="$t"\_"$mapname "
				i=$i$mapname
			else
				if [ $m2 == true ]; then
					echo "Checking generated mapinfo for gametype compatiability ($t): [NO]"
				fi
			fi

		fi
	done

	# Trim the last space and echo maplist
	i=$(echo $i | sed 's/ $//')
	i=$i"\""
	
	if [ "$status" == "warning" ]; then
		echo; echo "[WARNING] Some maps weren't added because no mapinfo files were found.  Some maps may not be included!  Restart Nexuiz to generate them automatically, then run this script again."
	fi
	
	echo; echo "-- Printing $t Maplist -----------"; echo; echo $i; echo
} # End create_maplist


###############
# Start System Functions
####################################################################

# This installs files/settings for nst
install_nst() {
	if [[ ! -f $core_dir/install/lock ]]; then
		# check all dependecies
		# config settings now? -- write to base.conf
		# Install Nexuiz?
		echo "Do you want to install nexuiz now (y/n)?"
		read answer
		if [ "$answer" == "y" ]; then
			install_nexuiz
		else
			echo -e "\n[alert] Not installing Nexuiz, You either need to run --install_nexuiz later or unzip a stable release 2.4.2 or higher in the nst/nexuiz folder."
		fi
		nexst_shortcuts_add
	else
		echo -e "NST has already run through the initial installation - remove the lock file if you know what you are doing"
	fi
} # End install_nst

# This uninstalls files/settings for nst
uninstall_nst() {
	nexst_shortcuts_remove
	# remove files?
} # End uninstall_nst

# Post installation shortcuts
nexst_shortcuts_add() {
	if [[ ! -f $core_dir/install/lock ]]; then
		#core_file=$(ls $core_dir/nst_core*.sh |egrep "[0-9]{6}" |sort -r |head -n 1)
		core_file=$(ls $core_dir |grep nst_core |tail -n1)
		echo -e "\nAdding alias \"nexst\" to .bashrc\n"
		# Add alias to .bashrc
		echo -e "\nalias nexst='$core_dir/$core_file'" >> ~/.bashrc
		# Alias NOW
		echo -e "Restart bash or paste this to active the alias now:\nalias nexst='$core_dir/$core_file'"
		# lock installation
		touch $core_dir/install/lock
	else
		echo -e "NST has already run through the initial installation - remove the lock file if you know what you are doing"
	fi
} # End next_shortcuts_add

# Uninstall shortcuts
nexst_shortcuts_remove() {
	if [[ -f ~/.bashrc ]]; then
		core_file=$(ls $core_dir |grep nst_core |tail -n1)
		echo -e "\nRemoving alias \"nexst\" from .bashrc\n"
		# Remove alias from .bashrc
		sed -i 's/alias nexst.*//g' ~/.bashrc
		# Unalias NOW -- doesn't work
		#unalias nexst
		# remove lock
		if [[ -f $core_dir/install/lock ]]; then
			rm $core_dir/install/lock
		else
			echo "[warning] lock file doesn't exist"
		fi
	else
		echo -e "For some reason, you don't have a ~/.bashrc file, so NST is already uninstalled, you can delete the nst folder and all of its contents."
	fi
} # End next_shortcuts_add

# This installs Nexuiz from SVN
install_nexuiz() {
	echo -e "\n-- Starting Nexuiz Install --\n"
	cd $core_dir/nexuiz
	if [[ -f $(ls *.sh |grep sb_install) ]]; then
		sb_script=$(ls *.sh |grep sb_install |tail -n1)
		chmod +x $sb_script
		echo -e "\nThis is going to take a while, it's not hanging.  You might want to make a sandwhich!\n"
		./$sb_script -t s
		latest_revision=$(ls $core_dir/nexuiz/ |grep Nexuiz_SVN |tail -n1)
		sed -i "s#basedir=.*#basedir=\"$core_dir/nexuiz/${latest_revision}\"#" $core_dir/config/base.conf
	else 
		echo -e "[FAILED] No install script found!  Did you delete it?\n"
	fi
} # End install_nexuiz

# This Packages NST for distribution
pack_nst() {
	# this function actually needs work... it'd be better NOT to package with the NST folder
	
	# get a list of all the files 
	cd $core_dir
	cd ..
	find $core_dir ! -type f -print | egrep 'svn|Nexuiz_SVN_.*|\.git.*|serverz.*offline' > nst_exclude
	sed -i "s#$core_dir#nst#" nst_exclude
	echo -e "\nnst_exclude" >> nst_exclude
	echo -e "\nnst/.gitignore" >> nst_exclude
	echo -e "\nnst/install/lock" >> nst_exclude
	tar cvf nst-pack_$( date +%m%d%y ).tar * --exclude-from=nst_exclude
	rm nst_exclude
} # End pack_nst

# Routes Help Functions based on whether extend = true or not
nst_help_all ()
{
	cd $core_dir/extraz/pluginz
	
	for plugin in $(ls); do
		ext_help=$($core_dir/extraz/pluginz/$plugin --help)
		full_help="$full_help $ext_help"
	done
	
	nst_help 			# nst help
	echo "$full_help"	# plugin help
	
} # nst_help_all

# The Help Function for NsT
nst_help ()
{
echo "

                          Nexuiz Ninjaz Present

                          v\`     _   __                _    
                         <f     / | / /__  _  ____  __(_)___
                        .d\`    /  |/ / _ \| |/_/ / / / /_  /
                  ..    j(    / /|  /  __/>  </ /_/ / / / /_
                 jQQ,  _2    /_/ |_/\___/_/|_|\__,_/_/ /___/
              <gmQQW;  d\`
        =c :><QQQQQQk ](           _____                          
         ~{,3QQQQQQQWsf           / ___/___  ______   _____  _____
           jQQQQQQQQQW\`           \__ \/ _ \/ ___/ | / / _ \/ ___/
         <mQQQQQQWWWQh           ___/ /  __/ /   | |/ /  __/ /    
        .mQQQQQQQc)QQ#          /____/\___/_/    |___/\___/_/
        =QQQQQQQQQQQQk
         \"\$QP!\"!4QQQW'       ______            __   
          -Q;    4QQQ>      /_  __/___  ____  / /___
          jW\`     \$WQWc      / / / __ \/ __ \/ /_  /
         qQE      ]QQQ#     / / / /_/ / /_/ / / / /_
         ~\"\`      )QQQW.   /_/  \____/\____/_/ /___/
                    -\"\$L
                      )Wc    created by -z- of www.nexuizninjaz.com
                       \"$;                                    

SYNOPSIS

Nexuiz Server Toolz is a collection of helpful scripts to help admins manage their Nexuiz game servers.  Following the methodology of Ruby on Rails, these scripts believe in convention over configuration.  This means using such devices as the \"config/serverz\" folder to tell this script where your servers are, instead of the classic \"configuration\" file which is edited manually.  Less work for you!  Easy to upgrade, easy to scale, easy to manage.

:::IMPORTANT USAGE NOTES:::

This script identifies your servers by the configs located in your \"config/serverz\" directory.  Furthermore, the name of the screen is constructed by the next token ending at .cfg.  That is: ([A-Za-z0-9_-]+).cfg

Example cfg name: local_ctf.cfg
Screen name:      local_ctf

Inside the configuration file, the conventions continue.  To prevent log errors when restarting servers, set the following cvars, replacing 'ctf_242_' with your corresponding server name.  eventlog is also the format read by the statistics parser, so if you are utilizing that feature, you're killing two birds with one stone.

sv_eventlog 1
sv_eventlog_files 1
sv_eventlog_files_nameprefix   \"local_ctf_\"

A sample config is available for your convenience, 'local_ctf.cfg'


General Usage: nexst --(start_all|stop_all|restart_all|start <server>|stop <server>|restart <server>|list|view <server>|edit <server>|rcon2irc (start |stop|restart|view) <server>|create_maplist <gametype>|install_nst|uninstall_nst|install_nexuiz|pack_nst|help)

options are...

+==================+
|  Core Functions  |
+==================+

SERVER MANAGEMENT

--start_all						Starts all servers identified by a \"([A-Za-z0-9_-]+).cfg\" file inside 'config/serverz'.
							It starts servers inside screens, using the token denoted by the () above
							to title it.  If the cfg was titled \"ctf_242.cfg\", the screen would be titled \"ctf_242\".
						
--start <server name>					Same as above except it allows you to specify a server

--stop_all						Stop all currently running Nexuiz servers

--stop <server name>					Stop a specific Nexuiz server
 
--restart_all						Restart all currently running Nexuiz servers

--restart <server name>					Restart a specific Nexuiz server
 
--list							List all currently running Nexuiz servers
 
--view <server name>					View a specific server based on the name given in --list
							i.e. --view dm

--rcon2irc (start|stop|restart|view) <server name>	View a specific server's rcon2irc based on the name given in --list
							i.e. --rcon2irc stop dm

CFG TOOLZ

--edit <server name>					Edit the configuration of a specific server based on the name given in --list and
							offers ability to restart.
							i.e. --edit dm

--create_maplist [gametype] [directory]			Create a maplist for a specific gametype based on the maps found
							in your data directory (default folder: ~/.nexuiz/data/)
								
							[gametype]:	(dm|tdm|ctf|lms|dom ... etc)
									default gametype is dm
										
							[directory]:	(Optional) if you wan to use a folder other than ~/.nexuiz/data

SYSTEM TOOLZ

--install_nst						Used to install Nexuiz Server Toolz -- install.sh calls this

--uninstall_nst						Used to uninstall Nexuiz Server Toolz

--install_nexuiz					Installs Nexuiz using Soulbringer's Nexuiz SVN install script.  It sets things up complete
							with configuration so you can just start up NST after the install -- install.sh asks if you'd like
							to do this, it's suggested you do.
							
--pack_nst						NST can package itself as a tarball.  This is handy for cloning or migrating servers.

INFORMATION

--help							You're lookin at it :-P - Thanks to Soulbringer for this case switch/framework.
"
} # End nst_help

# Routes parameters not found in the core to plugin files
nst_extend ()
{
	cd $core_dir/extraz/pluginz
	# Check plugins for function
	for plugin in *; do
		pfunction=$(echo $1 |sed 's/\-/\\-/g')
		string=$(egrep "$pfunction\)" $plugin)
		if [[ "$string" != "" ]]; then
			# check if chmod +X
			# execute script with parameter
			echo -e "\nExecuting function from plugin: $plugin \n"
			$core_dir/extraz/pluginz/./$plugin $1 $2 $3 $4
			exit 0
		fi
	done
	
	# function not found, display help for all
	nst_help_all

} # End nst_extend

# Case swtich to filter params
case $1 in
  --start) start_server $2;;				# start a specific server
  --start_all) start_all;; 					# start the servers defined in the top of this script
  --stop) stop_server $2;;					# stop a specific server
  --stop_all) stop_all;;					# stop the servers
  --restart) restart_server $2;;			# restart a specific server
  --restart_all) restart_all;;				# restart all servers
  --list) list_servers;;					# list all servers
  --view) view_server $2;;					# open the screen for a specific server
  --rcon2irc) rcon2irc_router $2 $3;;		# routes the rcon2irc (start,stop,restart,view) for a specific server
  --rcon) rcon $*;;							# passes rcon commands to the server
  --edit) edit_server $2;;					# edit a specific server's cfg
  --create_maplist) create_maplist $2 $3;;	# create maplist for the passed <gametype> <directory>
  --install_nst) install_nst;;				# Installs / configures NST easily
  --uninstall_nst) uninstall_nst;;			# Uninstalls / configures NST easily
  --install_nexuiz) install_nexuiz;;		# Installs Nexuiz from SVN
  --pack_nst) pack_nst;;					# Packs NST for distribution
  --help) nst_help_all;;					# command line parameter help
  --nst_help) nst_help;;					# Pure nst_help
  *) nst_extend $1 $2 $3 $4;;				# pass off to extend function if no flag is found
esac # End case switch
