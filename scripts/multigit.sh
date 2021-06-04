#!/bin/bash

cmd=""
targetDir="${PWD}"

# Colours
GREEN=$( echo -e "\033[38:5:34m" )
AMBER=$( echo -e "\033[38:5:166m" )
RED=$( echo -e "\033[38:5:160m" )
BLUE=$( echo -e "\033[38:5:39m" )
PLAIN=$( echo -e "\033[0m" )

__syntax() {
    echo "Syntax: $0 [ status ] [ <directory> ]"
    exit
}

__status() {
    find ${targetDir} -maxdepth 1 -mindepth 1 -type d | sort | while read dir ; do
        statusInit="    "
        status=$statusInit
        colour=${GREEN}

        if [[ ! -e ${dir}/.git ]] ; then

            status=$( echo "$status" | sed 's/ /!/' )
	    colour=${RED}

        else

            if [[ $( git -C ${dir} status | grep Untracked -c ) -ne 0 ]] ; then
                status=$( echo "$status" | sed 's/ /?/' )
	        colour=${RED}
            fi

            if [[ $( git -C ${dir} status | grep "new file" -c ) -ne 0 ]] ; then
                status=$( echo "$status" | sed 's/ /+/' )
	        colour=${RED}
            fi

            if [[ $( git -C ${dir} status | grep modified -c ) -ne 0 ]] ; then
                status=$( echo "$status" | sed 's/ /M/' )
	        colour=${RED}
            fi
        fi

        if [[ "${status}" == "${statusInit}" ]] ; then
            tick=$( echo -e '\u2714' )
            status=$( echo "$status" | sed "s/ /$tick/" )
        fi

        echo " ${colour}${status} ${dir}${PLAIN}"
    done
}

while [[ $# -gt 0 ]] ; do
    echo TEST $1
    shift
done

# If there is no command, we should do a status check
if [[ "$cmd" == "" ]] ; then
    __status
fi
