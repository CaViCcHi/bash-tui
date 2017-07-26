#!/usr/bin/env bash

function allfiles
{
ARG=$1
    find $(pwd) -type f | grep -v svn | grep "$1" --color
}
function alldirs
{
    find $(pwd) -type d | grep -v svn
}

function llocate
{
NOW=$(pwd)
        echo -e "Updating locate local db from ${NOW}"
        updatedb -U ${NOW} -o ${LOCATEDBDIR}locate_local.db
        echo -e "Searching in ${NOW}"
        locate -d ${LOCATEDBDIR}locate_local.db $1
}

function wakeup
{
CMD='/sbin/ether-wake';
WHO=$1;
CHECK="MAC_${WHO^^}"

	if [[ -z $WHO ]]; then
		echo "Well I need the name of who you want to wake up";
		return 1;
	fi

	if [[ -z "${!CHECK}" ]]; then
		echo -e "I have no idea who '$WHO' is... are you sure?"
		return 1;
	fi

	$CMD -i $MYETH ${!CHECK}
}

function unrpm
{
    rpm2cpio $1 | cpio -ivdm
}
function tslog
{
    echo "awk '{timestamp=strftime(\"[%Y-%m-%d %R:%S]\",\$1); \$1=\"\"; print timestamp\$0}' [LOGFILE]"
}

