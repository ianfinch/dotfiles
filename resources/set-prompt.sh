export TERM=xterm-color

if [[ `whoami` == "root" ]] ; then
   prompt="#"
   colour="31"
else
   prompt="$"
   colour="36"
fi

setTitle='\e]0;\u@\h:\W\a'
setPrompt="[\e[0;${colour}m\u\e[m@\e[0;35m\h\e[m:\e[0;32m\w\e[m]$prompt "

export PS1="$setTitle$setPrompt"
