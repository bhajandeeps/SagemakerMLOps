#!/bin/bash
: ${ENVIRONMENT:="dev"}
StackName="wipuat-pricing-real-time-monitor-pipeline"  #Name of stack we can change for experiments


PreProcessingInstanceType=`cat config/real-time-monitor.json | jq '.preprocessing_instance_type'`
ConfigBucket="wi-cred-datalake-"${ENVIRONMENT}"-s3-mlops-config"
ReportS3Prefix=`cat config/real-time-monitor.json | jq '.BaselineReportS3Prefix'`
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

# Copying CFN template on to s3
CFNBucket="wi-cred-datalake-"${ENVIRONMENT}"-s3-mlops-cfn"

# sleep 2 # Sleeping for few seconds to maintain s3 consistency

aws s3 cp cloudformation/monitor_real_time_cfn.yml s3://${CFNBucket}/cloudformation/ || true 
# Fetching endpoint name
# XGBoostEndPointName=`aws ssm get-parameters --names ${XGBoostEndPointName} --query "Parameters[0].Value"`
# LREndPointName=`aws ssm get-parameters --names ${LREndPointName} --query "Parameters[0].Value"`
# ScheduleExpression=$(echo $ScheduleExpression | sed  -e "s/\"/'/g")
# echo $ScheduleExpression



output=$(aws cloudformation update-stack --stack-name $StackName \
--template-url https://$CFNBucket.s3.amazonaws.com/cloudformation/monitor_real_time_cfn.yml \
--parameters ParameterKey=PreProcessingInstanceType,ParameterValue=$PreProcessingInstanceType ParameterKey=BaselineS3Bucket,ParameterValue=$BaselineS3Bucket ParameterKey=ReportS3Prefix,ParameterValue=$ReportS3Prefix \
ParameterKey=XGBoostEndPointName,ParameterValue=$XGBoostEndPointName ParameterKey=LREndPointName,ParameterValue=$LREndPointName \
ParameterKey=ConfigBucket,ParameterValue=$ConfigBucket \
ParameterKey=Subnet1,ParameterValue=$Subnet1 ParameterKey=Subnet2,ParameterValue=$Subnet2 ParameterKey=Subnet3,ParameterValue=$Subnet3 \
ParameterKey=SecurityGroup,ParameterValue=$SecurityGroup ParameterKey=Environment,ParameterValue=$Environment ParameterKey=TagTeam,ParameterValue=$TagTeam \
ParameterKey=TagProduct,ParameterValue=$TagProduct ParameterKey=TagTenant,ParameterValue=$TagTenant \
--capabilities CAPABILITY_IAM 2>&1 || \
aws cloudformation create-stack --stack-name $StackName --template-body file://cloudformation/monitor_real_time_cfn.yml \
--parameters ParameterKey=PreProcessingInstanceType,ParameterValue=$PreProcessingInstanceType ParameterKey=BaselineS3Bucket,ParameterValue=$BaselineS3Bucket ParameterKey=ReportS3Prefix,ParameterValue=$ReportS3Prefix \
ParameterKey=XGBoostEndPointName,ParameterValue=$XGBoostEndPointName ParameterKey=LREndPointName,ParameterValue=$LREndPointName \
ParameterKey=ConfigBucket,ParameterValue=$ConfigBucket \
ParameterKey=Subnet1,ParameterValue=$Subnet1 ParameterKey=Subnet2,ParameterValue=$Subnet2 ParameterKey=Subnet3,ParameterValue=$Subnet3 \
ParameterKey=SecurityGroup,ParameterValue=$SecurityGroup ParameterKey=Environment,ParameterValue=$Environment ParameterKey=TagTeam,ParameterValue=$TagTeam \
ParameterKey=TagProduct,ParameterValue=$TagProduct ParameterKey=TagTenant,ParameterValue=$TagTenant \
--capabilities CAPABILITY_IAM 2>&1)

sleep 60

aws s3 cp config/real-time-monitor.json s3://${ConfigBucket}/rtmonitorconfig/ || true
aws s3 cp CustomBaseline/constraints.json s3://${ConfigBucket}/${BaselineS3Bucket}/ || true
aws s3 cp CustomBaseline/statistics.json s3://${ConfigBucket}/${BaselineS3Bucket}/ || true

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