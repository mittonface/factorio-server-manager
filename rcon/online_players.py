import os
import json
import boto3
import factorio_rcon
from datetime import datetime

def lambda_handler(event, context):
    try:
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
        
        # Check online players
        response = client.send_command("/p o")
        
        # Create status object
        status = {
            'status': response,
            'timestamp': datetime.utcnow().isoformat(),
            'last_updated': datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC')
        }
        
        # Upload to S3
        s3 = boto3.client('s3')
        s3.put_object(
            Bucket=os.environ['STATUS_BUCKET'],
            Key='status.json',
            Body=json.dumps(status),
            ContentType='application/json',
            CacheControl='max-age=60'  # Cache for 1 minute
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Successfully updated status',
                'response': response
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