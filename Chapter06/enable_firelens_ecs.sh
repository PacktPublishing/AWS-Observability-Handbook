AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

if ! POLICY_ARN=$(aws iam get-policy \
                    --policy-arn arn:aws:iam::$AWS_ACCOUNT_ID:policy/AWSFirelensPolicy \
                    --query "Policy.Arn" \
                    --output text 2> /dev/null); then
    echo "AWSFirelensPolicy not found, creating..."
    read -r -d '' AWS_FIRELENS_POLICY <<EOF
    { 
        "Version": "2012-10-17", 
        "Statement": [ 
            { 
                "Effect": "Allow", 
                "Action": [ 
                    "logs:PutLogEvents",
                    "logs:CreateLogGroup",
                    "logs:CreateLogStream",
                    "logs:DescribeLogStreams",
                    "logs:DescribeLogGroups",
                    "ec2:DescribeVolumes",
                    "ec2:DescribeTags",
                    "ssm:GetParameters"
                ], 
                "Resource": "*" 
            } 
        ] 
    }
EOF

    echo "${AWS_FIRELENS_POLICY}" > AWSFirelensTaskPolicy.json
    
    POLICY_ARN=$(aws iam create-policy \
        --policy-name AWSFirelensPolicy \
        --policy-document file://AWSFirelensTaskPolicy.json \
        --query "Policy.Arn" --output text)
fi

echo "Using AWSFirelensPolicy with ARN: $POLICY_ARN"

read -r -d '' ECS_TASK_TRUST_POLICY <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

echo "${ECS_TASK_TRUST_POLICY}" > AWSFirelensECSTaskTrustPolicy.json

if ! TASK_ROLE_ARN=$(aws iam get-role \
        --role-name AWSFirelensECSTaskRole \
        --query "Role.Arn" --output text 2> /dev/null); then
    echo "AWSFirelensECSTaskRole not found, creating..."
    TASK_ROLE_ARN=$(aws iam create-role \
        --role-name AWSFirelensECSTaskRole \
        --assume-role-policy-document file://AWSFirelensECSTaskTrustPolicy.json \
        --query "Role.Arn" --output text)
        
    aws iam attach-role-policy --role-name AWSFirelensECSTaskRole --policy-arn $POLICY_ARN
  
fi

echo "Using AWSFirelensECSTaskRole with ARN: $TASK_ROLE_ARN"

if ! TASK_EXEC_ROLE_ARN=$(aws iam get-role --role-name AWSFirelensTaskExecutionRole --query "Role.Arn" --output text); then
    echo "AWSFirelensTaskExecutionRole not found, creating..."
    TASK_EXEC_ROLE_ARN=$(aws iam create-role \
        --role-name AWSFirelensTaskExecutionRole \
        --assume-role-policy-document file://AWSFirelensECSTaskTrustPolicy.json \
        --query "Role.Arn" --output text)
        
    aws iam attach-role-policy --role-name AWSFirelensTaskExecutionRole --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

    aws iam attach-role-policy --role-name AWSFirelensTaskExecutionRole --policy-arn arn:aws:iam::aws:policy/CloudWatchLogsFullAccess

    aws iam attach-role-policy --role-name AWSFirelensTaskExecutionRole --policy-arn arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess
fi

echo "Using AWSFirelensTaskExecutionRole with ARN: $TASK_EXEC_ROLE_ARN"

AWS_REGION=$(curl http://169.254.169.254/latest/meta-data/placement/region)

ECS_TASK_DEFINITION_ARN=$(aws ecs list-task-definitions --family-prefix firelens-example-cloudwatch --query "taskDefinitionArns[-1]" --output text)

if [ "$ECS_TASK_DEFINITION_ARN" = "None" ]; then
    echo "ECS task definition not found, creating..."
    read -r -d '' ECS_TASK_DEFINITION <<EOF
    {
        "family": "firelens-example-cloudwatch",
        "networkMode": "awsvpc",
        "requiresCompatibilities": [
            "FARGATE"
        ],
        "cpu": "512",
        "memory": "1024",
        "containerDefinitions": [
            {
                "essential": true,
                "image": "906394416424.dkr.ecr.us-west-2.amazonaws.com/aws-for-fluent-bit:latest",
                "name": "log_router",
                "firelensConfiguration": {
                    "type": "fluentbit"
                },
                "logConfiguration": {
                    "logDriver": "awslogs",
                    "options": {
                        "awslogs-group": "firelens-container",
                        "awslogs-region": "$AWS_REGION",
                        "awslogs-create-group": "true",
                        "awslogs-stream-prefix": "firelens"
                    }
                }
            },
            {
                "essential": true,
                "image": "httpd",
                "name": "app",
                "logConfiguration": {
                    "logDriver": "awsfirelens",
                    "options": {
                        "Name": "cloudwatch",
                        "region": "$AWS_REGION",
                        "log_group_name": "firelens-blog",
                        "auto_create_group": "true",
                        "log_stream_prefix": "from-fluent-bit",
                        "log-driver-buffer-limit": "2097152"
                    }
                }
            }
        ]
    }
EOF

    echo "${ECS_TASK_DEFINITION}" > TaskDefinition.json

    ECS_TASK_DEFINITION_ARN=$(aws ecs register-task-definition \
        --task-role-arn $TASK_ROLE_ARN \
        --execution-role-arn $TASK_EXEC_ROLE_ARN \
        --cli-input-json file://TaskDefinition.json \
        --query "taskDefinition.taskDefinitionArn" --output text)

fi

echo "Using ECS task definition with ARN: $ECS_TASK_DEFINITION_ARN"

if ! $(aws ecs list-services --cluster o11y-on-aws --query "serviceArns[*]" --output text | grep -w -q o11y-on-aws-firelens); then
    echo "ECS service not found, creating..."
    
    if ! DEFAULT_VPC_ID=$(aws ec2 describe-vpcs --query "Vpcs[?IsDefault].VpcId" --output text); then
        DEFAULT_VPC_ID=$(aws ec2 create-default-vpc --query "Vpc.VpcId" --output text)
    fi
    
    DEFAULT_SUBNET_IDS=$(aws ec2 describe-subnets \
        --query "Subnets[?DefaultForAz].SubnetId" --output text | sed 's/\s\+/,/g')

    DEFAULT_SG_ID=$(aws ec2 describe-security-groups \
        --filters Name=vpc-id,Values=$DEFAULT_VPC_ID Name=group-name,Values=default \
        --query "SecurityGroups[*].GroupId" --output text)
        
    aws ecs create-service \
        --cluster o11y-on-aws \
        --service-name o11y-on-aws-firelens \
        --task-definition $ECS_TASK_DEFINITION_ARN \
        --desired-count 1 \
        --launch-type "FARGATE" \
        --network-configuration "awsvpcConfiguration={subnets=[$DEFAULT_SUBNET_IDS],securityGroups=[$DEFAULT_SG_ID],assignPublicIp=ENABLED}" \
        --query "service.serviceArn" \
        --output text
    
fi

echo "Created ECS service named o11y-on-aws-firelens"
