//Inclusion of Logger Lambda PowerTools
const { Logger, injectLambdaContext } = require('@aws-lambda-powertools/logger');

//Inclusion of Metrics from Lambda PowerTools
const { Metrics, MetricUnits, logMetrics } = require('@aws-lambda-powertools/metrics');

//Inclusion of tracer from Lambda Powertools
const { Tracer, captureLambdaHandler } = require('@aws-lambda-powertools/tracer');

//Servicename of the lambda function shown in the CloudWatch Logs
const logger = new Logger({serviceName: 'get-all-items'});


//Custom Metric namespace and service name in CloudWatch Custom Metrics
const metrics = new Metrics({ namespace: 'getitems', serviceName: 'get-all-items' });

//X-Ray traces will be added with the servicename "get-all-items"
const tracer = new Tracer({ serviceName: 'get-all-items' });

const AWS = require('aws-sdk')

//Inclusion of dynamodb sdk to support tracing
const { DocumentClient} = require('aws-sdk/clients/dynamodb');

//Trace the dynamoDB calls 
const docClient = tracer.captureAWSClient(new DocumentClient());
//const docClient = new AWS.DynamoDB.DocumentClient()

exports.getAllItemsHandler = async (event, context) => {
    
        const segment = tracer.getSegment();
        logger.info(segment);
        const handlerSegment = segment.addNewSubsegment(`## ${process.env._HANDLER}`);
        logger.info(handlerSegment);
        tracer.setSegment(handlerSegment);
        
        // Tracer: Annotate the subsegment with the cold start & serviceName
        tracer.annotateColdStart();
        tracer.addServiceNameAnnotation();

        // Tracer: Add annotation for the awsRequestId
        tracer.putAnnotation('awsRequestId', context.awsRequestId);
        
    let response
    try {
        if (event.httpMethod !== 'GET') {
            throw new Error(`getAllItems only accept GET method, you tried: ${event.httpMethod}`)
        }

        const items = await getAllItems();
        logger.addContext(context);
        logger.info('Items in list:', { items });
        
        tracer.putAnnotation('awsRequestId', context.awsRequestId);
        tracer.putMetadata('eventPayload', event);  
        
// Adding the total retrieved items as a metric in the Custom namespace called "getitems"
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
    finally {
     // Close subsegment (the AWS Lambda one is closed automatically)
      handlerSegment.close();
      
      // Set back the facade segment as active again
      tracer.setSegment(segment);
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