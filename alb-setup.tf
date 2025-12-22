# ========================
# Application Load Balancer Target Group
# ========================

resource "aws_lb_target_group" "ritual_roast_tg" {
  name        = "ritual-roast"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.ritual_roast_vpc.id
  target_type = "ip" # ⚠️ REQUIRED for Fargate + awsvpc

  health_check {
    path                = "/health.html"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 2
    port                = "traffic-port"
    matcher             = "200"
  }

  ip_address_type  = "ipv4"
  protocol_version = "HTTP1"

  tags = {
    Name = "ritual-roast-target-group"
  }
}

# =========================
# Application Load Balancer
# =========================

resource "aws_lb" "ritual_roast_alb" {
  name               = "ritual-roast-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.rr_alb_sg.id]
  subnets = [
    aws_subnet.rr_public_subnet_1a.id,
    aws_subnet.rr_public_subnet_1b.id
  ]

  enable_deletion_protection = false

  tags = {
    Name = "ritual-roast-alb"
    App  = "ritual-roast"
  }
}
