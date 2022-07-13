#!/bin/bash
set -ex

# Set to "" if lint errors should not fail the job (default golint behaviour)
# "-set_exit_status" otherwise
LINT_EXIT_STATUS="-set_exit_status"

BASE_DIR="$(dirname $0)"
cd "${BASE_DIR}/../.."

[ -d "vendor" ] && rm -rf vendor

# Get golint
go install golang.org/x/lint/golint

golint ${LINT_EXIT_STATUS} ./...
