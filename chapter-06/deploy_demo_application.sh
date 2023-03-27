#!/bin/bash

# Please execute the following commands to clone all the service repositories: 

cd ~/environment 

git clone https://github.com/aws-containers/ecsdemo-platform 
git clone https://github.com/aws-containers/ecsdemo-frontend 
git clone https://github.com/aws-containers/ecsdemo-nodejs 
git clone https://github.com/aws-containers/ecsdemo-crystal 


# Execute the commands below to deploy the sample application microservices: 

cd ~/environment/ecsdemo-frontend
copilot init --app ecsworkshop --type "Load Balanced Web Service" --name ecsdemo-frontend --dockerfile "./Dockerfile" --deploy

cat << EOF >> copilot/ecsdemo-frontend/manifest.yml
variables:
  CRYSTAL_URL: "http://ecsdemo-crystal.test.ecsworkshop.local:3000/crystal"
  NODEJS_URL: "http://ecsdemo-nodejs.test.ecsworkshop.local:3000"
EOF
copilot deploy --app ecsworkshop --name ecsdemo-frontend

cd ~/environment/ecsdemo-nodejs
copilot init --app ecsworkshop --type "Backend Service" --name ecsdemo-nodejs --dockerfile "./Dockerfile" --deploy 

cd ~/environment/ecsdemo-crystal
git rev-parse --short=7 HEAD > code_hash.txt
copilot init --app ecsworkshop --type "Backend Service" --name ecsdemo-crystal --dockerfile "./Dockerfile" --deploy 
