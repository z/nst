#!/bin/bash
#
# Soubringer's Nexuiz Installation script
#
# Copyright (c) 2008 Soulbringer
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
 
install_dir=$(dirname $(which $0) | sed 's/\/.$//' )

#### user options ####
## if you want to fully automate this script you can use these options
TARGET="server"	# valid options are "client" "server" or "both"
MAPS=1		# only effects server installations.set to "0" if you dont want to install standard maps 
 
# if you want this script to pause after updating the source set "PAUSE" to "1"
# ( usefull if you want to "patch" the source code before you compile it )
# PAUSE=0	# not currently implimented
 
## these automatically remove old working copies when the latest is successfully compiled
PRUNE=1		# turns auto pruning on
BACKUPS=3 	# sets number of backup copies (old snapshots)
 
# would you like your "data" folder compressed?
# leaving uncompressed *could* lead to faster initial load times
# and compressing could cut the size of the install by %50 or more
COMPRESSIT=0
COMPRESSION=9	# Compression Level 0-larger and faster to compress, 9-smaller slower
 
# Please update this to reflect the current version number of fteqcc found here
# http://sourceforge.net/project/showfiles.php?group_id=116842&package_id=129507&abmode=1
# NOTE: This is ONLY used if the subversion of fteqcc doesnt compile AND fteqcc IS NOT installed on your system
FTECV=3343

#### end user options ####
 
 
ENVCHK()
{
	echo -e "Checking Environment"
	if [ ! -x $( whereis svn | sed "s/svn: //" | sed "s/ .*//" ) ];then ERROR=1 && echo -e "ERROR: Couldnt locate svn in\nplease check subversion installation";fi
	if [ ! -x $( whereis 7z | sed "s/7z: //" | sed "s/ .*//" ) ]; then HAS7ZIP=0 && echo -e "Warning: 7zip NOT found, the compiled svn snapshot will NOT be compressed";else HAS7ZIP=1;fi
	if [ ! -x $( whereis fteqcc | sed "s/fteqcc: //" | sed "s/ .*//" ) ];then HASFTEQCC=0;else HASFTEQCC=1;fi
	if [ -d svn ];then SVNCO=1;else SVNCO=0 && mkdir svn;fi
}
 
COFTEQCC()
{
	echo -e "Checking out FTQECC from SVN"
	if [ -d ./svn/qclib ];then svn revert svn/qclib > /dev/null && svn up svn/qclib > /dev/null;fi
	if [ "$?" != 0 ];then ERROR=2 && echo -e "$( date ): subversion update of \"https://fteqw.svn.sourceforge.net/svnroot/fteqw/trunk/engine/qclib/\" FAILED" >> install_nexuiz_svn.log;fi
	if [ ! -d ./svn/qclib ];then svn co https://fteqw.svn.sourceforge.net/svnroot/fteqw/trunk/engine/qclib/ ./svn/qclib > /dev/null;fi
	if [ "$?" != 0 ];then ERROR=2 && echo -e "$( date ): subversion checkout of \"https://fteqw.svn.sourceforge.net/svnroot/fteqw/trunk/engine/qclib/\" FAILED" >> install_nexuiz_svn.log;fi
}
 
CODP()
{
	echo -e "Checking out Dark Places from SVN"
	if [ -d ./svn/darkplaces ];then svn revert ./svn/darkplaces && svn up ./svn/darkplaces > /dev/null;fi
	if [ "$?" != 0 ];then ERROR=1 && echo -e "$( date ): subversion update of \"svn://svn.icculus.org/twilight/trunk/darkplaces/\" FAILED" >> install_nexuiz_svn.log;fi
	if [ ! -d ./svn/darkplaces ];then svn co svn://svn.icculus.org/twilight/trunk/darkplaces/ ./svn/darkplaces > /dev/null;fi
	if [ "$?" != 0 ];then ERROR=1 && echo -e "$( date ): subversion checkout of \"svn://svn.icculus.org/twilight/trunk/darkplaces/\" FAILED" >> install_nexuiz_svn.log;fi
}
 
CONEX()
{
	echo -e "Checking out Nexuiz from SVN"
	if [ -d ./svn/nexuiz ];then svn revert ./svn/nexuiz && svn up ./svn/nexuiz > /dev/null;fi
	if [ "$?" != 0 ];then ERROR=1 && echo -e "$( date ): subversion update of \"svn://svn.icculus.org/nexuiz/trunk/\" FAILED" >> install_nexuiz_svn.log;fi
	if [ ! -d ./svn/nexuiz ];then svn co svn://svn.icculus.org/nexuiz/trunk/ ./svn/nexuiz > /dev/null;fi
	if [ "$?" != 0 ];then ERROR=1 && echo -e "$( date ): subversion checkout of \"svn://svn.icculus.org/nexuiz/trunk/\" FAILED" >> install_nexuiz_svn.log;fi
}
 
PATCH()
{
echo "nothing" > /dev/null
}
 
