#!/usr/bin/env bash
## TODO: we need to use a larged depth of color
Bc="\e[%d;%dm"
Bph="Cantami o diva del pelide Achille l'ira funesta..."
getcolor() { _c=$(printf $Bc $1 $2); [ -z $3 ] && echo "${_c}$Bph : $1 $2${NC}" || eval "export ${3}=\$_c";  }

getcolor 0 31   red
getcolor 1 31   RED
getcolor 0 34   blue
getcolor 1 34   BLUE
getcolor 0 36   cyan
getcolor 1 36   CYAN
getcolor 0 32   green
getcolor 1 32   GREEN
getcolor 0 33   yellow
getcolor 1 33   YELLOW
getcolor 1 1    bold
getcolor 0 35   purple

getcolor 0 0    NC      ## No color

blu="\\033[48;5;95;38;5;214m"
