
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

if ! POLICY_ARN=$(aws iam get-policy \
                    --policy-arn arn:aws:iam::$AWS_ACCOUNT_ID:policy/AWSOpenTelemetryTaskPolicy \
                    --query "Policy.Arn" \
                    --output text 2> /dev/null); then
    echo "AWSOpenTelemetryTaskPolicy not found, creating..."
    read -r -d '' AWS_ADOT_POLICY <<EOF
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
                    "xray:PutTraceSegments",
                    "xray:PutTelemetryRecords",
                    "xray:GetSamplingRules",
                    "xray:GetSamplingTargets",
                    "xray:GetSamplingStatisticSummaries",
                    "cloudwatch:PutMetricData",
                    "ec2:DescribeVolumes",
                    "ec2:DescribeTags",
                    "ssm:GetParameters"
                ], 
                "Resource": "*" 
            } 
        ] 
    }
EOF

    echo "${AWS_ADOT_POLICY}" > AWSOpenTelemetryTaskPolicy.json
    POLICY_ARN=$(aws iam create-policy \
        --policy-name AWSOpenTelemetryTaskPolicy  \
        --policy-document file://AWSOpenTelemetryTaskPolicy.json \
        --query "Policy.Arn")
fi

echo "Using AWSOpenTelemetryTaskPolicy with ARN: $POLICY_ARN"

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

echo "${ECS_TASK_TRUST_POLICY}" > AWSOpenTelemetryECSTaskTrustPolicy.json

if ! TASK_ROLE_ARN=$(aws iam get-role \
        --role-name AWSOpenTelemetryECSTaskRole \
        --query "Role.Arn" --output text 2> /dev/null); then
    echo "AWSOpenTelemetryECSTaskRole not found, creating..."
    TASK_ROLE_ARN=$(aws iam create-role \
        --role-name AWSOpenTelemetryECSTaskRole \
        --assume-role-policy-document file://AWSOpenTelemetryECSTaskTrustPolicy.json \
        --query "Role.Arn" --output text)
        
    aws iam attach-role-policy --role-name AWSOpenTelemetryECSTaskRole --policy-arn $POLICY_ARN
  
fi

echo "Using AWSOpenTelemetryECSTaskRole with ARN: $TASK_ROLE_ARN"

if ! TASK_EXEC_ROLE_ARN=$(aws iam get-role --role-name AWSOpenTelemetryTaskExecutionRole --query "Role.Arn" --output text); then
    echo "AWSOpenTelemetryTaskExecutionRole not found, creating..."
    TASK_EXEC_ROLE_ARN=$(aws iam create-role \
        --role-name AWSOpenTelemetryTaskExecutionRole \
        --assume-role-policy-document file://AWSOpenTelemetryECSTaskTrustPolicy.json \
        --query "Role.Arn" --output text)
        
    aws iam attach-role-policy --role-name AWSOpenTelemetryTaskExecutionRole --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

    aws iam attach-role-policy --role-name AWSOpenTelemetryTaskExecutionRole --policy-arn arn:aws:iam::aws:policy/CloudWatchLogsFullAccess

    aws iam attach-role-policy --role-name AWSOpenTelemetryTaskExecutionRole --policy-arn arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess
fi

echo "Using AWSOpenTelemetryTaskExecutionRole with ARN: $TASK_EXEC_ROLE_ARN"

AWS_REGION=`curl http://169.254.169.254/latest/meta-data/placement/region`

ECS_TASK_DEFINITION_ARN=$(aws ecs list-task-definitions --family-prefix adot-example-containerinsights --query "taskDefinitionArns[-1]" --output text)

if [ "$ECS_TASK_DEFINITION_ARN" = "None" ]; then
    echo "ECS task definition not found, creating..."
    read -r -d '' ECS_TASK_DEFINITION <<EOF
    {
    "family": "adot-example-containerinsights",
    "networkMode": "awsvpc",
    "requiresCompatibilities": [
        "FARGATE"
    ],
    "cpu": "512",
    "memory": "1024",
    "containerDefinitions": [
        {
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-group": "/ecs/aws-otel-EC2",
                    "awslogs-region": "$AWS_REGION",
                    "awslogs-stream-prefix": "ecs",
                    "awslogs-create-group": "True"
                }
            },
            "portMappings": [
                {
                    "hostPort": 2000,
                    "protocol": "udp",
                    "containerPort": 2000
                },
                {
                    "hostPort": 4317,
                    "protocol": "tcp",
                    "containerPort": 4317
                },
                {
                    "hostPort": 8125,
                    "protocol": "udp",
                    "containerPort": 8125
                }
            ],
            "environment": [
                {
                    "name": "AWS_REGION",
                    "value": "$AWS_REGION"
                }
            ],
            "command": [
                "--config=/etc/ecs/container-insights/otel-task-metrics-config.yaml"
            ],
            "image": "amazon/aws-otel-collector",
            "name": "aws-otel-collector"
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

if ! $(aws ecs list-services --cluster o11y-on-aws --query "serviceArns[*]" --output text | grep -w -q o11y-on-aws-adot); then
    echo "ECS service not found, creating..."

    if ! DEFAULT_VPC_ID=$(aws ec2 describe-vpcs --query "Vpcs[?IsDefault].VpcId" --output text); then
        DEFAULT_VPC_ID=$(aws ec2 create-default-vpc --query "Vpc.VpcId" --output text)
    fi

    DEFAULT_SUBNET_IDS=$(aws ec2 describe-subnets \
        --filters Name=default-for-az,Values=true \
        --query "Subnets[*].SubnetId" --output text | sed 's/\s\+/,/g')

    DEFAULT_SG_ID=$(aws ec2 describe-security-groups \
        --filters Name=vpc-id,Values=$DEFAULT_VPC_ID Name=group-name,Values=default \
        --query "SecurityGroups[*].GroupId" --output text)

    aws ecs create-service \
        --cluster o11y-on-aws \
        --service-name o11y-on-aws-adot \
        --task-definition $ECS_TASK_DEFINITION_ARN \
        --desired-count 1 \
        --launch-type "FARGATE" \
        --network-configuration "awsvpcConfiguration={subnets=[$DEFAULT_SUBNET_IDS],securityGroups=[$DEFAULT_SG_ID],assignPublicIp=ENABLED}" \
        --query "service.serviceArn" \
        --output text

fi

echo "Created ECS service named o11y-on-aws-adot"

