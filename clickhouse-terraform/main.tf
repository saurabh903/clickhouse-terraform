provider "aws" {
  region = var.region
}

# ----------------------
# VPC
# ----------------------
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = { Name = "clickhouse-vpc" }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "clickhouse-igw" }
}

# ----------------------
# Subnets (2 AZs)
# ----------------------
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_cidrs[count.index]
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = true
  tags = { Name = "clickhouse-public-${count.index}" }
}

# Route Table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "clickhouse-public-rt" }
}

resource "aws_route" "internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public_assoc" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ----------------------
# Security Groups
# ----------------------

# ALB SG - allow from anywhere on 8123
resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.this.id
  name   = "alb-sg"

  ingress {
    from_port   = 8123
    to_port     = 8123
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

# EC2 SG - allow HTTP from ALB and SSH from your IP
resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.this.id
  name   = "ec2-sg"

  # Allow traffic from ALB on port 8123
  ingress {
    from_port       = 8123
    to_port         = 8123
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Allow SSH from your IP (replace YOUR_PUBLIC_IP with your actual IP)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["YOUR_PUBLIC_IP/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ----------------------
# EC2 Instances
# ----------------------
resource "aws_instance" "clickhouse" {
  count         = 2
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public[count.index].id
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  tags = {
    Name = "clickhouse-${count.index}"
    role = "Clickhouse"
  }
}

# ----------------------
# ALB
# ----------------------
resource "aws_lb" "this" {
  name               = "clickhouse-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public[*].id
}

resource "aws_lb_target_group" "this" {
  name     = "clickhouse-tg"
  port     = 8123
  protocol = "HTTP"
  vpc_id   = aws_vpc.this.id
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = 8123
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_lb_target_group_attachment" "attach" {
  count            = 2
  target_group_arn = aws_lb_target_group.this.arn
  target_id        = aws_instance.clickhouse[count.index].id
  port             = 8123
}
