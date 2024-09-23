import boto3
from botocore.exceptions import ClientError
import json

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('VisitorCounter')


def lambda_handler(event, context):
    counter_id = 'counter1'

    try:
        # Increment the counter
        response = table.update_item(
            Key={'CounterID': counter_id},
            UpdateExpression='SET visitor_count = if_not_exists(visitor_count, :start) + :inc',
            ExpressionAttributeValues={
                ':inc': 1,
                ':start': 0
            },
            ReturnValues='UPDATED_NEW'
        )

        # Get the updated counter value and convert to float
        visitor_count = float(response['Attributes']['visitor_count'])

        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': 'https://almonge-resume.com',
                'Access-Control-Allow-Headers': 'Content-Type'
            },
            'body': json.dumps({
                'visitor_count': visitor_count
            })
        }

    except ClientError as e:
        print(e.response['Error']['Message'])
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Origin': 'https://almonge-resume.com',
                'Access-Control-Allow-Headers': 'Content-Type'
            },
            'body': json.dumps({
                'error': 'Error updating visitor count'
            })
        }
