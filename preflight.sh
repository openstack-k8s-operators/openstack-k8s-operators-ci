#!/bin/bash

set -e

CHANGED_FILES=`git diff --name-only master...${TRAVIS_COMMIT}`
DOCKERFILE_CHANGED=False
DOCKERFILE=openstack-k8s-builder-toolbox

for CHANGED_FILE in $CHANGED_FILES; do
  if [[ $CHANGED_FILE == $DOCKERFILE ]]; then
    DOCKERFILE_CHANGED=TRUE
    break
  fi
done

if [[ $DOCKERFILE_CHANGED == False ]]; then
  echo "Dockerfile did not change, no build nessessary."
  travis_terminate 0
  exit 1
else
  echo "Dockerfile was changed, continuing with build."
fi
