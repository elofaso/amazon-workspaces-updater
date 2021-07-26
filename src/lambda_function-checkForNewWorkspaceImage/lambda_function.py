import json
import os
import logging
import boto3
import datetime
from dateutil import tz

ws_client = boto3.client('workspaces')
logging.basicConfig(format='%(asctime)s [%(levelname)+8s]%(module)s: %(message)s', datefmt='%Y-%m-%d %H:%M:%S')
logger = logging.getLogger(__name__)
logger.setLevel(getattr(logging, os.getenv('LOG_LEVEL', 'INFO')))

def lambda_handler(event, context):
    configurationCompletionDateTime = datetime.datetime.fromisoformat(event['configurationCompletionDateTime'])
    
    logger.error("configurationCompletionDateTime = %s" % configurationCompletionDateTime)

    response = ws_client.describe_workspace_images()

    images = response['Images']

    images = [image for image in images if image['OperatingSystem']['Type'] == 'LINUX' and image['State'] == 'AVAILABLE' and image['Created'] > configurationCompletionDateTime - datetime.timedelta(hours=3)]

    images.sort(key=lambda k: k['Created'], reverse=True)
    
    try:
        imageId = images[0]['ImageId']
    except IndexError:
        return {
            'statusCode' : 400,
            'configurationCompletionDateTime' : datetime.datetime.isoformat(configurationCompletionDateTime)
        }
    else:
        return {
            'statusCode': 200,
            'imageId' : imageId
        }

