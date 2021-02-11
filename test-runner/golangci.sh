#!/bin/bash
set -ex

BASE_DIR="$(dirname $0)"
cd "${BASE_DIR}/../.."

# Install golangci
curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s --

go mod vendor

GOLANGCI_LINT_CACHE=/tmp/golangci-cache ./bin/golangci-lint run --timeout=2m -v
