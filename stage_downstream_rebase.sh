# Based on the stage_downstream_rebase.sh from dprince
#   https://github.com/openstack-k8s-operators/osp-director-operator/pull/397
#

BUNDLE_IMG_REGISTRY=${BUNDLE_IMG_REGISTRY:-"registry.redhat.io"}

# https://access.redhat.com/RegistryAuthentication
# https://access.redhat.com/terms-based-registry/#/token/OSPDirectorOperatorCI/info
BUNDLE_REGISTRY_TOKEN=${BUNDLE_REGISTRY_TOKEN:-""}
BUNDLE_REGISTRY_USERNAME=${BUNDLE_REGISTRY_USERNAME:-"6340056|OSPDirectorOperatorCI"}

# Mapping between upstream and downstream branches
declare -A upstream_to_downstream
declare -A upstream_to_downstream_img
# master branch
upstream_to_downstream[master]=rhos-17.0-rhel-8
upstream_to_downstream_img[master]=  # TBD We don't have yet one for master
# osp16_tech_preview branch
upstream_to_downstream[osp16_tech_preview]=rhos-16.2-rhel-8
upstream_to_downstream_img[osp16_tech_preview]="${BUNDLE_IMG_REGISTRY}/rhosp-rhel8-tech-preview/"

UPSTREAM_GIT_REPO="https://github.com/openstack-k8s-operators/osp-director-operator.git"

CODEENG_USER=${CODEENG_USER:-"rhos-jenkins"} # Required for downstream CI
DOWNSTREAM_GIT_REPO="ssh://${CODEENG_USER}@code.engineering.redhat.com/osp-director-operator"

function download_operator_sdk() {
    local SDK_TMP_DIR=${1}
    curl -L -o "${SDK_TMP_DIR}/osp-director-dev-tools-default.yaml" "https://raw.githubusercontent.com/openstack-k8s-operators/osp-director-dev-tools/master/ansible/vars/default.yaml"
    local OPERATOR_SDK_VERSION=$(grep "^sdk_version:" "${SDK_TMP_DIR}/osp-director-dev-tools-default.yaml" | awk -F' ' '{ print $2 }')
    echo "Downloading operator-sdk version: ${OPERATOR_SDK_VERSION}"
    curl -L -o "${SDK_TMP_DIR}/operator-sdk" \
        "https://github.com/operator-framework/operator-sdk/releases/download/${OPERATOR_SDK_VERSION}/operator-sdk_linux_amd64"
    chmod 755 "${SDK_TMP_DIR}/operator-sdk"
    OPERATOR_SDK="${SDK_TMP_DIR}/operator-sdk"
}

# Do check if the branch is specified in upstream_to_downstream variable 
function check_if_branch_exists() {
    if [ -z ${upstream_to_downstream[${1}]} ]; then
        echo "Upstream branch ${1} is not supported by this script !"
        echo "Supported branches:"
        printf "$(echo ${!upstream_to_downstream[@]} | tr " " "\n")\n"
        exit 2
    else
        echo "Using upstream branch: ${1}"
        echo "Using downstream branch: ${upstream_to_downstream[${1}]}"
    fi
}

function clone_git_repo() {
    local BASE_DIR=${1}
    local GIT_REPO=${2}
    local GIT_BRANCH=${3}
    echo "Cloning ${GIT_REPO} into: ${BASE_DIR}/"
    git clone --depth 1 -b "${GIT_BRANCH}" "${GIT_REPO}" "${BASE_DIR}/"
}

function create_downstream_commit_message() {
    local UPSTREAM_DIRECTORY=${1}
    local GIT_REPO=${2}
    local GIT_BRANCH=${3}
    local COMMIT_MSG_FILE=${4}

    pushd "${UPSTREAM_DIRECTORY}"
        UPSTREAM_COMMIT_MSG=$(git log -1)
        UPSTREAM_SHORT_MSG=$(git log --oneline --format='%h %s' -n 1 HEAD)
    popd

    cat <<EOF > "${COMMIT_MSG_FILE}"
Updated US source to: ${UPSTREAM_SHORT_MSG}

Updated upstream source commit.
Commit details follow:

Project: ${GIT_REPO}
Branch: ${GIT_BRANCH}
${UPSTREAM_COMMIT_MSG}
EOF
}

