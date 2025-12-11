# ==========================================================
# Provider
# ==========================================================
provider "aws" {
  region = var.region
}

# ==========================================================
# VPC Module
# ==========================================================
module "network" {
  source = "terraform-aws-modules/vpc/aws"

  name = "ritual-roast-vpc"
  cidr = var.vpc_cidr
  azs  = var.azs

  public_subnets   = var.public_subnets
  private_subnets  = var.app_subnets
  database_subnets = var.data_subnets

  enable_nat_gateway = true
  single_nat_gateway = false

  tags = {
    Project = "ritual-roast"
  }
}

# ==========================================================
# Security Groups
# ==========================================================

# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name        = "ritual-roast-alb-sg"
  description = "Security group for ALB"
  vpc_id      = module.network.vpc_id

  ingress {
    description = "Allow HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS Task Security Group
resource "aws_security_group" "ecs_sg" {
  name        = "ritual-roast-ecs-sg"
  description = "ECS tasks SG"
  vpc_id      = module.network.vpc_id

  ingress {
    description     = "ALB_to_ECS"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ==========================================================
# ECS Cluster
# ==========================================================
resource "aws_ecs_cluster" "this" {
  name = "ritual-roast-cluster"
}

# ==========================================================
# IAM: ECS Task Execution Role
# ==========================================================
resource "aws_iam_role" "ecs_execution_role" {
  name               = "ritual-roast-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution_attach" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_extra_permissions" {
  name = "ritual-roast-extra-exec-policy"
  role = aws_iam_role.ecs_execution_role.id

  policy = data.aws_iam_policy_document.ecs_extra.json
}

data "aws_iam_policy_document" "ecs_extra" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "kms:Decrypt"
    ]
    resources = ["*"]
  }
}

# ==========================================================
# CloudWatch Logs
# ==========================================================
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/ritual-roast"
  retention_in_days = 14
}

# ==========================================================
# ECR Repository
# ==========================================================
resource "aws_ecr_repository" "app" {
  name = "ritual-roast"
  image_scanning_configuration { scan_on_push = true }
}

# ==========================================================
# RDS MySQL
# ==========================================================
resource "aws_db_subnet_group" "db_subnet" {
  name       = "ritual-roast-db-subnet-group"
  subnet_ids = module.network.database_subnets
}

resource "aws_db_instance" "mysql" {
  identifier           = "ritual-roast-mysql"
  engine               = "mysql"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  username             = var.db_username
  password             = random_password.db_password.result
  db_subnet_group_name = aws_db_subnet_group.db_subnet.name
  multi_az             = true
  publicly_accessible  = false
  skip_final_snapshot  = true
}

# ==========================================================
# Load Balancer
# ==========================================================
resource "aws_lb" "app" {
  name               = "ritual-roast-alb"
  load_balancer_type = "application"
  subnets            = module.network.public_subnets
  security_groups    = [aws_security_group.alb_sg.id]
}

resource "aws_lb_target_group" "app_tg" {
  name        = "ritual-roast-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.network.vpc_id
  target_type = "ip"
}

resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# ==========================================================
# ECS Task Definition
# ==========================================================
resource "aws_ecs_task_definition" "app" {
  family                   = "ritual-roast-task"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "ritual-roast-container"
      image     = "${aws_ecr_repository.app.repository_url}:latest"
      essential = true
      portMappings = [
        { containerPort = 80 }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_logs.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
      environment = [
        { name = "DB_HOST", value = aws_db_instance.mysql.address }
      ]
      secrets = [
        {
          name      = "DB_CREDENTIALS"
          valueFrom = aws_secretsmanager_secret.db.arn
        }
      ]
    }
  ])
}

# ==========================================================
# ECS Service with Autoscaling
# ==========================================================
resource "aws_ecs_service" "app" {
  name            = "ritual-roast-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.app.arn
  launch_type     = "FARGATE"

  desired_count = 2

  network_configuration {
    subnets          = module.network.private_subnets
    assign_public_ip = false
    security_groups  = [aws_security_group.ecs_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "ritual-roast-container"
    container_port   = 80
  }
}

# Autoscaling
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 4
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu_policy" {
  name               = "ritual-roast-cpu-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 60
  }
}
