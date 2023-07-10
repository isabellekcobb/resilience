#!/bin/bash
#
# Generic python environment for OpenFIDO
#
TESTED=0
FAILED=0
FILES=

echo "$TESTED tests completed"
echo "$FAILED tests failed"
if [ $FAILED -gt 0 ]; then
    tar cfz autotest-errors.tar.gz $FILES
    echo "Failure artifacts saved to autotest-errors.tar.gz"
    exit 1
else
    echo "Success"
    exit 0
fi
