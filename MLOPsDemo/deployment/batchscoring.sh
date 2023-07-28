#!/bin/bash
#set -e
: ${ENVIRONMENT:="dev"}
STACK_NAME="mlops-demo-batchscoring"

# Reading config values
PreProcessingInstanceType=`cat batchscoring-config.json | jq -r '.preprocessing_instance_type'`
ScoringInstanceType=`cat batchscoring-config.json | jq -r '.scoring_instance_type'`
DataS3Bucket="mlops-insurance"
InputS3Prefix=`cat batchscoring-config.json | jq -r '.input_s3_prefix'`
OutputS3Prefix=`cat batchscoring-config.json | jq -r '.output_s3_prefix'`
TagTeam=`cat common-config.json | jq -r '.tag_team'`
TagProduct=`cat common-config.json | jq -r '.tag_product'`
TagTenant=`cat common-config.json | jq -r '.tag_tenant'`
RandomString='9XF2'
Environment=${ENVIRONMENT}
NotifierEmail=`cat common-config.json | jq -r '.notifier_email'`
ConfigBucket="mlops-insurance"
CodeS3Prefix=`cat batchscoring-config.json | jq -r '.code_s3_prefix'`
CFNBucket="mlops-insurance"
XGscoreprocessScript=`cat batchscoring-config.json | jq -r '.xgboost_score_preprocess_script'`


# Copying CFN template on to s3
aws s3 cp batchscoring.yml s3://${ConfigBucket}/cloudformation/ || true 
sleep 2 # Sleeping for few seconds to maintain s3 consistency

# Deploy cloudformation template
output=$(aws cloudformation deploy --stack-name $STACK_NAME \
--template-file batchscoring.yml \
--s3-bucket ${ConfigBucket} --force-upload --s3-prefix "cloudformation" \
--parameter-overrides PreProcessingInstanceType=$PreProcessingInstanceType ScoringInstanceType=$ScoringInstanceType ConfigS3Bucket=$ConfigS3Bucket \
DataS3Bucket=$DataS3Bucket InputS3Prefix=$InputS3Prefix OutputS3Prefix=$OutputS3Prefix \
CodeS3Prefix=$CodeS3Prefix \
ConfigS3Bucket=$ConfigBucket XGscoreprocessScript=$XGscoreprocessScript \
TagTeam=$TagTeam TagProduct=$TagProduct TagTenant=$TagTenant \
RandomString=$RandomString Environment=$Environment NotifierEmail=$NotifierEmail \
--capabilities CAPABILITY_NAMED_IAM 2>&1)

sleep 5
# Copying Scripts and config files
aws s3 cp $XGscoreprocessScript s3://$ConfigBucket/$CodeS3Prefix/xg/

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

export value2="2"

