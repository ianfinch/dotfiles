#!/bin/bash

COMMAND=$(basename $0)
machine=$(uname -m)
wd=/usr/local/src

case "${COMMAND}_$machine" in

    go_x86_64)
        dockerImage="golang:alpine"
        ;;

    tinygo_x86_64)
        dockerImage="tinygo/tinygo"
        ;;

    *)
        echo "Unsupported architecture: $machine"
        exit 1
        ;;
esac

# Copy across any environmental variables starting with 'GO'
envVars=$(env | while read envVar ; do
    if [[ "$(echo $envVar | cut -c1-2)" == "GO" ]] ; then
        echo -n " _e $envVar"
    fi
done)

# Any local paths need to get mapped to our target working directory
envVars=$(echo $envVars | sed -e "s|$PWD|$wd|g" -e 's/_e/-e/g')

# Start the docker container
if [[ "$1" == "bash" ]] ; then
    docker run -ti --name go --hostname go -e "TERM=xterm-256color" $envVars -v "$PWD":$wd -w $wd $dockerImage sh
else
    docker run -ti --name go --hostname go -e "TERM=xterm-256color" $envVars -v "$PWD":$wd -w $wd -p 3000:3000 $dockerImage $COMMAND $*
fi
docker rm go
