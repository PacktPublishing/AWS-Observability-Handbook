#!/bin/bash

cluster_arn=$(aws ecs list-clusters | jq -r '.clusterArns[] | select(contains("container-demo"))') 

clustername=$(aws ecs describe-clusters --clusters $cluster_arn | jq -r '.clusters[].clusterName')

AWS_REGION=`curl http://169.254.169.254/latest/meta-data/placement/region`

aws cloudformation create-stack \
--stack-name CWAgentECS-$clustername-${AWS_REGION} \
--template-body "$(curl -Ls https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/ecs-task-definition-templates/deployment-mode/daemon-service/cwagent-ecs-instance-metric/cloudformation-quickstart/cwagent-ecs-instance-metric-cfn.json)" \
--parameters ParameterKey=ClusterName,ParameterValue=$clustername ParameterKey=CreateIAMRoles,ParameterValue=True \
--capabilities CAPABILITY_NAMED_IAM \
--region ${AWS_REGION} 