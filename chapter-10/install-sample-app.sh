#!/bin/bash

TEMPLATE=prometheus-sample-app.yaml

aws s3 cp s3://insiders-guide-observability-on-aws-book/chapter-10/$TEMPLATE .

kubectl apply -f $TEMPLATE