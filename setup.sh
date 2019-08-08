#!/bin/bash

SCRIPTNAME=$(basename "$0")
runningLocally=false

__help() {

    if [[ "$1" != "" ]] ; then
        echo
        echo "    ERROR"
        echo
        echo "    $*"
    fi

    cat <<-ENDOFHELP

    Syntax: $SCRIPTNAME [ local ]

    NOTES

    This setup script generally needs to be run as root (to install some files
    globally, e.g. to set the prompt), but can be run as 'local' if the word
    'local' is supplied as a parameter.

ENDOFHELP
}


__helpAndExit() {
    __help $*
    exit 1
}


# Handle parameters
while [ "$1" != "" ] ; do

    case "$1" in

        local)
            runningLocally=true
            ;;

        *)
            __helpAndExit "Unrecognised option: $1"
            ;;
    esac
    shift
done


__runningAsRoot() {
    if [[ `whoami` != "root" ]] ; then
        __helpAndExit "Either run as root (try typing sudo $SCRIPTNAME) or pass the 'local' parameter"
    fi
}


__checkUser() {
    if [[ $runningLocally == false ]] ; then
        __runningAsRoot
    fi
}

# If we're running on a VM on Windows, try to work out the windows user
__identifyWindowsUser() {
    if [[ -e /c/Users ]] ; then
        WINDOWS_USER="`ls -d /c/Users/[a-z]*/ | cut -d'/' -f4`"
    	WINDOWS_HOME="/c/Users/${WINDOWS_USER}"
    elif [[ -e /Folders ]] ; then
    	WINDOWS_HOME="/Folders"
    else
        WINDOWS_HOME="unknown"
    fi
}


__initCounter() {
    n=1
    max=$(grep '^__step ' "$0" | wc -l)
}


__initVariables() {
    DOCKER_SCRIPTS=$(dirname "$0")
    STAGE_BIN="/tmp/stage-bin"
    LOCAL_BIN="${HOME}/.bin"
    BIN="/usr/local/bin"
    REGISTRY_NAME="registry-local"
    RESOURCES="${DOCKER_SCRIPTS}/resources"
    CACHE="${DOCKER_SCRIPTS}/cache"
    VM_HOME="/home/docker"
    GENERIC_COMMAND="${DOCKER_SCRIPTS}/generic-command"
    __initCounter
}


__step() {
    echo "[${n}/${max}] $*"
    n=`expr $n + 1`
}


