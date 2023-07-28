#!/bin/bash
: ${ENVIRONMENT:="dev"}
STACK_NAME="mlops-demo-gluetables"

# Reading config values
Environment=${ENVIRONMENT}
DataS3Bucket="mlops-insurance"
DriftReportPath=`cat monitor_config.json | jq -r '.DriftReportPath'`
DataDriftTable=`cat monitor_config.json | jq -r '.DataDriftTable'`
BaselineDataTable=`cat monitor_config.json | jq -r '.BaselineDataTable'`
BslineReportPath=`cat monitor_config.json | jq -r '.BslineReportPath'`
ScoringDataTable=`cat monitor_config.json | jq -r '.ScoringDataTable'`
InferReportPath=`cat monitor_config.json | jq -r '.InferReportPath'`
ScoreMonitorBridgeTable=`cat monitor_config.json | jq -r '.ScoreMonitorBridgeTable'`
Scoremonitorbridgepath=`cat monitor_config.json | jq -r '.Scoremonitorbridgepath'`
PredictReportPath=`cat monitor_config.json | jq -r '.PredictReportPath'`
PredictionDataTbl=`cat monitor_config.json | jq -r '.PredictionDataTbl'`
TrainRefPath=`cat monitor_config.json | jq -r '.TrainRefPath'`
trainrefdatatbl=`cat monitor_config.json | jq -r '.trainrefdatatbl'`

CFNBucket="mlops-insurance"

# Copying CFN template on to s3
#aws s3 cp AthenaDB-TableV1.yml s3://${CFNBucket}/cloudformation/ || true 
sleep 2 # Sleeping for few seconds to maintain s3 consistency
# Deploy cloudformation template
output=$(aws cloudformation deploy --stack-name $STACK_NAME \
--template-file AthenaDB-TableV1.yml \
--capabilities CAPABILITY_NAMED_IAM \
--parameter-overrides DataS3Bucket=$DataS3Bucket \
DriftReportPath=$DriftReportPath DataDriftTable=$DataDriftTable \
BslineReportPath=$BslineReportPath BaselineDataTable=$BaselineDataTable \
Scoremonitorbridgepath=$Scoremonitorbridgepath ScoreMonitorBridgeTable=$ScoreMonitorBridgeTable \
InferReportPath=$InferReportPath ScoringDataTable=$ScoringDataTable \
PredictReportPath=$PredictReportPath PredictionDataTbl=$PredictionDataTbl \
TrainRefPath=$TrainRefPath trainrefdatatbl=$trainrefdatatbl \
Environment=$Environment )

sleep 5 #
# Displaying results as per conditions
RESULT=$?

if [ $RESULT -eq 0 ]; then
  echo "$output"
else
  if [[ "$output" == *"No updates are to be performed"* ]]; then
    echo "No cloudformation updates are to be performed."
    exit 0
  else
    echo "$output"
    exit $RESULT
  fi
fi
