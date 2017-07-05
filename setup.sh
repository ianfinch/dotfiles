#!/bin/bash

if [[ `whoami` != "root" ]] ; then
    echo "Must be run as root (try typing sudo $0)"
    exit 1
fi

# Find out who we are
if [[ -e /c/Users ]] ; then
    WINDOWS_USER="`ls -d /c/Users/[a-z]*/ | cut -d'/' -f4`"
else
    WINDOWS_USER="nobody"
fi
echo "Assuming windows user: ${WINDOWS_USER}"

# Variables
DOCKER_SCRIPTS="`dirname $0`"
STAGE_BIN="/tmp/stage-bin"
BIN="/usr/local/bin"
REGISTRY_NAME="registry-local"
RESOURCES="${DOCKER_SCRIPTS}/resources"
CACHE="${DOCKER_SCRIPTS}/cache"
WINDOWS_HOME="/c/Users/${WINDOWS_USER}"
VM_HOME="/home/docker"

# Count the steps
n=1
max=`grep expr $0 | wc -l`  # This introduces one more 'expr' line than we need
max=`expr ${max} - 2`       # So subtract from the total (+ the additional one this introduces)

echo "[${n}/${max}] Copying utility scripts" ; n=`expr $n + 1`

# First we create scripts for dockerised commands
mkdir -p ${STAGE_BIN}

# Anything from our base image
echo "tree,drill," | while read -d ',' cmd ; do
    ./generic-command $cmd guzo/base > ${STAGE_BIN}/$cmd
done;

# Commands which only have an x86 version
echo "vim,perl,gcloud," | while read -d ',' cmd ; do
    ./generic-command $cmd > ${STAGE_BIN}/$cmd
done;

# Commands which also have an ARM version
echo "hugo,npm," | while read -d ',' cmd ; do
    ./generic-command $cmd x86_64=guzo/$cmd,armv7l=guzo/$cmd:rpi > ${STAGE_BIN}/$cmd
done;

# Special cases
./generic-command node x86_64=guzo/npm,armv7l=guzo/npm:rpi > ${STAGE_BIN}/node
./generic-command lein clojure -v /run/lein:/root/.lein -v /run/m2:/root/.m2 -p 3000:3000 > ${STAGE_BIN}/lein
./generic-command mvn maven > ${STAGE_BIN}/mvn

# Some docker utilities
cp ${DOCKER_SCRIPTS}/docker-clean ${BIN}/docker-clean
cp ${DOCKER_SCRIPTS}/docker-kill ${BIN}/docker-kill
cp ${DOCKER_SCRIPTS}/docker-repo ${BIN}/docker-repo

# Move commands from our staging area
chmod +x ${STAGE_BIN}/*
cp ${STAGE_BIN}/* ${BIN}
rm ${STAGE_BIN}/*
rmdir ${STAGE_BIN}

# Alias in case a version of 'vim' is already earlier in the path
if [[ -e ${BIN}/vimx ]] ; then
    rm ${BIN}/vimx
fi
ln -s ${BIN}/vim ${BIN}/vimx

echo "[${n}/${max}] Adding bin to path" ; n=`expr $n + 1`
echo "export PATH=$PATH:$BIN" > /etc/profile.d/set-path.sh
chmod +x /etc/profile.d/set-path.sh

echo "[${n}/${max}] Setting up custom prompt" ; n=`expr $n + 1`
cp ${RESOURCES}/set-prompt.sh /etc/profile.d/set-prompt.sh
chmod +x /etc/profile.d/set-prompt.sh

echo "[${n}/${max}] Removing custom profile" ; n=`expr $n + 1`
if [[ -e /home/docker/.profile ]] ; then
    mv /home/docker/.profile /home/docker/.profile.bak
fi

echo "[${n}/${max}] Installing bash" ; n=`expr $n + 1`
if [[ -e /usr/bin/tce && ! -e /usr/local/bin/bash ]] ; then
    sudo -u docker tce-load -wi bash.tcz
fi

echo "[${n}/${max}] Installing docker-compose" ; n=`expr $n + 1`
if [[ ! -e ${CACHE} ]] ; then
    mkdir ${CACHE}
fi
if [[ ! -e ${CACHE}/docker-compose ]] ; then
    curl -Ls "https://github.com/docker/compose/releases/download/1.11.2/docker-compose-$(uname -s)-$(uname -m)" -o ${CACHE}/docker-compose
fi
cp ${CACHE}/docker-compose ${BIN}/docker-compose
chmod +x ${BIN}/docker-compose

echo "[${n}/${max}] Installing weaveworks kubernetes scope" ; n=`expr $n + 1`
if [[ ! -e ${CACHE}/scope ]] ; then
    curl -L git.io/scope -o ${CACHE}/scope
fi
cp ${CACHE}/scope ${BIN}/scope
chmod +x ${BIN}/scope

echo "[${n}/${max}] Setting up links to common directories" ; n=`expr $n + 1`
if [[ -e ${WINDOWS_HOME}/Documents && ! -e ${VM_HOME}/Documents ]] ; then
    ln -s ${WINDOWS_HOME}/Documents ${VM_HOME}/Documents
fi
if [[ -e ${WINDOWS_HOME}/Downloads && ! -e ${VM_HOME}/Downloads ]] ; then
    ln -s ${WINDOWS_HOME}/Downloads ${VM_HOME}/Downloads
fi
if [[ -e ${WINDOWS_HOME}/repositories && ! -e ${VM_HOME}/Repositories ]] ; then
    ln -s ${WINDOWS_HOME}/repositories ${VM_HOME}/Repositories
fi

echo
echo "Now type: exec bash -l"
echo
