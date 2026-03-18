import boto3
import json
import os
from src.utils.notifier import send_discord_notification

s3_client = boto3.client('s3')
WEBHOOK_URL = os.environ.get('DISCORD_WEBHOOK_URL')


def lambda_handler(event, context):

    try:
        bucket_name = event['detail']['requestParameters']['bucketName']
        print(f"Analysing bucket: {bucket_name}")

        s3_client.put_public_access_block(
            Bucket=bucket_name,
            PublicAccessBlockConfiguration={
                'BlockPublicAcls': True,
                'IgnorePublicAcls': True,
                'BlockPublicPolicy': True,
                'RestrictPublicBuckets': True
            }
        )

        msg = f"🛡️ **Nimbus-Cloud Remediation**\n**Resource:** {bucket_name}\n**Action:** Applied 'Block Public Access'\n**Status:** SECURED"

        send_discord_notification(WEBHOOK_URL, msg)

        return {
            'statusCode': 200,
            'body': json.dumps(f'Successfully secured {bucket_name}')
        }

    except Exception as e:

        error_msg = f"Error remediating {bucket_name}: {str(e)}"
        print(error_msg)

        send_discord_notification(WEBHOOK_URL, error_msg)

        raise e