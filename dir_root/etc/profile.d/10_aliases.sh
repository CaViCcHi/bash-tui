#!/bin/bash
alias ls='ls --color'
alias ll='ls -lah --color'
alias lt='ls -lart'
alias cd..='cd ..'
alias cd...='cd ..'
alias gettime='ntpdate -s 18.26.4.105'

alias t='tail -100f'

export PS1="${yellow}[\w]${purple}[\$?]${NC}\n[\u@\H \t]\\$ "
