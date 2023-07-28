#!/bin/bash


. ./deploy_training.sh


if [ "$value1" -eq "1" ];
then
    echo 'Completed running the first file and now second will begin'
    . ./deploy_batch_scoring.sh
    if [ "$value2" -eq "2" ];
    then
        echo "Second bash file ran successfully"
        echo " We will start running the third file"
        . ./deploy_real_time_Infer.sh
        if [ "$value3" -eq "3" ];
        then
            echo "Third script ran successfully"
        else
            echo "Third file has error in it."
        fi
    else
        echo "second bash file has error in it"
    fi
else
    echo "First bash file had error in it"
fi