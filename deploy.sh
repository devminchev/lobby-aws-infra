#!/bin/bash

# Stop script on error
set -e

# Region variables
EU_REGION="eu-west-1"
LAB_REGION="eu-west-1"
US_REGION="us-east-1"
GEN_AI_REGION_EU="eu-west-1"

# Load environment variables
if [ -f .env ]; then
  source .env
else
  echo "❌ .env file not found! Please create one before deploying."
  exit 1
fi

# Prompt user for deployment choice
echo "Please choose the deployment region:"
echo "1: EU ($EU_REGION)"
echo "2: US ($US_REGION)"
echo "3: EU Experimental Lab($LAB_REGION)"
echo "4: EU GEN AI SPACE($GEN_AI_REGION_EU)"
read -p "Enter your choice (1,2,3 or 4): " region_choice

# Deploy based on user choice
if [ "$region_choice" == "1" ]; then
  aws cloudformation deploy \
    --template-file templates/osGatewayDevStack.yml \
    --stack-name personalised-lobby-os-dev \
    --profile lobby-playground \
    --region $EU_REGION \
    --parameter-overrides MasterUserName=$MASTER_OS_USER_NAME MasterUserPassword=$MASTER_OS_USER_PASSWORD
  echo "✅ EU Deployment to $EU_REGION(Ireland) successful!"

elif [ "$region_choice" == "2" ]; then
  aws cloudformation deploy \
    --template-file templates/osGatewayDevStackUS.yml \
    --stack-name personalised-lobby-os-dev-us \
    --profile lobby-playground-us \
    --region $US_REGION \
    --parameter-overrides MasterUserName=$US_MASTER_OS_USER_NAME MasterUserPassword=$US_MASTER_OS_USER_PASSWORD
  echo "✅ US Deployment to $US_REGION(N. Virginia) successful!"

elif [ "$region_choice" == "3" ]; then
  aws cloudformation deploy \
    --template-file templates/osGatewayExperimental.yml \
    --stack-name personalised-lobby-os-experimental-lab \
    --profile lobby-playground \
    --region $LAB_REGION \
    --parameter-overrides MasterUserName=$MASTER_OS_USER_NAME MasterUserPassword=$MASTER_OS_USER_PASSWORD
  echo "✅ EU Deployment to $LAB_REGION(Ireland) successful!"

elif [ "$region_choice" == "4" ]; then
  aws cloudformation deploy \
    --template-file templates/osGatewayDevStack.yml \
    --stack-name personalised-lobby-os-dev \
    --profile lobby-playground-gen-ai \
    --region $GEN_AI_REGION_EU \
    --parameter-overrides MasterUserName=$MASTER_OS_USER_NAME MasterUserPassword=$MASTER_OS_USER_PASSWORD
  echo "✅ EU Deployment to $GEN_AI_REGION_EU(Ireland) successful!"

else
  echo "❌ Invalid choice. Deployment canceled."
  exit 1
fi
