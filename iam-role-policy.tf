#IAM Policy
resource "aws_iam_policy" "ritual_roast_allow_read_db_secret_policy" {
  name        = "ritual-roast-allow-read-db-secret-policy"
  description = "Allow ECS tasks to read DB secret"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:ritualroast-db-secret-*"
      }
    ]
  })
}

#ECS TASK ROLE
resource "aws_iam_role" "ritual_roast_ecs_task_role" {
  name = "ritual-roast-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_read_secret" {
  role       = aws_iam_role.ritual_roast_ecs_task_role.name
  policy_arn = aws_iam_policy.ritual_roast_allow_read_db_secret_policy.arn
}

#ECS EXECUTION ROLE
resource "aws_iam_role" "ritual_roast_ecs_execution_role" {
  name = "ritual-roast-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ritual_roast_ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
