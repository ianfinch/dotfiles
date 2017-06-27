#!/bin/sh

if [[ `whoami` != "root" ]] ; then
    echo "Must be run as root (try typing sudo $0)"
    exit 1
fi

# Find out who we are
WINDOWS_USER="`ls -d /c/Users/[a-z]*/ | cut -d'/' -f4`"
echo
echo "Assuming windows user: ${WINDOWS_USER}"
echo

# Variables
DOCKER_SCRIPTS="`dirname $0`"
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
cp ${DOCKER_SCRIPTS}/vim ${BIN}/vim
ln -s ${BIN}/vim ${BIN}/vimx # Alias in case a version of 'vim' is already earlier in the path
cp ${DOCKER_SCRIPTS}/tree ${BIN}/tree
cp ${DOCKER_SCRIPTS}/lein ${BIN}/lein
cp ${DOCKER_SCRIPTS}/perl ${BIN}/perl
cp ${DOCKER_SCRIPTS}/drill ${BIN}/drill
cp ${DOCKER_SCRIPTS}/gcloud ${BIN}/gcloud
cp ${DOCKER_SCRIPTS}/hugo ${BIN}/hugo
cp ${DOCKER_SCRIPTS}/node ${BIN}/node
cp ${DOCKER_SCRIPTS}/npm ${BIN}/npm
cp ${DOCKER_SCRIPTS}/docker-clean ${BIN}/docker-clean
cp ${DOCKER_SCRIPTS}/docker-kill ${BIN}/docker-kill
cp ${DOCKER_SCRIPTS}/docker-repo ${BIN}/docker-repo

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

echo "[${n}/${max}] Starting local docker repository" ; n=`expr $n + 1`
if [[ "`docker ps --filter name=${REGISTRY_NAME} -q`" == "" ]] ; then
    docker run -d -p 5000:5000 --restart=always --name ${REGISTRY_NAME} registry:2
fi

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
echo "Now type: exec $SHELL -l"
echo
