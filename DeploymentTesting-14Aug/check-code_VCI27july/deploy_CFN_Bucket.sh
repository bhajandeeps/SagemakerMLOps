#!/bin/bash
: ${ENVIRONMENT:=$1}
STACK_NAME="wipuat-pricing-CFN-S3-Bucket"

# Reading config values
CFNS3BucketName="wi-cred-datalake-"${ENVIRONMENT}"-s3-mlops-cfn"
Environment=${ENVIRONMENT}
TagTeam=`cat config/common-config.json | jq -r '.tag_team'`
TagProduct=`cat config/common-config.json | jq -r '.tag_product'`
TagTenant=`cat config/common-config.json | jq -r '.tag_tenant'`
CFNKMSKeyId=`cat config/env-specific-config.json | jq -r '.CFNKMSKeyId'`

# Deploy cloudformation template
output=$(aws cloudformation deploy --stack-name $STACK_NAME \
--template-file cloudformation/CFNS3Bucket_cfn.yml \
--parameter-overrides CFNS3BucketName=$CFNS3BucketName  \
TagTeam=$TagTeam TagProduct=$TagProduct TagTenant=$TagTenant \
CFNKMSKeyId=$CFNKMSKeyId \
Environment=$Environment \
--capabilities CAPABILITY_NAMED_IAM 2>&1 )


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
