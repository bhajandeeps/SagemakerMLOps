#!/bin/bash
: ${ENVIRONMENT:="dev"}
StackName="wipuat-pricing-real-time-monitor-pipeline"  #Name of stack we can change for experiments


PreProcessingInstanceType=`cat config/real-time-monitor.json | jq '.preprocessing_instance_type'`
ConfigBucket="wi-cred-datalake-"${ENVIRONMENT}"-s3-mlops-config"
ReportS3Prefix=`cat config/real-time-monitor.json | jq '.ActiveBaselineS3Prefix'`
CustombaselineS3Prefix=`cat config/real-time-monitor.json | jq '.CustombaselineS3Prefix'`
BaselineS3Bucket="wi-cred-datalake-"${ENVIRONMENT}"-s3-mlops-config"
#XGBoostEndPointName=$(aws cloudformation list-exports --query "Exports[?Name==\`mlops-off-lease-pricing-ml-training-pipeline-XGEndpointName\`].Value" --no-paginate --output text)
#LREndPointName=$(aws cloudformation list-exports --query "Exports[?Name==\`mlops-off-lease-pricing-ml-training-pipeline-LREndpointName\`].Value" --no-paginate --output text)
Subnet1=`cat config/common-config.json | jq '.subnet1'`
Subnet2=`cat config/common-config.json | jq '.subnet2'`
Subnet3=`cat config/common-config.json | jq '.subnet3'`
SecurityGroup=$(aws cloudformation list-exports --query "Exports[?Name==\`wipuat-pricing-ml-training-pipeline-SagemakerSecurityGroup\`].Value" --no-paginate --output text)
Environment=${ENVIRONMENT}
TagTeam=`cat config/common-config.json | jq '.tag_team'`
TagProduct=`cat config/common-config.json | jq '.tag_product'`
TagTenant=`cat config/common-config.json | jq '.tag_tenant'`
# ScheduleExpression=`cat config/${ENVIRONMENT}-real-time-monitor.json | jq '.ScheduleExpression'`
XGBoostEndPointName=`cat config/real-time-monitor.json | jq '.XGBoostEndPointName'`
LREndPointName=`cat config/real-time-monitor.json | jq '.LREndPointName'`
ConfigKMSKeyId=`cat config/env-specific-config.json | jq '.ConfigKMSKeyId'`
# Copying CFN template on to s3
CFNBucket="wi-cred-datalake-"${ENVIRONMENT}"-s3-mlops-cfn"

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
--parameter-overrides PreProcessingInstanceType=${PreProcessingInstanceType:1:-1} BaselineS3Bucket=$BaselineS3Bucket \
ReportS3Prefix=${ReportS3Prefix:1:-1} \
XGBoostEndPointName=${XGBoostEndPointName:1:-1} LREndPointName=${LREndPointName:1:-1} \
ConfigBucket=$ConfigBucket CustombaselineS3Prefix=${CustombaselineS3Prefix:1:-1} \
Subnet1=${Subnet1:1:-1} Subnet2=${Subnet2:1:-1} Subnet3=${Subnet3:1:-1} \
SecurityGroup=$SecurityGroup Environment=$Environment TagTeam=${TagTeam:1:-1} \
ConfigKMSKeyId=${ConfigKMSKeyId:1:-1}  \
TagProduct=${TagProduct:1:-1} TagTenant=${TagTenant:1:-1} \
--capabilities CAPABILITY_IAM 2>&1)

aws s3 cp config/real-time-monitor.json s3://${ConfigBucket}/rtmonitorconfig/ || true
aws s3 cp CustomBaseline/constraints.json s3://${ConfigBucket}/${CustombaselineS3Prefix:1:-1} || true
aws s3 cp CustomBaseline/statistics.json s3://${ConfigBucket}/${CustombaselineS3Prefix:1:-1} || true


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

