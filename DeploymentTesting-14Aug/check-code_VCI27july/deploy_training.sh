#!/bin/bash
#set -e
: ${ENVIRONMENT:="dev"}
STACK_NAME="wipuat-pricing-ml-training-pipeline"

## List of training parameters
PreProcessingInstanceType=`cat config/training-config.json | jq -r '.pre_processing_instance_type'`
DataS3BucketName="wi-cred-datalake-${ENVIRONMENT}-raw"
CFNBucket="wi-cred-datalake-"${ENVIRONMENT}"-s3-mlops-cfn"
ConfigBucket="wi-cred-datalake-"${ENVIRONMENT}"-s3-mlops-config"
TrainingInstanceType=`cat config/training-config.json | jq -r '.training_instance_type'`
InputS3Prefix=`cat config/training-config.json | jq -r '.input_s3_prefix'`
OutputS3Prefix=`cat config/training-config.json | jq  -r '.output_s3_prefix'`
Subnet1=`cat config/common-config.json | jq -r '.subnet1'`
Subnet2=`cat config/common-config.json | jq -r '.subnet2'`
Subnet3=`cat config/common-config.json | jq -r '.subnet3'`
SagemakerVPC=`cat config/common-config.json | jq -r '.sagemaker_vpc'`
KMSKeyID=`cat config/env-specific-config.json | jq -r '.DataKMSKeyId'`
ConfigKMSKeyId=`cat config/env-specific-config.json | jq -r '.ConfigKMSKeyId'`
ConfigKMSKey=`cat config/env-specific-config.json | jq -r '.ConfigKMSKey'`
Environment=${ENVIRONMENT}
TagTeam=`cat config/common-config.json | jq -r '.tag_team'`
TagProduct=`cat config/common-config.json | jq -r '.tag_product'`
TagTenant=`cat config/common-config.json | jq  -r '.tag_tenant'`
ReportS3Prefix=`cat config/training-config.json | jq -r '.report_s3_prefix'`
thresholdRMSE=`cat config/training-config.json | jq -r '.rmse_threshold'`
NotifierEmail=`cat config/env-specific-config.json | jq  -r '.notifier_email'`
CodeS3Prefix=`cat config/training-config.json | jq -r '.code_s3_prefix'`
XGPreprocessScript=`cat config/training-config.json | jq -r '.xgboost_preprocess_script'`
LRPreprocessScript=`cat config/training-config.json | jq  -r '.linear_learner_preprocess_script'`
PreProcessingContainer=`cat config/training-config.json | jq -r '.preprocessing_container'`
## List of XGBoost hyper parameters
XGmaxdepth=`cat train_hyperparameters/xg-parameter.json | jq -r '.max_depth'`
XGeta=`cat train_hyperparameters/xg-parameter.json | jq -r '.eta'`
XGgamma=`cat train_hyperparameters/xg-parameter.json | jq -r '.gamma'`
XGminchildweight=`cat train_hyperparameters/xg-parameter.json | jq -r '.min_child_weight'`
XGsubsample=`cat train_hyperparameters/xg-parameter.json | jq -r '.subsample'`
XGsilent=`cat train_hyperparameters/xg-parameter.json | jq -r '.silent'`
XGobjective=`cat train_hyperparameters/xg-parameter.json | jq -r '.objective'`
XGnumround=`cat train_hyperparameters/xg-parameter.json | jq -r '.num_round'`

## List of Linear Learner hyper parameters
lrepochs=`cat train_hyperparameters/lr-parameter.json | jq -r '.epochs'`
lrl1=`cat train_hyperparameters/lr-parameter.json | jq -r '.l1'`
lrlearningrate=`cat train_hyperparameters/lr-parameter.json | jq -r '.learning_rate'`
lrminibatchsize=`cat train_hyperparameters/lr-parameter.json | jq -r '.mini_batch_size'`
lrpredictortype=`cat train_hyperparameters/lr-parameter.json | jq -r '.predictor_type'`
RandomString='9XF2'


# Copying CFN template on to s3
aws s3 cp cloudformation//training_cfn.yml s3://${CFNBucket}/cloudformation/ || true 
sleep 2

# Deploy cloudformation template
output=$(aws cloudformation deploy --stack-name $STACK_NAME \
--template-file cloudformation/training_cfn.yml \
--s3-bucket ${CFNBucket} --force-upload --s3-prefix "cloudformation" \
--parameter-overrides PreProcessingInstanceType=$PreProcessingInstanceType DataS3BucketName=$DataS3BucketName TrainingInstanceType=$TrainingInstanceType \
InputS3Prefix=$InputS3Prefix OutputS3Prefix=$OutputS3Prefix \
CodeS3Prefix=$CodeS3Prefix \
Subnet1=$Subnet1 \
Subnet2=$Subnet2 Subnet3=$Subnet3 SagemakerVPC=$SagemakerVPC \
Environment=$Environment TagTeam=$TagTeam TagProduct=$TagProduct \
TagTenant=$TagTenant ReportS3Prefix=$ReportS3Prefix thresholdRMSE=$thresholdRMSE \
NotifierEmail=$NotifierEmail XGmaxdepth=$XGmaxdepth XGeta=$XGeta \
XGgamma=$XGgamma XGminchildweight=$XGminchildweight XGsubsample=$XGsubsample \
XGsilent=$XGsilent XGobjective=$XGobjective XGnumround=$XGnumround \
lrepochs=$lrepochs lrl1=$lrl1 lrlearningrate=$lrlearningrate \
lrminibatchsize=$lrminibatchsize lrpredictortype=$lrpredictortype \
RandomString=$RandomString ConfigS3BucketName=$ConfigBucket \
XGPreprocessScript=$XGPreprocessScript LRPreprocessScript=$LRPreprocessScript \
ConfigKMSKeyId=$ConfigKMSKeyId  \
ConfigKMSKey=$ConfigKMSKey  \
PreProcessingContainer=$PreProcessingContainer KMSKeyID=$KMSKeyID --capabilities CAPABILITY_NAMED_IAM 2>&1)

#sleep 5
# Copying Scripts and config files as an artifact on s3. Also it will trigger your pipeline on code changes
#aws s3 cp train_preprocessing/$XGPreprocessScript s3://$ConfigBucket/$CodeS3Prefix/xg/
#sleep 40
#aws s3 cp train_preprocessing/$LRPreprocessScript s3://$ConfigBucket/$CodeS3Prefix/lr/

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

export value1="1"
