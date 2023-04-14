#!/bin/bash

TEMPLATE=prometheus-daemonset.yaml

aws s3 cp s3://insiders-guide-observability-on-aws-book/chapter-10/$TEMPLATE .

export SERVICE_ACCOUNT_IAM_ROLE=EKS-AMP-ServiceAccount-Role
export SERVICE_ACCOUNT_IAM_ROLE_ARN=$(aws iam get-role --role-name $SERVICE_ACCOUNT_IAM_ROLE --query 'Role.Arn' --output text)
WORKSPACE_ID=$(aws amp list-workspaces --alias insidersguide | jq .workspaces[0].workspaceId -r)
REMOTE_WRITE="https://aps-workspaces.${AWS_REGION}.amazonaws.com/workspaces/${WORKSPACE_ID}/api/v1/remote_write"

sed -i "s+<REMOTE_WRITE_ENDPOINT>+$REMOTE_WRITE+g" $TEMPLATE 

sed -i "s/<REGION>/$AWS_REGION/g" $TEMPLATE

sed -i "s+<SERVICE_ACCOUNT_IAM_ROLE_ARN>+$SERVICE_ACCOUNT_IAM_ROLE_ARN+g" $TEMPLATE


kubectl apply -f $TEMPLATE
