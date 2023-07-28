#!/bin/bash
: ${ENVIRONMENT:="dev"}
STACK_NAME="mlops-demo-gluetables"

# Reading config values
Environment=${ENVIRONMENT}
DataS3Bucket="ajay-vishwakarma-useast1"
DriftReportPath=`cat monitor_config.json | jq -r '.DriftReportPath'`
DataDriftTable=`cat monitor_config.json | jq -r '.DataDriftTable'`
BaselineDataTable=`cat monitor_config.json | jq -r '.BaselineDataTable'`
BslineReportPath=`cat monitor_config.json | jq -r '.BslineReportPath'`
CFNBucket="vw-cred-datalake-"${ENVIRONMENT}"-s3-mlops-cfn"

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
