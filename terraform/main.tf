# --- PROVIDER & DATA ---
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"] # Changed to Amazon Linux 2 as per spec
  }
}

# --- NETWORK INFRASTRUCTURE ---

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16" 
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "ecommerce-vpc" }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id 
}

# --- Subnets ---
# Public Subnets for ALB and NAT Gateway
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index) # 10.0.0.0/24, 10.0.1.0/24
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = { Name = "ecommerce-public-subnet-${count.index + 1}" }
}

# Private Subnets for EC2 Instances
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  # Using spec CIDRs, assuming one per AZ for resilience
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 2) # 10.0.2.0/24, 10.0.3.0/24
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = { Name = "ecommerce-private-subnet-${count.index + 1}" }
}

# --- Routing & Gateways ---
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id # Place NAT in the first public subnet
  depends_on    = [aws_internet_gateway.gw]
  tags = { Name = "ecommerce-nat-gw" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = { Name = "ecommerce-public-rt" }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = { Name = "ecommerce-private-rt" }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

# --- BASTION HOST ---

resource "aws_security_group" "bastion" {
  name   = "ecommerce-bastion-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    description = "Allow SSH from anywhere for CI/CD"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # WARNING: For production, restrict this to your CI/CD runner's IP range.
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public[0].id # Must be in a public subnet
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  key_name                    = var.key_name
  associate_public_ip_address = true
  tags = { Name = "EC2-Bastion-Host" }
}

# --- SECURITY GROUPS ---

resource "aws_security_group" "alb" {
  name   = "ecommerce-alb-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "web" {
  name   = "ecommerce-web-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    description     = "Allow SSH from Bastion Host"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }
  ingress {
    description     = "Allow HTTP from ALB"
    from_port       = 80 
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id] 
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- LOAD BALANCER ---

resource "aws_lb" "web" {
  name               = "ecommerce-alb" 
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id 
}

resource "aws_lb_target_group" "web" {
  name     = "ecommerce-tg" 
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path = "/" 
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# --- EC2 INSTANCES ---

resource "aws_instance" "web" {
  count                       = var.instance_count
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type 
  subnet_id                   = aws_subnet.private[count.index].id # MOVED to private subnets
  vpc_security_group_ids      = [aws_security_group.web.id]
  key_name                    = var.key_name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = { Name = "EC2-Web-${count.index + 1}" }
}

resource "aws_lb_target_group_attachment" "web" {
  count            = var.instance_count
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web[count.index].id
  port             = 80
}
