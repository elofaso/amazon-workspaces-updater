import json
import os
import logging
import boto3

ws_client = boto3.client('workspaces')
ssm_client = boto3.client('ssm')
logging.basicConfig(format='%(asctime)s [%(levelname)+8s]%(module)s: %(message)s', datefmt='%Y-%m-%d %H:%M:%S')
logger = logging.getLogger(__name__)
logger.setLevel(getattr(logging, os.getenv('LOG_LEVEL', 'INFO')))

# --- Main handler ---
def lambda_handler(event, context):
    directoryIdParameter = event['directoryIdParameter']
    directoryId = ssm_client.get_parameter(Name=directoryIdParameter)['Parameter']['Value']
    response = ws_client.describe_workspaces(DirectoryId=directoryId)
    state = response['Workspaces'][0]['State']
    return {'state': state}
