#!/bin/bash
: ${ENVIRONMENT:="dev"}
# Reading tag values
Environment=${ENVIRONMENT}
TagTeam=`cat config/common-config.json | jq -r '.tag_team'`
TagProduct=`cat config/common-config.json | jq -r '.tag_product'`
TagTenant=`cat config/common-config.json | jq -r '.tag_tenant'`
ConfigBucket="wi-cred-datalake-"${ENVIRONMENT}"-s3-mlops-config"
ConfigKMSKeyId=`cat config/env-specific-config.json | jq -r '.ConfigKMSKeyId'`
ConfigKMSKeyId=${ConfigKMSKeyId:4}
echo $TagTeam
echo $TagTenant
echo $ConfigKMSKeyId