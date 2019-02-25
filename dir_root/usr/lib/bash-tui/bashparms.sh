#!/usr/bin/env bash
##
#

# This gets executed as . bashparms.sh 

## I really fu**ing dislike that there's no wholesome way to grab parameters... so I'd say let's just fuc*ing improvise...
# As of now you can nest this twice. I call bash lib with the possibility of parameters. and the main one. you can probably
# play with caller and get the depth from a methodino

[ -n "$_P_DEBUG_" ] && say "[    ]all parms '$*' && '${!_BP[*]}' ++ '$(caller 0)' \$?='$?'" $BLUE #- DEBUG

# At this point make sure you're cleaning up between levels
_P_ocm="$_P_cm"
_P_cm="$(caller 0 | awk '{print $2}')"
[ -n "$_P_DEBUG_" ] && say "and then '$(caller)' [1]> '$(caller 1)' [2]> '$(caller 2)'" $blue
[ -n "$_P_DEBUG_" ] && echo "CM:$_P_cm"
## I forgot what I had to put there... fuck - for now this is ok cause it's as if the line didn't exist
( [  ] && [ "$_P_cm" = 'main' ] ) && declare -A _BP=()
[ -z "${!_BP[*]}" ] && declare -A _BP=()

[ -n "$_P_DEBUG_" ] && say "[ -->]all parms '$*' && '${!_BP[*]}' ++ '$(caller 0)' \$?='$?'" $cyan #- DEBUG

