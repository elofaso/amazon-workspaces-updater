import csv
import logging
import os
import json
import boto3

ws_client = boto3.client('workspaces')
ssm_client = boto3.client('ssm')
logging.basicConfig(format='%(asctime)s [%(levelname)+8s]%(module)s: %(message)s', datefmt='%Y-%m-%d %H:%M:%S')
logger = logging.getLogger(__name__)
logger.setLevel(getattr(logging, os.getenv('LOG_LEVEL', 'INFO')))

# --- Main handler ---
def lambda_handler(event, context):
    imageId = event['imageId']
    bundleId = ssm_client.get_parameter(Name='/workspaces/linux_bundle_id')['Parameter']['Value']
    response = ws_client.update_workspace_bundle(BundleId=bundleId, ImageId=imageId)
    if response['ResponseMetadata']['HTTPStatusCode'] == 200:
        return {
            'statusCode': 200
        }
