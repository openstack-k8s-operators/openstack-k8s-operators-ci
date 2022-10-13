#!/bin/bash
set -ex

BASE_DIR="$(dirname $0)"
cd "${BASE_DIR}/../.."

MODULE_DIR="."
if [ -n "$1" ]; then
    MODULE_DIR=$1
fi

pushd ${MODULE_DIR}
go test -mod=mod -v ./...
popd