__setupUtilities() {

    # First we create scripts for dockerised commands
    mkdir -p ${STAGE_BIN}

    # Anything from our base image
    echo "tree,drill," | while read -d ',' cmd ; do
        "$GENERIC_COMMAND" $cmd guzo/base > ${STAGE_BIN}/$cmd
    done;

    # Commands which only have an x86 version
    echo "vim,perl,gcloud,vue,tig,zip," | while read -d ',' cmd ; do
        "$GENERIC_COMMAND" $cmd > ${STAGE_BIN}/$cmd
    done;

    # Commands which also have an ARM version
    echo "npm," | while read -d ',' cmd ; do
        "$GENERIC_COMMAND" $cmd x86_64=guzo/$cmd,armv7l=guzo/$cmd:rpi > ${STAGE_BIN}/$cmd
    done;

    # Special cases
    "$GENERIC_COMMAND" node x86_64=guzo/npm,armv7l=guzo/npm:rpi -p 3000:3000 > ${STAGE_BIN}/node
    "$GENERIC_COMMAND" go golang:alpine -e '"GOOS=$GOOS"' -e '"GOARCH=$GOARCH"' -p 3000:3000 > ${STAGE_BIN}/go
    "$GENERIC_COMMAND" tinygo tinygo/tinygo > ${STAGE_BIN}/tinygo
    "$GENERIC_COMMAND" ngrok guzo/ngrok -p 4040:4040 > ${STAGE_BIN}/ngrok
    "$GENERIC_COMMAND" lein guzo/leinjs -v /home/docker/.lein:/home/ian/.lein -v /run/m2:/home/ian/.m2 -p 3000:3000 > ${STAGE_BIN}/lein
    "$GENERIC_COMMAND" java java:alpine -p 3000:3000 > ${STAGE_BIN}/java
    "$GENERIC_COMMAND" mvn maven > ${STAGE_BIN}/mvn
    "$GENERIC_COMMAND" hugo x86_64=guzo/hugo,armv7l=guzo/hugo:rpi -p 8888:8888 > ${STAGE_BIN}/hugo
    "$GENERIC_COMMAND" npm guzo/npm -p 3000:3000 -v /run/node_dependencies:/usr/src/dependencies > ${STAGE_BIN}/npm
    "$GENERIC_COMMAND" task guzo/task -v ${VM_HOME}/task-data:/usr/src/data > ${STAGE_BIN}/task
    "$GENERIC_COMMAND" http guzo/httpie > ${STAGE_BIN}/http
    "$GENERIC_COMMAND" gpg guzo/gpg -v /run/gnupg:/home/ian/.gnupg -v /dev/urandom:/dev/random > ${STAGE_BIN}/gpg

    # Custom scripts
    cp "${DOCKER_SCRIPTS}/dot-server" ${STAGE_BIN}/dot
    cp "${DOCKER_SCRIPTS}/swagger" ${STAGE_BIN}/swagger

    # Temporary commands
    echo "docker run -ti -v ${WINDOWS_HOME}/Downloads/iplayer:/opt/iplayer guzo/iplayer get_iplayer --output /opt/iplayer/output --profile-dir /opt/iplayer/profile" '$*' > ${STAGE_BIN}/iplayer

    # Some docker utilities
    cp "${DOCKER_SCRIPTS}/docker-setup" ${STAGE_BIN}/docker-setup
    cp "${DOCKER_SCRIPTS}/docker-clean" ${STAGE_BIN}/docker-clean
    cp "${DOCKER_SCRIPTS}/docker-kill" ${STAGE_BIN}/docker-kill
    cp "${DOCKER_SCRIPTS}/docker-repo" ${STAGE_BIN}/docker-repo

    # Move commands from our staging area
    chmod +x ${STAGE_BIN}/*
    if [[ $runningLocally == true ]] ; then
        mkdir -p $LOCAL_BIN
        cp ${STAGE_BIN}/* ${LOCAL_BIN}
    else
        mkdir -p $BIN
        cp ${STAGE_BIN}/* ${BIN}

        # Alias in case a version of 'vim' is already earlier in the path
        if [[ -e ${BIN}/vimx ]] ; then
            rm ${BIN}/vimx
        fi
        ln -s ${BIN}/vim ${BIN}/vimx
    fi
    rm ${STAGE_BIN}/*
    rmdir ${STAGE_BIN}
}


__setupGlobalPath() {
    echo "export PATH=$PATH:$BIN" > /etc/profile.d/set-path.sh
    chmod +x /etc/profile.d/set-path.sh
}


__setupLocalPath() {
    if [[ ! -e $HOME/.profile || $(grep ${LOCAL_BIN} $HOME/.profile) == "" ]] ; then
        echo "export PATH=$PATH:$LOCAL_BIN" >> $HOME/.profile
    fi
}


__setupPath() {
    if [[ $runningLocally == true ]] ; then
        __setupLocalPath
    else
        __setupGlobalPath
    fi
}


__setupGlobalProfileFiles() {
    cp "${RESOURCES}/set-prompt.sh" /etc/profile.d/set-prompt.sh
    chmod +x /etc/profile.d/set-prompt.sh
    cp "${RESOURCES}/bind-clear-screen.sh" /etc/profile.d/bind-clear-screen.sh
    chmod +x /etc/profile.d/bind-clear-screen.sh
}



__setupLocalProfileFiles() {
    cp "${RESOURCES}/set-prompt.sh" ${LOCAL_BIN}/.set-prompt.sh
    cp "${RESOURCES}/set-prompt.sh" ${LOCAL_BIN}/.bind-clear-screen.sh
    if [[ ! -e $HOME/.profile || $(grep set-prompt.sh $HOME/.profile) == "" ]] ; then
        echo "source ${LOCAL_BIN}/.set-prompt.sh" >> $HOME/.profile
        echo "source ${LOCAL_BIN}/.bind-clear-screen.sh" >> $HOME/.profile
    fi
}


__setupProfileFiles() {
    if [[ $runningLocally == true ]] ; then
        __setupLocalProfileFiles
    else
        __setupGlobalProfileFiles
    fi
}


__installBash() {
    if [[ $runningLocally == false ]] ; then
        if [[ -e /usr/bin/tce && ! -e /usr/local/bin/bash ]] ; then
            sudo -u docker tce-load -wi bash.tcz
        fi
    fi
}


__createCacheDir () {
    if [[ ! -e "${CACHE}" ]] ; then
        mkdir "${CACHE}"
    fi
}


__installDockerCompose()  {
    __createCacheDir

    if [[ ! -e "${CACHE}/docker-compose" ]] ; then
        curl -Ls "https://github.com/docker/compose/releases/download/1.11.2/docker-compose-$(uname -s)-$(uname -m)" -o "${CACHE}/docker-compose"
    fi

    if [[ $runningLocally == true ]] ; then
        cp "${CACHE}/docker-compose" ${LOCAL_BIN}/docker-compose
        chmod +x ${LOCAL_BIN}/docker-compose
    else
        cp "${CACHE}/docker-compose" ${BIN}/docker-compose
        chmod +x ${BIN}/docker-compose
    fi
}


__installAwsCli () {
    __createCacheDir

    if [[ ! -e "${CACHE}/aws" ]] ; then
        curl -Ls "https://raw.githubusercontent.com/mesosphere/aws-cli/master/aws.sh" -o "${CACHE}/aws"
    fi

    if [[ $runningLocally == true ]] ; then
        cp "${CACHE}/aws" ${LOCAL_BIN}/aws
        chmod +x ${LOCAL_BIN}/aws
    else
        cp "${CACHE}/aws" ${BIN}/aws
        chmod +x ${BIN}/aws
    fi
}


__installWeaveworks()  {
    __createCacheDir

    if [[ ! -e "${CACHE}/scope" ]] ; then
        curl -L git.io/scope -o "${CACHE}/scope"
    fi

    if [[ $runningLocally == true ]] ; then
        cp "${CACHE}/scope" ${LOCAL_BIN}/scope
        chmod +x ${LOCAL_BIN}/scope
    else
        cp "${CACHE}/scope" ${BIN}/scope
        chmod +x ${BIN}/scope
    fi
}


__checkUser
__identifyWindowsUser
__initVariables

__step "Copying utility scripts"
__setupUtilities

__step "Adding bin to path"
__setupPath

__step "Setting up custom prompt"
__setupProfileFiles

__step "Installing bash"
__installBash

__step "Installing docker-compose"
__installDockerCompose

__step "Installing AWS cli client"
__installAwsCli

__step "Installing weaveworks scope"
__installWeaveworks

echo
echo "Now type: exec bash -l"
echo
