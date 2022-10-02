const AWS = require('aws-sdk')

const costexplorer = new AWS.CostExplorer()
const sns = new AWS.SNS({region: process.env.AWS_REGION})

// Handler
exports.handler = async function(event, context) {
  try {
    let cost = await getCost()
    let amount = parseFloat(cost.ResultsByTime[0].Total.UnblendedCost.Amount).toFixed(2)
    console.log(process.env.MESSAGE + " $" + amount)
    let status = await sendSNSMessage(process.env.MESSAGE + " $" + amount)
    return formatResponse(process.env.MESSAGE + " $" + amount)
  } catch(error) {
    return formatError(error)
  }
}


var formatResponse = function(body){
  var response = {
    "statusCode": 200,
    "headers": {
      "Content-Type": "application/json"
    },
    "isBase64Encoded": false,
    "body": body
  }
  return response
}


var formatError = function(error){
  var response = {
    "statusCode": error.statusCode,
    "headers": {
      "Content-Type": "text/plain",
      "x-amzn-ErrorType": error.code
    },
    "isBase64Encoded": false,
    "body": error.code + ": " + error.message
  }
  return response
}


var getCost = function(){
  let today = new Date()
  let yesterday = new Date()
  yesterday.setDate(today.getDate() - 1)
  let y = yesterday.toISOString().slice(0,10)
  let t = today.toISOString().slice(0,10)
  let params = {
    Granularity: 'DAILY',
    Metrics: [ 'UnblendedCost' ],
    TimePeriod: {
      Start: y,
      End: t
    }
  }
  return costexplorer.getCostAndUsage(params).promise()
}


var sendSNSMessage = function(body){
  let params = {
    TopicArn: process.env.TOPIC,
    Message: JSON.stringify({
      "version": "0",
      "id": "00000000-0000-0000-0000-000000000000",
      "account": process.env.ACCOUNT,
      "time": "1970-01-01T00:00:00Z",
      "region": process.env.AWS_REGION,
      "source": "aws.health",
      "detail-type": "AWS Health Event",
      "resources": [],
      "detail": {
        "eventDescription": [{
          "language": "en_US",
          "latestDescription": body
        }]
      }
    })
  }
  return sns.publish(params).promise()
}


var serialize = function(object) {
  return JSON.stringify(object, null, 2)
}
