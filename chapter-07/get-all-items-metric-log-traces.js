const { Logger, injectLambdaContext } = require('@aws-lambda-powertools/logger');
const { Metrics, MetricUnits, logMetrics } = require('@aws-lambda-powertools/metrics');
const { Tracer, captureLambdaHandler } = require('@aws-lambda-powertools/tracer');
//const middy = require('@middy/core');
const logger = new Logger({serviceName: 'get-all-items'});
const tracer = new Tracer({ serviceName: 'get-all-items' });
const metrics = new Metrics({ namespace: 'getitems', serviceName: 'get-all-items' });

const AWS = require('aws-sdk')

const docClient = new AWS.DynamoDB.DocumentClient()

exports.getAllItemsHandler = async function (event, context)
    {
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
        // logger.info('Incoming Request:', { event });
        logger.info('Items in list:', { items });
        tracer.putAnnotation('awsRequestId', context.awsRequestId);
        tracer.putAnnotation("segmentplace","Phani");
        tracer.putMetadata('eventPayload', event);  
     
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
      handlerSegment.close();
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

//const handler = middy(getAllItems)
 // .use(captureLambdaHandler(tracer))
 // .use(
  //  logMetrics(metrics, {
//      captureColdStartMetric: true
 //   })
  //)
  //.use(injectLambdaContext(logger));

//module.exports = { handler };

//exports.handler = handler;