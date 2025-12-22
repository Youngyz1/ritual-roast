#========================================================
# NAT Gateways
#========================================================

# EIP for NAT in 1a
resource "aws_eip" "rr_nat_eip_1a" {
  domain = "vpc" # Updated from vpc = true to domain = "vpc"
}

# NAT in 1a
resource "aws_nat_gateway" "rr_nat_1a" {
  allocation_id = aws_eip.rr_nat_eip_1a.id
  subnet_id     = aws_subnet.rr_public_subnet_1a.id

  tags = {
    Name = "rr-nat-1a"
  }

  depends_on = [
    aws_internet_gateway.rr_igw,
  ]
}

# EIP for NAT in 1b
resource "aws_eip" "rr_nat_eip_1b" {
  domain = "vpc" # Updated from vpc = true to domain = "vpc"
}

# NAT in 1b
resource "aws_nat_gateway" "rr_nat_1b" {
  allocation_id = aws_eip.rr_nat_eip_1b.id
  subnet_id     = aws_subnet.rr_public_subnet_1b.id

  tags = {
    Name = "rr-nat-1b"
  }

  depends_on = [
    aws_internet_gateway.rr_igw,
  ]
}
