#!/bin/bash
: ${ENVIRONMENT:="dev"}
STACK_NAME="wiptest-pricing-ml-training-pipeline"

## List of training parameters
PreProcessingInstanceType=`cat config/training-config.json | jq '.pre_processing_instance_type'`
DataS3BucketName="wi-cred-datalake-${ENVIRONMENT}-raw"
CFNBucket="wi-cred-datalake-"${ENVIRONMENT}"-s3-mlops-cfn"
ConfigBucket="wi-cred-datalake-"${ENVIRONMENT}"-s3-mlops-config"
TrainingInstanceType=`cat config/training-config.json | jq '.training_instance_type'`
InputS3Prefix=`cat config/training-config.json | jq '.input_s3_prefix'`
OutputS3Prefix=`cat config/training-config.json | jq '.output_s3_prefix'`
Subnet1=`cat config/common-config.json | jq '.subnet1'`
Subnet2=`cat config/common-config.json | jq '.subnet2'`
Subnet3=`cat config/common-config.json | jq '.subnet3'`
SagemakerVPC=`cat config/common-config.json | jq '.sagemaker_vpc'`
KMSKeyID=`cat config/env-specific-config.json | jq '.kms_key_id'`
Environment=${ENVIRONMENT}
TagTeam=`cat config/common-config.json | jq '.tag_team'`
TagProduct=`cat config/common-config.json | jq '.tag_product'`
TagTenant=`cat config/common-config.json | jq '.tag_tenant'`
ReportS3Prefix=`cat config/training-config.json | jq '.report_s3_prefix'`
thresholdRMSE=`cat config/training-config.json | jq '.rmse_threshold'`
NotifierEmail=`cat config/env-specific-config.json | jq '.notifier_email'`
CodeS3Prefix=`cat config/training-config.json | jq '.code_s3_prefix'`
CodeS3Prefix=${CodeS3Prefix:1:-1}
XGPreprocessScript=`cat config/training-config.json | jq '.xgboost_preprocess_script'`
XGPreprocessScript=${XGPreprocessScript:1:-1}
LRPreprocessScript=`cat config/training-config.json | jq '.linear_learner_preprocess_script'`
LRPreprocessScript=${LRPreprocessScript:1:-1}
PreProcessingContainer=`cat config/training-config.json | jq '.preprocessing_container'`
PreProcessingContainer=${PreProcessingContainer:1:-1}
## List of XGBoost hyper parameters
XGmaxdepth=`cat train_hyperparameters/xg-parameter.json | jq '.max_depth'`
XGeta=`cat train_hyperparameters/xg-parameter.json | jq '.eta'`
XGgamma=`cat train_hyperparameters/xg-parameter.json | jq '.gamma'`
XGminchildweight=`cat train_hyperparameters/xg-parameter.json | jq '.min_child_weight'`
XGsubsample=`cat train_hyperparameters/xg-parameter.json | jq '.subsample'`
XGsilent=`cat train_hyperparameters/xg-parameter.json | jq '.silent'`
XGobjective=`cat train_hyperparameters/xg-parameter.json | jq '.objective'`
XGnumround=`cat train_hyperparameters/xg-parameter.json | jq '.num_round'`

## List of Linear Learner hyper parameters
lrepochs=`cat train_hyperparameters/lr-parameter.json | jq '.epochs'`
lrl1=`cat train_hyperparameters/lr-parameter.json | jq '.l1'`
lrlearningrate=`cat train_hyperparameters/lr-parameter.json | jq '.learning_rate'`
lrminibatchsize=`cat train_hyperparameters/lr-parameter.json | jq '.mini_batch_size'`
lrpredictortype=`cat train_hyperparameters/lr-parameter.json | jq '.predictor_type'`
RandomString='9XF2'


# Copying CFN template on to s3
aws s3 cp cloudformation//training_cfn.yml s3://${CFNBucket}/cloudformation/ || true 
sleep 2

