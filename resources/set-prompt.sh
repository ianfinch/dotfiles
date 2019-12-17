# Set up prompt (tried with solarized)
#
# Notes
#  - uses Powerline font for chevrons
#  - the \[ ... \] construct stops contained characters being used in prompt length calculation

export TERM=xterm-color

if [[ `whoami` == "root" ]] ; then
   swatch=(124 160 202 235)
else
   swatch=(61 33 37 235)
fi

chevron=$'\xee\x82\xb0'

setColour() {
    echo "\[\e[48;5;${swatch[$1]};38;5;230m\]"
}

chevron() {
    chevronChar=$'\xee\x82\xb0'
    echo "\[\e[48;5;${swatch[$2]};38;5;${swatch[$1]}m\]$chevronChar"
}

machine="$(setColour 0)\h$(chevron 0 1)"
username="$(setColour 1)\u$(chevron 1 2)"
directory="$(setColour 2)\w$(chevron 2 3)"

setTitle='\e]0;\u@\h:\W\a'
setPrompt="${machine}${username}${directory}\[\e[m\] "

export PS1="$setTitle$setPrompt"
