#!/usr/bin/env bash

if [[ ! $TOPIC ]]; then
  echo "please define the environment variable TOPIC that your AWS Chatbot uses as an sns topic in ARN format!"
  echo "These are the available topics in your account:"
  aws sns list-topics --output text
  echo "Aborting"
  exit 1
else
  echo
  echo "Using TOPIC: $TOPIC"
fi

if [[ ! $MESSAGE ]]; then
  echo "please define the environment variable MESSAGE that your daily cost will be printed with!"
  echo "Aborting"
  exit 1
else
  echo
  echo "Using MESSAGE: $MESSAGE"
fi

echo
echo "Check if role lambda-cost-to-chatbot-role already exists"
ROLE=$(aws iam get-role --role-name lambda-cost-to-chatbot-role --query 'Role.Arn' --output text 2> /dev/null)
REGION=$(aws configure get region)
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)

if [[ ! $ROLE ]]; then
  echo
  echo "create role lambda-cost-to-chatbot-role"
  cat lambda-cost-to-chatbot-role-policy.json.template | sed -e "s/TOPIC/$TOPIC/" | sed -e "s/REGION/$REGION/" | sed -e "s/ACCOUNT/$ACCOUNT/" > lambda-cost-to-chatbot-role-policy.json
  aws iam create-role --role-name lambda-cost-to-chatbot-role --assume-role-policy-document file://assume-role-policy.json
  aws iam put-role-policy --role-name lambda-cost-to-chatbot-role --policy-name lambda-cost-to-chatbot --policy-document file://lambda-cost-to-chatbot-role-policy.json
else
  echo
  echo "role lambda-cost-to-chatbot-role already exists, skipping creation"
fi

EXISTING_VARS=$(aws lambda get-function-configuration --function-name cost-to-chatbot --query Environment.Variables --output text 2> /dev/null)

if [[ $EXISTING_VARS == "None" ]]; then
  # create parameter
  echo
  echo "Add MESSAGE, TOPIC and ACCOUNT to lambda environment"
  aws lambda update-function-configuration --function-name cost-to-chatbot --environment "Variables={ACCOUNT=$ACCOUNT,MESSAGE=$MESSAGE,TOPIC=$TOPIC}"
else
  # compare existing with newly specified
  if [[ $EXISTING_VARS != "$ACCOUNT	$MESSAGE	$TOPIC" ]]; then
    echo
    echo "Update lambda environment variables"
    aws lambda update-function-configuration --function-name cost-to-chatbot --environment "Variables={ACCOUNT=$ACCOUNT,MESSAGE=$MESSAGE,TOPIC=$TOPIC}"
  else
    echo
    echo "env vars have not changed"
  fi
fi

# make lambda package including module dependencies
echo
echo "zipping up the function code" 
zip -qr function.zip lambda.js node_modules/ -x test


FUNCTION=$(aws lambda get-function --function-name cost-to-chatbot --output text 2> /dev/null)
ROLE=$(aws iam get-role --role-name lambda-cost-to-chatbot-role --query 'Role.Arn' --output text 2> /dev/null)

if [[ ! $FUNCTION ]]; then
  echo
  echo "Creating cost-to-chatbot function"
  aws lambda create-function --region $REGION --function-name cost-to-chatbot --zip-file fileb://function.zip --handler lambda.handler --runtime nodejs16.x --role $ROLE
else
  echo
  echo "Function cost-to-chatbot already exists. Updating function"
  aws lambda update-function-code --region $REGION --function-name cost-to-chatbot --zip-file fileb://function.zip --publish
fi

echo
echo Success.
