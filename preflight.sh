#!/bin/bash

set -e

DOCKERFILE=openstack-k8s-builder-toolbox
DOCKERFILE_CHANGED=False
echo "Comparing: $TRAVIS_COMMIT_RANGE"
CHANGED_FILES=`git diff --name-only $TRAVIS_COMMIT_RANGE`
echo "Detected the following changed files: $CHANGED_FILES"

for CHANGED_FILE in $CHANGED_FILES; do
  if [[ $CHANGED_FILE == $DOCKERFILE ]]; then
    DOCKERFILE_CHANGED=TRUE
    break
  fi
done

if [[ $DOCKERFILE_CHANGED == False ]]; then
  echo "Dockerfile did not change, no build nessessary."
  exit 1
else
  echo "Dockerfile was changed, continuing with build."
fi
