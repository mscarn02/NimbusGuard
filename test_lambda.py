import sys
import os

sys.path.append(os.path.join(os.path.dirname(__file__), "lambda"))

from src.handlers.s3_healer import lambda_handler

os.environ['DISCORD_WEBHOOK_URL'] = "https://discord.com/api/webhooks/1481963820258820240/9_rElfeai0-C4uneHrffCxTirslHfn4eYLPzPEAG5hUFr2LZ9N84yCAX8hH1EyahvSNv"

test_event = {
    "detail": {
        "requestParameters": {
            "bucketName": "scarn-test-bucket"
        }
    }
}

print(lambda_handler(test_event, None))
