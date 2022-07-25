#!/bin/bash
set -ex

# Set to "" if lint errors should not fail the job (default golint behaviour)
# "-set_exit_status" otherwise
LINT_EXIT_STATUS="-set_exit_status"

BASE_DIR="$(dirname $0)"
cd "${BASE_DIR}/../.."

MODULE_DIR="."
if [ -n "$1" ]; then
    MODULE_DIR=$1
fi

pushd ${MODULE_DIR}

export GOFLAGS="-mod=mod"

go get -u -d golang.org/x/lint/golint
go install golang.org/x/lint/golint

golint ${LINT_EXIT_STATUS} ./...
popd
