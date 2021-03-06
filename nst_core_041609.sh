#!/bin/bash
#
# Nexuiz Ninjaz Proudly Present
# 
# Nexuiz Server Toolz
#
# Version: 0.99 Beta
# Released: 01/31/09
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
	
	# List any nn_server configs found
	for cfg in $(ls $core_dir/config/servers/*.cfg); do
		cfgname=$(echo $cfg | awk -F/ '{print $NF}')
		screenname=$(echo $cfgname | awk -F . '{ print $1 }')
		
		start_server $screenname
	done
	list_servers
} # End start_all

# start an individual server by its cfg name minus .cfg
start_server()
{
	if [[ "$1" != "" ]]; then
		screenname=$1
		cfgname="$screenname.cfg"
		confname="$screenname.conf"
		
		if [[ -f $core_dir/config/servers/$confname ]]; then
			source $core_dir/config/servers/$confname
			this_basedir=$server_basedir
		else
			this_basedir=$basedir
		fi
		
		# check if basedir exists
		if [[ ! -d $this_basedir ]]; then
			echo -e "\n[FAIL] The basedir '$this_basedir' is incorrect, please edit your config and try again.\n"
			exit 1
		fi
		
		# change to basedir so nexuiz can be executed and load cfgs without freaking out		
		cd $this_basedir
		
		# attempt to load the cfg based on the name of the server
		if [[ -f $core_dir/config/servers/$cfgname ]]; then
			
			# check to see if there is a corresponding files directory for this server
			if [[ -d $core_dir/extras/files/$screenname ]]; then
				if [[ ! -d $this_basedir/$screenname ]]; then
					ln -s $core_dir/extras/files/$screenname $this_basedir/$screenname
				fi
				# make a symlink to the cfg if there isn't one already
				if [[ ! -f $core_dir/extras/files/$screenname/$cfgname ]]; then
					ln -s $core_dir/config/servers/$cfgname $core_dir/extras/files/$screenname/$cfgname
				fi
				# symlink logs if it isn't already
				if [[ ! -d $this_basedir/logs ]]; then
					ln -s $core_dir/logs $this_basedir/logs
				fi
				# symlink global if it isn't already
				if [[ ! -d $this_basedir/global ]]; then
					ln -s $core_dir/extras/files/global $this_basedir/global
				fi
				# symlink common if it isn't already
				if [[ ! -d $this_basedir/common ]]; then
					ln -s $core_dir/config/servers/common $this_basedir/common
				fi
			else # No files directory -- execute from ~/.nexuiz/data/
				if [[ ! -f ~/.nexuiz/data/$cfgname ]]; then
					ln -s $core_dir/config/servers/$cfgname ~/.nexuiz/data/$cfgname
				fi
			fi
			
			echo -e "\n[Starting Server] $screenname"
			
			# This can be hardcoded because it's where QuakeC puts them -- THIS NEEDS TO BE UPDATED
			if [[ ! -d ~/.nexuiz/data/data/oldlogs ]];then mkdir -p ~/.nexuiz/data/data/oldlogs;fi
			if [[ -f ~/.nexuiz/data/data/$screenname*.log ]]; then
				mv ~/.nexuiz/data/data/$screenname*.log ~/.nexuiz/data/data/oldlogs
				echo -e " -- [Archiving Server Logs for: $screenname]"
			else
				echo -e " -- [No logs to archive for: $screenname]"
			fi
			
			# if there is a folder for this server in extras/files -- start with that as the game dir
			if [[ -d $core_dir/extras/files/$screenname ]];then
				screen -m -d -S $screenname $this_basedir/./nexuiz-dedicated -game global -game common -game $screenname +serverconfig $cfgname -userdir logs
			# otherwise use ~/.nexuiz/data
			else
				screen -m -d -S $screenname $this_basedir/./nexuiz-dedicated +serverconfig $cfgname
			fi
			
			if [[ "$auto_rcon" == "true" ]]; then
				rcon2irc_start $screenname
			fi
		else
			echo -e "\n[ERROR] Config: $cfgname not found in $core_dir/config/servers\n"
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
	for cfg in $(ls $core_dir/config/servers/*.cfg); do
		cfgname=$(echo $cfg | awk -F/ '{print $NF}')
		screenname=$(echo $cfgname | awk -F . '{ print $1 }')
		
		stop_server $screenname
	done
	echo -e "\n[Stopped All]\n"
} # End stop_all

# stop a single server by it's session name
stop_server()
{
	if [[ "$1" != "" ]]; then
		gsname=$1
		requested=$(ps -ef | grep SCREEN | grep nexuiz-dedicated | grep -v grep | awk '{ print $12 }' | grep ^${gsname}$)

		if [[ "$requested" != "" ]]; then
			pid=$(ps -ef | grep SCREEN | grep nexuiz-dedicated | grep -v grep | grep "+serverconfig ${gsname}.cfg" | awk '{ print $2 }')
			pkill -P $pid
			if [[ "$auto_rcon" == "true" ]]; then
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
	if [[ "$1" != "" ]]; then
		gsname=$1
		
		requested=$(ps -ef | grep SCREEN | grep nexuiz-dedicated | grep -v grep | awk '{ print $12 }' | grep ^${gsname}$)

		if [[ "$requested" != "" ]]; then
			stop_server $gsname
			
			echo -e "\nRestarting $gsname in 5..."
		
			sleep 1; echo -e "4"; sleep 1; echo -e "3"; sleep 1; echo -e "2"; sleep 1; echo -e "1";
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
	if [[ "$( ps -ef | grep nexuiz-dedicated | grep SCREEN | grep -v grep )" != "" ]]; then
		echo; echo -e " Currently Running Nexuiz Servers\n ----------------------------------------------------------------------------------------------------------------------"
		gsname=$(ps -ef | grep nexuiz-dedicated | grep SCREEN | grep -v grep | awk '{ print $12 }')

		while read gspid gsmem gsname; do
			gscfg=$(echo $gsname | sed "s/\(.*\)/\1.cfg/")
			gsport=$(grep ^port -r $core_dir/config/servers/${gscfg} | awk '{ print $2 }')
			gsaddress=$(grep ^net_address -r $core_dir/config/servers/${gscfg} | awk '{ print $2 }')
			if [[ "$gsaddress" == "" ]]; then gsaddress="$base_address"; fi
			if [[ "$qstat_enabled" == true ]]; then
				gsplayers=$(qstat -P -nexuizs $gsaddress:$gsport | head -n 2 | tail -n 1 | awk '{ print $2 }')
				totalplayers=$((totalplayers+$(echo $gsplayers | awk -F / '{ print $1 }')))
			else
				gsplayers="enable qstat"
			fi
			
			rconstatus="no"
			if [[ "$auto_rcon" == "true" ]]; then
				rconscreen=$(screen -ls | grep $gsname | awk '{ print $1 }' | grep \.$gsname$ | grep "rcon_")
				if [[ "$rconscreen" != "" ]]; then
					rconstatus="yes"
					rcontotal=$((rcontotal+1))
				fi
			fi
			
			totalmemory=$((totalmemory+gsmem))
			totalservers=$((totalservers+1))
			
			echo -e " Address:" $gsaddress:$gsport "\t PID:" $gspid "\t MEM:" $(echo $gsmem |awk '{ print $1 * 0.0009765625}') " \tName:" $gsname "  \tPlayers:" $gsplayers "\trcon2irc:" $rconstatus
		done < <( ps -C nexuiz-dedicate -o pid,vsz,args --sort vsz | sed '1d' | awk '{ printf "%s %s %s\n", $1, $2, $9 }' )
		echo " ----------------------------------------------------------------------------------------------------------------------"
		echo -e " Totals:  $totalservers servers                                   $(echo $totalmemory |awk '{ print $1 * 0.0009765625}')mb                                    $totalplayers                $rcontotal\n"
	else
		echo -e "\n[WARNING] No Nexuiz servers are currently running"
		echo -e "\n[ATTENTION] Here's a list of available cfgs:\n"
		ls $core_dir/config/servers/ |grep .cfg
		echo
	fi
} # End list_servers

# Loads a specific server into screen
view_server() {
	if [[ "$1" != "" ]]; then
		gsname=$1
		
		screenid=$(screen -ls | grep $gsname | awk '{ print $1 }' | grep \.$gsname$ | grep -v "rcon_" | awk -F . '{ print $1 }')
		echo -e "\n!!!IMPORTANT!!! To get out of a screen, hold ctrl, then press a, then d"
		echo -e "\n!!!IMPORTANT!!! To scroll, hold ctrl, then press a, then esc\n\nPress enter to continue"
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
rcon2irc_router() {
	case $1 in
	  start) rcon2irc_start $2;;				# start a specific rcon2irc bot
	  stop) rcon2irc_stop $2;;					# stop a specific rcon2irc bot
	  restart) rcon2irc_restart $2;;			# restart a specific rcon2irc bot
	  start_all) rcon2irc_start_all;;			# starts all rcon2irc bots
	  stop_all) rcon2irc_stop_all;;				# stops all rcon2irc bots
	  restart_all) rcon2irc_restart_all;;		# restarts all rcon2irc bots
	  view) rcon2irc_view $2;;					# view a specific rcon2irc bot
	  *) echo -e "\nOptions are: (start|stop|restart|start_all|stop_all|restart_all|view)\n";;
	esac
}

# Starts an rcon2irc server by name
rcon2irc_start() {
	if [[ "$1" != "" ]]; then
		screenname=$1
		confname="$screenname.conf"
		
		# I'm reusing the variable, I'm a bad boy
		if [[ -f $core_dir/config/servers/$confname ]]; then
			source $core_dir/config/servers/$confname
			this_basedir=$server_basedir
		else
			this_basedir=$basedir
		fi
		
		# If an rcon2irc config exists, start it.
		if [[ -f $core_dir/config/servers/rcon2irc/$confname ]]; then	
			echo -e "[Starting rcon2irc bot] $screenname\n"
			screen -m -d -S rcon_$screenname /usr/bin/perl $this_basedir/server/rcon2irc/rcon2irc.pl $core_dir/config/servers/rcon2irc/$confname
		else
			echo -e "\n -- [tip] If you create a file in your '$core_dir/config/servers/rcon2irc' folder called '$confname' per div's rcon2irc requirements, it will automatically be loaded.\n"
		fi
	else
		echo -e "\nSyntax is: --rcon2irc start <server name>\n\n<server name> is built from your server cfg file name.\n\"ctf_242.cfg\" would be titled \"ctf_242\".\nType --help for more.\n"
	fi
} # End rcon2irc_start

# Starts an rcon2irc server by name
rcon2irc_stop() {
	if [[ "$1" != "" ]]; then
		gsname=$1
		echo -e "[Stopping rcon2irc bot] $screenname"
		screenid=$(screen -ls | grep $gsname | awk '{ print $1 }' | grep \.$gsname$ | grep "rcon_" | awk -F . '{ print $1 }')
		if [[ "$screenid" != "" ]]; then
			kill -9 $screenid
			echo $(screen -wipe |grep $gsname)
		else
			echo -e "[WARNING] rcon2irc bot for $gsname is not running"
		fi
	else
		echo -e "\nSyntax is: --rcon2irc stop <server name>\n\n<server name> is built from your server cfg file name.\n\"ctf_242.cfg\" would be titled \"ctf_242\".\nType --help for more.\n"
	fi
} # End rcon2irc_stop

# Restarts an rcon2irc server by name
rcon2irc_restart() {
	if [[ "$1" != "" ]]; then
		gsname=$1
		echo -e "[Restarting rcon2irc bot] $screenname\n"
		rcon2irc_stop $gsname
		rcon2irc_start $gsname
	else
		echo -e "\nSyntax is: --rcon2irc restart <server name>\n\n<server name> is built from your server cfg file name.\n\"ctf_242.cfg\" would be titled \"ctf_242\".\nType --help for more.\n"
	fi
} # End rcon2irc_restart

# Starts all rcon2irc servers
rcon2irc_start_all() {
	for conf in $(ls $core_dir/config/servers/rcon2irc/*.conf); do
		rcon2irc_start $conf
	done
} # End rcon2irc_start_all

# Stops all rcon2irc servers
rcon2irc_stop_all() {
	for conf in $(ls $core_dir/config/servers/rcon2irc/*.conf); do
		rcon2irc_stop $conf
	done
} # End rcon2irc_stop_all

# Restarts all rcon2irc servers
rcon2irc_restart_all() {
	for conf in $(ls $core_dir/config/servers/rcon2irc/*.conf); do
		rcon2irc_restart $conf
	done
} # End rcon2irc_restart_all

# Loads a specific rcon server into screen
rcon2irc_view() {
	if [[ "$1" != "" ]]; then
		gsname=$1
		screenid=$(screen -ls | grep $gsname | awk '{ print $1 }' | grep \.$gsname$ | grep "rcon_" | awk -F . '{ print $1 }')
		echo -e "\n!!!IMPORTANT!!! To get out of a screen, hold ctrl, then press a, then d"
		echo -e "\n!!!IMPORTANT!!! To scroll, hold ctrl, then press a, then esc\n\nPress enter to continue"
		read
		screen -r ${screenid}
	else
		echo -e "\nSyntax is: --rcon2irc view <server name>\n\n<server name> is built from your server cfg file name.\n\"ctf_242.cfg\" would be titled \"ctf_242\".\nType --help for more.\n"
	fi
} # End rcon2irc_server

# Passes rcon commands to the server based on the rcon2irc conf
rcon() { # LITTLE BROKEN RIGHT NOW
	# server name
	servername=$(echo $* | awk '{ print $2 }')
	
	# get server login info
	head -n3 $core_dir/config/servers/rcon2irc/$servername\.conf | tail -n2 | sed 's/ = /=/' > $core_dir/config/servers/rcon2irc/temp_rcon.conf
	source $core_dir/config/servers/rcon2irc/temp_rcon.conf

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
	#echo "execing command: rcon_address=$dp_server rcon_password=$dp_password $this_basedir/Docs/server/./rcon.pl $command"
	
	if [[ -f $core_dir/config/servers/$confname ]]; then
		source $core_dir/config/servers/$confname
		this_basedir=$server_basedir
	else
		this_basedir=$basedir
	fi
		
	rcon_address=$dp_server rcon_password=$dp_password $this_basedir/server/./rcon.pl "$command"
	
	#cleanup
	rm $core_dir/config/servers/rcon2irc/temp_rcon.conf
}

###############
# Start Server Tool Functions
####################################################################

# Edits a specific server config based on the session name (--list name)
edit_server() {
	if [[ "$1" != "" ]]; then
		gsname=$1
	
		$default_editor $core_dir/config/servers/$1.cfg
		echo "Do you want to restart this server now (y/n)?"
		read answer
		if [[ "$answer" == "y" ]]; then
			restart_server $gsname
		else
			echo "[alert] Not restarting $gsname"
		fi
	else
		echo -e "\n[ERROR] No server specified\n"
	fi
} # End edit_server

# View a specific server log based on the session name (--list name)
view_server_log() {
	if [[ "$1" != "" ]]; then
		tail "$( if [[ "$2" != "" ]]; then echo -n$2; else echo -n400;fi )" $(ls -t $core_dir/logs/$1/*.log | head -n1)
	else
		echo -e "\n[ERROR] No server specified\n"
	fi
} # End view_log


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
		if [[ "$answer" == "y" ]]; then
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
	echo "Do you want to remove all files (including Nexuiz and any configs and maps you have in NST) now (y/n)?"
	read answer
	if [[ "$answer" == "y" ]]; then
		remove_nexuiz
		remove_nst
	else
		echo -e "\n[alert] Not removing files."
	fi
} # End uninstall_nst

# This removes all NST files
remove_nst() {
	echo "Removing NST files..."
	rm -rfv $core_dir
} # End remove_nst

# This Packages NST for distribution
pack_nst() {
	cd $core_dir
	find $core_dir -type f -print | egrep -v 'offline|svn|Nexuiz_SVN_.*|install/lock|logs/.*/|\.git|\.pk3|\.tar|tarlist.txt' | sed "s#$core_dir/##" > tarlist.txt
	xargs tar cvf nst-pack_$( date +%m%d%y ).tar < tarlist.txt
	rm tarlist.txt
} # End pack_nst