function modify_upstream_sources_file() {
    local UPSTREAM_DIRECTORY=${1}
    local DOWNSTREAM_DIRECTORY=${2}
    local GIT_REPO=${3}
    local GIT_BRANCH=${4}

    pushd "${UPSTREAM_DIRECTORY}"
        UPSTREAM_HASH=$(git rev-parse --verify HEAD)
    popd

    pushd "${DOWNSTREAM_DIRECTORY}"
        sed -i "/^- *branch:/c- branch: ${GIT_BRANCH}" upstream_sources.yml
        sed -i "/^ *commit:/c\\  commit: ${UPSTREAM_HASH}" upstream_sources.yml
        sed -i "/^ *url:/c\\  url: ${GIT_REPO}" upstream_sources.yml
    popd
}

# This should be more generic with better locations of the upsrteam
# Dockerfiles and it's naming
function translate_dockerfiles() {
    local UPSTREAM_DIRECTORY=${1}
    local DOWNSTREAM_DIRECTORY=${2}
    local GIT_BRANCH=${3}

    cp "${UPSTREAM_DIRECTORY}/Dockerfile" \
           "${DOWNSTREAM_DIRECTORY}/distgit/containers/osp-director-operator/Dockerfile.in"
    cp "${UPSTREAM_DIRECTORY}/Dockerfile.provision-ip-discovery-agent" \
           "${DOWNSTREAM_DIRECTORY}/distgit/containers/osp-director-provisioner/Dockerfile.in"
    cp "${UPSTREAM_DIRECTORY}/containers/image_downloader/Dockerfile" \
           "${DOWNSTREAM_DIRECTORY}/distgit/containers/osp-director-downloader/Dockerfile.in"


    ./dockerfile_to_osbs.sh -n osp-director-operator -b "${GIT_BRANCH}" -f  "${DOWNSTREAM_DIRECTORY}/distgit/containers/osp-director-operator/Dockerfile.in" || exit -1
    ./dockerfile_to_osbs.sh -n osp-director-provisioner -b "${GIT_BRANCH}" -f  "${DOWNSTREAM_DIRECTORY}/distgit/containers/osp-director-provisioner/Dockerfile.in" || exit -1
    ./dockerfile_to_osbs.sh -n osp-director-downloader -b "${GIT_BRANCH}" -f  "${DOWNSTREAM_DIRECTORY}/distgit/containers/osp-director-downloader/Dockerfile.in" || exit -1

}

function translate_bundle_dockerfile() {
    local UPSTREAM_DIRECTORY=${1}
    local DOWNSTREAM_DIRECTORY=${2}
    local GIT_BRANCH=${3}
    cp "${UPSTREAM_DIRECTORY}/bundle.Dockerfile" \
           "${DOWNSTREAM_DIRECTORY}/distgit/containers/osp-director-operator-bundle/Dockerfile.in"

    ./dockerfile_to_osbs.sh -n osp-director-operator-bundle -b "${GIT_BRANCH}" -f  "${DOWNSTREAM_DIRECTORY}/distgit/containers/osp-director-operator-bundle/Dockerfile.in" || exit -1
}

