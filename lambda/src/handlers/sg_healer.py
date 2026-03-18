import boto3
import os
from src.utils.notifier import send_discord_notification

ec2_client = boto3.client('ec2')
WEBHOOK_URL = os.environ.get('DISCORD_WEBHOOK_URL')

def lambda_handler(event, context):
    try:
        details = event['detail']['requestParameters']
        sg_id = details.get('groupId')
        
        ip_permissions = details.get('ipPermissions', {}).get('items', [])
        
        bad_rules = []
        
        for rule in ip_permissions:
            from_port = rule.get('fromPort')
            to_port = rule.get('toPort')
            ip_protocol = rule.get('ipProtocol')
            ip_ranges = rule.get('ipRanges', {}).get('items', [])
            
            if from_port in [22, 3389] or to_port in [22, 3389]:
                for ip_range in ip_ranges:
                    if ip_range.get('cidrIp') == '0.0.0.0/0':
                        
                        boto3_formatted_rule = {
                            'IpProtocol': ip_protocol,
                            'FromPort': int(from_port),
                            'ToPort': int(to_port),
                            'IpRanges': [{'CidrIp': '0.0.0.0/0'}]
                        }
                        
                        bad_rules.append(boto3_formatted_rule)
                        break 
                        
        if bad_rules:
            print(f"🚨 Critical vulnerability detected in SG: {sg_id}. Revoking...")
            
            
            ec2_client.revoke_security_group_ingress(
                GroupId=sg_id,
                IpPermissions=bad_rules
            )
            
            
            msg = f"🛡️ **Nimbus Remediation**\n**Resource:** {sg_id}\n**Action:** Revoked public access (0.0.0.0/0) on Port {bad_rules[0].get('FromPort')}\n**Status:** SECURED"
            send_discord_notification(WEBHOOK_URL, msg)
            
            return {"statusCode": 200, "body": f"Healed SG {sg_id}"}
        
        return {"statusCode": 200, "body": "No action needed."}

    except Exception as e:
        error_msg = f"❌ Error fixing SG: {str(e)}"
        print(error_msg)
        send_discord_notification(WEBHOOK_URL, error_msg)
        raise e