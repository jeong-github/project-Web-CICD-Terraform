terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"

    }
  }
}
provider "aws" {
  region = "ap-northeast-2"
}

##### VPC 생성 #####
resource "aws_vpc" "my_vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = var.instance_tenancy
  tags             = var.vpc_tag
}

# internet gateway 생성
resource "aws_internet_gateway" "my_internet_gateway" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my-igw"
  }
}
# Elastic Ip 생성
resource "aws_eip" "NAT-eip" {
  vpc = true
  tags = {
    Name = "NAT-eip"
  }
}

# NAT 게이트웨이 생성
resource "aws_nat_gateway" "myNAT" {
  allocation_id = aws_eip.NAT-eip.id
  subnet_id     = aws_subnet.public_subnet2.id

  tags = {
    Name = "myNAT"
  }
}

### Subnet 생성 ###
# public subnet 생성
resource "aws_subnet" "public_subnet1" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.16.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-2a"

  tags = {
    Name = "my-public1"
  }
}

resource "aws_subnet" "public_subnet2" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.16.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-2c"

  tags = {
    Name = "my-public2"
  }
}

# public-route 생성-연결
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.my_vpc.id


  tags = {
    Name = "public_rt"
  }
}
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_internet_gateway.id
}
resource "aws_route_table_association" "public_assoc1" {
  subnet_id      = aws_subnet.public_subnet1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_assoc2" {
  subnet_id      = aws_subnet.public_subnet2.id
  route_table_id = aws_route_table.public_rt.id
}

# private-route 생성 1,2
resource "aws_subnet" "private_subnet1" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.16.3.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "my_private1"
  }
}

resource "aws_subnet" "private_subnet2" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.16.4.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "my_private2"
  }
}

# private-route 생성-연결
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "private_rt"
  }
}

resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.myNAT.id
}

resource "aws_route_table_association" "private_assoc1" {
  subnet_id      = aws_subnet.private_subnet1.id
  route_table_id = aws_route_table.private_rt.id
}
resource "aws_route_table_association" "private_assoc2" {
  subnet_id      = aws_subnet.private_subnet2.id
  route_table_id = aws_route_table.private_rt.id
}




