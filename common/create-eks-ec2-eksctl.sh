#!/bin/bash

REGION=`curl http://169.254.169.254/latest/meta-data/placement/region`
TEMPLATE=eks-ec2-eksctl.yaml

aws cloud9 update-environment  --environment-id $C9_PID --managed-credentials-action DISABLE
rm -vf ${HOME}/.aws/credentials

aws s3 cp s3://insiders-guide-observability-on-aws-book/common/$TEMPLATE .

sed -i "s/REGION/$REGION/g" $TEMPLATE 

eksctl create cluster -f $TEMPLATE