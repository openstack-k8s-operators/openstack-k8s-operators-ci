#!/bin/bash
set -ex

# Get golint
go install golang.org/x/lint/golint

# Set to "" if lint errors should not fail the job (default golint behaviour)
# "-set_exit_status" otherwise
LINT_EXIT_STATUS="-set_exit_status"

BASE_DIR="$(dirname $0)"
cd "${BASE_DIR}/../.."

[ -d "vendor" ] && rm -rf vendor

golint ${LINT_EXIT_STATUS} ./...
