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

cat ${xcolors} | jq -r '.[] | [.number, .name] | join(": ")'
