#!/bin/bash
#
# Generic python environment for OpenFIDO
#
TESTED=0
FAILED=0
FILES=

for OPENFIDO_INPUT in $(find $PWD/autotest -name 'input_*' -print); do
        echo "Processing $OPENFIDO_INPUT..."
        export OPENFIDO_INPUT
        export OPENFIDO_OUTPUT=${OPENFIDO_INPUT/autotest\/input_/autotest\/output_}
        mkdir -p $OPENFIDO_OUTPUT
        rm -rf $OPENFIDO_OUTPUT/{*,.??*}
        if ! bash < openfido.sh 1>$OPENFIDO_OUTPUT/stdout 2>$OPENFIDO_OUTPUT/stderr; then
        FAILED=$(($FAILED+1)) 
        FILES="$FILES ${OPENFIDO_OUTPUT/$PWD\//}"
        echo "ERROR: $OPENFIDO_INPUT test failed"
        fi
        TESTED=$(($TESTED+1))
    done
    
echo "$TESTED tests completed"
echo "$FAILED tests failed"
if [ $FAILED -gt 0 ]; then
    tar cf autotest-errors.tar $FILES
    echo "Failure artifacts saved to autotest-errors.tar"
    exit 1
else
    echo "Success"
    exit 0
fi
