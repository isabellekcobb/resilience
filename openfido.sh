#!/bin/sh
#
# GridLAB-D environment for OpenFIDO
#

TEMPLATE=anticipation

error()
{
    echo '*** ABNORMAL TERMINATION ***'
    echo 'See error Console Output stderr for details.'
    echo "See https://github.com/openfido/loadshape for help"
    exit 1
}

trap on_error 1 2 3 4 6 7 8 11 13 14 15

set -x # print commands
set -e # exit on error
set -u # nounset enabled

if [ ! -f "/usr/local/bin/gridlabd" ]; then
    echo "ERROR [openfido.sh]: '/usr/local/bin/gridlabd' not found" > /dev/stderr
    error
elif [ ! -f "$OPENFIDO_INPUT/config.csv" ]; then
    OPTIONS=$(cd $OPENFIDO_INPUT; ls -1 | tr '\n' ' ')
    if [ ! -z "$OPTIONS" ]; then
        echo "WARNING [openfido.sh]: '$OPENFIDO_INPUT/config.csv' not found, using all input files by default" > /dev/stderr
    else
        echo "ERROR [openfido.sh]: no input files"
        error
    fi
else
    OPTIONS=$(cd $OPENFIDO_INPUT ; cat config.csv | tr '\n' ' ')
fi

echo '*** INPUTS ***'
ls -l $OPENFIDO_INPUT

if [ -f template.rc ]; then
    TEMPLATE_CFG=$(cat template.cfg | tr '\n' ' ' )
else
    TEMPLATE_CFG=""
fi

cd $OPENFIDO_OUTPUT
cp -R $OPENFIDO_INPUT/* . #WHY?


# process config file
if [ -e "config.csv" ]; then
    ANALYSIS=$(grep ^ANALYSIS, "config.csv" | cut -f2- -d, | tr ',' ' ')
    POLE_DATA=$(grep ^POLE_DATA, "config.csv" | cut -f2- -d, | tr ',' ' ')
    USECASE=$(grep ^USECASE, "config.csv" | cut -f2- -d, | tr ',' ' ')
    POLE_NAME=$(grep ^POLE_NAME, "config.csv" | cut -f2- -d, | tr ',' ' ')
    echo "Config settings:"
    echo "  ANALYSIS = ${ANALYSIS:-pole_analysis}"
    echo "  POLE_DATA = ${POLE_DATA:-}"
else
    echo "No 'config.csv', using default settings:"
    echo "  ANALYSIS = *pole_analysis"
    echo "  POLE_DATA = "
fi

if [ "$ANALYSIS" = "vegetation_analysis" ]; then 
    echo "Running vegetation analysis, only."
    gridlabd geodata merge -D elevation $OPENFIDO_INPUT/$POLE_DATA -r 30 | gridlabd geodata merge -D vegetation >$OPENFIDO_OUTPUT/path_vege.csv
    python3 $OPENFIDO_INPUT/add_info.py # this needs to get integrated into the gridlabd source code
    gridlabd geodata merge -D powerline $OPENFIDO_OUTPUT/path_vege.csv --cable_type="TACSR/AC 610mm^2" >$OPENFIDO_OUTPUT/path_result.csv
elif [ "$ANALYSIS" = "pole_analysis" ]; then 
    CSV_NAME="poles_w_equip_and_network"
    GLM_NAME="network"
    USECASES=("loading_scenario" "critical_speed" "worst_angle")
    echo "Converting SPIDAcalc excel report to CSV"
    gridlabd convert $OPENFIDO_INPUT/$POLE_DATA $OPENFIDO_OUTPUT/$CSV_NAME.csv -f xls-spida -t csv-geodata extract_equipment=yes include_network=yes
    echo "Converting CSV to GLM"
    gridlabd -D csv_load_options="-f table -t object -M powerflow -o $OPENFIDO_OUTPUT/$CSV_NAME.glm" $OPENFIDO_OUTPUT/$CSV_NAME.csv
    echo "Pole analysis on GLM file"
    if [[ "$USECASE" = "all" ]]
        for option in "${USECASES[@]}"; do
            gridlabd pole_analysis $OPENFIDO_OUTPUT/$CSV_NAME.glm --analysis=$option --output=$OPENFIDO_OUTPUT/results-$option.csv
            # --poles_selected=POLENAME
    else
        gridlabd pole_analysis $OPENFIDO_OUTPUT/$CSV_NAME.glm --analysis=$USECASE --output=$OPENFIDO_OUTPUT/results-$USECASE.csv
        # --poles_selected=POLENAME
fi 

# ( gridlabd template $TEMPLATE_CFG get $TEMPLATE && gridlabd --redirect all $OPTIONS -t $TEMPLATE  ) || error

echo '*** OUTPUTS ***'
ls -l $OPENFIDO_OUTPUT

echo '*** RUN COMPLETE ***'
echo 'See Data Visualization and Artifacts for results.'

echo '*** END ***'
