#!/bin/bash

# Please execute the following commands to clone all the service repositories: 

cd ~/environment 

git clone https://github.com/aws-containers/ecsdemo-platform 
git clone https://github.com/aws-containers/ecsdemo-frontend 
git clone https://github.com/aws-containers/ecsdemo-nodejs 
git clone https://github.com/aws-containers/ecsdemo-crystal 

# Execute the commands below to deploy the required infrastructure: 

cd ~/environment/ecsdemo-platform/cdk 
pip install -r requirements.txt 
cdk context --clear && cdk deploy --require-approval never 

# Execute the commands below to deploy the sample application microservices: 

cd ~/environment/ecsdemo-frontend/cdk 
pip install -r requirements.txt 
cdk context --clear && cdk deploy --require-approval never 

cd ~/environment/ecsdemo-nodejs/cdk 
pip install -r requirements.txt 
cdk context --clear && cdk deploy --require-approval never 

cd ~/environment/ecsdemo-crystal/cdk 
pip install -r requirements.txt 
cdk context --clear && cdk deploy --require-approval never