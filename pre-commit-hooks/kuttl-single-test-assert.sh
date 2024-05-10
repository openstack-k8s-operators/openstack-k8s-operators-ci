#!/bin/bash
set -euxo pipefail

# Ensure that there are no assert files with more than one TestAssert
# as the extra TestAsserts are silently ignored by kuttl
KUTTL_DIR=${1:-"./test/kuttl"}
! egrep -c --include='*.y*ml' -R -e 'kind: TestAssert' "$KUTTL_DIR" \
        | grep -v ':0' | grep -v ':1'
ret=$?
if [ $ret -ne 0 ]; then
    echo Kuttl only executes the last TestAssert in an assert file.
    echo Combine the TestAsserts into a single one with a list of commands.
fi
exit $ret
