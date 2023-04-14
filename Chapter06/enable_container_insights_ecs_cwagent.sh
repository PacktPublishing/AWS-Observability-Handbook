#!/bin/bash 

ClusterName=$1 

Region=`curl http://169.254.169.254/latest/meta-data/placement/region`

aws cloudformation create-stack --stack-name CWAgentECS-${ClusterName}-${Region} --template-body https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/ecs-task-definition-templates/deployment-mode/daemon-service/cwagent-ecs-instance-metric/cloudformation-quickstart/cwagent-ecs-instance-metric-cfn.json --parameters ParameterKey=ClusterName,ParameterValue=${ClusterName} ParameterKey=CreateIAMRoles,ParameterValue=True --capabilities CAPABILITY_NAMED_IAM --region ${Region}