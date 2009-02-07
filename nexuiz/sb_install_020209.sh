#!/bin/bash
# ver 0.86
 
#### user options ####
## if you want to fully automate this script you can use these options
target="complete"					# valid options are "client" "server" or "complete"
maps=1						# only effects server installations.set to "0" if you dont want to install standard maps 
 
## these automatically remove old working copies when the latest is successfully compiled
prune=1						# turns auto pruning on
backups=0 					# sets number of backup copies (old snapshots)
 
# would you like your "data" folder compressed?
# leaving uncompressed *could* lead to faster initial load times
# and compressing could cut the size of the install by %50 or more
compressit=0
compression=9					# Compression Level 0-larger and faster to compress, 9-smaller slower
 
svnfolder=$(pwd)/svn				# all source code will be placed here
 
nexprefix=Nexuiz_SVN_				# folder name
 
suffix="revision"				# unique build identifier set to "revision" or "date"
 
logfile="compile_nexuiz_svn.log"		# a file for logging important events.
 
#### end user options ####
 
 
ENVCHK() {
if [[ ! ( -w "$cur" && -r "$cur" && -x "$cur" ) ]]; then echo "You do not have RWX Permission. Bye...";exit 1;fi
if [[ ! -x $( whereis svn | sed "s/svn: //" | sed "s/ .*//" ) ]];then error=1 && echo -e "ERROR: Couldnt locate svn in\nplease check subversion installation";fi
if [[ ! -x $( whereis 7z | sed "s/7z: //" | sed "s/ .*//" ) ]]; then has7zip=0 ;else has7zip=1;fi
if [[ ! -x $( whereis fteqcc | sed "s/fteqcc: //" | sed "s/ .*//" ) ]];then hasfteqcc=0;else hasfteqcc=1;fi
if [[ -d "$svnfolder" ]];then svnco=1;else svnco=0 && mkdir "$svnfolder";fi
}
 
COFTEQCC() {
if [[ -d "$svnfolder"/qclib ]];then echo "Updating Subversion for FTEQCC" && svn up svn/qclib | grep revision;fi
if [[ "$?" != 0 ]];then error=2 && echo -e "$( date ): subversion update of \"https://fteqw.svn.sourceforge.net/svnroot/fteqw/trunk/engine/qclib/\" FAILED" >> "$cur"/"$logfile";fi
if [[ ! -d "$svnfolder"/qclib ]];then echo "Starting Subversion Checkout for FTEQCC" && svn co https://fteqw.svn.sourceforge.net/svnroot/fteqw/trunk/engine/qclib/ "$svnfolder"/qclib | grep revision;fi
if [[ "$?" != 0 ]];then error=2 && echo "$( date ): subversion checkout of \"https://fteqw.svn.sourceforge.net/svnroot/fteqw/trunk/engine/qclib/\" FAILED" >> "$cur"/"$logfile";fi
}
 
CODP() {
if [[ -d "$svnfolder"/darkplaces ]];then echo "Updating Subversion for Darkplaces" && svn up "$svnfolder"/darkplaces | grep revision;fi
if [[ "$?" != 0 ]];then error=1 && echo -e "$( date ): subversion update of \"svn://svn.icculus.org/twilight/trunk/darkplaces/\" FAILED" >> "$cur"/"$logfile";fi
if [[ ! -d "$svnfolder"/darkplaces ]];then echo "Starting Subversion Checkout for Darkplaces" && svn co svn://svn.icculus.org/twilight/trunk/darkplaces/ "$svnfolder"/darkplaces | grep revision;fi
if [[ "$?" != 0 ]];then error=1 && echo -e "$( date ): subversion checkout of \"svn://svn.icculus.org/twilight/trunk/darkplaces/\" FAILED" >> "$cur"/"$logfile";fi
}
 
