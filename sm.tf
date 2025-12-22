# =========================
# AWS Secrets Manager
# =========================

resource "aws_secretsmanager_secret" "ritualroast_db_secret" {
  name        = "ritualroast-db-secret"
  description = "RDS Database credentials for ritual-roast"

  tags = {
    Name = "ritual-roast-secret-rotation"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_secretsmanager_secret_version" "ritualroast_db_secret_version" {
  secret_id = aws_secretsmanager_secret.ritualroast_db_secret.id

  secret_string = jsonencode({
    username = "admin"
    password = "Youngyz123!" # ✅ Updated to valid password
  })
}

# =========================
# Secret Rotation
# =========================

resource "aws_secretsmanager_secret_rotation" "ritualroast_db_secret_rotation" {
  secret_id           = aws_secretsmanager_secret.ritualroast_db_secret.id
  rotation_lambda_arn = aws_lambda_function.secret_rotation_lambda.arn

  rotation_rules {
    automatically_after_days = 7
  }
}

# =========================
# Lambda Function
# =========================

resource "aws_lambda_function" "secret_rotation_lambda" {
  function_name = "ritualroast-db-secret-rotation-lambda"

  filename         = "${path.module}/lambda/rotation.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/rotation.zip")

  runtime = "python3.8"
  handler = "index.handler"
  role    = aws_iam_role.secret_rotation_role.arn
}

# =========================
# Random ID for Lambda Permission
# =========================

resource "random_id" "lambda_suffix" {
  byte_length = 4
}

# =========================
# Lambda Permission for Secrets Manager
# =========================

resource "aws_lambda_permission" "allow_secretsmanager" {
  statement_id  = "AllowExecutionFromSecretsManager-${random_id.lambda_suffix.hex}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.secret_rotation_lambda.function_name
  principal     = "secretsmanager.amazonaws.com"
}

# =========================
# IAM Role
# =========================

resource "aws_iam_role" "secret_rotation_role" {
  name = "secret_rotation_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "secret_rotation_policy" {
  name        = "secret_rotation_policy"
  description = "Policy for Lambda to rotate secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue"
        ]
        Resource = aws_secretsmanager_secret.ritualroast_db_secret.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "secret_rotation_policy_attachment" {
  role       = aws_iam_role.secret_rotation_role.name
  policy_arn = aws_iam_policy.secret_rotation_policy.arn
}
