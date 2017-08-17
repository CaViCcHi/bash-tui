#!/usr/bin/env bash
##
#

### UNRELATED
# aug10 2017 - YOU LEFT A /usr/lib/env somewhere at work at home I dont know.
### UNRELATED
. ${BASHTUI_LIB}/say.sh



[ ! -e /etc/bash-tui.conf ] && return 0 # well that didn't last long, did it?
. /etc/bash-tui.conf

SVN_CHECKGRACEFUL="/usr/bin/svn status --depth=empty --non-interactive --xml . 2>&1 | grep -e 'not a working copy' -e 'svn: warning' -q" # Does not check remote
SVN_CHECKREMOTE="/usr/bin/svn ls --depth=empty --non-interactive . &>/dev/null" # Does check remote

SVN_GETREMOTE="/usr/bin/svn info --depth=empty --non-interactive . | grep '^URL:' | sed 's|URL: ||g' " # Grabs the info

SVN_REPO_PATTERN="[%s]\n"
SVN_REPO_COLOR='dred'
SVN_REPO_COLORLIVE='lblue'

# Default
declare -a REPOS=(SVN) # And then GIT..
declare -a CHECKS=(GRACEFUL GET REMOTE) # Types of checks

# Types then declared here.
CHECK_GRACEFUL=CHECKGRACEFUL
CHECK_REMOTE=CHECKREMOTE
CHECK_GET=GETREMOTE

# The one that rules thems alls
VISUAL=
# Are we even in a repo?
REPO=
REPO_PATH=
REPO_ALIVE=
function __detectRepo
{
  REPO_ALIVE=
  REPO_PATH=
  VISUAL=
  REPO=
  for r in ${REPOS[@]}; do
    REPO=$r
    # GRACEFUL
    eval ${SVN_CHECKGRACEFUL}
    [ $? -eq 0 ] && continue 
    # PATH
    REPO_PATH=$(eval ${SVN_GETREMOTE})
    (( $? )) && continue 
    # ALIVE
    eval ${SVN_CHECKREMOTE}
    (( $? )) && continue 
    REPO_ALIVE=1 
    return 0 # This means all 3 completed succesfully
  done
  return 1
}

## IF detectRepo

# make Command Line... clever eh? 
function _MaCline_refresh
{
  if ! __detectRepo; then
    VISUAL= 
    return 1 # back to sleep
  fi
  [ ! -z ${REPO_PATH} ] && VISUAL="$(printf "$SVN_REPO_PATTERN" "$REPO_PATH")$NC"
  (( ${REPO_ALIVE} )) && VISUAL="${!SVN_REPO_COLORLIVE}${VISUAL}" && return 0
  VISUAL="${!SVN_REPO_COLOR}${VISUAL}"
  return 0
}

function BASHTUI_cline
{
  ERR_before=$?
  if ! _MaCline_refresh; then
    export PS1="${BASHTUI_PS1}"
    return 0 # back to sleep
  fi
  [ -z "$VISUAL" ] && return 0 # also back to sleep
  export PS1="${VISUAL}\n${BASHTUI_PS1}"
  return $ERR_before
}

PROMPT_COMMAND="BASHTUI_cline"
