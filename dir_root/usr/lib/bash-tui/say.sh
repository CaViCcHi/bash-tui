#!/usr/bin/env bash 
##
#

### DEBUG???
_D_=
############

_L_dir_=/var/log
_L_file_=say_output.log
_L_hor_dir_=$_L_dir_
_L_hor_file_=$_L_file_
###############################

_L_l_=30 # Log Level debug:30 warning:20 info:10 error:0 - unset:no logging?

# Default message
_L_hor_=
###############

# TODO: you gotta organize levels and numbers, centralize :)
# say "hey" error -> [ ... ][ERROR] hey <- red color
# say "hey" warning -> [ ... ][WARNING] hey <- yellow color
# say "hey" debug -> [ ... ][DEBUG] hey <- blue color
#
# say "hey" xxx -> [ ... ][xxx] hey <- no color
# say "hey" xxx red -> [ ... ][xxx] hey <- $red color
#
# say "hey" 100 grey <- grey colored "hey" and log level 100
# say "hey" boring 100 grey <- grey colored "hey" with submessage [boring] and log level 100
#
# I may split this lol...
#
# s => Status of Error :: TODO: so you need to rethink this part, divide [string-identifier][ERROR|WARNING...]
# x => Control query string, where in the log we are
# c => Color of Text :: TODO: Add patterning maybe...
# m => Final message
# b => Initial Log block :: Date - status string
# l => Log Level : read up on _L_l_
function say()
{	
	[ -z "${_L_l_}" ] && echo -e "$1" && return 0 #- Okay... geee...
  # This works with BASH-TUI
  [ -z "${BTUI_n}" ] && [ -n "$BTUI_cache" ] && [ -e "$BTUI_cache" ] && . "$BTUI_cache"
	#Default
  local x= # Control variable
	local c= # El Colore
	local s="${_L_hor_}" # Signal/Log level
	local l=10 #- info
	local b="[$(date '+%Y-%m-%d %H:%M:%S')]" #- What the log looks like
	local m=$1
  local doexit=0
  local exitnum=1
	# Parameters
	if [ ! -z "${2}" ];then
		if [ "${2}" = "debug" ]; then
			l=30
			c=${blue}
			s=DEBUG
      x=1
		elif [ "${2}" = "error" ]; then
			l=0
			c=${red}		
			s=ERROR
      x=1
		elif [ "${2}" = "exit" ]; then
			l=0
			c=${red}		
			s=ERROR
      x=1
      doexit=1
      [ ! -z $3 ] && exitnum=$3
		elif [ "${2}" = "warning" ]; then
			l=20
			c=${yellow}
			s=WARNING
      x=1
		elif [ "${2}" = "logonly" ]; then
			l=0
			lo=true
      x=20
    elif [[ "${2}" =~ ^[0-9]*$ ]]; then
      l=$2
      x=30
    ## This is legacy, if you send $red instead of red
    # the assignments in the if happen only if the first one is met
    elif [[ ${2} =~ \[[0-9\;]*m$ ]]; then 
      c=$2 
      x=40
    # this is the color "red"
    elif [ ! -z ${BTUI_s[${2}]+_} ]; then
      c=$(printf $BTUI_cp ${BTUI_s[${2}]})
      x=40
		else
			s="$2"
      x=50
		fi
	fi
  # SKIP THIS if I have a doexit
  # If you have a third parameter
  (( ! $doexit  )) && for me in 1; do # An old fisherman's trick
	if [ ! -z $3 ]; then
    ## numbers cannot be used as color name in colorset
    [ -z $clr ] && [[ ${3} =~ ^[0-9]*$ ]] && l=$3 && continue # I didn't have a color but a number
    # And this third parameter is a color or is named like one :D
    # the assignments in the if happen only if the first one is met, bite me
    [[ ${3} =~ [[0-9\;]*m$ ]] && clr=$3
    [ ! -z ${BTUI_s[${3}]+_} ] && clr=$(printf $BTUI_cp ${BTUI_s[${3}]})
    [ -z $clr ] && continue ## Dude I don't know what to do with it
    # I have a signal already let's recolor it
    ( [ $x -eq 1 ] || [ $x -eq 20 ] ) && c=$clr && continue # I like 'continue' better, lexically
    # If I had a submessage then color it
    [ $x -eq 50 ] && c=$clr && break # I know it's confusing, I'm showing it just doesn't matter
    # And now the freak red red situash, just swap color with submessage
    [ $x -eq 40 ] && q=$c && c=$clr && continue
    # So now I got a log level
    [ $x -eq 30 ] && c=$clr && continue
  fi
  done
  # SKIP THIS if I have a doexit
  # What about a fourth? ahuahua
  # for now this is just a color
  (( ! $doexit  )) && for me in 1; do # An old fisherman's trick
	if [ ! -z $4 ]; then
    # And this third parameter is a color or is named like one :D
    # the assignments in the if happen only if the first one is met, bite me
    [[ ${4} =~ [[0-9\;]*m$ ]] && clr=$4
    [ ! -z ${BTUI_s[${4}]+_} ] && clr=$(printf $BTUI_cp ${BTUI_s[${4}]})
    [ -z $clr ] && continue ## Dude I don't know what to do with it
    # I'm not gonna play this game
    [ ! -z $c ] && [ ! -z $q ] && continue 
    # Swap submesage with color
    [ ! -z $c ] && q=$c && c=$clr && continue
  fi
  done
	# So should I actually say this?
	[ $l -gt ${_L_l_} ] && return 0 # Okie dokie then... shhh
	# Coloring
	[ ! -z $c ] && m="${c}${m}${NC}"
	[ ! -z $s ] && b+="[${s}]"
	# Speaking
	[ ! $lo ] && echo -e "$m" 
	# Logging
	echo -e "${b} ${m}" >> "${_L_dir_}/${_L_file_}"

  (($doexit)) && exit $exitnum
return 0
}

say_clean()
{
	_L_hor_=
	_L_dir_=${_L_DEF_dir_}
	_L_file_=${_L_DEF_file_}
}
