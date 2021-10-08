#!/bin/bash

declare -A OSBS_VARS
declare -A OSBS_VARS_DIR="$(dirname "$0")/osbs_dockerfile_vars"
declare -A OSBS_SCRIPT_DIR="osbs_dockerfile_template_scripts"
declare -A TEMPLATE_TAG_START="### DO NOT EDIT LINES BELOW"
declare -A TEMPLATE_TAG_END="### DO NOT EDIT LINES ABOVE"

###########

function backup_dockerfile() {
    echo "Creating backup file for: ${1}"
    cp ${1}{,.bak}
}

function get_available_operators() {
    # Available operators are determined by the list of .env files in the
    # folder that consists of all vars
    local basedir=$(dirname "$0")
    available_operators=$(basename -s .env ${basedir}/${OSBS_VARS_DIR}/*.env | grep -v default)
    echo "$available_operators"
}

function print_available_operators() {
    printf "\nAvailable operators:\n\n"
    printf "$(get_available_operators)\n"
}

function check_if_operator_exists() {
    local operator=$1
    [[ "$(get_available_operators)" =~ (^|[[:space:]])$operator($|[[:space:]]) ]]
    retval=$?
    if [ "$retval" == 0 ]; then
      return "$retval"
    else
      echo "OSBS operator name not found!"
      print_available_operators
      return "$retval"
    fi
}

function print_help() {
    printf "\nUsage: $0 [OPTION]... -f Dockerfile\n\n"
    printf "\tStartup:\n"
    printf "\t  -h\tprint this help\n"
    printf "\n\tOptions:\n"
    printf "\t  -b\tupstream operator branch\n"
    printf "\t  -n\tOSBS operator name\n"

    exit 2
}

### Options
OPTIND=1
while getopts "h?f:b:n:" option; do
    case "$option" in
    h|\?) print_help; exit 0;;
    f)    input_dockerfile=$OPTARG;;
    b)    operator_branch=$OPTARG;;
    n)    operator_name=$OPTARG;;
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

[ -z "$operator_name" ] && echo "ERROR: No name for the operator specified!" \
                        && print_available_operators \
                        && print_help

[ ! -f "$input_dockerfile" ] && echo "ERROR: file not found:"\
                                     "$input_dockerfile" \
                             && exit -1

check_if_operator_exists "$operator_name" || exit -1

backup_dockerfile $input_dockerfile

# Call to ensure functions to be overriden are defined
source "$(dirname "$0")/${OSBS_SCRIPT_DIR}/default.sh"

TEMPLATE_SH="$(dirname "$0")/${OSBS_SCRIPT_DIR}/${operator_name}.sh"

[ -f "$TEMPLATE_SH" ] && source "$TEMPLATE_SH"

pre_template $input_dockerfile

# For all Dockerfiles ensure they match the template
source "$(dirname "$0")/${OSBS_SCRIPT_DIR}/default.sh"

replace_labels_from_template "$input_dockerfile"

replace_ARG_values "$operator_name" "$input_dockerfile" "$operator_branch"

[ -f "$TEMPLATE_SH" ] && source "$TEMPLATE_SH"

post_template $input_dockerfile
