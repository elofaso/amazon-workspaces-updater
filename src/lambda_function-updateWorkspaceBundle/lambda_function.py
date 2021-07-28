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

    try:
        bundleId = ssm_client.get_parameter(Name='/workspaces/linux_bundle_id')['Parameter']['Value']
    except ssm_client.exceptions.ParameterNotFound:
        bundleId = ws_client.create_workspace_bundle(
                                    BundleName = 'linux-configured',
                                    BundleDescription = 'Bundle for live Linux Workspaces',
                                    ImageId = imageId,
                                    ComputeType = {'Name': 'STANDARD'},
                                    UserStorage = {'Capacity': '10'},
                                    RootStorage = {'Capacity': '80'}
        )['WorkspaceBundle']['BundleId']	
        ssm_client.put_parameter(
                           Name = '/workspaces/linux_bundle_id',
                           Description = 'Bundle ID for live Linux Workspaces Bundle',
                           Type = 'String',
                           Value = bundleId  
        )
                              
    response = ws_client.update_workspace_bundle(BundleId=bundleId, ImageId=imageId)
    if response['ResponseMetadata']['HTTPStatusCode'] == 200:
        return {
            'statusCode': 200
        }
