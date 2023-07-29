#!/bin/bash
: ${ENVIRONMENT:="dev"}
StackName="wi-mlops-lease-pric-rl-monitor-piln"  #Name of stack we can change for experiments


PreProcessingInstanceType=`cat config/real-time-monitor.json | jq -r '.preprocessing_instance_type'`
ConfigBucket="wi-cred-datalake-"${ENVIRONMENT}"-s3-mlops-config"
ReportS3Prefix=`cat config/real-time-monitor.json | jq -r '.ActiveBaselineS3Prefix'`
CustombaselineS3Prefix=`cat config/real-time-monitor.json | jq -r '.CustombaselineS3Prefix'`
BaselineS3Bucket="wi-cred-datalake-"${ENVIRONMENT}"-s3-mlops-config"
#XGBoostEndPointName=$(aws cloudformation list-exports --query "Exports[?Name==\`mlops-off-lease-pricing-ml-training-pipeline-XGEndpointName\`].Value" --no-paginate --output text)
#LREndPointName=$(aws cloudformation list-exports --query "Exports[?Name==\`mlops-off-lease-pricing-ml-training-pipeline-LREndpointName\`].Value" --no-paginate --output text)
Environment=${ENVIRONMENT}
TagTeam=`cat config/common-config.json | jq -r '.tag_team'`
TagProduct=`cat config/common-config.json | jq -r '.tag_product'`
TagTenant=`cat config/common-config.json | jq -r '.tag_tenant'`
# ScheduleExpression=`cat config/${ENVIRONMENT}-real-time-monitor.json | jq '.ScheduleExpression'`
XGBoostEndPointName=`cat config/real-time-monitor.json | jq -r '.XGBoostEndPointName'`
LREndPointName=`cat config/real-time-monitor.json | jq -r '.LREndPointName'`

# Copying CFN template on to s3
CFNBucket="vw-cred-datalake-"${ENVIRONMENT}"-s3-mlops-cfn"

aws s3 cp cloudformation/monitor_real_time_cfn.yml s3://${CFNBucket}/cloudformation/ || true 
#aws s3 cp config/real-time-monitor.json s3://${ConfigBucket}/rtmonitorconfig/ || true 
# sleep 2 # Sleeping for few seconds to maintain s3 consistency

# Fetching endpoint name
# XGBoostEndPointName=`aws ssm get-parameters --names ${XGBoostEndPointName} --query "Parameters[0].Value"`
# LREndPointName=`aws ssm get-parameters --names ${LREndPointName} --query "Parameters[0].Value"`
# ScheduleExpression=$(echo $ScheduleExpression | sed  -e "s/\"/'/g")
# echo $ScheduleExpression





output=$(aws cloudformation deploy --stack-name $StackName \
--template-file cloudformation/monitor_real_time_cfn.yml \
--parameter-overrides PreProcessingInstanceType=$PreProcessingInstanceType BaselineS3Bucket=$BaselineS3Bucket \
ReportS3Prefix=$ReportS3Prefix \
XGBoostEndPointName=$XGBoostEndPointName LREndPointName=$LREndPointName \
ConfigBucket=$ConfigBucket CustombaselineS3Prefix=$CustombaselineS3Prefix \
Environment=$Environment TagTeam=$TagTeam \
TagProduct=$TagProduct TagTenant=$TagTenant \
--capabilities CAPABILITY_IAM 2>&1)

aws s3 cp config/real-time-monitor.json s3://${ConfigBucket}/rtmonitorconfig/ || true
aws s3 cp CustomBaseline/constraints.json s3://${ConfigBucket}/${CustombaselineS3Prefix} || true
aws s3 cp CustomBaseline/statistics.json s3://${ConfigBucket}/${CustombaselineS3Prefix} || true

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