# From a file, get me the rpm
function frpm
{
        thefile=$1;
        ret=$2;

        # Checks
        if [[ -z $thefile ]]; then
                echo -e "\n${RED}ERROR:${NC} I need as first parameter the file you want me to find as part of an rpm";
                return 1;
        fi

        # Find that file
        declare -a locts=( $(/usr/bin/locate $thefile) );
        if [[ ${#locts[@]} = 0 ]]; then
                echo -e "\n${RED}ERROR:${NC} Your search ${green}${thefile}${NC} was unsuccesful, try running 'updatedb'.\n";
                return 1;
        fi

        declare -a rpms;
        # Run through all the results
        for (( j=0 ; j < ${#locts[*]} ; j++ ));
        do
                if [[ ! -z ${locts[$j]} ]]; then
                        thisfile=$(/bin/basename ${locts[$j]});
                        if [[ "${thisfile}" == "${thefile}" ]]; then
                                thisrpm=$(/bin/rpm -qf ${locts[$j]});
                                if [[ $? = 0 ]]; then
                                        if [[ -z $ret ]]; then
                                                whole="${locts[$j]} : $thisrpm";
                                        else
                                                whole="$thisrpm";
                                        fi

                                        rpms+=("$whole");
                                fi
                        fi
                fi
        done

        # Now last check
        if [[ ${#rpms[@]} = 0 ]]; then
                # No results
                if [[ -z $ret ]]; then
                        echo -e "\n${RED}ERROR:${NC} Your search ${green}${thefile}${NC} was unsuccesful, I could not find any matches. Try running 'updatedb'.\n";
                fi
                return 1;
        elif [[ ${#rpms[@]} > 1 ]]; then
                # Too many results
                if [[ -z $ret ]]; then
                        echo -e "\n${yellow}WARNING:${NC} Your search ${green}${thefile}${NC} brought up more than 1 result.\n";
                        for (( j=0 ; j < ${#rpms[*]} ; j++ ));
                        do
                                echo -e "${rpms[$j]}";
                        done
                fi
                return 2;
        else
                # so now we only have 1 result
                echo -e "${rpms[0]}";
                return 0;
        fi

}


# Blame a file
function blame
{
        if [[ -z $1 ]]; then
                echo -e "\n${RED}ERROR:${NC} I need as first parameter the SVN file you want to blame";
                return 1;
        fi
        svn blame $1 | vim -
}

# Grep colored recursive
function cgrep
{
	p=$(pwd);
	allofit="$@";
	if [[ -z $allofit ]]; then
		echo -e "\n${RED}ERROR:${NC} yeah what are you grepping for? I need a parameter";
		return 1;
	fi
	/bin/grep --color=always -r 	\
--exclude-dir='*/.svn/*' 	\
--exclude-dir='*/.cvs/*' 	\
--exclude-dir='/proc/*'		\
--exclude-dir='/dev/*'		\
--exclude-dir='/run/*'		\
--exclude-dir='/sys/*'		\
--exclude-dir='/dev/*'		\
"${allofit//\"/\\\"}"		\
"${p}"
}

# goto get into the directory of a link
warp()
{
	[ -z $1 ] && [ ! -f $1 ]  && echo "ERROR: give me a valid file and I'll take you to its directory, like Spider-man, but for symlinks..." && return 1
	d=$(dirname "$(readlink $1)")
	[ ! -d $d ] && echo "Directory ${d} doesn't exist... bad simlink?" && return 1
	[ ! -z ${_D_} ] && say "Jumped to ${cyan}${d}${NC}"
	cd ${d}/
}

badlinks()
{
	for f in `/bin/ls -AX ./`;do
		[ ! -h $f ] && continue
		[ ! -z "$(readlink -qs $f)" ] && [ ! -f "$(readlink -qs $f)" ] && say "${cyan}$f${NC}" && [ "$1" = '-d' ] && /bin/rm -f $f && say "\tdeleted"
	done
	[ "$1" != '-d' ] && say "if you add -d you can delete those files as well..." badlinks
}

#TODO work on identities better... for work mostly cause you dont give a shit at home
Iam()
{
	[ -z $1 ] && return 1
	export S_name="$@"
	say "Hi ${S_name}"
}

# --device=/dev/sdX (property [property2 [propert3 [propertyX]]])
getUdevProps()
{
_P_DEBUG_=
	#local _P_self_=$(caller 0 | awk '{print $2}')
	. /usr/lib/bash-tui/bashparms.sh

	#say "getUdevProps" $yellow

	isNotParm device && say "You have to specify a device with --device=/dev/DEVICE" error && return 1
	local disk=$(getParm device)
	[ ! -e "$disk" ] && say "The device you specified '$disk' doesn't seem to exist" error && return 1
	
	# Pipe 'em
	local piped=
	for e in $@;do
		piped+="|${e}"
	done

	# If you wonder why... well I only care for the device, not his last possible child
	RET="$(udevadm info -a --name $disk 2>/dev/null)"
	if [ -z "$2" ]; then
		echo "$RET" | grep -m 1 "$1" | sed -r 's|^.*=="([^"]*)".*$|\1|g'
	else
		echo $(for OUT in $@; do echo "$RET" | grep -m 1 "$OUT" | grep '==' | sed 's|^\s*||g' | sed 's|==|=|g' | sed -e 's%{%[%g' | sed -e 's%}%]%g' | xargs -n1; done)
	fi
}

# b: batch mode, get only device names, no other output
# [-b]
declare -a USBDEVS_found
getUsbDevs()
{
_P_DEBUG_=
	. /usr/lib/bash-tui/bashparms.sh # <--- ahahah this shit is amazing

	local -a USBDEVS_found
	for d in `/bin/ls -AX /dev/sd?`;do
		local -A ATTR
		local DRIVERS=
		# I'm a clever sumbitch
		#eval $(udevadm info -a --name "$d" 2>/dev/null | grep -E 'size|storage|removable' | grep '==' | sed 's|^\s*||g' | sed 's|==|=|g' | sed -e 's%{%[%g' | sed -e 's%}%]%g' | xargs -n1)
		eval $(getUdevProps --device="$d" size storage removable)
		[ -z "${ATTR[removable]}" ] && continue
		[ -z "$DRIVERS" ] && continue
		[ "${ATTR[size]}" -le 0 ] && continue
		USBDEVS_found+=("$d")
	done
	if [ -n "${USBDEVS_found[*]}" ];then
		if isParm b;then
			echo "${USBDEVS_found[*]}"
			return 0 
		else
			say "I found ${#USBDEVS_found[@]} device(s): ${USBDEVS_found[*]}"  $yellow; 
			return 0
		fi
	fi
	isParm b && return 1 || say "I could not find any usb detachable devices :(" $red; return 2
}

## gcc $1 -o ${1/.c//}
c()
{
	CF="$1"
	[ -z "$CF" ] && say "You should pass me a .c file as parameter." error && return 1
	[ ! -e "$CF" ] && say "I cannot find the file '$CF'." error && return 1
	
	NCF="${CF/\.c/}"

	gcc "$CF" -o "${CF/\.c/}"
	(( $? )) && say "Hey Nikola, I think something went wrong with '$CF'." error && return 1

	say "OK, I think it worked!" $green
	say "Compiled: ./${NCF}" $yellow
}

chr()
{
	[ -z "$1" ] && exit 1
	[ "$1" -lt 256 ] || return 1
	printf "\\$(printf '%03o' "$1")"
}

ord()
{
	[ -z "$1" ] && exit 1
	echo "${1:0:1}" | tr -d "\n" | od -An -t uC | sed 's|\s*||g'
}

## Gives you a list of chars and its actual ascii code
str_ord()
{
	[ -z "$1" ] && exit 1
	str=$1
	for (( i=0; i<${#str}; i++ )); do
		echo -e "$i\t${str:$i:1}\t$(ord ${str:$i:1})"
	done
}

str_join()
{
	local IFS="$1"
	shift
	echo "$*"
}
