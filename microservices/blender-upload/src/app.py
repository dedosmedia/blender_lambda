import json
import os
import uuid
import boto3
import logging
import base64
import pathlib

s3_client = boto3.client('s3')

logger = logging.getLogger()
logger.setLevel(logging.INFO)

BUCKET_NAME = os.environ['BUCKET_NAME']
EVENT_DATA_FIELDS = ["file-name", "event-id", "session-id","session-n","session-total", "user-id"]

def validate_event(event):    
    valid_flag = True
    msg = None    
   
    # Check if all data fields are present in the event
    if not all(k in event for k in EVENT_DATA_FIELDS):
        valid_flag = False
        msg = "Invalid input. Missing fields in request"
    
    return (valid_flag, msg)


def put_s3(file_content, path, metadata):
    msg = None
    valid_flag = True

    try:
        msg = s3_client.put_object(Bucket=BUCKET_NAME, Key=path, Body=file_content, Metadata= metadata
        )
        logger.info('S3 Response: {}'.format(msg))
    except Exception as e:
        valid_flag = False
        msg = str(e)
        logger.info('S3 Error : {}'.format(e))
    
    return  (valid_flag, msg)


def handler(event, context):

    logger.info(f'Event: {event}')
    
    # Check if event data is valid
    event_validation, msg = validate_event(event['headers'])

    if event_validation is True:
            
        file_content = base64.b64decode(event['body'])
        file_name = event['headers']['file-name']
        event_id = event['headers']['event-id']
        session_id = event['headers']['session-id']
        session_n = event['headers']['session-n']
        session_total = event['headers']['session-total']
        user_id = event['headers']['user-id']
        

        resource_id = uuid.uuid4()
        response = None
        file_extension = pathlib.Path(file_name).suffix.lower()
        path = f'events/{event_id}/{session_id}/{resource_id}{file_extension}'
        
        metadata = {
            'session-id': str(session_id),
            'event-id': str(event_id),
            'session-n': str(session_n),
            'session-total': str(session_total),
            'user-id': str(user_id)
        }

        # Qué pasa si hay error al subir a S3?
        s3_validation, msg = put_s3(file_content, path, metadata)
        if s3_validation is False:
            response = {
                    'statusCode': 400,
                    'body': msg,
                    'headers': {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*'
                    }
                }
            return(response)

     
        response = {
            'statusCode': 200,
            'body': 'successfully created item!',
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
        }
        return(response)  
    else:
        response = {
                    'statusCode': 400,
                    'body': msg,
                    'headers': {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*'
                    }
                }
        return(response)