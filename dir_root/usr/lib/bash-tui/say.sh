#!/usr/bin/env bash

### DEBUG???
_D_=
############

_L_dir_=/var/log
_L_file_=say_output.log
_L_hor_dir_=$_L_dir_
_L_hor_file_=$_L_file_
###############################

_L_l_=10 # Log Level debug:30 warning:20 info:10 error:0 - unset:no logging?

_L_hor_=say
###############

# TODO: you gotta organize levels and numbers, centralize :)
# say "hey" error -> [ ... ][ERROR] hey <- red color
# say "hey" warning -> [ ... ][WARNING] hey <- yellow color
# say "hey" debug -> [ ... ][DEBUG] hey <- blue color
#
# say "hey" xxx -> [ ... ][xxx] hey <- no color
# say "hey" xxx ${red} -> [ ... ][xxx] hey <- $red color
#
# I may split this lol...
#
# s => Status of Error :: TODO: so you need to rethink this part, divide [string-identifier][ERROR|WARNING...]
# q => Control query string, where in the log we are
# c => Color of Text :: TODO: Add patterning maybe...
# m => Final message
# b => Initial Log block :: Date - status string
# l => Log Level : read up on _L_l_
say()
{		
	[ -z ${_L_l_} ] && echo -e "$1" && return 0 #- Okay... geee...
	#Default
	c=
	s=
	q="${_L_hor_}"
	l=10 #- info
	b="[$(date '+%Y-%m-%d %H:%M:%S')]" #- What the log looks like
	m=$1
	# Preparing the Status TODO: just loop and get up to 10 (I mean come on)
	[ ! -z ${_L_h1_} ] && q=${_L_h1_}
	[ ! -z ${_L_h2_} ] && q=${_L_h2_}-${q}
	[ ! -z ${_L_h3_} ] && q=${_L_h3_}-${q}
	# Parameters
	if [ ! -z $2 ];then
		if [ "$2" = "debug" ]; then
			l=30
			c=${blue}
			s=DEBUG
		elif [ "$2" = "error" ]; then
			l=0
			c=${red}		
			s=ERROR
		elif [ "$2" = "warning" ]; then
			l=20
			c=${yellow}
			s=WARNING
		elif [ "$2" = "logonly" ]; then
			l=0
			lo=true
    ## TODO: this needs to be fixed cause now the colors are more complicated
		elif [[ ${2:2:2} =~ [01]+\; && ${2:6} = 'm' ]]; then
			c=$2
		else
			q=$2
			[ ! -z $3 ] && [[ ${3:2:2} =~ [01]+\; && ${3:6} = 'm' ]] && c=$3
		fi
		# So should I actually say this?
		[ $l -gt ${_L_l_} ] && return 0;
	fi
	# Coloring
	[ ! -z $c ] && m="${c}${m}${NC}"
	[ ! -z $q ] && b+="[${q}]"
	[ ! -z $s ] && b+="[${s}]"
	# Speaking
	[ ! $lo ] && echo -e "$m" 
	# Logging
	echo -e "${b} ${m}" >> "${_L_dir_}/${_L_file_}"
}

say_clean()
{
	_L_h1_=${_L_hor_}
	_L_dir_=${_L_DEF_dir_}
	_L_file_=${_L_DEF_file_}
}
