#!/bin/bash

COMMAND=$(basename $0)
machine=$(uname -m)

case "$machine" in

    x86_64)
        dockerImage="golang:alpine"
        ;;

    *)
        echo "Unsupported architecture: $machine"
        exit 1
        ;;
esac

envVars=$(env | while read envVar ; do
    if [[ "$(echo $envVar | cut -c1-2)" == "GO" ]] ; then
        echo -n "-e $envVar "
    fi
done)

if [[ "$1" == "bash" ]] ; then
    docker run -ti --name go --hostname go -e "TERM=xterm-256color"$envVars -v "$PWD":/usr/local/src -w /usr/local/src $dockerImage sh
else
    docker run -ti --name go --hostname go -e "TERM=xterm-256color"$envVars -v "$PWD":/usr/local/src -w /usr/local/src -p 3000:3000 $dockerImage $COMMAND $*
fi
docker rm go
