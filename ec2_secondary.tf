resource "aws_instance" "secondary_public_ec2" {
  ami                         = "ami-0c101f26f147fa7fd" # Amazon Linux 2 (update if needed)
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet_secondary.id
  vpc_security_group_ids      = [aws_security_group.public_sg.id] # or define a new SG
  associate_public_ip_address = true
  key_name                    = "dron69"
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Secondary VPC Public EC2</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "secondary-public-ec2"
  }
}

resource "aws_instance" "secondary_private_ec2" {
  ami                         = "ami-0c101f26f147fa7fd"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.private_subnet_secondary.id
  vpc_security_group_ids      = [aws_security_group.private_sg.id]
  key_name                    = "dron69"
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Secondary VPC Private EC2</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "secondary-private-ec2"
  }
}
