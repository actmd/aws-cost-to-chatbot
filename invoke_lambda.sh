#!/usr/bin/env bash

rm -f out.json
aws lambda invoke --function-name cost-to-chatbot out.json --log-type Tail \
--query 'LogResult' --output text |  base64 -d
