#!/bin/bash

if [[ $(which jq) == "" ]] ; then
    echo "Could not find jq command"
    exit 1
fi

xcolors="$( dirname $0 )/../resources/xcolors.json"
if [[ ! -e "${xcolors}" ]] ; then
    echo "Could not find xcolors.json"
    exit 1
fi

n=1
cat ${xcolors} | jq -r '.[] | ( .number | tostring) + " " + .name + " " + .hex' | while read line ; do

    code=$( echo ${line} | cut -d' ' -f1 )
    name=$( echo ${line} | cut -d' ' -f2 )
    hex=$( echo ${line} | cut -d' ' -f3 )
    r=$( echo ${hex} | cut -c2-3 )
    g=$( echo ${hex} | cut -c4-5 )
    b=$( echo ${hex} | cut -c6-7 )
    brightness=$( expr $((16#${r})) + $((16#${g})) + $((16#${b})) )

    #echo ${brightness}
    if [[ ${brightness} -gt 380 ]] ; then

        printf "\e[48:5:${code};30m %3d \e[m" ${code}
    else

        printf "\e[48:5:${code};97m %3d \e[m" ${code}
    fi

    n=$( expr ${n} + 1)
    if [[ $n -eq 17 ]] ; then

        n=1
        echo
    fi
done
