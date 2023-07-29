#!/bin/bash
: ${ENVIRONMENT:="dev"}
STACK_NAME="Wi-MLOPS-QVisuals"

# Reading config values
DataS3Bucket="wi-cred-datalake-${ENVIRONMENT}-raw"
TagTeam=`cat config/common-config.json | jq -r '.tag_team'`
TagProduct=`cat config/common-config.json | jq -r '.tag_product'`
TagTenant=`cat config/common-config.json | jq -r '.tag_tenant'`
RandomString='9XF2'
Environment=${ENVIRONMENT}
NotifierEmail=`cat config/${ENVIRONMENT}-specific-config.json | jq -r '.notifier_email'`
ConfigS3Bucket="wi-cred-datalake-"${ENVIRONMENT}"-s3-mlops-config"
CodeLocation=`cat config/QS-config.json | jq -r '.CodeLocation'`
CFNBucket="wi-cred-datalake-"${ENVIRONMENT}"-s3-mlops-cfn"
KMSKeyID=`cat config/${ENVIRONMENT}-specific-config.json | jq -r '.kms_key_id'`
# Copying CFN template on to s3
#aws s3 cp cloudformation/model_monitor_cfn.yml s3://${CFNBucket}/cloudformation/ || true 
#sleep 2 # Sleeping for few seconds to maintain s3 consistency

# Deploy cloudformation template
output=$(aws cloudformation deploy --stack-name $STACK_NAME \
--template-file cloudformation/qsdeployment.yml \
--s3-bucket ${CFNBucket} --force-upload --s3-prefix "cloudformation" \
--parameter-overrides ConfigS3Bucket=$ConfigS3Bucket \
DataS3Bucket=$DataS3Bucket CodeLocation=$CodeLocation \
KMSKeyID=$KMSKeyID \
TagTeam=$TagTeam TagProduct=$TagProduct TagTenant=$TagTenant \
RandomString=$RandomString Environment=$Environment NotifierEmail=$NotifierEmail --capabilities CAPABILITY_NAMED_IAM 2>&1)

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