if [ -n "$*" ];then
	declare -a tp=( "$@" )
	declare -a _PP=();
	_endparms=
	qty=${#tp[*]}
	for (( j=0; j<=${qty}; j++ )); do
		[ -n "$_skipnext" ] && _skipnext= && continue # I will use this in case you tell me that a specific parameter requires a value, so I skip the collection of it afterwards
		if ( [ -z "$_endparms" ] && [ "${tp[$j]:0:2}" = '--' ] ); then ## DBL --parm or -- [end]
			[ "${#tp[$j]}" -eq 2 ] && _endparms=true && continue
			if [[ "${tp[$j]}" =~ '=' ]]; then
				# Then probably it's a --param=something
				read k v <<< $(echo "${tp[$j]:2}" | sed 's|=| |')
			else
				# I would check the next param to see if it's a value or just another parm		
				# so you keep -a AND the following parameter AND also the parameter by itself, why? shits and giggles I guess...
				# NO, not shits and giggles, it's because if this has a parameter it might matter or not
				k=${tp[$j]:2}
				( [ -z "${tp[$(($j+1))]+_}" ] || [ "${tp[$(($j+1))]:0:1}" = '-' ] ) && v=1 || v=${tp[$(($j+1))]}
			fi
			[ ! -z "${_BP["$k"]}" ] && echo "Duplicated '--$k $v' | Already parsed '--$k ${_BP["$k"]}'" && continue
			_BP+=( ["$k"]="$v" )
		elif ( [ -z "$_endparms" ] && [ "${tp[$j]:0:1}" = '-' ] ); then ## SINGLE -p
			# And in this case take it all -bpa asd ==> -b asd -p asd -a asd
			# why? why not? if the user wants -b -p -a asd or even just -b -p -a why should they even care
			# about the actual value, instead of being 1 (arbitrarily true) it's 'asd', it works the same.
			( [ -z "${tp[$(($j+1))]+_}" ] || [ "${tp[$(($j+1))]:0:1}" = '-' ] ) && v=1 || v=${tp[$(($j+1))]}
			for pr in $(echo "${tp[$j]:1}" | fold -w1);do
				[ ! -z "${_BP["$pr"]}" ] && echo "Duplicated '-$pr $v' | Already parsed '-$pr ${_BP["$pr"]}'" && continue
				_BP+=( ["$pr"]=$v )
			done
		else
			_PP+=( "${tp[$j]}" )
		fi
	done
	# So now clean the set...
	#( [ "$_P_cm" = 'main' ] || [ "$cm" != "${_P_self_}" ] ) && set -- && set -- ${_PP[*]}
	set -- && set -- ${_PP[*]}
fi

#### Parametrizer - if you have a configuration file instead of parameters
## just pass me a file name and I will look for a pair of KEY[space(s)]Value
if ( [ ! -z "${_BP[parametrizer]+_}" ] && [ -e "${_BP[parametrizer]}" ] );then
  ## Now read through it
  IFS=$'\n'
  for LINE in $(cat "${_BP[parametrizer]}" | grep -v '^#'); do
    ##TODO But Willy't Wonka if you have spaces in the parameter? If you quote it I think so
    IFS=$' '
    read k v <<< $LINE
    _BP+=( [$k]=$v )
  done
  unset IFS
fi
#### /

#### DEBUG #
if [ -n "$_P_DEBUG_" ]; then
	echo "Dashed Parameters: " 
	for kk in "${!_BP[@]}";do
		echo "$kk -> ${_BP[$kk]}"
	done
	echo "Other Parameters: "
	for kk in "$@";do
		echo "$kk"
	done
fi

####################################
#### METHODS

### INTERNALS

## I don't like getHelp --cit.
_BP_getHelp()
{
  cT="\e[0;33m" ## Color 1
  cA="\e[0;34m" ## Color 2
  cN="\e[0;0m"

  echo -e "\n"
  # header
  echo -e "Help generated by bashparms automagically for file $(caller 0 | awk '{print $3}')\n\n"

  tabs 4

  IFS=$'\n'
  declare -A h
  # Who needs help? whoever's not me and has to look into this
  for VAR in $(cat "$(caller 0 | awk '{print $3}')" | grep -E '^[^#].*(getParm|isParm|isNotParm)' | sed -E 's/.*(getParm|isParm|isNotParm) ([a-zA-Z]+[a-zA-Z0-9_-]*[a-zA-Z0-9]+).*(##BP: |$)(.*)/\2 \4/g'); do
    unset IFS
    read k v <<< $(echo $VAR)
    if [ -z "${h[$k]+_}" ];then
      h+=( [$k]=$v )
    else
      h[$k]+=$v
    fi
  done
  for v in $(echo "${!h[@]}" | xargs -n1 | sort | xargs); do ((p++))
    [ ${#v} -gt 1 ] && pv='--' || pv='-'
    [ -z "${h[$v]}" ] && h[$v]=''
    ((p%2)) && c=$cT || c=$cA

    echo -e "\t${c}${pv}${v}${cN}"
    [ -n "${h[$v]}" ] && echo -e "\t\t${c}'--(${cN}${h[$v]}${c})${cN}" || echo -e "\t"
  done
  echo -e "\n"
  ## In case you need help, call for help, but not here...
  #(( $? )) && say "Nobody was able to help :( call for help..." error && exit 119
  return 0
}

### EXTERNALS

# Y U NO PARMS??
isNoParm()
{
  [ "${#_BP[@]}" -lt 1 ] && return 0 || return 1
}

## In case you need to set parameters inside your code 
setParm()
{
  [ -z $1 ] && return 2 || k=$1
  [ -z $2 ] && v=1 || v=$2

  _BP+=( [$k]=$v ) || return 1
return 0
}

## TODO: for multiple parameters, create an assignment sheet on the script file. now I even wonder why you should have a choice of paramters long and short
## like:
##BP: f > force
##BP: l > length
# Return
isParm()
{
	[ -z $1 ] && return 2
	[ -z "${_BP["$1"]+_}" ] && return 1 || return 0
}
## Mainly cause I'm addicted to &&
isNotParm()
{
	[ -z $1 ] && return 2
	[ -z "${_BP["$1"]+_}" ] && return 0 || return 1
}
# Read - echo
getParm()
{
	isParm "$1" && echo "${_BP["$1"]}" || return 1
}

# It is rude to leave with a dirty debug
_P_DEBUG_=
