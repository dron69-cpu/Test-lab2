variable "aws_region" {
  default     = "us-east-1"
  description = "AWS Region"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  default = ["10.0.1.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidr" {
  default = "10.0.2.0/24"
}

variable "key_name" {
  default     = "dron69"
  description = "AWS key pair name"
}

variable "ami_id" {
  default = "ami-0c101f26f147fa7fd"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "domain_name" {
  default = "test.cdcmg.click"
}

resource "aws_ec2_transit_gateway" "main_tgw" {
  description                     = "Main TGW for peering"
 auto_accept_shared_attachments = "enable"
default_route_table_association = "enable"
default_route_table_propagation = "enable"


  tags = {
    Name = "main-tgw"
  }
}
