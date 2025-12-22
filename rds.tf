# =========================
# RDS DB Subnet Group
# =========================
resource "aws_db_subnet_group" "ritual_roast_db_subnet_group" {
  name       = "ritual-roast-db-subnet-group"

  # Ensure these subnets belong to the same VPC
  subnet_ids = [
    aws_subnet.rr_data_subnet_1a.id,  # us-east-1a
    aws_subnet.rr_data_subnet_1b.id   # us-east-1b
  ]

  description = "DB Subnet Group for ritual-roast MySQL instance"

  tags = {
    Name = "ritual-roast-db-subnet-group"
  }
}

# =========================
# RDS MySQL Database Instance
# =========================
resource "aws_db_instance" "ritual_roast_db" {
  identifier        = "ritualroastdb"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  db_name           = "ritualroastdb"

  username = "admin"
  password = "youngyz@123"
  port     = 3306

  publicly_accessible = false
  multi_az            = false

  vpc_security_group_ids = [aws_security_group.rr_data_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.ritual_roast_db_subnet_group.name

  storage_encrypted = false      # optional
  auto_minor_version_upgrade = true

  tags = {
    Name = "ritual-roast-db"
    App  = "ritual-roast"
  }

  lifecycle {
    prevent_destroy = false
  }

  depends_on = [
    aws_db_subnet_group.ritual_roast_db_subnet_group,
    aws_security_group.rr_data_sg
  ]
}
