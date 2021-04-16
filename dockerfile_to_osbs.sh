#!/bin/bash

declare -A OSBS_VARS

###########
OSBS_VARS=(
    [GOLANG_BUILDER]=openshift/golang-builder:1.14
    [OPERATOR_BASE_IMAGE]=registry.redhat.io/ubi8/ubi-minimal:latest
    # unpacked_remote_sources is default by cachito
    [REMOTE_SOURCE]=unpacked_remote_sources
    [REMOTE_SOURCE_DIR]=/remote-source
    [REMOTE_SOURCE_SUBDIR]=app
    [DEST_ROOT]=/dest-root
    [GO_BUILD_EXTRA_ARGS]='"-mod readonly "'
    [IMAGE_DOWNLOADER_BASE]=ubi8:latest
    [PKG_CMD]=dnf
    [ENTRYPOINT_PATH]=app/containers/image_downloader/entrypoint.sh
)
###########

function backup_dockerfile() {
    echo "Creating backup file for: ${1}"
    cp ${1}{,.bak}
}

function inline_dockerfile_replace() {
    local dockerfile=$1
    local argname=$2
    local argvalue=$3

    if [ -z "$argvalue" ]
    then
        # Ensure ARG does not contain value
        echo "Unsetting argument: ${argname}"
        sed -i "/^ARG *${argname}[\n|=]/cARG ${argname}" ${dockerfile}
    else
        echo "Setting: ${argname}=${argvalue}"
        sed -i "/^ARG *${argname}[\n|=]/cARG ${argname}=${argvalue}" ${dockerfile}
    fi
}

function dockerfile_template() {
    local dockerfile=$1
    local -n args_dict=$2
    
    for argname in "${!args_dict[@]}"
    do
        inline_dockerfile_replace ${dockerfile} "$argname" "${args_dict[$argname]}"
    done
}

function print_help() {
    echo "Usage: $0 [-h|-?] [ -f Dockerfile ]"
    exit 2
}

### Options
OPTIND=1
while getopts "h?f:" option; do
    case "$option" in
    h|\?) print_help; exit 0;;
    f)    input_dockerfile=$OPTARG;;
    esac
done
[ "${1:-}" = "--" ] && shift

### Main script

if [ $(echo "${BASH_VERSION}" | cut -d . -f1) -lt 4 ]
then
    echo 'You should use bash 4 or newer for "declare -A" functionality'
    exit 2
fi

[ -z "$input_dockerfile" ] && echo "ERROR: No dockerfile specified!" \
                           && print_help

[ ! -f "$input_dockerfile" ] && echo "ERROR: file not found:"\
                                     "$input_dockerfile" \
                             && exit -1

backup_dockerfile $input_dockerfile
dockerfile_template $input_dockerfile OSBS_VARS
