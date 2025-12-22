#=========================================================
# ALB Security Group
#=========================================================
resource "aws_security_group" "rr_alb_sg" {
  name        = "rr-alb-sg"
  description = "Allow HTTP and HTTPS from the internet"
  vpc_id      = aws_vpc.ritual_roast_vpc.id

  # HTTP (for redirect to HTTPS)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS (ACM / SSL)
  ingress {
    from_port   = 443
    to_port     = 443
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
    Name = "rr-alb-sg"
  }
}

#========================================================
# App Security Group
#========================================================
resource "aws_security_group" "rr_app_sg" {
  name        = "rr-app-sg"
  description = "Allow HTTP from ALB only"
  vpc_id      = aws_vpc.ritual_roast_vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.rr_alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rr-app-sg"
  }
}

#================================================================
# Data / RDS Security Group
#================================================================
resource "aws_security_group" "rr_data_sg" {
  name        = "rr-data-sg"
  description = "Allow MySQL from app tier"
  vpc_id      = aws_vpc.ritual_roast_vpc.id

  # App → DB
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.rr_app_sg.id]
  }

  # DB → DB (replication / failover)
  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rr-data-sg"
  }
}
