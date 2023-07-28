#!/bin/bash
: ${ENVIRONMENT:="dev"}
STACK_NAME="wiptest-pricing-CFN-S3-Bucket"
# Reading config values
CFNS3BucketName="wi-cred-datalake-"${ENVIRONMENT}"-s3-mlops-cfn"
Environment=${ENVIRONMENT}
TagTeam=`cat config/common-config.json | jq '.tag_team'`
TagProduct=`cat config/common-config.json | jq '.tag_product'`
TagTenant=`cat config/common-config.json | jq '.tag_tenant'`


# Deploy cloudformation template
output=$(aws cloudformation update-stack --stack-name $STACK_NAME \
--template-body file://cloudformation/CFNS3Bucket_cfn.yml \
--parameters ParameterKey=CFNS3BucketName,ParameterValue=$CFNS3BucketName  \
ParameterKey=TagTeam,ParameterValue=$TagTeam ParameterKey=TagProduct,ParameterValue=$TagProduct ParameterKey=TagTenant,ParameterValue=$TagTenant \
ParameterKey=Environment,ParameterValue=$Environment \
--capabilities CAPABILITY_NAMED_IAM 2>&1 || \
aws cloudformation create-stack --stack-name $STACK_NAME --template-body file://cloudformation/CFNS3Bucket_cfn.yml \
--parameters ParameterKey=CFNS3BucketName,ParameterValue=$CFNS3BucketName  \
ParameterKey=TagTeam,ParameterValue=$TagTeam ParameterKey=TagProduct,ParameterValue=$TagProduct ParameterKey=TagTenant,ParameterValue=$TagTenant \
ParameterKey=Environment,ParameterValue=$Environment \
--capabilities CAPABILITY_NAMED_IAM 2>&1)


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