# Post installation shortcuts
nexst_shortcuts_add() {
	if [[ ! -f $core_dir/install/lock ]]; then
		#core_file=$(ls $core_dir/nst_core*.sh |egrep "[0-9]{6}" |sort -r |head -n 1)
		echo -e "\nAdding alias \"nexst\" to .bashrc\n"
		# Add alias to .bashrc
		echo -e "\nalias nexst='$core_dir/$core_file'" >> ~/.bashrc
		# Alias NOW
		echo -e "Restart bash or paste this to active the alias now:\n\nalias nexst='$core_dir/$core_file'\n\n"
		# lock installation
		touch $core_dir/install/lock
	else
		echo -e "NST has already run through the initial installation - remove the lock file if you know what you are doing"
	fi
} # End next_shortcuts_add

# Uninstall shortcuts
nexst_shortcuts_remove() {
	if [[ -f ~/.bashrc ]]; then
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
	if [[ -f $(ls *.sh |grep sb_install |tail -n1) ]]; then
		sb_script=$(ls *.sh |grep sb_install |tail -n1)
		chmod +x $sb_script
		echo -e "\nThis is going to take a while, it's not hanging, just checking out a lot of things from SVN.  You might want to make a sandwich!\n"
		./$sb_script -t s
		latest_revision=$(ls $core_dir/nexuiz/ |grep Nexuiz_SVN |tail -n1)
		sed -i "s#basedir=.*#basedir=\"$core_dir/nexuiz/${latest_revision}\"#" $core_dir/config/base.conf
	else 
		echo -e "[FAILED] No install script found!  Did you delete it?\n"
	fi
} # End install_nexuiz

