#!/bin/sh

dockerDir=`echo $PWD | sed 's|^/home/docker|/home/ian|'`
docker run -ti --name vim --hostname vim --user ian -e "HOME=/home/ian" -e "TERM=xterm-256color" -v $PWD:$dockerDir -w $dockerDir guzo/vim vim $*
docker rm vim
