import sys
import os

sys.path.append(os.path.join(os.path.dirname(__file__), "lambda"))

from src.handlers.s3_healer import lambda_handler

os.environ['DISCORD_WEBHOOK_URL'] = #YOUR URL HERE

test_event = {
    "detail": {
        "requestParameters": {
            "bucketName": " " #input your bucket name here
        }
    }
}

print(lambda_handler(test_event, None))
