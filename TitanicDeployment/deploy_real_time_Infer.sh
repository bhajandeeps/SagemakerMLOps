#!/bin/bash
: ${ENVIRONMENT:="dev"}
STACK_NAME="wi-mlops-titanic-rtInfer-piln"

# Reading tag values
Environment=${ENVIRONMENT}
TagTeam=`cat config/common-config.json | jq -r '.tag_team'`
TagProduct=`cat config/common-config.json | jq -r '.tag_product'`
TagTenant=`cat config/common-config.json | jq -r '.tag_tenant'`
ConfigBucket="wi-cred-datalake-"${ENVIRONMENT}"-s3-mlops-config"
# Finding parameter store name from export parameters
ModelEndPointXGBoost=$(aws cloudformation list-exports --query "Exports[?Name==\`wi-mlops-titanic-ml-train-piln-XGEndpointName\`].Value" --no-paginate --output text)
ModelEndPointLinearLearner=$(aws cloudformation list-exports --query "Exports[?Name==\`wi-mlops-titanic-ml-train-piln-LREndpointName\`].Value" --no-paginate --output text)
# Copying CFN template on to s3
CFNBucket="wi-cred-datalake-"${ENVIRONMENT}"-s3-mlops-cfn"
aws s3 cp cloudformation//real_time_Infer_cfn.yml s3://${CFNBucket}/cloudformation/ || true 
sleep 2 # Sleeping for few seconds to maintain s3 consistency
aws s3 cp LambdaLayer/sagemaker_lambda.zip s3://$ConfigBucket/layers/ || true 
sleep 10
# Deploy cloudformation template
# Deploy cloudformation template
output=$(aws cloudformation deploy --stack-name $STACK_NAME \
--template-file cloudformation/real_time_Infer_cfn.yml \
--parameter-overrides ModelEndPointXGBoost=$ModelEndPointXGBoost ModelEndPointLinearLearner=$ModelEndPointLinearLearner Environment=$Environment \
ConfigBucket=$ConfigBucket \
TagTeam=$TagTeam TagProduct=$TagProduct TagTenant=$TagTenant \
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
