#!/usr/bin/env bash
##
#

# This gets executed as . bashparms.sh 

# As of now you can nest this twice. I call bash lib with the possibility of parameters. and the main one. you can probably
# play with caller and get the depth from a methodino

[ -n "$_P_DEBUG_" ] && echo "[    ]all parms '$*' && '${!_BP[*]}' ++ '$(caller 0)' \$?='$?'" #- DEBUG

# At this point make sure you're cleaning up between levels
_P_ocm="$_P_cm"
_P_cm="$(caller 0 | awk '{print $2}')"
[ -n "$_P_DEBUG_" ] && echo "and then '$(caller)' [1]> '$(caller 1)' [2]> '$(caller 2)'" 
[ -n "$_P_DEBUG_" ] && echo "CM:$_P_cm"
##TODO
( [  ] && [ "$_P_cm" = 'main' ] ) && declare -A _BP=()
[ -z "${!_BP[*]}" ] && declare -A _BP=()

[ -n "$_P_DEBUG_" ] && echo "[ -->]all parms '$*' && '${!_BP[*]}' ++ '$(caller 0)' \$?='$?'" #- DEBUG

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
				# so you keep -a AND the following parameter AND also the parameter by itself, why?
				# it's because if this has a parameter it might matter or not
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

_normalize_source_file(){
local fa="$1"
local OD="$2"
local wa= # Weighed Assumption
local ta= # Temporary Assumption
while true; do
    [ "${fa:0:1}" = "/" ] && [ -e "$fa" ] && wa=$fa && break
    [ "${fa:0:2}" = "./" ] && ta="${OD}/${fa:2}" && [ -e "$ta" ] && wa="$ta" && break
    ta="${OD}/${fa}" && [ -e "$ta" ] && wa="$ta" && break
    break # This really shouldn't happen, unless we're not in a file?!
done
echo ${wa}
}
_BP_getSourcedFiles() {
    # grep for lines that start with a dot or 'source', then remove leading dots or 'source' keyword
    # and exclude lines with 'bash-tui' or 'bashparms'
    local origin="$1"
    local origin_dir=$(dirname "${origin}")
    local -a raw_files
    raw_files=( $(grep -E '^\s*(\.|source)\s+' "${origin}" | grep -vE 'bash-tui|bashparms' | sed -E 's/^\s*(\.|source)\s+//') )
    for file in "${raw_files[@]}"; do
      echo "$(_normalize_source_file "${file}" "${origin_dir}")"
    done
}


## I don't like getHelp --cit.
_BP_getHelp()
{
  cT="\e[0;33m" ## Color 1
  cA="\e[0;34m" ## Color 2
  cN="\e[0;0m"
  # Original file
  local origin="$(readlink -fq "$(caller 0 | awk '{print $3}')")"

  echo -e "\n"
  # header
  echo -e "Help generated by bashparms automagically for ${cT}${origin}${cN} and libraries\n\n"

  tabs 4

  declare -A h
  IFS=$'\n'
  # Add origin and sourced files to files array
  local -a files=( "${origin}" $(_BP_getSourcedFiles "${origin}"))
  [ -n "$_P_DEBUG_" ] && echo "${files[*]}"
  # Who needs help? whoever's not me and has to look into this
  for file in "${files[@]}"; do
  IFS=$'\n'
    for VAR in $(cat "$file" | grep -E '^([^#]|).*(getParm|isParm|isNotParm)' | sed -E 's/.*(getParm|isParm|isNotParm) ([a-zA-Z0-9]+[a-zA-Z0-9_-]*[a-zA-Z0-9]*).*(##BP: |$)(.*)/\2 \4/g'); do
      unset IFS
      read k v <<< $(echo $VAR)
      if [ -z "${h[$k]+_}" ];then
        h+=( [$k]=$v )
      else
        h[$k]+=$v
      fi
    done
   unset IFS
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
  #(( $? )) && echo "Nobody was able to help :( call for help..." && exit 119
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
