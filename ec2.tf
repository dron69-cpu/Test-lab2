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