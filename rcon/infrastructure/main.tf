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

# Permission for EventBridge to invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.factorio_spot_handler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.spot_interruption.arn
}