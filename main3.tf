provider "aws" {
  region = "us-east-1"
}

##############################
# VPC and Subnets
##############################

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "tf-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "tf-public-subnet-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "tf-public-subnet-2"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "tf-private-subnet"
  }
}

##############################
# Route Tables
##############################

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_assoc_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

##############################
# Security Groups
##############################

resource "aws_security_group" "public_sg" {
  name   = "public-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

ingress {
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

resource "aws_security_group" "private_sg" {
  name   = "private-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public_sg.id]
  }

ingress {
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"] # or narrow to NLB's subnet CIDRs
}

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

##############################
# IAM Roles and Instance Profile
##############################

resource "aws_iam_role" "ec2_role" {
  name = "tf-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "tf-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

##############################
# NAT Gateway Setup
##############################

resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = "tf-nat-eip"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id
  depends_on    = [aws_internet_gateway.igw]

  tags = {
    Name = "tf-nat-gateway"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "tf-private-rt"
  }
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

##############################
# ALB and Target Group
##############################

resource "aws_lb" "alb" {
  name               = "tf-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.public_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}

resource "aws_lb_target_group" "tg" {
  name     = "tf-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.self_signed.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

##############################
# EC2 Instances
##############################

resource "aws_instance" "public_ec2_alb" {
  ami                         = "ami-0c101f26f147fa7fd"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet_2.id
  vpc_security_group_ids      = [aws_security_group.public_sg.id]
  associate_public_ip_address = true
  key_name                    = "dron69"
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  user_data                   = "#!/bin/bash\nyum install -y httpd\nsystemctl start httpd\nsystemctl enable httpd\necho '<h1>ALB Target</h1>' > /var/www/html/index.html"

  tags = {
    Name = "tf-public-alb-target"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group_attachment" "attach_alb" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.public_ec2_alb.id
  port             = 80
}

resource "aws_instance" "private_ec2" {
  ami                    = "ami-0c101f26f147fa7fd"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  key_name               = "dron69"
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "tf-private-ec2"
  }
}

##############################
# S3 Bucket and Permissions
##############################

resource "aws_s3_bucket" "private_bucket" {
  bucket = "tf-private-bucket-${random_id.rand.hex}"
  acl    = "private"

  tags = {
    Name        = "PrivateAccessBucket"
    Environment = "Dev"
  }
}

resource "random_id" "rand" {
  byte_length = 4
}

resource "aws_iam_policy" "s3_access_policy" {
  name        = "tf-private-ec2-s3-access"
  description = "Allow private EC2 instance to access S3"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:*"],
        Resource = [
          aws_s3_bucket.private_bucket.arn,
          "${aws_s3_bucket.private_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "private_ec2_s3" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

##############################
# Public NLB and Target Group
##############################

resource "aws_lb" "nlb" {
  name               = "tf-nlb"
  internal           = false  # <-- Public NLB
  load_balancer_type = "network"
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  tags = {
    Name = "tf-nlb"
  }
}

resource "aws_lb_target_group" "nlb_tg" {
  name        = "tf-nlb-tg"
  port        = 80
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"
}

resource "aws_lb_target_group_attachment" "private_ec2_nlb_attach" {
  target_group_arn = aws_lb_target_group.nlb_tg.arn
  target_id        = aws_instance.private_ec2.id
  port             = 80
}

resource "aws_lb_listener" "nlb_listener" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_tg.arn
  }
}
##############################
# ACM Certificate
##############################

resource "aws_acm_certificate" "self_signed" {
  domain_name       = "test.cdcmg.click"
  validation_method = "DNS"

  tags = {
    Name = "tf-self-signed"
  }

  lifecycle {
    create_before_destroy = true
  }
}