COMPILEFTEQCC()
{
	echo -e "Compiling FTEQCC"
	cd ./svn/qclib
	make clean && make
	if [ "$?" != 0 ];then ERROR=2 && echo -e "$( date ): fteqcc (qclib) failed to compile" >> install_nexuiz_svn.log;else HASFTEQCC=2;fi
	cd "$CUR"
}
 
COMPILEDP()
{
	echo -e "Compiling Dark Places"
	if [ "$TARGET" = "both" ]; then set -- nexuiz
	 elif [ "$TARGET" = "client" ]; then set -- cl-nexuiz
	 elif [ "$TARGET" = "server" ]; then set -- sv-nexuiz
	 else ERROR=1 && echo -e "$( date ): darkplaces failed to compile (invalid target)" >> install_nexuiz_svn.log
	fi
	cd  ./svn/darkplaces
	make clean && make $1
	if [ "$?" != 0 ];then ERROR=1 && echo -e "$( date ): darkplaces failed to compile" >> install_nexuiz_svn.log;fi
	mv nexuiz* "$CUR"/nexuiz_SVN_$( date +%m-%d-%y )
	cd "$CUR"
}
 
COMPILENEX()
{
	echo -e "Compiling Nexuiz"
	if [ "$HASFTEQCC" = 2 ];then FTEQCC="$CUR/svn/qclib/fteqcc.bin"
	 elif [ "$HASFTEQCC" = 1 ];then FTEQCC="$( whereis fteqcc | sed "s/fteqcc: //" | sed "s/ .*//" )"
	 elif [ "$HASFTEQCC" = 0 ];then
	  if [ $( uname -m ) = "x86_64" -o $( uname -m ) = "amd64" ];then CPUTYPE=64;elif [ $( uname -m ) = "i686" -o $( uname -m ) = "i386" ] ; then CPUTYPE=32; else unset CPUTYPE && echo "Auto-Detect OS type Failed..."; fi
	  if [ -n "$CPUTYPE" ];then cd ./svn
	   wget http://downloads.sourceforge.net/fteqw/fteqcc"$FTECV"-linux"$CPUTYPE".tar.gz
	   tar -xzf fteqcc$FTECV-linux$CPUTYPE.tar.gz
	   FTEQCC=./svn/fteqcc$CPUTYPE
	   cd "$CUR"
	   else ERROR=3
	  fi
	fi
	if [ "$ERROR" != 3 ]; then
	  ln -s "$FTEQCC" "$CUR"/nexuiz_SVN_$( date +%m-%d-%y )/data/qcsrc/menu
	  ln -s "$FTEQCC" "$CUR"/nexuiz_SVN_$( date +%m-%d-%y )/data/qcsrc/client
	  ln -s "$FTEQCC" "$CUR"/nexuiz_SVN_$( date +%m-%d-%y )/data/qcsrc/server
	  cd "$CUR"/nexuiz_SVN_$( date +%m-%d-%y )/data/qcsrc/menu && ./fteqcc.bin
	  cd "$CUR"/nexuiz_SVN_$( date +%m-%d-%y )/data/qcsrc/client && ./fteqcc.bin
	  cd "$CUR"/nexuiz_SVN_$( date +%m-%d-%y )/data/qcsrc/server && ./fteqcc.bin
	  cd "$CUR"
	#  the statements below should work fine but they dont?
	#   "$FTEQCC" -src "$CUR"/nexuiz_SVN_$( date +%m-%d-%y )/data/qcsrc/menu
	#   "$FTEQCC" -src "$CUR"/nexuiz_SVN_$( date +%m-%d-%y )/data/qcsrc/client 
	#   "$FTEQCC" -src "$CUR"/nexuiz_SVN_$( date +%m-%d-%y )/data/qcsrc/server 
	 else ERROR=1 && echo -e "$( DATE ): All attempts to find/create a useable version of fteqcc were unsuccessful. \"EPIC FAILURE!\"" >> install_nexuiz_svn.log
	fi
}
 
# EXPORTDP()
# {
# }
 
EXPORTNEX()
{
	echo -e "Exporting Nexuiz"
	if [ -d nexuiz_SVN_$( date +%m-%d-%y ) ]; then rm -rf nexuiz_SVN_$( date +%m-%d-%y );fi
	svn export ./svn/nexuiz/ ./nexuiz_SVN_$( date +%m-%d-%y )
}
 
CLEANIT()
{
	echo -e "Clean up"
	cd nexuiz_SVN_$( date +%m-%d-%y )/data
	rm -rf gfx demos sound textures video "$( if [ "$MAPS" = 0 ]; then echo maps;fi )"
	cd "$CUR"
}
 