# Deploy cloudformation template
output=$(aws cloudformation update-stack --stack-name $STACK_NAME \
--template-url https://$CFNBucket.s3.amazonaws.com/cloudformation/training_cfn.yml \
--parameters ParameterKey=PreProcessingInstanceType,ParameterValue=$PreProcessingInstanceType ParameterKey=DataS3BucketName,ParameterValue=$DataS3BucketName ParameterKey=TrainingInstanceType,ParameterValue=$TrainingInstanceType \
ParameterKey=InputS3Prefix,ParameterValue=$InputS3Prefix ParameterKey=OutputS3Prefix,ParameterValue=$OutputS3Prefix \
ParameterKey=CodeS3Prefix,ParameterValue=$CodeS3Prefix \
ParameterKey=Subnet1,ParameterValue=$Subnet1 \
ParameterKey=Subnet2,ParameterValue=$Subnet2 ParameterKey=Subnet3,ParameterValue=$Subnet3 ParameterKey=SagemakerVPC,ParameterValue=$SagemakerVPC \
ParameterKey=Environment,ParameterValue=$Environment ParameterKey=TagTeam,ParameterValue=$TagTeam ParameterKey=TagProduct,ParameterValue=$TagProduct \
ParameterKey=TagTenant,ParameterValue=$TagTenant ParameterKey=ReportS3Prefix,ParameterValue=$ReportS3Prefix ParameterKey=thresholdRMSE,ParameterValue=$thresholdRMSE \
ParameterKey=NotifierEmail,ParameterValue=$NotifierEmail ParameterKey=XGmaxdepth,ParameterValue=$XGmaxdepth ParameterKey=XGeta,ParameterValue=$XGeta \
ParameterKey=XGgamma,ParameterValue=$XGgamma ParameterKey=XGminchildweight,ParameterValue=$XGminchildweight ParameterKey=XGsubsample,ParameterValue=$XGsubsample \
ParameterKey=XGsilent,ParameterValue=$XGsilent ParameterKey=XGobjective,ParameterValue=$XGobjective ParameterKey=XGnumround,ParameterValue=$XGnumround \
ParameterKey=lrepochs,ParameterValue=$lrepochs ParameterKey=lrl1,ParameterValue=$lrl1 ParameterKey=lrlearningrate,ParameterValue=$lrlearningrate \
ParameterKey=lrminibatchsize,ParameterValue=$lrminibatchsize ParameterKey=lrpredictortype,ParameterValue=$lrpredictortype \
ParameterKey=RandomString,ParameterValue=$RandomString ParameterKey=ConfigS3BucketName,ParameterValue=$ConfigBucket \
ParameterKey=XGPreprocessScript,ParameterValue=$XGPreprocessScript ParameterKey=LRPreprocessScript,ParameterValue=$LRPreprocessScript \
ParameterKey=PreProcessingContainer,ParameterValue=$PreProcessingContainer ParameterKey=KMSKeyID,ParameterValue=$KMSKeyID --capabilities CAPABILITY_NAMED_IAM 2>&1 || \
aws cloudformation create-stack --stack-name $STACK_NAME --template-url https://$CFNBucket.s3.amazonaws.com/cloudformation/training_cfn.yml \
--parameters ParameterKey=PreProcessingInstanceType,ParameterValue=$PreProcessingInstanceType ParameterKey=DataS3BucketName,ParameterValue=$DataS3BucketName ParameterKey=TrainingInstanceType,ParameterValue=$TrainingInstanceType \
ParameterKey=InputS3Prefix,ParameterValue=$InputS3Prefix ParameterKey=OutputS3Prefix,ParameterValue=$OutputS3Prefix \
ParameterKey=CodeS3Prefix,ParameterValue=$CodeS3Prefix \
ParameterKey=Subnet1,ParameterValue=$Subnet1 \
ParameterKey=Subnet2,ParameterValue=$Subnet2 ParameterKey=Subnet3,ParameterValue=$Subnet3 ParameterKey=SagemakerVPC,ParameterValue=$SagemakerVPC \
ParameterKey=Environment,ParameterValue=$Environment ParameterKey=TagTeam,ParameterValue=$TagTeam ParameterKey=TagProduct,ParameterValue=$TagProduct \
ParameterKey=TagTenant,ParameterValue=$TagTenant ParameterKey=ReportS3Prefix,ParameterValue=$ReportS3Prefix ParameterKey=thresholdRMSE,ParameterValue=$thresholdRMSE \
ParameterKey=NotifierEmail,ParameterValue=$NotifierEmail ParameterKey=XGmaxdepth,ParameterValue=$XGmaxdepth ParameterKey=XGeta,ParameterValue=$XGeta \
ParameterKey=XGgamma,ParameterValue=$XGgamma ParameterKey=XGminchildweight,ParameterValue=$XGminchildweight ParameterKey=XGsubsample,ParameterValue=$XGsubsample \
ParameterKey=XGsilent,ParameterValue=$XGsilent ParameterKey=XGobjective,ParameterValue=$XGobjective ParameterKey=XGnumround,ParameterValue=$XGnumround \
ParameterKey=lrepochs,ParameterValue=$lrepochs ParameterKey=lrl1,ParameterValue=$lrl1 ParameterKey=lrlearningrate,ParameterValue=$lrlearningrate \
ParameterKey=lrminibatchsize,ParameterValue=$lrminibatchsize ParameterKey=lrpredictortype,ParameterValue=$lrpredictortype ParameterKey=RandomString,ParameterValue=$RandomString ParameterKey=ConfigS3BucketName,ParameterValue=$ConfigBucket \
ParameterKey=XGPreprocessScript,ParameterValue=$XGPreprocessScript ParameterKey=LRPreprocessScript,ParameterValue=$LRPreprocessScript \
ParameterKey=PreProcessingContainer,ParameterValue=$PreProcessingContainer ParameterKey=KMSKeyID,ParameterValue=$KMSKeyID --capabilities CAPABILITY_NAMED_IAM 2>&1)

#sleep 70

# Copying Scripts and config files as an artifact on s3. Also it will trigger your pipeline on code changes
aws s3 cp train_preprocessing/$XGPreprocessScript s3://$ConfigBucket/$CodeS3Prefix/xg/
sleep 20
aws s3 cp train_preprocessing/$LRPreprocessScript s3://$ConfigBucket/$CodeS3Prefix/lr/
#aws s3 cp train_hyperparameters/${ENVIRONMENT}-xg-parameter.json s3://$ConfigBucket/param/trigger/xgboost/
#aws s3 cp train_hyperparameters/${ENVIRONMENT}-lr-parameter.json s3://$ConfigBucket/param/trigger/lr/
#sleep 10

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


