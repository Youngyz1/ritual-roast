# =========================
# RDS MySQL Database Instance
# =========================

resource "aws_db_instance" "ritual_roast_db" {
  identifier        = "ritual-roast-db"
  engine            = "mysql"
  engine_version    = "8.0"           # You can choose the version that suits your need
  instance_class    = "db.t3.micro"   # Adjust the instance size as needed
  allocated_storage = 20              # Size in GB
  db_name           = "ritualroastdb" # Initial DB name

  username            = "admin"      # The master username
  password            = "youngyz123" # The master password (will be managed by Secrets Manager)
  port                = 3306
  multi_az            = false # Set true if you want Multi-AZ deployment
  publicly_accessible = false # Adjust based on your security requirements

  vpc_security_group_ids = [aws_security_group.rr_data_sg.id] # Reference to the security group for data access
  db_subnet_group_name   = aws_db_subnet_group.ritual_roast_subnet_group.id

  tags = {
    Name = "ritual-roast-db"
    App  = "ritual-roast"
  }

  lifecycle {
    prevent_destroy = false
  }

  depends_on = [
    aws_db_subnet_group.ritual_roast_subnet_group,
    aws_security_group.rr_data_sg
  ]
}

# DB Subnet Group (ensure RDS is placed in the right subnets)
resource "aws_db_subnet_group" "ritual_roast_subnet_group" {
  name       = "ritual-roast-subnet-group"
  subnet_ids = [aws_subnet.rr_data_subnet_1a.id, aws_subnet.rr_data_subnet_1b.id]

  tags = {
    Name = "ritual-roast-subnet-group"
  }
}