PACKIT()
{
	echo -e "Packing Nexuiz"
	cd nexuiz_SVN_$( date +%m-%d-%y )/data
	# zip -r - . -x *.cfg *.pk3 | dd of=data$( date +%Y%m%d ).pk3 # ftw. zip sux ass
	7za a -tzip -mx=${COMPRESSION} -x\!*.cfg -x\!*.txt -x\!*.sh -x\!*.pl -x\!*.pk3 data$( date +%Y%m%d ).pk3 ./
	for D in *
	 do
	 if [ -d "$D" ]; then rm -rf "$D";fi
	 done
	cd "$CUR"
}
 
PRUNEOLD()
{
	echo -e "Pruning old versions"
	LIST=`ls -1 nexuiz_SVN_* | grep -o ".*:" | tr -d ":"`
	let COUNT=`echo -e "$LIST" | grep -c nexuiz_SVN_.*`-"$((BACKUPS+=1))"
	for C in $( seq $COUNT )
	  do
	  OBJ=$( echo -e "$LIST" | head -n1 )
	  rm -rf "$OBJ"
	  OBJ=$( echo -e "$LIST" | sed '1d' )
	  done
	echo -e "\nYou'll want to paste this folder in your base.conf now\n\nnexuiz_SVN_$( date +%m-%d-%y )\n"
}
 
HELPME()
{
echo "
Useage:
compile_nexuiz_SVN.sh [option]
 
options are:
 
 client		only compiles what is nessary for client
 server		compiles only whats needed for a stand alone server
		NOTE: within the script their is an option that not include the default
		maps in the snapshot, thereby reducing the initial install size to < 50MB
 both		compiles both client and server (imagine that)
 help		your lookin at it!
 
the \"options\" are just that, \"optional\"...
current defaults are:
 
build type = "$TARGET"
include maps with server build = $( if [ "$MAPS" = 0 ]; then echo "no";elif [ "$MAPS" = 1 ]; then echo "yes";fi )
compress \"data\" folder = $( if [ "$COMPRESSIT" = 0 ]; then echo "no";elif [ "$COMPRESSIT" = 1 ]; then echo "yes";fi )
remove old versions = $( if [ "$PRUNE" = 0 ]; then echo "no";elif [ "$PRUNE" = 1 ]; then echo "yes";fi )
number of backup copies (old versions) to keep = "$BACKUP"
 
you can set the default options by editing this script"
}
cd $install_dir
cd ..
mkdir serverz && mkdir serverz/base
cd serverz/base 
CUR=$( pwd )
set -- $( echo "$1" | tr [:upper:] [:lower:] | tr -d [-] )
 
case $1 in
 server)	TARGET=server;;
 client)	TARGET=client;;
 both)		TARGET=both;;
 help)		HELPME;;
 *)		TARGET=${TARGET};;
esac
 
echo -e "Installing a Nexuiz $TARGET"
echo -e "\nYou won't see much action until it begins to compile.  THIS MAY TAKE A WHILE!!! Go read a book.\n"
 
ENVCHK
if [ "$ERROR" = 1 ];then echo -e "A Fatal error has occured\nplease check \"install_nexuiz_svn.log\" for details" && exit 1;fi
COFTEQCC
CODP
if [ "$ERROR" = 1 ];then echo -e "A Fatal error has occured\nplease check \"install_nexuiz_svn.log\" for details" && exit 1;fi
CONEX
if [ "$ERROR" = 1 ];then echo -e "A Fatal error has occured\nplease check \"install_nexuiz_svn.log\" for details" && exit 1;fi
EXPORTNEX
if [ "$ERROR" = 1 ];then echo -e "A Fatal error has occured\nplease check \"install_nexuiz_svn.log\" for details" && exit 1;fi
COMPILEFTEQCC
if [ "$ERROR" = 1 ];then echo -e "A Fatal error has occured\nplease check \"install_nexuiz_svn.log\" for details" && exit 1;fi
COMPILENEX
if [ "$ERROR" = 1 ];then echo -e "A Fatal error has occured\nplease check \"install_nexuiz_svn.log\" for details" && exit 1;fi
COMPILEDP "$TARGET"
if [ "$ERROR" = 1 ];then echo -e "A Fatal error has occured\nplease check \"install_nexuiz_svn.log\" for details" && exit 1;fi
if [ "$TARGET" = "server" ]; then CLEANIT;fi
if [ "$ERROR" = 1 ];then echo -e "A Fatal error has occured\nplease check \"install_nexuiz_svn.log\" for details" && exit 1;fi
if [ "$COMPRESSIT" = 1 -a "$HAS7ZIP" = 1 ]; then PACKIT; fi
if [ "$ERROR" = 1 ];then echo -e "A Fatal error has occured\nplease check \"install_nexuiz_svn.log\" for details" && exit 1;fi
if [ "$PRUNE" = 1 ];then PRUNEOLD;fi

# Install Aliases
#cd $install_dir
#cd ..
#core_file=$(ls nst_core*.sh |egrep "[0-9]{6}" |sort -r |head -n 1)
#chmod +x $core_file
#echo -e "\nAdding alias \"nexst\" to .bashrc\n"
#echo -e "\nalias nexst='$(pwd)/./$core_file'" >> ~/.bashrc
