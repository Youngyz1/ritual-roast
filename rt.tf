# =========================================
# 1. Public Route Table (ALB subnets)
# =========================================
resource "aws_route_table" "rr_public_rt" {
  vpc_id = aws_vpc.ritual_roast_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.rr_igw.id
  }

  tags = {
    Name = "rr-public-rt"
  }
}

# Associations for both public subnets
resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.rr_public_subnet_1a.id
  route_table_id = aws_route_table.rr_public_rt.id
}

resource "aws_route_table_association" "public_1b" {
  subnet_id      = aws_subnet.rr_public_subnet_1b.id
  route_table_id = aws_route_table.rr_public_rt.id
}

# =========================================
# 2. App Subnet 1 Route Table (Private with NAT in us-east-1a)
# =========================================
resource "aws_route_table" "rr_app_rt_1a" {
  vpc_id = aws_vpc.ritual_roast_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.rr_nat_1a.id
  }

  tags = {
    Name = "rr-app-rt-1a"
  }
}

resource "aws_route_table_association" "app_1a" {
  subnet_id      = aws_subnet.rr_app_subnet_1a.id
  route_table_id = aws_route_table.rr_app_rt_1a.id
}

# =========================================
# 3. App Subnet 2 Route Table (Private with NAT in us-east-1b)
# =========================================
resource "aws_route_table" "rr_app_rt_1b" {
  vpc_id = aws_vpc.ritual_roast_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.rr_nat_1b.id
  }

  tags = {
    Name = "rr-app-rt-1b"
  }
}

resource "aws_route_table_association" "app_1b" {
  subnet_id      = aws_subnet.rr_app_subnet_1b.id
  route_table_id = aws_route_table.rr_app_rt_1b.id
}

# =========================================
# 4. Data Subnet 1 Route Table (Private with NAT in us-east-1a)
# =========================================
resource "aws_route_table" "rr_data_rt_1a" {
  vpc_id = aws_vpc.ritual_roast_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.rr_nat_1a.id
  }

  tags = {
    Name = "rr-data-rt-1a"
  }
}

resource "aws_route_table_association" "data_1a" {
  subnet_id      = aws_subnet.rr_data_subnet_1a.id
  route_table_id = aws_route_table.rr_data_rt_1a.id
}

# =========================================
# 5. Data Subnet 2 Route Table (Private with NAT in us-east-1b)
# =========================================
resource "aws_route_table" "rr_data_rt_1b" {
  vpc_id = aws_vpc.ritual_roast_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.rr_nat_1b.id
  }

  tags = {
    Name = "rr-data-rt-1b"
  }
}

resource "aws_route_table_association" "data_1b" {
  subnet_id      = aws_subnet.rr_data_subnet_1b.id
  route_table_id = aws_route_table.rr_data_rt_1b.id
}
