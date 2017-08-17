#!/usr/bin/env bash
##
# COLORS
Bctop=256
NC="\e[0;0m" ## NC doesn't exist on the 256 table
# Initial Mapping
declare -a Bclrs
for c in $(seq 0 ${Bctop}); do
  Bclrs[$c]=C${c}
done
# Get Colors
colorget() { 
  Bc="\e[38;5;%dm"
  Bph="Cantami o diva del pelide Achille l'ira funesta..."
  _c=$(printf $Bc $1)
  [ -z $2 ] && echo -e "${_c}$Bph : ${Bclrs[$1]} ${NC}" && return 1
  [ "$2" != "C$1"  ] && eval "export ${2}=\$_c";  
}
# Set names
colorset() {
  [ -z $1 ] && echo "ERROR: I need a color id as first parameter" && return 1
  [ -z $2 ] && echo "ERROR: I need a color name as second parameter" && return 1

  Bclrs[$1]=$2
}
# Show rainbow
colorshow() {
  for c in $(seq 0 ${Bctop}); do
    colorget $c
  done
}
# Export your customs
colorexport() {
  for c in $(seq 0 ${Bctop}); do
    [ "${Bclrs[$c]}" != "C${c}" ] && echo "colorset $c ${Bclrs[$c]}"
  done
}
# Cause I said so
colorreset() {
 # I'll come back to this 
  say "I am not ready yet..." warning
}

# Specify colors, I mean if you know the names...
colorset 0    black
colorset 1    dred
colorset 2    dgreen
colorset 3    dyellow
colorset 4    blue
colorset 5    dmagenta
colorset 6    dcyan
colorset 7    lgrey
colorset 8    dgrey
colorset 9    red
colorset 10   green 
colorset 11   yellow 
colorset 12   lblue
colorset 13   magenta 
colorset 14   cyan 
colorset 15   white 
colorset 20   dblue

colorset 52   maroon

colorset 82   lgreen

colorset 90   purple
colorset 93   violet
colorset 100  gold
colorset 201  pink
colorset 202  dorange
colorset 208  orange
colorset 214  lorange

colorset 228  lyellow

colorset 244  grey

# now set them
for cc in $(seq 0 ${Bctop}); do
  colorget $cc ${Bclrs[$cc]}
done