CONEX() {
nexcomsg=
if [[ -d "$svnfolder"/nexuiz ]];then echo "Updating Subversion for Nexuiz" && nexcomsg=$(svn up $(if [[ "$rflag" = 1 ]]; then echo "-r "$rval"";fi) "$svnfolder"/nexuiz | grep revision);fi
if [[ "$?" != 0 ]];then error=1 && echo -e "$( date ): subversion update of \"svn://svn.icculus.org/nexuiz/trunk/\" FAILED" >> "$cur"/"$logfile";fi
if [[ ! -d "$svnfolder"/nexuiz ]];then echo "Starting Subversion Checkout for Nexuiz" && nexcomsg=$(svn co svn://svn.icculus.org/nexuiz/trunk/ "$svnfolder"/nexuiz | grep revision);fi
if [[ "$?" != 0 ]];then error=1 && echo -e "$( date ): subversion checkout of \"svn://svn.icculus.org/nexuiz/trunk/\" FAILED" >> "$cur"/"$logfile";fi
revision=$(echo "$nexcomsg" | tr -d [:alpha:][:space:][.])
echo "$nexcomsg"
if [[ "$suffix" = revision ]]; then suffix="$revision"; elif [[ "$suffix" = date ]]; then suffix=$( date +%Y%m%d ); else echo -e "invalid \"suffix\"!\Please edit this script and correct the issue" && exit ;fi
}
 
PATCHPAUSE() {
echo -e "please apply your patches now\n-- Press ENTER when finished --"
read nothing 
}
 
COMPILEFTEQCC() {
cd "$svnfolder"/qclib
echo "Compiling FTEQCC!"
export CFLAGS="-w"
make clean > /dev/null && make >> "$cur"/"$logfile"
if [[ "$?" != 0 ]];then error=2 && echo -e "$( date ): fteqcc (qclib) failed to compile" >> "$cur"/"$logfile";else hasfteqcc=2;fi
cd "$cur"
}
 
COMPILEDP() {
if [[ "$target" = "complete" ]]; then set -- nexuiz
 elif [[ "$target" = "client" ]]; then set -- cl-nexuiz
 elif [[ "$target" = "server" ]]; then set -- sv-nexuiz
 else error=1 && echo -e "$( date ): darkplaces failed to compile (invalid target)" >> "$cur"/"$logfile"
fi
cd  "$svnfolder"/darkplaces
echo "Compiling Darkplaces!"
make clean > /dev/null && make $1  >> "$cur"/"$logfile"
if [[ "$?" != 0 ]];then error=1 && echo -e "$( date ): darkplaces failed to compile" >> "$cur"/"$logfile";fi
cp nexuiz* "$cur"/"$nexprefix""$suffix"
cd "$cur"
}
 
COMPILENEX() {
if [[ "$hasfteqcc" = 2 ]];then fteqccbin="$cur/svn/qclib/fteqcc.bin"
 elif [[ "$hasfteqcc" = 1 ]];then fteqccbin="$( whereis fteqcc | sed "s/fteqcc: //" | sed "s/ .*//" )"
 elif [[ "$hasfteqcc" = 0 ]];then
   cd "$svnfolder"
   rm -f linux32-fteqcc.zip
   wget -q http://users.tpg.com.au/users/moodles/linux32-fteqcc.zip
   unzip -qquo linux32-fteqcc.zip
   fteqccbin="$svnfolder"/linux32-fteqcc
   cd "$cur"
   if [[ ! -x "$fteqccbin" ]]; then error=3;fi
   else error=3
fi
if [[ "$error" != 3 ]]; then
  echo -e  "\nCompiling Nexuiz!"
  ln -s "$fteqccbin" "$cur"/"$nexprefix""$suffix"/data/qcsrc/menu/fteqcc.bin >> "$cur"/"$logfile"
  ln -s "$fteqccbin" "$cur"/"$nexprefix""$suffix"/data/qcsrc/client/fteqcc.bin >> "$cur"/"$logfile"
  ln -s "$fteqccbin" "$cur"/"$nexprefix""$suffix"/data/qcsrc/server/fteqcc.bin >> "$cur"/"$logfile"
  cd "$cur"/"$nexprefix""$suffix"/data/qcsrc/menu && ./fteqcc.bin >> "$cur"/"$logfile"
  cd "$cur"/"$nexprefix""$suffix"/data/qcsrc/client && ./fteqcc.bin >> "$cur"/"$logfile"
  cd "$cur"/"$nexprefix""$suffix"/data/qcsrc/server && ./fteqcc.bin >> "$cur"/"$logfile"
  cd "$cur"
 else error=1 && echo -e "$( date ): All attempts to find/create a useable version of fteqcc were unsuccessful. \"EPIC FAILURE!\"" >> "$cur"/"$logfile"
fi
}
 
EXPORTNEX() {
if [[ -d "$nexprefix""$suffix" && "$Fflag" = 1 ]]
 then rm -rf "$nexprefix""$suffix";
  elif [[ -d "$nexprefix""$suffix" && -z "$Fflag" ]]
   then echo "Looks like your already using the newest revision of Nexuiz" && exit
fi
echo "Exporting a working copy of Nexuiz, be patient."
svn export "$svnfolder"/nexuiz/ "$cur"/"$nexprefix""$suffix"
}
 
CLEANIT() {
cd "$cur"/"$nexprefix""$suffix"/data
rm -rf gfx demos sound textures video "$( if [[ "$maps" = 0 ]]; then echo maps;fi )"
cd "$cur"
}
 
PACKIT() {
cd "$cur"/"$nexprefix""$suffix"/data
7za a -tzip -mx=${compression} -x\!*.cfg -x\!*.txt -x\!*.sh -x\!*.pl -x\!*.pk3 data$( date +%Y%m%d ).pk3 ./
for D in *
 do
 if [[ -d "$D" ]]; then rm -rf "$D";fi
 done
cd "$cur"
}
 
PRUNEOLD() {
LIST=$(ls -1 "$nexprefix"* | grep -o ".*:" | tr -d ":")
let COUNT=$(echo -e "$LIST" | grep -c "$nexprefix".*)-"$((backups+=1))"
for C in $( seq $COUNT )
  do
  OBJ=$( echo -e "$LIST" | head -n1 )
  rm -rf "$OBJ"
  OBJ=$( echo -e "$LIST" | sed '1d' )
  done
}
 
CONETRADIANT() {
netradcomsg=
if [[ -d "$svnfolder"/NetRadiant ]];then echo "Updating Subversion for NetRadiant" && netradcomsg=$(svn up $(if [[ "$rflag" = 1 ]]; then echo "-r "$rval"";fi) "$svnfolder"/NetRadiant | grep revision);fi
if [[ "$?" != 0 ]];then error=1 && echo -e "$( date ): subversion update of \"http://emptyset.endoftheinternet.org/svn/radiant15/trunk/\" FAILED" >> "$cur"/"$logfile";fi
if [[ ! -d "$svnfolder"/NetRadiant ]];then echo "Starting Subversion Checkout for NetRadiant" && netradcomsg=$(svn co http://emptyset.endoftheinternet.org/svn/radiant15/trunk/ "$svnfolder"/NetRadiant | grep revision);fi
if [[ "$?" != 0 ]];then error=1 && echo -e "$( date ): subversion checkout of \"http://emptyset.endoftheinternet.org/svn/radiant15/trunk/\" FAILED" >> "$cur"/"$logfile";fi
revision=$(echo "$netradcomsg" | tr -d [:alpha:][:space:][.])
echo "$netradcomsg"
if [[ "$suffix" = revision ]]; then suffix="$revision"; elif [[ "$suffix" = date ]]; then suffix=$( date +%Y%m%d ); else echo -e "invalid \"suffix\"!\Please edit this script and correct the issue" && exit ;fi
}
 
EXPORTNETRADIANT() {
if [[ -d NetRadiant_"$suffix" && "$Fflag" = 1 ]]
 then rm -rf NetRadiant_"$suffix";
  elif [[ -d NetRadiant_"$suffix" && -z "$Fflag" ]]
   then echo "Looks like your already using the newest revision of NetRadiant" && exit
fi
echo "Exporting a working copy of NetRadiant, be patient."
svn export "$svnfolder"/NetRadiant/ "$cur"/NetRadiant_"$suffix"
}
 
COMPILENETRADIANT() {
cd "$cur"/NetRadiant_"$suffix"
echo "Compiling NetRadiant!"
export CFLAGS="-w"
make clean > /dev/null && make -s >> "$cur"/"$logfile" 
if [[ "$?" != 0 ]];then error=1 && echo -e "$( date ): NetRadiant failed to compile" >> "$cur"/"$logfile";fi
cd "$cur"
}
 
NETRADIANT() {
CONETRADIANT
if [[ "$error" = 1 ]];then echo -e "A Fatal error has occured\nplease check \""$logfile"\" for details" && exit 1;fi
EXPORTNETRADIANT
if [[ "$error" = 1 ]];then echo -e "A Fatal error has occured\nplease check \""$logfile"\" for details" && exit 1;fi
COMPILENETRADIANT
if [[ "$error" = 1 ]];then echo -e "A Fatal error has occured\nplease check \""$logfile"\" for details" && exit 1;fi
}
 
HELPME() {
echo "
Useage:
compile_nexuiz_SVN.sh [option\s]
 
options are:
 
 -c		[0-9]
		Compress the data folder into "date$( date +%Y%m%d ).pk3"
		this can cut the installation size by more than 50%
		and can more than double your build time.
 
 -r		#### {YYYY-MM-DD} {YYYY-MM-DDtHH:MM}
		Build a specific revision of nexuiz.
		can accept revision number or date/time.
		be warned, svn is pretty picky about the date/time format.
		e.g. "./compile_nexuiz_svn.sh  -r {2008-07-22t11:25}" | "./compile_nexuiz_svn.sh  -r 5009"
 
 -t		Nexuiz Build type (ignored with -R); valid options are:
		[server|s] 	compiles only the server executable
		[client|c]	compiles only the client executable (glx & sdl)
		[all|both|a|b]	compiles BOTH server and client executables
 
 -R		Compiles NetRadiant insted of Nexuiz
 
 -F		Force recompile (will not update!)
 
 -p		Pauses after SVN update to allow for code patches (not usefull to most ppl) 
 -h		HELP: your lookin at it!
 
example:
this will compile a server based on the last revision before 2008-07-22 11:25am
and will compress the data folder at a compression level of 7
 
"./compile_nexuiz_svn.sh  -c 7 -r {2008-07-22t11:25} -t s"
 
 
current defaults are:
 
build type = "$target"
include maps with server build = $( if [[ "$maps" = 0 ]]; then echo "no";elif [[ "$maps" = 1 ]]; then echo "yes";fi )
compress \"data\" folder = $( if [[ "$compressit" = 0 ]]; then echo "no";elif [[ "$compressit" = 1 ]]; then echo "yes";fi )
remove old versions = $( if [[ "$prune" = 0 ]]; then echo "no";elif [[ "$prune" = 1 ]]; then echo "yes";fi )
number of backup copies (old versions) to keep = "$backups"
 
you can set the default options by editing this script"
}
 
cur=$( pwd )
 
while getopts "?RFpc:t:r:" opt; do
 case "$opt" in
   t)tflag=1;tval="$OPTARG"
	case "$tval" in
	 server|s) target=server ;;
	 client|c) target=client ;;
	 all|both|a|b) target=complete ;;
	 *) echo "Invalid build type!"; HELPME; break;;
	esac;;
   c) compressit=1;if [[ $OPTARG = [0-9] ]]; then compression="$OPTARG";else echo "invalid compression level, try 0-9" && exit;fi ;;
   r) prune=0;rflag=1;rval="$OPTARG";;
   p) pflag=1 ;;
   F) Fflag=1 ;;
   R) Rflag=1 ;;
  \?) echo "Invalid option -$OPTARG"; HELPME; exit ;;
 esac
