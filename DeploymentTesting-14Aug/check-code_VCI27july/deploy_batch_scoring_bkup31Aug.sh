#!/bin/bash
: ${ENVIRONMENT:="dev"}
STACK_NAME="wiptest-pricing-inference-pipeline"

# Reading config values
PreProcessingInstanceType=`cat config/batch-scoring-config.json | jq '.preprocessing_instance_type'`
ScoringInstanceType=`cat config/batch-scoring-config.json | jq '.scoring_instance_type'`
DataS3Bucket="wi-cred-datalake-${ENVIRONMENT}-raw"
InputS3Prefix=`cat config/batch-scoring-config.json | jq '.input_s3_prefix'`
OutputS3Prefix=`cat config/batch-scoring-config.json | jq '.output_s3_prefix'`
Subnet1=`cat config/common-config.json | jq '.subnet1'`
Subnet2=`cat config/common-config.json | jq '.subnet2'`
Subnet3=`cat config/common-config.json | jq '.subnet3'`
TagTeam=`cat config/common-config.json | jq '.tag_team'`
TagProduct=`cat config/common-config.json | jq '.tag_product'`
TagTenant=`cat config/common-config.json | jq '.tag_tenant'`
RandomString='9XF2'
Environment=${ENVIRONMENT}
NotifierEmail=`cat config/env-specific-config.json | jq '.notifier_email'`
ConfigBucket="wi-cred-datalake-"${ENVIRONMENT}"-s3-mlops-config"
CodeS3Prefix=`cat config/batch-scoring-config.json | jq '.code_s3_prefix'`
CodeS3Prefix=${CodeS3Prefix:1:-1}
SecurityGroup=$(aws cloudformation list-exports --query "Exports[?Name==\`wiptest-pricing-ml-training-pipeline-SagemakerSecurityGroup\`].Value" --no-paginate --output text)
LRModelParam=$(aws cloudformation list-exports --query "Exports[?Name==\`wiptest-pricing-ml-training-pipeline-LRModelName\`].Value" --no-paginate --output text)
XGModelParam=$(aws cloudformation list-exports --query "Exports[?Name==\`wiptest-pricing-ml-training-pipeline-XGModelName\`].Value" --no-paginate --output text)
CFNBucket="wi-cred-datalake-"${ENVIRONMENT}"-s3-mlops-cfn"
KMSKeyID=`cat config/env-specific-config.json | jq '.kms_key_id'`
XGscoreprocessScript=`cat config/batch-scoring-config.json | jq '.xgboost_score_preprocess_script'`
XGscoreprocessScript=${XGscoreprocessScript:1:-1}
lrscoreprocessScript=`cat config/batch-scoring-config.json | jq '.lr_score_preprocess_script'`
lrscoreprocessScript=${lrscoreprocessScript:1:-1}

# Copying CFN template on to s3
aws s3 cp cloudformation/batch_scoring_cfn.yml s3://${CFNBucket}/cloudformation/ || true 
sleep 2 # Sleeping for few seconds to maintain s3 consistency

# Deploy cloudformation template
output=$(aws cloudformation update-stack --stack-name $STACK_NAME \
--template-url https://$CFNBucket.s3.amazonaws.com/cloudformation/batch_scoring_cfn.yml \
--parameters ParameterKey=PreProcessingInstanceType,ParameterValue=$PreProcessingInstanceType ParameterKey=ScoringInstanceType,ParameterValue=$ScoringInstanceType ParameterKey=ConfigS3Bucket,ParameterValue=$ConfigS3Bucket \
ParameterKey=DataS3Bucket,ParameterValue=$DataS3Bucket ParameterKey=InputS3Prefix,ParameterValue=$InputS3Prefix ParameterKey=OutputS3Prefix,ParameterValue=$OutputS3Prefix \
ParameterKey=CodeS3Prefix,ParameterValue=$CodeS3Prefix ParameterKey=KMSKeyID,ParameterValue=$KMSKeyID \
ParameterKey=ConfigS3Bucket,ParameterValue=$ConfigBucket  \
ParameterKey=XGscoreprocessScript,ParameterValue=$XGscoreprocessScript ParameterKey=lrscoreprocessScript,ParameterValue=$lrscoreprocessScript \
ParameterKey=Subnet1,ParameterValue=$Subnet1 ParameterKey=Subnet2,ParameterValue=$Subnet2 ParameterKey=Subnet3,ParameterValue=$Subnet3 \
ParameterKey=TagTeam,ParameterValue=$TagTeam ParameterKey=TagProduct,ParameterValue=$TagProduct ParameterKey=TagTenant,ParameterValue=$TagTenant \
ParameterKey=RandomString,ParameterValue=$RandomString ParameterKey=Environment,ParameterValue=$Environment ParameterKey=NotifierEmail,ParameterValue=$NotifierEmail \
ParameterKey=SecurityGroup,ParameterValue=$SecurityGroup ParameterKey=LRModelParam,ParameterValue=$LRModelParam ParameterKey=XGModelParam,ParameterValue=$XGModelParam \
--capabilities CAPABILITY_NAMED_IAM 2>&1 || \
aws cloudformation create-stack --stack-name $STACK_NAME --template-url https://$CFNBucket.s3.amazonaws.com/cloudformation/batch_scoring_cfn.yml \
--parameters ParameterKey=PreProcessingInstanceType,ParameterValue=$PreProcessingInstanceType ParameterKey=ScoringInstanceType,ParameterValue=$ScoringInstanceType ParameterKey=ConfigS3Bucket,ParameterValue=$ConfigS3Bucket \
ParameterKey=DataS3Bucket,ParameterValue=$DataS3Bucket ParameterKey=InputS3Prefix,ParameterValue=$InputS3Prefix ParameterKey=OutputS3Prefix,ParameterValue=$OutputS3Prefix \
ParameterKey=ConfigS3Bucket,ParameterValue=$ConfigBucket  \
ParameterKey=CodeS3Prefix,ParameterValue=$CodeS3Prefix ParameterKey=KMSKeyID,ParameterValue=$KMSKeyID \
ParameterKey=XGscoreprocessScript,ParameterValue=$XGscoreprocessScript ParameterKey=lrscoreprocessScript,ParameterValue=$lrscoreprocessScript \
ParameterKey=Subnet1,ParameterValue=$Subnet1 ParameterKey=Subnet2,ParameterValue=$Subnet2 ParameterKey=Subnet3,ParameterValue=$Subnet3 \
ParameterKey=TagTeam,ParameterValue=$TagTeam ParameterKey=TagProduct,ParameterValue=$TagProduct ParameterKey=TagTenant,ParameterValue=$TagTenant \
ParameterKey=RandomString,ParameterValue=$RandomString ParameterKey=Environment,ParameterValue=$Environment ParameterKey=NotifierEmail,ParameterValue=$NotifierEmail \
ParameterKey=SecurityGroup,ParameterValue=$SecurityGroup ParameterKey=LRModelParam,ParameterValue=$LRModelParam ParameterKey=XGModelParam,ParameterValue=$XGModelParam \
--capabilities CAPABILITY_NAMED_IAM 2>&1)

sleep 30
# Copying Scripts and config files
aws s3 cp score_preprocessing/$XGscoreprocessScript s3://$ConfigBucket/$CodeS3Prefix/xg/
aws s3 cp score_preprocessing/$lrscoreprocessScript s3://$ConfigBucket/$CodeS3Prefix/lr/

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
