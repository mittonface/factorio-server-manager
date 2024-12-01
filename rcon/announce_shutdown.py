import os
import json
import boto3
import factorio_rcon

def lambda_handler(event, context):
    try:
        # Extract instance information from the CloudWatch Event
        detail = event['detail']
        instance_id = detail['instance-id']
        
        # For spot interruption warnings, we don't need to check state
        # The event will only trigger for interruption warnings based on the EventBridge rule
        
        # Get RCON password from Secrets Manager
        secrets_client = boto3.client('secretsmanager')
        secret_response = secrets_client.get_secret_value(
            SecretId=os.environ['FACTORIO_SECRET_ARN']
        )
        secret_data = json.loads(secret_response['SecretString'])
        rcon_password = secret_data['RCON_PASSWORD']
        
        # Connect to Factorio server
        server_host = os.environ['FACTORIO_SERVER_HOST']
        rcon_port = int(os.environ['FACTORIO_RCON_PORT'])
        
        client = factorio_rcon.RCONClient(
            server_host,
            rcon_port,
            rcon_password
        )
        
        # Send warning message and save the game
        client.send_command("Server about to shut down because of spot instance pricing.")
        client.send_command("It will come back online in 2-3 minutes. Find new instance in public server listing.")
        client.send_command("/server-save")
        
        print(f"Successfully handled spot interruption for instance {instance_id}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Successfully handled spot instance termination',
                'instance_id': instance_id
            })
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        }