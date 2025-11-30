# IAM Role for Lambda Execution
resource "aws_iam_role" "lambda_execution" {
  name = "${var.project_name}-lambda-execution-role"

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

  tags = {
    Name = "${var.project_name}-lambda-execution-role"
  }
}

# Attach AWS managed policy for VPC execution
resource "aws_iam_role_policy_attachment" "lambda_vpc_execution" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Attach AWS managed policy for basic Lambda execution
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Custom policy for Lambda to access Secrets Manager
resource "aws_iam_role_policy" "lambda_secrets_access" {
  name = "${var.project_name}-lambda-secrets-policy"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.db_credentials.arn
      }
    ]
  })
}

# Custom policy for Lambda to access S3
resource "aws_iam_role_policy" "lambda_s3_access" {
  name = "${var.project_name}-lambda-s3-policy"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.attachments.arn,
          "${aws_s3_bucket.attachments.arn}/*"
        ]
      }
    ]
  })
}

# CloudWatch Log Group for Lambda functions
resource "aws_cloudwatch_log_group" "lambda_notes" {
  name              = "/aws/lambda/${var.project_name}-notes-api"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-lambda-notes-logs"
  }
}

# Lambda Layer for shared dependencies (pg, aws-sdk, etc.)
resource "aws_lambda_layer_version" "dependencies" {
  filename            = "${path.module}/../backend/layers/dependencies.zip"
  layer_name          = "${var.project_name}-dependencies"
  compatible_runtimes = ["nodejs20.x"]
  description         = "Shared dependencies for Lambda functions"

  lifecycle {
    create_before_destroy = true
  }
}

# Lambda Function - Get Notes
resource "aws_lambda_function" "get_notes" {
  filename      = "${path.module}/../backend/dist/get-notes.zip"
  function_name = "${var.project_name}-get-notes"
  role          = aws_iam_role.lambda_execution.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 30
  memory_size   = 512

  source_code_hash = fileexists("${path.module}/../backend/dist/get-notes.zip") ? filebase64sha256("${path.module}/../backend/dist/get-notes.zip") : null

  layers = [aws_lambda_layer_version.dependencies.arn]

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DB_SECRET_ARN       = aws_secretsmanager_secret.db_credentials.arn
      ATTACHMENTS_BUCKET  = aws_s3_bucket.attachments.bucket
      NODE_ENV            = var.environment
    }
  }

  tags = {
    Name = "${var.project_name}-get-notes"
  }

  lifecycle {
    ignore_changes = [source_code_hash]
  }
}

# Lambda Function - Create Note
resource "aws_lambda_function" "create_note" {
  filename      = "${path.module}/../backend/dist/create-note.zip"
  function_name = "${var.project_name}-create-note"
  role          = aws_iam_role.lambda_execution.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 30
  memory_size   = 512

  source_code_hash = fileexists("${path.module}/../backend/dist/create-note.zip") ? filebase64sha256("${path.module}/../backend/dist/create-note.zip") : null

  layers = [aws_lambda_layer_version.dependencies.arn]

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DB_SECRET_ARN       = aws_secretsmanager_secret.db_credentials.arn
      ATTACHMENTS_BUCKET  = aws_s3_bucket.attachments.bucket
      NODE_ENV            = var.environment
    }
  }

  tags = {
    Name = "${var.project_name}-create-note"
  }

  lifecycle {
    ignore_changes = [source_code_hash]
  }
}

# Lambda Function - Update Note
resource "aws_lambda_function" "update_note" {
  filename      = "${path.module}/../backend/dist/update-note.zip"
  function_name = "${var.project_name}-update-note"
  role          = aws_iam_role.lambda_execution.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 30
  memory_size   = 512

  source_code_hash = fileexists("${path.module}/../backend/dist/update-note.zip") ? filebase64sha256("${path.module}/../backend/dist/update-note.zip") : null

  layers = [aws_lambda_layer_version.dependencies.arn]

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DB_SECRET_ARN       = aws_secretsmanager_secret.db_credentials.arn
      ATTACHMENTS_BUCKET  = aws_s3_bucket.attachments.bucket
      NODE_ENV            = var.environment
    }
  }

  tags = {
    Name = "${var.project_name}-update-note"
  }

  lifecycle {
    ignore_changes = [source_code_hash]
  }
}

# Lambda Function - Delete Note
resource "aws_lambda_function" "delete_note" {
  filename      = "${path.module}/../backend/dist/delete-note.zip"
  function_name = "${var.project_name}-delete-note"
  role          = aws_iam_role.lambda_execution.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 30
  memory_size   = 512

  source_code_hash = fileexists("${path.module}/../backend/dist/delete-note.zip") ? filebase64sha256("${path.module}/../backend/dist/delete-note.zip") : null

  layers = [aws_lambda_layer_version.dependencies.arn]

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DB_SECRET_ARN       = aws_secretsmanager_secret.db_credentials.arn
      ATTACHMENTS_BUCKET  = aws_s3_bucket.attachments.bucket
      NODE_ENV            = var.environment
    }
  }

  tags = {
    Name = "${var.project_name}-delete-note"
  }

  lifecycle {
    ignore_changes = [source_code_hash]
  }
}
