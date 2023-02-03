#!/bin/bash

AWS_REGION=`curl http://169.254.169.254/latest/meta-data/placement/region`

curl -s https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluentd-quickstart.yaml | \
sed "s/{{cluster_name}}/eksworkshop-eksctl/;s/{{region_name}}/${AWS_REGION}/" | \
kubectl apply -f - 