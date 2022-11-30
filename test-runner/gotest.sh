#!/bin/bash
set -ex

GOWORK=${GOWORK:-'off'}
BASE_DIR="$(dirname $0)"
cd "${BASE_DIR}/../.."

MODULE_DIR="."
if [ -n "$1" ]; then
    MODULE_DIR=$1
fi

pushd ${MODULE_DIR}
GOWORK=$GOWORK go test -mod=mod -v ./...
popd
