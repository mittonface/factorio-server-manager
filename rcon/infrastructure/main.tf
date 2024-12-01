# Lambda Function
resource "aws_lambda_function" "factorio_spot_handler" {
  filename         = "shutdown_lambda_function.zip"
  function_name    = "factorio-spot-termination-handler"
  role            = aws_iam_role.lambda_role.arn
  handler         = "announce_shutdown.lambda_handler"
  runtime         = "python3.9"
  timeout         = 30

  environment {
    variables = {
      FACTORIO_SERVER_HOST  = "factorio.brent.click"
      FACTORIO_RCON_PORT   = "27015"
      FACTORIO_SECRET_ARN  = "arn:aws:secretsmanager:us-east-1:009960124252:secret:factorio-server-credentials-0vrhaq"
    }
  }
}


# Lambda Function for Online Player Check
resource "aws_lambda_function" "factorio_online_check" {
  filename         = "online_players_lambda_function.zip"
  function_name    = "factorio-online-check"
  role            = aws_iam_role.lambda_role.arn
  handler         = "online_players.lambda_handler"
  runtime         = "python3.9"
  timeout         = 30
  source_code_hash = filebase64sha256("shutdown_lambda_function.zip")


  environment {
    variables = {
      FACTORIO_SERVER_HOST  = "factorio.brent.click"
      FACTORIO_RCON_PORT   = "27015"
      FACTORIO_SECRET_ARN  = "arn:aws:secretsmanager:us-east-1:009960124252:secret:factorio-server-credentials-0vrhaq"
      STATUS_BUCKET = aws_s3_bucket.status.id

    }
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "factorio_spot_termination_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# CloudWatch Logs policy for Lambda
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Secrets Manager access policy
resource "aws_iam_role_policy" "secrets_access" {
  name = "secrets_access"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = ["arn:aws:secretsmanager:us-east-1:009960124252:secret:factorio-server-credentials-0vrhaq"]
      }
    ]
  })
}

# EventBridge rule for Spot Instance interruption notices
resource "aws_cloudwatch_event_rule" "spot_interruption" {
  name        = "factorio-spot-interruption"
  description = "Capture Spot Instance interruption notices"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Spot Instance Interruption Warning"]
  })
}

# EventBridge target (Lambda function)
resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.spot_interruption.name
  target_id = "SendToLambda"
  arn       = aws_lambda_function.factorio_spot_handler.arn
}


# EventBridge rule for 1-minute schedule
resource "aws_cloudwatch_event_rule" "one_minute" {
  name                = "every-minute"
  description         = "Trigger every minute"
  schedule_expression = "rate(1 minute)"
}

# EventBridge target
resource "aws_cloudwatch_event_target" "check_online" {
  rule      = aws_cloudwatch_event_rule.one_minute.name
  target_id = "CheckOnlinePlayers"
  arn       = aws_lambda_function.factorio_online_check.arn
}

# Permission for EventBridge to invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.factorio_spot_handler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.spot_interruption.arn
}

# Permission for EventBridge to invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge_online_check" {
  statement_id  = "AllowEventBridgeInvokeOnlineCheck"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.factorio_online_check.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.one_minute.arn
}



# S3 bucket for status
resource "aws_s3_bucket" "status" {
  bucket = "factorio-status-${data.aws_caller_identity.current.account_id}"
}

# Enable versioning
resource "aws_s3_bucket_versioning" "status" {
  bucket = aws_s3_bucket.status.id
  versioning_configuration {
    status = "Enabled"
  }
  depends_on = [aws_s3_bucket.status]
}

# Enable website hosting
resource "aws_s3_bucket_website_configuration" "status" {
  bucket = aws_s3_bucket.status.id

  index_document {
    suffix = "index.html"
  }
  depends_on = [aws_s3_bucket.status]
}

# CORS configuration
resource "aws_s3_bucket_cors_configuration" "status" {
  bucket = aws_s3_bucket.status.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    expose_headers  = []
    max_age_seconds = 3000
  }
  depends_on = [aws_s3_bucket.status]
}

# Public access block
resource "aws_s3_bucket_public_access_block" "status" {
  bucket = aws_s3_bucket.status.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
  depends_on = [aws_s3_bucket.status]
}

# Bucket ownership controls
resource "aws_s3_bucket_ownership_controls" "status" {
  bucket = aws_s3_bucket.status.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
  depends_on = [aws_s3_bucket.status]
}

# Bucket acl
resource "aws_s3_bucket_acl" "status" {
  bucket = aws_s3_bucket.status.id
  acl    = "public-read"
  depends_on = [
    aws_s3_bucket_ownership_controls.status,
    aws_s3_bucket_public_access_block.status,
  ]
}

# Bucket policy
resource "aws_s3_bucket_policy" "status" {
  bucket = aws_s3_bucket.status.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.status.arn}/*"
      },
    ]
  })
  depends_on = [
    aws_s3_bucket.status,
    aws_s3_bucket_public_access_block.status,
    aws_s3_bucket_ownership_controls.status,
  ]
}

# Add S3 permissions to Lambda role
resource "aws_iam_role_policy" "s3_access" {
  name = "s3_access"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = ["${aws_s3_bucket.status.arn}/*"]
      }
    ]
  })
}

# Get current account ID
data "aws_caller_identity" "current" {}

# Output the website URL
output "status_website_url" {
  value = "http://${aws_s3_bucket.status.bucket}.s3-website-${data.aws_region.current.name}.amazonaws.com/status.json"
}

# Get current region
data "aws_region" "current" {}