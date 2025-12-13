# ==========================================================
# ECR Repository
# ==========================================================
resource "aws_ecr_repository" "ritual" {
  name = "ritual-roast"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project = "ritual-roast"
  }
}

# ==========================================================
# IAM Roles (Execution + Task)
# ==========================================================
resource "aws_iam_role" "ecs_execution_role" {
  name = "ritual-roast-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_default" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "ritual-roast-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# ==========================================================
# IAM Policy for ECS Tasks to read Secrets Manager
# ==========================================================
resource "aws_iam_policy" "ecs_secrets_policy" {
  name = "ritual-roast-ecs-secrets-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue","kms:Decrypt"]
      Resource = aws_secretsmanager_secret_version.db_version.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_secrets_attach" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_secrets_policy.arn
}

# ==========================================================
# Secrets Manager (DB credentials) using GitHub Actions variable
# ==========================================================
resource "aws_secretsmanager_secret" "db" {
  name        = "ritual-roast-db-credentials-${var.env}"
  description = "RDS credentials for ritual-roast (${var.env})"

  tags = {
    Project = "ritual-roast"
    Env     = var.env
  }
}

resource "aws_secretsmanager_secret_version" "db_version" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
  })
}

# ==========================================================
# Output
# ==========================================================
output "secretsmanager_db_secret_arn" {
  value       = aws_secretsmanager_secret.db.arn
  description = "ARN of the Secrets Manager secret"
}
