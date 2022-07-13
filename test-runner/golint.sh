#!/bin/bash
set -ex

# Get golint
GO_VERSION=`go version | { read _ _ ver _; echo ${ver#go}; }`
if [ $(echo $GO_VERSION|awk -F. '{print $2}') -lt 14 ]; then
  go get -mod=readonly golang.org/x/lint/golint
else
  go get -u golang.org/x/lint/golint
fi

# Set to "" if lint errors should not fail the job (default golint behaviour)
# "-set_exit_status" otherwise
LINT_EXIT_STATUS="-set_exit_status"

BASE_DIR="$(dirname $0)"
cd "${BASE_DIR}/../.."

[ -d "vendor" ] && rm -rf vendor

golint ${LINT_EXIT_STATUS} ./...
