#!/bin/bash
: ${ENVIRONMENT:="dev"}
STACK_NAME="wi-mlops-titanic-ml-score-piln"

# Reading config values
PreProcessingInstanceType=`cat config/batch-scoring-config.json | jq -r '.preprocessing_instance_type'`
ScoringInstanceType=`cat config/batch-scoring-config.json | jq -r '.scoring_instance_type'`
DataS3Bucket="wi-cred-datalake-${ENVIRONMENT}-raw"
InputS3Prefix=`cat config/batch-scoring-config.json | jq -r '.input_s3_prefix'`
OutputS3Prefix=`cat config/batch-scoring-config.json | jq -r '.output_s3_prefix'`
TagTeam=`cat config/common-config.json | jq -r '.tag_team'`
TagProduct=`cat config/common-config.json | jq -r '.tag_product'`
TagTenant=`cat config/common-config.json | jq -r '.tag_tenant'`
RandomString='9XF2'
Environment=${ENVIRONMENT}
NotifierEmail=`cat config/${ENVIRONMENT}-specific-config.json | jq -r '.notifier_email'`
ConfigBucket="wi-cred-datalake-"${ENVIRONMENT}"-s3-mlops-config"
CodeS3Prefix=`cat config/batch-scoring-config.json | jq -r '.code_s3_prefix'`
LRModelParam=$(aws cloudformation list-exports --query "Exports[?Name==\`wi-mlops-titanic-ml-train-piln-LRModelName\`].Value" --no-paginate --output text)
XGModelParam=$(aws cloudformation list-exports --query "Exports[?Name==\`wi-mlops-titanic-ml-train-piln-XGModelName\`].Value" --no-paginate --output text)
CFNBucket="wi-cred-datalake-"${ENVIRONMENT}"-s3-mlops-cfn"
KMSKeyID=`cat config/${ENVIRONMENT}-specific-config.json | jq -r '.kms_key_id'`
XGscoreprocessScript=`cat config/batch-scoring-config.json | jq -r '.xgboost_score_preprocess_script'`
lrscoreprocessScript=`cat config/batch-scoring-config.json | jq -r '.lr_score_preprocess_script'`
ProcessingS3Prefix=`cat config/batch-scoring-config.json | jq -r '.ProcessingS3Prefix'`

# Copying CFN template on to s3
aws s3 cp cloudformation/batch_scoring_cfn.yml s3://${CFNBucket}/cloudformation/ || true 
sleep 2 # Sleeping for few seconds to maintain s3 consistency

# Deploy cloudformation template
output=$(aws cloudformation deploy --stack-name $STACK_NAME \
--template-file cloudformation/batch_scoring_cfn.yml \
--s3-bucket ${CFNBucket} --force-upload --s3-prefix "cloudformation" \
--parameter-overrides PreProcessingInstanceType=$PreProcessingInstanceType ScoringInstanceType=$ScoringInstanceType ConfigS3Bucket=$ConfigS3Bucket \
DataS3Bucket=$DataS3Bucket InputS3Prefix=$InputS3Prefix OutputS3Prefix=$OutputS3Prefix \
CodeS3Prefix=$CodeS3Prefix KMSKeyID=$KMSKeyID \
ConfigS3Bucket=$ConfigBucket ProcessingS3Prefix=$ProcessingS3Prefix \
XGscoreprocessScript=$XGscoreprocessScript lrscoreprocessScript=$lrscoreprocessScript \
TagTeam=$TagTeam TagProduct=$TagProduct TagTenant=$TagTenant \
RandomString=$RandomString Environment=$Environment NotifierEmail=$NotifierEmail \
LRModelParam=$LRModelParam XGModelParam=$XGModelParam \
--capabilities CAPABILITY_NAMED_IAM 2>&1)

sleep 5
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
