# =========================
# ECS CLUSTER
# =========================
resource "aws_ecs_cluster" "ritual_roast_ecs_cluster" {
  name = "ritual-roast-ecs-cluster"

  tags = {
    Name = "ritual-roast-ecs-cluster"
  }
}

# =========================
# ECS TASK DEFINITION
# =========================
resource "aws_ecs_task_definition" "ritual_roast_task_definition" {
  family                   = "ritual-roast-task-definition"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"

  execution_role_arn = aws_iam_role.ritual_roast_ecs_execution_role.arn
  task_role_arn      = aws_iam_role.ritual_roast_ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "ritualroast"
      image     = "${aws_ecr_repository.ritual_roast.repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "DB_SERVER"
          value = aws_db_instance.ritual_roast_db.address
        },
        {
          name  = "DB_DATABASE"
          value = "ritualroastdb"
        },
        {
          name  = "AWS_REGION"
          value = "us-east-1"
        }
      ]

      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = aws_secretsmanager_secret.ritualroast_db_secret.arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/ritual-roast"
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "ritual-roast-task-definition"
  }
}

# =========================
# ECS SERVICE
# =========================
resource "aws_ecs_service" "ritual_roast_service" {
  name            = "ritual-roast-service"
  cluster         = aws_ecs_cluster.ritual_roast_ecs_cluster.id
  task_definition = aws_ecs_task_definition.ritual_roast_task_definition.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets = [
      aws_subnet.rr_app_subnet_1a.id,
      aws_subnet.rr_app_subnet_1b.id
    ]
    security_groups  = [aws_security_group.rr_app_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ritual_roast_tg.arn
    container_name   = "ritualroast"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener.ritual_roast_https
  ]

  tags = {
    Name = "ritual-roast-service"
  }
}

# =========================
# ECS AUTO SCALING
# =========================
resource "aws_appautoscaling_target" "ecs_service_scaling" {
  service_namespace  = "ecs"
  scalable_dimension = "ecs:service:DesiredCount"
  resource_id        = "service/${aws_ecs_cluster.ritual_roast_ecs_cluster.name}/${aws_ecs_service.ritual_roast_service.name}"

  min_capacity = 1
  max_capacity = 4
}

resource "aws_appautoscaling_policy" "ecs_service_scaling_policy" {
  name               = "ritual-roast-autoscale-ecs"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.ecs_service_scaling.service_namespace
  scalable_dimension = aws_appautoscaling_target.ecs_service_scaling.scalable_dimension
  resource_id        = aws_appautoscaling_target.ecs_service_scaling.resource_id

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 70
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}
