#!/usr/bin/env bash

REX_repos='\.svn|\.git';

function allfiles
{
ARG=$1
    find $(pwd) -type f | grep -vE $REX_repos | grep "$1" --color
}
function alldirs
{
    find $(pwd) -type d | grep -vE $REX_repos
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
		say "Well I need the name of who you want to wake up";
		return 1;
	fi
	if [[ -z "${CHECK+x}" ]]; then
		say "I have no idea who '$WHO' is... are you sure?"
		return 1;
	fi

	$CMD -i $MYETH ${!CHECK}
}

function unrpm
{
    basedir=$(pwd)
    therpm=$1
    subdir=$(rpm -qp $1)
    (( $? )) && say "There was an issue with your command: $0, is $therpm an rpm?" error && return 1
    # With a second parameter I expect a path
    # If absolute, well absolute, if relative... well relative.
    if [ ! -z "$subdir" ];then
        if [ -d "$subdir" ];then
            say "ERROR: Dir "$subdir" exists, stopping..." error && return 1
        else
            say "I am about to make the directory $subdir to export $therpm" $yellow
            sleep 5
            mkdir -p "$subdir"
        fi
    fi
    cd "$subdir"
    rpm2cpio "$basedir/$therpm" | cpio -ivdm
    (( $? )) && say "ERROR: There was a probleme extracting the rpm, check for errors above." error && return 1
    cd "$basedir"
    say "Extracted in: $basedir/$subdir" $green

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

## PERLOCATE
##
## locates perl module given Switchvox::API::Users::RapidDial::Entries (sometimes I don't feel like replacing manually)
# Usage: perlocate Switchvox::API::Users::RapidDial::Entries
perlocate()
{
  l="${1//:://}";
  locate ${l}
  (( $? )) && echo "Maybe the last one is a method" && locate $(dirname ${l})
}

##
## Tracks speed and traffic for an interface given
netspeed()
{
    ## if you don't give me an interface I'll get what I think is default
    [ ! -z "$1" ] && eth=$1 || eth=$(ip -4 route list 0/0 | awk '{print $5}' | head -n1)
    RX=/sys/class/net/$eth/statistics/rx_bytes
    TX=/sys/class/net/$eth/statistics/tx_bytes

    ( [ ! -e ${RX} ] || [ ! -e ${TX} ] ) && say "Make sure $eth is correct..." error && exit 1

    TIME_start=$(date +%s)

    TX_start=$(cat $TX | xargs)
    TX_speed=0
    TX_pretty=0
    TX_weight=0
    TX_end=0

    RX_start=$(cat $RX | xargs)
    TX_speed=0
    RX_pretty=0
    RX_weight=0
    RX_end=0

    TIME_pretty=0

    sleep 1

    ## And now let's do some me.. math
    echo -e "\nRunning Netspeed against interface: $eth"
    tabs 45 
    while true; do ((r++))
        RX_weight=$(( $(cat $RX | xargs) - $RX_start ))
        TX_weight=$(( $(cat $TX | xargs) - $TX_start ))
        TIME_weight=$(( $(date +%s) - $TIME_start ))

        RX_speed=$(( $RX_weight - $RX_end ))
        TX_speed=$(( $TX_weight - $TX_end ))

        ## Why end? cause I'm negative..
        RX_end=$RX_weight
        TX_end=$TX_weight

        ## Get the right values
        TIME_pretty=$(_netspeed_pretty ${TIME_weight} T 1)

        RX_pretty=$(_netspeed_pretty ${RX_weight} S 1)
        TX_pretty=$(_netspeed_pretty ${TX_weight} S 1)
        RX_speed_pretty=$(_netspeed_pretty ${RX_speed} S 1)
        TX_speed_pretty=$(_netspeed_pretty ${TX_speed} S 1)

        # This is to reset the line
        echo -ne "                                                                                        \r"
        # This is the output
        
        echo -ne "${dred}RX:${red}$RX_pretty - ${RX_speed_pretty}/s\t"
        echo -ne "${orange}TX:${yellow}$TX_pretty - ${TX_speed_pretty}/s${NC}\t"
        echo -ne "${dgreen}Time:${green}${TIME_pretty}\r"

        ## Measure speed and translate it to dots...
        (( $RX_speed )) && RX_leng=$(printf %0$(_netspeed_liner ${RX_speed})s|tr \  -)
        (( $TX_speed )) && TX_leng=$(printf %0$(_netspeed_liner ${TX_speed})s|tr \  -)
        sleep 1

        echo -ne "                                                                                                    \r"
        echo -e "${dred}##|${red}${RX_leng}\t${orange}##|${yellow}${TX_leng}\t${dgreen}Time:${green}${TIME_pretty}${NC}"
    done
return 0
}
### I decided to scale this in 4 sections of 5, 10, 10, 10 dots/dashes/equals.
# -> _netspeed_liner SPEED_Bps 
_netspeed_liner()
{
  [ -z "$1" ] && exit 50
  _speed=$1

  ## 1. 5 slots from 0 to 1mbps = 131.072
  mbps1=131072
  mbps1_slot=$(( mbps1 / 10 ))
  ## 2. 10 slots from 1mbps to 10mbps = 1.310.720
  mbps10=1310720
  mbps10_slot=$(( mbps10 / 10 ))
  mbps10_start=9
  ## 3. 10 slots from 10mbps to 100mbps = 13.107.200
  mbps100=13107200
  mbps100_slot=$(( mbps100 / 10 ))
  mbps100_start=19
  ## 4. 10 slots from 100mbps to 1gbps = 134.217.728
  mbps1000=134217720
  mbps1000_slot=$(( mbps1000 / 10 ))
  mbps1000_start=29
  ## Starting score
  _score=1
  ## Now calculate RX
  while true; do
    (( ! $_speed )) && _score=0 && break

    ## 1 gbps
    if [ $_speed -gt $mbps100 ]; then
      _score=${mbps1000_start}
      for (( m=10; m>0; m--)); do
        (( $(( _speed / ( mbps1000_slot * m ) )) )) && (( _score += m )) && break 2
      done
      (( _score += 11 ))
    ## 100 mbps
    elif [ $_speed -gt $mbps10 ]; then
      _score=${mbps100_start}
      for (( m=10; m>0; m--)); do
        (( $(( _speed / ( mbps100_slot * m ) )) )) && (( _score += m )) && break 2
      done
      (( _score += 10 ))
    ## 10 mbps
    elif [ $_speed -gt $mbps1 ]; then
      _score=${mbps10_start}
      for (( m=10; m>0; m--)); do
        (( $(( _speed / ( mbps10_slot * m ) )) )) && (( _score += m )) && break 2
      done
      (( _score += 10 ))
    ## 1 mbps
    elif [ $_speed -le $mbps1 ]; then
      for (( m=10; m>0; m--)); do
        #say "[$m]doing: $(( _speed / ( mbps1_slot * m ) )) : $_speed / $(( mbps1_slot * m ))"
        (( $(( _speed / ( mbps1_slot * m ) )) )) && (( _score += m )) && break 2
      done
    fi
    break
  done
  echo "${_score}"
}
# -> _netspeed_pretty IT_weight 'T' 1/0
# original value, Array of magnitude (GB, MB etc), Recursive magnitude
_netspeed_pretty()
{
  ## 1024 or 1000...
  kbv=1024 
  declare -A Ss=(
    [G]=$((kbv * kbv * kbv))
    [M]=$((kbv * kbv))
    [K]=${kbv}
    [b]=1
  )
  declare -a So=( G M K b )
  
  ## TIME
  declare -A Ts=(
    [d]=$((60 * 60 * 24))
    [h]=$((60 * 60))
    [m]=60
    [s]=1
  )
  declare -a To=( d h m s )

  # The remainder during the operations
  IT_rest=
  # The final string
  IT_pretty=''
  # The initial value, mandatory
  IT_weight=$1 || return 23
  # The name of the array in which you have the order of magnitude (GB. MB... etc)
  L_name=$2 || 'S'
  # If you want the magnitude to be recursive: 1 (eg. 3G,24M,14K,3b), or if you want to stop at the first occurrence: 0 (eg. 1GB)
  recursive=$3 || recursive=0

  declare -A Ls
  declare -a Lo
  eval "Lo=( \"\${${L_name}o[@]}\" )"

  # yeah I know this is violently convoluted, so what?
  d=0
  for (( c=0; c<${#Lo[@]}; c++ )); do
    Ls[${Lo[$c]}]=$(eval "echo \${${L_name}s[${Lo[$c]}]}")
    IT_tmp=$(( $IT_weight / ${Ls[${Lo[$c]}]} ))
    if (( $IT_tmp )); then 
      (( $d )) && IT_pretty+=','
      IT_pretty+="${IT_tmp}${Lo[$c]}"
      ## if we want to make this recursive...
      ((d++))
      if (( $recursive )); then
        IT_rest=$(( $IT_weight % ${Ls[${Lo[$c]}]} ))
        ## So if we have any rest, we'll rest it
        (( $IT_rest )) && IT_weight=$IT_rest || break
      else
        break
      fi
    fi
  done
  echo "${IT_pretty}"
return 0
}
## I've never run that fast! -- cit.

## ALLATEST
##
## gets a list of the last 50 files modified within your dir and in its subdirs
## if you add "loop" it will keep looping every second until you ctrl+c
# Usage: allatest [loop]
allatest()
{
    if ( [ ! -z $1 ] && [ $1 = loop ] );then
        while true; do ls -lart `allfiles` | tail -50; sleep 1; done
    else
        ls -lart `allfiles` | tail -50 # I can rewrite it... I dislike evals
    fi

}


# SVN Blame a file
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
	/bin/grep --color=always -r \
    --exclude-dir='.git' 	\
    --exclude-dir='.svn' 	\
    --exclude-dir='.cvs' 	\
    --exclude-dir='/proc'	\
    --exclude-dir='/dev'	\
    --exclude-dir='/run'	\
    --exclude-dir='/sys'	\
    "${allofit//\"/\\\"}"	\
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


## RPMVERCMP
##
## it uses the Perl RPM2 which uses the rpm c lib, so pretty trustworthy, if you give me 6_0_frank > 6.0; gino_5_0_lol > 5.0
# Returns: 'gt' = 'Greater than'; 'lt' = 'Less than'; 'eq' = 'Same as' (I mean pretty straightforward, no?)
# Usage: rpmvercmp 6.5.2 6.5.1 (returns 'gt')
rpmvercmp()
{
    [ -z $1 ] && say "ERROR: I need the first parameter as the version you need information on" error && return 1
    [ -z $2 ] && say "ERROR: I need a second parameter as the version to which you want to comparei '$1'" error && return 1
    # let's clean the inputs
    f=$(echo "$1" | sed -r 's|^[^0-9]*?([0-9]+[0-9_\-]*[0-9]+)[^0-9]*$|\1|g' | sed -r 's|[_\-]|.|g')
    s=$(echo "$2" | sed -r 's|^[^0-9]*?([0-9]+[0-9_\-]*[0-9]+)[^0-9]*$|\1|g' | sed -r 's|[_\-]|.|g')
    RES=$(/usr/bin/perl -e "use lib '/usr/local/lib/perl5';use RPM2; print RPM2::rpmvercmp('$f', '$s');")
    (( $? )) && say "ERROR: I had a problem comparing '$f' with '$s', please check them again" error && return 1
    [ $RES -eq 1 ] && say gt
    [ $RES -eq 0 ] && say eq
    [ $RES -eq -1 ] && say lt

    return 0
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
