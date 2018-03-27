#!/usr/bin/env bash
##
#

[ ! -e /etc/bash-tui.conf ] && return 0 # well that didn't last long, did it?

## LIBS
###
. ${BASHTUI_LIB}/say.sh
. /etc/bash-tui.conf

( [ -z "$BASHTUI_cline_repo_ENABLED" ] || [[ "${BASHTUI_cline_repo_ENABLED}" =~ 0|false ]] ) && return 0 ## oh well... I promise I'm good :(

## TOP OBJs
###
[ ! -z $cline_GRACEFUL ] && unset cline_GRACEFUL
[ ! -z $cline_REMOTE ] && unset cline_REMOTE
[ ! -z $cline_GET ] && unset cline_GET
[ ! -z $cline_REPO_PATTERN ] && unset cline_REPO_PATTERN
[ ! -z $cline_REPO_COLOR ] && unset cline_REPO_COLOR
[ ! -z $cline_REPO_COLORLIVE ] && unset cline_REPO_COLORLIVE

declare -A cline_GRACEFUL
declare -A cline_REMOTE
declare -A cline_GET
declare -A cline_REPO_PATTERN
declare -A cline_REPO_COLOR
declare -A cline_REPO_COLORLIVE

## GIT: You can create custom methods
cline_GRACEFUL[GIT]="/usr/bin/git rev-parse --is-inside-work-tree &>/dev/null 2>&1"
cline_REMOTE[GIT]="/usr/bin/git remote -v | grep '^origin' | tail -1 | awk '{print \$2}'"
cline_GET[GIT]="/usr/bin/git branch -a | grep '^*' | sed 's|^*[[:space:]]*||g'"

cline_REPO_PATTERN[GIT]="[%s]\n"
cline_REPO_COLOR[GIT]=$dred
cline_REPO_COLORLIVE[GIT]=$lblue

cline_REMOTEGIT_ATMOSTSECS=60
cline_REMOTEGIT_LASTALIVE=

_clineParse_REMOTE_GIT()
{
  cline_REPO_PATH+=" -> $2"
  (( $1 )) && cline_REPO_ALIVE=0
  [ ! -z $cline_REMOTEGIT_LASTALIVE ] && \
    [ $(( $(date +%s) - $cline_REMOTEGIT_LASTALIVE )) -lt $cline_REMOTEGIT_ATMOSTSECS ] && cline_REPO_ALIVE=1 && return 0

  [ ! -z "$2" ] && /usr/bin/git ls-remote -h "$2" &>/dev/null 2>&1 && cline_REPO_ALIVE=1 && cline_REMOTEGIT_LASTALIVE=$(date +%s)
  
}

## SVN
cline_GRACEFUL[SVN]="/usr/bin/svn info --depth=empty --non-interactive . &>/dev/null 2>&1" # Does not check remote
cline_REMOTE[SVN]="/usr/bin/svn ls --depth=empty --non-interactive . &>/dev/null 2>&1" # Does check remote
cline_GET[SVN]="/usr/bin/svn info --depth=empty --non-interactive . | grep '^URL:' | sed 's|URL: ||g'" # Grabs the info

cline_REPO_PATTERN[SVN]="[%s]\n"
cline_REPO_COLOR[SVN]=$dred
cline_REPO_COLORLIVE[SVN]=$lblue

#### Default STUFF
#### DO not modify, create _clineParse_{{CHECK}}_{{REPO}} instead

declare -a cline_REPOS=(SVN GIT) # And then GIT..
declare -a cline_CHECKS=(GRACEFUL GET REMOTE) # Types of checks

# The one that rules thems alls
cline_VISUAL=

# Are we even in a repo?
cline_REPO=
cline_REPO_PATH=
cline_REPO_ALIVE=
cline_REPO_CHOSEN=0

## Default methods

_clineParse_GET()
{
  (( $1 )) && cline_REPO_PATH= && return 1
  cline_REPO_PATH="$2"
  cline_REPO_CHOSEN=1
  return 0
}

_clineParse_REMOTE()
{
  cline_REPO_ALIVE=1
  (( $1 )) && cline_REPO_ALIVE=0 
  return 0 # the return in this case is always positive because you're just checking if the remote is alive.
}

####

function __detectRepo
{
  cline_REPO=
  cline_REPO_ALIVE=
  cline_REPO_PATH=
  cline_REPO_CHOSEN=0
  local RETURN=
  for r in ${cline_REPOS[@]}; do
    for c in ${cline_CHECKS[@]}; do
      cline_REPO=$r
      cline="cline_$c[$r]"
      RETURN=$(eval ${!cline}); local EX=$?
      if type -t "_clineParse_${c}_${r}" &>/dev/null 2>&1; then
        _clineParse_${c}_${r} "$EX" "$RETURN" || break
      else
        if type -t "_clineParse_${c}" &>/dev/null 2>&1; then
          _clineParse_${c} "$EX" "$RETURN" || break
        else
          (( $EX )) && break
        fi
      fi
    done
    [ $cline_REPO_CHOSEN -eq 1 ] && return 0
  done
  return 1
}

## IF detectRepo

# make Command Line... clever eh? 
function _MaCline_refresh
{
  if ! __detectRepo; then
    cline_VISUAL= 
    return 1 # back to sleep
  fi
  [ ! -z "${cline_REPO_PATH}" ] && cline_VISUAL="$(printf "${cline_REPO_PATTERN[$cline_REPO]}" "${cline_REPO_PATH[$cline_REPO]}")$NC"
  (( ${cline_REPO_ALIVE} )) && cline_VISUAL="${cline_REPO_COLORLIVE[$cline_REPO]}${cline_VISUAL}" && return 0
  cline_VISUAL="${cline_REPO_COLOR[$cline_REPO]}${cline_VISUAL}"
  return 0
}

function BASHTUI_cline
{
  ERR_before=$?
  if ! _MaCline_refresh; then
    export PS1="${BASHTUI_PS1}"
    return 0 # back to sleep
  fi
  [ -z "$cline_VISUAL" ] && return 0 # also back to sleep
  export PS1="${cline_VISUAL}\n${BASHTUI_PS1}"
  return $ERR_before
}

PROMPT_COMMAND="BASHTUI_cline"
