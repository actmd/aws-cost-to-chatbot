
Get last day's AWS cost and send it to AWS Chatbot
==================================================

This repo contains a lambda and a few bash scripts that setup the lambda and test it.

The lambda code is in lambda.js. It uses the latest recommended nodejs.

to install or update the lambda, use ./deploy_lambda.sh

to run lambda and see its output, use ./invoke_lambda.sh

It requires two bash env vars to be defined: TOPIC which is the ARM of the topic your AWS Chatbot uses, and MESSAGE, which is the tet we print ahead of the dollar amount.

Copyright Imre Fitos 2022
