#!/bin/bash

machine=$(uname -m)
case "$machine" in

    x86_64)
        dockerImage="guzo/serverless"
        ;;

    *)
        echo "Unsupported architecture: $machine"
        exit 1
        ;;
esac

# Copy across any environmental variables starting with 'AWS'
envVars=$(env | while read envVar ; do
    if [[ "$(echo $envVar | cut -c1-3)" == "AWS" ]] ; then
        echo -n " _e $envVar"
    fi
done)
envVars=$(echo $envVars | sed -e 's/_e/-e/g')

if [[ "$1" == "bash" ]] ; then
    docker run -ti --name sls --hostname sls -e "TERM=xterm-256color" $envVars --user ian -e "HOME=/home/ian" -v "$PWD":/usr/src/sls -w /usr/src/sls $dockerImage bash
else
    docker run -ti --name sls --hostname sls -e "TERM=xterm-256color" $envVars --user ian -e "HOME=/home/ian" -v "$PWD":/usr/src/sls -w /usr/src/sls $dockerImage sls $*
fi
docker rm sls
