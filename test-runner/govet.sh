#!/bin/bash
set -ex

BASE_DIR="$(dirname $0)"
cd "${BASE_DIR}/../.."

[ -d "vendor" ] && rm -rf vendor

go vet ./...
