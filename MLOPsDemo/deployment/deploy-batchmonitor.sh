#!/bin/bash
: ${ENVIRONMENT:="dev"}
STACK_NAME="MLOPSdemo-ModelMonitor"

# Reading config values
PreProcessingInstanceType=`cat config/batchmonitor-config.json | jq -r '.preprocessing_instance_type'`
DataS3Bucket="mlops-insurance"
TagTeam=`cat config/common-config.json | jq -r '.tag_team'`
TagProduct=`cat config/common-config.json | jq -r '.tag_product'`
TagTenant=`cat config/common-config.json | jq -r '.tag_tenant'`
RandomString='9XF2'
Environment=${ENVIRONMENT}
NotifierEmail=`cat config/common-config.json | jq -r '.notifier_email'`
ConfigS3Bucket="mlops-insurance"
CodeLocation=`cat config/batchmonitor-config.json | jq -r '.CodeLocation'`
GlueS3Dest=`cat config/batchmonitor-config.json | jq -r '.GlueS3Dest'`
GlueS3Source=`cat config/batchmonitor-config.json | jq -r '.GlueS3Source'`
PrefixJsonlPath=`cat config/batchmonitor-config.json | jq -r '.PrefixJsonlPath'`
PrefixViolationPath=`cat config/batchmonitor-config.json | jq -r '.PrefixViolationPath'`
PrefixPostProcCodeXGB=`cat config/batchmonitor-config.json | jq -r '.PrefixPostProcCodeXGB'`
PrefixGlueCode=`cat config/batchmonitor-config.json | jq -r '.PrefixGlueCode'`
PrefixReportPath=`cat config/batchmonitor-config.json | jq -r '.PrefixReportPath'`
Schedulefreq=`cat config/batchmonitor-config.json | jq -r '.Schedulefreq'`
BaselineS3Prefix=`cat config/batchmonitor-config.json | jq -r '.BaselineS3Prefix'`
CFNBucket="mlops-insurance"
#KMSKeyID=`cat config/${ENVIRONMENT}-specific-config.json | jq -r '.kms_key_id'`
MDPrefixViolationPath=`cat config/batchmonitor-config.json | jq -r '.MDPrefixViolationPath'`
DriftReportPath=`cat config/batchmonitor-config.json | jq -r '.DriftReportPath'`
InferReportPath=`cat config/batchmonitor-config.json | jq -r '.InferReportPath'`
BslineReportPath=`cat config/batchmonitor-config.json | jq -r '.BslineReportPath'`
Scoremonitorbridgepath=`cat config/batchmonitor-config.json | jq -r '.Scoremonitorbridgepath'`
InpGroundTruth=`cat config/batchmonitor-config.json | jq -r '.InpGroundTruth'`
OpGroundTruth=`cat config/batchmonitor-config.json | jq -r '.OpGroundTruth'`
# Copying CFN template on to s3
aws s3 cp BatchMonit-cfnV1.yml s3://${CFNBucket}/cloudformation/ || true 
sleep 2 # Sleeping for few seconds to maintain s3 consistency
# Deploy cloudformation template
output=$(aws cloudformation deploy --stack-name $STACK_NAME \
--template-file BatchMonit-cfnV1.yml \
--s3-bucket ${CFNBucket} --force-upload --s3-prefix "cloudformation" \
--parameter-overrides PreProcessingInstanceType=$PreProcessingInstanceType ConfigS3Bucket=$ConfigS3Bucket \
DataS3Bucket=$DataS3Bucket CodeLocation=$CodeLocation PrefixPostProcCodeXGB=$PrefixPostProcCodeXGB \
BaselineS3Prefix=$BaselineS3Prefix PrefixGlueCode=$PrefixGlueCode \
DriftReportPath=$DriftReportPath InferReportPath=$InferReportPath \
BslineReportPath=$BslineReportPath \
InpGroundTruth=$InpGroundTruth OpGroundTruth=$OpGroundTruth \
Scoremonitorbridgepath=$Scoremonitorbridgepath MDPrefixViolationPath=$MDPrefixViolationPath \
ConfigS3Bucket=$ConfigS3Bucket PrefixViolationPath=$PrefixViolationPath PrefixReportPath=$PrefixReportPath \
GlueS3Dest=$GlueS3Dest GlueS3Source=$GlueS3Source PrefixJsonlPath=$PrefixJsonlPath \
TagTeam=$TagTeam TagProduct=$TagProduct TagTenant=$TagTenant \
RandomString=$RandomString Environment=$Environment NotifierEmail=$NotifierEmail --capabilities CAPABILITY_NAMED_IAM 2>&1)

sleep 5
# Copying Scripts and config files
#aws s3 cp monitor_preprocessing/$PrefixPostProcCodeLL s3://$DataS3Bucket/$CodeLocation/$PrefixPostProcCodeLL
aws s3 cp $PrefixPostProcCodeXGB s3://$DataS3Bucket/$CodeLocation/$PrefixPostProcCodeXGB
aws s3 cp $PrefixGlueCode s3://$DataS3Bucket/$CodeLocation/$PrefixGlueCode
#aws s3 cp monitor_preprocessing/$RTPrefixGlueCode s3://$DataS3Bucket/$CodeLocation/$RTPrefixGlueCode
#aws s3 cp monitor_preprocessing/$PrefixPostProcCode s3://$ConfigBucket/$CodeS3Prefix/lr/
#aws s3 cp LambdaLayer/smartopen.zip s3://${ConfigS3Bucket}/layers/ || true 

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