done
 
if [[ $Rflag = 1 ]];then NETRADIANT && echo "looks like your finished";exit;fi
 
echo "Building Nexuiz $(if [[ $target != complete ]];then echo "$target";fi)"
ENVCHK
if [[ "$error" = 1 ]];then echo -e "A Fatal error has occured\nplease check \""$logfile"\" for details" && exit 1;fi
if [[ ! "$Fflag" = 1 ]];then
 COFTEQCC
 CODP
 if [[ "$error" = 1 ]];then echo -e "A Fatal error has occured\nplease check \""$logfile"\" for details" && exit 1;fi
 CONEX
 if [[ "$error" = 1 ]];then echo -e "A Fatal error has occured\nplease check \""$logfile"\" for details" && exit 1;fi
fi
EXPORTNEX
if [[ "$error" = 1 ]];then echo -e "A Fatal error has occured\nplease check \""$logfile"\" for details" && exit 1;fi
if [[ "$pflag" = 1 ]]; then PATCHPAUSE; fi
COMPILEFTEQCC
if [[ "$error" = 1 ]];then echo -e "A Fatal error has occured\nplease check \""$logfile"\" for details" && exit 1;fi
COMPILENEX
if [[ "$error" = 1 ]];then echo -e "A Fatal error has occured\nplease check \""$logfile"\" for details" && exit 1;fi
COMPILEDP "$target"
if [[ "$error" = 1 ]];then echo -e "A Fatal error has occured\nplease check \""$logfile"\" for details" && exit 1;fi
if [[ "$target" = "server" ]]; then CLEANIT;fi
if [[ "$error" = 1 ]];then echo -e "A Fatal error has occured\nplease check \""$logfile"\" for details" && exit 1;fi
if [[ "$compressit" = 1 && "$has7zip" = 1 ]]; then PACKIT
   elif [[ "$compressit" = 1 && "$has7zip" = 0 ]]; then echo "Cannot compress data folder, 7zip not found" ;fi
if [[ "$error" = 1 ]];then echo -e "A Fatal error has occured\nplease check \""$logfile"\" for details" && exit 1;fi
if [[ "$prune" = 1 ]];then PRUNEOLD;fi
echo "looks like your finished"
 
 
if [[ -h ./Nexuiz_svn ]];then unlink ./Nexuiz_svn;fi
ln -s "$cur"/"$nexprefix""$suffix"/ "$HOME"/Nexuiz_svn
