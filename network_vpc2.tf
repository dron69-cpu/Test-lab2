##############################
# VPC and Subnets
##############################

resource "aws_vpc" "vpc_secondary" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "secondary-vpc"
  }
}

resource "aws_internet_gateway" "igw_secondary" {
  vpc_id = aws_vpc.vpc_secondary.id

  tags = {
    Name = "secondary-igw"
  }
}

# Public Subnet
resource "aws_subnet" "public_subnet_secondary" {
  vpc_id                  = aws_vpc.vpc_secondary.id
  cidr_block              = "10.1.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "secondary-public-subnet"
  }
}

# Private Subnet
resource "aws_subnet" "private_subnet_secondary" {
  vpc_id            = aws_vpc.vpc_secondary.id
  cidr_block        = "10.1.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "secondary-private-subnet"
  }
}


# Public Route Table
resource "aws_route_table" "public_rt_secondary" {
  vpc_id = aws_vpc.vpc_secondary.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_secondary.id
  }

  tags = {
    Name = "secondary-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc_secondary" {
  subnet_id      = aws_subnet.public_subnet_secondary.id
  route_table_id = aws_route_table.public_rt_secondary.id
}

# Private Route Table (TGW route added in tgw.tf)
resource "aws_route_table" "private_rt_secondary" {
  vpc_id = aws_vpc.vpc_secondary.id

  tags = {
    Name = "secondary-private-rt"
  }
}

resource "aws_route_table_association" "private_assoc_secondary" {
  subnet_id      = aws_subnet.private_subnet_secondary.id
  route_table_id = aws_route_table.private_rt_secondary.id
}
