# ==========================================================
# ECS Task Definition
# ==========================================================
resource "aws_ecs_task_definition" "ritual_task" {
  family                   = "ritual-roast-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.ecs_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "ritual-web"
    image     = "${aws_ecr_repository.ritual.repository_url}:latest"
    essential = true

    portMappings = [{
      containerPort = 80
      protocol      = "tcp"
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs_logs.name
        awslogs-region        = var.region
        awslogs-stream-prefix = "ritual"
      }
    }

    environment = [
      { name = "DB_HOST",    value = aws_db_instance.mysql.address },
      { name = "DB_NAME",    value = "ritualdb" },
      { name = "AWS_REGION", value = var.region }
    ]

    secrets = [
      {
        name      = "DB_USERNAME"
        valueFrom = "${aws_secretsmanager_secret_version.db_version.arn}:username"
      },
      {
        name      = "DB_PASSWORD"
        valueFrom = "${aws_secretsmanager_secret_version.db_version.arn}:password"
      }
    ]
  }])
}

# ==========================================================
# ECS Service
# ==========================================================
resource "aws_ecs_service" "ritual_service" {
  name            = "ritual-roast-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.ritual_task.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.network.private_subnets
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "ritual-web"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener.app_listener,
    aws_cloudwatch_log_group.ecs_logs,
    aws_ecr_repository.ritual
  ]
}
