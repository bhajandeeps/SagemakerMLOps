#!/bin/bash
: ${ENVIRONMENT:="dev"}
STACK_NAME="wi-mlops-titanic-ModelMonitor"

# Reading config values
PreProcessingInstanceType=`cat config/Monitor-config.json | jq -r '.preprocessing_instance_type'`
DataS3Bucket="wi-cred-datalake-${ENVIRONMENT}-raw"
TagTeam=`cat config/common-config.json | jq -r '.tag_team'`
TagProduct=`cat config/common-config.json | jq -r '.tag_product'`
TagTenant=`cat config/common-config.json | jq -r '.tag_tenant'`
RandomString='9XF2'
Environment=${ENVIRONMENT}
NotifierEmail=`cat config/${ENVIRONMENT}-specific-config.json | jq -r '.notifier_email'`
ConfigS3Bucket="wi-cred-datalake-"${ENVIRONMENT}"-s3-mlops-config"
CodeLocation=`cat config/Monitor-config.json | jq -r '.CodeLocation'`
#PrefixDriftLambda=`cat config/Monitor-config.json | jq -r '.PrefixDriftLambda'`
#PrefixEvalLambda=`cat config/Monitor-config.json | jq -r '.PrefixEvalLambda'`
GlueS3Dest=`cat config/Monitor-config.json | jq -r '.GlueS3Dest'`
GlueS3Source=`cat config/Monitor-config.json | jq -r '.GlueS3Source'`
PrefixJsonlPath=`cat config/Monitor-config.json | jq -r '.PrefixJsonlPath'`
ModelMonitor=`cat config/Monitor-config.json | jq -r '.ModelMonitor'`
PrefixViolationPath=`cat config/Monitor-config.json | jq -r '.PrefixViolationPath'`
PrefixPostProcCodeLL=`cat config/Monitor-config.json | jq -r '.PrefixPostProcCodeLL'`
PrefixPostProcCodeXGB=`cat config/Monitor-config.json | jq -r '.PrefixPostProcCodeXGB'`
PrefixGlueCode=`cat config/Monitor-config.json | jq -r '.PrefixGlueCode'`
PrefixReportPath=`cat config/Monitor-config.json | jq -r '.PrefixReportPath'`
DataDriftTable=`cat config/Monitor-config.json | jq -r '.DataDriftTable'`
Schedulefreq=`cat config/Monitor-config.json | jq -r '.Schedulefreq'`
BaselineS3Prefix=`cat config/Monitor-config.json | jq -r '.BaselineS3Prefix'`
CFNBucket="wi-cred-datalake-"${ENVIRONMENT}"-s3-mlops-cfn"
KMSKeyID=`cat config/${ENVIRONMENT}-specific-config.json | jq -r '.kms_key_id'`
RTGlueS3Dest=`cat config/Monitor-config.json | jq -r '.RTGlueS3Dest'`
RTGlueS3Source=`cat config/Monitor-config.json | jq -r '.RTGlueS3Source'`
RTPrefixJsonlPath=`cat config/Monitor-config.json | jq -r '.RTPrefixJsonlPath'`
MDPrefixViolationPath=`cat config/Monitor-config.json | jq -r '.MDPrefixViolationPath'`
RTPrefixGlueCode=`cat config/Monitor-config.json | jq -r '.RTPrefixGlueCode'`
RTPrefixReportPath=`cat config/Monitor-config.json | jq -r '.RTPrefixReportPath'`
DriftReportPath=`cat config/Monitor-config.json | jq -r '.DriftReportPath'`
RTReportPath=`cat config/Monitor-config.json | jq -r '.RTReportPath'`
InferReportPath=`cat config/Monitor-config.json | jq -r '.InferReportPath'`
ScoringDataTable=`cat config/Monitor-config.json | jq -r '.ScoringDataTable'`
BslineReportPath=`cat config/Monitor-config.json | jq -r '.BslineReportPath'`
BaselineDataTable=`cat config/Monitor-config.json | jq -r '.BaselineDataTable'`
ScoreMonitorBridgeTable=`cat config/Monitor-config.json | jq -r '.ScoreMonitorBridgeTable'`
Scoremonitorbridgepath=`cat config/Monitor-config.json | jq -r '.Scoremonitorbridgepath'`
InpGroundTruth=`cat config/Monitor-config.json | jq -r '.InpGroundTruth'`
OpGroundTruth=`cat config/Monitor-config.json | jq -r '.OpGroundTruth'`
# Copying CFN template on to s3
aws s3 cp cloudformation/model_monitor_cfn.yml s3://${CFNBucket}/cloudformation/ || true 
sleep 2 # Sleeping for few seconds to maintain s3 consistency
# Deploy cloudformation template
output=$(aws cloudformation deploy --stack-name $STACK_NAME \
--template-file cloudformation/model_monitor_cfn.yml \
--s3-bucket ${CFNBucket} --force-upload --s3-prefix "cloudformation" \
--parameter-overrides PreProcessingInstanceType=$PreProcessingInstanceType ConfigS3Bucket=$ConfigS3Bucket \
DataS3Bucket=$DataS3Bucket CodeLocation=$CodeLocation PrefixPostProcCodeXGB=$PrefixPostProcCodeXGB \
KMSKeyID=$KMSKeyID BaselineS3Prefix=$BaselineS3Prefix PrefixGlueCode=$PrefixGlueCode ScoringDataTable=$ScoringDataTable \
RTGlueS3Dest=$RTGlueS3Dest RTGlueS3Source=$RTGlueS3Source RTPrefixJsonlPath=$RTPrefixJsonlPath \
DriftReportPath=$DriftReportPath RTReportPath=$RTReportPath InferReportPath=$InferReportPath \
BslineReportPath=$BslineReportPath BaselineDataTable=$BaselineDataTable \
InpGroundTruth=$InpGroundTruth OpGroundTruth=$OpGroundTruth ModelMonitor=$ModelMonitor \
ScoreMonitorBridgeTable=$ScoreMonitorBridgeTable Scoremonitorbridgepath=$Scoremonitorbridgepath \
MDPrefixViolationPath=$MDPrefixViolationPath RTPrefixGlueCode=$RTPrefixGlueCode RTPrefixReportPath=$RTPrefixReportPath \
ConfigS3Bucket=$ConfigS3Bucket PrefixViolationPath=$PrefixViolationPath PrefixReportPath=$PrefixReportPath \
GlueS3Dest=$GlueS3Dest GlueS3Source=$GlueS3Source PrefixJsonlPath=$PrefixJsonlPath DataDriftTable=$DataDriftTable \
PrefixPostProcCodeLL=$PrefixPostProcCodeLL TagTeam=$TagTeam TagProduct=$TagProduct TagTenant=$TagTenant \
RandomString=$RandomString Environment=$Environment NotifierEmail=$NotifierEmail --capabilities CAPABILITY_NAMED_IAM 2>&1)

sleep 5
# Copying Scripts and config files
aws s3 cp monitor_preprocessing/$PrefixPostProcCodeLL s3://$DataS3Bucket/$CodeLocation/$PrefixPostProcCodeLL
aws s3 cp monitor_preprocessing/$PrefixPostProcCodeXGB s3://$DataS3Bucket/$CodeLocation/$PrefixPostProcCodeXGB
aws s3 cp monitor_preprocessing/$PrefixGlueCode s3://$DataS3Bucket/$CodeLocation/$PrefixGlueCode
aws s3 cp monitor_preprocessing/$RTPrefixGlueCode s3://$DataS3Bucket/$CodeLocation/$RTPrefixGlueCode
#aws s3 cp monitor_preprocessing/$PrefixPostProcCode s3://$ConfigBucket/$CodeS3Prefix/lr/
aws s3 cp LambdaLayer/smartopen.zip s3://${ConfigS3Bucket}/layers/ || true 

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
