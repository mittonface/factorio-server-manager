import os
import json
import boto3
import factorio_rcon

def lambda_handler(event, context):
    # Extract instance information from the CloudWatch Event
    try:
        detail = event['detail']
        instance_id = detail['instance-id']
        state = detail['state']
        
        # Only proceed if this is a termination notice
        if state != 'interrupted':
            print(f"Not a termination event. State: {state}")
            return {
                'statusCode': 200,
                'body': 'Not a termination event'
            }
        
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
        client.send_command("Server about to shut down because of spot instance pricing")
        client.send_command("/server-save")
        
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