data "aws_caller_identity" "current" {}

# 1. THE ZIPPER: Lambda requires code to be uploaded as a .zip
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../../lambda" 
  output_path = "${path.module}/files/s3_healer.zip"
}

# 2. THE IDENTITY: The "Job Description" for the Lambda
resource "aws_iam_role" "s3_healer_role" {
  name = "nimbus_s3_healer_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# 3. THE PERMISSIONS: Allowing the Lambda to fix S3 and write logs
resource "aws_iam_role_policy" "s3_healer_policy" {
  role = aws_iam_role.s3_healer_role.id
  name = "nimbus_s3_healer_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Permission to actually "Heal" the bucket
        Action   = ["s3:PutBucketPublicAccessBlock"]
        Effect   = "Allow"
        Resource = "*" 
      },
      {
        # Permission to "talk" to CloudWatch Logs (SOC Visibility)
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# 4. THE BRAIN: The actual Lambda function
resource "aws_lambda_function" "s3_healer" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "nimbus-s3-healer"
  role             = aws_iam_role.s3_healer_role.arn
  handler          = "src.handlers.s3_healer.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      DISCORD_WEBHOOK_URL = var.discord_webhook_url
    }
  }
}

# 1. THE RULE: The "Motion Detector"
resource "aws_cloudwatch_event_rule" "s3_create_bucket_rule" {
  name        = "nimbus_s3_create_bucket_rule"
  description = "Triggers when a new S3 bucket is created"

  event_pattern = jsonencode({
    "source": ["aws.s3"],
    "detail-type": ["AWS API Call via CloudTrail"],
    "detail": {
      "eventSource": ["s3.amazonaws.com"],
      "eventName": ["CreateBucket"]
    }
  })
}

# 2. THE TARGET: Pointing the Rule at our Lambda
resource "aws_cloudwatch_event_target" "s3_healer_target" {
  rule      = aws_cloudwatch_event_rule.s3_create_bucket_rule.name
  target_id = "SendToLambda"
  arn       = aws_lambda_function.s3_healer.arn
}

# 3. THE PERMISSION: Giving EventBridge the "Key" to wake up Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_healer.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3_create_bucket_rule.arn
}

# 1. We need a bucket to store the logs (CloudTrail requirement)
resource "aws_s3_bucket" "nimbus_logs" {
  bucket        = "nimbus-cloudtrail-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = true # Allows terraform to delete it even if it has logs
}

# 2. The CCTV Camera itself
resource "aws_cloudtrail" "nimbus_trail" {
  name                          = "nimbus-security-trail"
  s3_bucket_name                = aws_s3_bucket.nimbus_logs.id
  include_global_service_events = true
  is_multi_region_trail         = false # Stay in one region to stay in Free Tier
  enable_log_file_validation    = true

  event_selector {
    read_write_type           = "WriteOnly"
    include_management_events = true
  }
}

resource "aws_s3_bucket_policy" "nimbus_logs_policy" {
  bucket = aws_s3_bucket.nimbus_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.nimbus_logs.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.nimbus_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      }
    ]
  })
}