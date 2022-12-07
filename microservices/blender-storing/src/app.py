import json
import os
import uuid
import boto3
import logging
import base64
import pathlib

ddb_client = boto3.client('dynamodb')
sts = boto3.client('sts')
s3_client = boto3.client('s3')

logger = logging.getLogger()
logger.setLevel(logging.INFO)

BUCKET_NAME = os.environ['BUCKET_NAME']
DYNAMODB_TABLE_NAME = os.environ.get("DYNAMODB_TABLE_NAME")
EVENT_DATA_FIELDS = ["file-name", "event-id", "session-id"]


def validate_event(event):
    print(event)
    valid_flag = True
    msg = None
    
   
    # Check if all data fields are present in the event
    if not all(k in event for k in EVENT_DATA_FIELDS):
        valid_flag = False
        msg = "Invalid input"
    
    return (valid_flag, msg)


def save_to_ddb(ddb_payload):
    
    return ddb_client.put_item(
        TableName=DYNAMODB_TABLE_NAME,
        Item=ddb_payload
    )


def handler_s3(event, context):

    print(event)
    
    # Check if event data is valid
    event_validation, msg = validate_event(event['headers'])

    if event_validation is True:
            
        file_name = event['headers']['file-name']
        file_content = base64.b64decode(event['body'])
        event_id = event['headers']['event-id']
        session_id = event['headers']['session-id']
        response = None

        resource_id = uuid.uuid4()
        file_extension = pathlib.Path(file_name).suffix.lower()
        path = f'events/{event_id}/{session_id}/{resource_id}{file_extension}'
        

        # TODO:  Qué pasa si es duplicado el uuid?
        
        ddb_payload = {
                    'ResourceId': {
                        'S': str(resource_id)
                    },
                    'Path': {
                        'S': path
                    },
                    'EventId': {
                        'S': event_id
                    },
                    'SessionId': {
                        'S': session_id
                    },
                    'FileType': {
                        'S': file_extension
                    }
                }
        data = save_to_ddb(ddb_payload)

        try:
            s3_response = s3_client.put_object(Bucket=BUCKET_NAME, Key=path, Body=file_content)
            logger.info('S3 Response: {}'.format(s3_response))

            response  = {
                'statusCode': 200,
                'headers': {
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Credentials': 'true'
                },
                'body': ''
            }

            response['body'] = 'Your file has been uploaded'
            return response

        except Exception as e:
            raise IOError(e)   
    else:
        response = {
                    'statusCode': 400,
                    'body': msg,
                    'headers': {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*'
                    }
                }