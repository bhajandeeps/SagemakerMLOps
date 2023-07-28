#!/bin/bash
: ${ENVIRONMENT:="dev"}
aws events enable-rule --name "wipuat-pricing-ml-training-pipeline-failure-9XF2"
