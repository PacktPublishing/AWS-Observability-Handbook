//Logging using Lambda powertools with Lambda context support.

//Inclusion of Logger PowerLambda Tools
const { Logger, injectLambdaContext } = require('@aws-lambda-powertools/logger');
//Servicename of the lambda function
const logger = new Logger({serviceName: 'get-all-items'});
const AWS = require('aws-sdk')
const docClient = new AWS.DynamoDB.DocumentClient()

exports.getAllItemsHandler = async (event, context) => {
    let response
    try {
        if (event.httpMethod !== 'GET') {
            throw new Error(`getAllItems only accept GET method, you tried: ${event.httpMethod}`)
        }

        const items = await getAllItems();
        
//Logging Lambda Context and the output of items as a JSON using logger standard format
        logger.addContext(context);
        logger.info('Items in list:', { items });

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