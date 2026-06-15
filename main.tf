provider "aws" {
  region     = "us-east-1"
}

data "aws_availability_zones" "available" {}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "my-main-vpc"
  }
}


resource "aws_subnet" "public_subnets" {
  count = 3

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet("10.0.0.0/16", 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

# -------------------------
# Private Subnets (3)
# -------------------------
resource "aws_subnet" "private_subnets" {
  count = 3

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet("10.0.0.0/16", 8, count.index + 3)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet-${count.index + 1}"
  }
}

#==============================================
# Internet Gateway (for public subnets)
#==============================================

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

#==============================================
# Public Route Table
#==============================================

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "public-route-table"
  }
}

#==============================================
# Route to Internet (Public)
#==============================================

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

#==============================================
# Associate Public Subnets
#==============================================

resource "aws_route_table_association" "public_assoc" {
  count = 3

  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

#==============================================
# Elastic IP for NAT
#==============================================

resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

#==============================================
# NAT Gateway (in Public Subnet)
#==============================================

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnets[0].id

  tags = {
    Name = "nat-gateway"
  }
}

#==============================================
# Private Route Table
#==============================================

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-route-table"
  }
}

#==============================================
# Route for Private Subnets (via NAT)
#==============================================


resource "aws_route" "private_internet_access" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"

  nat_gateway_id = aws_nat_gateway.nat.id

  depends_on = [aws_nat_gateway.nat]
}


#==============================================
# Associate Private Subnets
#==============================================
resource "aws_route_table_association" "private_assoc" {
  count = 3

  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

# ======================================
#  Security Group (for private instance)
# ======================================
resource "aws_security_group" "private_sg" {
  name   = "private-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "Allow SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Only from inside VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ======================================
# EC2 Instance in Private Subnet
# ======================================

resource "aws_instance" "private_instance" {
  ami           = "ami-0c374876b6fc67b33" # Amazon Linux 2 (update if needed)
  instance_type = "t2.micro"

  subnet_id = aws_subnet.private_subnets[0].id # any private subnet

  vpc_security_group_ids = [aws_security_group.private_sg.id]

  associate_public_ip_address = false

  tags = {
    Name = "private-instance"
  }
}

# ================================
# EC2 in public subnet:
# ================================

resource "aws_instance" "bastion" {
  ami           = "ami-0c374876b6fc67b33"
  instance_type = "t2.micro"

  subnet_id = aws_subnet.public_subnets[0].id

  associate_public_ip_address = true

  tags = {
    Name = "bastion-host"
  }
}

# ==================================
# AWS SSM
# ==================================
resource "aws_iam_role" "ssm_role" {
  name = "ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# =================================
# Attach policy:
# =================================

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}