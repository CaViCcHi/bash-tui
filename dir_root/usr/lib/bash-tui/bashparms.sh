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
				read k v <<< $(echo "${tp[$j]:2}" | sed 's|=| |g')
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

# Return
isParm()
{
	[ -z $1 ] && return 1
	[ -z "${_BP["$1"]+_}" ] && return 1 || return 0
}
## Mainly cause I'm addicted to &&
isNotParm()
{
	[ -z $1 ] && return 1
	[ -z "${_BP["$1"]+_}" ] && return 0 || return 1
}
# Read - echo
getParm()
{
	isParm "$1" && echo "${_BP["$1"]}" || return 1
}

# It is rude to leave with a dirty debug
_P_DEBUG_=
