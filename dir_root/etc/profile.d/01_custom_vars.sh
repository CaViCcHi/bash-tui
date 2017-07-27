#!/usr/bin/env bash

export LOCATEDBDIR=/var/lib/mlocate/
export MYETH=$(ip -4 route list 0/0 | awk '{print $5}')

export BASHTUI_LIB=/usr/lib/bash-tui
export BASHTUI_BIN=/usr/bin/bash-tui

PATH=${PATH}:${BASHTUI_BIN}
