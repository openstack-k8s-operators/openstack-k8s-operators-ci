#!/bin/bash
set -ex

GOWORK=${GOWORK:-'off'}
BASE_DIR="$(dirname $0)"
cd "${BASE_DIR}/../.."
mkdir -p ${PWD}/bin
ENVTEST="${PWD}/bin/setup-envtest"
ENVTEST_K8S_VERSION=$(grep "^ENVTEST_K8S_VERSION" Makefile | awk -F'?= ' '{ print $2 }')
test -s ${ENVTEST} || GOBIN=${PWD}/bin go install sigs.k8s.io/controller-runtime/tools/setup-envtest@latest

MODULE_DIR="."
if [ -n "$1" ]; then
    MODULE_DIR=$1
fi

pushd ${MODULE_DIR}
KUBEBUILDER_ASSETS="$(${ENVTEST} use ${ENVTEST_K8S_VERSION} -p path)" GOWORK=$GOWORK go test -mod=mod -v ./...
popd
