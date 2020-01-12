#! /bin/bash

STACK_NAME=aws-good-parts
REGION=ap-southeast-1
CLI_PROFILE=aws-good-parts

EC2_INSTANCE_TYPE=t2.micro

AWS_ACCOUNT_ID=`aws sts get-caller-identity --profile aws-good-parts \
 --query "Account" --output text`
CODEPIPELINE_BUCKET="$STACK_NAME-$REGION-codepipeline-$AWS_ACCOUNT_ID"

# Generate a personal access token with repo and admin:repo_hook
# permissions from https://github.com/settings/tokens
GH_ACCESS_TOKEN=$(cat ~/.github/aws-good-parts-access-token)
GH_OWNER=$(cat ~/.github/aws-good-parts-owner)
GH_REPO=$(cat ~/.github/aws-good-parts-repo)
GH_BRANCH=master

# Deploys static resources
echo -e "\n\n=========== Deploying setup.yml ===========" 
aws cloudformation deploy \
  --region $REGION \
  --profile $CLI_PROFILE \
  --stack-name $STACK_NAME-setup \
  --template-file setup.yml \
  --no-fail-on-empty-changeset \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    CodePipelineBucket=$CODEPIPELINE_BUCKET

# Deploy the CloudFormation template
echo -e "\n\n=========== Deploying main.yml ==========="
aws cloudformation deploy \
  --region $REGION \
  --profile $CLI_PROFILE \
  --stack-name $STACK_NAME \
  --template-file main.yml \
  --no-fail-on-empty-changeset \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    EC2InstanceType=$EC2_INSTANCE_TYPE \
    GitHubOwner=$GH_OWNER \
    GitHubRepo=$GH_REPO \
    GitHubBranch=$GH_BRANCH \
    GitHubPersonalAccessToken=$GH_ACCESS_TOKEN \
    CodePipelineBucket=$CODEPIPELINE_BUCKET

# If the deploy succeeded, show the DNS name of the created instance
if [ $? -eq 0 ]; then
  aws cloudformation list-exports \
    --profile aws-good-parts \
    --query "Exports[?starts_with(Name,'InstanceEndpoint')].Value"
fi