function get_current_operator_version() {
    local RELEASE_VERSION=${1}
    local GIT_BRANCH=${2}
    type podman > /dev/null || { echo "No podman CLI found in the PATH";  exit 2; }
    podman image search --help  | grep -q list-tags || { echo "podman CLI does not support 'image search --list-tags' option, please upgrade podman"; exit 2; }

    if ! podman login --get-login "$BUNDLE_IMG_REGISTRY" &> /dev/null; then
        if [ -z $BUNDLE_REGISTRY_TOKEN ]; then
            echo "Please run podman login ${BUNDLE_IMG_REGISTRY} before running this script."
            exit 1
        else
            podman login -u="${BUNDLE_REGISTRY_USERNAME}" -p="${BUNDLE_REGISTRY_TOKEN}" "${BUNDLE_IMG_REGISTRY}" &> /dev/null
            if ! podman login --get-login "$BUNDLE_IMG_REGISTRY" &> /dev/null; then
                echo "Could not log in to the podman registry: ${BUNDLE_IMG_REGISTRY}"
                exit 2
            fi
        fi
    fi
   # should end up looking like this OPERATOR_TAG="${RELEASE_VERSION}-1"
    OPERATOR_IMG="${upstream_to_downstream_img[$GIT_BRANCH]}osp-director-operator"
    OPERATOR_TAG=$(podman image search --list-tags ${OPERATOR_IMG} | grep $RELEASE_VERSION | sort | tail -1 | awk -F$RELEASE_VERSION '{print $2}') || exit 2
    BUILD_ID=$(echo $OPERATOR_TAG | sed -e "s|.*-||") || exit 2
    BUILD_ID_PLUS_1=$(($BUILD_ID + 1))
    echo "${RELEASE_VERSION}-${BUILD_ID_PLUS_1}"
}

function generate_new_bundle() {
    local UPSTREAM_DIRECTORY=${1}
    local GIT_BRANCH=${2}
    local RELEASE_VERSION=${3}

    OPERATOR_IMG="${upstream_to_downstream_img[$GIT_BRANCH]}osp-director-operator:${RELEASE_VERSION}"

    echo "Operator image: ${OPERATOR_IMG}"

    pushd "${UPSTREAM_DIRECTORY}"
        export PATH=${OPERATOR_SDK}:$PATH
        VERSION=$RELEASE_VERSION IMG=$OPERATOR_IMG make bundle
    popd
}

function copy_new_bundle() {
    local UPSTREAM_DIRECTORY=${1}
    local DOWNSTREAM_DIRECTORY=${2}
    # First we remove bundle from downstream repository
    local DOWNSTREAM_BUNDLE_DIR="${DOWNSTREAM_DIRECTORY}/distgit/containers/osp-director-operator-bundle/"
    pushd "${DOWNSTREAM_BUNDLE_DIR}"
        git rm -r bundle
        cp -a "${UPSTREAM_DIRECTORY}/bundle" .

        # HACKs for webhook deployment to work around: https://bugzilla.redhat.com/show_bug.cgi?id=1921000
        # TODO: Figure out how to do this via Kustomize so that it's automatically rolled into the make
        #       commands above
        sed -i '/^    webhookPath:.*/a #added\n    containerPort: 4343\n    targetPort: 4343' bundle/manifests/osp-director-operator.clusterserviceversion.yaml
        sed -i 's/deploymentName: webhook/deploymentName: osp-director-operator-controller-manager/g' bundle/manifests/osp-director-operator.clusterserviceversion.yaml
    popd
}

### Options
function print_help() {
    printf "\nUsage: $0 [OPTION]... -b BRANCH\n\n"
    printf "\tStartup:\n"
    printf "\t  -h\tprint this help\n"
    printf "\t  -b\tupstream operator branch\n"
    printf "\n\tOptions:\n"
    printf "\t  -u\tlocal upstream OSP Director Operator dir\n"
    printf "\t  -d\tlocal downstream OSP Director Operator dir\n"

    exit 2
}

OPTIND=1
while getopts "h?u:b:d:" option; do
    case "$option" in
    h|\?) print_help; exit 0;;
    b)    operator_branch=$OPTARG;;
    u)    upstream_local_dir=$OPTARG;;
    d)    downstream_local_dir=$OPTARG;;
    esac
done
[ "${1:-}" = "--" ] && shift

### Main script

if [ $(echo "${BASH_VERSION}" | cut -d . -f1) -lt 4 ]
then
    echo 'You should use bash 4 or newer for "declare -A" functionality'
    exit 2
fi

