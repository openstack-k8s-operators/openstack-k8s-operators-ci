#!/bin/bash
set -ex

# Set to "" if lint errors should not fail the job (default golint behaviour)
# "-set_exit_status" otherwise
LINT_EXIT_STATUS="-set_exit_status"

GOWORK=${GOWORK:-'off'}
BASE_DIR="$(dirname $0)"
cd "${BASE_DIR}/../.."

MODULE_DIR="."
if [ -n "$1" ]; then
    MODULE_DIR=$1
fi

if ! command -v golint &> /dev/null; then
    LINT_INSTALL=$(mktemp -d)
    pushd "$LINT_INSTALL"
    go mod init example.com/lint
    go get -d golang.org/x/lint/golint
    go install golang.org/x/lint/golint
    popd
fi

pushd ${MODULE_DIR}
export GOFLAGS="-mod=mod"

GOWORK=$GOWORK golint ${LINT_EXIT_STATUS} ./...
popd
