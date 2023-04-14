#!/bin/bash

ROLE_NAME=$(aws iam list-roles --query 'Roles[?contains(RoleName,`NodeInstanceRole`)].RoleName' --output text) 

aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy