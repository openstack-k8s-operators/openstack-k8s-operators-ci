#!/bin/bash
set -ex

BASE_DIR="$(dirname $0)"
cd "${BASE_DIR}/../.."

# Install golangci
curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s --

go mod vendor

./bin/golangci-lint run -v
