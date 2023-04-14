#!/bin/bash

alb_url=$(aws cloudformation describe-stacks --stack-name o11y-on-aws-test | jq -r '.Stacks[].Outputs[] | select(.OutputKey | contains("PublicLoadBalancerDNSName")) | .OutputValue')

siege -c 200 -i $alb_url