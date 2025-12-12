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

  tags = {
    Project = "ritual-roast"
  }
}

# ECS Task Security Group
resource "aws_security_group" "ecs_sg" {
  name        = "ritual-roast-ecs-sg"
  description = "ECS tasks SG"
  vpc_id      = module.network.vpc_id

  ingress {
    description     = "ALB to ECS"
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

  tags = {
    Project = "ritual-roast"
  }
}

# ==========================================================
# ECS Cluster
# ==========================================================
resource "aws_ecs_cluster" "this" {
  name = "ritual-roast-cluster"

  tags = {
    Project = "ritual-roast"
  }
}

# ==========================================================
# CloudWatch Logs
# ==========================================================
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/ritual-roast"
  retention_in_days = 14

  tags = {
    Project = "ritual-roast"
  }
}

# ==========================================================
# RDS MySQL
# ==========================================================
resource "aws_db_subnet_group" "db_subnet" {
  name       = "ritual-roast-db-subnet-group"
  subnet_ids = module.network.database_subnets

  tags = {
    Project = "ritual-roast"
  }
}

resource "random_password" "db_password" {
  length  = 16
  special = true
}

resource "aws_db_instance" "mysql" {
  identifier           = "ritual-roast-mysql"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  username             = var.db_username
  password             = random_password.db_password.result
  db_subnet_group_name = aws_db_subnet_group.db_subnet.name
  multi_az             = true
  publicly_accessible  = false
  skip_final_snapshot  = true

  tags = {
    Project = "ritual-roast"
  }
}

# ==========================================================
# Load Balancer
# ==========================================================
resource "aws_lb" "app" {
  name               = "ritual-roast-alb"
  load_balancer_type = "application"
  subnets            = module.network.public_subnets
  security_groups    = [aws_security_group.alb_sg.id]

  tags = {
    Project = "ritual-roast"
  }
}

resource "aws_lb_target_group" "app_tg" {
  name        = "ritual-roast-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.network.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }

  tags = {
    Project = "ritual-roast"
  }
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
