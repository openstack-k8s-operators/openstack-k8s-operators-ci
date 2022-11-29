#!/bin/bash
set -ex

GOWORK=${GOWORK:-'off'}
BASE_DIR="$(dirname $0)"
cd "${BASE_DIR}/../.."

export GOFLAGS="-mod=mod"

# Install golangci
curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | bash -x -s --

MODULE_DIR="."
if [ -n "$1" ]; then
  MODULE_DIR=$1
fi

TIMEOUT=5
if [ -n "$2" ] && [ "$2" -ge 1 ]; then
  TIMEOUT=$2
fi

pushd ${MODULE_DIR}

GOWORK=$GOWORK GOGC=10 GOLANGCI_LINT_CACHE=/tmp/golangci-cache ${BASE_DIR}/../../bin/golangci-lint run --timeout=${TIMEOUT}m -v
popd
