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
--policy-name AWSDistroOpenTelemetryPolicy \
--policy-document file://AWSOpenTelemetryTaskPolicy.json \
--query "Policy.Arn" --output text)

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

TASK_ROLE_ARN=$(aws iam create-role \
  --role-name AWSOpenTelemetryECSTaskRole \
  --assume-role-policy-document file://AWSOpenTelemetryECSTaskTrustPolicy.json \
  --query "Role.Arn" --output text)

aws iam attach-role-policy --role-name AWSOpenTelemetryECSTaskRole --policy-arn $POLICY_ARN


TASK_EXEC_ROLE_ARN=$(aws iam create-role \
  --role-name AWSOpenTelemetryTaskExecutionRole \
  --assume-role-policy-document file://AWSOpenTelemetryECSTaskTrustPolicy.json \
  --query "Role.Arn" --output text)

aws iam attach-role-policy --role-name AWSOpenTelemetryTaskExecutionRole --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

aws iam attach-role-policy --role-name AWSOpenTelemetryTaskExecutionRole --policy-arn arn:aws:iam::aws:policy/CloudWatchLogsFullAccess

aws iam attach-role-policy --role-name AWSOpenTelemetryTaskExecutionRole --policy-arn arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess

AWS_REGION=`curl http://169.254.169.254/latest/meta-data/placement/region`

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
                    "awslogs-region": "eu-central-1",
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
                    "region": "eu-central-1",
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

DEFAULT_VPC_ID=$(aws ec2 describe-vpcs \
    --filters Name=is-default,Values=true \
    --query "Vpcs[*].VpcId" --output text)

DEFAULT_SUBNET_IDS=$(aws ec2 describe-subnets \
    --filters Name=default-for-az,Values=true \
    --query "Subnets[*].SubnetId" --output text | sed 's/\s\+/,/g')

DEFAULT_SG_ID=$(aws ec2 describe-security-groups \
    --filters Name=vpc-id,Values=$DEFAULT_VPC_ID Name=group-name,Values=default \
    --query "SecurityGroups[*].GroupId" --output text)

aws ecs create-service --cluster o11y-on-aws --service-name o11y-on-aws-firelens --task-definition $ECS_TASK_DEFINITION_ARN --desired-count 1 --launch-type "FARGATE" --network-configuration "awsvpcConfiguration={subnets=[$DEFAULT_SUBNET_IDS],securityGroups=[$DEFAULT_SG_ID],assignPublicIp=ENABLED}"

