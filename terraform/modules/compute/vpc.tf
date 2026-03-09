# VPC for compute resources
resource "aws_vpc" "main" {
  for_each           = var.regions
  region             = each.key
  cidr_block         = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name   = "compute-vpc-${each.key}"
    Region = each.key
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  for_each = var.regions
  region   = each.key
  vpc_id   = aws_vpc.main[each.key].id

  tags = {
    Name   = "compute-igw-${each.key}"
    Region = each.key
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  for_each                = var.regions
  region                  = each.key
  vpc_id                  = aws_vpc.main[each.key].id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available[each.key].names[0]
  map_public_ip_on_launch = true

  tags = {
    Name   = "compute-public-subnet-${each.key}"
    Region = each.key
  }
}

# Get available AZs
data "aws_availability_zones" "available" {
  for_each = var.regions
  region   = each.key
  state    = "available"
}

# Route Table for public subnet
resource "aws_route_table" "public" {
  for_each = var.regions
  region   = each.key
  vpc_id   = aws_vpc.main[each.key].id

  tags = {
    Name   = "compute-public-rt-${each.key}"
    Region = each.key
  }
}

# Route to Internet Gateway
resource "aws_route" "public_internet_gateway" {
  for_each               = var.regions
  region                 = each.key
  route_table_id         = aws_route_table.public[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main[each.key].id
}

# Associate public subnet with route table
resource "aws_route_table_association" "public" {
  for_each       = var.regions
  region      = each.key
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public[each.key].id
}
