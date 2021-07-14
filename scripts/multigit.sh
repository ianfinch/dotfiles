#!/bin/bash

cmd=""
targetDir="${PWD}"

# Colours
GREEN=$( echo -e "\033[38:5:34m" )
AMBER=$( echo -e "\033[38:5:166m" )
RED=$( echo -e "\033[38:5:196m" )
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
    branch=""

        if [[ ! -e ${dir}/.git ]] ; then

            status=$( echo "$status" | sed 's/ /!/' )
        colour=${RED}

        else

            branch=" $( echo -e '\ue0a0' ) $( git -C ${dir} rev-parse -q --abbrev-ref HEAD )"

            if [[ $( git -C ${dir} status | grep Untracked -c ) -ne 0 ]] ; then
                status=$( echo "$status" | sed 's/ /?/' )
                colour=${RED}
            fi

            if [[ $( git -C ${dir} status | grep "new file" -c ) -ne 0 ]] ; then
                status=$( echo "$status" | sed 's/ /+/' )
                colour=${RED}
            fi

            if [[ $( git -C ${dir} status | grep modified -c ) -ne 0 ]] ; then
#                modified=$( echo -e '\u270f' )
                modified="M"
                status=$( echo "$status" | sed "s/ /$modified/" )
                colour=${RED}
            fi

            if [[ $( git -C ${dir} status | grep deleted -c ) -ne 0 ]] ; then
#                deleted=$( echo -e '\u274c' )
                deleted="D"
                status=$( echo "$status" | sed "s/ /$deleted/" )
                colour=${RED}
            fi

            if [[ $( git -C ${dir} status | grep ahead -c ) -ne 0 ]] ; then
                arrow=$( echo -e '\u2191' )
                status=$( echo "$status" | sed "s/ /$arrow/" )
                if [[ "$colour" != "$RED" ]] ; then
                    colour=${AMBER}
                fi
            fi

            if [[ $( git -C ${dir} status | grep behind -c ) -ne 0 ]] ; then
                arrow=$( echo -e '\u2193' )
                status=$( echo "$status" | sed "s/ /$arrow/" )
                if [[ "$colour" != "$RED" ]] ; then
                    colour=${AMBER}
                fi
            fi
        fi

        if [[ "${status}" == "${statusInit}" ]] ; then
            tick=$( echo -e '\u2714' )
            status=$( echo "$status" | sed "s/ /$tick/" )
        fi

        echo " ${colour}${status} ${dir}${branch}${PLAIN}"
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
