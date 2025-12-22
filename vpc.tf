# ==========================================
# VPC
# ==========================================
resource "aws_vpc" "ritual_roast_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "ritual-roast-vpc"
  }

  lifecycle {
    prevent_destroy = false # allow destroy
  }
}

# =========================
# Internet Gateway
# =========================
resource "aws_internet_gateway" "rr_igw" {
  vpc_id = aws_vpc.ritual_roast_vpc.id

  tags = {
    Name = "rr-igw"
  }

  lifecycle {
    prevent_destroy = false
  }
}

#========================================================
# Public Subnets
#=======================================================
resource "aws_subnet" "rr_public_subnet_1a" {
  vpc_id                  = aws_vpc.ritual_roast_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "rr-public-subnet1"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_subnet" "rr_public_subnet_1b" {
  vpc_id                  = aws_vpc.ritual_roast_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "rr-public-subnet2"
  }

  lifecycle {
    prevent_destroy = false
  }
}

#========================================================
# App (Private) Subnets
#=======================================================
resource "aws_subnet" "rr_app_subnet_1a" {
  vpc_id            = aws_vpc.ritual_roast_vpc.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "rr-app-subnet1"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_subnet" "rr_app_subnet_1b" {
  vpc_id            = aws_vpc.ritual_roast_vpc.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "rr-app-subnet2"
  }

  lifecycle {
    prevent_destroy = false
  }
}

#========================================================
# Data (Private) Subnets
#=======================================================
resource "aws_subnet" "rr_data_subnet_1a" {
  vpc_id            = aws_vpc.ritual_roast_vpc.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "rr-data-subnet1"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_subnet" "rr_data_subnet_1b" {
  vpc_id            = aws_vpc.ritual_roast_vpc.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "rr-data-subnet2"
  }

  lifecycle {
    prevent_destroy = false
  }
}
