# 1. Identity Check
data "aws_caller_identity" "current" {}

# 2. Package the Python Code
data "archive_file" "sg_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../../lambda"
  output_path = "${path.module}/files/sg_healer.zip"
}

# 3. The IAM Role (Job Description)
resource "aws_iam_role" "sg_healer_role" {
  name = "nimbus_sg_healer_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# 4. The Permissions (Least Privilege)
resource "aws_iam_role_policy" "sg_healer_policy" {
  role = aws_iam_role.sg_healer_role.id
  name = "nimbus_sg_healer_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Permission strictly to revoke rules, NOT to create or delete entire SGs
        Action   = ["ec2:RevokeSecurityGroupIngress"]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        # Logging permissions
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# 5. The Lambda Function
resource "aws_lambda_function" "sg_healer" {
  filename         = data.archive_file.sg_lambda_zip.output_path
  function_name    = "nimbus-sg-healer"
  role             = aws_iam_role.sg_healer_role.arn
  handler          = "src.handlers.sg_healer.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = data.archive_file.sg_lambda_zip.output_base64sha256

  environment {
    variables = {
      DISCORD_WEBHOOK_URL = var.discord_webhook_url
    }
  }
}

# 6. The EventBridge Rule (The Motion Detector)
resource "aws_cloudwatch_event_rule" "sg_ingress_rule" {
  name        = "nimbus_sg_ingress_rule"
  description = "Triggers when a Security Group Ingress rule is added"

  event_pattern = jsonencode({
    "source": ["aws.ec2"],
    "detail-type": ["AWS API Call via CloudTrail"],
    "detail": {
      "eventSource": ["ec2.amazonaws.com"],
      "eventName": ["AuthorizeSecurityGroupIngress"]
    }
  })
}

# 7. The Target Link
resource "aws_cloudwatch_event_target" "sg_healer_target" {
  rule      = aws_cloudwatch_event_rule.sg_ingress_rule.name
  target_id = "SendToSGLambda"
  arn       = aws_lambda_function.sg_healer.arn
}

# 8. The Permission to Wake Up
resource "aws_lambda_permission" "allow_eventbridge_sg" {
  statement_id  = "AllowExecutionFromEventBridgeSG"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sg_healer.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.sg_ingress_rule.arn
}