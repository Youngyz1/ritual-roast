# =========================================
# Public Route Table (ALB)
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

# Public Subnet Associations
resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.rr_public_subnet_1a.id
  route_table_id = aws_route_table.rr_public_rt.id
}

resource "aws_route_table_association" "public_1b" {
  subnet_id      = aws_subnet.rr_public_subnet_1b.id
  route_table_id = aws_route_table.rr_public_rt.id
}

# =========================================
# App Subnet Route Table (Private with NAT)
# =========================================
resource "aws_route_table" "rr_app_rt" {
  vpc_id = aws_vpc.ritual_roast_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.rr_nat_1a.id
  }

  tags = {
    Name = "rr-app-rt"
  }
}

# App Subnet Associations
resource "aws_route_table_association" "app_1a" {
  subnet_id      = aws_subnet.rr_app_subnet_1a.id
  route_table_id = aws_route_table.rr_app_rt.id
}

resource "aws_route_table_association" "app_1b" {
  subnet_id      = aws_subnet.rr_app_subnet_1b.id
  route_table_id = aws_route_table.rr_app_rt.id
}

# =========================================
# Data Subnet Route Table (Private - NO Internet)
# =========================================
resource "aws_route_table" "rr_data_rt" {
  vpc_id = aws_vpc.ritual_roast_vpc.id

  # IMPORTANT:
  # No 0.0.0.0/0 route
  # Only local VPC traffic is allowed

  tags = {
    Name = "rr-data-rt"
  }
}

# Data Subnet Associations
resource "aws_route_table_association" "data_1a" {
  subnet_id      = aws_subnet.rr_data_subnet_1a.id
  route_table_id = aws_route_table.rr_data_rt.id
}

resource "aws_route_table_association" "data_1b" {
  subnet_id      = aws_subnet.rr_data_subnet_1b.id
  route_table_id = aws_route_table.rr_data_rt.id
}
