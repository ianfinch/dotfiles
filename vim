#!/bin/sh

machine=$(uname -m)
case "$machine" in

    x86_64)
        dockerImage="guzo/vim"
        ;;

    *)
        echo "Unsupported architecture: $machine"
        exit 1
        ;;
esac

dockerDir=`echo $PWD | sed 's|^/home/`whoami`|/home/ian|'`
docker run -ti --name vim --hostname vim --user ian -e "HOME=/home/ian" -e "TERM=xterm-256color" -v $PWD:$dockerDir -w $dockerDir $dockerImage vim $*
docker rm vim