# This removes Nexuiz
remove_nexuiz() {
	echo "Removing Nexuiz.."
	cd $core_dir
	rm -rfv nexuiz
} # End remove_nexuiz

# Routes Help Functions based on whether extend = true or not
nst_help_all ()
{
	cd $core_dir/extras/plugins
	
	for plugin in $(ls |grep -v plugin.inc); do
		ext_help=$($core_dir/extras/plugins/$plugin --help)
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

Nexuiz Server Toolz is a collection of helpful scripts to help admins manage their Nexuiz game servers.  Following the methodology of Ruby on Rails, these scripts believe in convention over configuration.  This means using such devices as the \"config/servers\" folder to tell this script where your servers are, instead of the classic \"configuration\" file which is edited manually.  Less work for you!  Easy to upgrade, easy to scale, easy to manage.

:::IMPORTANT USAGE NOTES:::

This script identifies your servers by the configs located in your \"config/servers\" directory.  Furthermore, the name of the screen is constructed by the next token ending at .cfg.  That is: ([A-Za-z0-9_-]+).cfg

Example cfg name: local_ctf.cfg
Screen name:      local_ctf

Inside the configuration file, the conventions continue.  To prevent log errors when restarting servers, set the following cvars, replacing 'ctf_242_' with your corresponding server name.  eventlog is also the format read by the statistics parser, so if you are utilizing that feature, you're killing two birds with one stone.

sv_eventlog 1
sv_eventlog_files 1
sv_eventlog_files_nameprefix   \"local_ctf_\"

A sample config is available for your convenience, 'local_ctf.cfg'


General Usage: nexst --(start_all|stop_all|restart_all|start <server>|stop <server>|restart <server>|list|view <server>|edit <server>|rcon2irc (start|stop|restart|start_all|stop_all|restart_all|view) <server>|create_maplist <gametype>|install_nst|uninstall_nst|install_nexuiz|pack_nst|help)

options are...

+==================+
|  Core Functions  |
+==================+

SERVER MANAGEMENT

--start_all						Starts all servers identified by a \"([A-Za-z0-9_-]+).cfg\" file inside 'config/servers'.
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

--rcon2irc ([re]start|stop|view) <server name>		Control a specific server's rcon2irc based on the name given in --list
							i.e. --rcon2irc stop dm
							
--rcon2irc ([re]start|stop)_all				Control all server's rcon2irc based on the name given in --list

CFG TOOLZ

--edit <server name>					Edit the configuration of a specific server based on the name given in --list and
							offers ability to restart.
							i.e. --edit dm

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
	cd $core_dir/extras/plugins
	# Check plugins for function
	for plugin in *; do
		pfunction=$(echo $1 |sed 's/\-/\\-/g')
		string=$(egrep "$pfunction\)" $plugin)
		if [[ "$string" != "" ]]; then
			# check if chmod +X
			chmod +x $core_dir/extras/plugins/./$plugin
			# execute script with parameter
			echo -e "\nExecuting function from plugin: $plugin \n"
			$core_dir/extras/plugins/./$plugin $1 $2 $3 $4
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
  --view_log) view_server_log $2 $3;;		# view the log of a specific server
  --rcon2irc) rcon2irc_router $2 $3;;		# routes the rcon2irc (start,stop,restart,view) for a specific server
  --rcon) rcon $*;;							# passes rcon commands to the server
  --edit) edit_server $2;;					# edit a specific server's cfg
  --install_nst) install_nst;;				# Installs / configures NST easily
  --uninstall_nst) uninstall_nst;;			# Uninstalls / configures NST easily
  --install_nexuiz) install_nexuiz;;		# Installs Nexuiz from SVN
  --pack_nst) pack_nst;;					# Packs NST for distribution
  --help) nst_help_all;;					# command line parameter help
  --nst_help) nst_help;;					# Pure nst_help
  *) nst_extend $1 $2 $3 $4;;				# pass off to extend function if no flag is found
esac # End case switch
