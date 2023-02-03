//Inclusion of Logger Lambda PowerTools
const { Logger, injectLambdaContext } = require('@aws-lambda-powertools/logger');

//Inclusion of Metrics from Lambda PowerTools
const { Metrics, MetricUnits, logMetrics } = require('@aws-lambda-powertools/metrics');

//Servicename of the lambda function shown in the CloudWatch Logs
const logger = new Logger({serviceName: 'get-all-items'});


//Custom Metric namespace and service name in CloudWatch Custom Metrics
const metrics = new Metrics({ namespace: 'getitems', serviceName: 'get-all-items' });

const AWS = require('aws-sdk')
const docClient = new AWS.DynamoDB.DocumentClient()

exports.getAllItemsHandler = async (event, context) => {
    let response
    try {
        if (event.httpMethod !== 'GET') {
            throw new Error(`getAllItems only accept GET method, you tried: ${event.httpMethod}`)
        }

        const items = await getAllItems();
        logger.addContext(context);
        logger.info('Items in list:', { items });
     
        metrics.addMetric('itemcount', MetricUnits.Count, items.Count);
        metrics.publishStoredMetrics();
        
        response = {
            statusCode: 200,
            headers: {
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify(items)
        }
    } catch (err) {
        response = {
            statusCode: 500,
            headers: {
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify(err)
        }
    }
    return response
}

const getAllItems = async () => {
    let response
    try {
        var params = {
            TableName: process.env.SAMPLE_TABLE
        }
        response = await docClient.scan(params).promise()
 
    } catch (err) {
        throw err
    }
    return response
}

