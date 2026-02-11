#!/bin/bash

# Check if both parameters are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <CURRENT> <NEXT>"
    echo "Example: $0 fr3 fr4"
    exit 1
fi

set -ex

CURRENT=$1
NEXT=$2

for X in $(find . -name .git -prune -o -type f -print | grep 18.0-fr); do
    #rename the file (NOTE: prow jobs require frX in the name)
    NEW_FILE=$(echo $X | sed -e "s|$CURRENT|$NEXT|")
    git mv $X $NEW_FILE

    #switch the branch
    sed -i $NEW_FILE -e "s|$CURRENT|$NEXT|"
done
export CONTAINER_ENGINE=podman
make jobs
make ci-operator-config
