#!/bin/sh

# Copyright (c) 2018 Lars Kiesow <lkiesow@uos.de>
# https://github.com/lkiesow/automated-quay.io-deployment
# Licensed under the terms of the MIT License.
# See LICENSE for more details.

set -ue

payload="{
  \"commit\": \"${TRAVIS_COMMIT}\",
  \"ref\": \"refs/heads/${TRAVIS_BRANCH}\",
  \"default_branch\": \"${QUAY_DEFAULT_BRANCH:-master}\"
}"

# Fix webhook URL if necessary
QUAY_WEBHOOK_URL="$(echo "${QUAY_WEBHOOK_URL}" | sed "s_https://:_https://\$token:_")"

curl -H 'Content-Type: application/json' --data "${payload}" "${QUAY_WEBHOOK_URL}"