if [ -z "$operator_branch" ]; then
    if [ -z "$upstream_local_dir" ]; then
        echo "ERROR: upstream dir or upstream branch must be specified !"
        exit -1
    fi
    [ ! -d "$upstream_local_dir" ] && echo "ERROR: upstream dir not found:"\
                                     "$upstream_local_dir" \
                                     && exit -1

    pushd "$upstream_local_dir"
        # We try to get branch name from .pull_request_pipeline file, we need to ensure only one is specified there.
        TMP_BRANCH=$(cat .pull_request_pipeline | grep branch | grep -v *. | awk -F\' '{ print $2 }')
        if [ $(echo $TMP_BRANCH | wc -w) -eq 1 ]; then
           operator_branch="$TMP_BRANCH"
        fi
    popd
    if [ -z "$operator_branch" ]; then
        echo "ERROR: No upstream branch found!" 
        exit -1
    fi
fi

[ -z "$operator_branch" ] && echo "ERROR: No upstream branch specified!" \
                           && print_help

check_if_branch_exists "$operator_branch"

TMP_DIR=$(mktemp -d -t tmp.XXXXX_Operator_SDK)

#TBD: uncomment
download_operator_sdk ${TMP_DIR} && echo $OPERATOR_SDK

# Clone repositories if they were not passed as args
[ -z "$upstream_local_dir" ] && \
    clone_git_repo "${TMP_DIR}/osp-director-operator-upstream" \
                   "$UPSTREAM_GIT_REPO" "$operator_branch" && \
    upstream_local_dir="${TMP_DIR}/osp-director-operator-upstream"

# Downstream branch is calculated from upstream_to_downstream var
[ -z "$downstream_local_dir" ] && \
    clone_git_repo "${TMP_DIR}/osp-director-operator-downstream" \
                   "$DOWNSTREAM_GIT_REPO" \
                   "${upstream_to_downstream[$operator_branch]}" && \
    downstream_local_dir="${TMP_DIR}/osp-director-operator-downstream"

# Ensure git dirs exists, especially needed when the CLI argument was passed
[ ! -d "$upstream_local_dir" ] && echo "ERROR: upstream dir not found:"\
                                     "$upstream_local_dir" \
                             && exit -1

[ ! -d "$downstream_local_dir" ] && echo "ERROR: downstream dir not found:"\
                                     "$downstream_local_dir" \
                             && exit -1

create_downstream_commit_message "$upstream_local_dir" "$UPSTREAM_GIT_REPO" \
                                 "$operator_branch" \
                                 "${TMP_DIR}/commit_message.txt"

modify_upstream_sources_file "$upstream_local_dir" "$downstream_local_dir" \
                             "$UPSTREAM_GIT_REPO" "$operator_branch"

# First translate all the files except bundle. It's because we calculate
# version of the image from multiple files in the osbs_dockerfile_vars/
# directory and it's better to get the final version from calculated
# Dockerfile for the osp-director-operator image.
translate_dockerfiles "$upstream_local_dir" "$downstream_local_dir" "$operator_branch"

RELEASE_VERSION=$(grep IMAGE_VERSION "${downstream_local_dir}/distgit/containers/osp-director-operator/Dockerfile.in" | awk -F'=' '{ print $2 }'| tr -d \")

IMAGE_TAG=$(get_current_operator_version "$RELEASE_VERSION" "$operator_branch") || { echo "$IMAGE_TAG"; exit -1; }

generate_new_bundle "$upstream_local_dir" "$operator_branch" "$IMAGE_TAG"

copy_new_bundle "$upstream_local_dir" "$downstream_local_dir"

# It needs to be separate from translate_dockerfiles
translate_bundle_dockerfile "$upstream_local_dir" "$downstream_local_dir" "$operator_branch"

# Remove all backup copies left by translation script
find "$downstream_local_dir" -name "*.in.bak" -type f -delete
find "$downstream_local_dir" -name "*.inr" -type f -delete

# Commit changes using previously generated commit message
pushd "$downstream_local_dir"
    git add .
    git commit -a -F "${TMP_DIR}/commit_message.txt"
popd

echo "Temporary directory with operator-sdk, repos is at: ${TMP_DIR}"
echo "Your ready to git-review changes are in the: ${downstream_local_dir}"
